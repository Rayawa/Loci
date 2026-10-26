import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { util } from '@kit.ArkTS';
import { ACTIVITY_CATEGORIES, Activity, ActivityCategory } from '../../domain/model/Activity';
import { DayRoutine, JournalLine, JournalLineKind } from '../../domain/model/DayRoutine';
import { Place } from '../../domain/model/Atlas';
import { calendarDate, clockText, dateKey, dayClockText, parseJournalLine } from '../../domain/service/ActivityRules';
import { pageTransition } from '../../common/motion';
import { Icons } from '../../common/icons';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { Haptics } from '../../service/haptics/Haptics';
import { StatePanel } from '../components/StatePanel';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { destinationActions, PageAction } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct ActivityEditorPage {
  @Require @Param model: JournalViewModel;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param recordId: string;
  @Require @Param stack: NavPathStack;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local input: string = '';
  @Local selectedDate: string = '';
  @Local categoryId: string = '';
  @Local placeId: string = '';
  @Local note: string = '';
  @Local more: boolean = false;
  @Local dirty: boolean = false;
  @Local saving: boolean = false;
  @Local loading: boolean = true;
  @Local error: string = '';
  @Local loadError: boolean = false;
  private activityId: string = '';
  private createdAt: number = 0;
  private ids: string[] = [];

  aboutToAppear(): void { this.load(); }
  private async load(): Promise<void> {
    this.loading = true; this.error = ''; this.loadError = false;
    this.selectedDate = this.model.selectedDate; this.activityId = this.recordId || util.generateRandomUUID();
    if (this.recordId) {
      try {
        const record = await this.model.getRepository().get(this.recordId);
        this.input = `${record.startMinute >= 1440 ? '次日 ' : ''}${clockText(record.startMinute % 1440)}${record.endMinute !== record.startMinute ? `-${clockText(record.endMinute % 1440)}` : ''} ${record.title}`;
        this.categoryId = record.categoryId; this.selectedDate = record.localDate; this.placeId = record.placeId;
        this.note = record.note; this.createdAt = record.createdAt;
      } catch (_) { this.error = '读取失败'; this.loadError = true; }
    }
    this.loading = false;
  }
  private pickDate(): void {
    this.getUIContext().showDatePickerDialog({ selected: calendarDate(this.selectedDate), start: new Date(1970, 0, 1), end: new Date(2100, 11, 31),
      onDateAccept: (date: Date) => { this.selectedDate = dateKey(date); this.dirty = true; } });
  }
  private timeValue(): JournalLine {
    try { return parseJournalLine(this.input, this.model.routine(this.selectedDate).wakeMinute); }
    catch (_) {
      const value = new JournalLine(); const now = new Date();
      value.startMinute = now.getHours() * 60 + now.getMinutes(); value.endMinute = value.startMinute + 30;
      value.title = this.input.trim(); return value;
    }
  }
  private pickTime(starting: boolean): void {
    const value = this.timeValue(); const minute = (starting ? value.startMinute : value.endMinute) % 1440;
    const selected = calendarDate(this.selectedDate); selected.setHours(Math.floor(minute / 60), minute % 60, 0, 0);
    this.getUIContext().showTimePickerDialog({ selected: selected, useMilitaryTime: true,
      onAccept: (time: TimePickerResult) => {
        const clock = (time.hour ?? 0) * 60 + (time.minute ?? 0);
        if (starting) { value.startMinute = clock + (value.startMinute >= 1440 ? 1440 : 0); }
        else { value.endMinute = clock + (value.startMinute >= 1440 ? 1440 : 0); }
        if (value.endMinute < value.startMinute) { value.endMinute += 1440; }
        this.input = `${value.startMinute >= 1440 ? '次日 ' : ''}${clockText(value.startMinute % 1440)}${value.endMinute !== value.startMinute ? `-${clockText(value.endMinute % 1440)}` : ''} ${value.title}`;
        this.dirty = true; this.error = '';
      } });
  }
  private async save(): Promise<void> {
    if (this.saving || this.loading || this.loadError) { return; }
    this.saving = true; this.error = '';
    try {
      const lines = this.input.split('\n').map((line: string) => line.trim()).filter((line: string) => line.length > 0);
      if (!lines.length) { throw new Error('请输入记录'); }
      if (lines.length > 100) { throw new Error('每次最多100条'); }
      if (this.recordId && lines.length > 1) { throw new Error('编辑时请保留一条记录'); }
      const existing = await this.model.getRepository().getRoutine(this.selectedDate);
      const routine = new DayRoutine(); routine.localDate = this.selectedDate;
      routine.wakeMinute = existing.wakeMinute; routine.sleepMinute = existing.sleepMinute;
      // Find a wake marker before resolving early-morning entries, independent of input order.
      for (const line of lines) {
        const point = parseJournalLine(line);
        if (point.kind === JournalLineKind.Wake) { routine.wakeMinute = point.startMinute; }
      }
      const records: Activity[] = []; let changedRoutine = false;
      for (let index = 0; index < lines.length; index++) {
        const value = parseJournalLine(lines[index], routine.wakeMinute);
        if (value.kind === JournalLineKind.Wake || value.kind === JournalLineKind.Sleep) {
          if (this.recordId) { throw new Error('起床和睡觉请在作息中修改'); }
          if (value.kind === JournalLineKind.Wake) { routine.wakeMinute = value.startMinute; }
          else { routine.sleepMinute = value.startMinute; }
          changedRoutine = true; continue;
        }
        if (!this.ids[index]) { this.ids[index] = index === 0 ? this.activityId : util.generateRandomUUID(); }
        const record = new Activity(); record.id = this.ids[index]; record.localDate = this.selectedDate;
        record.title = value.title; record.categoryId = this.categoryId || value.categoryId;
        record.startMinute = value.startMinute; record.endMinute = value.endMinute;
        record.placeId = this.placeId; record.note = this.note; record.createdAt = this.createdAt;
        records.push(record);
      }
      await this.model.getRepository().saveBatch(records, changedRoutine ? routine : undefined);
      this.dirty = false; this.model.selectDate(this.selectedDate); Haptics.confirm(); this.stack.pop();
    } catch (error) { this.error = (error as Error).message || '保存失败'; }
    finally { this.saving = false; }
  }
  private remove(): void {
    if (this.saving) { return; }
    this.getUIContext().showAlertDialog({ title: '删除记录？', message: '',
      primaryButton: { value: '取消', action: () => {} }, secondaryButton: { value: '删除', action: async () => {
        this.saving = true;
        try { await this.model.getRepository().delete(this.activityId); this.dirty = false; this.model.refresh(); this.stack.pop(); }
        catch (_) { this.error = '删除失败'; } finally { this.saving = false; }
      } } });
  }
  private back(): boolean {
    if (this.saving) { return true; }
    if (!this.dirty) { return false; }
    this.getUIContext().showAlertDialog({ title: '放弃修改？', message: '', primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃', action: () => { this.dirty = false; this.stack.pop(); } } }); return true;
  }
  private actions(): PageAction[] {
    const ready = !this.saving && !this.loading && !this.loadError;
    const result: PageAction[] = [{ label: '保存', icon: Icons.save, isEnabled: ready && this.input.trim().length > 0, action: () => this.save() }];
    if (this.recordId) { result.push({ label: '删除', icon: $r('sys.symbol.trash'), isEnabled: ready, action: () => this.remove() }); }
    return result;
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 18 }) {
          Blank().height(100).width('100%')
          if (this.loading) { LoadingProgress().width(28).height(28) }
          else if (this.loadError) { StatePanel({ title: this.error, action: '重试', onAction: () => this.load() }) }
          else {
            Button(this.selectedDate).fontSize(14).fontColor(Theme.muted).backgroundColor(Color.Transparent).height(40)
              .onClick(() => this.pickDate()).accessibilityText('记录日期')
            TextArea({ text: this.input, placeholder: '7:25 起床\n8:00-9:30 高数\n23:30-3:00 开发\n3:00 睡觉' })
              .height(220).fontSize(17).backgroundColor(Theme.surface).maxLength(15000)
              .onChange((value: string) => { this.input = value; this.dirty = true; this.error = ''; })
              .accessibilityText('时间和事项，可输入多行')
            Button(this.more ? '收起' : '更多').fontSize(14).fontColor(Theme.muted).backgroundColor(Color.Transparent).height(40)
              .onClick(() => { this.more = !this.more; })
            if (this.more) {
              if (!this.input.trim().includes('\n')) {
                Row({ space: 8 }) {
                  Button(`开始 ${dayClockText(this.timeValue().startMinute)}`).layoutWeight(1).height(44).fontSize(14)
                    .backgroundColor(Theme.surface).fontColor(Theme.ink).onClick(() => this.pickTime(true))
                  Button(`结束 ${dayClockText(this.timeValue().endMinute)}`).layoutWeight(1).height(44).fontSize(14)
                    .backgroundColor(Theme.surface).fontColor(Theme.ink).onClick(() => this.pickTime(false))
                }.width('100%')
              }
              Select([{ value: '自动分类' }, ...ACTIVITY_CATEGORIES.map((category: ActivityCategory): SelectOption => ({ value: category.name }))])
                .selected(ACTIVITY_CATEGORIES.findIndex((category: ActivityCategory) => category.id === this.categoryId) + 1)
                .value(ACTIVITY_CATEGORIES.find((category: ActivityCategory) => category.id === this.categoryId)?.name ?? '自动分类')
                .onSelect((index: number) => { this.categoryId = index > 0 ? ACTIVITY_CATEGORIES[index - 1].id : ''; this.dirty = true; })
                .width('100%').accessibilityText('分类')
              Select([{ value: '无地点' }, ...this.atlas.places.map((place: Place): SelectOption => ({ value: place.name }))])
                .selected(Math.max(0, this.atlas.places.findIndex((place: Place) => place.id === this.placeId) + 1))
                .value(this.atlas.places.find((place: Place) => place.id === this.placeId)?.name ?? '无地点')
                .onSelect((index: number) => { this.placeId = index > 0 ? this.atlas.places[index - 1].id : ''; this.dirty = true; })
                .width('100%').accessibilityText('地点')
              TextArea({ text: this.note, placeholder: '备注' }).height(100).maxLength(10000)
                .onChange((value: string) => { this.note = value; this.dirty = true; }).accessibilityText('备注')
            }
            if (this.error) { Text(this.error).fontSize(14).fontColor(Theme.ink).width('100%') }
          }
          Blank().height(40).width('100%')
        }.width('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding }).enabled(!this.saving)
      }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
    }.titleMode(HdsNavDestinationTitleMode.MINI)
      .titleBar(destinationActions(this.recordId ? '编辑' : '新增', this.experience.materialLevel, this.actions()))
      .transition(pageTransition()).backgroundColor(Theme.background).onBackPressed(() => this.back())
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
