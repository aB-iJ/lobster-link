#!/bin/bash
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
MSG="${1:-起床了}"
SOUND="/System/Library/Sounds/Glass.aiff"

# 连续提醒：通知 + 语音 + 声音循环
/usr/bin/osascript -e "display notification \"$MSG\" with title \"⏰ 起床闹钟\" sound name \"Glass\"" >/dev/null 2>&1 || true
/usr/bin/say "$MSG" >/dev/null 2>&1 || true
for i in $(seq 1 40); do
  /usr/bin/afplay "$SOUND" >/dev/null 2>&1 &
  sleep 3
done
