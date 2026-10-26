import { common } from '@kit.AbilityKit';
import { ActivityTotal } from '../../domain/model/Activity';
import { durationText } from '../../domain/service/ActivityRules';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { DateNavigator } from '../components/DateNavigator';
import { StatePanel } from '../components/StatePanel';
import { Theme } from '../theme/Theme';
import { categoryColor } from '../theme/ActivityStyle';
import { JournalViewModel } from '../viewmodel/JournalViewModel';

@ComponentV2
export struct StatisticsPage {
  @Require @Param model: JournalViewModel;
  @Param weekly: boolean = false;
  @Local animStep: number = 0;
  private timers: number[] = [];
  private labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void { this.timers = startStaggerEnterAnimation(this.getUIContext(), 3, (step: number) => { this.animStep = step; }); }
  aboutToDisappear(): void { cancelStaggerEnterAnimation(this.timers); }
  private maxMinutes(): number { return Math.max(60, ...this.model.itemTotals().map((total: ActivityTotal) => total.minutes)); }
  private wedge(index: number): string {
    const totals = this.model.totals(this.weekly);
    const total = Math.max(1, this.model.totalMinutes(this.weekly));
    const value = totals[index].minutes;
    // SVG path commands use physical pixels; the component frame uses vp.
    const center = this.getUIContext().vp2px(90); const radius = this.getUIContext().vp2px(84);
    if (value === total) {
      return `M ${center} ${center - radius} A ${radius} ${radius} 0 1 1 ${center} ${center + radius} A ${radius} ${radius} 0 1 1 ${center} ${center - radius} Z`;
    }
    const previous = totals.slice(0, index).reduce((sum: number, item: ActivityTotal) => sum + item.minutes, 0);
    const start = previous / total * Math.PI * 2 - Math.PI / 2;
    const end = (previous + value) / total * Math.PI * 2 - Math.PI / 2;
    return `M ${center} ${center} L ${center + radius * Math.cos(start)} ${center + radius * Math.sin(start)} A ${radius} ${radius} 0 ${value / total > 0.5 ? 1 : 0} 1 ${center + radius * Math.cos(end)} ${center + radius * Math.sin(end)} Z`;
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Blank().height(100).width('100%')
        DateNavigator({ model: this.model, weekly: this.weekly })
        Column({ space: 6 }) {
          Text(this.weekly ? '本周' : this.model.isToday() ? '今天' : '当日').fontSize(26).fontWeight(FontWeight.Medium).fontColor(Theme.ink).width('100%')
          Text(`累计 ${durationText(this.model.totalMinutes(this.weekly))} · ${this.model.periodRecords(this.weekly).length}条记录`)
            .fontSize(16).fontColor(Theme.muted).width('100%')
        }.width('100%').opacity(this.animStep >= 1 ? 1 : 0).translate({ y: this.animStep >= 1 ? 0 : 20 })
        if (this.model.loading) { StatePanel({ title: '正在统计', loading: true }) }
        else if (this.model.error) { StatePanel({ title: this.model.error, action: '重试', onAction: () => this.model.retry(this.getUIContext().getHostContext() as common.UIAbilityContext) }) }
        else {
          Column({ space: 16 }) {
            Text('分类统计').fontSize(17).fontWeight(FontWeight.Medium).fontColor(Theme.ink).width('100%')
            if (this.model.totals(this.weekly).length === 0) {
              StatePanel({ title: '暂无时段' })
            } else {
              Stack() {
                ForEach(this.model.totals(this.weekly), (total: ActivityTotal, index: number) => {
                  Path().commands(this.wedge(index)).fill(categoryColor(total.key)).strokeWidth(0).width(180).height(180)
                }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)
              }.width(180).height(180).accessibilityText('分类时长饼图，详细时长及占比见下方列表')
              ForEach(this.model.totals(this.weekly), (total: ActivityTotal) => {
                Row({ space: 10 }) {
                  Row().width(8).height(8).backgroundColor(categoryColor(total.key)).borderRadius(4)
                  Text(total.name).fontSize(15).fontColor(Theme.ink).layoutWeight(1)
                  Text(durationText(total.minutes)).fontSize(14).fontColor(Theme.ink)
                  Text(`${Math.round(total.minutes / Math.max(1, this.model.totalMinutes(this.weekly)) * 100)}%`)
                    .fontSize(13).fontColor(Theme.muted).width(44).textAlign(TextAlign.End)
                }.width('100%').accessibilityText(`${total.name}，${durationText(total.minutes)}`)
              }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)
            }
          }.width('100%').padding(16).backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
            .opacity(this.animStep >= 2 ? 1 : 0).translate({ y: this.animStep >= 2 ? 0 : 20 })
          Column({ space: 16 }) {
            Text('单项').fontSize(17).fontWeight(FontWeight.Medium).fontColor(Theme.ink).width('100%')
            if (this.model.titles().length === 0) { Text('暂无记录').fontSize(14).fontColor(Theme.muted) }
            else {
              Select(this.model.titles().map((title: string): SelectOption => ({ value: title })))
                .selected(this.model.titles().indexOf(this.model.selectedTitle)).value(this.model.selectedTitle)
                .onSelect((index: number) => { this.model.selectedTitle = this.model.titles()[index]; })
                .width('100%').accessibilityText('选择统计事项')
              Text(`分钟 · ${this.model.days()[0]} — ${this.model.days()[6]}`).fontSize(12).fontColor(Theme.muted).width('100%')
              Row({ space: 6 }) {
                ForEach(this.model.itemTotals(), (total: ActivityTotal, index: number) => {
                  Column({ space: 8 }) {
                    Text(`${total.minutes}`).fontSize(11).fontColor(Theme.muted)
                    Stack({ alignContent: Alignment.Bottom }) {
                      Rect().width(20).height(Math.max(0, total.minutes / this.maxMinutes() * 130)).fill(Theme.accent).radius(4)
                    }.height(130).width('100%')
                    Text(this.labels[index]).fontSize(13).fontColor(Theme.muted)
                  }.layoutWeight(1).height(176).justifyContent(FlexAlign.End)
                    .accessibilityText(`${total.key}，${durationText(total.minutes)}`)
                }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)
              }.width('100%').alignItems(VerticalAlign.Bottom)
            }
          }.width('100%').padding(16).backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
            .opacity(this.animStep >= 3 ? 1 : 0).translate({ y: this.animStep >= 3 ? 0 : 20 })
        }
        Blank().height(110).width('100%')
      }.width('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding })
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }
}
