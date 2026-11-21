# Dashboard 风格复用

按用户要求直接复用 `/Users/raychen/Develop/Dashboard/dashboard-HarmonyOS` 的实现。参考工程只读，没有改动。

## 2026-10-30 用户再次明确后的精确对齐

按用户最新要求，品牌区恢复Dashboard原实现的居中竖排：100vp图标、图标底距10vp、30/20sp主副标题、800/600字重、上下18/左右12vp内边距，移除自加的左图卡片与边框。这是本页品牌区对先前卡片标题限制的明确覆盖，其余页面标题约束保留。

用户名恢复原生TextInput行内编辑，布局与Dashboard UsernameEditor一致：左标签、右204vp区域、40vp输入框及22vp说明入口；失焦、提交或离开标签时保存。成功写入后才更新已提交状态，失败保留草稿并显示原生错误提示。移除用户名Sheet路由和目的地。我的页不再构造空白titleBar stackBuilder，避免低版本透明区域拦截靠近标题栏的输入交互。

缓存大小按1024进位自动显示B/KB/MB/GB/TB，保留一位小数并去除多余零，进位边界不会显示1024 KB；未知或非法值显示“-”。加入三项原生格式边界回归。

以下规格复核及05:15记录保留为历史，左图卡片和用户名Sheet已由上述实现替代。

## 2026-10-30 我的页面规格复核

按当前 `pages/main/MyPage.ets`、`components/settings/SettingsPanel.ets` 与 `UsernameEditor.ets` 对照：品牌图标 100vp，主副标题 30/20sp、800/600 字重，内边距上下18/左右12；分组标题14sp、缩进4vp，组距14vp、标题内容间距8vp；原生设置卡高68vp（窄屏116vp）、操作行54vp、缓存行52vp，圆角16vp，前后缀边距8vp，滑杆190vp与三档标签40vp。恢复用户名左标签、右侧204vp区域、40vp字段和22vp说明入口。材质选项遵循参考实现，仅API23及以上显示。图标和语义色继续复用参考资源。

遵循先前主副标题仅放在左图/带框卡片内的要求，品牌区目前保留左图卡片；用户名编辑继续进入唯一共享Sheet，未恢复参考工程的行内自动保存。顶部系统/标题栏安全区由原生布局处理，不复制参考工程为沉浸标题预留的100/110vp顶部占位。宽屏仍为840vp阈值、4:6分栏、16vp栏距、1440vp内容上限。主包与测试包构建通过。05:15续跑使用独立API24手机模拟器，原生业务/数据库29项、UI10项均通过，并检查手机、1440vp宽窗口分栏/Sheet及平板兼容窗口截图；窗口就绪等待已修正，初始输入法向导完成后复测。真机仍断开，本轮真机安装及UI复测待恢复连接，不沿用上一轮真机测试结果作为本轮通过证据。详见 `verification-20261030-0515.md`。

## 2026-10-30 顶部栏避让修复

主导航和普通目的地的 `titleBar` 开启 API20 原生 `avoidLayoutSafeArea` 与 `enableComponentSafeArea`，标题、按钮及分段控件避让系统状态栏，正文避让标题栏；Sheet 已由系统定位于安全区内，仅开启组件级避让，避免再次累加状态栏高度。内容不再以 64/72/80/88vp 占位模拟标题栏。导航背景继续延展到系统区域，地图控件从内容区内侧布局。

PLA-AL10 / API26 真机保留数据更新安装，主包与测试包构建成功，10 项 UI 回归全部通过（0 失败、0 错误、0 跳过），涵盖主标签与分段状态、Sheet 反复开关/侧滑/草稿保护、保存编辑删除、二级页面重入、地点内切换、浅深色、大字号、横屏及前后台恢复。已检查主页面与显示配置截图。本次未重新运行 API20 模拟器。证据：`build/verification/topbar-20261030/`。

## 2026-10-29 原生导航与兼容调整

最低 API20，目标 API26，版本判断继续参考当前 Dashboard。窗口初始化使用原生沉浸布局，与安全区扩展保持一致，避免旧版本显示位置与触控位置错位。一级入口保持记录/地点/统计/我的，根页使用 SegmentButtons，地点详情用 HdsTabs 切换地点与到访记录。API23 的浮动材质与缓存配置在调用前隔离；API20–22 使用原生底栏并预留系统手势区。

事项、作息、到访、筛选、用户名和短时账号操作复用一个根 bindSheet 宿主。每次会话使用独立导航栈，旧面板消失后才创建下一会话；关闭、系统返回和手势统一处理未保存确认。关闭按钮使用原生 titleBar backIcon，避免系统 Sheet 关闭按钮与保存按钮重叠。

目的地以 onShown 触发每次入场，以 onHidden 和销毁回调清理动画；入口通过真实 onBackPress 分发返回，目的地绑定 onBackPressed。地图同步与日期计时器跟随应用前后台状态。页面和分组使用单一标题，主副标题仅用于带图或带框的卡片。设置中的用户名改为原生表单 Sheet，写入成功后才关闭。

