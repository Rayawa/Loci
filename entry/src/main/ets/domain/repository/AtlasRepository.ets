import { Place, PlaceHistory, RecordedVisit, Visit, VisitDraft } from '../model/Atlas';

export interface AtlasRepository {
  listPlaces(): Promise<Place[]>;
  getPlaceHistory(placeId: string): Promise<PlaceHistory>;
  getVisit(visitId: string): Promise<Visit>;
  recordVisit(draft: VisitDraft): Promise<RecordedVisit>;
  updateMemory(visitId: string, diary: string, mood: number): Promise<void>;
  deleteVisit(visitId: string): Promise<void>;
}
