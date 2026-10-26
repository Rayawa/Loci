import { dateKey, calendarDate } from '../../domain/service/ActivityRules';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { Theme } from '../theme/Theme';
import { vibration } from '../../common/vibration';

@ComponentV2
export struct DateNavigator {
  @Require @Param model: JournalViewModel;
  @Param weekly: boolean = false;

  private pick(): void {
    this.getUIContext().showDatePickerDialog({ selected: calendarDate(this.model.selectedDate),
      start: new Date(1970, 0, 1), end: new Date(2100, 11, 31),
      onDateAccept: (date: Date) => { this.model.selectDate(dateKey(date)); vibration.dotVibration(); } });
  }

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Button('‹').width(44).height(44).backgroundColor(Theme.surface).fontColor(Theme.ink)
          .onClick(() => this.model.moveDay(this.weekly ? -7 : -1)).accessibilityText(this.weekly ? '上一周' : '前一天')
        Button(this.weekly ? `${this.model.days()[0].slice(5)} — ${this.model.days()[6].slice(5)}` : this.model.selectedDate)
          .layoutWeight(1).height(44).fontSize(17).fontColor(Theme.ink).backgroundColor(Theme.surface)
          .onClick(() => this.pick()).accessibilityText(`选择日期，当前${this.model.selectedDate}`)
        Button('›').width(44).height(44).backgroundColor(Theme.surface).fontColor(Theme.ink)
          .onClick(() => this.model.moveDay(this.weekly ? 7 : 1)).accessibilityText(this.weekly ? '下一周' : '后一天')
      }.width('100%')
      if (!this.model.isToday()) {
        Button('今天').fontSize(13).fontColor(Theme.accent).backgroundColor(Color.Transparent).height(40)
          .onClick(() => this.model.today())
      }
    }.width('100%')
  }
}
