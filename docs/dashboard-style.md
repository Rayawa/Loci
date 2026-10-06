# Dashboard 风格复用

按用户要求直接复用 `/Users/raychen/Develop/Dashboard/dashboard-HarmonyOS` 的实现。参考工程只读，没有改动。

## 原样复制

| Loci 文件（entry/src/main/ets 下） | 复用方式 | SHA-256 |
| --- | --- | --- |
| `common/vibration.ets` | 完整复制，逐字节一致 | `ede7720d13153548c9e1e2c49b457e1a1c411851d18f92f75340a64e6c15a8e0` |
| `common/visualEffects.ets` | 完整复制，逐字节一致 | `20b395550c18074ddd84bf979df1d8edbdde38e98529a93fd829739f4a34f87a` |
| `common/motion.ets` | 完整复制，逐字节一致 | `d82d3222ce38cd1c88ebfcf407dd6f2415aa6973eb7d803dea97bcb9d5092947` |
| `common/platformCompatibility.ets` | 完整复制，逐字节一致 | `509f66c9334c859877930f9eab337c322373ff7692ddd7a6073e83a48562d560` |
| `common/DiskStorage.ets` | 完整复制，逐字节一致 | `9288fb6f54d21428ad3d8a5862e8c7b4203538412da0abd857754d01e7da0705` |
| `common/safeUi.ets` | 完整复制，逐字节一致 | `7e7765a50fc6aa668bba4651e0b52cf1fefff70a9ab86ba0c3f1b71ad7e2de8f` |

三种体验设置图标 `vibrate.png`、`immersive.png`、`light.png` 的 base/dark 资源原样复制自 Dashboard AppScope。品牌及地图旗帜继续使用 Loci 资源。

## 接入与维护

- `AppShell`：HdsTabs 承载三个页面。沿用 `Dashboard.mainTabsView` 的 250vp 悬浮底栏、28vp 底距、92vp 渐变区域、缓存、模糊与 adaptive 材质。标签页缩放、透明度与弹簧参数亦取自 Dashboard。按 Loci 页面数量将缓存数设为 3。
- `HdsNav`：改为与 Dashboard 相同的外层 HdsNavigation → HdsTabs，统一 NavPathStack。移除 TabContent 的底部 padding 与内层导航的顶部 padding，采用原工程的 ignoreLayoutSafeArea。进入二级详情时主 Tabs 随根页面隐藏；重访与保存保留原生 toolbar，地图动作放入 titleBar menu。
- `HdsTitleBarSegment`、`HdsMiniBarButton`：直接取自 Dashboard，标题栏 stackBuilder 固定承载地图/地点、旅程/轨迹、城市/国家/时间的二级切换。保留 50% 宽度、52vp 容器、40vp 按钮、32vp 项高度、迷你 HdsTabs 材质与按压参数。Segment 状态适配 V2 Event/Param，业务文案与可访问性适配 Loci。
- `NavigationStyle`：复用 AppDetailPage 的透明 titleBar、系统主标题色、菜单色、滚动效果配置和材质参数，抽出标题与设置等级入参。
- `ActionButton`、`VisitCard`：沿用 Dashboard 的 pressed 状态、0.985 缩放、130ms 弹簧、Up/Cancel 恢复、点光源与 HDR 滤镜。预览和状态卡使用 16vp 圆角、14vp 边距、8vp/2vp 阴影。
- `ExperiencePanel`：按参考工程当前显示顺序排列用户名、振动、材质、缓存；光场滑杆与原工程一样保留构建方法但不显示。用户名编辑器、卡片高度、分隔线、前后缀边距、窄屏换行、滑杆方向与缓存说明图标来自 SettingsPanel。
- `SettingsPage`：按 MyPage 的图标/名称 → 设置分组 → 版本信息顺序，保留 100/110vp 首尾留白、14vp 页面边距、分组动画、原生滚动弹性与透明 titleBar。品牌和说明使用 Loci，不复制 Dashboard 的投稿、网页、备案或遥测业务。
- `ExperienceSettings`：调用直接复制的 storage → DiskStorage → app_storage → AppStorage 单一通道，EntryAbility 在加载界面前水合；保留串行写入。storage 增补 loci-experience 三档旧设置迁移，已有偏好不清空。地点与记忆继续由 ArkData RDB 管理。
- `common/icons` 统一引用系统 Symbol 与自定义资源；Map 服务和 UI 均从同一目录读取。
- 浅深色资源复制 Dashboard 的 background、diff_content、v3_surface、v3_surface_alt、v3_text_primary、v3_text_secondary、nd_card_border、v3_shadow、v3_scrim 等语义色。另加 Loci 的 on_accent 对比色。

动效接入：标签切换弹簧、按压点光源、卡片 contentEnterTransition、二级页面 pageTransition、设置分组 startStaggerEnterAnimation。页面销毁时取消定时器。API 24 HDR 方法只在设备版本支持时调用；API 23 使用普通光场。

## 已修复的集成问题

2026-10-06 真机发现 `AppShell.mapContent` 在 HdsNav 中读取 model 时崩溃。直接传给 BuilderParam 的成员 Builder 改变了 this；所有页面内容和 destination 均改为箭头闭包保留父组件上下文。编译成功不足以证明这条路径正常，因此另外执行冷启动、切页、设置与返回检查。

之前把 Navigation 放在 Tabs 内并额外加 56/108vp padding，偏离 Dashboard，造成沉浸与位置问题。本轮移除这套布局；列表内容使用参考工程的首尾留白，地图本体延伸到背景，悬浮预览单独避让底栏。新布局已构建安装，真机启动验收曾被锁屏拒绝，待解锁后检查真实坐标、滚动、返回和设置恢复。不能把参数复用当作视觉验收通过。
