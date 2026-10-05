import { beforeEach, afterEach, describe, expect, it } from '@ohos/hypium';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { AtlasDatabase } from '../../../main/ets/data/database/AtlasDatabase';
import { RdbAtlasRepository } from '../../../main/ets/data/repository/RdbAtlasRepository';
import { CoordinateSystem, VisitDraft, VisitSource } from '../../../main/ets/domain/model/Atlas';

function draft(name: string = '北海公园'): VisitDraft {
  const value = new VisitDraft();
  value.requestId = util.generateRandomUUID();
  value.newPlaceId = util.generateRandomUUID();
  value.name = name;
  value.latitude = 39.932;
  value.longitude = 116.389;
  value.coordinateSystem = CoordinateSystem.GCJ02;
  value.city = '北京';
  value.diary = '第一次到访';
  return value;
}

export default function atlasPersistenceTest(): void {
  describe('AtlasPersistence', () => {
    let store: relationalStore.RdbStore;
    let repository: RdbAtlasRepository;
    let databaseName: string = '';
    const context = abilityDelegatorRegistry.getAbilityDelegator().getAppContext();

    beforeEach(async () => {
      databaseName = `loci-test-${util.generateRandomUUID()}.db`;
      store = await AtlasDatabase.open(context, databaseName);
      repository = new RdbAtlasRepository(store);
    });

    afterEach(async () => {
      await store.close();
      await relationalStore.deleteRdbStore(context, databaseName);
    });

    it('writerRejectsOrphanVisit', 0, async () => {
      const transaction = await store.createTransaction();
      let rejected = false;
      try {
        await transaction.execute(`INSERT INTO visits
          (id,place_id,visited_at,local_date,utc_offset_minutes,diary,mood,source,created_at,updated_at)
          VALUES ('orphan','missing',0,'1970-01-01',0,'',0,'map_selection',0,0)`);
      } catch (_) {
        rejected = true;
      } finally {
        await transaction.rollback();
      }
      expect(rejected).assertTrue();
    });

    it('newPlaceAndExplicitRevisitKeepOneIdentity', 0, async () => {
      const first = await repository.recordVisit(draft());
      const repeat = draft();
      repeat.existingPlaceId = first.placeId;
      repeat.diary = '多年以后，再次来到这里';
      repeat.source = VisitSource.ExistingPlace;
      const second = await repository.recordVisit(repeat);
      expect(first.isNewPlace).assertTrue();
      expect(second.isNewPlace).assertFalse();
      expect(second.placeId).assertEqual(first.placeId);
      expect((await repository.listPlaces()).length).assertEqual(1);
      const history = await repository.getPlaceHistory(first.placeId);
      expect(history.visits.length).assertEqual(2);
      expect(history.place.visitCount).assertEqual(2);
      expect((await repository.getVisit(first.visitId)).diary).assertEqual('第一次到访');
      expect((await repository.getVisit(second.visitId)).diary).assertEqual(repeat.diary);
    });

    it('doubleSubmitIsIdempotentAndQueueRecovers', 0, async () => {
      const value = draft();
      const results = await Promise.all([repository.recordVisit(value), repository.recordVisit(value)]);
      expect(results[0].placeId).assertEqual(results[1].placeId);
      expect((await repository.getPlaceHistory(results[0].placeId)).visits.length).assertEqual(1);
      expect((await repository.listPlaces()).length).assertEqual(1);
    });

    it('exactIdentityReusesPlaceButAdjacentPlacesStaySeparate', 0, async () => {
      const first = await repository.recordVisit(draft());
      const same = await repository.recordVisit(draft());
      expect(same.placeId).assertEqual(first.placeId);
      const neighbor = draft();
      neighbor.latitude += 0.0001;
      const second = await repository.recordVisit(neighbor);
      expect(second.isNewPlace).assertTrue();
      expect((await repository.listPlaces()).length).assertEqual(2);
    });

    it('backdatingAndDeletionRecomputeHistoryAndYears', 0, async () => {
      const recent = draft();
      recent.visitedAt = new Date('2026-10-02T12:00:00+08:00').getTime();
      recent.utcOffsetMinutes = 480;
      const first = await repository.recordVisit(recent);
      const old = draft();
      old.existingPlaceId = first.placeId;
      old.visitedAt = new Date('2024-04-03T12:00:00+08:00').getTime();
      old.utcOffsetMinutes = 480;
      const older = await repository.recordVisit(old);
      let history = await repository.getPlaceHistory(first.placeId);
      expect(history.place.firstVisitedAt).assertEqual(old.visitedAt);
      expect(history.place.lastVisitedAt).assertEqual(recent.visitedAt);
      expect(history.visits[0].id).assertEqual(first.visitId);
      expect(history.place.visitedYears.includes('2024')).assertTrue();
      expect(history.place.visitedYears.includes('2026')).assertTrue();
      await repository.deleteVisit(older.visitId);
      history = await repository.getPlaceHistory(first.placeId);
      expect(history.place.visitCount).assertEqual(1);
      expect(history.place.firstVisitedAt).assertEqual(recent.visitedAt);
      expect(history.place.visitedYears.includes('2024')).assertFalse();
    });

    it('failedVisitInsertRollsBackPlaceAndAllowsNextWrite', 0, async () => {
      const invalid = draft('回滚地点');
      invalid.source = 'invalid' as VisitSource;
      let failed = false;
      try {
        await repository.recordVisit(invalid);
      } catch (_) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect((await repository.listPlaces()).length).assertEqual(0);
      await repository.recordVisit(draft());
      expect((await repository.listPlaces()).length).assertEqual(1);
    });

    it('memoryEditsStayIndependent', 0, async () => {
      const first = await repository.recordVisit(draft());
      const repeat = draft();
      repeat.existingPlaceId = first.placeId;
      const second = await repository.recordVisit(repeat);
      await repository.updateMemory(second.visitId, '第二次到访的日记', 4);
      const firstMemory = await repository.getVisit(first.visitId);
      const secondMemory = await repository.getVisit(second.visitId);
      expect(firstMemory.diary).assertEqual('第一次到访');
      expect(firstMemory.mood).assertEqual(0);
      expect(secondMemory.diary).assertEqual('第二次到访的日记');
      expect(secondMemory.mood).assertEqual(4);
    });

    it('closeAndReopenRestoreStableIdsAndMemory', 0, async () => {
      const first = await repository.recordVisit(draft());
      await repository.updateMemory(first.visitId, '重新打开时仍然存在', 3);
      await store.close();
      store = await AtlasDatabase.open(context, databaseName);
      repository = new RdbAtlasRepository(store);
      const history = await repository.getPlaceHistory(first.placeId);
      expect(store.version).assertEqual(1);
      expect(history.place.id).assertEqual(first.placeId);
      expect(history.visits[0].id).assertEqual(first.visitId);
      expect(history.visits[0].diary).assertEqual('重新打开时仍然存在');
      expect(history.visits[0].mood).assertEqual(3);
    });
  });
}
