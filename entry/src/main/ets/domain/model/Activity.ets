export class ActivityCategory {
  id: string;
  name: string;
  constructor(id: string, name: string) { this.id = id; this.name = name; }
}

export const ACTIVITY_CATEGORIES: ActivityCategory[] = [
  new ActivityCategory('work', '工作'), new ActivityCategory('study', '学习'),
  new ActivityCategory('life', '生活'), new ActivityCategory('exercise', '运动'),
  new ActivityCategory('rest', '休息'), new ActivityCategory('travel', '出行'), new ActivityCategory('other', '其他')
];

export class Activity {
  id: string = '';
  localDate: string = '';
  title: string = '';
  categoryId: string = 'other';
  startMinute: number = 540;
  endMinute: number = 600;
  placeId: string = '';
  note: string = '';
  createdAt: number = 0;
  updatedAt: number = 0;
}

export class ActivityTotal {
  key: string;
  name: string;
  minutes: number;
  constructor(key: string, name: string, minutes: number = 0) {
    this.key = key; this.name = name; this.minutes = minutes;
  }
}

export class ExtractedActivity {
  title: string = '';
  categoryId: string = 'other';
  startMinute: number = 0;
  endMinute: number = 0;
}
