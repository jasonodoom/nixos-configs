# User-specific configuration 
{ config, pkgs, lib, inputs, ... }:

{
  # User account
  users.users.jason = {
    isNormalUser = true;
    description = "Jason Odoom";
    extraGroups = [
      "wheel"           # sudo/doas access
      "audio"           # audio devices
      "video"           # video devices
      "networkmanager"  # network management
      "dialout"         # serial devices
      "docker"          # docker daemon
      "libvirtd"        # virtualization
      "kvm"             # kvm virtualization
      "input"           # input devices
    ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKQRbcTH0OZCQciQLgFXDqqqbc0383pXA/65JlZqpCyQ jason@scalene.local"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDdTRD5etaWB3UmGiJ2cD/TVCn/asEw7c8frhAYDOhsb1bmEp7z3mG7gKFwepBaWFX3D7aXXirTTNsnKd7AsM5riQQg1tZ5qtmT+nEmpDhi1WVtFm89jc0ezyJN1SnlsCUEhQ0twn4qzR+PnjRVE1E4KTpbwTCapgMl9w4iCEQikaPWWcg9u+CRGNLaehgM7Jm5jKdVoIa258wNgvCrNZcba4LCccz1PK5j4j1uu3sr400CatIEkWe+aqiDCBIamFPXuJqZy1gb4+dqk1wKPJqn8L9WFD6j5mDarrIaHHmy7rnviPinbpLoCE3eksxAVeI1QjI8uPXyrn4GtUQNSNBMZPu2DTCZSo5bG5NbcE2Di9KSkW8SQJg0dYgZSJjssp5qkT9uFx7AnLfvIlR3+IQA45cXnM+jXCikNbGPLMenv8jjMrSke73hxr8T6rsjO2FGT3tWeiDBN5B59wgWY+bbrExOcFe2/cClYfBFzdF9d800Xg6+fN7E6gamTyrNNRL68f+sawuTDBrWggPJFFcHvQMd4zxE/ujbyCgy+11U8M5AAU/y6/Aa2XUt0jnEXgMXBpo7M3/5OWRzzyCO2RwtDWVxrJXPW9xYGvSoPAfDmdi0VNiGyldvbw4HHcHiFqftTCrNzMbR/QbjsuF4HMGI4fXddWYOFlNHbv+X+O2/kQ== cardno:5252959"
    ];
    # Password will be managed via agenix secrets (disabled for initial install)
    # passwordFile = config.age.secrets.jason-password.path;
  };

  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      PubkeyAuthentication = true;
    };
  };
  # Programs configuration
  programs = {
    # Git configuration
    git = {
      enable = true;
      config = {
        # User information
        user = {
          name = "Jason Odoom";
          email = "jasonodoom@riseup.net";
          username = "jasonodoom";
          signingkey = "C944F52C851F5243";
        };

        # Commit settings
        commit.gpgSign = true;
        init.defaultBranch = "main";

        # Core settings
        core = {
          editor = "/run/current-system/sw/bin/vim";
          whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
          pager = "less";
        };

        # Web and instaweb
        web.browser = "firefox";
        instaweb.httpd = "apache2 -f";

        # Rerere settings
        rerere = {
          enabled = 1;
          autoupdate = 1;
        };

        # Color settings
        color = {
          ui = "auto";
          branch = {
            current = "yellow bold";
            local = "green bold";
            remote = "cyan bold";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old = "red bold";
            new = "green bold";
            whitespace = "red reverse";
          };
          status = {
            added = "green bold";
            changed = "yellow bold";
            untracked = "red bold";
          };
        };

        # Diff and merge tools
        diff.tool = "kdiff3";
        difftool.prompt = false;

        # Delta configuration
        delta = {
          features = "line-numbers decorations";
          line-numbers = true;
        };
        "delta \"decorations\"" = {
          minus-style = "red bold normal";
          plus-style = "green bold normal";
          minus-emph-style = "white bold red";
          minus-non-emph-style = "red bold normal";
          plus-emph-style = "white bold green";
          plus-non-emph-style = "green bold normal";
          file-style = "yellow bold none";
          file-decoration-style = "yellow box";
          hunk-header-style = "magenta bold";
          hunk-header-decoration-style = "magenta box";
          minus-empty-line-marker-style = "normal normal";
          plus-empty-line-marker-style = "normal normal";
          line-numbers-right-format = "{np:^4}│ ";
        };

        # GitHub settings
        github = {
          user = "jasonodoom";
          token = "token";
        };

        # Git flow
        "gitflow \"prefix\"".versiontag = "v";

        # Sequence editor
        sequence.editor = "interactive-rebase-tool";

        # GPG settings
        gpg.program = "gpg";

        # Git LFS
        "filter \"lfs\"" = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };

        # Extensive aliases from your .gitconfig
        alias = {
          # Add operations
          a = "add --all";
          ai = "add -i";

          # Apply operations
          ap = "apply";
          as = "apply --stat";
          ac = "apply --check";

          # AM operations
          ama = "am --abort";
          amr = "am --resolved";
          ams = "am --skip";

          # Branch operations
          b = "branch";
          ba = "branch -a";
          bd = "branch -d";
          bdd = "branch -D";
          br = "branch -r";
          bc = "rev-parse --abbrev-ref HEAD";
          bu = "!git rev-parse --abbrev-ref --symbolic-full-name \"@{u}\"";
          bs = "!git-branch-status";

          # Commit operations
          c = "commit";
          ca = "commit -a";
          cm = "commit -m";
          cam = "commit -am";
          cem = "commit --allow-empty -m";
          cd = "commit --amend";
          cad = "commit -a --amend";
          ced = "commit --allow-empty --amend";

          # Clone operations
          cl = "clone";
          cld = "clone --depth 1";
          clg = "!sh -c 'git clone git://github.com/$1 $(basename $1)' -";
          clgp = "!sh -c 'git clone git@github.com:$1 $(basename $1)' -";
          clgu = "!sh -c 'git clone git@github.com:$(git config --get user.username)/$1 $1' -";

          # Cherry-pick operations
          cp = "cherry-pick";
          cpa = "cherry-pick --abort";
          cpc = "cherry-pick --continue";

          # Diff operations
          d = "diff";
          dp = "diff --patience";
          dc = "diff --cached";
          dk = "diff --check";
          dck = "diff --cached --check";
          dt = "difftool";
          dct = "difftool --cached";

          # Fetch operations
          f = "fetch";
          fo = "fetch origin";
          fu = "fetch upstream";

          # Format patch
          fp = "format-patch";

          # Fsck
          fk = "fsck";

          # Grep
          g = "grep -p";

          # Log operations
          l = "log --oneline";
          lg = "log --oneline --graph --decorate";

          # List files
          ls = "ls-files";
          lsf = "!git ls-files | grep -i";

          # Merge operations
          m = "merge";
          ma = "merge --abort";
          mc = "merge --continue";
          ms = "merge --skip";

          # Checkout operations
          o = "checkout";
          om = "checkout master";
          ob = "checkout -b";
          opr = "!sh -c 'git fo pull/$1/head:pr-$1 && git o pr-$1'";

          # Prune
          pr = "prune -v";

          # Push operations
          ps = "push";
          psf = "push -f";
          psu = "push -u";
          pst = "push --tags";
          pso = "push origin";
          psao = "push --all origin";
          psfo = "push -f origin";
          psuo = "push -u origin";
          psom = "push origin master";
          psaom = "push --all origin master";
          psfom = "push -f origin master";
          psuom = "push -u origin master";
          psoc = "!git push origin $(git bc)";
          psaoc = "!git push --all origin $(git bc)";
          psfoc = "!git push -f origin $(git bc)";
          psuoc = "!git push -u origin $(git bc)";
          psdc = "!git push origin :$(git bc)";

          # Pull operations
          pl = "pull";
          pb = "pull --rebase";
          plo = "pull origin";
          pbo = "pull --rebase origin";
          plom = "pull origin master";
          ploc = "!git pull origin $(git bc)";
          pbom = "pull --rebase origin master";
          pboc = "!git pull --rebase origin $(git bc)";
          plu = "pull upstream";
          plum = "pull upstream master";
          pluc = "!git pull upstream $(git bc)";
          pbum = "pull --rebase upstream master";
          pbuc = "!git pull --rebase upstream $(git bc)";

          # Rebase operations
          rb = "rebase";
          rba = "rebase --abort";
          rbc = "rebase --continue";
          rbi = "rebase --interactive";
          rbs = "rebase --skip";

          # Reset operations
          re = "reset";
          rh = "reset HEAD";
          reh = "reset --hard";
          rem = "reset --mixed";
          res = "reset --soft";
          rehh = "reset --hard HEAD";
          remh = "reset --mixed HEAD";
          resh = "reset --soft HEAD";
          rehom = "reset --hard origin/master";

          # Remote operations
          r = "remote";
          ra = "remote add";
          rr = "remote rm";
          rv = "remote -v";
          rn = "remote rename";
          rp = "remote prune";
          rs = "remote show";
          rao = "remote add origin";
          rau = "remote add upstream";
          rro = "remote remove origin";
          rru = "remote remove upstream";
          rso = "remote show origin";
          rsu = "remote show upstream";
          rpo = "remote prune origin";
          rpu = "remote prune upstream";

          # Remove operations
          rmf = "rm -f";
          rmrf = "rm -r -f";

          # Status operations
          s = "status";
          sb = "status -s -b";

          # Stash operations
          sa = "stash apply";
          sc = "stash clear";
          sd = "stash drop";
          sl = "stash list";
          sp = "stash pop";
          ss = "stash save";
          ssk = "stash save -k";
          sw = "stash show";
          st = "!git stash list | wc -l 2>/dev/null | grep -oEi '[0-9][0-9]*'";

          # Tag operations
          t = "tag";
          td = "tag -d";

          # Show operations
          w = "show";
          wp = "show -p";
          wr = "show -p --no-color";

          # SVN operations
          svnr = "svn rebase";
          svnd = "svn dcommit";
          svnl = "svn log --oneline --show-commit";

          # Submodule operations
          subadd = "!sh -c 'git submodule add git://github.com/$1 $2/$(basename $1)' -";
          subrm = "!sh -c 'git submodule deinit -f -- $1 && rm -rf .git/modules/$1 && git rm -f $1' -";
          subup = "submodule update --init --recursive";
          subpull = "!git submodule foreach git pull --tags -f origin master";

          # Assume operations
          assume = "update-index --assume-unchanged";
          unassume = "update-index --no-assume-unchanged";
          assumed = "!git ls -v | grep ^h | cut -c 3-";
          unassumeall = "!git assumed | xargs git unassume";
          assumeall = "!git status -s | awk {'print $2'} | xargs git assume";

          # Utility operations
          bump = "!sh -c 'git commit -am \"Version bump v$1\" && git psuoc && git release $1' -";
          release = "!sh -c 'git tag v$1 && git pst' -";
          unrelease = "!sh -c 'git tag -d v$1 && git pso :v$1' -";
          merged = "!sh -c 'git o master && git plom && git bd $1 && git rpo' -";
          aliases = "!git config -l | grep alias | cut -c 7-";
          snap = "!git stash save 'snapshot: $(date)' && git stash apply 'stash@{0}'";
          bare = "!sh -c 'git symbolic-ref HEAD refs/heads/$1 && git rm --cached -r . && git clean -xfd' -";
          whois = "!sh -c 'git log -i -1 --author=\"$1\" --pretty=\"format:%an <%ae>\"' -";
          serve = "daemon --reuseaddr --verbose --base-path=. --export-all ./.git";
          behind = "!git rev-list --left-only --count $(git bu)...HEAD";
          ahead = "!git rev-list --right-only --count $(git bu)...HEAD";
          ours = "!f() { git checkout --ours $@ && git add $@; }; f";
          theirs = "!f() { git checkout --theirs $@ && git add $@; }; f";
          subrepo = "!sh -c 'git filter-branch --prune-empty --subdirectory-filter $1 master' -";
          human = "name-rev --name-only --refs=refs/heads/*";
        };
      };
    };

    zsh.enable = true;

    # Direnv for development environments
    direnv.enable = true;

  };

  # Environment configuration
  environment = {
    # Global environment variables
    variables = {
      EDITOR = "vim";
      LANG = "en_US.UTF-8";
      GPG_TTY = "$(tty)";

      # Development tools
      MOB_TIMER_ROOM = "diligent-flea-68";
    };

    # Shell initialization for all shells
    interactiveShellInit = ''
      # GPG and SSH agent configuration
      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      # History settings for bash
      export HISTCONTROL=ignoreboth:erasedups
      export HISTFILESIZE=4096
      export HISTSIZE=4096
      export PROMPT_COMMAND="history -n; history -w; history -c; history -r"

      # Path additions
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"

      # Bash silence deprecation warning (macOS)
      export BASH_SILENCE_DEPRECATION_WARNING=1

      # System update alias
      alias update-system='doas nixos-rebuild switch --flake "github:jasonodoom/nixos-configs?dir=framework-desktop#perdurabo" --refresh'

      # Run vocab on shell start (if available)
      # [ -x /etc/vocab ] && /etc/vocab  # Temporarily disabled for compatibility
    '';

    # Bash-specific prompt configuration
    shellInit = ''
      # Colors for bash prompt
      RED="\[\033[0;31m\]"
      BROWN="\[\033[0;33m\]"
      GREY="\[\033[0;97m\]"
      GREEN="\[\033[0;32m\]"
      BLUE="\[\033[0;34m\]"
      PS_CLEAR="\[\033[0m\]"

      # Git branch parser for bash
      parse_git_branch() {
        [ -d .git ] || return 1
        git symbolic-ref HEAD 2> /dev/null | sed 's#\(.*\)\/\([^\/]*\)$# \2#'
      }

      # Colored prompt for bash
      if [ -n "$BASH_VERSION" ]; then
        PS1="''${GREEN}\W\$(parse_git_branch) → ''${GREY}"
        PS2="\[[33;1m\]continue \[[0m[1m\]> "
      fi
    '';
  };
}