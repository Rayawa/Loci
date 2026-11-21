import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { contentEnterTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { calendarDate, dateKey } from '../../domain/service/ActivityRules';
import { vibration } from '../../common/vibration';
import { Theme } from '../theme/Theme';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { PressInteraction } from './PressInteraction';

const WEEKDAY_LABELS: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

@ComponentV2
export struct DateNavigator {
  @Require @Param model: JournalViewModel;
  @Param weekly: boolean = false;
  @Local interaction: PressInteraction = new PressInteraction();

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
  }

  aboutToDisappear(): void {
    this.interaction.dispose();
  }

  private pick(): void {
    this.getUIContext().showDatePickerDialog({
      selected: calendarDate(this.model.selectedDate),
      start: new Date(1970, 0, 1),
      end: new Date(2100, 11, 31),
      onDateAccept: (date: Date) => {
        this.model.selectDate(dateKey(date));
        vibration.dotVibration();
      },
    });
  }

  private dateLabel(): string {
    if (this.weekly) {
      return `${this.model.days()[0].slice(5)} — ${this.model.days()[6].slice(5)}`;
    }
    return this.model.selectedDate;
  }

  private badgeLabel(): string {
    if (this.weekly) {
      return '本周';
    }
    return WEEKDAY_LABELS[calendarDate(this.model.selectedDate).getDay()] ?? '';
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Button('‹', { type: ButtonType.Normal, stateEffect: false })
          .width(40)
          .height(40)
          .borderRadius(12)
          .fontSize(20)
          .fontColor(Theme.ink)
          .backgroundColor(Theme.surfaceAlt)
          .scale({
            x: this.interaction.pressedKey === 'prev' ? 0.95 : 1,
            y: this.interaction.pressedKey === 'prev' ? 0.95 : 1,
          })
          .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.interaction.pressedKey === 'prev', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
          .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'prev'))
          .onTouch((event: TouchEvent) => this.interaction.touch('prev', event))
          .onClick(() => {
            this.interaction.activate('prev');
            this.model.moveDay(this.weekly ? -7 : -1);
          })
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText(this.weekly ? '上一周' : '前一天')

        Button({ type: ButtonType.Normal, stateEffect: false }) {
          Row({ space: 8 }) {
            SymbolGlyph(Icons.journal)
              .fontSize(16)
              .fontColor([Theme.accent])
            Text(this.dateLabel())
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.ink)
              .maxLines(1)
            Text(this.badgeLabel())
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.model.isToday() && !this.weekly ? Theme.accent : Theme.muted)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
              .borderRadius(8)
              .backgroundColor(Theme.surfaceAlt)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
        }
        .layoutWeight(1)
        .height(40)
        .borderRadius(12)
        .backgroundColor(this.interaction.pressedKey === 'pick' ? Theme.surfaceAlt : Color.Transparent)
        .scale({
          x: this.interaction.pressedKey === 'pick' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'pick' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'pick', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'pick'))
        .onTouch((event: TouchEvent) => this.interaction.touch('pick', event))
        .onClick(() => {
          this.interaction.activate('pick');
          this.pick();
        })
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityText(`选择日期，当前${this.model.selectedDate}`)

        Button('›', { type: ButtonType.Normal, stateEffect: false })
          .width(40)
          .height(40)
          .borderRadius(12)
          .fontSize(20)
          .fontColor(Theme.ink)
          .backgroundColor(Theme.surfaceAlt)
          .scale({
            x: this.interaction.pressedKey === 'next' ? 0.95 : 1,
            y: this.interaction.pressedKey === 'next' ? 0.95 : 1,
          })
          .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.interaction.pressedKey === 'next', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
          .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'next'))
          .onTouch((event: TouchEvent) => this.interaction.touch('next', event))
          .onClick(() => {
            this.interaction.activate('next');
            this.model.moveDay(this.weekly ? 7 : 1);
          })
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText(this.weekly ? '下一周' : '后一天')
      }
      .width('100%')
      .padding(6)
      .backgroundColor(Theme.surface)
      .borderRadius(Theme.cardRadius)
      .border({ width: 1, color: Theme.line })
      .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

      if (!this.model.isToday()) {
        Row() {
          Blank()
          Button('今天', { type: ButtonType.Normal, stateEffect: false })
            .height(32)
            .padding({ left: 12, right: 12 })
            .borderRadius(12)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.accent)
            .backgroundColor(Theme.surfaceAlt)
            .border({ width: 1, color: Theme.line })
            .scale({
              x: this.interaction.pressedKey === 'today' ? 0.96 : 1,
              y: this.interaction.pressedKey === 'today' ? 0.96 : 1,
            })
            .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(
              this.interaction.pressedKey === 'today', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
            .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'today'))
            .onTouch((event: TouchEvent) => this.interaction.touch('today', event))
            .onClick(() => {
              this.interaction.activate('today');
              this.model.today();
            })
            .transition(contentEnterTransition(6))
            .accessibilityRole(AccessibilityRoleType.BUTTON)
            .accessibilityText('回到今天')
        }.width('100%')
      }
    }.width('100%')
  }
}
