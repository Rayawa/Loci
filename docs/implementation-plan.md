# Loci 第一版实施方案

状态：方案已确认并进入首轮实现。此文件中的工程盘点保留为实现前基线，当前状态见 [progress.md](progress.md)。检查日期：2026-10-05。

本轮遵循需求附件的“先输出方案，不要立即大规模修改工程”。本文件记录实现边界、架构、数据结构和验收标准，不表示应用已完成。

## 1. 范围与当前工程

第一轮交付：Project Foundation → Map → Place → Visit。用户能创建地点、记录纯文本 Memory、重启后恢复，再次到访复用同一个 Place 并增加独立 Visit。五档 Mood 可随 Visit 编辑加入；照片、视频、音频、Trip、Track、Atlas 在该闭环通过后逐项实现。

最终 v1 按附件 Phase 0–6 推进，持续维护各阶段状态。账号、云同步、社交、AI、攻略、全天候后台追踪、离线地图与分享不进入本轮核心。

已检查工程：

| 项目 | 当前证据与结论 |
| --- | --- |
| 应用身份 | `AppScope/app.json5`：`top.rayawa.loci`，版本 `1.0.0`，vendor 仍为模板值 |
| 平台 | `entry/build-profile.json5`：Stage Model；`build-profile.json5`：compatible `6.1.0(23)`、target `26.0.0` |
| 页面 | 只有 `entry/src/main/ets/pages/Index.ets` 的 Hello World |
| 生命周期 | 模板 EntryAbility；已跟随系统颜色模式，但业务主题和资源尚未建立 |
| 数据与系统服务 | 没有数据库、Repository、Map Kit、位置授权或业务实体 |
| 设备 | module 只声明 phone；尚未声明 tablet / 2in1 |
| 签名 | signingConfigs 为空，product 引用 default；运行前需核实签名配置 |
| 备份 | 模板已声明 BackupExtensionAbility，并允许备份；需要明确数据目录和恢复后重开数据库流程 |
| 测试 | Hypium / Hamock 已安装，只有模板断言，没有业务测试 |
| 工具链 | DevEco 位于 `~/Applications/DevEco-Studio.app`；随附 SDK 为 API 26 Release `26.0.0.105`，包含 hvigor、Node、hdc |
| 版本管理 | 当前目录不是 Git 仓库；没有 AGENTS.md 或 README |

未执行编译、安装或真机验证。现有 `.hvigor` 的同步记录不能代替完整构建验证。保留现有 HAP 和入口工程，逐步扩展，不推倒重建。

## 2. 目录与依赖

```text
docs/
  implementation-plan.md     # 范围、架构与验收
  progress.md                # 阶段、证据、阻碍
  api-matrix.md              # 官方来源、since、兼容路径
  decisions/                 # 数据、坐标、状态、迁移等 ADR
entry/src/main/ets/
  entryability/              # 保留；仅负责生命周期和装配
  entrybackupability/        # 保留；备份恢复协调
  pages/Index.ets            # 保留；挂载 AppShell
  app/                       # CompositionRoot、AppDependencies
  domain/
    model/                   # Place、Visit、Trip、媒体、轨迹
    repository/              # 类型明确的 Repository 接口
    service/                 # RecordVisit、ResolvePlace、UpdateMemory
  data/
    database/                # RdbStore 的获取、关闭、串行写事务
    entity/                  # 持久化行与 domain 映射
    repository/              # ArkData Repository 实现
    migration/               # 有序版本升级和回滚处理
    mock/                    # 仅测试/预览注入；正式数据库不自动灌数据
  service/
    location/                # 定位、授权、地理编码、坐标来源
    map/                     # Map Kit 控制器、Marker、相机、事件解绑
    haptics/                 # 按业务事件触发、异常降级
    capabilities/            # SDK / 设备能力判断
    media/                   # 后续：系统选择与沙箱媒体生命周期
    audio/                   # 后续：录制与播放
    track/                   # 后续：前台轨迹状态机
  ui/
    navigation/              # 路由名、参数、AppShell
    pages/                   # Map、PlaceDetail、VisitMemory、Settings
    viewmodel/               # 页面状态和操作；不暴露 RdbStore
    components/              # MapCanvas、PlacePreview、VisitCard、MoodSelector
    theme/                   # 语义色、间距、字体、原生交互效果
  utils/                     # 时间、坐标距离、ID 等小型纯函数
entry/src/test/              # 业务规则与 ViewModel
entry/src/ohosTest/          # 数据库、重启恢复、系统授权等设备测试
```

