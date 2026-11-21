#!/bin/sh
set -eu
loci_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
loci_deveco=${DEVECO_HOME:-"$HOME/Applications/DevEco-Studio.app/Contents"}
if [ -d "$loci_deveco/Contents" ]; then loci_deveco="$loci_deveco/Contents"; fi
loci_hdc="$loci_deveco/sdk/default/openharmony/toolchains/hdc"
: "${HDC_TARGET_ID:?Set HDC_TARGET_ID to the device to test}"
loci_suite=${1:-core}
case "$loci_suite" in
  core) loci_runner=OpenHarmonyTestRunner ;;
  ui) loci_runner=OpenHarmonyUITestRunner ;;
  *) echo 'Usage: HDC_TARGET_ID=<device> sh scripts/test-device.sh [core|ui]' >&2; exit 2 ;;
esac
mkdir -p "$loci_root/build/verification"
loci_device=$(printf '%s' "$HDC_TARGET_ID" | tr -c '[:alnum:]_-' '_')
loci_log="$loci_root/build/verification/$loci_suite-$(date +%Y%m%d-%H%M%S)-$loci_device.log"
if [ -n "${2:-}" ]; then
  "$loci_hdc" -t "$HDC_TARGET_ID" shell aa test -b top.rayawa.loci -m entry_test -s unittest "$loci_runner" -s timeout 240000 -s class "$2" > "$loci_log" 2>&1
else
  "$loci_hdc" -t "$HDC_TARGET_ID" shell aa test -b top.rayawa.loci -m entry_test -s unittest "$loci_runner" -s timeout 240000 > "$loci_log" 2>&1
fi
cat "$loci_log"
python3 - "$loci_log" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
matches = re.findall(r'Tests run:\s*(\d+), Failure:\s*(\d+), Error:\s*(\d+), Pass:\s*(\d+), Ignore:\s*(\d+)', text)
if 'error in afterAll' in text or 'error in afterEach' in text:
    raise SystemExit('Native test cleanup failed')
if not matches:
    raise SystemExit('Missing native test summary')
for values in matches:
    total, failed, errors, passed, ignored = map(int, values)
    if total == 0 or failed or errors or ignored or passed != total:
        raise SystemExit('Native test suite did not fully pass')
print('Native test summary verified:', sys.argv[1])
PY
