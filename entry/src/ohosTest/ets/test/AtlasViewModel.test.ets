import { beforeEach, afterEach, describe, expect, it } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { relationalStore } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import { mapCommon } from '@kit.MapKit';
import { AtlasDatabase } from '../../../main/ets/data/database/AtlasDatabase';
import { RdbAtlasRepository } from '../../../main/ets/data/repository/RdbAtlasRepository';
import { AtlasRepository } from '../../../main/ets/domain/repository/AtlasRepository';
import { CoordinateSystem, Place, PlaceHistory, RecordedVisit, Visit, VisitDraft } from '../../../main/ets/domain/model/Atlas';
import { VisitLocationSource } from '../../../main/ets/service/location/LocationService';
import { AtlasViewModel } from '../../../main/ets/ui/viewmodel/AtlasViewModel';

class ControlledLocation implements VisitLocationSource {
  selectCalls: number = 0;
  locateFailureCode: number = 3301200;
  private complete?: (value: VisitDraft) => void;
  locate(includeAddress?: boolean): Promise<VisitDraft> {
    const error: BusinessError = new Error('Native service diagnostic') as BusinessError;
    error.code = this.locateFailureCode;
    return Promise.reject(error);
  }
  select(position: mapCommon.LatLng): Promise<VisitDraft> {
    this.selectCalls++;
    return new Promise<VisitDraft>((resolve) => { this.complete = resolve; });
  }
  finish(): void {
    const value = new VisitDraft();
    value.name = '验收地点'; value.city = '北京';
    value.latitude = 39.932; value.longitude = 116.389;
    value.coordinateSystem = CoordinateSystem.GCJ02;
    value.diary = '补记的一段记忆';
    value.visitedAt = Date.UTC(2024, 6, 1, 12);
    value.utcOffsetMinutes = 480;
    this.complete?.(value);
    this.complete = undefined;
  }
}

class ReadFailureRepository implements AtlasRepository {
  failNextRead: boolean = false;
  private inner: AtlasRepository;
  constructor(inner: AtlasRepository) { this.inner = inner; }
  listPlaces(): Promise<Place[]> {
    if (this.failNextRead) { this.failNextRead = false; return Promise.reject(new Error('读取暂时失败')); }
    return this.inner.listPlaces();
  }
  getPlaceHistory(id: string): Promise<PlaceHistory> { return this.inner.getPlaceHistory(id); }
  getVisit(id: string): Promise<Visit> { return this.inner.getVisit(id); }
  recordVisit(draft: VisitDraft): Promise<RecordedVisit> { return this.inner.recordVisit(draft); }
  updateMemory(id: string, diary: string, mood: number): Promise<void> { return this.inner.updateMemory(id, diary, mood); }
  deleteVisit(id: string): Promise<void> { return this.inner.deleteVisit(id); }
}

