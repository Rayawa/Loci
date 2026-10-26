import { Activity } from '../../domain/model/Activity';
import { dayClockText } from '../../domain/service/ActivityRules';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { Theme } from '../theme/Theme';
import { categoryColor } from '../theme/ActivityStyle';

@ComponentV2
export struct WeekTimeline {
  @Require @Param model: JournalViewModel;
  @Event onDay: (day: string) => void = () => {};
  @Event onOpen: (record: Activity) => void = () => {};
  private labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];
  private hours(): number[] {
    const end = Math.max(1440, ...this.model.records.map((value: Activity) => value.endMinute),
      ...this.model.routines.map((value) => value.sleepMinute));
    const hours: number[] = [];
    for (let hour = 0; hour <= Math.ceil(end / 120) * 2; hour += 2) { hours.push(hour); }
    return hours;
  }
  private gridHeight(): number { const hours = this.hours(); return hours[hours.length - 1] * 36 + 16; }

  @Builder timeAxis() {
    Column({ space: 0 }) {
      Text('时间').height(56).width('100%').fontSize(12).fontColor(Theme.muted)
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.hours(), (hour: number) => {
          Text(dayClockText(hour * 60)).fontSize(11).fontColor(Theme.muted).position({ x: 0, y: hour * 36 })
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
              Button({ type: ButtonType.Normal }) {
                Column({ space: 4 }) {
                  Text(this.labels[index]).fontSize(13)
                  Text(day.slice(8)).fontSize(16).fontWeight(FontWeight.Medium)
                }
              }.width(84).height(56).backgroundColor(day === this.model.selectedDate ? Theme.surfaceAlt : Theme.surface)
                .fontColor(day === this.model.selectedDate ? Theme.accent : Theme.ink)
                .onClick(() => this.onDay(day)).accessibilityText(`${day}，查看当日记录`)
            }, (day: string) => day)
          }
          Row({ space: 0 }) {
            ForEach(this.model.days(), (day: string) => {
              Stack({ alignContent: Alignment.TopStart }) {
                ForEach(this.hours(), (hour: number) => {
                  Divider().color(Theme.line).position({ x: 0, y: hour * 36 }).width('100%')
                })
                ForEach(this.model.dayRecords(day), (record: Activity) => {
                  Button({ type: ButtonType.Normal }) {
                    if (record.endMinute - record.startMinute >= 30) {
                      Column({ space: 2 }) {
                        Text(record.title).fontSize(12).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).fontColor(Theme.ink)
                        if (record.endMinute - record.startMinute >= 45) {
                          Text(dayClockText(record.startMinute)).fontSize(11).fontColor(Theme.muted)
                        }
                      }.padding(3).width('100%').alignItems(HorizontalAlign.Start)
                    } else { Blank().width('100%').height('100%') }
                  }.width(80).height(Math.max(5, (record.endMinute - record.startMinute) * 0.6))
                    .borderRadius(5).backgroundColor(record.endMinute - record.startMinute < 30 ? categoryColor(record.categoryId) : Theme.surfaceAlt)
                    .border({ width: { left: 3 }, color: categoryColor(record.categoryId) }).clip(true)
                    .position({ x: 2, y: record.startMinute * 0.6 })
                    .onClick(() => this.onOpen(record))
                    .accessibilityText(`${day} ${record.title} ${dayClockText(record.startMinute)}至${dayClockText(record.endMinute)}`)
                }, (record: Activity) => `${record.id}-${record.updatedAt}`)
              }.width(84).height(this.gridHeight()).border({ width: { left: 0.5 }, color: Theme.line })
            }, (day: string) => day)
          }.alignItems(VerticalAlign.Top)
        }.width(588)
      }.scrollable(ScrollDirection.Horizontal).layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').alignItems(VerticalAlign.Top).padding({ top: 8, bottom: 12 })
      .backgroundColor(Theme.surface).borderRadius(Theme.cardRadius).clip(true)
  }
}
