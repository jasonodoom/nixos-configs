{ pkgs, nixosSystem }:

# Guard: the forgejo-runner microvm module produces the expected shape.
# Pure eval. No boot, no network. Catches typos, dropped attrs, and
# secret-path regressions.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  hostName = cfg.networking.hostName;

  vms = cfg.microvm.vms or {};
  vm = vms.forgejo-runner or null;
  guest = if vm == null then null else vm.config.config or null;

  secrets = cfg.age.secrets or {};
  tokenSecret = secrets.forgejo-runner-token or null;
  tsKeySecret = secrets.forgejo-runner-tailscale-authkey or null;

  runnerInstances =
    if guest == null then {}
    else guest.services.gitea-actions-runner.instances or {};
  aerInstance = runnerInstances.aer or null;

  tailscaleCfg = if guest == null then null else guest.services.tailscale or null;

  checks = [
    { name = "microvm.vms.forgejo-runner is declared";
      ok = vm != null; }

    { name = "guest config is reachable for eval";
      ok = guest != null; }

    { name = "guest hostname is perdurabo-ci";
      ok = guest != null && guest.networking.hostName == "perdurabo-ci"; }

    { name = "guest declares gitea-actions-runner instance 'aer'";
      ok = aerInstance != null && aerInstance.enable == true; }

    { name = "runner points at the Forgejo tailnet URL";
      ok = aerInstance != null
        && aerInstance.url == "https://perdurabo.ussuri-elevator.ts.net"; }

    { name = "runner token is sourced from a runtime path, not the store";
      ok = aerInstance != null
        && !(lib.isStorePath (toString aerInstance.tokenFile)); }

    { name = "guest has tailscale enabled";
      ok = tailscaleCfg != null && tailscaleCfg.enable == true; }

    { name = "tailscale authKeyFile is a runtime path";
      ok = tailscaleCfg != null
        && !(lib.isStorePath (toString tailscaleCfg.authKeyFile)); }

    { name = "host declares forgejo-runner-token agenix secret";
      ok = tokenSecret != null; }

    { name = "host declares forgejo-runner-tailscale-authkey agenix secret";
      ok = tsKeySecret != null; }

    { name = "token secret owner is microvm";
      ok = tokenSecret != null && tokenSecret.owner == "microvm"; }

    { name = "guest enables a container runtime for job execution";
      ok = guest != null
        && (guest.virtualisation.podman.enable or false) == true; }

    { name = "vm memory ceiling is at least 8 GiB";
      ok = vm != null
        && (guest.microvm.mem or 0) >= 8192; }
  ];

  failed = lib.filter (c: !c.ok) checks;
  failedNames = lib.concatMapStringsSep ", " (c: c.name) failed;
  passLines = lib.concatMapStringsSep "\n" (c: "  [PASS] ${c.name}") checks;

in

if failed != []
then throw "forgejo-runner-vm check failed for ${hostName}: ${failedNames}"
else pkgs.runCommand "forgejo-runner-vm-${hostName}" { } ''
  echo "=== forgejo-runner-vm-${hostName} ==="
  cat <<'EOF'
  ${passLines}
  EOF
  touch $out
''
