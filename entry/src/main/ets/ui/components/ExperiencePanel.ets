import { common } from '@kit.AbilityKit';
import { getDeviceName } from '../../common/storage';
import { showToastSafely } from '../../common/safeUi';
import { clearCompleteCache, getCacheSizeBytes } from '../../common/CacheService';
import { formatBytes } from '../../common/cacheFormat';
import { UsernameEditor } from './UsernameEditor';
import { HdsListItemCard, IconSize, PrefixIcon } from '@kit.UIDesignKit';
import { ExperienceSettings, ExperienceOption } from '../../service/settings/ExperienceSettings';
import { vibration } from '../../common/vibration';
import { isHdrLightFieldSupported } from '../../common/visualEffects';
import { LIST_ITEM_PREFIX_MARGIN, LIST_ITEM_SUFFIX_MARGIN } from '../../common/constants';
import { Icons } from '../../common/icons';
import { Theme } from '../theme/Theme';

// Dashboard SettingsPanel builders, with V2 state and Loci persistence bindings.
@ComponentV2
export struct ExperiencePanel {
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local contentWidth: number = 0;
  @Local cacheSize: string = '计算中…';
  @Local handlePopupTrash: boolean = false;
  private cacheSizeTimer: number = -1;
  private usernamePrefixItem: PrefixIcon = new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: Icons.user } });
  private trashPrefixItem: PrefixIcon = new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: Icons.trash } });
  private attemptedUnsupportedHighLight: boolean = false;
  private readonly vibrationSupported: boolean = vibration.isSupported();
  private vibrationPrefixItem: PrefixIcon = new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: Icons.vibration } });
  private materialPrefixItem: PrefixIcon = new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: Icons.material } });
  private lightFieldPrefixItem: PrefixIcon = new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: Icons.light } });
  private isNarrowSettings(): boolean { return this.contentWidth > 0 && this.contentWidth < 330; }

  @Builder divider() { Divider().color($r('app.color.border')).strokeWidth(0.5).margin({ left: 16, right: 16 }) }
  build() {
    Column() {
      this.usernameItem()
      this.divider()
      if (this.vibrationSupported) { this.vibrationLevelItem(); this.divider() }
      this.divider()
      this.materialLevelItem()
      this.divider()
      this.trashItem()
    }.width('100%').backgroundColor(Theme.surface).borderRadius(16)
      .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 }).clip(true)
      .enabled(this.experience.ready)
      .onAppear(() => this.scheduleCacheSizeRefresh())
      .onAreaChange((_old: Area, area: Area) => { this.contentWidth = Number(area.width); })
      .accessibilityText('应用体验设置')
  }
    private vibrationLevelName(): string {
        if (this.experience.vibrationLevel === 0) {
            return '关闭';
        }

        if (this.experience.vibrationLevel === 1) {
            return '灵动';
        }

        return '硬朗';
    }

    @Builder
    private vibrationLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.vibrationPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.vibrationLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `振动强度设置`,
            },
        })
    }

    @Builder
    private vibrationLevelContent(): void {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('振动强度')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('振动强度')

            Column({ space: 1 }) {
                Slider({
                    value: this.experience.vibrationLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(190)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode) => {
                        const nextLevel = Math.round(value);

                        if (mode === SliderChangeMode.Click ||
                            mode === SliderChangeMode.End) {
                            vibration.dotVibration();

                            this.experience.update(ExperienceOption.Vibration, nextLevel);
                        }
                    })
                    .accessibilityText(
                        `振动强度，当前${this.vibrationLevelName()}，共三档`
                    )

                Row() {
                    this.vibrationLevelLabel('关闭', 0)
                    this.vibrationLevelLabel('灵动', 1)
                    this.vibrationLevelLabel('硬朗', 2)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
            .margin({
                top: this.isNarrowSettings() ? 4 : 0
            })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(
            `振动强度，当前${this.vibrationLevelName()}`
        )
    }

    @Builder
    private vibrationLevelLabel(label: string, level: number): void {
        Text(label)
            .fontSize(12)
            .fontWeight(
                this.experience.vibrationLevel === level ?
                    FontWeight.Medium :
                    FontWeight.Regular
            )
            .fontColor(
                this.experience.vibrationLevel === level ?
                    $r('app.color.diff_content') :
                    $r('app.color.v3_text_secondary')
            )
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(
                `${label}振动${this.experience.vibrationLevel === level ? '，已选择' : ''}`
            )
    }

    private lightFieldLevelName(): string {
        if (this.experience.lightFieldLevel === 0) {
            return '暗淡';
        }
        if (this.experience.lightFieldLevel === 2) {
            return '高亮';
        }
        return '明亮';
    }

    private persistLightFieldLevel(level: number): void {
        this.experience.update(ExperienceOption.LightField, level);
    }

    private showLightFieldPrompt(message: string): void {
        showToastSafely(this.getUIContext().getPromptAction(), message, 4000, 'Settings');
    }

    private onLightFieldLevelChange(value: number, mode: SliderChangeMode): void {
        const nextLevel = Math.round(value);
        if (mode === SliderChangeMode.Begin) {
            this.attemptedUnsupportedHighLight = false;
            return;
        }

        if (!isHdrLightFieldSupported() && nextLevel === 2) {
            this.attemptedUnsupportedHighLight = true;
        }

        if (mode !== SliderChangeMode.Click && mode !== SliderChangeMode.End) {
            return;
        }

        vibration.dotVibration();
        if (!isHdrLightFieldSupported() &&
            (nextLevel === 2 || this.attemptedUnsupportedHighLight)) {
            this.experience.lightFieldLevel = 1;
            this.persistLightFieldLevel(1);
            this.showLightFieldPrompt('当前设备不支持全局HDR功能');
            this.attemptedUnsupportedHighLight = false;
            return;
        }

        this.experience.lightFieldLevel = nextLevel;
        this.persistLightFieldLevel(nextLevel);
        if (nextLevel === 2) {
            this.showLightFieldPrompt('光场视效将以HDR显示，该功能会显著提升亮度与功耗，部分设备不支持');
        }
        this.attemptedUnsupportedHighLight = false;
    }

    @Builder
    private lightFieldLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.lightFieldPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.lightFieldLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText: '光场视效设置',
            },
        })
    }

    @Builder
    private lightFieldLevelContent(): void {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('光场视效')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('光场视效')

            Column({ space: 1 }) {
                Slider({
                    value: this.experience.lightFieldLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(190)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode): void => {
                        this.onLightFieldLevelChange(value, mode);
                    })
                    .accessibilityText(`光场视效，当前${this.lightFieldLevelName()}，共三档`)

                Row() {
                    this.lightFieldLevelLabel('暗淡', 0)
                    this.lightFieldLevelLabel('明亮', 1)
                    this.lightFieldLevelLabel('高亮', 2)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
            .margin({ top: this.isNarrowSettings() ? 4 : 0 })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(`光场视效，当前${this.lightFieldLevelName()}`)
    }

    @Builder
    private lightFieldLevelLabel(label: string, level: number): void {
        Text(label)
            .fontSize(12)
            .fontWeight(this.experience.lightFieldLevel === level ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(level === 2 && !isHdrLightFieldSupported() ?
                $r('app.color.v3_text_secondary') :
                this.experience.lightFieldLevel === level ?
                    $r('app.color.diff_content') : $r('app.color.v3_text_secondary'))
            .opacity(level === 2 && !isHdrLightFieldSupported() ? 0.55 : 1)
            .decoration({
                type: level === 2 && !isHdrLightFieldSupported() ?
                    TextDecorationType.LineThrough : TextDecorationType.None,
                color: $r('app.color.v3_text_secondary'),
            })
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(`${label}光场${this.experience.lightFieldLevel === level ? '，已选择' : ''}${
                level === 2 && !isHdrLightFieldSupported() ? '，当前设备不支持' : ''}`)
    }

    private materialLevelName(): string {
        if (this.experience.materialLevel === 2) {
            return '流畅';
        }

        if (this.experience.materialLevel === 1) {
            return '轻柔';
        }

        return '精美';
    }

    @Builder
    private materialLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.materialPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.materialLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `材质等级设置`,
            },
        })
    }

    @Builder
    private materialLevelContent(): void {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('材质等级')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('材质等级')

            Column({ space: 1 }) {
                Slider({
                    value: 2 - this.experience.materialLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(190)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode) => {
                        const nextLevel = 2 - Math.round(value);

                        if (mode === SliderChangeMode.Click ||
                            mode === SliderChangeMode.End) {


                            vibration.dotVibration();

                            this.experience.update(ExperienceOption.Material, nextLevel);
                        }
                    })
                    .accessibilityText(
                        `材质等级，当前${this.materialLevelName()}，共三档`
                    )

                Row() {
                    this.materialLevelLabel('流畅', 2)
                    this.materialLevelLabel('轻柔', 1)
                    this.materialLevelLabel('精美', 0)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
            .margin({
                top: this.isNarrowSettings() ? 4 : 0
            })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(
            `材质等级，当前${this.materialLevelName()}`
        )
    }

    @Builder
    private materialLevelLabel(label: string, level: number): void {
        Text(label)
            .fontSize(12)
            .fontWeight(
                this.experience.materialLevel === level ?
                    FontWeight.Medium :
                    FontWeight.Regular
            )
            .fontColor(
                this.experience.materialLevel === level ?
                    $r('app.color.diff_content') :
                    $r('app.color.v3_text_secondary')
            )
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(
                `${label}材质${
                this.experience.materialLevel === level ?
                    '，已选择' :
                    ''
                }`
            )
    }


  private persistUsername(username: string): void { this.experience.updateUsername(username); }
  private scheduleCacheSizeRefresh(): void {
    if (this.cacheSizeTimer >= 0) { clearTimeout(this.cacheSizeTimer); }
    this.cacheSizeTimer = setTimeout(() => {
      this.cacheSizeTimer = -1;
      this.cacheSize = formatBytes(getCacheSizeBytes(this.getUIContext().getHostContext() as common.UIAbilityContext));
    }, 0);
  }
  aboutToDisappear(): void { if (this.cacheSizeTimer >= 0) { clearTimeout(this.cacheSizeTimer); } }
  private trash(): void {
    this.getUIContext().showAlertDialog({ message: '将清除本机临时缓存。地点、记忆、用户名和设置会保留。',
      primaryButton: { value: '取消', action: () => vibration.dotVibration() },
      secondaryButton: { value: '继续', action: async () => {
        vibration.dotVibration();
        try {
          await clearCompleteCache(this.getUIContext().getHostContext() as common.UIAbilityContext);
          showToastSafely(this.getUIContext().getPromptAction(), '缓存已清除', 1800, 'Settings');
        } catch (_) { showToastSafely(this.getUIContext().getPromptAction(), '部分缓存文件正在使用，请稍后重试', 2190, 'Settings'); }
        this.scheduleCacheSizeRefresh();
      } }
    });
  }
    @Builder
    private usernameItem(): void {
        HdsListItemCard({
            prefixItem: this.usernamePrefixItem,
            textItem: {
                customBuilder: () => {
                    this.usernameContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 108 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `用户名设置，当前${this.experience.username || getDeviceName()}`,
            },
        })
    }

    @Builder
    private usernameContent(): void {
        UsernameEditor({
            initialUsername: this.experience.username,
            narrow: this.isNarrowSettings(),
            onCommit: (value: string): void => this.persistUsername(value),
        })
    }

    @Builder
    private trashItem(): void {
        HdsListItemCard({
            prefixItem: this.trashPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.trashContent()
                },
            },
            onClick: () => {
                vibration.dotVibration();
                this.trash();
            },
            cardHeight: 52,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `清除缓存，当前缓存文件总大小：${this.cacheSize}`,
            },
        })
    }

    @Builder
    private trashContent(): void {
        Flex({
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('清除缓存')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText('清除缓存')

            Row({ space: 8 }) {
                Text(`缓存文件总大小：${this.cacheSize}`)
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(
                        `缓存文件总大小${this.cacheSize}`
                    )

                Image(Icons.help)
                    .height(24)
                    .width(24)
                    .objectFit(ImageFit.Contain)
                    .accessibilityText('查看清除缓存说明')
                    .clickEffect({
                        level: ClickEffectLevel.LIGHT,
                        scale: 0.9
                    })
                    .onClick(() => {
                        if (this.experience.vibrationLevel > 0) {
                            vibration.dotVibration();
                        }

                        this.handlePopupTrash =
                            !this.handlePopupTrash;
                    })
                    .monopolizeEvents(true)
                    .bindPopup(this.handlePopupTrash, {
                        message:
                        '清除本机临时缓存；地点、记忆、用户名和设置不会被删除',
                        onStateChange: (event) => {
                            if (!event.isVisible) {
                                this.handlePopupTrash = false;
                            }
                        }
                    })
            }
        }
        .width('100%')
        .padding({ right: 7 })
        .accessibilityGroup(true)
        .accessibilityText(
            `清除缓存，当前缓存文件总大小${this.cacheSize}`
        )
    }
}
