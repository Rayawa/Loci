import { common } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { ActivityTotal } from '../../domain/model/Activity';
import { durationText } from '../../domain/service/ActivityRules';
import { Haptics } from '../../service/haptics/Haptics';
import { DateNavigator } from '../components/DateNavigator';
import { PressInteraction, PressSelectStyle } from '../components/PressInteraction';
import { RollingNumber } from '../components/RollingNumber';
import { StatePanel } from '../components/StatePanel';
import { categoryColor } from '../theme/ActivityStyle';
import { Theme } from '../theme/Theme';
import { JournalViewModel } from '../viewmodel/JournalViewModel';

@ComponentV2
export struct StatisticsPage {
  @Require @Param model: JournalViewModel;
  @Param weekly: boolean = false;
  @Param scrollToTopVersion: number = 0;
  @Local animStep: number = 0;
  @Local contentWidth: number = 0;
  @Local selectedCategoryKey: string = '';
  @Local selectedDayIndex: number = -1;
  @Local interaction: PressInteraction = new PressInteraction();
  private scroller: Scroller = new Scroller();
  private timers: number[] = [];
  private labels: string[] = ['一', '二', '三', '四', '五', '六', '日'];

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
    this.timers = startStaggerEnterAnimation(this.getUIContext(), 3, (step: number) => {
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

  private maxMinutes(): number {
    return Math.max(60, ...this.model.itemTotals().map((total: ActivityTotal) => total.minutes));
  }

  private selectedCategory(totals: ActivityTotal[]): ActivityTotal | undefined {
    if (!this.selectedCategoryKey) {
      return undefined;
    }
    return totals.find((item: ActivityTotal) => item.key === this.selectedCategoryKey);
  }

  private categoryPercent(minutes: number): number {
    return Math.round(minutes / Math.max(1, this.model.totalMinutes(this.weekly)) * 100);
  }

  private wedge(index: number): string {
    const totals = this.model.totals(this.weekly);
    const total = Math.max(1, this.model.totalMinutes(this.weekly));
    const value = totals[index].minutes;
    // SVG path commands use physical pixels; the component frame uses vp.
    const center = this.getUIContext().vp2px(90);
    const radius = this.getUIContext().vp2px(84);
    if (value === total) {
      return `M ${center} ${center - radius} A ${radius} ${radius} 0 1 1 ${center} ${center + radius} A ${radius} ${radius} 0 1 1 ${center} ${center - radius} Z`;
    }
    const previous = totals.slice(0, index).reduce((sum: number, item: ActivityTotal) => sum + item.minutes, 0);
    const start = previous / total * Math.PI * 2 - Math.PI / 2;
    const end = (previous + value) / total * Math.PI * 2 - Math.PI / 2;
    return `M ${center} ${center} L ${center + radius * Math.cos(start)} ${center + radius * Math.sin(start)} A ${radius} ${radius} 0 ${value / total > 0.5 ? 1 : 0} 1 ${center + radius * Math.cos(end)} ${center + radius * Math.sin(end)} Z`;
  }

  @Builder
  kpiCards() {
    GridRow({ columns: 2, gutter: { x: 10, y: 10 } }) {
      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text(this.weekly ? '本周累计' : this.model.isToday() ? '今日累计' : '当日累计')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
          Text(durationText(this.model.totalMinutes(this.weekly)))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.accent)
            .maxLines(1)
            .width('100%')
          Text(this.weekly ? '7日记录汇总' : '当日记录汇总')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'kpi-duration' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'kpi-duration' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'kpi-duration', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'kpi-duration'))
        .onTouch((event: TouchEvent) => this.interaction.touch('kpi-duration', event))
        .accessibilityGroup(true)
        .accessibilityText(`${this.weekly ? '本周累计' : '当日累计'} ${durationText(this.model.totalMinutes(this.weekly))}`)
      }

      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('记录条数')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
          Row({ space: 6 }) {
            RollingNumber({
              value: this.model.periodRecords(this.weekly).length,
              fontSize: 24,
              color: Theme.accentCyan,
              accessibilityLabel: '记录条数',
            })
            Text('条')
              .fontSize(13)
              .fontColor(Theme.muted)
          }.width('100%').alignItems(VerticalAlign.Bottom)
          Text(`覆盖 ${this.model.totals(this.weekly).length} 个分类`)
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'kpi-count' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'kpi-count' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'kpi-count', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'kpi-count'))
        .onTouch((event: TouchEvent) => this.interaction.touch('kpi-count', event))
        .accessibilityGroup(true)
        .accessibilityText(`共 ${this.model.periodRecords(this.weekly).length} 条记录，覆盖 ${this.model.totals(this.weekly).length} 个分类`)
      }
    }
    .width('100%')
    .opacity(this.animStep >= 1 ? 1 : 0)
    .translate({ y: this.animStep >= 1 ? 0 : 20 })
  }

  @Builder
  donutGraphic(totals: ActivityTotal[]) {
    Stack({ alignContent: Alignment.Center }) {
      ForEach(totals, (total: ActivityTotal, index: number) => {
        Path()
          .commands(this.wedge(index))
          .fill(categoryColor(total.key))
          .opacity(!this.selectedCategory(totals) || this.selectedCategoryKey === total.key ? 1 : 0.35)
          .strokeWidth(0)
          .width(180)
          .height(180)
      }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)

      Column({ space: 2 }) {
        Text(this.selectedCategory(totals)?.name ?? '总时长')
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.muted)
          .maxLines(1)
        Text(this.selectedCategory(totals)
          ? `${this.categoryPercent(this.selectedCategory(totals)!.minutes)}%`
          : `${totals.length} 项`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.selectedCategory(totals) ? categoryColor(this.selectedCategory(totals)!.key) : Theme.ink)
          .maxLines(1)
        Text(durationText(this.selectedCategory(totals)?.minutes ?? this.model.totalMinutes(this.weekly)))
          .fontSize(11)
          .fontColor(Theme.muted)
          .maxLines(1)
      }
      .width(102)
      .height(102)
      .borderRadius(51)
      .backgroundColor(Theme.surface)
      .border({ width: 1, color: Theme.line })
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(6)
    }
    .width(180)
    .height(180)
    .accessibilityText('分类时长环形图，详细时长及占比见图例')
  }

  @Builder
  categoryLegendGrid(totals: ActivityTotal[]) {
    GridRow({ columns: 2, gutter: { x: 8, y: 8 } }) {
      ForEach(totals, (total: ActivityTotal) => {
        GridCol({ span: 1 }) {
          Column({ space: 6 }) {
            Row({ space: 6 }) {
              Row()
                .width(8)
                .height(8)
                .borderRadius(4)
                .backgroundColor(categoryColor(total.key))
                .flexShrink(0)
              Text(total.name)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.ink)
                .layoutWeight(1)
                .maxLines(1)
              Text(`${this.categoryPercent(total.minutes)}%`)
                .fontSize(12)
                .fontWeight(FontWeight.Medium)
                .fontColor(Theme.muted)
            }.width('100%').alignItems(VerticalAlign.Center)

            Text(durationText(total.minutes))
              .fontSize(12)
              .fontColor(Theme.muted)
              .width('100%')
              .maxLines(1)

            Stack({ alignContent: Alignment.Start }) {
              Row()
                .width('100%')
                .height(4)
                .borderRadius(2)
                .backgroundColor(Theme.barTrack)
              Row()
                .width(`${Math.max(4, this.categoryPercent(total.minutes))}%`)
                .height(4)
                .borderRadius(2)
                .backgroundColor(categoryColor(total.key))
            }.width('100%').height(4)
          }
          .width('100%')
          .padding(10)
          .borderRadius(12)
          .backgroundColor(this.selectedCategoryKey === total.key ? Theme.surfaceAlt : Theme.surface)
          .border({ width: 1, color: this.selectedCategoryKey === total.key ? Theme.accent : Theme.line })
          .scale({
            x: this.interaction.pressedKey === `cat-${total.key}` ? 0.97 : 1,
            y: this.interaction.pressedKey === `cat-${total.key}` ? 0.97 : 1,
          })
          .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.interaction.pressedKey === `cat-${total.key}`, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
          .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === `cat-${total.key}`))
          .onTouch((event: TouchEvent) => this.interaction.touch(`cat-${total.key}`, event))
          .onClick(() => {
            this.interaction.activate(`cat-${total.key}`);
            this.selectedCategoryKey = this.selectedCategoryKey === total.key ? '' : total.key;
          })
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText(`${total.name}，${durationText(total.minutes)}，占比${this.categoryPercent(total.minutes)}%`)
        }
      }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)
    }.width('100%')
  }

  @Builder
  categoryCard() {
    Column({ space: 14 }) {
      Row() {
        Text('分类统计')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ink)
          .layoutWeight(1)
        if (this.selectedCategory(this.model.totals(this.weekly))) {
          Text('点击还原')
            .fontSize(12)
            .fontColor(Theme.accent)
            .onClick(() => {
              Haptics.confirm();
              this.selectedCategoryKey = '';
            })
        }
      }.width('100%')

      if (this.model.totals(this.weekly).length === 0) {
        Column({ space: 8 }) {
          Stack({ alignContent: Alignment.Center }) {
            SymbolGlyph(Icons.statistics).fontSize(22).fontColor([Theme.accent])
          }.width(44).height(44).borderRadius(12).backgroundColor(Theme.surfaceAlt)
          Text('暂无时段').fontSize(14).fontColor(Theme.muted)
        }.width('100%').padding({ top: 16, bottom: 16 }).alignItems(HorizontalAlign.Center)
      } else if (this.contentWidth >= 600 && this.contentWidth < Theme.wideBreakpoint) {
        Row({ space: 14 }) {
          this.donutGraphic(this.model.totals(this.weekly))
          Column() {
            this.categoryLegendGrid(this.model.totals(this.weekly))
          }.layoutWeight(1)
        }.width('100%').alignItems(VerticalAlign.Center)
      } else {
        this.donutGraphic(this.model.totals(this.weekly))
        this.categoryLegendGrid(this.model.totals(this.weekly))
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
    .opacity(this.animStep >= 2 ? 1 : 0)
    .translate({ y: this.animStep >= 2 ? 0 : 20 })
  }

  @Builder
  itemTrendCard() {
    Column({ space: 14 }) {
      Row({ space: 8 }) {
        Text('单项趋势')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ink)
          .layoutWeight(1)
        Text(`${this.model.days()[0].slice(5)} — ${this.model.days()[6].slice(5)}`)
          .fontSize(12)
          .fontColor(Theme.muted)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(8)
          .backgroundColor(Theme.surfaceAlt)
      }.width('100%')

      if (this.model.titles().length === 0) {
        Text('暂无记录').fontSize(14).fontColor(Theme.muted).padding({ top: 8, bottom: 8 })
      } else {
        Select(this.model.titles().map((title: string): SelectOption => ({ value: title })))
          .selected(this.model.titles().indexOf(this.model.selectedTitle))
          .value(this.model.selectedTitle)
          .attributeModifier(new PressSelectStyle(this.interaction.pressedKey === 'stat-select'))
          .onTouch((event: TouchEvent) => this.interaction.touch('stat-select', event))
          .onSelect((index: number) => {
            Haptics.confirm();
            this.model.selectedTitle = this.model.titles()[index];
          })
          .width('100%')
          .borderRadius(Theme.pillRadius)
          .accessibilityText('选择统计事项')

        Row({ space: 6 }) {
          ForEach(this.model.itemTotals(), (total: ActivityTotal, index: number) => {
            Column({ space: 6 }) {
              Text(`${total.minutes}`)
                .fontSize(11)
                .fontWeight(this.selectedDayIndex === index ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.selectedDayIndex === index ? Theme.accent : Theme.muted)

              Stack({ alignContent: Alignment.Bottom }) {
                Rect()
                  .width(22)
                  .height(132)
                  .fill(Theme.barTrack)
                  .radius(8)
                if (total.minutes > 0) {
                  Rect()
                    .width(22)
                    .height(Math.max(8, total.minutes / this.maxMinutes() * 132))
                    .fill(this.selectedDayIndex === index || this.model.days()[index] === this.model.selectedDate
                      ? Theme.accent : Theme.accentCyan)
                    .radius(8)
                    .animation({ duration: 360, curve: curves.springMotion(0.45, 0.9) })
                }
              }.height(132).width('100%')

              Text(this.labels[index])
                .fontSize(12)
                .fontWeight(this.selectedDayIndex === index || this.model.days()[index] === this.model.selectedDate
                  ? FontWeight.Bold : FontWeight.Regular)
                .fontColor(this.selectedDayIndex === index || this.model.days()[index] === this.model.selectedDate
                  ? Theme.accent : Theme.muted)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(6)
                .backgroundColor(this.selectedDayIndex === index ? Theme.surfaceAlt : Color.Transparent)
            }
            .layoutWeight(1)
            .height(184)
            .justifyContent(FlexAlign.End)
            .borderRadius(10)
            .scale({
              x: this.interaction.pressedKey === `bar-${index}` ? 0.96 : 1,
              y: this.interaction.pressedKey === `bar-${index}` ? 0.96 : 1,
            })
            .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(
              this.interaction.pressedKey === `bar-${index}`, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 4, 80))
            .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === `bar-${index}`))
            .onTouch((event: TouchEvent) => this.interaction.touch(`bar-${index}`, event))
            .onClick(() => {
              this.interaction.activate(`bar-${index}`);
              this.selectedDayIndex = this.selectedDayIndex === index ? -1 : index;
            })
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText(`${total.key}，${durationText(total.minutes)}`)
          }, (total: ActivityTotal) => `${total.key}-${total.minutes}`)
        }.width('100%').alignItems(VerticalAlign.Bottom)
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
    .opacity(this.animStep >= 3 ? 1 : 0)
    .translate({ y: this.animStep >= 3 ? 0 : 20 })
  }

  @Builder
  chartsBody() {
    if (this.model.loading) {
      StatePanel({ title: '正在统计', loading: true })
    } else if (this.model.error) {
      StatePanel({
        title: this.model.error,
        action: '重试',
        onAction: () => this.model.retry(this.getUIContext().getHostContext() as common.UIAbilityContext),
      })
    } else {
      this.categoryCard()
      this.itemTrendCard()
    }
  }

  build() {
    Stack() {
      if (this.contentWidth >= Theme.wideBreakpoint) {
        Row({ space: 16 }) {
          Column({ space: 14 }) {
            Blank().height(8).width('100%')
            DateNavigator({ model: this.model, weekly: this.weekly })
            this.kpiCards()
          }
          .layoutWeight(4)
          .height('100%')
          .padding({ left: Theme.pagePadding, right: Theme.pagePadding })

          Divider().vertical(true).height('100%').color(Theme.border)

          Scroll(this.scroller) {
            Column({ space: 14 }) {
              Blank().height(8).width('100%')
              this.chartsBody()
              Blank().height(110).width('100%')
            }.width('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding })
          }
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
            DateNavigator({ model: this.model, weekly: this.weekly })
            this.kpiCards()
            this.chartsBody()
            Blank().height(110).width('100%')
          }
          .width('100%')
          .constraintSize({ maxWidth: Theme.contentMaxWidth })
          .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
        }
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
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
