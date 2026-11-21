# 已采用 API 与兼容性

依据：华为官方指南与 DevEco 随附 API 26 SDK（26.0.0.105）的声明和 since 标注。最低兼容 API 20，目标 API 26。接口声明、编译检查与设备运行证据分别记录。

| API / 组件 | 起始 API | 用途 / 兼容路径 |
| --- | --- | --- |
| HdsNavigation / HdsNavDestination / titleBar / toolbarConfiguration | 18 | 页面返回栈、原生标题与动作工具栏；基线 20 可用 |
| HdsTabs | 20 | 地图、旅行、足迹一级入口承载；基线 20 可用 |
| HdsNavigation titleBar menu.maxCount | 18 | 居中 Segment 页面限制为一个原生菜单占位，多个动作由 HDS 更多菜单承载；API 26 已验证无重叠 |
| TabSegmentButtonV2 / SegmentButtonV2Items | 18 | 复制 Dashboard 分段控件，固定在 titleBar stackBuilder；基线 20 可用 |
| HDS ignoreLayoutSafeArea | 18 | 导航背景延展至系统区域，交互内容由原生安全区避让 |
| titleBar.avoidLayoutSafeArea / enableComponentSafeArea | 20 | 根页和二级页避让系统状态栏，正文避让标题栏；Sheet 已在系统安全区内，仅启用组件级避让，移除固定高度占位 |
| HdsNavDestination.onShown / onHidden / onWillShow（无参数回调） | 18 | 页面重新显示时重播入场；地图跟随显示状态与 Ability 前后台状态，避免使用 API21 激活回调 |
| ArkUI V2 ObservedV2 / Trace / ComponentV2 | 12 | UI 状态与纯实体分离；基线 20 可用 |
| bindSheet / onWillDismiss / DismissSheetAction | 12（拦截关闭） | 录入面板、关闭防丢失、保存时阻止关闭 |
| UIContext.showAlertDialog | 10 | 使用当前窗口上下文显示原生确认 |
| util.generateRandomUUID | 9 | 地点、到访、请求稳定身份 |
| relationalStore.getRdbStore / querySql / executeSql | 9 | S3 本地数据库和参数化查询 |
| RdbStore.execute | 12 | 带结果的修改与删除 |
| createTransaction / Transaction.execute / querySql / commit / rollback | 14 | Place + Visit 原子写入与迁移 |
| MapComponent / getEventManager / marker / rectifyCoordinate | 12 | 地图、事件、旗帜、区域坐标归一；需要 AGC 地图服务 |
| MapEventManager.mapLoad | 11 | 控制器初始化后等待地图加载完成；15 秒超时提供重试并清理监听 |
| MapComponentController.animateCameraStatus | 12 | 首次保存等待聚焦结束再显示旗帜；基线 20 可用，真实地图未验收 |
| Marker.setAnimation / startAnimation、AlphaAnimation | 11 | 首次旗帜淡入，使用 Dashboard 的 280ms 入场时长；失败保留静态旗帜，真实地图未验收 |
| ohos.permission.GET_NETWORK_INFO / INTERNET | 8 / 9（SDK 权限声明） | Map Kit 网络状态查询与联网；normal 权限，模块声明即可；重新安装后 own-PID 日志未再出现网络查询 201，服务鉴权仍失败 |
| geoLocationManager.getCurrentLocation / getAddressesFromLocation | 9 | 用户触发单次定位与可失败的逆地理编码 |
| abilityAccessCtrl.requestPermissionsFromUser | 9 | 按需申请近似与精确定位 |
| hdsEffect.HdsEffectBuilder.pointLight | 20 | 原样复用 Dashboard 的按压光場与松开恢复 |
| HdsTabs.barFloatingStyle / cachedMaxCount / titleBar systemMaterialEffect | 23 | 复用 Dashboard 的 SDK 与发行版双判断；原生 HdsTabs 构建分支仅在支持时调用浮动与缓存配置。API20–22 使用原生底栏并避让系统手势区 |
| uiEffect.Filter.hdrBrightnessRatio | 24 | 仅高亮档按压时启用；API 20–23 降级普通光场，配置 HDR_BRIGHTNESS 权限 |
| vibrator preset / isSupportEffectSync / getVibratorInfoSync | 12 / 12 / 19 | 原样复制 Dashboard 的预置波形、能力检查、去重与三档设置；设备失败降级 |
| HdsNavDestinationTitleMode.MINI | 20 | 二级标题栏 |
| AbilityDelegator.startAbility | 9 | 原生测试能力启动，测试包内使用 |

高版本能力必须在访问之前隔离：API23 浮动栏、缓存策略与材质仅在版本判断通过后调用；API24 HDR 亦保留运行时隔离。高版本枚举不在 API20 启动路径提前解析。`apiAvailable` 本身自 API26 起提供，因此基础版本判断使用 `deviceInfo.sdkApiVersion`，HDS 材质同时核对发行版字段。

沉浸光感 `uiMaterial` 起始 API26，目前未引入；低版本保持语义色和已有 HDS 基础样式。地图与定位保留权限拒绝、服务失败和重试路径，编译成功不代表地图服务鉴权成功。

页面根入口通过真实 `onBackPress` 分发，目的地使用 `onBackPressed`，全局只有一个 `bindSheet` 宿主，原生关闭统一经 `onWillDismiss`。新会话等待旧 Sheet 的 `onDisappear` 后创建独立导航栈，异步保存回调通过会话 token 校验。

SDK 对照：`hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`、`@hms.core.map.map.d.ts`；`openharmony/ets/api/@ohos.data.relationalStore.d.ts`、`@ohos.geoLocationManager.d.ts` 与 `openharmony/ets/component/common.d.ts`。

官方指南：[关系型数据库](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)、[按压阴影](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-visual-effect-background-color)、[导航](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-basic-components-navigation)、[Map Kit](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)。部分动态页面无法完整提取，声明确认与编译、设备验收分别记录。

覆盖物动画依据：[华为 Map Kit 动画](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/api/map-map-animation)，[设置与启动覆盖物动画](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-basepriorityoverlay)。Marker 方法与 animateCameraStatus 签名另已对照本机官方 API 26 SDK；不引用 Android 或 Java 实现。

定位失败反馈依据：[华为 Location Kit 错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/errorcode-geolocationmanager-V14)，以及本机官方 `@ohos.geoLocationManager.d.ts` 的 getCurrentLocation 抛错声明（201、3301000、3301100、3301200）；`@hms.core.map.map.d.ts` 的 rectifyCoordinate 声明 1002600013（当前路由位置未知）。新版仅把这些既有业务码转换为用户可理解的提示，没有增加未经确认的定位接口。
