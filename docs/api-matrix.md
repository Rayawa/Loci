# 已采用 API 与兼容性

依据：华为官方指南与 DevEco 随附 API 26 SDK（26.0.0.105）的声明和 since 标注。表内“可用于 API 23”是接口版本判断，实际 API 23 设备运行尚未验证。

| API / 组件 | 起始 API | 用途 / 兼容路径 |
| --- | --- | --- |
| HdsNavigation / HdsNavDestination / titleBar / toolbarConfiguration | 18 | 页面返回栈、原生标题与动作工具栏；基线 23 可用 |
| HdsTabs | 20 | 地图、旅行、足迹一级入口承载；基线 23 可用 |
| HdsNavigation titleBar menu.maxCount | 18 | 居中 Segment 页面限制为一个原生菜单占位，多个动作由 HDS 更多菜单承载；API 26 已验证无重叠 |
| TabSegmentButtonV2 / SegmentButtonV2Items | 18 | 复制 Dashboard 分段控件，固定在 titleBar stackBuilder；基线 23 可用 |
| ignoreLayoutSafeArea | 12 | 复用 Dashboard 的 Navigation/Destination 沉浸布局与内容留白 |
| HdsNavDestination.onActive / onInactive | 21 | 地点详情地图跟随页面可见状态，后台不触发 Toast 或选点 |
| ArkUI V2 ObservedV2 / Trace / ComponentV2 | 12 | UI 状态与纯实体分离；基线 23 可用 |
| bindSheet / onWillDismiss / DismissSheetAction | 12（拦截关闭） | 录入面板、关闭防丢失、保存时阻止关闭 |
| UIContext.showAlertDialog | 10 | 使用当前窗口上下文显示原生确认 |
| util.generateRandomUUID | 9 | 地点、到访、请求稳定身份 |
| relationalStore.getRdbStore / querySql / executeSql | 9 | S3 本地数据库和参数化查询 |
| RdbStore.execute | 12 | 带结果的修改与删除 |
| createTransaction / Transaction.execute / querySql / commit / rollback | 14 | Place + Visit 原子写入与迁移 |
| MapComponent / getEventManager / marker / rectifyCoordinate | 12 | 地图、事件、旗帜、区域坐标归一；需要 AGC 地图服务 |
| MapEventManager.mapLoad | 11 | 控制器初始化后等待地图加载完成；15 秒超时提供重试并清理监听 |
| MapComponentController.animateCameraStatus | 12 | 首次保存等待聚焦结束再显示旗帜；基线 23 可用，真实地图未验收 |
| Marker.setAnimation / startAnimation、AlphaAnimation | 11 | 首次旗帜淡入，使用 Dashboard 的 280ms 入场时长；失败保留静态旗帜，真实地图未验收 |
| ohos.permission.GET_NETWORK_INFO / INTERNET | 8 / 9（SDK 权限声明） | Map Kit 网络状态查询与联网；normal 权限，模块声明即可；重新安装后 own-PID 日志未再出现网络查询 201，服务鉴权仍失败 |
| geoLocationManager.getCurrentLocation / getAddressesFromLocation | 9 | 用户触发单次定位与可失败的逆地理编码 |
| abilityAccessCtrl.requestPermissionsFromUser | 9 | 按需申请近似与精确定位 |
| hdsEffect.HdsEffectBuilder.pointLight | 20 | 原样复用 Dashboard 的按压光場与松开恢复 |
| HdsTabs.barFloatingStyle / titleBar systemMaterialEffect | 23 | 原样复用 Dashboard 的 adaptive 材质与等级 |
| uiEffect.Filter.hdrBrightnessRatio | 24 | 仅高亮档按压时启用；API 23 降级普通光场，配置 HDR_BRIGHTNESS 权限 |
| vibrator preset / isSupportEffectSync / getVibratorInfoSync | 12 / 12 / 19 | 原样复制 Dashboard 的预置波形、能力检查、去重与三档设置；设备失败降级 |
| HdsNavDestinationTitleMode.MINI | 20 | 二级标题栏 |
| AbilityDelegator.startAbility | 9 | 原生测试能力启动，测试包内使用 |

除已做运行时隔离的 API 24 HDR 外，当前选用接口起始版本均不高于 23。运行环境还需满足对应 SystemCapability；定位和地图失败有 UI 错误路径。现有构建警告中的能力检查与异常提示不能当作设备验证通过。

沉浸光感 `uiMaterial` 起始 API 26，尚未加入当前代码。后续仅在系统版本与设备支持均满足时启用，23–25 保留语义色/已有 HDS 材质。不能只添加 if 就宣称跨版本兼容。球形地图既有接口 since 15，后续 Atlas 探索，不属于当前核心。

SDK 对照：`hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`、`@hms.core.map.map.d.ts`；`openharmony/ets/api/@ohos.data.relationalStore.d.ts`、`@ohos.geoLocationManager.d.ts` 与 `openharmony/ets/component/common.d.ts`。

官方指南：[关系型数据库](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)、[按压阴影](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-visual-effect-background-color)、[导航](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-basic-components-navigation)、[Map Kit](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)。部分动态页面无法完整提取，声明确认与编译、设备验收分别记录。

覆盖物动画依据：[华为 Map Kit 动画](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/api/map-map-animation)，[设置与启动覆盖物动画](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/map-map-basepriorityoverlay)。Marker 方法与 animateCameraStatus 签名另已对照本机官方 API 26 SDK；不引用 Android 或 Java 实现。

定位失败反馈依据：[华为 Location Kit 错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V14/errorcode-geolocationmanager-V14)，以及本机官方 `@ohos.geoLocationManager.d.ts` 的 getCurrentLocation 抛错声明（201、3301000、3301100、3301200）；`@hms.core.map.map.d.ts` 的 rectifyCoordinate 声明 1002600013（当前路由位置未知）。新版仅把这些既有业务码转换为用户可理解的提示，没有增加未经确认的定位接口。