export default function atlasViewModelTest(context: common.UIAbilityContext): void {
  describe('AtlasViewModel', () => {
    let store: relationalStore.RdbStore;
    let name: string = '';
    let location: ControlledLocation;
    let repository: ReadFailureRepository;
    let model: AtlasViewModel;

    beforeEach(async () => {
      name = `loci-viewmodel-test-${util.generateRandomUUID()}.db`;
      store = await AtlasDatabase.open(context, name);
      repository = new ReadFailureRepository(new RdbAtlasRepository(store));
      location = new ControlledLocation();
      model = new AtlasViewModel(repository, location);
      await model.initialize(context);
    });
    afterEach(async () => { await store.close(); await relationalStore.deleteRdbStore(context, name); });

    it('concurrentMapSelectionsKeepOneDraft', 0, async () => {
      const first = model.selectMap({ latitude: 39.932, longitude: 116.389 });
      const second = model.selectMap({ latitude: 40, longitude: 117 });
      expect(location.selectCalls).assertEqual(1);
      location.finish();
      await Promise.all([first, second]);
      const id = model.draft?.requestId;
      expect(model.showAdd).assertTrue();
      await model.selectMap({ latitude: 40, longitude: 117 });
      expect(model.draft?.requestId).assertEqual(id);
      expect(location.selectCalls).assertEqual(1);
    });

    it('savedBackdatedPlaceIsVisibleDespiteBrowseFilters', 0, async () => {
      model.city = '上海'; model.year = '2000';
      const selection = model.selectMap({ latitude: 39.932, longitude: 116.389 });
      location.finish(); await selection;
      if (!model.draft) { throw new Error('未生成草稿'); }
      const saved = await model.save(model.draft);
      expect(model.showAdd).assertFalse();
      expect(model.selectedPlace()?.id).assertEqual(saved.placeId);
      expect(model.focus?.id).assertEqual(saved.placeId);
      expect(model.filteredPlaces().length).assertEqual(1);
      expect((await repository.getVisit(saved.visitId)).localDate).assertEqual('2024-07-01');
    });

    it('committedMemorySurvivesReadFailureAndRetryRevealsPlace', 0, async () => {
      model.city = '上海';
      const selection = model.selectMap({ latitude: 39.932, longitude: 116.389 });
      location.finish(); await selection;
      if (!model.draft) { throw new Error('未生成草稿'); }
      repository.failNextRead = true;
      const saved = await model.save(model.draft);
      expect(model.showAdd).assertFalse();
      expect((await repository.getVisit(saved.visitId)).diary).assertEqual('补记的一段记忆');
      expect(model.error.length > 0).assertTrue();
      expect(model.placesError.length > 0).assertTrue();
      await model.retryPlaces();
      expect(model.error).assertEqual('');
      expect(model.placesError).assertEqual('');
      expect(model.selectedPlace()?.id).assertEqual(saved.placeId);
      expect(model.focus?.id).assertEqual(saved.placeId);
      expect(model.places[0].visitCount).assertEqual(1);
    });

    it('locationFailuresKeepDataReadyAndDoNotOfferPlaceRefresh', 0, async () => {
      location.locateFailureCode = 1002600013;
      await model.recordHere();
      expect(model.error.includes('地图尚未准备好')).assertTrue();
      expect(model.error.includes('Native service diagnostic')).assertFalse();
      expect(model.placesError).assertEqual('');
      expect(model.ready).assertTrue();
      expect(model.locating).assertFalse();
      expect(model.showAdd).assertFalse();
      expect(model.draft).assertUndefined();
      location.locateFailureCode = 3301200;
      await model.locateOnMap();
      expect(model.error.includes('暂时无法获取当前位置')).assertTrue();
      expect(model.placesError).assertEqual('');
      expect(model.focus).assertUndefined();
    });

    it('locationFailurePreservesAnIndependentPlaceReadRetry', 0, async () => {
      repository.failNextRead = true;
      await model.retryPlaces();
      const readError = model.placesError;
      expect(readError.length > 0).assertTrue();
      await model.recordHere();
      expect(model.placesError).assertEqual(readError);
      expect(model.error === readError).assertFalse();
      await model.retryPlaces();
      expect(model.placesError).assertEqual('');
      expect(model.error).assertEqual('');
      expect(model.ready).assertTrue();
    });

    it('onlyFirstPlaceRequestsAnUnlockAndRestoringDoesNotReplayIt', 0, async () => {
      const selection = model.selectMap({ latitude: 39.932, longitude: 116.389 });
      location.finish(); await selection;
      if (!model.draft) { throw new Error('未生成草稿'); }
      const first = await model.save(model.draft);
      expect(model.unlockPlaceId).assertEqual(first.placeId);
      expect(model.recentVisit?.visitId).assertEqual(first.visitId);
      model.markPlaceRevealed('another-place');
      expect(model.unlockPlaceId).assertEqual(first.placeId);
      model.markPlaceRevealed(first.placeId);
      expect(model.unlockPlaceId).assertEqual('');

      const restored = new AtlasViewModel(repository, location);
      await restored.initialize(context);
      expect(restored.unlockPlaceId).assertEqual('');
      expect(restored.recentVisit).assertUndefined();
      model.revisit(model.places[0]);
      if (!model.draft) { throw new Error('未生成重访草稿'); }
      model.draft.diary = '第二次到访的记忆';
      const second = await model.save(model.draft);
      expect(second.isNewPlace).assertFalse();
      expect(second.placeId).assertEqual(first.placeId);
      expect(second.visitId === first.visitId).assertFalse();
      expect(model.unlockPlaceId).assertEqual('');
      expect(model.recentVisit?.isNewPlace).assertFalse();
      expect(model.places[0].visitCount).assertEqual(2);
    });
  });
}
