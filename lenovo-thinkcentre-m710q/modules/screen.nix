# GNU Screen Configuration - Traditional Terminal Multiplexer
{ config, pkgs, ... }:

{
  # Install GNU Screen
  environment.systemPackages = with pkgs; [
    screen
  ];

  # .screenrc configuration
  environment.etc."screenrc".text = ''
    term screen-256color
    #turn startup message off
    startup_message off

    # Add stuff to xterm (and cousins) title bars.    This is a moderate abuse of the
    # hardstatus feature--it just puts the hardstatus stuff into an xterm title
    # bar.
    termcapinfo xterm*|Eterm|mlterm 'hs:ts=\E]0;:fs=\007:ds=\E]0;screen\007'
    defhstatus "screen ^E (^Et) | $USER@^EH"
    hardstatus off
    #scrollback
    defscrollback 5000

    #Start with shell
    #shell /opt/apps/shells/zsh/5.0.0/bin/zsh

    # Give me some info at the bottom of the screen.  Since hardstatus is in use by
    # the above xterm title hack, the only source of information left is the
    # caption that normally only gets displayed if you have split windows.
    # e.g.:
    # 11:50|Mon|Jan 06|aragorn f  3$ mutt  4$ centericq  5$* less  6-&!$ man  7$ xe
    # (Current window is in reverse bold.)
    # See bottom of file for more complete description.
    caption always "%?%F%{-b bc}%:%{-b bb}%?%C|%D|%M %d|%H%?%F%{+u wb}%? %L=%-Lw%45>%{+b by}%n%f* %t%{-}%+Lw%-0<"

    # ^l gives a navigable window list
    # ^n starts a new screen
    bindkey ^L windowlist -b
    bindkey ^N screen

    # caption description:
    # caption always "%?%F%{-b bc}%:%{-b bb}%?%C|%D|%M %d|%H%?%F%{+u wb}%?
    # %L=%-Lw%45>%{+b by}%n%f* %t%{-}%+Lw%-0<"
    #
    # Anything I don't describe is treated literally.
    #
    # %?          - Start of a conditional statement.
    #  %F          - Use this part of the statement if the window has focus (i.e. it
    #        is the only window or the currently active one).
    #  %{-b bc}   - Turn off bold, blue foreground, cyan background.
    # %:          - else
    #  %{-b bb}   - Turn off bold, blue foreground, blue background (this obscures
    #        the text on non-focused windows and just gives a blue line).
    # %?          - End conditional statement.
    #  %C          - time (hh:mm, leading space) in 12 hour format
    #  %D          - Three-letter day-of-week appreviation
    #  %M          - Three-letter month appreviation
    #  %d          - Day of the month
    #  %H          - hostname
    #  %?          - Start of conditional statement.
    #   %F          - Use this part of the statement if the window has focus.
    #   %{+u wb}  - underlined, white foreground, blue background
    #  %?          - End conditional (if not focused, text remaind blue on blue).
    #    %L=      - truncation/padding point.  With the 'L' qualifier, basically
    #        just acts as a reference point.     Further truncation/padding is
    #        done relative to here, not the beginning of the string
    #    %-Lw     - window list up to but not including the current window (-),
    #        show window flags (L)
    #    %45>     - truncation/padding marker; place this point about 45% of the
    #        way into the display area (45)
    #    %{+b by} - add bold (still underlined from before), blue foreground,
    #        yellow background
    #      %n     - number of the current window
    #      %f     - flags for current window
    #      %t     - title of current window
    #    %{-}     - undo last color change (so now we're back to underlined white
    #        on blue)  (technically, this is a pop; a second invocation
    #        would drop things back to unadorned blue on cyan)
    #    %+Lw     - window list from the next window on (-), show window flags (L)
    #    %-0<     - truncation/padding point.  Place this point zero spaces (0)
    #        from the right margin (-).
  '';

  # Create symlink to system screenrc for user accessibility
  systemd.user.services.screen-config = {
    description = "Setup Screen configuration";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mkdir -p $HOME && ln -sf /etc/screenrc $HOME/.screenrc'";
    };
  };
}
