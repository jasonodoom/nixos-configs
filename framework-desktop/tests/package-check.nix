# Simple package validation test
{ pkgs ? import <nixpkgs> {} }:

pkgs.runCommand "package-check" {} ''
  echo "Testing essential KDE packages exist..."

  # Test that key KDE packages are available
  test -n "${pkgs.kdePackages.plasma-desktop}"
  test -n "${pkgs.kdePackages.kwin}"
  test -n "${pkgs.kdePackages.sddm}"
  test -n "${pkgs.kdePackages.konsole}"
  test -n "${pkgs.kdePackages.dolphin}"

  echo "All packages found successfully"
  echo "success" > $out
''