{ pkgs, nixosSystem }:

# Guard: ensure no evaluated config pulls age/agenix secret content into the
# nix store. Age secrets should always be referenced by runtime .path
# (/run/agenix/<name>), never baked into a store path at eval time.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  hostName = cfg.networking.hostName;

  etc = cfg.environment.etc or {};
  etcEntries = lib.attrValues etc;

  sourceIsStoreSecret = entry:
    let src = entry.source or null; in
    src != null
    && builtins.isString (toString src)
    && lib.isStorePath (toString src)
    && (lib.hasInfix "age" (toString src) || lib.hasInfix "secret" (toString src));

  textHasSecretMarker = entry:
    let t = entry.text or null; in
    t != null
    && builtins.isString t
    && t != ""
    && (lib.hasInfix "-----BEGIN AGE ENCRYPTED FILE-----" t
        || lib.hasInfix "-----BEGIN OPENSSH PRIVATE KEY-----" t
        || lib.hasInfix "-----BEGIN RSA PRIVATE KEY-----" t
        || lib.hasInfix "-----BEGIN PRIVATE KEY-----" t);

  suspiciousEtc = lib.filter
    (e: sourceIsStoreSecret e || textHasSecretMarker e)
    etcEntries;

  checks = [
    { name = "no environment.etc entry sources a store-path secret";
      ok = lib.all (e: !sourceIsStoreSecret e) etcEntries; }

    { name = "no environment.etc entry embeds a private key literal";
      ok = lib.all (e: !textHasSecretMarker e) etcEntries; }
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
