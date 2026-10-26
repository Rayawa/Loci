import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { DayRoutine } from '../../domain/model/DayRoutine';
import { calendarDate, dayClockText } from '../../domain/service/ActivityRules';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { destinationActions, PageAction } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';

@ComponentV2
export struct DayRoutinePage {
  @Require @Param model: JournalViewModel;
  @Require @Param localDate: string;
  @Require @Param stack: NavPathStack;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local wake: number = -1;
  @Local sleep: number = -1;
  @Local loading: boolean = true;
  @Local saving: boolean = false;
  @Local ready: boolean = false;
  @Local dirty: boolean = false;
  @Local error: string = '';
  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    this.loading = true; this.error = ''; this.ready = false;
    try { const value = await this.model.getRepository().getRoutine(this.localDate); this.wake = value.wakeMinute; this.sleep = value.sleepMinute; this.ready = true; }
    catch (_) { this.error = '读取失败'; } finally { this.loading = false; }
  }
  private pick(waking: boolean): void {
    const existing = waking ? this.wake : this.sleep;
    const minute = existing >= 0 ? existing % 1440 : waking ? 420 : 1380;
    const selected = calendarDate(this.localDate); selected.setHours(Math.floor(minute / 60), minute % 60, 0, 0);
    this.getUIContext().showTimePickerDialog({ selected: selected, useMilitaryTime: true,
      onAccept: (value: TimePickerResult) => {
        const clock = (value.hour ?? 0) * 60 + (value.minute ?? 0);
        if (waking) { this.wake = clock; if (this.sleep >= 0 && this.sleep <= clock) { this.sleep += 1440; } }
        else { this.sleep = clock + ((this.wake >= 0 && clock <= this.wake) || (this.wake < 0 && clock < 720) ? 1440 : 0); }
        this.dirty = true;
      } });
  }
  private async save(): Promise<void> {
    if (this.saving || !this.ready) { return; } this.saving = true;
    const value = new DayRoutine(); value.localDate = this.localDate; value.wakeMinute = this.wake; value.sleepMinute = this.sleep;
    try { await this.model.getRepository().saveRoutine(value); this.dirty = false; this.model.refresh(); this.stack.pop(); }
    catch (error) { this.error = (error as Error).message || '保存失败'; } finally { this.saving = false; }
  }
  private back(): boolean {
    if (this.saving) { return true; } if (!this.dirty) { return false; }
    this.getUIContext().showAlertDialog({ title: '放弃修改？', message: '', primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃', action: () => { this.dirty = false; this.stack.pop(); } } }); return true;
  }
  private actions(): PageAction[] {
    return [{ label: '保存', icon: Icons.save, isEnabled: this.ready && !this.saving && this.dirty, action: () => this.save() },
      { label: '重置', icon: $r('sys.symbol.arrow_counterclockwise'), isEnabled: this.ready && !this.saving,
        action: () => { this.wake = -1; this.sleep = -1; this.dirty = true; } }];
  }
  build() {
    HdsNavDestination() {
      Column({ space: 16 }) {
        Blank().height(100).width('100%')
        Text(this.localDate).fontSize(14).fontColor(Theme.muted)
        Button(`起床  ${dayClockText(this.wake)}`).width('100%').height(54).fontSize(17).fontColor(Theme.ink)
          .backgroundColor(Theme.surface).borderRadius(16).enabled(this.ready).onClick(() => this.pick(true))
        Button(`睡觉  ${dayClockText(this.sleep)}`).width('100%').height(54).fontSize(17).fontColor(Theme.ink)
          .backgroundColor(Theme.surface).borderRadius(16).enabled(this.ready).onClick(() => this.pick(false))
        if (this.sleep >= 0) {
          Row({ space: 10 }) {
            Checkbox({ name: 'nextDay' }).select(this.sleep >= 1440).onChange((checked: boolean) => {
              this.sleep = this.sleep % 1440 + (checked ? 1440 : 0); this.dirty = true;
            })
            Text('次日睡觉').fontSize(14).fontColor(Theme.muted)
          }
        }
        if (this.error) { Text(this.error).fontSize(14).fontColor(Theme.ink) }
        if (!this.loading && !this.ready) {
          Button('重试').onClick(() => this.load()).enabled(true)
        }
        Blank().layoutWeight(1)
      }.width('100%').height('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding }).enabled(!this.saving)
    }.titleMode(HdsNavDestinationTitleMode.MINI).titleBar(destinationActions('作息', this.experience.materialLevel, this.actions()))
      .backgroundColor(Theme.background).transition(pageTransition()).onBackPressed(() => this.back())
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
