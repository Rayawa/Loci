import { DayRoutine } from '../model/DayRoutine';
import { Activity } from '../model/Activity';

export interface ActivityRepository {
  list(startDate: string, endDate: string): Promise<Activity[]>;
  get(id: string): Promise<Activity>;
  save(value: Activity): Promise<void>;
  delete(id: string): Promise<void>;
  getRoutine(localDate: string): Promise<DayRoutine>;
  listRoutines(startDate: string, endDate: string): Promise<DayRoutine[]>;
  saveRoutine(value: DayRoutine): Promise<void>;
  saveBatch(values: Activity[], routine?: DayRoutine): Promise<void>;
}
