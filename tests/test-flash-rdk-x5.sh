#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." >/dev/null 2>&1 && pwd -P)"
FLASH_SCRIPT="$ROOT_DIR/scripts/saha-flash-rdk-x5"
README="$ROOT_DIR/README.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

contains() {
  local haystack=$1
  local needle=$2
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

expect_failure() {
  local expected=$1
  shift
  local output status

  set +e
  output="$("$@" 2>&1)"
  status=$?
  set -e
  [ "$status" -ne 0 ] || fail "command unexpectedly succeeded: $*"
  contains "$output" "$expected"
}

[ -f "$FLASH_SCRIPT" ] || fail "RDK X5 flash script is missing"
[ -f "$README" ] || fail "project README is missing"
bash -n "$FLASH_SCRIPT"

help_output="$("$FLASH_SCRIPT" --help)"
contains "$help_output" 'Usage: scripts/saha-flash-rdk-x5'
contains "$help_output" '--image PATH'
contains "$help_output" '--device PATH'
contains "$help_output" '--dry-run'
contains "$help_output" 'NAND/eMMC firmware'

grep -Fq './scripts/saha-flash-rdk-x5' "$README" ||
  fail "README must document the guarded RDK X5 flash helper"
grep -Fq -- '--dry-run --image <image.wic.bz2> --device /dev/sdX' "$README" ||
  fail "README must document flash-script preflight"

expect_failure '--image is required' "$FLASH_SCRIPT" --dry-run --device /dev/null

temporary_dir="$(mktemp -d)"
trap 'find "$temporary_dir" -xdev -depth -delete' EXIT
invalid_image="$temporary_dir/invalid.wic.bz2"
printf '%s\n' 'not a bzip2 archive' > "$invalid_image"
expect_failure 'image is not a valid bzip2 archive' \
  "$FLASH_SCRIPT" --dry-run --image "$invalid_image" --device /dev/null

non_wic_image="$temporary_dir/not-a-wic.wic.bz2"
printf '%s\n' 'valid bzip2 but not a WIC image' | bzip2 -c > "$non_wic_image"
expect_failure 'expected RDK X5 WIC MBR signature' \
  "$FLASH_SCRIPT" --dry-run --image "$non_wic_image" --device /dev/null

valid_image="$temporary_dir/tiny.wic.bz2"
{
  dd if=/dev/zero bs=510 count=1 status=none
  printf '\x55\xaa'
} | bzip2 -c > "$valid_image"
expect_failure 'device is not a block device' \
  "$FLASH_SCRIPT" --dry-run --image "$valid_image" --device /dev/null

for required_fragment in \
  'lsblk -dn -o TYPE' \
  'lsblk -dn -o RM' \
  'findmnt -rn -o SOURCE,TARGET' \
  'bzip2 -t' \
  'expected RDK X5 WIC MBR signature' \
  'lsblk -bdn -o SIZE' \
  'a TTY is required for a real write' \
  'conv=fsync' \
  'partprobe' \
  "grep -Fxq 'CONFIG'" \
  "grep -Fxq 'rootfs'" \
  'Unmounting post-write desktop automount' \
  'blockdev --flushbufs' \
  'write completed, unmounted, and flushed successfully'; do
  grep -Fq -- "$required_fragment" "$FLASH_SCRIPT" ||
    fail "flash script is missing safety contract: $required_fragment"
done

confirmation_line="$(grep -n '^require_tty_confirmation$' "$FLASH_SCRIPT" | tail -n 1 | cut -d: -f1)"
post_write_unmount_line="$(grep -n '^finalize_written_card$' "$FLASH_SCRIPT" | tail -n 1 | cut -d: -f1)"
[[ "$confirmation_line" =~ ^[0-9]+$ && "$post_write_unmount_line" =~ ^[0-9]+$ ]] ||
  fail "flash script must call confirmation and post-write finalization"
[ "$post_write_unmount_line" -gt "$confirmation_line" ] ||
  fail "flash script must never unmount a filesystem before confirmation"

if grep -Eq -- '^[[:space:]]*--yes\)' "$FLASH_SCRIPT" ||
  grep -Eq -- '/dev/tty(USB|ACM)' "$FLASH_SCRIPT"; then
  fail "flash script must not bypass confirmation or access a serial device"
fi

printf 'PASS: RDK X5 flash script safety checks\n'
