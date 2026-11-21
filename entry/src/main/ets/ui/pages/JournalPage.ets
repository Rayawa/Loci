import { common } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { Activity } from '../../domain/model/Activity';
import { dayClockText, durationText } from '../../domain/service/ActivityRules';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Haptics } from '../../service/haptics/Haptics';
import { ActivityCard } from '../components/ActivityCard';
import { DateNavigator } from '../components/DateNavigator';
import { PressInteraction } from '../components/PressInteraction';
import { RollingNumber } from '../components/RollingNumber';
import { StaggerEnter } from '../components/StaggerEnter';
import { StatePanel } from '../components/StatePanel';
import { WeekTimeline } from '../components/WeekTimeline';
import { Theme } from '../theme/Theme';
import { JournalViewModel } from '../viewmodel/JournalViewModel';

@ComponentV2
export struct JournalPage {
  @Require @Param model: JournalViewModel;
  @Event onEdit: (id: string) => void = () => {};
  @Event onRoutine: (date: string) => void = () => {};
  @Param viewIndex: number = 0;
  @Param scrollToTopVersion: number = 0;
  @Event onSelectList: () => void = () => {};
  @Local animStep: number = 0;
  @Local contentWidth: number = 0;
  @Local interaction: PressInteraction = new PressInteraction();
  private scroller: Scroller = new Scroller();
  private timers: number[] = [];

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
    this.timers = startStaggerEnterAnimation(this.getUIContext(), 2, (step: number) => {
      this.animStep = step;
    });
  }

  aboutToDisappear(): void {
    cancelStaggerEnterAnimation(this.timers);
    this.interaction.dispose();
  }

  @Monitor('scrollToTopVersion')
  onScrollToTop(): void {
    if (this.scrollToTopVersion <= 0) {
      return;
    }
    try {
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
    } catch (_) {}
  }

  private open(record: Activity): void {
    this.onEdit(record.id);
  }

  private routine(): void {
    this.onRoutine(this.model.selectedDate);
  }

  @Builder
  bentoSummary() {
    GridRow({ columns: 2, gutter: { x: 10, y: 10 } }) {
      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('当日记录')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
          Row({ space: 6 }) {
            RollingNumber({
              value: this.model.dayRecords().length,
              fontSize: 24,
              color: Theme.accent,
              accessibilityLabel: '当日记录数',
            })
            Text('条')
              .fontSize(13)
              .fontColor(Theme.muted)
          }
          .width('100%')
          .alignItems(VerticalAlign.Bottom)
          Text(`累计 ${durationText(this.model.totalMinutes(false))}`)
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
            .maxLines(1)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'summary-count' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'summary-count' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'summary-count', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'summary-count'))
        .onTouch((event: TouchEvent) => this.interaction.touch('summary-count', event))
        .accessibilityGroup(true)
        .accessibilityText(`当日记录${this.model.dayRecords().length}条，累计${durationText(this.model.totalMinutes(false))}`)
      }

      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Row() {
            Text('今日作息')
              .fontSize(12)
              .fontColor(Theme.muted)
              .layoutWeight(1)
            Text('›')
              .fontSize(16)
              .fontColor(Theme.muted)
              .accessibilityLevel('no')
          }.width('100%')
          Text(`起 ${dayClockText(this.model.routine().wakeMinute)}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ink)
            .width('100%')
            .maxLines(1)
          Text(`睡 ${dayClockText(this.model.routine().sleepMinute)}`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.accentPurple)
            .width('100%')
            .maxLines(1)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'summary-routine' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'summary-routine' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'summary-routine', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'summary-routine'))
        .onTouch((event: TouchEvent) => this.interaction.touch('summary-routine', event))
        .onClick(() => {
          this.interaction.activate('summary-routine');
          this.routine();
        })
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityGroup(true)
        .accessibilityText(`今日作息，起 ${dayClockText(this.model.routine().wakeMinute)}，睡 ${dayClockText(this.model.routine().sleepMinute)}，点击调整`)
      }
    }
    .width('100%')
    .opacity(this.animStep >= 1 ? 1 : 0)
    .translate({ y: this.animStep >= 1 ? 0 : 16 })
  }

  @Builder
  boundary(label: string, waking: boolean) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row({ space: 10 }) {
        Row()
          .width(8)
          .height(8)
          .borderRadius(4)
          .backgroundColor(waking ? Theme.accentOrange : Theme.accentPurple)
        Text(label)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ink)
          .layoutWeight(1)
        Text(dayClockText(waking ? this.model.routine().wakeMinute : this.model.routine().sleepMinute))
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.muted)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Center)
    }
    .id(waking ? 'routine-wake' : 'routine-sleep')
    .width('100%')
    .backgroundColor(Theme.surfaceAlt)
    .borderRadius(12)
    .scale({
      x: this.interaction.pressedKey === (waking ? 'wake' : 'sleep') ? 0.985 : 1,
      y: this.interaction.pressedKey === (waking ? 'wake' : 'sleep') ? 0.985 : 1,
    })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(
      this.interaction.pressedKey === (waking ? 'wake' : 'sleep'), hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
    .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === (waking ? 'wake' : 'sleep')))
    .onTouch((event: TouchEvent) => this.interaction.touch(waking ? 'wake' : 'sleep', event))
    .onClick(() => {
      this.interaction.activate(waking ? 'wake' : 'sleep');
      this.routine();
    })
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`${label} ${dayClockText(waking ? this.model.routine().wakeMinute : this.model.routine().sleepMinute)}，设置作息`)
  }

  @Builder
  timelineBody() {
    if (this.model.loading) {
      StatePanel({ title: '正在读取记录', loading: true })
    } else if (this.model.error) {
      StatePanel({
        title: this.model.error,
        action: '重试',
        onAction: () => this.model.retry(this.getUIContext().getHostContext() as common.UIAbilityContext),
      })
    } else if (this.viewIndex === 1) {
      WeekTimeline({
        model: this.model,
        onDay: (day: string) => {
          this.model.selectDate(day);
          this.onSelectList();
        },
        onOpen: (record: Activity) => this.open(record),
      })
    } else {
      Column({ space: 12 }) {
        Row() {
          Text('时间线')
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ink)
            .layoutWeight(1)
          Text(`${this.model.dayRecords().length} 项`)
            .fontSize(12)
            .fontColor(Theme.muted)
            .padding({ left: 8, right: 8, top: 3, bottom: 3 })
            .borderRadius(8)
            .backgroundColor(Theme.surfaceAlt)
        }.width('100%')

        this.boundary('睡觉', false)

        Column({ space: 6 }) {
          if (!this.model.dayRecords().length) {
            Column({ space: 8 }) {
              Stack({ alignContent: Alignment.Center }) {
                SymbolGlyph(Icons.journal).fontSize(22).fontColor([Theme.accent])
              }
              .width(44)
              .height(44)
              .borderRadius(12)
              .backgroundColor(Theme.surfaceAlt)
              Text('暂无记录')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.ink)
              Text('点击右上角 + 记录今天的时间片段')
                .fontSize(12)
                .fontColor(Theme.muted)
            }
            .width('100%')
            .padding({ top: 20, bottom: 20 })
            .alignItems(HorizontalAlign.Center)
          }
          ForEach(this.model.dayRecords(), (record: Activity, index: number) => {
            StaggerEnter({
              order: index,
              speed: 2,
              content: () => {
                ActivityCard({ record: record, onOpen: () => this.open(record) })
              },
            })
          }, (record: Activity) => `${record.id}-${record.updatedAt}`)
        }
        .width('calc(100% - 14vp)')
        .padding({ left: 8, top: 4, bottom: 4 })
        .border({ width: { left: 1.5 }, color: Theme.chartGrid })
        .margin({ left: 14 })

        this.boundary('起床', true)
      }
      .width('100%')
      .padding(14)
      .backgroundColor(Theme.surface)
      .borderRadius(Theme.panelRadius)
      .border({ width: 1, color: Theme.line })
      .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
      .opacity(this.animStep >= 2 ? 1 : 0)
      .translate({ y: this.animStep >= 2 ? 0 : 18 })
    }
  }

  @Builder
  pageContent() {
    if (this.contentWidth >= Theme.wideBreakpoint) {
      Row({ space: 16 }) {
        Column({ space: 14 }) {
          Blank().height(8).width('100%')
          DateNavigator({ model: this.model, weekly: this.viewIndex === 1 })
            .opacity(this.animStep >= 1 ? 1 : 0)
          if (this.viewIndex === 0 && !this.model.loading && !this.model.error) {
            this.bentoSummary()
          }
        }
        .layoutWeight(4)
        .height('100%')
        .padding({ left: Theme.pagePadding, right: Theme.pagePadding })

        Divider().vertical(true).height('100%').color(Theme.border)

        Scroll(this.scroller) {
          Column({ space: 14 }) {
            Blank().height(8).width('100%')
            this.timelineBody()
            Blank().height(110).width('100%')
          }.width('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding })
        }
        .id('journalScroll')
        .layoutWeight(6)
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
      .width('100%')
      .height('100%')
      .constraintSize({ maxWidth: Theme.contentMaxWidth })
      .alignItems(VerticalAlign.Top)
      .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
    } else {
      Scroll(this.scroller) {
        Column({ space: 14 }) {
          Blank().height(8).width('100%')
          DateNavigator({ model: this.model, weekly: this.viewIndex === 1 })
            .opacity(this.animStep >= 1 ? 1 : 0)
          if (this.viewIndex === 0 && !this.model.loading && !this.model.error) {
            this.bentoSummary()
          }
          this.timelineBody()
          Blank().height(110).width('100%')
        }
        .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
        .width('100%')
        .constraintSize({ maxWidth: Theme.contentMaxWidth })
      }
      .id('journalScroll')
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
  }

  build() {
    Stack() {
      if (this.viewIndex === 0) {
        Stack() {
          this.pageContent()
        }
        .width('100%')
        .height('100%')
        .priorityGesture(
          PanGesture({ direction: PanDirection.Horizontal, distance: 45 })
            .onActionEnd((event: GestureEvent) => {
              Haptics.confirm();
              this.model.moveDay(event.offsetX < 0 ? 1 : -1);
            })
        )
      } else {
        this.pageContent()
      }
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Top)
    .onAreaChange((_old: Area, area: Area) => {
      this.contentWidth = Number(area.width);
    })
  }
}
