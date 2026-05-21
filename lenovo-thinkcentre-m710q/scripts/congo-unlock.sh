#!/usr/bin/env bash
# Automated Congo LUKS unlock script for perdurabo
# Run this on perdurabo to automatically unlock Congo server after reboot

set -euo pipefail

# Configuration
CONGO_IP="192.168.1.42"
SSH_PORT="2222"
SSH_KEY="$HOME/.ssh/congo_unlock"
MAX_ATTEMPTS=30
RETRY_INTERVAL=10
UNLOCK_TIMEOUT=60

# Colors for output
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if Congo is responding to SSH (initrd)
check_congo_initrd() {
    timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -i "$SSH_KEY" -p "$SSH_PORT" "root@$CONGO_IP" "echo 'initrd-ready'" 2>/dev/null
}

# Check if Congo has fully booted
check_congo_booted() {
    timeout 5 ssh -o ConnectTimeout=3 -o BatchMode=yes -i "$SSH_KEY" -p 2222 "amy@$CONGO_IP" "echo 'booted'" 2>/dev/null
}

# Wait for Congo to be reachable in initrd
wait_for_congo() {
    log "Waiting for Congo to boot into initrd environment..."

    for ((i=1; i<=MAX_ATTEMPTS; i++)); do
        log "Attempt $i/$MAX_ATTEMPTS - Checking Congo connectivity..."

        if check_congo_initrd; then
            success "Congo is reachable in initrd environment"
            return 0
        fi

        if ((i < MAX_ATTEMPTS)); then
            log "Congo not ready, waiting ${RETRY_INTERVAL}s before retry..."
            sleep "$RETRY_INTERVAL"
        fi
    done

    error "Congo did not become reachable after $MAX_ATTEMPTS attempts"
    return 1
}

# Unlock the LUKS encrypted disk
unlock_congo() {
    log "Attempting to unlock Congo LUKS encryption..."

    # Run the unlock command (NixOS 25.05 uses systemd-tty-ask-password-agent)
    if timeout "$UNLOCK_TIMEOUT" ssh -o ConnectTimeout=10 -i "$SSH_KEY" -p "$SSH_PORT" "root@$CONGO_IP" \
        "systemd-tty-ask-password-agent && echo 'unlock-success'"; then
        success "Congo LUKS unlock command executed successfully"
        return 0
    else
        log "Trying alternative unlock method (cryptsetup-askpass)..."
        if timeout "$UNLOCK_TIMEOUT" ssh -o ConnectTimeout=10 -i "$SSH_KEY" -p "$SSH_PORT" "root@$CONGO_IP" \
            "cryptsetup-askpass && echo 'unlock-success'"; then
            success "Congo LUKS unlock command executed successfully"
            return 0
        else
            error "Failed to execute unlock command with both methods"
            return 1
        fi
    fi
}

# Wait for Congo to finish booting
wait_for_boot() {
    log "Waiting for Congo to complete boot process..."

    for ((i=1; i<=20; i++)); do
        log "Boot check $i/20 - Waiting for Congo services..."

        if check_congo_booted; then
            success "Congo has fully booted and is operational"
            return 0
        fi

        sleep 15
    done

    warn "Congo boot status uncertain after 5 minutes"
    return 1
}

# Send notification (customize as needed)
send_notification() {
    local status="$1"
    local message="$2"

    # Log to syslog
    logger -t "congo-unlock" "$status: $message"

    # Optional: Send to notification service
    # curl -X POST "https://your-notification-service" -d "$message"
}

# Main execution
main() {
    log "🇨🇩 Starting automated Congo unlock process..."

    # Check if SSH key exists
    if [[ ! -f "$SSH_KEY" ]]; then
        error "SSH key not found at $SSH_KEY"
        error "Generate key: ssh-keygen -t ed25519 -f $SSH_KEY"
        exit 1
    fi

    # Step 1: Wait for Congo to be reachable
    if ! wait_for_congo; then
        send_notification "FAILED" "Congo did not become reachable for unlock"
        exit 1
    fi

    # Step 2: Unlock the disk
    if ! unlock_congo; then
        send_notification "FAILED" "Congo LUKS unlock failed"
        exit 1
    fi

    # Step 3: Wait for full boot
    wait_for_boot

    if check_congo_booted; then
        success "🇨🇩 Congo unlock and boot completed successfully!"
        send_notification "SUCCESS" "Congo is fully operational"
    else
        warn "Congo unlock completed but boot status uncertain"
        send_notification "PARTIAL" "Congo unlocked but boot verification failed"
    fi
}

# Handle script arguments
case "${1:-auto}" in
    "auto")
        main
        ;;
    "check")
        if check_congo_booted; then
            success "Congo is fully operational"
        elif check_congo_initrd; then
            warn "Congo is in initrd (needs unlock)"
        else
            error "Congo is not reachable"
        fi
        ;;
    "unlock")
        unlock_congo
        ;;
    "monitor")
        log "Monitoring Congo status..."
        while true; do
            if check_congo_booted; then
                echo -ne "\r${GREEN}●${NC} Congo operational $(date +'%H:%M:%S')"
            elif check_congo_initrd; then
                echo -ne "\r${YELLOW}●${NC} Congo needs unlock $(date +'%H:%M:%S')"
            else
                echo -ne "\r${RED}●${NC} Congo unreachable $(date +'%H:%M:%S')"
            fi
            sleep 5
        done
        ;;
    *)
        echo "Usage: $0 [auto|check|unlock|monitor]"
        echo "  auto    - Full automated unlock process (default)"
        echo "  check   - Check current Congo status"
        echo "  unlock  - Unlock only (assume Congo is in initrd)"
        echo "  monitor - Continuous status monitoring"
        exit 1
        ;;
esac
