#!/bin/bash
set -e
WHEN="$1"
shift
MSG="$*"
TARGET_EPOCH=$(/bin/date -j -f "%Y-%m-%d %H:%M:%S" "$WHEN" "+%s")
NOW_EPOCH=$(/bin/date "+%s")
SLEEP_SECS=$((TARGET_EPOCH - NOW_EPOCH))
if [ "$SLEEP_SECS" -lt 0 ]; then
  echo "target already passed: $WHEN"
  exit 1
fi
sleep "$SLEEP_SECS"
/usr/bin/osascript -e "display notification \"$MSG\" with title \"⏰ 起床闹钟\" sound name \"Glass\"" >/dev/null 2>&1 || true
/usr/bin/say "$MSG" >/dev/null 2>&1 || true
for i in $(seq 1 20); do
  /usr/bin/afplay /System/Library/Sounds/Glass.aiff >/dev/null 2>&1
  sleep 2
done
