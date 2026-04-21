{ pkgs, nixosSystem }:

# Guard: ensure no evaluated config pulls secret content into the nix store
# via `environment.etc.<name>.text`. Age secrets should be referenced by
# runtime .path (/run/agenix/<name>), never baked into a store path at eval.
#
# We do NOT flag `.source = <store-path>` by substring ("age"/"secret") —
# those collided with many legitimate NixOS paths. The real leak vector is
# a literal private key in `.text`, which is what this check guards.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  hostName = cfg.networking.hostName;

  etc = cfg.environment.etc or {};
  etcEntries = lib.attrValues etc;

  textHasSecretMarker = entry:
    let t = entry.text or null; in
    t != null
    && builtins.isString t
    && t != ""
    && (lib.hasInfix "-----BEGIN AGE ENCRYPTED FILE-----" t
        || lib.hasInfix "-----BEGIN OPENSSH PRIVATE KEY-----" t
        || lib.hasInfix "-----BEGIN RSA PRIVATE KEY-----" t
        || lib.hasInfix "-----BEGIN PRIVATE KEY-----" t);

  suspiciousEtc = lib.filter textHasSecretMarker etcEntries;

  checks = [
    { name = "no environment.etc entry embeds a private key literal";
      ok = suspiciousEtc == []; }
  ];

  failed = lib.filter (c: !c.ok) checks;
  failedNames = lib.concatMapStringsSep ", " (c: c.name) failed;
  passLines = lib.concatMapStringsSep "\n" (c: "  [PASS] ${c.name}") checks;

in

if failed != []
then throw "no-store-secrets check failed for ${hostName}: ${failedNames} (${toString (lib.length suspiciousEtc)} suspicious entries)"
else pkgs.runCommand "no-store-secrets-${hostName}" { } ''
  echo "=== no-store-secrets-${hostName} ==="
  cat <<'EOF'
  ${passLines}
  EOF
  touch $out
''
