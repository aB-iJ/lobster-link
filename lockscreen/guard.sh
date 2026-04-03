#!/bin/bash
# 董学九锁屏守护脚本
# 自动检测空闲状态，触发锁屏/解锁

LOCKFILE="/tmp/dongxuejiu-lock.pid"
UNLOCK_SIGNAL="/tmp/dongxuejiu-unlock"
LOCK_ACTIVE="/tmp/dongxuejiu-locked"
LOCKSCREEN_HTML="/Users/alastairsmac1/.openclaw/workspace/lockscreen/index.html"
M1DDC="/opt/homebrew/bin/m1ddc"
PYTHON="/opt/homebrew/bin/python3"

# 配置
NIGHT_START=23
NIGHT_END=7
NIGHT_IDLE_THRESHOLD=300  # 夜间 5 分钟空闲锁屏
DAY_IDLE_THRESHOLD=900    # 白天 15 分钟（备用）
BRIGHTNESS_LOW=5
BRIGHTNESS_NORMAL=""
CHECK_INTERVAL=10

# PID 文件
echo $$ > "$LOCKFILE"
rm -f "$LOCK_ACTIVE" "$UNLOCK_SIGNAL"

cleanup() {
    rm -f "$LOCKFILE" "$LOCK_ACTIVE" "$UNLOCK_SIGNAL"
    if [ -n "$BRIGHTNESS_NORMAL" ]; then
        "$M1DDC" set luminance "$BRIGHTNESS_NORMAL" 2>/dev/null
    fi
    close_lockscreen
    kill "$LISTENER_PID" 2>/dev/null
    exit 0
}

trap cleanup SIGINT SIGTERM

# 记录当前亮度
BRIGHTNESS_NORMAL=$("$M1DDC" get luminance 2>/dev/null)
[ -z "$BRIGHTNESS_NORMAL" ] && BRIGHTNESS_NORMAL=80

get_idle_seconds() {
    local idle_ns=$(/usr/sbin/ioreg -c IOHIDSystem | awk '/HIDIdleTime/ {print $NF; exit}')
    echo $((idle_ns / 1000000000))
}

get_hour() {
    date +%-H
}

is_night() {
    local hour=$(get_hour)
    [ "$hour" -ge "$NIGHT_START" ] || [ "$hour" -lt "$NIGHT_END" ]
}

close_lockscreen() {
    osascript -e '
    tell application "Microsoft Edge"
        set windowList to every window
        repeat with aWindow in windowList
            set tabList to every tab of aWindow
            repeat with aTab in tabList
                if URL of aTab contains "lockscreen" then
                    close aTab
                end if
            end repeat
        end repeat
    end tell' 2>/dev/null
}

activate_lock() {
    if [ -f "$LOCK_ACTIVE" ]; then
        return
    fi

    echo "$(date): 激活锁屏" >> /tmp/dongxuejiu-lock.log
    touch "$LOCK_ACTIVE"
    rm -f "$UNLOCK_SIGNAL"

    "$M1DDC" set luminance "$BRIGHTNESS_LOW" 2>/dev/null

    open -na "Microsoft Edge" --args \
        --app="file://$LOCKSCREEN_HTML" \
        --test-type \
        --start-fullscreen \
        --disable-pinch \
        --overscroll-history-navigation=0 \
        --disable-features=TranslateUI \
        --no-first-run \
        --disable-infobars \
        --disable-session-crashed-bubble \
        --disable-default-apps \
        --disable-translate 2>/dev/null

    sleep 2

    # 最大化窗口 + 关掉信息栏（按 Enter）
    osascript -e '
    tell application "Microsoft Edge"
        activate
        set bounds of front window to {0, 0, 3840, 2160}
    end tell' 2>/dev/null
    
    sleep 0.5
}

deactivate_lock() {
    if [ ! -f "$LOCK_ACTIVE" ]; then
        return
    fi

    echo "$(date): 解除锁屏" >> /tmp/dongxuejiu-lock.log
    rm -f "$LOCK_ACTIVE" "$UNLOCK_SIGNAL"

    close_lockscreen

    # 恢复亮度 - 关闭锁屏后再恢复，确保 DDC 通道不被占用
    sleep 1
    "$M1DDC" set luminance "$BRIGHTNESS_NORMAL" 2>/dev/null
    sleep 1
    "$M1DDC" set luminance "$BRIGHTNESS_NORMAL" 2>/dev/null

    echo "$(date): 亮度恢复到 $BRIGHTNESS_NORMAL (实际: $("$M1DDC" get luminance 2>/dev/null))" >> /tmp/dongxuejiu-lock.log
}

# 启动 HTTP 解锁监听（后台）
start_unlock_listener() {
    while true; do
        "$PYTHON" -c "
import http.server, socketserver, os

class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if 'unlock' in self.path:
            open('/tmp/dongxuejiu-unlock', 'w').close()
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(b'OK')
    def do_GET(self):
        if 'unlock' in self.path:
            open('/tmp/dongxuejiu-unlock', 'w').close()
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(b'OK')
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.end_headers()
    def log_message(self, *args): pass

socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(('127.0.0.1', 19753), H) as s:
    s.serve_forever()
" 2>/dev/null
        sleep 2
    done
}

start_unlock_listener &
LISTENER_PID=$!

echo "$(date): 董学九锁屏守护启动 (PID $$, listener PID $LISTENER_PID)" >> /tmp/dongxuejiu-lock.log

# 主循环
while true; do
    # 检查解锁信号
    if [ -f "$UNLOCK_SIGNAL" ]; then
        deactivate_lock
    fi

    idle=$(get_idle_seconds)

    # 夜间 + 空闲超阈值 → 锁屏
    if is_night && [ "$idle" -ge "$NIGHT_IDLE_THRESHOLD" ]; then
        activate_lock
    fi

    # 锁屏状态：保持窗口最大化
    if [ -f "$LOCK_ACTIVE" ]; then
        osascript -e '
        tell application "Microsoft Edge"
            activate
            set bounds of front window to {0, 0, 3840, 2160}
        end tell' 2>/dev/null
        sleep 3
    else
        sleep "$CHECK_INTERVAL"
    fi
done
