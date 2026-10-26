# 时迹

HarmonyOS 原生每日时间记录应用。以「记录 / 地点 / 统计 / 我的」为主导航，支持日期滑动与日历跳转、事项分类、起止时间、本地文本提取、列表/周视图、分类饼图和单项周柱状图。地点与到访记忆由独立一级 HdsTabs 标签承载，保留地图/地点切换。记录首页默认今天，起床到睡觉之间的记录从晚到早排列。直接输入或粘贴多行时间＋事项，支持跨夜、重叠和单个时间点；我的页对齐 Dashboard 的品牌、内嵌设置、分组功能和版本信息。

Stage / ArkTS / ArkUI V2，最低 API 23，目标 API 26，手机优先。UI 延续 Dashboard 的 HDS 导航、悬浮底栏、分组卡片、动效与光场。设计与交互见 [UI/UX 方案](docs/design/daily-records.md)。

时间记录与地点数据都保存在本机 ArkData，schema v4 以有序迁移兼容原有 v1/v2/v3，保留原记录身份和地点历史。用户已选择华为账号 + 华为云，目前尚无 AGC 配置：账号授权代码和状态页面已建立，真实登录联调及云同步仍待开通与实现，详见 [华为服务接入](docs/huawei-account-sync.md)。构建通过不代表设备 UI 或云同步验收通过。

应用图标为 [app_icon](app_icon/README.md) 下的 1024×1024 前景与背景双层 PNG，通过 layered_image 渲染。应用展示名为时迹，包名 top.rayawa.loci 与正式库名 loci.db 保持稳定。

## 运行

1. 使用包含 API 26 SDK 的 DevEco Studio 打开工程并同步依赖。
2. 将 `build-profile.example.json5` 复制为 `build-profile.json5`，在 IDE 中配置个人调试签名。该文件与证书/私钥均已忽略，不提交。
3. 为 `top.rayawa.loci` 在 AppGallery Connect 开通 Map Kit，匹配签名指纹，在 `entry/src/main/module.json5` 的 module metadata 中设置应用 `client_id`。详见 [地图配置](docs/map-setup.md)。
4. 连接已解锁的 API 23 或更高版本设备，运行 entry。

终端构建：

```sh
sh scripts/build.sh main
sh scripts/build.sh test
```

不依赖设备的纯领域规则检查：使用 DevEco 随附 Node 执行 `node scripts/test-rules.cjs`。新增时间规则运行 `node scripts/test-activity-rules.cjs`，迁移 SQL 运行 `python3 scripts/test-activity-schema.py`。该脚本读取实际 domain 源码，检查跨年/闰日时区、坐标系隔离、距离与输入边界；仅运行无平台依赖的规则，不替代 ArkTS 完整构建、ArkData 或界面真机测试。

默认寻找 `~/Applications/DevEco-Studio.app/Contents`，其他安装位置通过 `DEVECO_HOME` 指定。生成 HAP 位于 `entry/build/default/outputs/`。构建成功不代表 Map Kit 鉴权或设备兼容已通过。

## 结构

| 目录 | 职责 |
| --- | --- |
| `app` | 平台依赖装配与数据库单例 |
| `domain/model`、`domain/repository`、`domain/service` | 稳定实体、Repository 契约、纯规则 |
| `data/database`、`data/migration`、`data/entity`、`data/repository` | 数据库生命周期、版本、映射、参数化事务 |
| `service/location`、`service/map`、`service/haptics`、`service/settings` | 授权定位、坐标归一、地图资源、触感与体验设置 |
| `ui/navigation`、`ui/pages`、`ui/components`、`ui/viewmodel`、`ui/theme` | HDS 导航、页面、可复用组件、响应状态与语义色 |

目录均在 `entry/src/main/ets` 下。`common` 保留 Dashboard 原样复制的振动、光场、动效与兼容工具，复用来源见 [风格复用记录](docs/dashboard-style.md)。UI 不写 SQL，domain 不依赖系统 Kit，Repository 不依赖 UI。一个地点稳定对应一个 Place；每次到访新增 Visit。正式数据库不自动插入示例地点。

## 验证与项目管理

设备 Hypium 测试：`entry/src/ohosTest/ets/test/List.test.ets` 汇总地点数据库、时间记录数据库/状态、地点 ViewModel 与 DiskStorage 套件，独立随机命名测试库，不操作正式 `loci.db`。通过 DevEco 测试运行器执行，或使用显式设备标识：

```sh
hdc list targets
hdc -t DEVICE_ID install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc -t DEVICE_ID install -r entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap
hdc -t DEVICE_ID shell aa test -b top.rayawa.loci -m entry_test -s unittest OpenHarmonyTestRunner -w 45
```

新设备必须先安装主包，再安装测试包；测试 feature 模块不能作为独立应用环境运行。测试入口通过原生 TestAbility 提供真实 Stage 上下文，运行全部业务套件，不创建测试窗口。检查测试结果与断言数量，不能只根据 shell 退出码判断。真机交互验收见 [验收清单](docs/validation/core-checklist.md)。

- [UI/UX 方案](docs/design/daily-records.md)：当前产品方向、页面、交互与视觉规范。
- [重构验收](docs/validation/daily-records-checklist.md)：自动化覆盖与设备待验收清单。
- [旧实施方案](docs/implementation-plan.md)：保留原地点版历史设计。
- [进度](docs/progress.md)：已实现、已验证及外部依赖。
- [API 矩阵](docs/api-matrix.md)：官方依据、since、兼容路径。
- [架构决策](docs/decisions/001-place-visit.md)：身份、坐标、事务和历史聚合。

本轮产品方向以 [每日记录 UI/UX 方案](docs/design/daily-records.md) 为准，旧版 Trip / Track / Atlas 排期不再作为主线。新增结构通过有序迁移升级；迁移失败保留原数据库，不清空或重建用户数据。
