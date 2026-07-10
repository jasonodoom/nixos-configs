# Restrict macOS Remote Login (sshd) to the Tailscale network only and
# harden it to key-only auth.
#
# macOS runs sshd via launchd socket activation bound to ALL interfaces,
# so `ListenAddress` in sshd_config is ignored. The network restriction
# is therefore enforced with pf: inbound tcp/22 is allowed only from the
# Tailscale CGNAT range (100.64.0.0/10) and dropped on every other
# interface (Wi-Fi, LAN, etc). Filtering by source range is more stable
# than by interface name — the tailscale utun index changes across
# reconnects, but tailnet peers always carry a 100.64.0.0/10 source.
#
# Remote Login itself is toggled in System Settings -> General ->
# Sharing -> Remote Login (or `sudo systemsetup -setremotelogin on`);
# this module only hardens and firewalls it. It does NOT touch the
# tailnet connection, so applying it is non-disruptive.
{ config, pkgs, lib, ... }:

let
  # pf anchor: pass SSH from Tailscale peers, drop it everywhere else.
  # `quick` makes the first match decisive, so the pass wins for tailnet
  # traffic and the block wins for everything else.
  sshAnchor = ''
    pass in quick proto tcp from 100.64.0.0/10 to any port 22 flags S/SA keep state
    block in quick proto tcp to any port 22
  '';

  # A pf ruleset that reproduces the macOS defaults and appends our
  # anchor, so loading it does not drop Apple's built-in rules. `set
  # skip on lo0` keeps loopback (and local tooling) unaffected.
  pfConf = ''
    set skip on lo0
    scrub-anchor "com.apple/*" all fragment reassemble
    nat-anchor "com.apple/*" all
    rdr-anchor "com.apple/*" all
    dummynet-anchor "com.apple/*" all
    anchor "com.apple/*" all
    load anchor "com.apple" from "/etc/pf.anchors/com.apple"
    anchor "ssh-tailnet"
    load anchor "ssh-tailnet" from "/etc/pf.anchors/ssh-tailnet"
  '';
in
{
  # Key-only, no-root sshd hardening. macOS sshd includes
  # /etc/ssh/sshd_config.d/*, so this drop-in is picked up.
  environment.etc."ssh/sshd_config.d/100-tailnet-hardening.conf".text = ''
    # Managed by nixos-configs (modules/network/ssh-tailnet.nix).
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    ChallengeResponseAuthentication no
    PermitRootLogin no
  '';

  # pf anchor + a base ruleset that references it.
  environment.etc."pf.anchors/ssh-tailnet".text = sshAnchor;
  environment.etc."pf-ssh-tailnet.conf".text = pfConf;

  # Load the ruleset at boot so the tailnet-only restriction survives
  # reboots and OS updates (which reset /etc/pf.conf). If another service
  # flushes pf, a reboot (or relaunching this daemon) reapplies it.
  launchd.daemons.pf-ssh-tailnet = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/sbin/pfctl -E -f /etc/pf-ssh-tailnet.conf"
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/pf-ssh-tailnet.log";
      StandardErrorPath = "/var/log/pf-ssh-tailnet.log";
    };
  };
}
