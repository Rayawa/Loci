import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { mapCommon } from '@kit.MapKit';
import { AppDependencies } from '../../app/AppDependencies';
import { Place, RecordedVisit, VisitDraft, VisitSource } from '../../domain/model/Atlas';
import { AtlasRepository } from '../../domain/repository/AtlasRepository';
import { distanceMeters } from '../../domain/service/VisitRules';
import { Haptics } from '../../service/haptics/Haptics';
import { LocationService } from '../../service/location/LocationService';

@ObservedV2
export class AtlasViewModel {
  @Trace places: Place[] = [];
  @Trace loading: boolean = true;
  @Trace ready: boolean = false;
  @Trace error: string = '';
  @Trace locating: boolean = false;
  @Trace selectedPlaceId: string = '';
  @Trace city: string = '';
  @Trace year: string = '';
  @Trace focus: Place | undefined = undefined;
  @Trace draft: VisitDraft | undefined = undefined;
  @Trace showAdd: boolean = false;
  @Trace notice: string = '';
  private repository?: AtlasRepository;
  private location?: LocationService;

  async initialize(context: common.UIAbilityContext): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.repository = await AppDependencies.repository(context);
      this.location = new LocationService(context);
      await this.refresh();
      this.ready = true;
    } catch (error) {
      this.error = (error as Error).message || '无法打开本地足迹，请重试';
    } finally {
      this.loading = false;
    }
  }

  getRepository(): AtlasRepository {
    if (!this.repository) {
      throw new Error('本地数据尚未准备好');
    }
    return this.repository;
  }

  async refresh(): Promise<void> {
    const places = await this.getRepository().listPlaces();
    this.places = places;
  }

  async retryPlaces(): Promise<void> {
    if (this.loading || !this.ready) { return; }
    this.loading = true;
    try {
      await this.refresh();
      this.error = '';
    } catch (_) {
      this.error = '暂时无法更新地点，请稍后重试';
    } finally {
      this.loading = false;
    }
  }

  clearFilters(): void {
    this.city = '';
    this.year = '';
  }

  filteredPlaces(): Place[] {
    return this.places.filter((place: Place) => (!this.city || place.city === this.city) &&
      (!this.year || place.visitedYears.includes(this.year)));
  }

  selectedPlace(): Place | undefined {
    return this.filteredPlaces().find((place: Place) => place.id === this.selectedPlaceId);
  }

  nearby(draft: VisitDraft): Place[] {
    return this.places.filter((place: Place) => distanceMeters(place, draft) <= 150);
  }

  private begin(draft: VisitDraft): void {
    draft.requestId = util.generateRandomUUID();
    draft.newPlaceId = util.generateRandomUUID();
    this.draft = draft;
    this.showAdd = true;
    this.error = '';
  }

  async recordHere(): Promise<void> {
    if (this.locating || !this.location) {
      return;
    }
    this.locating = true;
    this.error = '';
    try {
      this.begin(await this.location.locate());
    } catch (error) {
      this.error = (error as Error).message || '定位失败，你可以长按地图补记';
    } finally {
      this.locating = false;
    }
  }

  async locateOnMap(): Promise<void> {
    if (this.locating || !this.location) {
      return;
    }
    this.locating = true;
    this.error = '';
    try {
      const coordinate = await this.location.locate(false);
      const focus = new Place();
      focus.latitude = coordinate.latitude;
      focus.longitude = coordinate.longitude;
      focus.coordinateSystem = coordinate.coordinateSystem;
      this.focus = focus;
    } catch (error) {
      this.error = (error as Error).message || '暂时无法定位，请稍后重试';
    } finally {
      this.locating = false;
    }
  }

  async selectMap(position: mapCommon.LatLng): Promise<void> {
    if (!this.location || this.showAdd || this.locating) {
      return;
    }
    try {
      this.begin(await this.location.select(position));
    } catch (error) {
      this.error = (error as Error).message || '选点失败，请重试';
    }
  }

  revisit(place: Place): void {
    const draft = new VisitDraft();
    draft.existingPlaceId = place.id;
    draft.name = place.name;
    draft.latitude = place.latitude;
    draft.longitude = place.longitude;
    draft.coordinateSystem = place.coordinateSystem;
    draft.source = VisitSource.ExistingPlace;
    this.begin(draft);
  }

  async save(draft: VisitDraft): Promise<RecordedVisit> {
    const result = await this.getRepository().recordVisit(draft);
    this.showAdd = false;
    this.selectedPlaceId = result.placeId;
    this.notice = result.isNewPlace ? '一个地点，一段新的记忆' : '再次来到这里，留下新的记忆';
    // A refresh failure is a read failure after a successful commit, never a failed write.
    try {
      await this.refresh();
      this.focus = this.selectedPlace();
    } catch (_) {
      this.error = '记忆已保存，地点列表暂未更新，请刷新';
    }
    Haptics.confirm();
    return result;
  }
}
