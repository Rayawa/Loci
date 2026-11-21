import { curves, TextModifier } from '@kit.ArkUI';
import {
  hdsEffect,
  HdsListItemCard,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  PrefixCustomBuilder,
  SuffixCustomBuilder,
} from '@kit.UIDesignKit';
import { util } from '@kit.ArkTS';
import { LIST_ITEM_PREFIX_MARGIN, LIST_ITEM_SUFFIX_MARGIN } from '../../common/constants';
import { Icons } from '../../common/icons';
import { contentEnterTransition, pageTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { ACTIVITY_CATEGORIES, Activity, ActivityCategory } from '../../domain/model/Activity';
import { Place } from '../../domain/model/Atlas';
import { DayRoutine, JournalLine, JournalLineKind } from '../../domain/model/DayRoutine';
import { calendarDate, clockText, dateKey, dayClockText, parseJournalLine } from '../../domain/service/ActivityRules';
import { Haptics } from '../../service/haptics/Haptics';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { ActionButton } from '../components/ActionButton';
import { PressInteraction, PressSelectStyle } from '../components/PressInteraction';
import { StatePanel } from '../components/StatePanel';
import { PageMotion } from '../navigation/PageMotion';
import { SheetSession } from '../navigation/SheetSession';
import { PageAction, sheetTitle } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { JournalViewModel } from '../viewmodel/JournalViewModel';

@ComponentV2
export struct ActivityEditorPage {
  @Local motion: PageMotion = new PageMotion();
  @Require @Param model: JournalViewModel;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param recordId: string;
  @Require @Param session: SheetSession;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local input: string = '';
  @Local selectedDate: string = '';
  @Local categoryId: string = '';
  @Local placeId: string = '';
  @Local note: string = '';
  @Local more: boolean = false;
  @Local loading: boolean = true;
  @Local error: string = '';
  @Local loadError: boolean = false;
  @Local interaction: PressInteraction = new PressInteraction();
  private activityId: string = '';
  private createdAt: number = 0;
  private ids: string[] = [];

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
    this.load();
  }

  aboutToDisappear(): void {
    this.motion.stop();
    this.interaction.dispose();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.error = '';
    this.loadError = false;
    this.selectedDate = this.model.selectedDate;
    this.activityId = this.recordId || util.generateRandomUUID();
    if (this.recordId) {
      try {
        const record = await this.model.getRepository().get(this.recordId);
        this.input = `${record.startMinute >= 1440 ? '次日 ' : ''}${clockText(record.startMinute % 1440)}${record.endMinute !== record.startMinute ? `-${clockText(record.endMinute % 1440)}` : ''} ${record.title}`;
        this.categoryId = record.categoryId;
        this.selectedDate = record.localDate;
        this.placeId = record.placeId;
        this.note = record.note;
        this.createdAt = record.createdAt;
      } catch (_) {
        this.error = '读取失败';
        this.loadError = true;
      }
    }
    this.loading = false;
  }

  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({
      selected: calendarDate(this.selectedDate),
      start: new Date(1970, 0, 1),
      end: new Date(2100, 11, 31),
      onDateAccept: (date: Date) => {
        this.selectedDate = dateKey(date);
        this.session.dirty = true;
      },
    });
  }

  private timeValue(): JournalLine {
    try {
      return parseJournalLine(this.input, this.model.routine(this.selectedDate).wakeMinute);
    } catch (_) {
      const value = new JournalLine();
      const now = new Date();
      value.startMinute = now.getHours() * 60 + now.getMinutes();
      value.endMinute = value.startMinute + 30;
      value.title = this.input.trim();
      return value;
    }
  }

  private pickTime(starting: boolean): void {
    const value = this.timeValue();
    const minute = (starting ? value.startMinute : value.endMinute) % 1440;
    const selected = calendarDate(this.selectedDate);
    selected.setHours(Math.floor(minute / 60), minute % 60, 0, 0);
    this.getUIContext().showTimePickerDialog({
      selected: selected,
      useMilitaryTime: true,
      onAccept: (time: TimePickerResult) => {
        const clock = (time.hour ?? 0) * 60 + (time.minute ?? 0);
        if (starting) {
          value.startMinute = clock + (value.startMinute >= 1440 ? 1440 : 0);
        } else {
          value.endMinute = clock + (value.startMinute >= 1440 ? 1440 : 0);
        }
        if (value.endMinute < value.startMinute) {
          value.endMinute += 1440;
        }
        this.input = `${value.startMinute >= 1440 ? '次日 ' : ''}${clockText(value.startMinute % 1440)}${value.endMinute !== value.startMinute ? `-${clockText(value.endMinute % 1440)}` : ''} ${value.title}`;
        this.session.dirty = true;
        this.error = '';
      },
    });
  }

  private async save(): Promise<void> {
    if (this.session.saving || this.loading || this.loadError) {
      return;
    }
    this.session.saving = true;
    this.error = '';
    try {
      const lines = this.input.split('\n').map((line: string) => line.trim()).filter((line: string) => line.length > 0);
      if (!lines.length) {
        throw new Error('请输入记录');
      }
      if (lines.length > 100) {
        throw new Error('每次最多100条');
      }
      if (this.recordId && lines.length > 1) {
        throw new Error('编辑时请保留一条记录');
      }
      const existing = await this.model.getRepository().getRoutine(this.selectedDate);
      const routine = new DayRoutine();
      routine.localDate = this.selectedDate;
      routine.wakeMinute = existing.wakeMinute;
      routine.sleepMinute = existing.sleepMinute;
      // Find a wake marker before resolving early-morning entries, independent of input order.
      for (const line of lines) {
        const point = parseJournalLine(line);
        if (point.kind === JournalLineKind.Wake) {
          routine.wakeMinute = point.startMinute;
        }
      }
      const records: Activity[] = [];
      let changedRoutine = false;
      for (let index = 0; index < lines.length; index++) {
        const value = parseJournalLine(lines[index], routine.wakeMinute);
        if (value.kind === JournalLineKind.Wake || value.kind === JournalLineKind.Sleep) {
          if (this.recordId) {
            throw new Error('起床和睡觉请在作息中修改');
          }
          if (value.kind === JournalLineKind.Wake) {
            routine.wakeMinute = value.startMinute;
          } else {
            routine.sleepMinute = value.startMinute;
          }
          changedRoutine = true;
          continue;
        }
        if (!this.ids[index]) {
          this.ids[index] = index === 0 ? this.activityId : util.generateRandomUUID();
        }
        const record = new Activity();
        record.id = this.ids[index];
        record.localDate = this.selectedDate;
        record.title = value.title;
        record.categoryId = this.categoryId || value.categoryId;
        record.startMinute = value.startMinute;
        record.endMinute = value.endMinute;
        record.placeId = this.placeId;
        record.note = this.note;
        record.createdAt = this.createdAt;
        records.push(record);
      }
      await this.model.getRepository().saveBatch(records, changedRoutine ? routine : undefined);
      this.session.dirty = false;
      this.model.selectDate(this.selectedDate);
      this.session.finish();
    } catch (error) {
      this.error = (error as Error).message || '保存失败';
    } finally {
      this.session.saving = false;
    }
  }

  private remove(): void {
    if (this.session.saving) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '删除记录？',
      message: '',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: {
        value: '删除',
        action: async () => {
          this.session.saving = true;
          try {
            await this.model.getRepository().delete(this.activityId);
            this.session.dirty = false;
            this.model.refresh();
            this.session.finish();
          } catch (_) {
            this.error = '删除失败';
          } finally {
            this.session.saving = false;
          }
        },
      },
    });
  }

  private back(): boolean {
    this.session.requestClose();
    return true;
  }

  private actions(): PageAction[] {
    const ready = !this.session.saving && !this.loading && !this.loadError;
    const result: PageAction[] = [{
      label: '保存',
      icon: Icons.save,
      isEnabled: ready && this.input.trim().length > 0,
      action: () => this.save(),
    }];
    if (this.recordId) {
      result.push({
        label: '删除',
        icon: $r('sys.symbol.trash'),
        isEnabled: ready,
        action: () => this.remove(),
      });
    }
    return result;
  }

  @Builder
  datePrefix() {
    SymbolGlyph(Icons.journal)
      .fontSize(20)
      .fontColor([Theme.accent])
  }

  @Builder
  dateSuffix() {
    Row({ space: 6 }) {
      Text(this.selectedDate)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.muted)
      Image($r('app.media.profile_right'))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
    }.alignItems(VerticalAlign.Center)
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Blank().height(8).width('100%')
          if (this.loading) {
            LoadingProgress().width(28).height(28).color(Theme.accent)
          } else if (this.loadError) {
            StatePanel({ title: this.error, action: '重试', onAction: () => this.load() })
          } else {
            Column() {
              HdsListItemCard({
                prefixItem: new PrefixCustomBuilder(() => {
                  this.datePrefix();
                }),
                textItem: {
                  primaryText: {
                    text: '记录日期',
                    modifier: new TextModifier().fontSize(16).fontColor(Theme.ink),
                  },
                },
                suffixItem: new SuffixCustomBuilder(() => {
                  this.dateSuffix();
                }),
                onClick: () => {
                  Haptics.confirm();
                  this.pickDate();
                },
                cardHeight: 54,
                cardBackgroundColor: Theme.surface,
                cardBorderRadius: 0,
                hoverBorderRadius: 12,
                cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
                cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
                accessibilityOptions: { accessibilityText: `记录日期，当前${this.selectedDate}` },
              })
            }
            .width('100%')
            .borderRadius(Theme.cardRadius)
            .backgroundColor(Theme.surface)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
            .clip(true)

            Column({ space: 10 }) {
              Row() {
                Text('时间与事项')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ink)
                  .layoutWeight(1)
                Text('支持多行粘贴')
                  .fontSize(11)
                  .fontColor(Theme.muted)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .borderRadius(8)
                  .backgroundColor(Theme.surfaceAlt)
              }.width('100%').alignItems(VerticalAlign.Center)

              TextArea({ text: this.input, placeholder: '7:25 起床\n8:00-9:30 高数\n23:30-3:00 开发\n3:00 睡觉' })
                .height(220)
                .fontSize(16)
                .backgroundColor(Theme.surfaceAlt)
                .borderRadius(Theme.pillRadius)
                .maxLength(15000)
                .onChange((value: string) => {
                  this.input = value;
                  this.session.dirty = true;
                  this.error = '';
                })
                .accessibilityText('时间和事项，可输入多行')
                .id('activityInput')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

            Button({ type: ButtonType.Normal, stateEffect: false }) {
              Row() {
                Text('更多选项')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.ink)
                  .layoutWeight(1)
                Text(this.more ? '收起' : '更多')
                  .fontSize(13)
                  .fontColor(Theme.accent)
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 14, bottom: 14 })
              .alignItems(VerticalAlign.Center)
            }
            .width('100%')
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.cardRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
            .scale({
              x: this.interaction.pressedKey === 'more-toggle' ? 0.985 : 1,
              y: this.interaction.pressedKey === 'more-toggle' ? 0.985 : 1,
            })
            .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(
              this.interaction.pressedKey === 'more-toggle', hdsEffect.PointLightIlluminatedType.BORDER))
            .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'more-toggle'))
            .onTouch((event: TouchEvent) => this.interaction.touch('more-toggle', event))
            .onClick(() => {
              this.interaction.activate('more-toggle');
              this.getUIContext().animateTo({ duration: 300, curve: Curve.Friction }, () => {
                this.more = !this.more;
              });
            })
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText(this.more ? '收起更多选项' : '展开更多选项')

            if (this.more) {
              Column({ space: 12 }) {
                if (!this.input.trim().includes('\n')) {
                  Row({ space: 8 }) {
                    ActionButton({
                      label: `开始 ${dayClockText(this.timeValue().startMinute)}`,
                      compact: true,
                      onAction: () => this.pickTime(true),
                    }).layoutWeight(1)
                    ActionButton({
                      label: `结束 ${dayClockText(this.timeValue().endMinute)}`,
                      compact: true,
                      onAction: () => this.pickTime(false),
                    }).layoutWeight(1)
                  }.width('100%')
                }
                Select([{ value: '自动分类' }, ...ACTIVITY_CATEGORIES.map((category: ActivityCategory): SelectOption => ({ value: category.name }))])
                  .selected(ACTIVITY_CATEGORIES.findIndex((category: ActivityCategory) => category.id === this.categoryId) + 1)
                  .value(ACTIVITY_CATEGORIES.find((category: ActivityCategory) => category.id === this.categoryId)?.name ?? '自动分类')
                  .attributeModifier(new PressSelectStyle(this.interaction.pressedKey === 'cat-select'))
                  .onTouch((event: TouchEvent) => this.interaction.touch('cat-select', event))
                  .onSelect((index: number) => {
                    Haptics.confirm();
                    this.categoryId = index > 0 ? ACTIVITY_CATEGORIES[index - 1].id : '';
                    this.session.dirty = true;
                  })
                  .width('100%')
                  .borderRadius(Theme.pillRadius)
                  .accessibilityText('分类')

                Select([{ value: '无地点' }, ...this.atlas.places.map((place: Place): SelectOption => ({ value: place.name }))])
                  .selected(Math.max(0, this.atlas.places.findIndex((place: Place) => place.id === this.placeId) + 1))
                  .value(this.atlas.places.find((place: Place) => place.id === this.placeId)?.name ?? '无地点')
                  .attributeModifier(new PressSelectStyle(this.interaction.pressedKey === 'place-select'))
                  .onTouch((event: TouchEvent) => this.interaction.touch('place-select', event))
                  .onSelect((index: number) => {
                    Haptics.confirm();
                    this.placeId = index > 0 ? this.atlas.places[index - 1].id : '';
                    this.session.dirty = true;
                  })
                  .width('100%')
                  .borderRadius(Theme.pillRadius)
                  .accessibilityText('地点')

                TextArea({ text: this.note, placeholder: '备注' })
                  .height(100)
                  .maxLength(10000)
                  .backgroundColor(Theme.surfaceAlt)
                  .borderRadius(Theme.pillRadius)
                  .onChange((value: string) => {
                    this.note = value;
                    this.session.dirty = true;
                  })
                  .accessibilityText('备注')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(Theme.surface)
              .borderRadius(Theme.panelRadius)
              .border({ width: 1, color: Theme.line })
              .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
              .transition(contentEnterTransition(8))
            }

            if (this.error) {
              Row({ space: 8 }) {
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
              .transition(contentEnterTransition(6))
            }
          }
          Blank().height(40).width('100%')
        }
        .width('100%')
        .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
        .enabled(!this.session.saving)
      }
      .opacity(this.motion.visible ? 1 : 0)
      .translate({ y: this.motion.visible ? 0 : 12 })
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .backgroundColor(Theme.background)
    }
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .titleBar(sheetTitle(this.recordId ? '编辑' : '新增', this.experience.materialLevel, this.actions()))
    .transition(pageTransition())
    .backgroundColor(Theme.background)
    .onWillShow(() => this.motion.prepare())
    .onShown(() => this.motion.enter(this.getUIContext()))
    .onHidden(() => this.motion.stop())
    .onBackPressed(() => this.back())
  }
}
