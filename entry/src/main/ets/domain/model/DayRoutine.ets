export class DayRoutine {
  localDate: string = '';
  wakeMinute: number = -1;
  sleepMinute: number = -1;
  updatedAt: number = 0;
}

export enum JournalLineKind { Activity = 'activity', Wake = 'wake', Sleep = 'sleep' }
export class JournalLine {
  kind: JournalLineKind = JournalLineKind.Activity;
  title: string = '';
  categoryId: string = 'other';
  startMinute: number = 0;
  endMinute: number = 0;
}