依赖方向：UI → ViewModel → domain 用例 / Repository 接口；data 和平台 service 实现由 app 装配。domain 不导入 ArkUI、Map Kit 或 RdbStore。界面不写 SQL、不申请权限、不掌管定位监听。

一个 entry HAP 先保证清晰的组件与功能边界；在出现真实跨模块复用需求时再抽 HAR。禁止循环依赖和万能工具类。状态管理优先采用 ArkUI V2（页面状态与纯领域对象分开），不混用 V1 / V2 对同一个对象的响应式管理。

组件按独立职责或可复用交互拆分，不给每一行文字单独造组件。MapCanvas 仅接收坐标、选中 ID、过滤结果以及事件；PlacePreview / VisitCard 使用展示模型；MoodSelector 使用枚举、Symbol、文案与选中状态共同表达。

## 3. 数据库 schema 初稿

UUID 字符串作为业务主键；UTC 毫秒作为瞬时时间；Trip 起止日期为日历日期字符串。Visit 额外记录当地时区/偏移和 localDate，未来按旅行当地日期分组，避免跨时区后历史日期改变。没有账号表，单一本地 Atlas 即可。

以下为逻辑 schema，尚未创建数据库。v1 migration 先建立 Place / Visit；其余表在相应阶段迁移中加入。v1 Visit 的 tripId 暂不建列，加入 Trip 时再迁移为可空外键。

| 实体 | 字段草稿 |
| --- | --- |
| Place | id TEXT PK；name / customName；latitude / longitude REAL；coordinateSystem TEXT；address / countryCode / country / province / city / district；provider / providerPlaceId 可空；favorite INTEGER；note；createdAt / updatedAt INTEGER |
| Visit | id TEXT PK；placeId TEXT FK；tripId TEXT FK 可空（Trip 阶段增加）；visitedAt INTEGER；endedAt INTEGER 可空；localDate / timeZone / utcOffsetMinutes；diary TEXT；mood INTEGER 可空，范围 1–5；source TEXT（current_location / map_selection / existing_place）；capturedLatitude / capturedLongitude / coordinateSystem / accuracy 可空；createdAt / updatedAt INTEGER |
| Trip | id TEXT PK；name TEXT；startDate / endDate TEXT；note TEXT；coverMediaId TEXT 可空；createdAt / updatedAt INTEGER |
| MediaAttachment | id TEXT PK；visitId TEXT FK；type TEXT（photo / video / audio）；uri / thumbnailUri TEXT；durationMs INTEGER 可空；mimeType TEXT；sortOrder INTEGER；createdAt / updatedAt INTEGER |
| Track | id TEXT PK；tripId TEXT FK；startTime / endTime INTEGER；distanceMeters REAL；durationMs INTEGER；status TEXT（recording / paused / completed / interrupted）；createdAt / updatedAt INTEGER |
| TrackPoint | id TEXT PK；trackId TEXT FK；sequence INTEGER；latitude / longitude REAL；coordinateSystem TEXT；timestamp INTEGER；altitude / accuracy REAL 可空；segment INTEGER（暂停恢复后分段，避免跨暂停连线） |

Place 的 firstVisitedAt、lastVisitedAt、visitCount 首轮由 Visit 聚合查询得到，并映射为领域展示字段。这样删除、补记、修改到访日期后不会留下错误缓存；数据量与性能证据确实需要时，再迁移加入缓存列并在同一事务中重算。

索引与约束：

