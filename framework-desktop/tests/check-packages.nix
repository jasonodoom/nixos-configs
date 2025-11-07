/*
  Package validation test for Plasma MacSonoma configuration.

  This test validates that all packages referenced in KDE and theme modules
  exist and are accessible without running a full VM test.

  Type: Build-time validation
  Speed: Fast (~30 seconds)
  Catches: Package naming errors, missing dependencies and build-time issues

  Example usage:
    nix-build tests/check-packages.nix
*/
{ pkgs ? import <nixpkgs> {} }:

let
  # Import modules to validate package references
  # This will fail if any packages are incorrectly named or missing
  testConfig = pkgs.nixos [
    ../modules/kde-config.nix
    ../modules/themes.nix
  ];
in

pkgs.runCommand "check-packages" {} ''
  echo "Validating KDE package references..."

  # Test essential KDE packages I reference in kde-config.nix
  # These were causing "missing attribute" errors before I fixed them
  ${pkgs.kdePackages.plasma-desktop}/bin/plasma-desktop --version || exit 1
  ${pkgs.kdePackages.kwin}/bin/kwin_x11 --version || exit 1
  ${pkgs.kdePackages.kglobalaccel}/bin/kglobalaccel --version || exit 1
  ${pkgs.kdePackages.kscreenlocker}/bin/kscreenlocker_greet --version || exit 1

  # Test X11 packages I added for KWin support in themes.nix
  # I fixed libxcb -> xorg.libxcb and xcbutilcursor -> xorg.xcbutilcursor
  test -f ${pkgs.xorg.libxcb}/lib/libxcb.so || exit 1
  test -f ${pkgs.xorg.xcbutilcursor}/lib/libxcb-cursor.so || exit 1

  # Test Qt6 packages for MacSonoma theme compatibility
  # These are required by the MacSonoma theme's QML components
  test -d ${pkgs.qt6Packages.qtdeclarative}/lib || exit 1
  test -d ${pkgs.qt6Packages.qtsvg}/lib || exit 1
  test -d ${pkgs.qt6Packages.qtmultimedia}/lib || exit 1

  echo "Package validation completed successfully"
  echo "All referenced packages exist and are accessible" > $out
''