# Loci (时迹)

English | [简体中文](README_zh.md)


A native HarmonyOS daily time-recording app with Records / Places / Statistics / My navigation. It supports date swipes and calendar jumps, categories, start/end times, local text extraction, list/week views, category pie charts and per-item weekly bar charts. Places and visit memories have a separate top-level HdsTabs section with map/place switching. Records open on today and list the period from waking to sleeping in reverse order. Typed or pasted multiline time/activity input supports overnight entries, overlaps and single time points. The My page follows Dashboard's branding, embedded settings, grouped features and version information.

Stage / ArkTS / ArkUI V2; minimum API 23, target API 26, phone-first. The UI follows Dashboard's HDS navigation, floating bottom bar, grouped cards, motion and lighting effects. See the [UI/UX plan](docs/design/daily-records.md) for design and interactions.

Time and place data are stored locally in ArkData. Ordered schema-v4 migrations support v1/v2/v3 while preserving record identities and place history. Huawei account + Huawei Cloud has been selected, but AGC configuration is not yet available. Authorization code and status screens exist; real login integration and cloud synchronization still require activation and implementation. See [Huawei service integration](docs/huawei-account-sync.md). A successful build does not establish device-UI or cloud-sync acceptance.

The app icon consists of 1024×1024 foreground and background PNG layers under [app_icon](app_icon/README.md), rendered through layered_image. The display name is 时迹; package top.rayawa.loci and production database loci.db remain unchanged.

## Running

1. Open the project in DevEco Studio with the API 26 SDK and synchronize dependencies.
2. Copy `build-profile.example.json5` to `build-profile.json5` and configure local debug signing in the IDE. That file, certificates and private keys are ignored and must not be committed.
3. Enable Map Kit for `top.rayawa.loci` in AppGallery Connect, match the signing fingerprint and set the application `client_id` in the module metadata of `entry/src/main/module.json5`. See [map setup](docs/map-setup.md).
4. Connect an unlocked API 23+ device and run entry.

Terminal builds:

```sh
sh scripts/build.sh main
sh scripts/build.sh test
```

Device-independent domain checks: use DevEco's bundled Node to run `node scripts/test-rules.cjs`. For added time rules, run `node scripts/test-activity-rules.cjs`; for migration SQL, run `python3 scripts/test-activity-schema.py`. These checks read the actual domain source and cover year boundaries, leap days, time zones, coordinate-system separation, distances and input boundaries. They exercise platform-independent rules only, not complete ArkTS builds, ArkData or physical-device UI behavior.

The default IDE location is `~/Applications/DevEco-Studio.app/Contents`; set `DEVECO_HOME` for another installation. Generated HAP files are under `entry/build/default/outputs/`. A successful build does not verify Map Kit authorization or device compatibility.

## Structure

| Directory | Responsibility |
| --- | --- |
| `app` | Platform-dependency composition and database singleton |
| `domain/model`, `domain/repository`, `domain/service` | Stable entities, repository contracts and pure rules |
| `data/database`, `data/migration`, `data/entity`, `data/repository` | Database lifecycle, versions, mappings and parameterized transactions |
| `service/location`, `service/map`, `service/haptics`, `service/settings` | Authorized location, coordinate normalization, map resources, haptics and experience settings |
| `ui/navigation`, `ui/pages`, `ui/components`, `ui/viewmodel`, `ui/theme` | HDS navigation, pages, reusable components, reactive state and semantic colors |

All directories are under `entry/src/main/ets`. `common` retains Dashboard's vibration, lighting, motion and compatibility utilities unchanged; see the [reuse record](docs/dashboard-style.md). The UI does not write SQL, the domain does not depend on system Kits, and repositories do not depend on UI. One location consistently maps to one Place; each visit adds a Visit. The production database does not seed example places automatically.

## Verification and Project Management

Device Hypium tests: `entry/src/ohosTest/ets/test/List.test.ets` aggregates place-database, time-record database/state, place-ViewModel and DiskStorage suites. They use independently randomized test databases and do not operate on production `loci.db`. Run through DevEco's test runner or specify an explicit device identifier:

```sh
hdc list targets
hdc -t DEVICE_ID install -r entry/build/default/outputs/default/entry-default-signed.hap
hdc -t DEVICE_ID install -r entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap
hdc -t DEVICE_ID shell aa test -b top.rayawa.loci -m entry_test -s unittest OpenHarmonyTestRunner -w 45
```

Install the main package before the test package on a new device; the test feature cannot run as an independent app environment. The native TestAbility supplies a real Stage context and runs all business suites without creating a test window. Examine test outcomes and assertion counts rather than relying only on the shell exit code. See the [acceptance checklist](docs/validation/core-checklist.md) for physical-device interaction checks.

- [UI/UX plan](docs/design/daily-records.md): current product direction, pages, interactions and visual rules.
- [Restructuring acceptance](docs/validation/daily-records-checklist.md): automation coverage and outstanding device checks.
- [Previous implementation plan](docs/implementation-plan.md): historical place-focused design.
- [Progress](docs/progress.md): implementation, validation and external dependencies.
- [API matrix](docs/api-matrix.md): official references, since versions and compatibility paths.
- [Architecture decision](docs/decisions/001-place-visit.md): identity, coordinates, transactions and historical aggregation.

The current product direction follows the [daily-records UI/UX plan](docs/design/daily-records.md); the old Trip / Track / Atlas schedule is no longer the main plan. New structures use ordered migrations. Migration failure preserves the original database instead of clearing or recreating user data.