- Visit(placeId, visitedAt DESC, id)：地点时间线；Visit(visitedAt, id)：时间轴。
- Place(city)、Place(countryCode)、Place(coordinateSystem, latitude, longitude)：筛选与附近候选粗筛。
- 后续 Visit(tripId, visitedAt, id)、MediaAttachment(visitId, sortOrder)、Track(tripId, startTime)、TrackPoint(trackId, sequence)；轨迹序号按 track 唯一。
- 已确认 providerPlaceId 时可对 provider + providerPlaceId 建唯一约束，手动地点不强造 POI ID。
- 检查经纬度范围、非空名称、mood 取值、endedAt ≥ visitedAt、Trip 结束日期 ≥ 开始日期。
- Place 删除需要明确确认；Visit / 附件元数据按关联清理。Trip 删除将 Visit.tripId 置空，不删地点与记忆；对应轨迹按既定策略清理。
- 启用并验证外键；迁移在事务内执行，成功后更新 RdbStore version。不能在失败时重建数据库或静默清空用户数据。
- 每次查询及时关闭 ResultSet；写事务串行执行；所有用户输入用参数绑定。
- 媒体二进制只在文件系统；URI/元数据入库。持久化时确认读取授权寿命，必要时复制到应用沙箱；删除文件与数据库需补偿和重试，不能先删可能仍被其他附件引用的文件。

地点识别流程：显式选择已有 Place → 已知且一致的 providerPlaceId → 坐标归一后附近候选 + 名称/地址匹配。附近仅为候选，不能把相邻店铺自动合并；精度不足、坐标系不一致或匹配含糊时让用户选择。现有 Place 详情的“再次来到这里”直接指定 placeId，不重新搜索。

RecordVisit 在一个事务内完成查重/复用、必要的新 Place、Visit 插入。提交成功后才更新 UI 与播放解锁反馈。操作带唯一 requestId（可作为 visit UUID），禁用重复提交，并通过唯一约束处理重试。不能用内存列表充当持久化来源。

坐标必须保留 coordinateSystem 和来源，Map Kit 的地图坐标与 Location Kit 定位坐标不能直接混算。转换只使用官方确认的接口；未确认转换路径前不做猜测算法，不做跨坐标系自动归并。

## 4. 导航与视觉

```text
EntryAbility → Index → AppShell / HdsNavigation + NavPathStack
  HdsTabs（默认 Map）
    Map → PlacePreview → PlaceDetail → VisitMemory
      记录这里 / 长按选择 → AddVisitSheet → 选择或新建 Place → VisitMemory
    Trips（后续启用）→ TripDetail → PlaceDetail / VisitMemory
    Atlas（后续启用）→ 国家 / 城市 / 年月 → PlaceDetail / VisitMemory
  Settings（二级入口）
```

Phase 0 可以建立三入口壳层，Phase 1 验收版不把未完成页包装成可用功能。路由参数只传 placeId、visitId、tripId 与小型类型明确的参数，由目标页面重新读取数据；返回地图保留相机、筛选与选中地点。页面 onActive 刷新业务数据，地图控制器不因普通状态刷新被反复创建。

地图是主视觉；顶层少量原生控制按钮，下方 PlacePreview 半模态，地点历史倒序展示。首次记录为“在这里留下第一段记忆”，重访为“再次来到这里”。落旗短动画和一次轻触感只在事务成功后触发。Marker 样式表达选中、访问次数与个人地点优先级，不干扰地图标识/署名。

从首轮建立浅深色语义资源、字号缩放、按钮无障碍名称、键盘避让和安全区。手机采用单栏；大屏根据窗口尺寸采用地图 + 详情分栏，功能相同。正式声明 tablet / 2in1 前完成对应设备验证。

## 5. Phase 0 / Phase 1 执行顺序

