# Hyprland keyboard and mouse bindings
{ config, pkgs, lib, ... }:

{
  # Add keybindings to the main Hyprland configuration
  environment.etc."hypr/hyprland.conf".text = lib.mkAfter ''

    # Keybindings
    $mod = SUPER

    # Program shortcuts
    bind = $mod, Return, exec, kitty
    bind = $mod, T, exec, kitty
    bind = $mod, Q, killactive
    bind = $mod, M, exit
    bind = $mod, E, movetoworkspace, special:minimized
    bind = $mod, V, togglefloating
    bind = $mod, R, exec, rofi -show drun
    bind = $mod, P, pseudo
    bind = $mod, J, togglesplit

    # Primary launcher (nwg-drawer) - Super key alone
    bindr = SUPER, SUPER_L, exec, nwg-drawer -mb 200 -mt 200 -mr 200 -ml 200

    # Emergency fallback shortcuts
    bind = $mod ALT, T, exec, kitty
    bind = $mod ALT, R, exec, rofi -show drun

    # Emoji picker
    bind = $mod, period, exec, rofimoji

    # Rofi extensions
    bind = $mod, C, exec, rofi -show calc
    bind = $mod SHIFT, T, exec, rofi -show top

    # Waybar controls
    bind = $mod SHIFT, B, exec, waybar
    bind = $mod CTRL, B, exec, pkill waybar

    # Dock controls
    bind = $mod SHIFT, D, exec, nwg-dock-hyprland
    bind = $mod CTRL, D, exec, pkill nwg-dock-hyprland

    # Hyprland reload
    bind = $mod CTRL, R, exec, hyprctl reload

    # Move focus
    bind = $mod, left, movefocus, l
    bind = $mod, right, movefocus, r
    bind = $mod, up, movefocus, u
    bind = $mod, down, movefocus, d

    # Switch workspaces
    bind = $mod, 1, workspace, 1
    bind = $mod, 2, workspace, 2
    bind = $mod, 3, workspace, 3
    bind = $mod, 4, workspace, 4
    bind = $mod, 5, workspace, 5
    bind = $mod, 6, workspace, 6
    bind = $mod, 7, workspace, 7
    bind = $mod, 8, workspace, 8
    bind = $mod, 9, workspace, 9
    bind = $mod, 0, workspace, 10

    # Move windows to workspaces
    bind = $mod SHIFT, 1, movetoworkspace, 1
    bind = $mod SHIFT, 2, movetoworkspace, 2
    bind = $mod SHIFT, 3, movetoworkspace, 3
    bind = $mod SHIFT, 4, movetoworkspace, 4
    bind = $mod SHIFT, 5, movetoworkspace, 5
    bind = $mod SHIFT, 6, movetoworkspace, 6
    bind = $mod SHIFT, 7, movetoworkspace, 7
    bind = $mod SHIFT, 8, movetoworkspace, 8
    bind = $mod SHIFT, 9, movetoworkspace, 9
    bind = $mod SHIFT, 0, movetoworkspace, 10

    # Advanced window management with animation triggers
    bind = $mod ALT, left, movewindow, l
    bind = $mod ALT, right, movewindow, r
    bind = $mod ALT, up, movewindow, u
    bind = $mod ALT, down, movewindow, d

    # Resize windows with smooth animations
    bind = $mod CTRL, left, resizeactive, -40 0
    bind = $mod CTRL, right, resizeactive, 40 0
    bind = $mod CTRL, up, resizeactive, 0 -40
    bind = $mod CTRL, down, resizeactive, 0 40

    # Special workspace (scratchpad) with dramatic entrance
    bind = $mod, grave, togglespecialworkspace, magic
    bind = $mod SHIFT, grave, movetoworkspace, special:magic

    # Center floating windows
    bind = $mod, C, centerwindow

    # Pin windows (always on top with glow effect)
    bind = $mod SHIFT, P, pin

    # Scroll through workspaces
    bind = $mod, mouse_down, workspace, e+1
    bind = $mod, mouse_up, workspace, e-1

    # Screenshots
    bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
    bind = $mod, Print, exec, grim - | wl-copy

    # Screen lock binding - ultimate modern Hyprland lock
    bind = $mod, L, exec, hyprlock

    # Power management shortcuts
    bind = $mod SHIFT, L, exec, loginctl lock-session
    bind = $mod SHIFT, Q, exec, hyprctl dispatch exit
    bind = $mod SHIFT, S, exec, systemctl suspend
    bind = $mod, Escape, exec, wlogout --layer-shell
    bind = $mod SHIFT, P, exec, wlogout --layer-shell

    # Direct power shortcuts (with confirmation)
    bind = $mod CTRL SHIFT, R, exec, systemctl reboot
    bind = $mod CTRL SHIFT, S, exec, systemctl poweroff

    # Mouse binds
    bindm = $mod, mouse:272, movewindow
    bindm = $mod, mouse:273, resizewindow

    # hych plugin bindings for window minimization
    bind = ALT, m, hych:minimize                    # Minimize window (Alt+M)
    bind = ALT SHIFT, m, hych:restore_minimize      # Manual restore window
    bind = ALT, w, hych:toggle_restore_window       # Toggle special workspace

    # Update Super+E to use hych minimize instead
    bind = $mod, E, hych:minimize                   # Minimize to dock (Super+E)
  '';
}