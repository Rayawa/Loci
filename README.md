# Loci

English | [简体中文](README_zh.md)

A local-first HarmonyOS application for daily time records, places and activity statistics.

## Overview

Loci records activities, categories and start/end times, supports text extraction and day/week views, and keeps place and visit history. ArkData stores records locally with ordered schema migrations. Account authorization scaffolding exists; production login and cloud synchronization are not yet complete.

## Technology and Dependencies

ArkTS, ArkUI V2/HDS, HarmonyOS Stage APIs, ArkData and Map Kit; OHPM and Hvigor. Target API 26, minimum API 23. Map features require AppGallery Connect configuration and a matching signing fingerprint.

## Repository Structure

- `entry/src/main/ets/` — ArkTS application code
- `entry/src/main/resources/` — resources and routes
- `AppScope/` — application metadata
- `build-profile.example.json5` — build configuration template
- `oh-package.json5` — package dependencies
- `entry/src/main/ets/domain/` — entities and domain rules
- `entry/src/main/ets/data/` — database and migrations
- `entry/src/main/ets/service/` — location, map and device services
- `app_icon/` — icon source assets
- `docs/` — design and platform setup
- `scripts/` — build and rule checks

## Quick Start

1. Open the repository root in DevEco Studio with the SDK required by `build-profile.example.json5`.
2. Copy that template to `build-profile.json5`, restore OHPM dependencies and configure signing locally if installing on a device.
3. Select the `entry` module and a compatible device/emulator, then build and run from the IDE. Keep certificates and machine-specific paths outside version control.

Configure Map Kit following [docs/map-setup.md](docs/map-setup.md), then run `sh scripts/build.sh main` to build the main module. `DEVECO_HOME` can select a nondefault IDE installation. See [account/sync status](docs/huawei-account-sync.md) before enabling account-related flows.
