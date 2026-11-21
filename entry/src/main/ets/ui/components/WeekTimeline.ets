import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Activity } from '../../domain/model/Activity';
import { dayClockText } from '../../domain/service/ActivityRules';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { PressInteraction } from './PressInteraction';
import { Theme } from '../theme/Theme';
import { categoryColor } from '../theme/ActivityStyle';

@ComponentV2
export struct WeekTimeline {
  @Require @Param model: JournalViewModel;
  @Event onDay: (day: string) => void = () => {};
  @Event onOpen: (record: Activity) => void = () => {};
  @Local interaction: PressInteraction = new PressInteraction();
  private labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
  }

  aboutToDisappear(): void {
    this.interaction.dispose();
  }

  private hours(): number[] {
    const end = Math.max(1440, ...this.model.records.map((value: Activity) => value.endMinute),
      ...this.model.routines.map((value) => value.sleepMinute));
    const hours: number[] = [];
    for (let hour = 0; hour <= Math.ceil(end / 120) * 2; hour += 2) {
      hours.push(hour);
    }
    return hours;
  }

  private gridHeight(): number {
    const hours = this.hours();
    return hours[hours.length - 1] * 36 + 16;
  }

  @Builder
  timeAxis() {
    Column({ space: 0 }) {
      Text('时间')
        .height(56)
        .width('100%')
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.muted)
        .textAlign(TextAlign.Center)
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.hours(), (hour: number) => {
          Text(dayClockText(hour * 60))
            .fontSize(11)
            .fontColor(Theme.muted)
            .width('100%')
            .textAlign(TextAlign.Center)
            .position({ x: 0, y: hour * 36 })
        })
      }.width(64).height(this.gridHeight())
    }.width(64)
  }

  build() {
    // Keep hour labels outside the horizontal viewport, aligned with every day.
    Row({ space: 0 }) {
      this.timeAxis()
      Scroll() {
        Column({ space: 0 }) {
          Row({ space: 0 }) {
            ForEach(this.model.days(), (day: string, index: number) => {
              Button({ type: ButtonType.Normal, stateEffect: false }) {
                Column({ space: 4 }) {
                  Text(this.labels[index])
                    .fontSize(12)
                    .fontColor(day === this.model.selectedDate ? Theme.onAccent : Theme.muted)
                  Text(day.slice(8))
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(day === this.model.selectedDate ? Theme.onAccent : Theme.ink)
                }
                .width(76)
                .height(48)
                .justifyContent(FlexAlign.Center)
                .borderRadius(12)
                .backgroundColor(day === this.model.selectedDate ? Theme.accent : Theme.surfaceAlt)
              }
              .width(84)
              .height(56)
              .backgroundColor(Theme.surface)
              .scale({
                x: this.interaction.pressedKey === `day-${day}` ? 0.96 : 1,
                y: this.interaction.pressedKey === `day-${day}` ? 0.96 : 1,
              })
              .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
              .visualEffect(pressVisualEffect(
                this.interaction.pressedKey === `day-${day}`, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
              .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === `day-${day}`))
              .onTouch((event: TouchEvent) => this.interaction.touch(`day-${day}`, event))
              .onClick(() => {
                this.interaction.activate(`day-${day}`);
                this.onDay(day);
              })
              .accessibilityRole(AccessibilityRoleType.BUTTON)
              .accessibilityText(`${day}，查看当日记录`)
            }, (day: string) => day)
          }

          Row({ space: 0 }) {
            ForEach(this.model.days(), (day: string) => {
              Stack({ alignContent: Alignment.TopStart }) {
                ForEach(this.hours(), (hour: number) => {
                  Divider().color(Theme.chartGrid).position({ x: 0, y: hour * 36 }).width('100%')
                })
                ForEach(this.model.dayRecords(day), (record: Activity) => {
                  Button({ type: ButtonType.Normal, stateEffect: false }) {
                    if (record.endMinute - record.startMinute >= 30) {
                      Column({ space: 2 }) {
                        Text(record.title)
                          .fontSize(12)
                          .fontWeight(FontWeight.Medium)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .fontColor(Theme.ink)
                        if (record.endMinute - record.startMinute >= 45) {
                          Text(dayClockText(record.startMinute))
                            .fontSize(11)
                            .fontColor(Theme.muted)
                        }
                      }.padding({ left: 5, right: 4, top: 3, bottom: 3 }).width('100%').alignItems(HorizontalAlign.Start)
                    } else {
                      Blank().width('100%').height('100%')
                    }
                  }
                  .width(80)
                  .height(Math.max(5, (record.endMinute - record.startMinute) * 0.6))
                  .borderRadius(8)
                  .backgroundColor(record.endMinute - record.startMinute < 30 ? categoryColor(record.categoryId) : Theme.surfaceAlt)
                  .border({ width: { left: 3.5 }, color: categoryColor(record.categoryId) })
                  .clip(true)
                  .position({ x: 2, y: record.startMinute * 0.6 })
                  .scale({
                    x: this.interaction.pressedKey === `wk-${record.id}` ? 0.97 : 1,
                    y: this.interaction.pressedKey === `wk-${record.id}` ? 0.97 : 1,
                  })
                  .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
                  .visualEffect(pressVisualEffect(
                    this.interaction.pressedKey === `wk-${record.id}`, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                  .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === `wk-${record.id}`))
                  .onTouch((event: TouchEvent) => this.interaction.touch(`wk-${record.id}`, event))
                  .onClick(() => {
                    this.interaction.activate(`wk-${record.id}`);
                    this.onOpen(record);
                  })
                  .accessibilityRole(AccessibilityRoleType.BUTTON)
                  .accessibilityText(`${day} ${record.title} ${dayClockText(record.startMinute)}至${dayClockText(record.endMinute)}`)
                }, (record: Activity) => `${record.id}-${record.updatedAt}`)
              }.width(84).height(this.gridHeight()).border({ width: { left: 0.5 }, color: Theme.chartGrid })
            }, (day: string) => day)
          }.alignItems(VerticalAlign.Top)
        }.width(588)
      }.scrollable(ScrollDirection.Horizontal).layoutWeight(1).scrollBar(BarState.Off)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 10, bottom: 12, left: 6, right: 6 })
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
    .clip(true)
    .id('weekTimeline')
  }
}
