# DSHA-Chrome

在 [DSHA](https://github.com/DSH-APP/DSHA) 的 Linux 容器中部署 Chromium，使 AI 能够浏览网页、登录账号并执行页面操作。

## 安全提示

- **无沙箱运行**：wrapper 以 `--no-sandbox` + root 运行，用容器内隔离换可用性。页面若逃逸，受影响的是整个 dsh 环境（可能含 API key、会话数据）。
- **代理流量**：默认走 `127.0.0.1:7890`，账号登录流量会经过本机代理。
- **提示注入风险**：让 AI 在已登录账号的浏览器里点击/输入/提交，等于把账号操作权交给模型。页面上的恶意文字可能诱导 agent 改设置、转账、退出登录。建议只登小号/只读账号，不要放主力凭据。
- **平台风控**：国内平台对自动化操作有风控，建议先用小号试。

## 二进制校验

Chromium 来自 `cdn.npmmirror.com` 的 Playwright 官方构建（revision 1243）。脚本内置 sha256 校验：

```
f144b7f58b61c6bea2c192c4c178faa9b606bdf758e2d47ca99fa03f759a13e4
```

## 安装

见 [Releases](https://github.com/sannian556/dsha-chrome/releases)。

完整脚本见 [`setup-chrome.sh`](https://github.com/sannian556/dsha-chrome/blob/main/setup-chrome.sh)。
