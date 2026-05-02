# Stub agenix module for VM tests.
#
# Replaces the real ragenix/agenix module so tests don't have to decrypt real
# secrets in CI. Provides the same `age.secrets.<name>` option surface, but
# materializes plaintext placeholder content at the same paths via tmpfiles.
#
# Plaintext content is "stub-<name>" so anything reading the file gets a
# deterministic value rather than a decryption failure.
{ config, lib, pkgs, ... }:

let
  inherit (lib) mkOption types mapAttrsToList;

  secretType = types.submodule ({ name, ... }: {
    options = {
      file = mkOption { type = types.path; };
      mode = mkOption { type = types.str; default = "0400"; };
      owner = mkOption { type = types.str; default = "root"; };
      group = mkOption { type = types.str; default = "root"; };
      name = mkOption { type = types.str; default = name; };
      path = mkOption { type = types.str; default = "/run/agenix/${name}"; };
      symlink = mkOption { type = types.bool; default = true; };
    };
  });

  cfg = config.age;
in
{
  # Don't load the real agenix module alongside this stub.
  disabledModules = [ "modules/age.nix" ];

  options.age = {
    secrets = mkOption {
      type = types.attrsOf secretType;
      default = {};
    };
    identityPaths = mkOption {
      type = types.listOf types.str;
      default = [];
    };
  };

  config.systemd.tmpfiles.rules =
    [ "d /run/agenix 0755 root root -" ]
    ++ mapAttrsToList
      (n: s: "f+ ${s.path} ${s.mode} ${s.owner} ${s.group} - stub-${n}")
      cfg.secrets;
}
