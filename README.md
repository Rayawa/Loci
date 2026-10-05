# Loci

以 Place + Visit 为核心的 HarmonyOS 本地个人空间记忆应用。Stage / ArkTS / ArkUI V2，最低 API 23，目标 API 26，手机优先。

当前只推进首轮地点记忆闭环。文字、Mood、地点历史、筛选与本地数据库已实现；真实地图、定位、重启交互仍需设备验收。Trip、Track、媒体、Atlas 尚未实现。准确状态见 [阶段进度](docs/progress.md)。

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

不依赖设备的纯领域规则检查：使用 DevEco 随附 Node 执行 `node scripts/test-rules.cjs`。该脚本读取实际 domain 源码，检查跨年/闰日时区、坐标系隔离、距离与输入边界；仅运行无平台依赖的规则，不替代 ArkTS 完整构建、ArkData 或界面真机测试。

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

设备 Hypium 测试：`entry/src/ohosTest/ets/test/AtlasPersistence.test.ets`，独立随机命名测试库，不操作正式 `loci.db`。通过 DevEco 测试运行器执行，或使用显式设备标识：

```sh
hdc list targets
hdc -t DEVICE_ID install -r entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap
hdc -t DEVICE_ID shell aa test -b top.rayawa.loci -m entry_test -s unittest OpenHarmonyTestRunner -w 45
```

测试入口通过原生 TestAbility 提供真实 Stage 上下文，直接运行数据库套件，不创建测试窗口。检查测试结果与断言数量，不能只根据 shell 退出码判断。真机交互验收见 [验收清单](docs/validation/core-checklist.md)。

- [实施方案](docs/implementation-plan.md)：首轮范围、数据与阶段顺序。
- [进度](docs/progress.md)：已实现、已验证及外部依赖。
- [API 矩阵](docs/api-matrix.md)：官方依据、since、兼容路径。
- [架构决策](docs/decisions/001-place-visit.md)：身份、坐标、事务和历史聚合。

先通过地点记忆闭环，再依次实现媒体、Trip、前台 Track 与 Atlas。新增结构通过有序迁移升级；迁移失败保留原数据库，不清空或重建用户数据。
