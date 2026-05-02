# OpenBao container configuration
{ config, pkgs, lib, ... }:

let
  # OpenBao configuration variables
  containerIP = "192.168.100.10";
  hostIP = "192.168.100.1";
  apiPort = 8200;
  clusterPort = 8201;
in
{
  # OpenBao container
  containers.openbao = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = hostIP;
    localAddress = containerIP;

    bindMounts = {
      "/etc/ssl/certs" = {
        hostPath = "/etc/ssl/certs";
        isReadOnly = true;
      };
    };

    config = { config, pkgs, ... }: {
      system.stateVersion = "25.05";

      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ apiPort ];
      };

      # Install OpenBao
      environment.systemPackages = with pkgs; [
        openbao
        jq
        curl
      ];

      # OpenBao service
      systemd.services.openbao = {
        description = "OpenBao secrets management";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          User = "openbao";
          Group = "openbao";
          ExecStart = "${pkgs.openbao}/bin/bao server -config=/etc/openbao/config.hcl";
          ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
          KillMode = "process";
          Restart = "on-failure";
          RestartSec = 42;
          LimitNOFILE = 65536;
          LimitMEMLOCK = "infinity";

          # Security hardening
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ReadWritePaths = [ "/var/lib/openbao" ];
        };

        # Health check to ensure OpenBao is responding
        preStart = ''
          # Ensure data directory is properly initialized
          mkdir -p /var/lib/openbao/{data,logs,backup}
          chown -R openbao:openbao /var/lib/openbao
        '';
      };

      # OpenBao health check service
      systemd.services.openbao-health = {
        description = "OpenBao health check";
        after = [ "openbao.service" ];
        wants = [ "openbao.service" ];

        serviceConfig = {
          Type = "oneshot";
          User = "openbao";
          Group = "openbao";
        };

        script = ''
          # Wait for OpenBao to start
          sleep 10

          # Health check
          if ${pkgs.curl}/bin/curl -f http://localhost:${toString apiPort}/v1/sys/health &>/dev/null; then
            echo "OpenBao is healthy"
            exit 0
          else
            echo "OpenBao health check failed"
            exit 1
          fi
        '';
      };

      systemd.timers.openbao-health = {
        description = "OpenBao health check timer";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5min";
          OnUnitActiveSec = "5min";
          Unit = "openbao-health.service";
        };
      };

      # OpenBao user and group
      users.users.openbao = {
        isSystemUser = true;
        group = "openbao";
        home = "/var/lib/openbao";
        createHome = true;
      };
      users.groups.openbao = {};

      # OpenBao configuration directory
      environment.etc."openbao/config.hcl".text = ''
        ui = true

        storage "file" {
          path = "/var/lib/openbao/data"
        }

        # Bind to the container's private subnet IP only. Host firewall
        # restricts upstream access to tailscale0 (see networking.nix).
        listener "tcp" {
          address     = "${containerIP}:${toString apiPort}"
          tls_disable = 1
        }

        api_addr = "http://${containerIP}:${toString apiPort}"
        cluster_addr = "http://${containerIP}:${toString clusterPort}"

        log_level = "Info"

        # SSH CA configuration
        ssh_ca {
          enabled = true
        }
      '';

      # OpenBao backup service
      systemd.services.openbao-backup = {
        description = "Backup OpenBao data";
        serviceConfig = {
          Type = "oneshot";
          User = "openbao";
          Group = "openbao";
        };

        script = ''
          BACKUP_DIR="/var/lib/openbao/backup"
          DATA_DIR="/var/lib/openbao/data"
          TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

          # Create backup if data exists
          if [ -d "$DATA_DIR" ] && [ "$(ls -A $DATA_DIR)" ]; then
            echo "Creating OpenBao backup: $TIMESTAMP"
            ${pkgs.gnutar}/bin/tar -czf "$BACKUP_DIR/openbao_backup_$TIMESTAMP.tar.gz" -C "$DATA_DIR" .

            # Keep only last 7 backups
            cd "$BACKUP_DIR"
            ls -t openbao_backup_*.tar.gz | tail -n +8 | xargs -r rm -f
            echo "Backup completed successfully"
          else
            echo "No OpenBao data to backup"
          fi
        '';
      };

      systemd.timers.openbao-backup = {
        description = "Daily OpenBao backup";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
          Unit = "openbao-backup.service";
        };
      };

      # Ensure directories exist with correct permissions
      systemd.tmpfiles.rules = [
        "d /var/lib/openbao 0755 openbao openbao"
        "d /var/lib/openbao/data 0755 openbao openbao"
        "d /var/lib/openbao/logs 0755 openbao openbao"
        "d /var/lib/openbao/backup 0755 openbao openbao"
      ];
    };
  };

  # Note: Host firewall rules and NAT forwarding configured in networking.nix
}
