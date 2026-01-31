# Chrome VNC - 带 VNC 远程桌面的 Chrome 浏览器容器
# https://github.com/DouDOU-start/chrome-vnc

FROM debian:bookworm-slim

LABEL maintainer="DouDOU-start"
LABEL description="Chrome browser with VNC remote desktop support"

# 环境变量
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    CDP_PORT=9222 \
    RESOLUTION=1920x1080x24 \
    VNC_PASSWORD=chrome \
    CHROME_ARGS="" \
    PROXY_SERVER="" \
    USER_AGENT="" \
    LANG=zh_CN.UTF-8 \
    LANGUAGE=zh_CN:zh \
    LC_ALL=zh_CN.UTF-8 \
    TZ=Asia/Shanghai \
    # 输入法配置
    GTK_IM_MODULE=fcitx \
    QT_IM_MODULE=fcitx \
    XMODIFIERS=@im=fcitx \
    INPUT_METHOD=fcitx

# 安装基础依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 基础工具
    ca-certificates \
    curl \
    wget \
    gnupg \
    locales \
    tzdata \
    procps \
    # X11 和 VNC
    xvfb \
    x11vnc \
    xterm \
    fluxbox \
    x11-xserver-utils \
    feh \
    # Python (noVNC 需要)
    python3 \
    python3-numpy \
    # 字体
    fonts-liberation \
    fonts-noto-cjk \
    fonts-wqy-zenhei \
    # 中文输入法
    fcitx \
    fcitx-pinyin \
    fcitx-googlepinyin \
    fcitx-frontend-gtk3 \
    fcitx-ui-classic \
    fcitx-config-gtk \
    im-config \
    # 剪贴板同步
    autocutsel \
    # 网络工具
    net-tools \
    dbus-x11 \
    && rm -rf /var/lib/apt/lists/*

# 设置语言环境
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    sed -i '/zh_CN.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

# 安装 Chrome/Chromium（根据架构选择）
# amd64: Google Chrome（官方版本，功能更完整）
# arm64: Chromium（Google Chrome 不支持 arm64）
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg && \
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
        apt-get update && \
        apt-get install -y --no-install-recommends google-chrome-stable && \
        ln -sf /usr/bin/google-chrome-stable /usr/bin/chrome; \
    elif [ "$ARCH" = "arm64" ]; then \
        apt-get update && \
        apt-get install -y --no-install-recommends chromium && \
        ln -sf /usr/bin/chromium /usr/bin/chrome; \
    fi && \
    rm -rf /var/lib/apt/lists/*

# 安装 noVNC
RUN mkdir -p /opt/novnc && \
    curl -sL https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xzf - -C /opt/novnc --strip-components=1 && \
    mkdir -p /opt/novnc/utils/websockify && \
    curl -sL https://github.com/novnc/websockify/archive/refs/tags/v0.11.0.tar.gz | tar -xzf - -C /opt/novnc/utils/websockify --strip-components=1 && \
    ln -s /opt/novnc/vnc.html /opt/novnc/index.html

# 创建非 root 用户
RUN useradd -m -s /bin/bash chrome && \
    mkdir -p /home/chrome/.config /home/chrome/.vnc && \
    chown -R chrome:chrome /home/chrome

# 复制脚本和配置
COPY scripts/ /scripts/
COPY config/ /config/

# 设置脚本权限
RUN chmod +x /scripts/*.sh

# 设置工作目录
WORKDIR /home/chrome

# 暴露端口
# 5900: VNC 原生端口
# 6080: noVNC Web 端口
# 9222: Chrome CDP 端口
EXPOSE 5900 6080 9222

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:${CDP_PORT}/json/version || exit 1

# 入口脚本
ENTRYPOINT ["/scripts/entrypoint.sh"]
