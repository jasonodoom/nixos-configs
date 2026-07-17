{ config, lib, pkgs, ... }:

# bosun supervisor — runs the tmux AI-agent supervisor as a system
# service pinned to the jason user. The binary itself is currently
# deployed out-of-band to ~/.local/bin/bosun. When I add bosun as a
# flake input the ExecStart path moves to ${bosunPkg}/bin/bosun.
#
# It has to run as jason, not root: the supervised agent panes live
# in jason's tmux server (socket $XDG_RUNTIME_DIR/tmux-1000/default),
# and tmux derives the socket dir from the caller's EUID. A root
# instance looks for tmux-0 and sees an empty server, so every pane
# capture returns nothing and every pane classifies "unknown". A
# system service with User=jason keeps a single instance bound to the
# right runtime dir regardless of who is logged in.

let
  binary = "/home/jason/.local/bin/bosun";
  configFile = "/home/jason/.config/bosun/bosun.toml";
  runtimeDir = "/run/user/1000";
in {
  # jason's user runtime dir ($XDG_RUNTIME_DIR) must exist before an
  # interactive login for the boot-time service to reach the tmux
  # socket, so keep the user manager lingering.
  users.users.jason.linger = true;

  systemd.services.bosun = {
    description = "Bosun supervisor";
    documentation = [ "https://github.com/Ad-Astra-Computing/bosun" ];
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];

    # bosun shells out to tmux on every supervisor tick for
    # capture-pane and send-keys, and to ssh/openssh for the planner
    # and ask-peer bridges into the ai-* microvms. A system unit gets
    # a minimal PATH and none of jason's nix-profile, so both have to
    # be injected or the calls fail "command not found".
    path = [ pkgs.tmux pkgs.openssh ];

    # A system unit has no session, so pam_systemd never populates
    # these. tmux derives its socket from TMUX_TMPDIR; point both at
    # jason's runtime dir so capture/send-keys hit the live server.
    environment = {
      HOME = "/home/jason";
      XDG_RUNTIME_DIR = runtimeDir;
      TMUX_TMPDIR = runtimeDir;
      # The browser planner registry registers an agent only when its
      # CLI is on PATH or its ssh host is named here. The agent CLIs
      # live inside the ai-* microvms, so point the planners at them;
      # without this the browser "plan with" dropdown shows every
      # agent as not registered.
      BOSUN_PLANNER_CLAUDE_SSH = "ai-claude";
      BOSUN_PLANNER_CODEX_SSH = "ai-codex";
    };

    serviceConfig = {
      Type = "simple";
      User = "jason";
      Group = "users";
      WorkingDirectory = "/home/jason";
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
