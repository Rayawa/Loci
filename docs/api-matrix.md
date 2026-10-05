# 已采用 API 与兼容性

依据：华为官方指南与 DevEco 随附 API 26 SDK（26.0.0.105）的声明和 since 标注。表内“可用于 API 23”是接口版本判断，实际 API 23 设备运行尚未验证。

| API / 组件 | 起始 API | 用途 / 兼容路径 |
| --- | --- | --- |
| HdsNavigation / HdsNavDestination / titleBar / toolbarConfiguration | 18 | 页面返回栈、原生标题与动作工具栏；基线 23 可用 |
| HdsTabs | 20 | 地图、旅行、足迹一级入口承载；基线 23 可用 |
| ArkUI V2 ObservedV2 / Trace / ComponentV2 | 12 | UI 状态与纯实体分离；基线 23 可用 |
| bindSheet / onWillDismiss / DismissSheetAction | 12（拦截关闭） | 录入面板、关闭防丢失、保存时阻止关闭 |
| UIContext.showAlertDialog | 10 | 使用当前窗口上下文显示原生确认 |
| util.generateRandomUUID | 9 | 地点、到访、请求稳定身份 |
| relationalStore.getRdbStore / querySql / executeSql | 9 | S3 本地数据库和参数化查询 |
| RdbStore.execute | 12 | 带结果的修改与删除 |
| createTransaction / Transaction.execute / querySql / commit / rollback | 14 | Place + Visit 原子写入与迁移 |
| MapComponent / getEventManager / marker / rectifyCoordinate | 12 | 地图、事件、旗帜、区域坐标归一；需要 AGC 地图服务 |
| geoLocationManager.getCurrentLocation / getAddressesFromLocation | 9 | 用户触发单次定位与可失败的逆地理编码 |
| abilityAccessCtrl.requestPermissionsFromUser | 9 | 按需申请近似与精确定位 |
| hdsEffect.HdsEffectBuilder.pressShadow | 20 | Mood 与 VisitCard 按压渐变；Touch Up/Cancel 恢复 NONE |
| vibrator.startVibration（time） | 9 | 保存成功与 Mood 选择轻触感；权限/设备失败静默降级 |

所有当前选用接口起始版本均低于 23。运行环境还需满足对应 SystemCapability；定位和地图失败有 UI 错误路径。现有构建警告中的能力检查与异常提示不能当作设备验证通过。

沉浸光感 `uiMaterial` 起始 API 26，尚未加入当前代码。后续仅在系统版本与设备支持均满足时启用，23–25 保留语义色/已有 HDS 材质。不能只添加 if 就宣称跨版本兼容。球形地图既有接口 since 15，后续 Atlas 探索，不属于当前核心。

SDK 对照：`hms/ets/api/@hms.hds.hdsBaseComponent.d.ets`、`@hms.core.map.map.d.ts`；`openharmony/ets/api/@ohos.data.relationalStore.d.ts`、`@ohos.geoLocationManager.d.ts` 与 `openharmony/ets/component/common.d.ts`。

官方指南：[关系型数据库](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store)、[按压阴影](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ui-design-visual-effect-background-color)、[导航](https://developer.huawei.com/consumer/cn/doc/doccenter-references/api/ts-basic-components-navigation)、[Map Kit](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)。部分动态页面无法完整提取，声明确认与编译、设备验收分别记录。
