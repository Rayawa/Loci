# Map Kit 接入

Loci 已使用 MapComponent，但当前仓库没有应用 client_id，AGC 开通与签名匹配尚未确认。地图显示、坐标转换与落旗必须在配置完成后实测。

1. 在 AppGallery Connect 为 `top.rayawa.loci` 建立对应 HarmonyOS 应用，开通地图服务。
2. 配置与本机调试 HAP 签名一致的证书指纹。
3. 取得该应用的 client_id，在 `entry/src/main/module.json5` 的 `module` 对象内添加：

```json5
"metadata": [
  { "name": "client_id", "value": "实际应用的Client ID" }
]
```

不要使用示例值、项目级 ID 或 Android API Key。配置后重新构建并安装，验证联网设备能显示地图，长按选点可创建地点，重启后旗帜仍在同一坐标。

地图初始化或坐标操作失败时界面提供重试，已经保存的地点与文字可继续通过地点列表读取。没有服务配置时不宣称完成地图验收，也不填入伪造当前位置。

官方依据：[HarmonyOS Map Kit 集成场景](https://developer.huawei.com/consumer/cn/doc/doccenter-scenario/bpta-shared-bicycle)，[地图错误码与鉴权原因](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V14/map-errorcode-V14)。历史文档仅辅助解释，调用签名以当前官方 API 26 SDK 为准。
