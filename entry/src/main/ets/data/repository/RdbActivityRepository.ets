import { relationalStore } from '@kit.ArkData';
import { DayRoutine } from '../../domain/model/DayRoutine';
import { Activity } from '../../domain/model/Activity';
import { ActivityRepository } from '../../domain/repository/ActivityRepository';
import { validateActivity, validDateKey, validateRoutine } from '../../domain/service/ActivityRules';

function mapActivity(rows: relationalStore.ResultSet): Activity {
  const value = new Activity();
  value.id = rows.getString(rows.getColumnIndex('id'));
  value.localDate = rows.getString(rows.getColumnIndex('local_date'));
  value.title = rows.getString(rows.getColumnIndex('title'));
  value.categoryId = rows.getString(rows.getColumnIndex('category_id'));
  value.startMinute = rows.getLong(rows.getColumnIndex('start_minute'));
  value.endMinute = rows.getLong(rows.getColumnIndex('end_minute'));
  const placeColumn = rows.getColumnIndex('place_id');
  value.placeId = rows.isColumnNull(placeColumn) ? '' : rows.getString(placeColumn);
  value.note = rows.getString(rows.getColumnIndex('note'));
  value.createdAt = rows.getLong(rows.getColumnIndex('created_at'));
  value.updatedAt = rows.getLong(rows.getColumnIndex('updated_at'));
  return value;
}

export class RdbActivityRepository implements ActivityRepository {
  private store: relationalStore.RdbStore;
  private writes: Promise<void> = Promise.resolve();
  constructor(store: relationalStore.RdbStore) { this.store = store; }

  private serialize(operation: () => Promise<void>): Promise<void> {
    const result = this.writes.then(operation);
    this.writes = result.then(() => {}, () => {}); return result;
  }

  async list(startDate: string, endDate: string): Promise<Activity[]> {
    if (!validDateKey(startDate) || !validDateKey(endDate)) { throw new Error('日期范围无效'); }
    await this.writes;
    const rows = await this.store.querySql('SELECT * FROM activities WHERE local_date BETWEEN ? AND ? ORDER BY local_date,start_minute,id', [startDate, endDate]);
    const values: Activity[] = [];
    try { while (rows.goToNextRow()) { values.push(mapActivity(rows)); } } finally { rows.close(); }
    return values;
  }

  async get(id: string): Promise<Activity> {
    await this.writes;
    const rows = await this.store.querySql('SELECT * FROM activities WHERE id = ?', [id]);
    try {
      if (!rows.goToFirstRow()) { throw new Error('这条记录已不存在'); }
      return mapActivity(rows);
    } finally { rows.close(); }
  }

  save(value: Activity): Promise<void> { return this.saveBatch([value]); }

  saveBatch(values: Activity[], routine?: DayRoutine): Promise<void> {
    const records: Activity[] = [];
    for (const value of values) {
      validateActivity(value);
      const record = new Activity();
      record.id = value.id; record.localDate = value.localDate; record.title = value.title.trim();
      record.categoryId = value.categoryId; record.startMinute = value.startMinute; record.endMinute = value.endMinute;
      record.placeId = value.placeId; record.note = value.note; record.createdAt = value.createdAt;
      records.push(record);
    }
    let capturedRoutine: DayRoutine | undefined = undefined;
    if (routine) {
      validateRoutine(routine); capturedRoutine = new DayRoutine();
      capturedRoutine.localDate = routine.localDate; capturedRoutine.wakeMinute = routine.wakeMinute;
      capturedRoutine.sleepMinute = routine.sleepMinute;
    }
    const snapshot = capturedRoutine;
    return this.serialize(async () => {
      const transaction = await this.store.createTransaction();
      try {
        for (const record of records) { await this.writeRecord(transaction, record); }
        if (snapshot) { await this.writeRoutine(transaction, snapshot); }
        await transaction.commit();
      } catch (error) { await transaction.rollback(); throw error as Error; }
    });
  }

  private async writeRecord(transaction: relationalStore.Transaction, record: Activity): Promise<void> {
    const now = Date.now();
    await transaction.execute(`INSERT INTO activities
      (id,local_date,title,category_id,start_minute,end_minute,place_id,note,created_at,updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET local_date=excluded.local_date,title=excluded.title,
      category_id=excluded.category_id,start_minute=excluded.start_minute,end_minute=excluded.end_minute,
      place_id=excluded.place_id,note=excluded.note,updated_at=excluded.updated_at`,
      [record.id, record.localDate, record.title, record.categoryId, record.startMinute, record.endMinute,
        record.placeId || null, record.note, record.createdAt || now, now]);
  }

  private async writeRoutine(transaction: relationalStore.Transaction, value: DayRoutine): Promise<void> {
    if (value.wakeMinute < 0 && value.sleepMinute < 0) {
      await transaction.execute('DELETE FROM day_routines WHERE local_date = ?', [value.localDate]); return;
    }
    await transaction.execute(`INSERT INTO day_routines(local_date,wake_minute,sleep_minute,updated_at) VALUES (?,?,?,?)
      ON CONFLICT(local_date) DO UPDATE SET wake_minute=excluded.wake_minute,sleep_minute=excluded.sleep_minute,updated_at=excluded.updated_at`,
      [value.localDate, value.wakeMinute < 0 ? null : value.wakeMinute, value.sleepMinute < 0 ? null : value.sleepMinute, Date.now()]);
  }

  saveRoutine(value: DayRoutine): Promise<void> { return this.saveBatch([], value); }

  async listRoutines(startDate: string, endDate: string): Promise<DayRoutine[]> {
    if (!validDateKey(startDate) || !validDateKey(endDate)) { throw new Error('日期无效'); }
    await this.writes;
    const rows = await this.store.querySql('SELECT * FROM day_routines WHERE local_date BETWEEN ? AND ? ORDER BY local_date', [startDate, endDate]);
    const values: DayRoutine[] = [];
    try {
      while (rows.goToNextRow()) {
        const value = new DayRoutine(); value.localDate = rows.getString(rows.getColumnIndex('local_date'));
        const wake = rows.getColumnIndex('wake_minute'); const sleep = rows.getColumnIndex('sleep_minute');
        value.wakeMinute = rows.isColumnNull(wake) ? -1 : rows.getLong(wake);
        value.sleepMinute = rows.isColumnNull(sleep) ? -1 : rows.getLong(sleep);
        value.updatedAt = rows.getLong(rows.getColumnIndex('updated_at')); values.push(value);
      }
    } finally { rows.close(); }
    return values;
  }

  async getRoutine(localDate: string): Promise<DayRoutine> {
    const values = await this.listRoutines(localDate, localDate);
    if (values.length > 0) { return values[0]; }
    const value = new DayRoutine(); value.localDate = localDate; return value;
  }

  delete(id: string): Promise<void> {
    return this.serialize(async () => { await this.store.execute('DELETE FROM activities WHERE id = ?', [id]); });
  }
}
