# Default overlay file
{ inputs, ... }:

final: prev: {
  # Import all overlays
  inherit (import ./claude-code.nix final prev) claude-code;

  # Use Tailscale from nixpkgs-unstable for latest version
  tailscale = (import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; }).tailscale;

  # Use Forgejo from nixpkgs-unstable for latest major (v15+)
  forgejo = (import inputs.nixpkgs-unstable { system = final.stdenv.hostPlatform.system; }).forgejo;

  # LLM agents from numtide/llm-agents.nix
  llm-agents = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system};

  # Promote individual agents to top-level pkgs attrs so the AI microvm
  # module can reference pkgs.codex / pkgs.gemini-cli uniformly alongside
  # pkgs.claude-code.
  codex = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.codex;
  gemini-cli = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.gemini-cli;

  # The .deb unpack tries to preserve the setuid bit on chrome-sandbox,
  # which fails outside a CAP_FSETID context (any nix build sandbox,
  # incl. our CI runner and Hydra). --no-same-permissions drops the
  # setuid bit. Chrome on modern kernels uses the user-namespace
  # sandbox instead of the SUID sandbox, so the bit is not required
  # at runtime. Drop this overlay once Hydra publishes a cached
  # google-chrome-149+ build that I can substitute instead.
  google-chrome = prev.google-chrome.overrideAttrs (old: {
    unpackPhase = ''
      runHook preUnpack
      ${prev.binutils-unwrapped}/bin/ar x $src
      tar xf data.tar.xz --no-same-permissions
      runHook postUnpack
    '';
  });

  # Bundled chrome-sandbox has setuid; tar default xf fails in any
  # nix build sandbox (no CAP_FSETID). --no-same-permissions alone
  # broke later phases that needed read perms on resources/app/*.
  # Restore a permissive default mask + clear setuid/setgid after.
  # Override only the bit that fails (tar setting setuid). Then let
  # the stock genericBuild logic find sourceRoot and cd into it; the
  # default unpackPhase resets sourceRoot to the dir tar created.
  vscode = prev.vscode.overrideAttrs (old: {
    unpackCmd = ''
      tar xf $curSrc --no-same-permissions
      ${prev.findutils}/bin/find . -type d -exec chmod a+rx {} +
      ${prev.findutils}/bin/find . -type f \( -perm -4000 -o -perm -2000 \) -exec chmod ug-s {} +
    '';
  });

  # The functional test suite calls `unshare` to set up per-test
  # namespace sandboxes. CI runners that lack
  # kernel.unprivileged_userns_clone (the self-hosted vega container)
  # fail every test with "Operation not permitted". Disable the check
  # phase so the closure can be built; nix itself is unaffected.
  nix = prev.nix.overrideAttrs (old: {
    doCheck = false;
    doInstallCheck = false;
  });
}
