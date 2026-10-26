此目录归档2026-10-22的平面前景与当时说明；对应背景已保留在本目录background.png。以下提示词对应旧版前景。

# 时迹应用图标

时间与地点：橙色地点图钉中嵌入白色时钟。两层均为 1024 × 1024、1:1，无预制边框或圆角；系统负责启动器遮罩。

- `foreground.png`：上层图标，PNG alpha 透明背景。
- `background.png`：下层背景，完整不透明蓝色渐变。
- `layered_image.json`：HarmonyOS 分层资源描述，与 AppScope 和 entry 的资源描述一致。

工程资源副本位于 AppScope 与 entry 的 `resources/base/media/app_icon_foreground.png` 和 `app_icon_background.png`。修改原稿后需同步副本。启动器、启动窗口及应用内品牌图标均使用 `layered_image`；应用内通过 ResourceManager 获取 DrawableDescriptor 渲染。

生成方式：内置 image_gen；仅用系统 sips 等比缩放至精确 1024 × 1024，保留前景 alpha。未使用外部 API/CLI 生成。

## 前景最终提示词

Use case: logo-brand. Asset type: transparent foreground layer for the app 时迹. Create one compact, bold, perfectly smooth amber-orange location pin, containing a simple white analog clock dial inside its circular head. The pin is one continuous opaque solid shape; the clock is drawn ON the pin, with a small amber circular center and two amber clock hands. This must clearly communicate both time and place. Flat vector-like precision, smooth antialiased edges, solid fills, no grain, no worn texture, no speckles, no translucent material, no shadows or glow. A single connected pin silhouette, absolutely no disconnected decorative elements. Pin centered with generous 22% transparent margin on all sides on a square 1024x1024 canvas. Outside the pin must be genuine alpha transparency. The clock dial is solid white, not a hole. No text, frame, border, rounded app tile, or checkerboard drawing.

## 背景最终提示词

Use case: logo-brand. Asset type: opaque background layer for a layered mobile app icon. Square 1024x1024 edge-to-edge calm royal blue background, a very subtle smooth gradient from lighter blue upper left to deeper blue lower right, with restrained soft illumination. Absolutely no symbol, no pin, no clock, no text, no frame, no border, no rounded corners, no white margin, no texture or pattern. All pixels opaque. This is only the lower background layer; the upper icon layer is provided separately.
