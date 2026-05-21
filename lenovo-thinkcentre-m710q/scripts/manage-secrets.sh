#!/usr/bin/env bash
# Helper script for managing agenix secrets on Congo server

set -euo pipefail

SECRETS_DIR="/etc/nixos/lenovo-thinkcentre-m710q/secrets"
cd "$SECRETS_DIR"

show_menu() {
    echo ""
    echo "=== Congo Server Secret Management ==="
    echo ""
    echo "1) Create/Update amy's password"
    echo "2) Create/Update initrd SSH host key"
    echo "3) Create/Update FreeDNS URL"
    echo "4) Create/Update Pi-hole admin password"
    echo "5) View existing secrets"
    echo "6) Edit existing secret"
    echo "7) Exit"
    echo ""
    read -p "Select option: " choice
    echo ""

    case $choice in
        1) create_amy_password ;;
        2) create_initrd_key ;;
        3) create_freedns_url ;;
        4) create_pihole_password ;;
        5) list_secrets ;;
        6) edit_secret ;;
        7) exit 0 ;;
        *) echo "Invalid option"; show_menu ;;
    esac
}

create_amy_password() {
    echo "=== Create/Update amy's Password ==="
    echo ""
    read -sp "Enter new password for amy: " password
    echo ""
    read -sp "Confirm password: " password2
    echo ""

    if [ "$password" != "$password2" ]; then
        echo "Passwords don't match!"
        return 1
    fi

    echo "Generating password hash..."
    PASS_HASH=$(openssl passwd -6 "$password")

    echo "Encrypting with age..."
    echo "$PASS_HASH" | ragenix -e amy-password.age

    echo "✓ amy-password.age created/updated"
    echo ""
    echo "Next steps:"
    echo "  1. git add secrets/amy-password.age"
    echo "  2. git commit -m 'Update amy password'"
    echo "  3. nixos-rebuild switch"

    show_menu
}

create_initrd_key() {
    echo "=== Create/Update Initrd SSH Host Key ==="
    echo ""
    echo "Options:"
    echo "1) Use existing key at /etc/ssh/initrd_ssh_host_ed25519_key"
    echo "2) Generate new key"
    read -p "Select option: " opt

    case $opt in
        1)
            if [ ! -f /etc/ssh/initrd_ssh_host_ed25519_key ]; then
                echo "Error: /etc/ssh/initrd_ssh_host_ed25519_key not found!"
                return 1
            fi
            echo "Encrypting existing key..."
            ragenix -e initrd-ssh-host-ed25519-key.age < /etc/ssh/initrd_ssh_host_ed25519_key
            ;;
        2)
            echo "Generating new ed25519 key..."
            ssh-keygen -t ed25519 -f /tmp/initrd_key -N "" -C "initrd@congo"
            echo ""
            echo "Public key:"
            cat /tmp/initrd_key.pub
            echo ""
            echo "Encrypting private key..."
            ragenix -e initrd-ssh-host-ed25519-key.age < /tmp/initrd_key
            rm /tmp/initrd_key /tmp/initrd_key.pub
            ;;
        *)
            echo "Invalid option"
            return 1
            ;;
    esac

    echo "✓ initrd-ssh-host-ed25519-key.age created/updated"
    echo ""
    echo "Next steps:"
    echo "  1. git add secrets/initrd-ssh-host-ed25519-key.age"
    echo "  2. git commit -m 'Update initrd SSH host key'"
    echo "  3. nixos-rebuild switch"

    show_menu
}

create_freedns_url() {
    echo "=== Create/Update FreeDNS URL ==="
    echo ""
    read -p "Enter FreeDNS update URL: " url

    if [ -z "$url" ]; then
        echo "Error: URL cannot be empty!"
        return 1
    fi

    echo "Encrypting FreeDNS URL..."
    echo "$url" | ragenix -e freedns-url.age

    echo "✓ freedns-url.age created/updated"
    echo ""
    echo "Next steps:"
    echo "  1. git add secrets/freedns-url.age"
    echo "  2. git commit -m 'Update FreeDNS URL'"
    echo "  3. nixos-rebuild switch"

    show_menu
}

create_pihole_password() {
    echo "=== Create/Update Pi-hole Admin Password ==="
    echo ""
    read -sp "Enter Pi-hole admin password: " password
    echo ""
    read -sp "Confirm password: " password2
    echo ""

    if [ "$password" != "$password2" ]; then
        echo "Passwords don't match!"
        return 1
    fi

    echo "Encrypting password..."
    echo "$password" | ragenix -e pihole-admin-password.age

    echo "✓ pihole-admin-password.age created/updated"
    echo ""
    echo "Next steps:"
    echo "  1. git add secrets/pihole-admin-password.age"
    echo "  2. git commit -m 'Update Pi-hole admin password'"
    echo "  3. nixos-rebuild switch"

    show_menu
}

list_secrets() {
    echo "=== Existing Secrets ==="
    echo ""
    ls -lh *.age 2>/dev/null || echo "No .age files found"
    echo ""
    show_menu
}

edit_secret() {
    echo "=== Edit Existing Secret ==="
    echo ""
    ls *.age 2>/dev/null || { echo "No .age files found"; show_menu; return; }
    echo ""
    read -p "Enter secret filename to edit: " filename

    if [ ! -f "$filename" ]; then
        echo "Error: $filename not found!"
        return 1
    fi

    ragenix -e "$filename"

    echo "✓ $filename updated"
    echo ""
    echo "Next steps:"
    echo "  1. git add secrets/$filename"
    echo "  2. git commit -m 'Update $filename'"
    echo "  3. nixos-rebuild switch"

    show_menu
}

# Check if ragenix is available
if ! command -v ragenix &> /dev/null; then
    echo "Error: ragenix not found. Install with:"
    echo "  nix-env -iA nixpkgs.ragenix"
    exit 1
fi

# Main
echo "Congo Server Secret Management"
echo "==============================="
show_menu
