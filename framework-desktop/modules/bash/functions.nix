# Bash Functions Configuration
{ config, pkgs, lib, ... }:

{
  environment.shellInit = ''
    # FZF widget functions for fish-like autocomplete
    __fzf_cd_widget() {
      local selected
      selected=$(find . -type d 2>/dev/null | fzf --preview 'ls -la {}' --preview-window=right:60%)
      if [[ -n "$selected" ]]; then
        cd "$selected" || return
        READLINE_LINE=""
        READLINE_POINT=0
      fi
    }

    __auto_suggest() {
      local current_line="$READLINE_LINE"
      local suggestion=""

      [[ ''${#current_line} -lt 2 ]] && return

      suggestion=$(HISTTIMEFORMAT= history | grep "^ *[0-9]\\+ *$current_line" | tail -1 | sed 's/^ *[0-9]* *//')

      if [[ -n "$suggestion" && "$suggestion" != "$current_line" ]]; then
        READLINE_LINE="$suggestion"
        READLINE_POINT=''${#suggestion}
      fi
    }

    # Extract function
    extract() {
      if [[ ! -f "$1" ]]; then
        echo "'$1' is not a valid file"
        return 1
      fi

      case "$1" in
        *.tar.bz2)   tar xjf "$1"    ;;
        *.tar.gz)    tar xzf "$1"    ;;
        *.tar.xz)    tar xJf "$1"    ;;
        *.bz2)       bunzip2 "$1"    ;;
        *.rar)       unrar x "$1"    ;;
        *.gz)        gunzip "$1"     ;;
        *.tar)       tar xf "$1"     ;;
        *.tbz2)      tar xjf "$1"    ;;
        *.tgz)       tar xzf "$1"    ;;
        *.zip)       unzip "$1"      ;;
        *.Z)         uncompress "$1" ;;
        *.7z)        7z x "$1"       ;;
        *.xz)        unxz "$1"       ;;
        *.lzma)      unlzma "$1"     ;;
        *)           echo "Unsupported archive format: $1" ;;
      esac
    }

    # Find files by name pattern
    ff() {
      find . -type f -iname "*$1*" 2>/dev/null
    }

    # System information function
    ii() {
      echo -e "\nYou are logged on \033[1;31m$(hostname)\033[0m"
      echo -e "\n\033[1;31mAdditional information:\033[0m"; uname -a
      echo -e "\n\033[1;31mUsers logged on:\033[0m"; w -hs | cut -d " " -f1 | sort | uniq
      echo -e "\n\033[1;31mCurrent date:\033[0m"; date
      echo -e "\n\033[1;31mMachine stats:\033[0m"; uptime
      echo -e "\n\033[1;31mMemory stats:\033[0m"; free -h
      echo -e "\n\033[1;31mDiskspace:\033[0m"; mydf / $HOME
      echo -e "\n\033[1;31mLocal IP Address:\033[0m"; my_ip
      echo -e "\n\033[1;31mOpen connections:\033[0m"; netstat -pan --inet 2>/dev/null || ss -tuln
      echo
    }

    # Pretty disk usage display
    mydf() {
      for partfs in "''${@:-/}"; do
        if [[ ! -d "$partfs" ]]; then
          echo -e "$partfs: No such file or directory"
          continue
        fi

        local info=($(df -P "$partfs" 2>/dev/null | awk 'END{ print $2,$3,$5 }'))
        local free=($(df -Pkh "$partfs" 2>/dev/null | awk 'END{ print $4 }'))
        local nbstars=$(( 20 * ''${info[1]} / ''${info[0]} ))
        local out="["

        for ((j=0; j<20; j++)); do
          if [[ $j -lt $nbstars ]]; then
            out="$out*"
          else
            out="$out-"
          fi
        done

        out="''${info[2]} $out] ($free free on $partfs)"
        echo -e "$out"
      done
    }

    # Get IP address
    my_ip() {
      local MY_IP=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
      echo "''${MY_IP:-Not connected}"
    }

    # File swapping function
    swap() {
      if [[ $# -ne 2 ]]; then
        echo "Usage: swap file1 file2"
        return 1
      fi

      if [[ ! -e "$1" ]] || [[ ! -e "$2" ]]; then
        echo "Both files must exist"
        return 1
      fi

      local tmpfile=$(mktemp)
      mv "$1" "$tmpfile" && mv "$2" "$1" && mv "$tmpfile" "$2"
    }

    # Improved disk usage function
    disk_usage() {
      local target=''${1:-.}
      if [[ ! -d "$target" ]]; then
        echo "Directory '$target' not found"
        return 1
      fi
      du -h "$target"/* 2>/dev/null | sort -hr | head -20
    }

    # Process search
    psg() {
      if [[ -z "$1" ]]; then
        echo "Usage: psg <pattern>"
        return 1
      fi
      ps aux | grep -v grep | grep --color=always "$1"
    }

    # VM disk storage directory
    VM_DISK_DIR="$HOME/.vm-disks"

    # Build NixOS Calamares ISO
    build-iso() {
      local de="''${1:-gnome}"
      local nixpkgs_path="''${2:-.}"

      if [[ "$de" != "gnome" && "$de" != "plasma" ]]; then
        echo "Usage: build-iso [gnome|plasma] [nixpkgs-path]"
        return 1
      fi

      local config="nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-''${de}.nix"
      [[ "$de" == "plasma" ]] && config="nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"

      echo "Building $de ISO from $nixpkgs_path..."
      nix-build '<nixpkgs/nixos>' \
        -A config.system.build.isoImage \
        -I nixos-config="$config" \
        -I nixpkgs="$nixpkgs_path"
    }

    # Test ISO in QEMU
    test-iso() {
      local persistent=false
      local boot_disk=false
      local efi_mode=false
      local iso=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
          -p|--persistent) persistent=true; shift ;;
          -b|--boot) boot_disk=true; shift ;;
          -e|--efi) efi_mode=true; shift ;;
          *) iso="$1"; shift ;;
        esac
      done

      mkdir -p "$VM_DISK_DIR"
      local disk="$VM_DISK_DIR/test-disk.qcow2"
      local efi_disk="$VM_DISK_DIR/test-disk-efi.qcow2"
      local ovmf_code="/run/libvirt/nix-ovmf/edk2-x86_64-code.fd"
      local ovmf_vars_src="/run/libvirt/nix-ovmf/edk2-i386-vars.fd"
      local ovmf_vars="$VM_DISK_DIR/edk2-vars.fd"

      # Use EFI disk if in EFI mode
      [[ "$efi_mode" == true ]] && disk="$efi_disk"

      # EFI firmware args
      local efi_args=""
      if [[ "$efi_mode" == true ]]; then
        if [[ ! -f "$ovmf_code" ]]; then
          echo "Error: OVMF not found at $ovmf_code"
          echo "Make sure libvirtd is enabled in your NixOS config"
          return 1
        fi
        if [[ ! -f "$ovmf_vars" ]]; then
          cp "$ovmf_vars_src" "$ovmf_vars"
          chmod 644 "$ovmf_vars"
        fi
        efi_args="-drive if=pflash,format=raw,readonly=on,file=$ovmf_code -drive if=pflash,format=raw,file=$ovmf_vars"
      fi

      # Boot from installed disk (post-installation)
      if [[ "$boot_disk" == true ]]; then
        if [[ ! -f "$disk" ]]; then
          echo "Error: No disk found at $disk. Run installation first."
          return 1
        fi
        echo "Connect from theophany: open vnc://perdurabo:5901"
        echo "Starting QEMU (booting from installed disk, EFI=$efi_mode)"
        qemu-system-x86_64 -enable-kvm -m 4G \
          $efi_args \
          -drive file="$disk",format=qcow2 \
          -vnc :1
        return 0
      fi

      if [[ -z "$iso" ]]; then
        echo "Usage: test-iso [-p] [-e] <iso-path>  # boot ISO for installation"
        echo "       test-iso [-e] -b                # boot from installed disk"
        echo ""
        echo "Options:"
        echo "  -p, --persistent   Save changes to disk (for installation)"
        echo "  -b, --boot         Boot from disk (after installation)"
        echo "  -e, --efi          Use UEFI firmware (default: BIOS)"
        echo ""
        echo "Examples:"
        echo "  test-iso result/iso/*.iso           # BIOS ephemeral test"
        echo "  test-iso -e result/iso/*.iso        # EFI ephemeral test"
        echo "  test-iso -p result/iso/*.iso        # BIOS install to disk"
        echo "  test-iso -e -p result/iso/*.iso     # EFI install to disk"
        echo "  test-iso -b                         # boot BIOS installed system"
        echo "  test-iso -e -b                      # boot EFI installed system"
        return 1
      fi

      if [[ ! -f "$disk" ]]; then
        echo "Creating 20G disk: $disk"
        qemu-img create -f qcow2 "$disk" 20G
      fi

      echo "Connect from theophany: open vnc://perdurabo:5901"

      if [[ "$persistent" == true ]]; then
        echo "Starting QEMU (persistent mode, EFI=$efi_mode)"
        echo "After installation, run: test-iso $([[ "$efi_mode" == true ]] && echo '-e ') -b"
        qemu-system-x86_64 -enable-kvm -m 4G \
          $efi_args \
          -drive file="$disk",format=qcow2 \
          -cdrom "$iso" \
          -boot d \
          -vnc :1
      else
        echo "Starting QEMU (ephemeral mode, EFI=$efi_mode)"
        qemu-system-x86_64 -enable-kvm -m 4G \
          $efi_args \
          -drive file="$disk",format=qcow2 \
          -cdrom "$iso" \
          -boot d \
          -vnc :1 \
          -snapshot
      fi
    }

    # Command correction function
    command_not_found_handle() {
      local cmd="$1"
      local suggestion=""

      # Common command abbreviations and typos
      case "$cmd" in
        "gt") suggestion="git" ;;
        "gi") suggestion="git" ;;
        "gti") suggestion="git" ;;
        "got") suggestion="git" ;;
        "gut") suggestion="git" ;;
        "sl") suggestion="ls" ;;
        "l") suggestion="ls" ;;
        "la") suggestion="ls -la" ;;
        "ll") suggestion="ls -l" ;;
        "cd..") suggestion="cd .." ;;
        "cd...") suggestion="cd ../.." ;;
        "mkdir") suggestion="mkdir" ;;
        "mkdr") suggestion="mkdir" ;;
        "mkdi") suggestion="mkdir" ;;
        "rm") suggestion="rm" ;;
        "rmr") suggestion="rm -r" ;;
        "mv") suggestion="mv" ;;
        "cp") suggestion="cp" ;;
        "chr") suggestion="chmod" ;;
        "chmd") suggestion="chmod" ;;
        "chmdo") suggestion="chmod" ;;
        "chown") suggestion="chown" ;;
        "chonw") suggestion="chown" ;;
        "grep") suggestion="grep" ;;
        "gerp") suggestion="grep" ;;
        "grpe") suggestion="grep" ;;
        "find") suggestion="find" ;;
        "finde") suggestion="find" ;;
        "findd") suggestion="find" ;;
        "cat") suggestion="cat" ;;
        "cta") suggestion="cat" ;;
        "vim") suggestion="vim" ;;
        "vi") suggestion="vim" ;;
        "vm") suggestion="vim" ;;
        "nano") suggestion="nano" ;;
        "nao") suggestion="nano" ;;
        "emacs") suggestion="emacs" ;;
        "emac") suggestion="emacs" ;;
        "ssh") suggestion="ssh" ;;
        "shh") suggestion="ssh" ;;
        "scp") suggestion="scp" ;;
        "rsync") suggestion="rsync" ;;
        "rync") suggestion="rsync" ;;
        "wget") suggestion="wget" ;;
        "wgte") suggestion="wget" ;;
        "curl") suggestion="curl" ;;
        "crul") suggestion="curl" ;;
        "ps") suggestion="ps" ;;
        "top") suggestion="top" ;;
        "htop") suggestion="htop" ;;
        "htp") suggestion="htop" ;;
        "df") suggestion="df" ;;
        "du") suggestion="du" ;;
        "tar") suggestion="tar" ;;
        "tra") suggestion="tar" ;;
        "zip") suggestion="zip" ;;
        "unzip") suggestion="unzip" ;;
        "man") suggestion="man" ;;
        "amn") suggestion="man" ;;
        "which") suggestion="which" ;;
        "whch") suggestion="which" ;;
        "history") suggestion="history" ;;
        "hstory") suggestion="history" ;;
        "histroy") suggestion="history" ;;
        "clear") suggestion="clear" ;;
        "clar") suggestion="clear" ;;
        "cls") suggestion="clear" ;;
        "exit") suggestion="exit" ;;
        "eixt") suggestion="exit" ;;
        "exti") suggestion="exit" ;;
        "logout") suggestion="logout" ;;
        "logut") suggestion="logout" ;;
      esac

      # If no predefined suggestion, try fuzzy matching with available commands
      if [[ -z "$suggestion" ]]; then
        # Get list of available commands and find closest match
        local commands=($(compgen -c | sort -u))
        local best_match=""
        local min_distance=999

        for command in "''${commands[@]}"; do
          # Simple distance calculation (character differences)
          if [[ ''${#command} -ge $((''${#cmd} - 2)) ]] && [[ ''${#command} -le $((''${#cmd} + 2)) ]]; then
            # Check if command contains most of the typed characters
            local match_count=0
            for (( i=0; i<''${#cmd}; i++ )); do
              if [[ "$command" == *"''${cmd:$i:1}"* ]]; then
                ((match_count++))
              fi
            done

            # If most characters match, consider it a good suggestion
            if [[ $match_count -gt $((''${#cmd} * 60 / 100)) ]]; then
              if [[ $match_count -gt $((min_distance)) ]]; then
                min_distance=$match_count
                best_match="$command"
              fi
            fi
          fi
        done

        if [[ -n "$best_match" ]]; then
          suggestion="$best_match"
        fi
      fi

      if [[ -n "$suggestion" ]]; then
        echo -e "\033[31mCommand '$cmd' not found.\033[0m"
        echo -e "Did you mean: \033[32m$suggestion\033[0m?"
        read -p "Run '$suggestion'? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          # Shift to remove the original command and pass remaining arguments
          shift
          eval "$suggestion" "$@"
        fi
      else
        echo -e "\033[31mCommand '$cmd' not found.\033[0m"
        return 127
      fi
    }
  '';
}