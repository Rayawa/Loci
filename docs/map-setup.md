# Map Kit 接入

Loci 已使用 MapComponent，但当前仓库没有应用 client_id，AGC 开通与签名匹配尚未确认。地图显示、坐标转换与落旗必须在配置完成后实测。

主模块声明 INTERNET 与 GET_NETWORK_INFO；后者用于 Map Kit 查询网络状态，不需要用户弹窗授权。2026-10-06 的真机日志曾出现网络状态查询错误 201（Permission denied），补齐权限并重新安装后，本次进程日志未再出现此错误。地图错误 1002600004（地图服务未开通）仍在，需要下面的应用服务配置。

1. 在 AppGallery Connect 为 `top.rayawa.loci` 建立对应 HarmonyOS 应用，开通地图服务。
2. 配置与本机调试 HAP 签名一致的证书指纹。
3. 取得该应用的 client_id，在 `entry/src/main/module.json5` 的 `module` 对象内添加：

```json5
"metadata": [
  { "name": "client_id", "value": "实际应用的Client ID" }
]
```

不要使用示例值、项目级 ID 或 Android API Key。配置后重新构建并安装，验证联网设备能显示地图，长按选点可创建地点，重启后旗帜仍在同一坐标。

2026-10-06 从本机 default 调试签名配置引用的公开证书计算得到 SHA-256 指纹：

```text
DF:21:A3:C0:9F:79:54:57:93:05:F8:5C:64:F8:0C:AD:86:F7:98:53:EE:3A:88:7C:1D:EC:95:D2:18:DF:3A:37
```

可据此登记当前调试证书。换证书或使用发布签名时须重新计算；此值不能替代应用 client_id。这里仅记录公开证书指纹，不保存签名私钥或密码。

控制器初始化后等待 mapLoad；15 秒未完成会提示重试。地图初始化或坐标操作失败时界面提供重试，已经保存的地点与文字可继续通过地点列表读取。没有服务配置时不宣称完成地图验收，也不填入伪造当前位置。

检查日志时先读取当前 Loci 进程 PID，再使用 `hdc -t DEVICE_ID shell hilog -x -P PID -L E,F`。`-x` 与 `-z` 不能同时使用；返回命令冲突不代表应用没有错误。重试时已对事件解绑与 Marker 清理逐项隔离异常；本次单次重试后同一进程保持运行，但此前退出没有可靠堆栈，正常服务下的重试仍需验收。

官方依据：[HarmonyOS Map Kit 集成场景](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)，[地图错误码与鉴权原因](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V14/map-errorcode-V14)。历史文档仅辅助解释，调用签名以当前官方 API 26 SDK 为准。

网络权限依据：[华为官方网络连接接口](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V3/js-apis-net-connection-0000001333720849-V3)；本机 SDK 的 `@ohos.net.connection.d.ts` 也声明 getDefaultNet/getNetCapabilities 所需 GET_NETWORK_INFO 权限。
