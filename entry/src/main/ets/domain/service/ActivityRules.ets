import { DayRoutine, JournalLine, JournalLineKind } from '../model/DayRoutine';
import { ACTIVITY_CATEGORIES, Activity, ActivityTotal, ExtractedActivity } from '../model/Activity';

export function dateKey(date: Date = new Date()): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

export function calendarDate(key: string): Date {
  const parts = key.split('-').map((part: string) => Number(part));
  return new Date(parts[0], parts[1] - 1, parts[2], 12);
}

export function validDateKey(key: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(key) && key >= '1900-01-01' && key <= '2199-12-31' && dateKey(calendarDate(key)) === key;
}

export function shiftDate(key: string, amount: number): string {
  const date = calendarDate(key); date.setDate(date.getDate() + amount); return dateKey(date);
}

export function weekDates(key: string): string[] {
  const offset = (calendarDate(key).getDay() + 6) % 7;
  const start = shiftDate(key, -offset);
  return [0, 1, 2, 3, 4, 5, 6].map((day: number) => shiftDate(start, day));
}

export function clockText(minute: number): string {
  return `${String(Math.floor(minute / 60)).padStart(2, '0')}:${String(minute % 60).padStart(2, '0')}`;
}

export function durationText(minutes: number): string {
  if (minutes === 0) { return '0分钟'; }
  const hours = Math.floor(minutes / 60); const rest = minutes % 60;
  return `${hours ? `${hours}小时` : ''}${rest ? `${rest}分钟` : ''}`;
}

export function categoryName(id: string): string {
  return ACTIVITY_CATEGORIES.find((category) => category.id === id)?.name ?? '其他';
}

export function validateActivity(value: Activity): void {
  if (!value.id || !validDateKey(value.localDate)) { throw new Error('请选择有效日期'); }
  if (!value.title.trim() || value.title.trim().length > 120) { throw new Error('事项名称需为1–120个字'); }
  if (!ACTIVITY_CATEGORIES.some((category) => category.id === value.categoryId)) { throw new Error('请选择分类'); }
  if (!Number.isInteger(value.startMinute) || !Number.isInteger(value.endMinute) ||
    value.startMinute < 0 || value.startMinute >= 2880 || value.endMinute > 2880 || value.endMinute < value.startMinute) {
    throw new Error('时间无效');
  }
  if (value.note.length > 10000) { throw new Error('备注不能超过10000个字'); }
}

export function overlaps(value: Activity, other: Activity): boolean {
  return value.id !== other.id && value.localDate === other.localDate &&
    value.startMinute < other.endMinute && value.endMinute > other.startMinute;
}

export function categoryTotals(records: Activity[]): ActivityTotal[] {
  return ACTIVITY_CATEGORIES.map((category) => new ActivityTotal(category.id, category.name,
    records.filter((record: Activity) => record.categoryId === category.id)
      .reduce((total: number, record: Activity) => total + record.endMinute - record.startMinute, 0)))
    .filter((total: ActivityTotal) => total.minutes > 0).sort((a: ActivityTotal, b: ActivityTotal) => b.minutes - a.minutes);
}

export function itemWeekTotals(records: Activity[], dates: string[], title: string): ActivityTotal[] {
  return dates.map((day: string) => new ActivityTotal(day, day.slice(5), records
    .filter((record: Activity) => record.localDate === day && record.title === title)
    .reduce((total: number, record: Activity) => total + record.endMinute - record.startMinute, 0)));
}

function guessCategory(title: string): string {
  if (/学习|阅读|读书|课程|练习|英语|复习|高数|线代|笔记|单片机|课/.test(title)) { return 'study'; }
  if (/工作|会议|开发|设计|项目|写代码|办公/.test(title)) { return 'work'; }
  if (/跑步|散步|运动|健身|游泳|骑行|瑜伽/.test(title)) { return 'exercise'; }
  if (/睡觉|睡眠|休息|午睡/.test(title)) { return 'rest'; }
  if (/通勤|地铁|公交|开车|出行|旅行/.test(title)) { return 'travel'; }
  if (/吃饭|早餐|午餐|晚餐|做饭|购物|打扫/.test(title)) { return 'life'; }
  return 'other';
}

