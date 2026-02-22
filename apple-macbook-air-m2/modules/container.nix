# Apple container runtime for Theophany
{ config, pkgs, lib, ... }:

{
  launchd.daemons.container-system = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.container}/bin/container"
        "system"
        "start"
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/container-system.log";
      StandardErrorPath = "/var/log/container-system.log";
    };
  };
}
