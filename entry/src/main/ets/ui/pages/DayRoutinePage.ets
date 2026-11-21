import { TextModifier } from '@kit.ArkUI';
import {
  HdsListItemCard,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  PrefixCustomBuilder,
  SuffixCustomBuilder,
} from '@kit.UIDesignKit';
import { LIST_ITEM_PREFIX_MARGIN, LIST_ITEM_SUFFIX_MARGIN } from '../../common/constants';
import { Icons } from '../../common/icons';
import { contentEnterTransition, pageTransition } from '../../common/motion';
import { DayRoutine } from '../../domain/model/DayRoutine';
import { calendarDate, dayClockText } from '../../domain/service/ActivityRules';
import { Haptics } from '../../service/haptics/Haptics';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { ActionButton } from '../components/ActionButton';
import { PageMotion } from '../navigation/PageMotion';
import { SheetSession } from '../navigation/SheetSession';
import { PageAction, sheetTitle } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { JournalViewModel } from '../viewmodel/JournalViewModel';

@ComponentV2
export struct DayRoutinePage {
  @Local motion: PageMotion = new PageMotion();
  @Require @Param model: JournalViewModel;
  @Require @Param localDate: string;
  @Require @Param session: SheetSession;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local wake: number = -1;
  @Local sleep: number = -1;
  @Local loading: boolean = true;
  @Local ready: boolean = false;
  @Local error: string = '';

  aboutToAppear(): void {
    this.load();
  }

  aboutToDisappear(): void {
    this.motion.stop();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    this.ready = false;
    try {
      const value = await this.model.getRepository().getRoutine(this.localDate);
      this.wake = value.wakeMinute;
      this.sleep = value.sleepMinute;
      this.ready = true;
    } catch (_) {
      this.error = '读取失败';
    } finally {
      this.loading = false;
    }
  }

