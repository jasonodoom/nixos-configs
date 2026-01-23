# Ollama
{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    host = "0.0.0.0";
  };
}
