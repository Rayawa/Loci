# 实施进度

更新：2026-10-06。目标仍在实施；完整 v1 与地图闭环尚未完成。

| 阶段 | 状态 | 证据 / 剩余工作 |
| --- | --- | --- |
| Phase 0 工程与分层 | 已实现 | Stage、API 23–26、domain/data/service/ui/common、构建脚本、签名隐私与 Git 管理 |
| Phase 0 数据库 | API 26 真机验证通过 | schema v2、UUID、参数化事务、写队列；9 项 Hypium 全部通过 |
| HDS 导航 | 基础交互验证通过 | HdsTabs 承载三个独立 HdsNav；详情 HdsNavDestination；toolbar；冷启动/三标签/设置/返回通过 |
| Dashboard 风格统一 | 已接入 | 4 个工具文件逐字节一致；titleBar、悬浮 Tabs、按钮、光场、HDR 降级、动效、语义色、设置卡片与图标，见 dashboard-style.md |
| 体验设置 | 振动重启恢复通过 | 三档振动/光场/材质与 Preferences；硬朗档重启保留，验收后恢复灵动档；效果感受和其他档位待人工确认 |
| Phase 1 地图与地点 | 已实现 / 地图服务待确认 | MapComponent、Marker、点击/长按、坐标转换；实际地图加载及 client_id/AGC/签名匹配待确认 |
| Phase 1 多次 Visit | 数据库逻辑通过 | 重访身份、独立日记/Mood、幂等提交、相邻地点、聚合；地图到录入面板完整交互仍待验收 |
| Phase 2 媒体 | 待实施 | 闭环通过后加入照片/视频/录音与 URI 生命周期 |
| Phase 3 Trip | 待实施 | CRUD、Visit 归属、分日与地图 |
| Phase 4 Track | 待实施 | 前台开始/暂停/结束、轨迹点与 Polyline |
| Phase 5 Atlas | 待实施 | 国家/城市/时间轴/统计与世界视图探索 |
| Phase 6 全面原生打磨 | 待全面验收 | API 23 设备、横屏/平板/大字/无障碍与性能；API 26 新特性需合适场景与兼容路径 |

当前证据：主包与测试包签名构建成功；主机纯规则 8 项通过；API 26 原生数据库测试 `Tests run: 9, Failure: 0, Error: 0, Pass: 9`。日志在本机 `/tmp/loci-build.log`、`/tmp/loci-test-build.log`、`/tmp/loci-rdb-test.log`，临时日志不提交。

已解决两项阻碍：默认测试入口通过 shell 启动界面时曾被锁屏拒绝；现在使用原生 AbilityDelegator.startAbility 启动轻量 TestAbility，提供真实 Stage 上下文并运行数据库套件。不能在无 Stage 上下文的 TestRunner 中把 getAppContext 直接传给 ArkData。

数据库测试发现事务连接不继承 foreign_keys PRAGMA：v2 用数据库触发器保护关联，迁移保持历史数据与 UUID，已实际验证孤立 Visit 被拒绝、父引用更新被拒绝、删除级联以及重开恢复。

2026-10-06 的启动 JS 崩溃来自 HdsNav 的 BuilderParam 改变 this：页面内容和路由改为箭头闭包保持 AppShell 上下文。修复包已重新安装，冷启动、三个标签页、进入设置、返回和再次冷启动均成功；一级页面为 native mini titleBar 留出 56vp，toolbar 和悬浮 Tabs 不覆盖内容。

真实地图服务、定位授权、首次落旗、通过界面保存两次 Visit、强停后旗帜与内容恢复仍是首轮验收剩余项。数据库通过不等于地图和 UI 全闭环通过；首轮完成前不进入 Trip / Track / Atlas 主功能。