  private pick(waking: boolean): void {
    if (!this.ready) {
      return;
    }
    const existing = waking ? this.wake : this.sleep;
    const minute = existing >= 0 ? existing % 1440 : waking ? 420 : 1380;
    const selected = calendarDate(this.localDate);
    selected.setHours(Math.floor(minute / 60), minute % 60, 0, 0);
    this.getUIContext().showTimePickerDialog({
      selected: selected,
      useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const clock = (value.hour ?? 0) * 60 + (value.minute ?? 0);
        if (waking) {
          this.wake = clock;
          if (this.sleep >= 0 && this.sleep <= clock) {
            this.sleep += 1440;
          }
        } else {
          this.sleep = clock + ((this.wake >= 0 && clock <= this.wake) || (this.wake < 0 && clock < 720) ? 1440 : 0);
        }
        this.session.dirty = true;
      },
    });
  }

  private async save(): Promise<void> {
    if (this.session.saving || !this.ready) {
      return;
    }
    this.session.saving = true;
    const value = new DayRoutine();
    value.localDate = this.localDate;
    value.wakeMinute = this.wake;
    value.sleepMinute = this.sleep;
    try {
      await this.model.getRepository().saveRoutine(value);
      this.session.dirty = false;
      this.model.refresh();
      this.session.finish();
    } catch (error) {
      this.error = (error as Error).message || '保存失败';
    } finally {
      this.session.saving = false;
    }
  }

  private back(): boolean {
    this.session.requestClose();
    return true;
  }

  private actions(): PageAction[] {
    return [
      {
        label: '保存',
        icon: Icons.save,
        isEnabled: this.ready && !this.session.saving && this.session.dirty,
        action: () => this.save(),
      },
      {
        label: '重置',
        icon: $r('sys.symbol.arrow_counterclockwise'),
        isEnabled: this.ready && !this.session.saving,
        action: () => {
          this.wake = -1;
          this.sleep = -1;
          this.session.dirty = true;
        },
      },
    ];
  }

  @Builder
  dotPrefix(color: Resource) {
    Row()
      .width(10)
      .height(10)
      .borderRadius(5)
      .backgroundColor(color)
  }

  @Builder
  timeSuffix(text: string, accent: boolean) {
    Row({ space: 6 }) {
      Text(text)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(accent ? Theme.accent : Theme.muted)
      Image($r('app.media.profile_right'))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
    }.alignItems(VerticalAlign.Center)
  }

  build() {
    HdsNavDestination() {
      Column({ space: 14 }) {
        Blank().height(8).width('100%')
        Row({ space: 8 }) {
          SymbolGlyph(Icons.journal).fontSize(15).fontColor([Theme.accent])
          Text(this.localDate).fontSize(14).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(12)
        .backgroundColor(Theme.surface)
        .border({ width: 1, color: Theme.line })

        Column() {
          HdsListItemCard({
            prefixItem: new PrefixCustomBuilder(() => {
              this.dotPrefix(Theme.accentOrange);
            }),
            textItem: {
              primaryText: {
                text: '起床',
                modifier: new TextModifier().fontSize(16).fontColor(this.ready ? Theme.ink : Theme.muted),
              },
            },
            suffixItem: new SuffixCustomBuilder(() => {
              this.timeSuffix(dayClockText(this.wake), this.wake >= 0);
            }),
            onClick: () => {
              if (!this.ready) {
                return;
              }
              Haptics.confirm();
              this.pick(true);
            },
            cardHeight: 56,
            cardBackgroundColor: Theme.surface,
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: { accessibilityText: `起床 ${dayClockText(this.wake)}，点击选择时间` },
          })

          Divider().color(Theme.chartGrid).margin({ left: 16, right: 16 })

          HdsListItemCard({
            prefixItem: new PrefixCustomBuilder(() => {
              this.dotPrefix(Theme.accentPurple);
            }),
            textItem: {
              primaryText: {
                text: '睡觉',
                modifier: new TextModifier().fontSize(16).fontColor(this.ready ? Theme.ink : Theme.muted),
              },
            },
            suffixItem: new SuffixCustomBuilder(() => {
              this.timeSuffix(dayClockText(this.sleep), this.sleep >= 0);
            }),
            onClick: () => {
              if (!this.ready) {
                return;
              }
              Haptics.confirm();
              this.pick(false);
            },
            cardHeight: 56,
            cardBackgroundColor: Theme.surface,
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: { accessibilityText: `睡觉 ${dayClockText(this.sleep)}，点击选择时间` },
          })
        }
        .width('100%')
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
        .clip(true)
        .enabled(this.ready)

        if (this.sleep >= 0) {
          Row({ space: 12 }) {
            Checkbox({ name: 'nextDay' })
              .select(this.sleep >= 1440)
              .selectedColor(Theme.accent)
              .onChange((checked: boolean) => {
                this.sleep = this.sleep % 1440 + (checked ? 1440 : 0);
                this.session.dirty = true;
              })
            Column({ space: 2 }) {
              Text('次日睡觉')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.ink)
              Text('勾选后凌晨时段归入当天记录')
                .fontSize(12)
                .fontColor(Theme.muted)
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          }
          .width('100%')
          .padding({ left: 14, right: 14, top: 12, bottom: 12 })
          .backgroundColor(Theme.surface)
          .borderRadius(Theme.cardRadius)
          .border({ width: 1, color: Theme.line })
          .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
          .transition(contentEnterTransition(6))
        }

        if (this.error) {
          Row() {
            Text(this.error)
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.accentRed)
              .width('100%')
          }
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .backgroundColor(Theme.warningBg)
        }

        if (!this.loading && !this.ready) {
          ActionButton({ label: '重试', highlighted: true, onAction: () => this.load() })
        }

        Blank().layoutWeight(1)
      }
      .opacity(this.motion.visible ? 1 : 0)
      .translate({ y: this.motion.visible ? 0 : 12 })
      .width('100%')
      .height('100%')
      .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
      .alignItems(HorizontalAlign.Start)
      .enabled(!this.session.saving)
    }
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .titleBar(sheetTitle('作息', this.experience.materialLevel, this.actions()))
    .backgroundColor(Theme.background)
    .transition(pageTransition())
    .onWillShow(() => this.motion.prepare())
    .onShown(() => this.motion.enter(this.getUIContext()))
    .onHidden(() => this.motion.stop())
    .onBackPressed(() => this.back())
  }
}
