#!/usr/bin/env bash

set -Eeuo pipefail

readonly MODPROBE_FILE="/etc/modprobe.d/99-huawei-audio.conf"
readonly FIRMWARE_DIR="/lib/firmware/intel/sof-tplg"
readonly FIRMWARE_NAME="sof-tgl-es8336-dmic2ch.tplg"
readonly FIRMWARE_TARGET="sof-tgl-es8336-dmic2ch-ssp0.tplg"
readonly HEADPHONE_SERVICE="huawei-soundcard-headphones-monitor.service"

say() {
    printf '%s\n' "$*"
}

fail() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

require_root() {
    [[ ${EUID} -eq 0 ]] || fail "run this script with sudo: sudo ./huawei-audio-fix.sh"
}

check_hardware() {
    if ! lspci -nn 2>/dev/null | grep -q '8086:a0c8'; then
        fail "Intel audio controller 8086:a0c8 was not found; this script targets the Huawei MateBook D15 BOD-WXX9."
    fi
}

install_modprobe_config() {
    cat > "$MODPROBE_FILE" <<'EOF'
# Huawei MateBook D15 BOD-WXX9: the ACPI firmware does not expose the ES8336 I2C link.
# Use the HDA codec path so speakers and the headphone jack remain available.
options snd-intel-dspcfg dsp_driver=1
options snd-hda-intel dmic_detect=0
options snd-hda-intel index=0
EOF
}

install_firmware_alias() {
    local source="$FIRMWARE_DIR/$FIRMWARE_TARGET"
    local destination="$FIRMWARE_DIR/$FIRMWARE_NAME"

    [[ -f "$source" ]] || fail "firmware file not found: $source"
    ln -sfn "$source" "$destination"
}

disable_conflicting_service() {
    if systemctl list-unit-files --full 2>/dev/null | grep -q "^${HEADPHONE_SERVICE}"; then
        systemctl disable --now "$HEADPHONE_SERVICE" >/dev/null 2>&1 || true
    fi
}

refresh_initramfs() {
    command -v update-initramfs >/dev/null || fail "update-initramfs was not found"
    update-initramfs -u
}

show_status() {
    say
    say "Setup is complete. After reboot, check the result with:"
    say "  aplay -l"
    say "  wpctl status"
    say
    say "Expected result: HDA Intel PCH and the built-in analog output."
    say "The built-in microphone may remain unavailable: this is an ACPI/BIOS limitation of this model, not a volume setting."
}

main() {
    require_root
    check_hardware
    install_modprobe_config
    install_firmware_alias
    disable_conflicting_service
    refresh_initramfs
    show_status
}

main "$@"
