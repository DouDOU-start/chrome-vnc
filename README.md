# Chrome VNC

带 VNC 远程桌面的 Chrome 浏览器 Docker 镜像。

## 特性

- 最新稳定版 Chrome 浏览器
- VNC 远程桌面（支持 noVNC Web 访问）
- Chrome DevTools Protocol (CDP) 支持
- 内置反自动化检测参数
- 代理支持（HTTP/SOCKS5）
- 中文字体支持

## 快速开始

```bash
docker run -d -p 6080:6080 -p 9222:9222 --shm-size=2g ghcr.io/doudou-start/chrome-vnc
```

访问 http://localhost:6080 即可通过 Web 控制浏览器。

默认 VNC 密码: `chrome`

## 使用场景

- 浏览器自动化需要人工干预时
- 远程浏览器测试
- 爬虫项目的验证码处理
- 在服务器上运行带界面的浏览器
- 需要远程调试的浏览器自动化场景

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DISPLAY` | `:99` | X 显示器 |
| `VNC_PORT` | `5900` | VNC 端口 |
| `NOVNC_PORT` | `6080` | noVNC Web 端口 |
| `CDP_PORT` | `9222` | Chrome CDP 端口 |
| `RESOLUTION` | `1920x1080x24` | 屏幕分辨率 |
| `VNC_PASSWORD` | `chrome` | VNC 密码 |
| `CHROME_ARGS` | `""` | 额外 Chrome 参数 |
| `PROXY_SERVER` | `""` | 代理服务器 |
| `USER_AGENT` | `""` | 自定义 User-Agent |
| `LANG` | `en_US.UTF-8` | 语言设置 |

## 端口说明

| 端口 | 用途 |
|------|------|
| 5900 | VNC 原生端口 |
| 6080 | noVNC Web 端口 |
| 9222 | Chrome CDP 端口 |

## 使用示例

### 基本使用

```bash
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  ghcr.io/doudou-start/chrome-vnc
```

### 使用代理

```bash
# HTTP 代理
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  -e PROXY_SERVER=http://user:pass@proxy:8080 \
  ghcr.io/doudou-start/chrome-vnc

# SOCKS5 代理
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  -e PROXY_SERVER=socks5://proxy:1080 \
  ghcr.io/doudou-start/chrome-vnc
```

### 自定义分辨率

```bash
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  -e RESOLUTION=1280x720x24 \
  ghcr.io/doudou-start/chrome-vnc
```

### 自定义 User-Agent

```bash
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  -e USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" \
  ghcr.io/doudou-start/chrome-vnc
```

### 使用 Docker Compose

```yaml
services:
  chrome:
    image: ghcr.io/doudou-start/chrome-vnc
    ports:
      - "6080:6080"
      - "9222:9222"
    environment:
      - RESOLUTION=1920x1080x24
      - VNC_PASSWORD=mypassword
    shm_size: '2gb'
```

## 与自动化工具集成

### go-rod (Go)

```go
package main

import (
    "github.com/go-rod/rod"
)

func main() {
    browser := rod.New().
        ControlURL("ws://localhost:9222").
        MustConnect()
    defer browser.MustClose()

    page := browser.MustPage("https://example.com")
    // ... 执行自动化操作
}
```

### Playwright (Node.js)

```javascript
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.connectOverCDP('http://localhost:9222');
    const context = browser.contexts()[0];
    const page = context.pages()[0];

    await page.goto('https://example.com');
    // ... 执行自动化操作

    await browser.close();
})();
```

### Puppeteer (Node.js)

```javascript
const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.connect({
        browserURL: 'http://localhost:9222'
    });

    const pages = await browser.pages();
    const page = pages[0];

    await page.goto('https://example.com');
    // ... 执行自动化操作

    await browser.disconnect();
})();
```

### Selenium (Python)

```python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

options = Options()
options.debugger_address = "localhost:9222"

driver = webdriver.Chrome(options=options)
driver.get("https://example.com")
# ... 执行自动化操作
```

## 反自动化检测

镜像内置以下反检测参数:

- `--disable-blink-features=AutomationControlled` - 禁用自动化检测标志
- `--disable-infobars` - 禁用信息栏
- `--disable-extensions` - 禁用扩展
- `--no-first-run` - 跳过首次运行向导

你可以通过 `CHROME_ARGS` 环境变量添加更多参数:

```bash
docker run -d \
  -p 6080:6080 \
  -p 9222:9222 \
  --shm-size=2g \
  -e CHROME_ARGS="--lang=zh-CN --disable-web-security" \
  ghcr.io/doudou-start/chrome-vnc
```

## 本地构建

```bash
# 克隆仓库
git clone https://github.com/DouDOU-start/chrome-vnc.git
cd chrome-vnc

# 构建镜像
docker build -t chrome-vnc:local .

# 运行测试
docker run -d -p 6080:6080 -p 9222:9222 --shm-size=2g chrome-vnc:local

# 访问
open http://localhost:6080
```

## 注意事项

1. **共享内存**: Chrome 需要足够的共享内存，建议使用 `--shm-size=2g` 或挂载 `/dev/shm`

2. **资源限制**: Chrome 是资源密集型应用，建议至少分配 2GB 内存

3. **安全性**: 生产环境请修改默认 VNC 密码

4. **网络访问**: CDP 端口 9222 默认绑定到 0.0.0.0，注意网络安全

## 故障排除

### Chrome 崩溃

通常是共享内存不足导致:

```bash
docker run -d --shm-size=2g ...
# 或
docker run -d -v /dev/shm:/dev/shm ...
```

### VNC 连接失败

检查容器日志:

```bash
docker logs chrome-vnc
```

### CDP 无法连接

确保端口映射正确，且没有防火墙阻止:

```bash
curl http://localhost:9222/json/version
```

## License

MIT License - 详见 [LICENSE](LICENSE) 文件
