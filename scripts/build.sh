#!/bin/sh
set -eu
task_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
task_deveco=${DEVECO_HOME:-"$HOME/Applications/DevEco-Studio.app/Contents"}
if [ -d "$task_deveco/Contents" ]; then task_deveco="$task_deveco/Contents"; fi
task_variant=${1:-main}
case "$task_variant" in
  main) task_module=entry@default ;;
  test) task_module=entry@ohosTest ;;
  *) echo 'Usage: scripts/build.sh [main|test]' >&2; exit 2 ;;
esac
if [ ! -f "$task_root/build-profile.json5" ]; then
  echo 'Copy build-profile.example.json5 to build-profile.json5 and configure local signing in DevEco Studio.' >&2
  exit 1
fi
if [ ! -x "$task_deveco/tools/node/bin/node" ]; then
  echo 'Set DEVECO_HOME to the DevEco Studio Contents directory.' >&2
  exit 1
fi
export PATH="$task_deveco/tools/node/bin:$PATH"
export DEVECO_SDK_HOME="$task_deveco/sdk"
cd "$task_root"
exec "$task_deveco/tools/hvigor/bin/hvigorw" --mode module -p product=default -p module="$task_module" assembleHap --no-daemon
