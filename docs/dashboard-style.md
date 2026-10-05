# Dashboard 风格复用

按用户要求直接复用 `/Users/raychen/Develop/Dashboard/dashboard-HarmonyOS` 的实现。参考工程只读，没有改动。

## 原样复制

| Loci 文件（entry/src/main/ets 下） | 复用方式 | SHA-256 |
| --- | --- | --- |
| `common/vibration.ets` | 完整复制，逐字节一致 | `ede7720d13153548c9e1e2c49b457e1a1c411851d18f92f75340a64e6c15a8e0` |
| `common/visualEffects.ets` | 完整复制，逐字节一致 | `20b395550c18074ddd84bf979df1d8edbdde38e98529a93fd829739f4a34f87a` |
| `common/motion.ets` | 完整复制，逐字节一致 | `d82d3222ce38cd1c88ebfcf407dd6f2415aa6973eb7d803dea97bcb9d5092947` |
| `common/platformCompatibility.ets` | 完整复制，逐字节一致 | `509f66c9334c859877930f9eab337c322373ff7692ddd7a6073e83a48562d560` |

三种体验设置图标 `vibrate.png`、`immersive.png`、`light.png` 的 base/dark 资源原样复制自 Dashboard AppScope。品牌及地图旗帜继续使用 Loci 资源。

## 接入与维护

- `AppShell`：HdsTabs 承载三个页面。沿用 `Dashboard.mainTabsView` 的 250vp 悬浮底栏、28vp 底距、92vp 渐变区域、缓存、模糊与 adaptive 材质。标签页缩放、透明度与弹簧参数亦取自 Dashboard。按 Loci 页面数量将缓存数设为 3。
- `HdsNav`：每个一级页面拥有 HdsNavigation 与独立 NavPathStack。详情使用 HdsNavDestination；记录、定位、筛选、重访与保存使用原生 toolbar。
- `NavigationStyle`：复用 AppDetailPage 的透明 titleBar、系统主标题色、菜单色、滚动效果配置和材质参数，抽出标题与设置等级入参。
- `ActionButton`、`VisitCard`：沿用 Dashboard 的 pressed 状态、0.985 缩放、130ms 弹簧、Up/Cancel 恢复、点光源与 HDR 滤镜。预览和状态卡使用 16vp 圆角、14vp 边距、8vp/2vp 阴影。
- `ExperiencePanel`：直接复制 SettingsPanel 的三档滑杆与原生 HdsListItemCard 构建方法，保留窄屏换行、材质方向与 HDR 兼容处理。将 V1 状态与 storage 调用改接 Loci 的 ObservedV2 / Preferences。
- `ExperienceSettings`：持久化振动、光场、材质三个等级；只通过 AppStorage 中的数字桥接原样复制的工具。领域实体与数据库不依赖该 UI 设置。
- `common/icons` 统一引用系统 Symbol 与自定义资源；Map 服务和 UI 均从同一目录读取。
- 浅深色资源复制 Dashboard 的 background、diff_content、v3_surface、v3_surface_alt、v3_text_primary、v3_text_secondary、nd_card_border、v3_shadow、v3_scrim 等语义色。另加 Loci 的 on_accent 对比色。

动效接入：标签切换弹簧、按压点光源、卡片 contentEnterTransition、二级页面 pageTransition、设置分组 startStaggerEnterAnimation。页面销毁时取消定时器。API 24 HDR 方法只在设备版本支持时调用；API 23 使用普通光场。

## 已修复的集成问题

2026-10-06 真机发现 `AppShell.mapContent` 在 HdsNav 中读取 model 时崩溃。直接传给 BuilderParam 的成员 Builder 改变了 this；所有页面内容和 destination 均改为箭头闭包保留父组件上下文。编译成功不足以证明这条路径正常，因此另外执行冷启动、切页、设置与返回检查。

一级 mini titleBar 为 56vp，页面内容显式预留对应空间；底部另为悬浮 HdsTabs 预留 108vp，避免覆盖内容与 toolbar。
