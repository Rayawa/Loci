# Loci

[English](README.md) | 简体中文

本地优先的 HarmonyOS 每日时间记录、地点与活动统计应用。

## 项目概述

Loci 记录事项、分类及起止时间，支持文本提取、日视图和周视图，并管理地点与到访历史。记录通过 ArkData 保存在本机，按顺序迁移数据库结构。已有账号授权框架，真实登录和云同步尚未完成。

## 技术栈与依赖

ArkTS、ArkUI V2/HDS、HarmonyOS Stage 接口、ArkData、Map Kit、OHPM、Hvigor。目标 API 26，最低 API 23。地图功能需配置 AppGallery Connect 并匹配签名指纹。

## 文件结构

- `entry/src/main/ets/` — ArkTS 应用代码
- `entry/src/main/resources/` — 资源与路由
- `AppScope/` — 应用配置
- `build-profile.example.json5` — 构建配置模板
- `oh-package.json5` — 包依赖
- `entry/src/main/ets/domain/` — 实体与领域规则
- `entry/src/main/ets/data/` — 数据库与迁移
- `entry/src/main/ets/service/` — 定位、地图与设备服务
- `app_icon/` — 图标源素材
- `docs/` — 设计与平台配置
- `scripts/` — 构建与规则检查

## 快速上手

1. 使用 DevEco Studio 打开仓库根目录，并安装 `build-profile.example.json5` 指定的 SDK。
2. 将模板复制为 `build-profile.json5`，恢复 OHPM 依赖；如需真机安装，在本地配置签名。
3. 选择 `entry` 模块和兼容设备或模拟器，在 IDE 中构建运行。证书及机器路径不进入版本控制。

按 [docs/map-setup.md](docs/map-setup.md) 配置 Map Kit，使用 `sh scripts/build.sh main` 构建主模块。非默认 IDE 安装位置可通过 `DEVECO_HOME` 指定。账号相关流程的状态见[账号与同步说明](docs/huawei-account-sync.md)。
