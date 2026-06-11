{ config, lib, pkgs, ... }:

# bosun supervisor — runs the tmux AI-agent supervisor as a
# systemd user service so it survives logout/login. The binary
# itself is currently deployed out-of-band to ~/.local/bin/bosun.
# When I add bosun as a flake input the ExecStart path moves to
# ${bosunPkg}/bin/bosun.
#
# The unit content mirrors what `bosun service install --manager
# systemd` writes when bosun owns the file. Keeping it declarative
# means I don't need to re-run install after a host rebuild.

let
  binary = "/home/jason/.local/bin/bosun";
  configFile = "/home/jason/.config/bosun/bosun.toml";
in {
  systemd.user.services.bosun = {
    description = "Bosun supervisor (user instance)";
    documentation = [ "https://github.com/Ad-Astra-Computing/bosun" ];
    wantedBy = [ "default.target" ];
    after = [ "default.target" ];

    # bosun shells out to tmux on every supervisor tick for
    # capture-pane and send-keys. NixOS gives user units a minimal
    # PATH (coreutils, findutils, grep, sed, systemd) and strips
    # the operator's nix-profile, so without injecting tmux here
    # every capture would fail "tmux: command not found".
    path = [ pkgs.tmux ];

    # %t expands to $XDG_RUNTIME_DIR. tmux derives its socket from
    # TMUX_TMPDIR; interactive shells inherit it via pam_systemd,
    # but a user-unit's env is stripped, so without this the unit
    # would look at /tmp/tmux-UID/default and miss the live socket.
    environment = {
      TMUX_TMPDIR = "%t";
    };

    serviceConfig = {
      Type = "simple";
      WorkingDirectory = "%h";
      ExecStart = "${binary} run --config ${configFile}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Publish the bosun dashboard over tailscale on port 8443 so I can
  # open it from any tailnet device. Port 443 is taken by forgejo, so
  # picking a non-conflicting one. tailscale serve persists its
  # config in /var/lib/tailscale/serve.json; this oneshot ensures the
  # mapping survives reboots and host rebuilds without my having to
  # rerun `tailscale serve` manually.
  systemd.services.bosun-tailscale-serve = {
    description = "Publish bosun dashboard over tailscale (port 8443)";
    after = [ "tailscaled.service" "network-online.target" ];
    wants = [ "tailscaled.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --https=8443 http://127.0.0.1:7766";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=8443 off";
    };
  };
}
