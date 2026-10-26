import { common } from '@kit.AbilityKit';
import { AppDependencies } from '../../app/AppDependencies';
import { DayRoutine } from '../../domain/model/DayRoutine';
import { Activity, ActivityTotal } from '../../domain/model/Activity';
import { ActivityRepository } from '../../domain/repository/ActivityRepository';
import { categoryTotals, dateKey, itemWeekTotals, shiftDate, validDateKey, weekDates } from '../../domain/service/ActivityRules';

@ObservedV2
export class JournalViewModel {
  @Trace selectedDate: string = dateKey();
  @Trace routines: DayRoutine[] = [];
  @Trace records: Activity[] = [];
  @Trace loading: boolean = true;
  @Trace ready: boolean = false;
  @Trace error: string = '';
  @Trace selectedTitle: string = '';
  private repository?: ActivityRepository;
  private generation: number = 0;
  private activeRoutine: DayRoutine = new DayRoutine();
  @Trace lastToday: string = dateKey();

  constructor(repository?: ActivityRepository) { this.repository = repository; }

  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.repository = this.repository ?? await AppDependencies.activityRepository(context);
      this.ready = true;
      const previous = await this.getRepository().getRoutine(shiftDate(dateKey(), -1));
      const minute = new Date().getHours() * 60 + new Date().getMinutes();
      if (this.selectedDate === dateKey() && previous.sleepMinute > 1440 && minute < previous.sleepMinute - 1440) {
        this.selectedDate = previous.localDate; this.lastToday = previous.localDate;
      }
      await this.refresh();
    } catch (_) { this.error = '读取失败'; this.loading = false; }
  }

  retry(context: common.UIAbilityContext): void {
    if (this.repository) { this.refresh(); } else { this.initialize(context); }
  }

  getRepository(): ActivityRepository {
    if (!this.repository) { throw new Error('本地数据尚未准备好'); } return this.repository;
  }

  async refresh(): Promise<void> {
    const generation = ++this.generation;
    const days = this.days(); this.loading = true; this.error = '';
    try {
      const records = await this.getRepository().list(days[0], days[6]);
      const routines = await this.getRepository().listRoutines(days[0], days[6]);
      const activeRoutine = await this.getRepository().getRoutine(this.lastToday);
      if (generation !== this.generation) { return; }
      this.records = records; this.routines = routines; this.activeRoutine = activeRoutine;
      if (!this.titles().includes(this.selectedTitle)) { this.selectedTitle = this.titles()[0] ?? ''; }
    } catch (_) {
      if (generation === this.generation) { this.records = []; this.error = '读取失败'; }
    } finally { if (generation === this.generation) { this.loading = false; } }
  }

  selectDate(value: string): void {
    if (!validDateKey(value) || value < '1970-01-01' || value > '2100-12-31') { return; }
    this.selectedDate = value;
    this.refresh();
  }
  moveDay(amount: number): void { this.selectDate(shiftDate(this.selectedDate, amount)); }
  async today(): Promise<void> {
    if (!this.ready) { return; }
    try {
      const today = dateKey(); const previous = await this.getRepository().getRoutine(shiftDate(today, -1));
      const minute = new Date().getHours() * 60 + new Date().getMinutes();
      const selected = previous.sleepMinute > 1440 && minute < previous.sleepMinute - 1440 ? previous.localDate : today;
      this.lastToday = selected; this.selectDate(selected);
    } catch (_) { this.error = '读取失败'; }
  }
  isToday(): boolean { return this.selectedDate === this.lastToday; }
  routine(day: string = this.selectedDate): DayRoutine {
    const saved = this.routines.find((value: DayRoutine) => value.localDate === day);
    if (saved) { return saved; }
    const value = new DayRoutine(); value.localDate = day; return value;
  }
  checkDayChange(today: string = dateKey(), minute: number = new Date().getHours() * 60 + new Date().getMinutes()): void {
    const active = this.activeRoutine.localDate === this.lastToday ? this.activeRoutine : this.routine(this.lastToday);
    if (today === shiftDate(this.lastToday, 1) && active.sleepMinute > 1440 && minute < active.sleepMinute - 1440) { return; }
    if (this.lastToday !== today) {
      const followingToday = this.selectedDate === this.lastToday;
      this.lastToday = today;
      if (followingToday) { this.selectDate(today); }
    }
  }
  days(): string[] { return weekDates(this.selectedDate); }
  dayRecords(day: string = this.selectedDate): Activity[] { return this.records.filter((record: Activity) => record.localDate === day)
    .sort((a: Activity, b: Activity) => b.startMinute - a.startMinute || b.endMinute - a.endMinute); }
  periodRecords(weekly: boolean): Activity[] { return weekly ? this.records : this.dayRecords(); }
  totalMinutes(weekly: boolean = false): number {
    return this.periodRecords(weekly).reduce((total: number, record: Activity) => total + record.endMinute - record.startMinute, 0);
  }
  totals(weekly: boolean): ActivityTotal[] { return categoryTotals(this.periodRecords(weekly)); }
  titles(): string[] {
    const result: string[] = [];
    this.records.forEach((record: Activity) => { if (!result.includes(record.title)) { result.push(record.title); } });
    return result;
  }
  itemTotals(): ActivityTotal[] { return itemWeekTotals(this.records, this.days(), this.selectedTitle); }
}
