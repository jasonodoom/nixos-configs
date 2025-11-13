# Log aggregation with Grafana Loki and Promtail for Congo server
{ config, pkgs, lib, ... }:

let
  # Logs service configuration variables
  lokiHttpPort = 3100;
  lokiGrpcPort = 9096;
  promtailHttpPort = 3031;
  promtailGrpcPort = 3032;
  dashboardPort = 8080;
  hostname = "congo";
  retentionDays = 31;

  # Create the log dashboard HTML directory with index.html
  logDashboard = pkgs.runCommand "congo-logs-dashboard" {} ''
    mkdir -p $out
    cat > $out/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Congo Server Logs</title>
    <style>
        body { font-family: monospace; background: #1a1a1a; color: #fff; margin: 40px; }
        .header { color: #ffd700; font-size: 24px; margin-bottom: 20px; }
        .service { background: #333; padding: 15px; margin: 10px 0; border-radius: 5px; }
        .service h3 { color: #4CAF50; margin-top: 0; }
        a { color: #81C784; text-decoration: none; cursor: pointer; }
        a:hover { color: #A5D6A7; }
        .query { background: #444; padding: 10px; margin: 5px 0; border-radius: 3px; font-size: 12px; }
        pre { background: #222; padding: 10px; overflow-x: auto; max-height: 400px; }
        .result { margin-top: 20px; }
    </style>
    <script>
        function queryLogs(job, filter, hours) {
            const now = Date.now() * 1000000; // nanoseconds
            const start = (Date.now() - (hours * 3600000)) * 1000000;
            let query = `{job="` + job + `"}`;
            if (filter) query += `|~"` + filter + `"`;
            const url = `/loki/api/v1/query_range?query=` + encodeURIComponent(query) + `&start=` + start + `&end=` + now + `&limit=100`;
            window.location.href = url;
        }
    </script>
</head>
<body>
    <div class="header">Congo Server Log Dashboard</div>

    <div class="service">
        <h3>Security Logs</h3>
        <div class="query">Fail2ban bans: <a onclick="queryLogs('fail2ban', 'Ban', 24)">View Recent Bans (24h)</a></div>
        <div class="query">SSH failures: <a onclick="queryLogs('ssh-auth', 'Failed', 24)">View Failed Logins (24h)</a></div>
    </div>

    <div class="service">
        <h3>Pi-hole DNS Logs</h3>
        <div class="query">DNS queries: <a onclick="queryLogs('pihole-queries', null, 1)">Last Hour</a></div>
        <div class="query">Blocked domains: <a onclick="queryLogs('pihole-queries', 'blocked', 24)">View Blocked (24h)</a></div>
    </div>

    <div class="service">
        <h3>Container Logs</h3>
        <div class="query">All containers: <a onclick="queryLogs('containers', null, 1)">View Container Logs (1h)</a></div>
        <div class="query">System journal: <a onclick="queryLogs('systemd-journal', null, 1)">View System Logs (1h)</a></div>
    </div>

    <div class="service">
        <h3>Query by Label</h3>
        <div class="query"><a href="/loki/api/v1/labels">Available Labels</a></div>
        <div class="query"><a href="/loki/api/v1/label/job/values">Available Jobs</a></div>
    </div>
</body>
</html>
EOF
  '';
in

{
  # Loki for log storage and querying
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = lokiHttpPort;
        grpc_listen_port = lokiGrpcPort;
        log_level = "info";
      };

      ingester = {
        lifecycler = {
          address = "127.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
        };
        chunk_idle_period = "1h";
        max_chunk_age = "1h";
        chunk_target_size = 1048576;
        chunk_retain_period = "30s";
      };

      schema_config = {
        configs = [
          {
            from = "2020-10-24";
            store = "boltdb-shipper";
            object_store = "filesystem";
            schema = "v11";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      storage_config = {
        boltdb_shipper = {
          active_index_directory = "/var/lib/loki/boltdb-shipper-active";
          cache_location = "/var/lib/loki/boltdb-shipper-cache";
          cache_ttl = "24h";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };

      limits_config = {
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        retention_period = "${toString (retentionDays * 24)}h";
        allow_structured_metadata = false;
      };

      table_manager = {
        retention_deletes_enabled = false;
        retention_period = "0s";
      };

      compactor = {
        working_directory = "/var/lib/loki";
        compactor_ring = {
          kvstore = {
            store = "inmemory";
          };
        };
      };
    };
  };

  # Promtail for log collection
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = promtailHttpPort;
        grpc_listen_port = promtailGrpcPort;
      };

      positions = {
        filename = "/tmp/positions.yaml";
      };

      clients = [
        {
          url = "http://localhost:${toString lokiHttpPort}/loki/api/v1/push";
        }
      ];

      scrape_configs = [
        # System logs
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = hostname;
            };
          };
          relabel_configs = [
            {
              source_labels = ["__journal__systemd_unit"];
              target_label = "unit";
            }
          ];
        }

        # Pi-hole DNS query logs
        {
          job_name = "pihole-queries";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "pihole-queries";
                host = hostname;
                service = "pihole";
                __path__ = "/var/log/pihole-queries.log";
              };
            }
          ];
          pipeline_stages = [
            {
              match = {
                selector = ''{job="pihole-queries"}'';
                stages = [
                  {
                    regex = {
                      expression = "^(?P<timestamp>\\S+ \\S+) (?P<type>\\w+)\\[\\d+\\]: (?P<client>\\S+) (?P<query>\\S+) (?P<result>.*)$";
                    };
                  }
                  {
                    labels = {
                      query_type = "type";
                      client_ip = "client";
                      domain = "query";
                    };
                  }
                ];
              };
            }
          ];
        }

        # Fail2ban logs
        {
          job_name = "fail2ban";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "fail2ban";
                host = hostname;
                service = "fail2ban";
                __path__ = "/var/log/fail2ban.log";
              };
            }
          ];
          pipeline_stages = [
            {
              match = {
                selector = ''{job="fail2ban"}'';
                stages = [
                  {
                    regex = {
                      expression = "^(?P<timestamp>\\S+ \\S+ \\S+) (?P<level>\\w+)\\s+\\[(?P<jail>\\w+)\\] (?P<action>\\w+) (?P<ip>\\S+)";
                    };
                  }
                  {
                    labels = {
                      level = "level";
                      jail = "jail";
                      action = "action";
                      banned_ip = "ip";
                    };
                  }
                ];
              };
            }
          ];
        }

        # SSH authentication logs
        {
          job_name = "ssh-auth";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "ssh-auth";
                host = hostname;
                service = "sshd";
                __path__ = "/var/log/auth.log";
              };
            }
          ];
          pipeline_stages = [
            {
              match = {
                selector = ''{job="ssh-auth"} |~ "sshd"'';
                stages = [
                  {
                    regex = {
                      expression = "^(?P<timestamp>\\S+ \\d+ \\S+) \\S+ sshd\\[\\d+\\]: (?P<event>.*)";
                    };
                  }
                  {
                    labels = {
                      auth_event = "event";
                    };
                  }
                ];
              };
            }
          ];
        }

        # Container logs
        {
          job_name = "containers";
          static_configs = [
            {
              targets = ["localhost"];
              labels = {
                job = "containers";
                host = hostname;
                __path__ = "/var/log/containers/*.log";
              };
            }
          ];
        }
      ];
    };
  };

