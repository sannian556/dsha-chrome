# DSHA-Chrome

在 [DSHA](https://github.com/DSH-APP/DSHA) 的 Linux 容器中部署 Chromium，使 AI 能够浏览网页、登录账号并执行页面操作。

## 特性

- **AI 浏览网页**：在 [DSHA](https://github.com/DSH-APP/DSHA) 右栏运行完整 Chromium，AI 可打开页面、点击、输入、滚动、读取内容
- **登录账号操作**：登录账号后，AI 可在已登录状态下代为操作页面。
- 面向 aarch64（arm64）Linux 容器，适配 [DSHA](https://github.com/DSH-APP/DSHA) 手机运行环境
- 启动 wrapper 内置 --no-sandbox 与代理环境变量，开箱即用
- 右栏虚拟视口补丁：解决手机窄栏裁切桌面优先站点的问题

## 安装

### 方式一：在线安装（推荐）

推荐使用此方式，**由 AI 自动安装**。让 AI 联网执行以下步骤：

1. 装依赖：`apt-get install -y libglib2.0-0 libnss3 libnspr4 libasound2t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 libcups2t64 libdrm2 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 libcairo2 libdbus-1-3 libexpat1 libxkbcommon0 libxshmfence1 libx11-xcb1 unzip fonts-noto-cjk fonts-noto-core`
2. 下载解压 Chromium：从 npmmirror 镜像拉 Playwright 官方构建（Chromium 153，revision 1243），用 `unzip` 解压，并用 sha256 校验
3. 建 wrapper：代理走环境变量 `DSH_BROWSER_PROXY`（空串即直连）；GPU 默认启用，设 `DSH_BROWSER_DISABLE_GPU=1` 才关（省内存，但 WebGL/滑块验证/地图/播放器会退化）
4. 修权限：`chmod 755` chrome、`chrome_crashpad_handler`
5. 依赖校验：`ldd ... | grep "not found"` 为空，`chrome --version` 输出 `Chromium 153.0.8010.12`
6. 装插件：在 DSHA 插件市场安装 `dsh-inner-browser-use`（0.47.101）
7. 打视口补丁：按 `PATCHES.md` 修改 `client.js`（`dpr` 改 `1`）
8. 验证：打开右栏，访问中文站点确认中文正常、宽站不裁边

完整可执行脚本见仓库 [`setup-chrome.sh`](https://github.com/sannian556/dsha-chrome/blob/main/setup-chrome.sh)。

### 方式二：本地安装包

下载本 Release 的 Assets 附件 `DSHA-Chrome.v1.0.0.zip`，解压后按包内 `README.md` 从包内取文件安装，不依赖网络。

> 注意：该包为早期版本，安装流程可能与当前 `setup-chrome.sh` 不一致，建议优先用方式一。

## 补丁

### 右栏虚拟视口

手机上右栏宽度过窄，桌面优先站点（B 站、Bing、抖音等）右侧内容被裁切。该补丁将上报给 Chrome 的视口改为桌面宽度，默认 1024，可按需调整：

- 内存紧张或希望字大 → 768
- 追求完整桌面布局 → 1280
- 降低内存占用 → 1024×640 固定桌面比例

**注意：补丁必须把 `dpr` 设为 `1`**（否则 CSS 1024 宽 × dpr 3 按 3072 光栅化，内存翻倍）。详细改动与调参见 [`PATCHES.md`](https://github.com/sannian556/dsha-chrome/blob/main/PATCHES.md)。

## 资源占用

安装的是完整的 Chromium 浏览器，因此占用资源较多，请量力而行：

| 资源 | 占用 |
|------|------|
| 磁盘 | 解压后约 740MB |
| 内存 | 运行时约 1–2GB；应用视口补丁后复杂页面可达约 1.8GB |

**风险提示**：wrapper 以 `--no-sandbox` + root 运行，用容器内隔离换可用性，建议只登小号/只读账号，不要放主力凭据。

## 致谢

- [dsh-inner-browser-use](https://github.com/regrevia/dsh-inner-browser-use)（作者 regrevia，MIT License）——驱动 [DSHA](https://github.com/DSH-APP/DSHA) 右栏浏览器，本项目视口补丁基于其 client.js 修改。
- [DSHA](https://github.com/DSH-APP/DSHA)（作者 qiannianhuanxiang，MIT License）——本项目面向的运行环境。

上游版权与许可声明均保留，不作改动。