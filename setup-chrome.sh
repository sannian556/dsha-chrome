#!/bin/bash
# setup-chrome.sh — 在 DSHA Linux 容器(aarch64)部署 Chromium + 右栏浏览器
# 用法: bash setup-chrome.sh
set -e

echo "== 0. 环境自检 =="
[ "$(uname -m)" = "aarch64" ] || { echo "错误: 需要 aarch64"; exit 1; }
[ "$(id -u)" = "0" ] || { echo "错误: 需要 root"; exit 1; }

echo "== 1. 安装依赖 =="
apt-get update
apt-get install -y libglib2.0-0 libnss3 libnspr4 libasound2t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 libcups2t64 libdrm2 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libdbus-1-3 libexpat1 libxkbcommon0 libxshmfence1 libx11-xcb1 unzip fonts-noto-cjk fonts-noto-core

echo "== 2. 下载并解压 Chromium =="
if [ ! -x /opt/chromium/chrome-linux/chrome ]; then
  mkdir -p /opt/chromium
  curl -L -sS -m 1800 --retry 3 "https://cdn.npmmirror.com/binaries/playwright/builds/chromium/1243/chromium-linux-arm64.zip" -o /tmp/chromium.zip
  ls -l /tmp/chromium.zip
  unzip -q -o /tmp/chromium.zip -d /opt/chromium
  rm -f /tmp/chromium.zip
fi

echo "== 3. 建 wrapper =="
cat > /usr/bin/google-chrome <<'WRAPEOF'
#!/bin/bash
PROXY="${DSH_BROWSER_PROXY-http://127.0.0.1:7890}"
ARGS=(--no-sandbox --disable-dev-shm-usage --disable-gpu --lang=zh-CN)
[ -n "$PROXY" ] && ARGS+=(--proxy-server="$PROXY")
exec /opt/chromium/chrome-linux/chrome "${ARGS[@]}" "$@"
WRAPEOF
cp /usr/bin/google-chrome /usr/bin/chromium
cp /usr/bin/google-chrome /usr/bin/chromium-browser
chmod 755 /usr/bin/google-chrome /usr/bin/chromium /usr/bin/chromium-browser

echo "== 4. 权限 =="
chmod 755 /opt/chromium /opt/chromium/chrome-linux 2>/dev/null || true
chmod -R a+rX /opt/chromium/chrome-linux
chmod 755 /opt/chromium/chrome-linux/chrome /opt/chromium/chrome-linux/chrome_crashpad_handler /opt/chromium/chrome-linux/chrome_sandbox 2>/dev/null || true

echo "== 5. 字体缓存 =="
fc-cache -f 2>/dev/null || true

echo "== 6. 依赖检查 =="
missing=$(ldd /opt/chromium/chrome-linux/chrome | grep "not found" || true)
if [ -n "$missing" ]; then echo "缺失依赖:"; echo "$missing"; exit 1; fi
echo "依赖齐全"

echo "== 7. 验证 =="
/usr/bin/google-chrome --version
echo "== 完成 =="
