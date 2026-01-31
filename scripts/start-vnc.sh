#!/bin/bash
# 独立启动 VNC 服务的脚本（供 supervisord 使用）
set -e

echo "[VNC] Starting x11vnc server on port $VNC_PORT..."

exec x11vnc -display $DISPLAY \
    -forever \
    -shared \
    -rfbport $VNC_PORT \
    -passwd "$VNC_PASSWORD" \
    -xkb \
    -noxrecord \
    -noxfixes \
    -noxdamage \
    -repeat \
    -wait 5