# Simple web interface for log viewing using nginx
  services.nginx = {
    enable = true;
    virtualHosts."logs.congo.local" = {
      listen = [
        {
          addr = "0.0.0.0";
          port = dashboardPort;
        }
      ];
      locations = {
        "/" = {
          return = "301 http://$server_name/logs/";
        };
        "/loki/" = {
          proxyPass = "http://127.0.0.1:${toString lokiHttpPort}/loki/";
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
        "/logs/" = {
          alias = "${logDashboard}/";
        };
      };
    };
  };

  # Note: Firewall rules configured in networking.nix

  # Log rotation for custom logs
  services.logrotate.settings = {
    "/var/log/pihole-queries.log" = {
      frequency = "daily";
      rotate = 7;
      compress = true;
      delaycompress = true;
      missingok = true;
      notifempty = true;
      create = "644 root root";
    };
    "/var/log/fail2ban.log" = {
      frequency = "daily";
      rotate = 30;
      compress = true;
      missingok = true;
      notifempty = true;
    };
  };

  # Add promtail user to adm group for log access
  users.users.promtail.extraGroups = [ "adm" ];

  # Systemd service to create log directories
  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0755 loki loki"
    "d /var/log 0755 root root"
    "f /var/log/pihole-queries.log 0644 root root"
    "f /var/log/auth.log 0640 root adm"
  ];
}