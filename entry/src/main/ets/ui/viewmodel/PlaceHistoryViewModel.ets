import { Place, Visit } from '../../domain/model/Atlas';
import { AtlasRepository } from '../../domain/repository/AtlasRepository';

@ObservedV2
export class PlaceHistoryViewModel {
  @Trace place: Place | undefined = undefined;
  @Trace visits: Visit[] = [];
  @Trace loading: boolean = true;
  @Trace error: string = '';

  async load(repository: AtlasRepository, placeId: string): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const history = await repository.getPlaceHistory(placeId);
      this.place = history.place;
      this.visits = history.visits;
    } catch (error) {
      this.error = (error as Error).message || '无法读取这个地点，请重试';
    } finally {
      this.loading = false;
    }
  }
}
