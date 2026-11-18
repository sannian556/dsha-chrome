#!/bin/bash
# setup-chrome.sh — 在 DSHA Linux 容器(aarch64)部署 Chromium + 右栏浏览器
# 用法: bash setup-chrome.sh
# 环境变量:
#   DSH_BROWSER_PROXY        代理地址，默认 http://127.0.0.1:7890，设空串即直连
#   DSH_BROWSER_DISABLE_GPU  默认 1(省内存，WebGL/Canvas 会退化)，设空串则启用 GPU 合成
set -e

REV=1243

echo "== 0. 环境自检 =="
[ "$(uname -m)" = "aarch64" ] || { echo "错误: 需要 aarch64"; exit 1; }
[ "$(id -u)" = "0" ] || { echo "错误: 需要 root"; exit 1; }

echo "== 1. 安装依赖 =="
apt-get update || echo "警告: apt update 失败，继续尝试安装"
apt-get install -y \
  libglib2.0-0 libnss3 libnspr4 libasound2t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
  libcups2t64 libdrm2 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 \
  libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libdbus-1-3 libexpat1 libxkbcommon0 libxshmfence1 libx11-xcb1 \
  unzip fonts-noto-cjk fonts-noto-core

echo "== 2. 下载并解压 Chromium (revision $REV) =="
if [ "$(cat /opt/chromium/.rev 2>/dev/null)" != "$REV" ]; then
  rm -rf /opt/chromium
  mkdir -p /opt/chromium
  curl -L -sS -m 1800 --retry 3 \
    "https://cdn.npmmirror.com/binaries/playwright/builds/chromium/${REV}/chromium-linux-arm64.zip" \
    -o /tmp/chromium.zip
  ls -l /tmp/chromium.zip
  unzip -q -o /tmp/chromium.zip -d /opt/chromium
  rm -f /tmp/chromium.zip
  echo "$REV" > /opt/chromium/.rev
fi

echo "== 3. 建 wrapper =="
cat > /usr/bin/google-chrome <<'WRAPEOF'
#!/bin/bash
PROXY="${DSH_BROWSER_PROXY-http://127.0.0.1:7890}"
ARGS=(--no-sandbox --disable-dev-shm-usage --lang=zh-CN --accept-lang=zh-CN,zh)
if [ -n "$PROXY" ]; then ARGS+=(--proxy-server="$PROXY"); fi
if [ -n "${DSH_BROWSER_DISABLE_GPU-1}" ]; then ARGS+=(--disable-gpu); fi
exec /opt/chromium/chrome-linux/chrome "${ARGS[@]}" "$@"
WRAPEOF
cp /usr/bin/google-chrome /usr/bin/chromium
cp /usr/bin/google-chrome /usr/bin/chromium-browser
chmod 755 /usr/bin/google-chrome /usr/bin/chromium /usr/bin/chromium-browser

echo "== 4. 权限 =="
chmod 755 /opt/chromium /opt/chromium/chrome-linux 2>/dev/null || true
chmod -R a+rX /opt/chromium/chrome-linux
chmod 755 /opt/chromium/chrome-linux/chrome \
          /opt/chromium/chrome-linux/chrome_crashpad_handler \
          /opt/chromium/chrome-linux/chrome_sandbox 2>/dev/null || true

echo "== 5. 字体缓存与校验 =="
fc-cache -f 2>/dev/null || true
fc-list 2>/dev/null | grep -qi "Noto Sans CJK" || echo "警告: 中文字体可能没装上，中文会显示方框"

echo "== 6. 依赖检查(应为空) =="
missing=$(ldd /opt/chromium/chrome-linux/chrome | grep "not found" || true)
if [ -n "$missing" ]; then echo "缺失依赖:"; echo "$missing"; exit 1; fi
echo "依赖齐全"

echo "== 7. 验证 =="
/usr/bin/google-chrome --version

echo "== 8. 清理 =="
apt-get clean 2>/dev/null || true
rm -rf /var/lib/apt/lists/* 2>/dev/null || true

echo "== 完成 =="
echo "下一步: 在 DSHA 插件市场安装 dsh-inner-browser-use (0.47.101)"
echo "      并按 PATCHES.md 打视口补丁(记得 dpr 改 1)"
echo "风险提示: --no-sandbox + root 运行，建议只登小号/只读账号，不要放主力凭据"
