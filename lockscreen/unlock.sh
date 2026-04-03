#!/bin/bash
# 解锁脚本 - 由锁屏页面或手动调用
UNLOCK_SIGNAL="/tmp/dongxuejiu-unlock"
touch "$UNLOCK_SIGNAL"
echo "解锁信号已发送"
