import { beforeEach, afterEach, describe, expect, it } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { AtlasDatabase } from '../../../main/ets/data/database/AtlasDatabase';
import { RdbActivityRepository } from '../../../main/ets/data/repository/RdbActivityRepository';
import { RdbAtlasRepository } from '../../../main/ets/data/repository/RdbAtlasRepository';
import { SCHEMA_V1, SCHEMA_V2, SCHEMA_V3 } from '../../../main/ets/data/migration/Schema';
import { dateKey, shiftDate } from '../../../main/ets/domain/service/ActivityRules';
import { DayRoutine } from '../../../main/ets/domain/model/DayRoutine';
import { parseJournalLine } from '../../../main/ets/domain/service/ActivityRules';
import { Activity } from '../../../main/ets/domain/model/Activity';
import { VisitDraft } from '../../../main/ets/domain/model/Atlas';
import { JournalViewModel } from '../../../main/ets/ui/viewmodel/JournalViewModel';

function activity(start: number = 540, end: number = 600): Activity {
  const value = new Activity(); value.id = util.generateRandomUUID(); value.localDate = '2026-10-22';
  value.title = '阅读'; value.categoryId = 'study'; value.startMinute = start; value.endMinute = end; return value;
}

export default function activityPersistenceTest(context: common.UIAbilityContext): void {
  describe('ActivityPersistence', () => {
    let store: relationalStore.RdbStore;
    let repository: RdbActivityRepository;
    let name: string = '';
    beforeEach(async () => {
      name = `loci-activity-test-${util.generateRandomUUID()}.db`;
      store = await AtlasDatabase.open(context, name); repository = new RdbActivityRepository(store);
    });
    afterEach(async () => { await store.close(); await relationalStore.deleteRdbStore(context, name); });

    it('saveEditReopenAndDeleteKeepStableIdentity', 0, async () => {
      const record = activity(); await repository.save(record);
      const original = await repository.get(record.id);
      original.title = '阅读与笔记'; original.note = '独立记录'; original.endMinute = 630;
      await repository.save(original);
      await store.close(); store = await AtlasDatabase.open(context, name); repository = new RdbActivityRepository(store);
      const restored = await repository.get(record.id);
      expect(restored.title).assertEqual('阅读与笔记'); expect(restored.note).assertEqual('独立记录');
      expect(restored.createdAt).assertEqual(original.createdAt);
      expect((await repository.list(record.localDate,record.localDate)).length).assertEqual(1);
      await repository.delete(record.id);
      expect((await repository.list(record.localDate,record.localDate)).length).assertEqual(0);
    });
    it('concurrentNotesCanOverlapWithoutLosingEntries', 0, async () => {
      const first = activity(); const second = activity(570,630);
      await Promise.all([repository.save(first), repository.save(second)]);
      expect((await repository.list(first.localDate,first.localDate)).length).assertEqual(2);
    });
    it('batchFailureRollsBackAllRecordsAndRoutine', 0, async () => {
      const first = activity(); const second = activity(600,630); second.placeId = 'missing';
      const routine = new DayRoutine(); routine.localDate = first.localDate; routine.wakeMinute = 420;
      let rejected = false;
      try { await repository.saveBatch([first,second],routine); } catch (_) { rejected = true; }
      expect(rejected).assertTrue();
      expect((await repository.list(first.localDate,first.localDate)).length).assertEqual(0);
      expect((await repository.getRoutine(first.localDate)).wakeMinute).assertEqual(-1);
      await repository.saveBatch([first],routine);
      expect((await repository.getRoutine(first.localDate)).wakeMinute).assertEqual(420);
    });
    it('idempotentSaveAndBackdatingUpdateCorrectDay', 0, async () => {
      const record = activity(); await Promise.all([repository.save(record),repository.save(record)]);
      expect((await repository.list(record.localDate,record.localDate)).length).assertEqual(1);
      record.localDate = '2024-02-29'; await repository.save(record);
      expect((await repository.list('2026-10-22','2026-10-22')).length).assertEqual(0);
      expect((await repository.list('2024-02-29','2024-02-29')).length).assertEqual(1);
    });
    it('optionalPlaceRequiresParentAndDeletingPlaceRetainsActivity', 0, async () => {
      const record = activity(); record.placeId = 'missing'; let rejected = false;
      try { await repository.save(record); } catch (_) { rejected = true; }
      expect(rejected).assertTrue();
      const draft = new VisitDraft(); draft.requestId = util.generateRandomUUID(); draft.newPlaceId = util.generateRandomUUID(); draft.name = '图书馆';
      const place = await new RdbAtlasRepository(store).recordVisit(draft);
      record.placeId = place.placeId; await repository.save(record);
      await store.executeSql('DELETE FROM places WHERE id = ?', [place.placeId]);
      expect((await repository.get(record.id)).placeId).assertEqual('');
      expect((await repository.get(record.id)).title).assertEqual('阅读');
    });
    it('v2MigrationPreservesPlaceAndVisitAndStartsWithNoActivities', 0, async () => {
      const legacyName = `loci-v2-test-${util.generateRandomUUID()}.db`;
      let legacy = await relationalStore.getRdbStore(context,{name:legacyName,securityLevel:relationalStore.SecurityLevel.S3});
      try {
        for (const sql of SCHEMA_V1) { await legacy.executeSql(sql); }
        for (const sql of SCHEMA_V2) { await legacy.executeSql(sql); }
        await legacy.executeSql('PRAGMA user_version = 2');
        const draft = new VisitDraft(); draft.requestId = util.generateRandomUUID(); draft.newPlaceId = util.generateRandomUUID(); draft.name = '旧地点'; draft.diary = '保留记忆';
        const record = await new RdbAtlasRepository(legacy).recordVisit(draft);
        await legacy.close(); legacy = await AtlasDatabase.open(context,legacyName);
        expect((await new RdbAtlasRepository(legacy).getVisit(record.visitId)).diary).assertEqual('保留记忆');
        expect((await new RdbActivityRepository(legacy).list('2026-01-01','2026-12-31')).length).assertEqual(0);
      } finally { await legacy.close(); await relationalStore.deleteRdbStore(context,legacyName); }
    });
    it('journalDateSelectionAndStatsUsePersistedRecords', 0, async () => {
      await repository.save(activity()); const other = activity(600,630); other.title = '会议'; other.categoryId = 'work'; await repository.save(other);
      const model = new JournalViewModel(repository); await model.initialize(context); model.selectDate('2026-10-22'); await model.refresh();
      expect(model.totalMinutes()).assertEqual(90); expect(model.totals(false).length).assertEqual(2);
      expect(model.dayRecords()[0].id).assertEqual(other.id);
      expect(model.dayRecords()[1].startMinute).assertEqual(540);
      model.selectedTitle = '阅读'; expect(model.itemTotals()[3].minutes).assertEqual(60);
      model.moveDay(1); await model.refresh(); expect(model.dayRecords().length).assertEqual(0);
      expect(model.totalMinutes(true)).assertEqual(90);
    });
    it('midnightOpensNewDayAndPreservesHistoricalSelection', 0, async () => {
      const today = dateKey();
      const model = new JournalViewModel(repository); await model.initialize(context);
      model.checkDayChange(shiftDate(today,1)); await model.refresh();
      expect(model.selectedDate).assertEqual(shiftDate(today,1));
      model.selectDate('2024-02-29'); await model.refresh();
      model.checkDayChange(shiftDate(today,2)); await model.refresh();
      expect(model.selectedDate).assertEqual('2024-02-29');
    });

    it('routineAndOvernightPointsSurviveReopen', 0, async () => {
      const routine = new DayRoutine(); routine.localDate = '2026-10-22'; routine.wakeMinute = 445; routine.sleepMinute = 1620;
      const range = activity(1410,1620); const point = activity(1500,1500);
      await repository.saveBatch([range,point],routine);
      await store.close(); store = await AtlasDatabase.open(context,name); repository = new RdbActivityRepository(store);
      expect((await repository.getRoutine(routine.localDate)).sleepMinute).assertEqual(1620);
      expect((await repository.get(point.id)).endMinute).assertEqual(1500);
      const model = new JournalViewModel(repository); await model.initialize(context); model.selectDate(routine.localDate); await model.refresh();
      expect(model.totalMinutes()).assertEqual(210);
      const cleared = new DayRoutine(); cleared.localDate = routine.localDate; await repository.saveRoutine(cleared);
      expect((await repository.getRoutine(routine.localDate)).wakeMinute).assertEqual(-1);
      expect((await repository.list(routine.localDate,routine.localDate)).length).assertEqual(2);
    });
    it('v3MigrationPreservesActivityIdsAndNotes', 0, async () => {
      const legacyName = `loci-v3-test-${util.generateRandomUUID()}.db`;
      let legacy = await relationalStore.getRdbStore(context,{name:legacyName,securityLevel:relationalStore.SecurityLevel.S3});
      try {
        for (const sql of SCHEMA_V1) { await legacy.executeSql(sql); }
        for (const sql of SCHEMA_V2) { await legacy.executeSql(sql); }
        for (const sql of SCHEMA_V3) { await legacy.executeSql(sql); }
        await legacy.executeSql('PRAGMA user_version = 3');
        const record = activity(); record.note = '旧版备注';
        await new RdbActivityRepository(legacy).save(record);
        await legacy.close(); legacy = await AtlasDatabase.open(context,legacyName);
        const migrated = new RdbActivityRepository(legacy);
        expect((await migrated.get(record.id)).note).assertEqual('旧版备注');
        expect((await migrated.get(record.id)).startMinute).assertEqual(540);
        expect((await migrated.getRoutine(record.localDate)).wakeMinute).assertEqual(-1);
        await migrated.save(activity(1410,1620));
      } finally { await legacy.close(); await relationalStore.deleteRdbStore(context,legacyName); }
    });
    it('MarkdownParserRecognizesBoundaryAndRangeOnDevice', 0, async () => {
      expect(parseJournalLine('7:25起床').startMinute).assertEqual(445);
      expect(parseJournalLine('3:00睡觉',445).startMinute).assertEqual(1620);
      expect(parseJournalLine('23:30-3:00 鸿蒙开发',445).endMinute).assertEqual(1620);
    });

    it('overnightRoutineKeepsWakingDayUntilSleep', 0, async () => {
      const today = dateKey(); const routine = new DayRoutine(); routine.localDate = today;
      routine.wakeMinute = 445; routine.sleepMinute = 1620; await repository.saveRoutine(routine);
      const model = new JournalViewModel(repository); await model.initialize(context);
      model.checkDayChange(shiftDate(today,1),120); await model.refresh();
      expect(model.selectedDate).assertEqual(today);
      model.selectDate('2024-02-29'); await model.refresh();
      model.checkDayChange(shiftDate(today,1),120);
      expect(model.isToday()).assertFalse();
      expect(model.lastToday).assertEqual(today);
      model.selectDate(today); await model.refresh();
      model.checkDayChange(shiftDate(today,1),240); await model.refresh();
      expect(model.selectedDate).assertEqual(shiftDate(today,1));
    });

  });
}
