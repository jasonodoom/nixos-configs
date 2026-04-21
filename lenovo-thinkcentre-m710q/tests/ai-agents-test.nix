{ pkgs, nixosSystem }:

# Guard: the AI agent nspawn module produces the expected shape.
# Pure eval. No boot, no network. Catches overlay breakage, missing
# packages, wrong ports, broken bind mounts.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  hostName = cfg.networking.hostName;

  containers = cfg.containers or {};
  expected = [ "claude" "codex" "gemini" ];

  containerOf = name: containers.${name} or null;
  guestOf = name:
    let c = containerOf name; in
    if c == null then null else c.config or null;

  hasSshPort = name: port:
    let g = guestOf name; in
    g != null
    && (lib.elem port g.services.openssh.ports);

  hasPackage = name: pkgName:
    let g = guestOf name; in
    g != null
    && lib.any (p: (p.pname or "") == pkgName || (lib.getName p) == pkgName)
               g.environment.systemPackages;

  hasBindMount = name: path:
    let c = containerOf name; in
    c != null
    && (c.bindMounts ? ${path});

  checks =
    (map (n: {
      name = "containers.${n} is declared";
      ok = containerOf n != null;
    }) expected)
    ++
    [
      { name = "claude guest has claude-code package";
        ok = hasPackage "claude" "claude-code"; }
      { name = "codex guest has codex package";
        ok = hasPackage "codex" "codex"; }
      { name = "gemini guest has gemini-cli package";
        ok = hasPackage "gemini" "gemini-cli"; }

      { name = "claude guest sshd listens on 2201";
        ok = hasSshPort "claude" 2201; }
      { name = "codex guest sshd listens on 2202";
        ok = hasSshPort "codex" 2202; }
      { name = "gemini guest sshd listens on 2203";
        ok = hasSshPort "gemini" 2203; }

      { name = "claude container bind-mounts /home/agent/code";
        ok = hasBindMount "claude" "/home/agent/code"; }

      { name = "all three containers use private network";
        ok = lib.all
          (n: let c = containerOf n; in c != null && c.privateNetwork == true)
          expected; }

      { name = "host creates state dirs under ~/.local/state/ai-agents";
        ok = lib.any
          (r: lib.hasInfix "/home/jason/.local/state/ai-agents" r)
          cfg.systemd.tmpfiles.rules; }
    ];

  failed = lib.filter (c: !c.ok) checks;
  failedNames = lib.concatMapStringsSep ", " (c: c.name) failed;
  passLines = lib.concatMapStringsSep "\n" (c: "  [PASS] ${c.name}") checks;

in

if failed != []
then throw "ai-agents check failed for ${hostName}: ${failedNames}"
else pkgs.runCommand "ai-agents-${hostName}" { } ''
  echo "=== ai-agents-${hostName} ==="
  cat <<'EOF'
  ${passLines}
  EOF
  touch $out
''
