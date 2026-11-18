# 补丁说明

## 右栏虚拟视口

**问题**：手机上右栏宽度过窄，桌面优先站点（B 站、Bing、抖音等）右侧内容被裁切。

**改法**：在 dsh-inner-browser-use 的 `client.js` 里，把上报给 Chrome 的视口从「栏宽」改成「桌面宽度 + 等比高度」，并将 `dpr` 设为 `1`。

**关键：`dpr` 必须改为 1。** 否则 CSS 1024 宽 × dpr 3 会按 3072 光栅化，内存和 CPU 成倍上升（复杂页可达约 1.8GB）。

```diff
- if (Math.abs(Number(view?.w ?? 0) - size.w) < 1 && Math.abs(Number(view?.h ?? 0) - size.h) < 1) return undefined
+ const wantW = Math.max(1024, Math.round(size.w))
+ const wantH = Math.round(wantW * (size.h / size.w))
+ if (Math.abs(Number(view?.w ?? 0) - wantW) < 1 && Math.abs(Number(view?.h ?? 0) - wantH) < 1) return undefined
...
- body: JSON.stringify({ session: String(props.sessionId ?? ''), w: Math.round(size.w), h: Math.round(size.h), dpr: Number(window.devicePixelRatio) || 1 }),
+ body: JSON.stringify({ session: String(props.sessionId ?? ''), w: wantW, h: wantH, dpr: 1 }),