| 步骤 | 工作 | 可验证的完成标准 |
| --- | --- | --- |
| P0-1 | Git 基线、README、需求与决策文档、核实工具链与签名 | 现有模板完整编译；调试签名与本机配置不提交 |
| P0-2 | 类型模型、Repository 接口、应用装配、UI 状态模型 | domain 不依赖 UI/系统 Kit；可替换 Mock Repository |
| P0-3 | ArkData 打开、schema v1、migration、查询与事务 | 新建/重开数据库一致；迁移失败无丢数据 |
| P0-4 | Navigation、主题、状态组件、手机布局壳 | 返回栈正常；加载/空/错误/重试明确；浅深色可读 |
| P0-5 | Hypium 业务测试与设备数据库测试基架 | 重访身份、事务失败、日期聚合有可运行用例 |
| P1-1 | Map Kit 开通验证、client_id、真实地图、坐标规则 | 签名匹配的设备可显示地图；无网络/鉴权失败可重试 |
| P1-2 | 已存 Place Marker、点击/选中、地点预览/详情 | markerId → placeId 映射正确；列表与地图同源 |
| P1-3 | 单次定位授权与长按补记、附近 Place 候选 | 拒绝授权也可手动选择；低精度不自动错误合并 |
| P1-4 | RecordVisit 事务、输入校验、重复提交保护 | 新地点 1 Place + 1 Visit；重访仍 1 Place + 2 Visits |
| P1-5 | Visit 文本编辑/保存，必要的五档 Mood | 两个 Visit 的文本独立；失败保留编辑内容；返回再进可恢复 |
| P1-6 | 解锁动画、触感、系统 Symbol、原生按压效果 | 成功后反馈；失败不显示落旗成功；禁用触感不影响保存 |
| P1-7 | 重启验收、真实设备/API 23 与 26 验证 | 杀进程后数据存在；重复到访身份正确；版本兼容有实测证据 |

关键验收用例：

1. 空数据库进入真实地图，创建地点并写第一段 Memory。
2. 杀进程后重开，旗帜、地点 ID、日记与 Visit 时间不变。
3. 显式重访同一地点，仍一个 Place，倒序显示两个独立 Visit。
4. 补记早于首次记录的 Visit，最早/最近到访日期与次数准确。
5. 拒绝定位/定位超时/地理编码失败，仍可手动完成记录；不使用伪造当前位置。
6. 相邻两家店铺不因距离近被错误合并；地图选点与定位经坐标检查后显示一致。
7. 双击保存、写入中断或返回页面，不能产生半个地点或重复 Visit。
8. 编辑保存失败保留文本并可重试；删除一次 Visit 不影响其他 Memory。

闭环通过后：P2 媒体与录音 → P3 Trip CRUD/时间分组 → P4 前台轨迹状态机/持久化 → P5 Atlas → P6 兼容性、性能和原生体验全面验收。阶段功能通过后再进入下一阶段。

## 6. 官方 API / Kit 与验证方式

| Kit | 首轮用途 | 接口确认与阶段 |
| --- | --- | --- |
| Ability Kit | UIAbility、生命周期、UIAbilityContext、运行时授权 | 沿用现有 Stage；核实 abilityAccessCtrl 权限申请 |
| ArkUI | Navigation、NavPathStack、NavDestination、Tabs、bindSheet、SymbolGlyph、表单/列表、状态管理 | 基础导航有官方文档；所有实际选用属性逐项记录 since |
| ArkData | relationalStore、RdbStore、ResultSet、事务、版本 | 官方模块文档 + 本机声明确认实际重载，先用 API 23 内可用能力 |
| ArkTS | util.generateRandomUUID | 本机官方声明 since 9；不用时间戳/自增冒充稳定 ID |
| Map Kit | MapComponent、MapComponentController、Marker、相机、地图事件、坐标转换/地点查询 | 开通地图、client_id、签名指纹和设备服务验证；地理信息失败允许手动填名称 |
| Location Kit | geoLocationManager.getCurrentLocation、地理编码 | 本机 getCurrentLocation since 9；用户操作时授权，处理近似位置/拒绝/关闭/超时 |
| UIDesignKit | hdsEffect 的按压阴影 | 官方指南明确从 API 20 支持；用于地图操作和记忆卡片 |
| Sensor Service Kit | vibrator 轻量触感 | 具体效果、权限和设备支持逐项确认；异常无反馈降级 |
| Performance Analysis Kit | hilog、耗时/错误诊断 | 日志不包含私密日记、精确坐标和媒体内容 |
| 后续媒体 Kit | PhotoAccessKit、CoreFileKit、MediaKit | P2 确认系统选择、授权保留、AVRecorder/AVPlayer、Video 的实际 API |

