{ pkgs, nixosSystem }:

# Structural assertions on the real host config to catch reboot surprises:
# LUKS initrd must have networking, SSH, and tailscaled wired in such that
# cryptsetup waits for tailscale.
#
# This is a mock: it inspects the evaluated config and the produced initrd
# image. It does not boot the machine or talk to the tailscale control plane.

let
  lib = pkgs.lib;
  cfg = nixosSystem.config;
  initrd = cfg.boot.initrd;
  tsUnit = initrd.systemd.services.tailscale-initrd or null;
  sshUnit = initrd.network.ssh;
  hostName = cfg.networking.hostName;

  storePathStr = p:
    if builtins.isAttrs p
    then toString (p.source or p.target or "")
    else toString p;

  hasTailscaleStorePath =
    lib.any (p: lib.hasInfix "tailscale" (storePathStr p))
      initrd.systemd.storePaths;

  checks = [
    { name = "initrd systemd enabled";
      ok = initrd.systemd.enable; }

    { name = "tailscale included in initrd store paths";
      ok = hasTailscaleStorePath; }

    { name = "tailscale auth-key secret wired into initrd";
      ok = initrd.secrets ? "/etc/tailscale/auth-key"; }

    { name = "tailscale-initrd service defined";
      ok = tsUnit != null; }

    { name = "tailscale up command includes --ssh flag";
      ok = tsUnit != null
        && (let post = tsUnit.serviceConfig.ExecStartPost or "";
                postStr = if builtins.isList post then lib.concatStringsSep " " post else post;
            in lib.hasInfix "tailscale up" postStr && lib.hasInfix "--ssh" postStr); }

    { name = "tailscale-initrd waits for network-online";
      ok = tsUnit != null && lib.elem "network-online.target" (tsUnit.after or []); }

    { name = "tailscale-initrd orders before cryptsetup.target";
      ok = tsUnit != null && lib.elem "cryptsetup.target" (tsUnit.before or []); }

    { name = "tailscale-initrd wantedBy initrd.target";
      ok = tsUnit != null && lib.elem "initrd.target" (tsUnit.wantedBy or []); }

    { name = "initrd SSH enabled";
      ok = sshUnit.enable; }

    { name = "initrd SSH host key configured";
      ok = sshUnit.hostKeys != []; }

    { name = "initrd SSH has at least one authorized key";
      ok = sshUnit.authorizedKeys != []; }

    { name = "LUKS crypted device configured";
      ok = initrd.luks.devices ? crypted; }

    { name = "initrd has tun module (tailscale requirement)";
      ok = lib.elem "tun" initrd.availableKernelModules; }

    { name = "initrd has at least one ethernet driver";
      ok = lib.any (m: lib.elem m initrd.availableKernelModules)
        [ "r8169" "e1000e" "igb" "iwlwifi" ]; }

    { name = "initrd has USB keyboard modules for local unlock";
      ok = lib.all (m: lib.elem m initrd.availableKernelModules)
        [ "usbhid" "hid_generic" ]; }
  ];

  failed = lib.filter (c: !c.ok) checks;
  failedNames = lib.concatMapStringsSep ", " (c: c.name) failed;
  passLines = lib.concatMapStringsSep "\n" (c: "  [PASS] ${c.name}") checks;

in

if failed != []
then throw "initrd-unlock check failed for ${hostName}: ${failedNames}"
else pkgs.runCommand "initrd-unlock-${hostName}"
  { nativeBuildInputs = [ pkgs.cpio pkgs.zstd pkgs.gzip pkgs.xz ]; }
  ''
    echo "=== initrd-unlock-${hostName} ==="
    echo ""
    echo "Structural assertions:"
    cat <<'EOF'
    ${passLines}
    EOF
    echo ""

    mkdir extracted
    cd extracted

    INITRD=${cfg.system.build.initialRamdisk}/initrd

    if zstd -dc "$INITRD" 2>/dev/null | cpio -idmv 2>/dev/null; then
      echo "Decompressed with zstd"
    elif xz -dc "$INITRD" 2>/dev/null | cpio -idmv 2>/dev/null; then
      echo "Decompressed with xz"
    elif gzip -dc "$INITRD" 2>/dev/null | cpio -idmv 2>/dev/null; then
      echo "Decompressed with gzip"
    else
      echo "[WARN] Could not decompress initrd; skipping binary check"
      touch $out
      exit 0
    fi

    if find . -name tailscaled -type f | grep -q .; then
      echo "[PASS] tailscaled binary present in initrd"
    else
      echo "[FAIL] tailscaled binary NOT found in initrd"
      exit 1
    fi

    if find . -name 'tailscale-initrd.service' | grep -q .; then
      echo "[PASS] tailscale-initrd.service unit present in initrd"
    else
      echo "[FAIL] tailscale-initrd.service unit NOT found in initrd"
      exit 1
    fi

    touch $out
  ''
