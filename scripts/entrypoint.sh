#!/bin/bash
# 不使用 set -e，避免某些非关键命令失败导致脚本退出

echo "=========================================="
echo "  Chrome VNC Container Starting..."
echo "=========================================="
echo "  Display:     $DISPLAY"
echo "  Resolution:  $RESOLUTION"
echo "  VNC Port:    $VNC_PORT"
echo "  noVNC Port:  $NOVNC_PORT"
echo "  CDP Port:    $CDP_PORT"
echo "=========================================="

# 创建必要的目录
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# 清理可能存在的锁文件
rm -f /tmp/.X99-lock

# 启动 Xvfb（虚拟显示器）
echo "[1/5] Starting Xvfb..."
Xvfb $DISPLAY -screen 0 $RESOLUTION -ac +extension GLX +render -noreset &
XVFB_PID=$!

# 等待 Xvfb 启动
sleep 2

# 验证 Xvfb 是否正常运行
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "ERROR: Xvfb failed to start"
    exit 1
fi

# 设置黑色背景（在启动 fluxbox 之前）
echo "[2/5] Setting up desktop environment..."
xsetroot -solid black 2>/dev/null || true

# 复制 fluxbox 配置（避免 xmessage 弹窗）
mkdir -p /home/chrome/.fluxbox
cp -r /config/fluxbox/* /home/chrome/.fluxbox/ 2>/dev/null || true

# 启动窗口管理器
fluxbox 2>/dev/null &
sleep 1

# 启动中文输入法
echo "[2.5/5] Starting Fcitx input method..."
fcitx -d 2>/dev/null &
sleep 1

# 启动剪贴板同步（支持外部复制粘贴到容器）
echo "[2.6/5] Starting clipboard sync..."
autocutsel -fork 2>/dev/null &
autocutsel -selection PRIMARY -fork 2>/dev/null &

# 启动 x11vnc
echo "[3/5] Starting VNC server..."
x11vnc -display $DISPLAY \
    -forever \
    -shared \
    -rfbport $VNC_PORT \
    -passwd "$VNC_PASSWORD" \
    -xkb \
    -noxrecord \
    -noxdamage \
    -repeat \
    -wait 5 \
    -ncache 10 \
    -ncache_cr \
    -o /dev/null &

# 等待 VNC 服务器启动
sleep 2

# 启动 noVNC
echo "[4/5] Starting noVNC..."
/opt/novnc/utils/novnc_proxy \
    --vnc localhost:$VNC_PORT \
    --listen $NOVNC_PORT \
    --web /opt/novnc &

# 等待 noVNC 启动
sleep 1

# 启动 Chrome
echo "[5/5] Starting Chrome browser..."
/scripts/start-chrome.sh &

echo "=========================================="
echo "  Chrome VNC is ready!"
echo "  noVNC:  http://localhost:$NOVNC_PORT"
echo "  CDP:    http://localhost:$CDP_PORT"
echo "=========================================="

# 保持容器运行，等待所有后台进程
wait