// Local, explicit time-range extraction. Ambiguous text must be corrected by the user.
export function extractActivity(input: string): ExtractedActivity {
  const normalized = input.trim().replace(/：/g, ':');
  const match = /^(?:今天\s*)?(\d{1,2})(?::(\d{2})|点(半|\d{1,2}分?)?)?\s*(?:到|至|[-—~～])\s*(\d{1,2})(?::(\d{2})|点(半|\d{1,2}分?)?)?(?![:\d点半分])\s*(.+)$/.exec(normalized);
  if (!match) { throw new Error('请使用「09:00到10:30 阅读」或「9点到10点半 阅读」'); }
  const startHour = Number(match[1]); const endHour = Number(match[4]);
  const startRest = match[2] ? Number(match[2]) : match[3] === '半' ? 30 : Number((match[3] || '0').replace('分', ''));
  const endRest = match[5] ? Number(match[5]) : match[6] === '半' ? 30 : Number((match[6] || '0').replace('分', ''));
  if (startHour > 23 || endHour > 24 || startRest > 59 || endRest > 59 || (endHour === 24 && endRest !== 0)) {
    throw new Error('时间超出范围，请填写24小时制时间');
  }
  const result = new ExtractedActivity();
  result.startMinute = startHour * 60 + startRest; result.endMinute = endHour * 60 + endRest;
  if (result.endMinute < result.startMinute) { result.endMinute += 1440; }
  result.title = match[7].replace(/^[，,、\s]+/, '').trim(); result.categoryId = guessCategory(result.title);
  const check = new Activity(); check.id = 'extraction'; check.localDate = '2000-01-01';
  check.title = result.title; check.startMinute = result.startMinute; check.endMinute = result.endMinute;
  validateActivity(check);
  if (check.startMinute === check.endMinute) { throw new Error('起止时间相同'); }
  return result;
}


export function dayClockText(minute: number): string {
  if (minute < 0) { return '未设置'; }
  return `${minute >= 2880 ? '后日 ' : minute >= 1440 ? '次日 ' : ''}${clockText(minute % 1440)}`;
}

export function validateRoutine(value: DayRoutine): void {
  if (!validDateKey(value.localDate)) { throw new Error('日期无效'); }
  if (!Number.isInteger(value.wakeMinute) || value.wakeMinute < -1 || value.wakeMinute >= 1440 ||
    !Number.isInteger(value.sleepMinute) || value.sleepMinute < -1 || value.sleepMinute > 2880) {
    throw new Error('时间无效');
  }
  if (value.wakeMinute >= 0 && value.sleepMinute >= 0 && value.sleepMinute <= value.wakeMinute) {
    throw new Error('睡觉时间应晚于起床');
  }
}

export function parseJournalLine(input: string, wakeMinute: number = -1): JournalLine {
  const clean = input.trim().replace(/^(?:[-*•]\s+)+/, '');
  const nextDay = /^次日\s*/.test(clean);
  const text = clean.replace(/^次日\s*/, '').replace(/：/g, ':');
  const result = new JournalLine();
  const point = /^(\d{1,2})(?::(\d{2})|点(半|\d{1,2}分?)?)?(?![:\d点半分])\s*(.+)$/.exec(text);
  if (point && !/^(?:到|至|[-—~～])/.test(point[4].trim())) {
    const hour = Number(point[1]);
    const rest = point[2] ? Number(point[2]) : point[3] === '半' ? 30 : Number((point[3] || '0').replace('分', ''));
    if (hour > 23 || rest > 59) { throw new Error('时间无效'); }
    result.title = point[4].trim(); result.startMinute = hour * 60 + rest; result.endMinute = result.startMinute;
    if (/^(起床|醒来)$/.test(result.title)) { result.kind = JournalLineKind.Wake; }
    else if (/^(睡觉|睡眠|入睡)$/.test(result.title)) { result.kind = JournalLineKind.Sleep; }
    result.categoryId = guessCategory(result.title);
  } else {
    const range = extractActivity(text);
    result.title = range.title; result.categoryId = range.categoryId;
    result.startMinute = range.startMinute; result.endMinute = range.endMinute;
  }
  if (result.kind !== JournalLineKind.Wake &&
    ((nextDay && result.startMinute < 1440) || (wakeMinute >= 0 && result.startMinute < wakeMinute) ||
      (result.kind === JournalLineKind.Sleep && wakeMinute < 0 && result.startMinute < 720))) {
    result.startMinute += 1440; result.endMinute += 1440;
  }
  const check = new Activity(); check.id = 'line'; check.localDate = '2000-01-01';
  check.title = result.title; check.startMinute = result.startMinute; check.endMinute = result.endMinute;
  validateActivity(check);
  return result;
}
