# Networking configuration for Theophany
{ config, pkgs, lib, ... }:

{
  # Networking and hostname
  networking = {
    hostName = "theophany";
    computerName = "theophany";
    localHostName = "theophany";
  };
}
