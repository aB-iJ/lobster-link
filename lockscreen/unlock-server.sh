#!/bin/bash
# 解锁信号接收器 - 简单 HTTP 服务器
# 监听 127.0.0.1:19753，任何请求都创建解锁信号文件

UNLOCK_SIGNAL="/tmp/dongxuejiu-unlock"
PORT=19753

cleanup() {
    rm -f /tmp/dongxuejiu-unlock-server.pipe
    exit 0
}
trap cleanup SIGINT SIGTERM

PIPE="/tmp/dongxuejiu-unlock-server.pipe"
rm -f "$PIPE"
mkfifo "$PIPE"

echo "解锁信号接收器启动在 127.0.0.1:$PORT"

while true; do
    # 用管道让 nc 能正确返回响应
    ( 
        cat "$PIPE" | nc -l 127.0.0.1 $PORT > /tmp/dongxuejiu-nc-req.txt 2>/dev/null
        # 检查请求
        if grep -q "unlock" /tmp/dongxuejiu-nc-req.txt 2>/dev/null; then
            touch "$UNLOCK_SIGNAL"
            echo "$(date): 收到解锁信号" >> /tmp/dongxuejiu-lock.log
        fi
    ) &
    
    # 等一小会让 nc 启动
    sleep 0.2
    
    # 写入 HTTP 响应到管道
    printf "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: POST, GET, OPTIONS\r\nContent-Length: 2\r\nConnection: close\r\n\r\nOK" > "$PIPE" 2>/dev/null
    
    wait
    sleep 0.1
done
