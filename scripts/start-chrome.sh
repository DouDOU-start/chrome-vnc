#!/bin/bash
set -e

# 基础 Chrome 参数（反自动化检测）
CHROME_FLAGS=(
    # CDP 远程调试
    "--remote-debugging-port=${CDP_PORT}"
    "--remote-debugging-address=0.0.0.0"

    # 性能和稳定性
    "--no-sandbox"
    "--disable-dev-shm-usage"
    "--disable-gpu"
    "--disable-software-rasterizer"

    # 反自动化检测
    "--disable-blink-features=AutomationControlled"
    "--disable-infobars"
    "--disable-extensions"
    "--disable-default-apps"
    "--disable-component-extensions-with-background-pages"

    # 窗口设置
    "--start-maximized"
    "--window-position=0,0"

    # 其他优化
    "--disable-background-networking"
    "--disable-sync"
    "--disable-translate"
    "--disable-features=TranslateUI"
    "--metrics-recording-only"
    "--no-first-run"
    "--safebrowsing-disable-auto-update"

    # 忽略证书错误（开发环境）
    "--ignore-certificate-errors"

    # 允许在 root 下运行（容器环境）
    "--no-zygote"
    "--disable-setuid-sandbox"
)

# 代理服务器配置
if [ -n "$PROXY_SERVER" ]; then
    echo "[Chrome] Using proxy: $PROXY_SERVER"
    CHROME_FLAGS+=("--proxy-server=$PROXY_SERVER")
fi

# 自定义 User-Agent
if [ -n "$USER_AGENT" ]; then
    echo "[Chrome] Using User-Agent: $USER_AGENT"
    CHROME_FLAGS+=("--user-agent=$USER_AGENT")
fi

# 添加用户自定义参数
if [ -n "$CHROME_ARGS" ]; then
    echo "[Chrome] Additional args: $CHROME_ARGS"
    # 将 CHROME_ARGS 按空格分割并添加
    IFS=' ' read -ra EXTRA_ARGS <<< "$CHROME_ARGS"
    CHROME_FLAGS+=("${EXTRA_ARGS[@]}")
fi

# 设置 Chrome 用户数据目录
export CHROME_USER_DATA_DIR="/home/chrome/.config/chrome-data"
mkdir -p "$CHROME_USER_DATA_DIR"

# 启动 Chrome
echo "[Chrome] Starting with flags: ${CHROME_FLAGS[*]}"
exec google-chrome "${CHROME_FLAGS[@]}" --user-data-dir="$CHROME_USER_DATA_DIR" "about:blank"
