{ config, pkgs, lib, inputs, ... }:

# AI agent microvms on perdurabo.
#
# Each agent runs in its own cloud-hypervisor microvm for host-kernel
# isolation. The host reaches the guest sshd via a Linux bridge
# (virbr-ai, 10.0.42.0/24); bash aliases on the host ssh into the VM
# and invoke the tool binary.
#
# State (OAuth tokens, config) lives in
# /home/jason/.local/state/ai-agents/<name> and is virtiofs-shared into
# the guest as /home/agent. ~/code is shared read-write.

let
  userHomeState = "/home/jason/.local/state/ai-agents";
  codeDir = "/home/jason/code";

  hostAuthorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwLk94aSzaUrpxHZ6BHbxMaF3054VZJh6rUF8cdSHIm jason@perdurabo"
  ];

  # The attribute key is the systemd unit instance: microvm@ai-claude etc.
  # That matches the inner unit names the microvm flake derives from
  # hostName, so /var/lib/microvms/ai-<name> is consistent across the
  # top-level VM unit, microvm-set-booted@, and microvm-virtiofsd@.
  # `short` keys the per-agent state under ${userHomeState} so the
  # large persistent dirs (~/.claude, ~/.codex, ~/.gemini) keep their
  # existing paths and need no migration.
  agents = {
    ai-claude = { short = "claude"; mac = "02:00:00:00:ae:01"; ip = "10.0.42.11"; sshPort = 2201; };
    ai-codex  = { short = "codex";  mac = "02:00:00:00:ae:02"; ip = "10.0.42.12"; sshPort = 2202; };
    ai-gemini = { short = "gemini"; mac = "02:00:00:00:ae:03"; ip = "10.0.42.13"; sshPort = 2203; };
  };

  # Each guest gets every agent CLI so claude can shell out to codex/gemini
  # and vice versa.
  allAgentPackages = with pkgs; [ claude-code codex gemini-cli ];

  mkAgentVm = name: agent: {
    specialArgs = { inherit inputs; };

    config = { config, pkgs, lib, inputs, ... }: {
      imports = [
        inputs.microvm.nixosModules.microvm
        ../../modules/shared/ai-agent-guest.nix
      ];

      nixpkgs.overlays = [ (import ../overlays/default.nix { inherit inputs; }) ];

      system.stateVersion = "25.11";
      networking.hostName = name;

      my.aiAgent = {
        name = agent.short;
        packages = allAgentPackages;
        sshPort = agent.sshPort;
        hostPublicKeys = hostAuthorizedKeys;
        # The gemini CLI authenticates via GEMINI_API_KEY at every
        # invocation; the peer inbox watcher runs as a system service
        # so it does not source ~/.bashrc and never sees the token.
        # Activation script below converts the operator's bash-shape
        # ~/.gemini-token into a systemd EnvironmentFile and points
        # the watcher at it. Only gemini needs this; claude uses an
        # OAuth keyring and codex authenticates from ~/.codex/auth.json.
        envFile = if agent.short == "gemini" then "/run/agent-env/gemini.env" else null;
      };

      # Runs after the virtiofs share for /home/agent is up. As an activation
      # script (earlier attempt) the token file wasn't readable yet and the
      # watcher booted without GEMINI_API_KEY.
      systemd.services.gemini-env-prep = lib.mkIf (agent.short == "gemini") {
        description = "Materialize /run/agent-env/gemini.env from ~/.gemini-token";
        requiredBy = [ "ai-peer-inbox-watcher.service" ];
        before     = [ "ai-peer-inbox-watcher.service" ];
        after      = [ "home-agent.mount" "local-fs.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          install -d -m 0700 -o agent -g agent /run/agent-env
          if [ -r /home/agent/.gemini-token ]; then
            ${pkgs.gnused}/bin/sed -E 's/^[[:space:]]*export[[:space:]]+//' \
              /home/agent/.gemini-token > /run/agent-env/gemini.env
            chmod 0400 /run/agent-env/gemini.env
            chown agent:agent /run/agent-env/gemini.env
          else
            echo "gemini-env-prep: /home/agent/.gemini-token missing" >&2
            exit 1
          fi
        '';
      };

      microvm = {
        hypervisor = "qemu";
        # 6 vCPU + 12GB per agent microvm. Default of 2/4096 ran
        # out of CPU with 4 concurrent claude sessions and load
        # spiked past 11 on a 2-core guest, which correlates with
        # observed hard crashes. Host has 32 cores / 62GB so three
        # of these still leaves room for the host + bosun-browser.
        vcpu = 6;
        mem = 12288;
        balloon = true;

        interfaces = [{
          type = "bridge";
          id = "vm-${agent.short}";
          mac = agent.mac;
          bridge = "virbr-ai";
        }];

        shares = [
          {
            source = "${userHomeState}/${agent.short}";
            mountPoint = "/home/agent";
            tag = "agent-home";
            proto = "virtiofs";
          }
          {
            source = codeDir;
            mountPoint = "/home/agent/code";
            tag = "agent-code";
            proto = "virtiofs";
          }
          {
            source = "${userHomeState}/${agent.short}-sshd";
            mountPoint = "/var/lib/sshd-hostkeys";
            tag = "agent-sshd";
            proto = "virtiofs";
          }
          # Mount the parent dir so each guest can read the others'
          # ~/.claude/projects, ~/.codex/sessions, etc. at ~/peers/<agent>/.
          # Same uid mapping (1000 on host = agent in guest) means perms
          # carry through cleanly.
          {
            source = userHomeState;
            mountPoint = "/home/agent/peers";
            tag = "agent-peers";
            proto = "virtiofs";
          }
          # Persistent upper layer for the writable /nix/store overlay.
          # Lets nix-shell / nix develop materialize derivations inside
          # the VM; survives VM restarts since it lives on the host.
          {
            source = "${userHomeState}/${agent.short}-rwstore";
            mountPoint = "/nix/.rwstore";
            tag = "agent-rwstore";
            proto = "virtiofs";
          }
          {
            source = "${userHomeState}/${agent.short}-secrets";
            mountPoint = "/run/host-secrets";
            tag = "agent-secrets";
            proto = "virtiofs";
          }
          # Persist tailscaled state so the VM keeps the same tailnet
          # node identity across restarts; without this each restart
          # registers a fresh node and the hostname gets a -N suffix.
          {
            source = "${userHomeState}/${agent.short}-tailscale";
            mountPoint = "/var/lib/tailscale";
            tag = "agent-tailscale";
            proto = "virtiofs";
          }
        ];

        writableStoreOverlay = "/nix/.rwstore";
      };

      services.tailscale = {
        enable = true;
        authKeyFile = "/run/host-secrets/tailscale-authkey";
        # --accept-dns=false stops tailscaled from pushing the tailnet's
        # broken ts.net split-route to systemd-resolved. The route below
        # in extraConfig sends ts.net queries to 100.100.100.100 directly.
        # extraUpFlags runs only on initial registration; extraSetFlags
        # is what re-applies every activation.
        extraUpFlags = [ "--ssh" "--hostname=${name}" ];
        extraSetFlags = [ "--accept-dns=false" ];
        openFirewall = true;
      };

      services.resolved.enable = true;
      # extraConfig was retired in nixpkgs 26.05; settings takes the
      # same INI sections as a structured attrset.
      services.resolved.settings = {
        Resolve = {
          DNS = "100.100.100.100";
          Domains = "~ts.net";
        };
      };

      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.networks."10-eth" = {
        matchConfig.MACAddress = agent.mac;
        address = [ "${agent.ip}/24" ];
        routes = [ { Gateway = "10.0.42.1"; } ];
        dns = [ "1.1.1.1" "8.8.8.8" ];
      };
    };
  };
in
{
  age.secrets.ai-agent-tailscale-authkey = {
    file = ../secrets/ai-agent-tailscale-authkey.age;
    mode = "0400";
  };

  systemd.tmpfiles.rules = [
    "d ${userHomeState}              0750 jason users -"
    "d ${userHomeState}/claude       0750 1000  1000  -"
    "d ${userHomeState}/codex        0750 1000  1000  -"
    "d ${userHomeState}/gemini       0750 1000  1000  -"
    "d ${userHomeState}/claude-sshd  0700 root  root  -"
    "d ${userHomeState}/codex-sshd   0700 root  root  -"
    "d ${userHomeState}/gemini-sshd  0700 root  root  -"
    "d ${userHomeState}/claude-rwstore 0700 root root -"
    "d ${userHomeState}/codex-rwstore  0700 root root -"
    "d ${userHomeState}/gemini-rwstore 0700 root root -"
    "d ${userHomeState}/claude-secrets 0700 root root -"
    "d ${userHomeState}/codex-secrets  0700 root root -"
    "d ${userHomeState}/gemini-secrets 0700 root root -"
    "d ${userHomeState}/claude-tailscale 0700 root root -"
    "d ${userHomeState}/codex-tailscale  0700 root root -"
    "d ${userHomeState}/gemini-tailscale 0700 root root -"
  ];

  networking.bridges.virbr-ai.interfaces = [];
  networking.interfaces.virbr-ai.ipv4.addresses = [
    { address = "10.0.42.1"; prefixLength = 24; }
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = [ "virbr-ai" ];
  };

  networking.firewall.trustedInterfaces = [ "virbr-ai" ];

  # qemu-bridge-helper refuses by default; whitelist the AI bridge.
  environment.etc."qemu/bridge.conf".text = ''
    allow virbr-ai
  '';

  microvm.vms = lib.mapAttrs mkAgentVm agents;

  # Don't let nixos-rebuild switch bounce running VMs - it would drop any
  # active claude/codex/gemini session. New config sits on disk; pick it
  # up with `claude-restart` etc. or `ai-restart-all` when convenient.
  # The unit name matches microvm.vms.<name>, which after the rename is
  # microvm@ai-claude etc. preStart drops the decrypted tailscale auth
  # key into the per-VM secrets dir that's virtiofs-shared into the
  # guest as /run/host-secrets.
  systemd.services = lib.mapAttrs' (name: agent:
    lib.nameValuePair "microvm@${name}" {
      restartIfChanged = false;
      preStart = ''
        install -m 0400 ${config.age.secrets.ai-agent-tailscale-authkey.path} \
          ${userHomeState}/${agent.short}-secrets/tailscale-authkey
      '';
      serviceConfig.PermissionsStartOnly = true;
    }
  ) agents;

  # One-time migration for hosts that still have the pre-rename layout.
  # The microvm flake's runtime dir uses the unit name, so the old
  # /var/lib/microvms/<short> dirs need to be reachable under the new
  # ai-<short> path. Symlink instead of moving so a running VM keeps
  # working without restart; the next planned restart picks up either
  # layout transparently. Also drains stale virtiofsd@<short> instances
  # from the prior generation that systemd would otherwise leave running.
  system.activationScripts.aiMicrovmRename = lib.stringAfter [ "etc" ] ''
    for short in claude codex gemini; do
      old="/var/lib/microvms/$short"
      new="/var/lib/microvms/ai-$short"
      if [ -d "$old" ] && [ ! -e "$new" ]; then
        ln -s "$short" "$new"
      fi
      if ${pkgs.systemd}/bin/systemctl is-active --quiet "microvm-virtiofsd@$short.service" 2>/dev/null; then
        ${pkgs.systemd}/bin/systemctl stop "microvm-virtiofsd@$short.service" || true
      fi
    done
  '';

  environment.systemPackages = [ inputs.microvm.packages.x86_64-linux.microvm ];
}