### 官方资料

- [Navigation / NavPathStack](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-basic-components-navigation)
- [Navigation 分栏](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/arkts-navigation-split-mode)
- [ArkData relationalStore](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/api/arkts-apis-data-relationalstore)
- [MapComponent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V13/map-mapcomponent-V13)（该链接为历史 API 参考；实现前对照当前 SDK，不能直接照抄旧例）
- [Map Kit 集成场景：开通、client_id、定位权限](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)
- [Map Kit 简介与区域坐标系](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V13/map-introduction-V13)（坐标策略实现前核实当前参考）
- [Location 官方指南](https://developer.huawei.com/consumer/ru/doc/atomic-guides/atomic-location-development)
- [UI Design Kit 按压阴影](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-visual-effect-background-color)
- [沉浸光感简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-immersive-light-sense-overview)

官方网页部分动态内容无法完整读取，当前方案同时核对随附官方 SDK 声明；实现前未核实的接口不写入业务代码。API 矩阵需记录具体重载/枚举/系统能力，不能只写 Kit 名称与一个版本号。

## 7. API 23–26 兼容性与风险

| 风险 | 处理 |
| --- | --- |
| target 26 不等于运行系统 26 | 基线代码只用 API ≤23 的接口；新接口调用、参数、构造与枚举均隔离并检查实际运行 API |
| 沉浸光感版本与设备差异 | 本机 `@ohos.arkui.uiMaterial` since 26.0.0，并提供 `isImmersiveMaterialSupported()`；版本判断后再查设备能力，旧系统使用原生颜色/已有材质。模块加载兼容性需实机验证，不能只给方法调用加 if 就宣称完成 |
| 沉浸材质性能 | 首轮只考虑导航、底部栏、半模态/少量地图控制；避免铺满卡片，按官方适用组件与功耗要求验证 |
| 按压阴影 | 已确认 since 20，在 API 23 基线可用；具体组件 visualEffect 支持仍按选用接口校验 |
| 球形地图版本误判 | 本机官方 `sphereEnabled` / `setSphereEnabled(boolean)` 标注 since 5.0.3(15)，并非 API 26 专属；后续研究 Atlas，不用它作为“必须 API 26”的理由。新增重载各自核查 |
| 地图服务未开通/签名不匹配 | 无 client_id、AGC 开通和指纹证据前不能宣称地图接入完成；保留错误与重试，数据库功能可独立验证 |
| 坐标体系与定位精度 | 显式记录 CRS/来源；距离计算和展示必须确认转换；近似位置不自动归并 |
| API 26 DB 或 UI 新重载误用 | 每个新重载核对 since；事务与迁移选择基线已支持接口，旧系统功能路径完整 |
| 媒体授权跨重启 | P2 必须验证 URI 可持久读取或沙箱复制；不能只在选择当天可显示就算完成 |
| 轨迹后台与恢复 | P4 仅前台手动记录；后台/中断暂停并持久化状态，恢复后明确让用户继续；不承诺熄屏持续记录 |
| 构建通过而兼容未验证 | API 26 构建 + API 23 真机/对应模拟器 + API 26 设备验证分别记录；无法运行的项目标记待验证 |

实现阶段维护 progress.md，每项区分“待实施 / 实施中 / 已实现待验证 / 已验证 / 外部依赖”。每个完成项记录相关代码、构建或测试命令与结果。Git 只做本地版本管理，不默认推送或发布；私钥/证书密码/个人设备配置不入库。

用户补充导航约束：使用 HdsNavigation，一级入口由 HdsTabs 承载，详情页采用 HdsNavDestination；记录、筛选、重访、保存等上下文动作充分使用原生 toolbar。已按此约束实现并编译。当前下一步见 progress.md，整个应用第一版目标仍未完成。