以下是历史记录，旧 API23 基线、独立编辑页和大标题品牌区已被本轮结构替代。

## 当前实现 · 2026-10-22

应用已更名时迹。四个HdsTabs为记录/地点/统计/我的，缓存数4；我的页按真实Dashboard MyPage对齐，内嵌设置、账号与帮助分组保持原有结构、字号、间距、动效与光场。记录行去掉卡片装饰，采用Markdown式项目符号与时间＋事项；边界为用户记录的起床/睡觉。所有编辑/保存/删除操作进入子页原生titleBar menu，取消保存toolbar和正文保存按钮。应用图标使用1024×1024透明前景/不透明背景，经layered_image和DrawableDescriptor渲染，API26真机已确认时钟与地点同时可见。

以下为迭代历史；先前的三个标签、24:00/00:00边界、普通startIcon与保存toolbar已由当前实现替代。

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

之前把 Navigation 放在 Tabs 内并额外加 56/108vp padding，偏离 Dashboard，造成沉浸与位置问题。本轮移除这套布局；列表内容使用参考工程的首尾留白，地图本体延伸到背景，悬浮预览单独避让底栏。新布局已构建安装并完成 API 26 冷启动、三标签与所有分段、设置滚动、返回和振动重启恢复。真机发现多个地图菜单遮住 Segment，已将 titleBar menu.maxCount 设为 1，由 HDS 原生更多菜单承载全部地图动作。Segment 和主 Tabs 在各根页面与返回后位置一致。其他设备尺寸、字体和真实地图仍未验收，不能宣称完整 1:1 视觉验收通过。


## 2026-10-07 分段控件阴影修复

同步用户已在 Dashboard 真机确认的修复：HdsMiniBarButton 的 HdsTabs 背景以实际高度（barHeight − 12）的一半为圆角单独裁剪，避免胶囊四角露出灰色矩形；背景不参与命中测试，前景按压光效和 V2 状态回调保持原样。HdsTitleBarSegment 显式关闭背景模糊，由外层迷你栏统一提供材质。`sh scripts/build.sh main` 构建及签名成功，`git diff --check` 通过。本轮未安装 Loci 修复包或进行修复后的真机截图验收。


## 2026-10-22 每日记录重构

先形成 UI/UX 方案和交互设计稿，再落地 ArkUI；参考工程仍只读。主导航改为记录/统计/我的，保留 Dashboard HdsNavigation 外壳、固定分段、250vp 悬浮底栏和材质参数。新增 ProfileRow 直接参考 Dashboard MyPage.MoreRow 的 HdsListItemCard/PrefixIcon/SuffixCustomBuilder/56vp高度及分组写法，适配 V2。

ActivityCard 沿用 VisitCard 的按压状态、0.985缩放、130ms弹簧、点光源、HDR滤镜与阴影。JournalPage、StatisticsPage、ProfilePage 使用原有分组入场和计时器清理；ActivityEditorPage、PlacesPage、InformationPage 使用 pageTransition 与 destinationTitle。表单动作复用 ActionButton，设置继续使用 ExperiencePanel 和同一持久化链路。分类颜色添加独立浅深色资源；饼图使用原生 Path，避免不可用的 Chart 组件和新版本专属调用。

主包/测试包构建通过，API24临时手机模拟器25项原生回归通过，设计稿浏览器布局和原生导航/空态/账号状态已检查。短内容Scroll默认居中造成顶部空白，已保留100vp标题栏避让并显式顶部对齐；饼图坐标按SDK从vp转换为px。没有将原型截图描述为原生截图；API23/26真机完整视觉一致性仍待验收。


## 2026-10-22 用户纠正后的对齐

地点恢复为「记录 / 地点 / 统计 / 我的」四个一级 HdsTabs 之一，统一根 HdsNavigation，地图/地点的分段与原生菜单保持固定位置。移除前一版的地点二级页与我的地点入口；新地点保存后回到地点标签观察落旗。

ProfilePage 按当前 Dashboard MyPage 的实际实现重新排布：appIdentity → settingsAndLinks → versionInformation。应用图标100vp、品牌字号30/字重800/强调色、副标题20/600、14vp组间距、设置直接内嵌ExperiencePanel，账号和帮助是有标题的分组；54vp HdsListItemCard 和20vp右箭头替换前版56vp行与文字箭头。profile_right/profile_log/profile_info/profile_sync 图片直接复制参考工程base/dark资源。5组入场仅在该页首次激活时播放；840vp以上复用4:6分栏结构。

首页按起始时间倒序显示当天全部记录，增加24:00与00:00边界；周网格仍按真实时间坐标定位，统计聚合不受排列方向影响。


API26真机续测：我的页应用图标在普通Image中无法显示原分层资源，已使用现有startIcon普通图片并实测可见。已对照参考的应用标识字号、设置组、图片箭头、卡片间距、账号与帮助分组和版本信息完成上下屏截图检查；二级关于页隐藏主Tabs、返回保持滚动位置。日期高优先级手势仅作用于列表，周视图保留独立水平滚动，固定时间轴和短时段色条避免溢出。所有QA录入已清理。
