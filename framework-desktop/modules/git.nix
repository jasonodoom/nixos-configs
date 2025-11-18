# Git Configuration - Framework Desktop
{ config, pkgs, ... }:

{
  # Install git and related tools
  environment.systemPackages = with pkgs; [
    git
    git-lfs
    gh
  ];

  # System-wide git configuration for the user
  users.users.jason.packages = [ pkgs.git ];

  # Git configuration through home-manager style config
  programs.git = {
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
        editor = "/run/current-system/sw/bin/nvim";
        whitespace = "fix,-indent-with-non-tab,trailing-space,cr-at-eol";
        pager = "delta";
      };

      # Delta configuration
      delta = {
        navigate = true;
        light = false;
        side-by-side = false;
        line-numbers = true;
        syntax-theme = "Dracula";
        features = "decorations";
      };

      # Delta decorations
      "delta \"decorations\"" = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "cyan box ul";
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
          untracked = "cyan bold";
        };
      };

      # Push settings
      push = {
        default = "matching";
        followTags = true;
      };

      # Merge and diff settings
      merge = {
        stat = true;
        tool = "vimdiff";
      };

      diff = {
        renames = "copies";
        mnemonicprefix = true;
        tool = "vimdiff";
      };

      # Branch settings
      branch.autosetuprebase = "always";

      # Apply settings
      apply = {
        whitespace = "fix";
      };

      # Help settings
      help.autocorrect = 1;

      # GitHub specific settings
      github = {
        user = "jasonodoom";
      };

      # Git flow settings
      "gitflow \"prefix\"".versiontag = "v";

      # Git LFS settings
      "filter \"lfs\"" = {
        required = true;
        clean = "git-lfs clean -- %f";
        smudge = "git-lfs smudge -- %f";
        process = "git-lfs filter-process";
      };

      # Extensive aliases from your .gitconfig
      alias = {
        # Basic shortcuts
        a = "add";
        ai = "add --interactive";
        ap = "add --patch";
        au = "add --update";

        # Branch operations
        b = "branch";
        ba = "branch -a";
        bd = "branch -d";
        bD = "branch -D";
        br = "branch -r";
        bc = "rev-parse --abbrev-ref HEAD";
        bu = "!git rev-parse --abbrev-ref --symbolic-full-name \"@{u}\"";
        bs = "!git-branch-status";

        # Checkout operations
        c = "commit";
        ca = "commit -a";
        cm = "commit -m";
        cam = "commit -am";
        cem = "commit --allow-empty -m";
        cd = "commit --amend";
        cad = "commit -a --amend";
        ced = "commit --allow-empty --amend";

        # Clone shortcuts
        cl = "clone";
        cld = "clone --depth 1";
        clg = "!sh -c 'git clone git://github.com/$1 $(basename $1)' -";
        clgp = "!sh -c 'git clone git@github.com:$1 $(basename $1)' -";
        clgu = "!sh -c 'git clone git@github.com:$(git config --get user.username)/$1 $1' -";

        # Checkout operations
        co = "checkout";
        cob = "checkout -b";
        com = "checkout master";
        cod = "checkout develop";
        cobd = "checkout -b develop";

        # Copy operations
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

        # Flow operations
        f = "flow";
        fo = "fetch origin";
        fu = "fetch upstream";

        # List operations
        ls = "ls-files";
        lsf = "!git ls-files | grep -i";

        # Log operations
        l = "log --oneline";
        lg = "log --oneline --graph --decorate";

        # Merge operations
        m = "merge";
        ma = "merge --abort";
        mc = "merge --continue";
        ms = "merge --skip";

        # Remote operations
        o = "checkout";
        ob = "checkout -b";
        opr = "!sh -c 'git fo pull/$1/head:pr-$1 && git o pr-$1'";

        # Push operations
        ps = "push";
        psa = "push --all";
        pst = "push --tags";
        psal = "push --all && git push --tags";
        psf = "push --force";
        psu = "push --set-upstream";
        pso = "push origin";
        psao = "push --all origin";
        psto = "push --tags origin";
        psoc = "!git push origin $(git bc)";
        psaoc = "!git push --all origin $(git bc)";
        psfoc = "!git push -f origin $(git bc)";
        psuoc = "!git push -u origin $(git bc)";
        psdc = "!git push origin :$(git bc)";

        # Pull operations
        pl = "pull";
        plo = "pull origin";
        ploc = "!git pull origin $(git bc)";
        plu = "pull upstream";
        pluc = "!git pull upstream $(git bc)";
        pboc = "!git pull --rebase origin $(git bc)";
        plom = "pull origin master";
        plum = "pull upstream master";
        pbuc = "!git pull --rebase upstream $(git bc)";

        # Rebase operations
        rb = "rebase";
        rba = "rebase --abort";
        rbc = "rebase --continue";
        rbi = "rebase --interactive";
        rbs = "rebase --skip";

        # Reset operations
        re = "reset";
        rh = "reset --hard";
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

        # Worktree operations
        w = "worktree";
        wa = "worktree add";
        wr = "worktree remove";
        wl = "worktree list";

        # Submodule operations
        sm = "submodule";
        smi = "submodule init";
        sma = "submodule add";
        sms = "submodule sync";
        smu = "submodule update";
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

        # Release operations
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
      };
    };
  };
}