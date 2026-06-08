{ pkgs, nixosSystem }:

# Guard: the AI agent microvm module produces the expected shape.
# Pure eval. No boot, no network. Catches overlay breakage, missing
# packages, wrong ports, broken shares.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  hostName = cfg.networking.hostName;

  vms = cfg.microvm.vms or {};
  expected = [ "ai-claude" "ai-codex" "ai-gemini" ];

  vmOf = name: vms.${name} or null;
  guestOf = name:
    let vm = vmOf name; in
    if vm == null then null else vm.config.config or null;

  hasSshPort = name: port:
    let g = guestOf name; in
    g != null
    && (lib.elem port g.services.openssh.ports);

  hasPackage = name: pkgName:
    let g = guestOf name; in
    g != null
    && lib.any (p: (p.pname or "") == pkgName || (lib.getName p) == pkgName)
               g.environment.systemPackages;

  hasShare = name: source:
    let g = guestOf name; in
    g != null
    && lib.any (s: s.source == source) (g.microvm.shares or []);

  checks =
    (map (n: {
      name = "microvm.vms.${n} is declared";
      ok = vmOf n != null;
    }) expected)
    ++
    [
      { name = "ai-claude guest has claude-code package";
        ok = hasPackage "ai-claude" "claude-code"; }
      { name = "ai-codex guest has codex package";
        ok = hasPackage "ai-codex" "codex"; }
      { name = "ai-gemini guest has gemini-cli package";
        ok = hasPackage "ai-gemini" "gemini-cli"; }

      { name = "ai-claude guest sshd listens on 2201";
        ok = hasSshPort "ai-claude" 2201; }
      { name = "ai-codex guest sshd listens on 2202";
        ok = hasSshPort "ai-codex" 2202; }
      { name = "ai-gemini guest sshd listens on 2203";
        ok = hasSshPort "ai-gemini" 2203; }

      { name = "ai-claude guest shares /home/jason/code";
        ok = hasShare "ai-claude" "/home/jason/code"; }

      { name = "virbr-ai bridge is declared on host";
        ok = cfg.networking.bridges ? virbr-ai; }

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
