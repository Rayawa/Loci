# 华为账号与云同步接入状态

2026-10-22：用户确认使用华为账号 + 华为云，并明确目前尚无 AGC 配置。当前交付本地可用版本，账号入口包含真实 Account Kit 授权代码；云同步暂未实现，界面明确显示未启用。

## 已实现

- `HuaweiAccount` 调用 SDK 的 `HuaweiIDProvider.createLoginWithHuaweiIDRequest` 和 `AuthenticationController(context).executeRequest`，仅在用户点击时请求授权。
- 读取 module metadata 的 `client_id` 判断是否已配置；当前配置为空，不发起无效授权请求。
- 每次请求独立随机 state，核对返回 state；取消、网络错误与其他失败展示中文反馈。
- 仅把本次授权成功作为内存会话状态；不持久化凭据、不记录授权码/ID Token/OpenID、不自动上传任何本地内容。
- 华为账号授权不等于通过云端业务认证，页面明确区分。重启后需重新授权。

## 开通后的实施顺序

1. 在 AGC 为 `top.rayawa.loci` 创建或关联应用，配置实际签名指纹并开通华为账号；在 `entry/src/main/module.json5` 的 module metadata 添加真实 `client_id`。不把 client_secret 放入 HAP。
2. 确定 AGC 项目、region 和云数据库存储区，开通认证服务。通过服务器交换并验证一次性授权码，或使用官方认证服务生成用户凭据；不能直接把客户端声明的 OpenID 当作服务器认证。
3. 部署按认证用户隔离的记录同步接口。用户身份只能来自已验证会话；配置 CloudFoundationKit 的 authProvider、云函数或云数据库权限。
4. 迁移增加账号归属、同步游标、变更队列和删除墓碑；活动、地点和到访完整同步。写入本地记录与变更队列必须在同一事务内完成。
5. 采用服务端单调 revision/CAS 解决冲突，不以设备时间作为唯一胜负标准；并发修改保留可恢复版本。跨设备相互重叠的时段由用户确认后合并，不能绕过本地时间约束。
6. 换账号前明确本机数据归属，不把上一账号数据上传给下一账号。首次登录提示选择是否合并本机数据；同步成功后才推进游标；退出登录取消在途请求并隔离缓存。
7. 用两个测试账号、两台设备验证离线新增/编辑/删除、冲突、重试、过期凭据、账号切换和地点引用，再启用同步按钮。

当前不提供伪造服务端、模拟成功或静默云端备份。账号开通、服务端认证与同步实现是后续待完成项，不能把本地构建通过写成云同步验收通过。

## 已核对的官方依据

- [Account Kit](https://developer.huawei.com/consumer/cn/hms/huawei-accountkit)
- [华为账号认证接口](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/account-api-authentication)
- 本机 API 26 SDK：`@kit.AccountKit`、`@hms.core.authentication.d.ts`，所用 API since 10/11，低于应用 API 23 基线。
- 本机 `@kit.CloudFoundationKit`、cloudCommon 的 AuthProvider 定义要求真实用户凭据；本轮没有伪造或接入未经配置的云端。
