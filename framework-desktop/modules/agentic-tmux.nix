{ config, lib, pkgs, ... }:

# agentic-tmux daemon — runs alongside bosun on perdurabo so I can
# develop the new supervisor against live observations without
# disturbing bosun. Disabled by default; flip enable to true once
# I've validated the binary on the host. Port 7767 to avoid colliding
# with bosun's 7766.

let
  cfg = config.services.agenticTmux;
in {
  options.services.agenticTmux = {
    enable = lib.mkEnableOption "agentic-tmux daemon (Zellij plugin supervisor)";

    package = lib.mkOption {
      type = lib.types.path;
      default = "/home/jason/.local/bin/at-daemon";
      description = "Path to the at-daemon binary (out-of-band deploy until pinned as flake input).";
    };

    httpAddr = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:7767";
      description = "HTTP control-plane bind address. Empty disables HTTP.";
    };

    socketPath = lib.mkOption {
      type = lib.types.str;
      default = "%t/agentic-tmux/socket";
      description = "Unix socket the Zellij plugin connects to.";
    };

    auditPath = lib.mkOption {
      type = lib.types.str;
      default = "%S/agentic-tmux/audit.jsonl";
      description = "Append-only audit log path.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.agentic-tmux = {
      description = "agentic-tmux supervisor daemon";
      documentation = [ "https://github.com/Ad-Astra-Computing/agentic-tmux" ];
      wantedBy = [ "default.target" ];
      after = [ "default.target" ];

      environment = {
        XDG_RUNTIME_DIR = "%t";
        XDG_STATE_HOME = "%S";
      };

      serviceConfig = {
        Type = "simple";
        WorkingDirectory = "%h";
        ExecStart = "${cfg.package} --socket ${cfg.socketPath} --http ${cfg.httpAddr} --audit ${cfg.auditPath}";
        Restart = "on-failure";
        RestartSec = "5s";
        StateDirectory = "agentic-tmux";
        RuntimeDirectory = "agentic-tmux";
        RuntimeDirectoryMode = "0700";
        StateDirectoryMode = "0700";
      };
    };
  };
}
