import { relationalStore } from '@kit.ArkData';
import { Place, PlaceHistory, RecordedVisit, Visit, VisitDraft } from '../../domain/model/Atlas';
import { AtlasRepository } from '../../domain/repository/AtlasRepository';
import { validateMemory, validateVisit, visitLocalDate } from '../../domain/service/VisitRules';
import { mapPlace, mapVisit } from '../entity/AtlasMapper';
import { PLACE_SUMMARY_SQL } from '../migration/Schema';

export class RdbAtlasRepository implements AtlasRepository {
  private writeQueue: Promise<void> = Promise.resolve();

  private store: relationalStore.RdbStore;
  constructor(store: relationalStore.RdbStore) { this.store = store; }

  private serialize<T>(operation: () => Promise<T>): Promise<T> {
    const result = this.writeQueue.then(operation);
    this.writeQueue = result.then(() => {}, () => {});
    return result;
  }

  async listPlaces(): Promise<Place[]> {
    await this.writeQueue;
    const rows = await this.store.querySql(`${PLACE_SUMMARY_SQL} GROUP BY p.id ORDER BY last_visited_at DESC, p.id`);
    const places: Place[] = [];
    try {
      while (rows.goToNextRow()) {
        places.push(mapPlace(rows));
      }
    } finally {
      rows.close();
    }
    return places;
  }

  async getPlaceHistory(placeId: string): Promise<PlaceHistory> {
    return this.serialize(async () => {
      const rows = await this.store.querySql(`${PLACE_SUMMARY_SQL} WHERE p.id = ? GROUP BY p.id`, [placeId]);
      let place: Place;
      try {
        if (!rows.goToFirstRow()) {
          throw new Error('这个地点已不存在');
        }
        place = mapPlace(rows);
      } finally {
        rows.close();
      }
      const visitRows = await this.store.querySql('SELECT * FROM visits WHERE place_id = ? ORDER BY visited_at DESC, id', [placeId]);
      const visits: Visit[] = [];
      try {
        while (visitRows.goToNextRow()) {
          visits.push(mapVisit(visitRows));
        }
      } finally {
        visitRows.close();
      }
      return new PlaceHistory(place, visits);
    });
  }

  async getVisit(visitId: string): Promise<Visit> {
    await this.writeQueue;
    const rows = await this.store.querySql('SELECT * FROM visits WHERE id = ?', [visitId]);
    try {
      if (!rows.goToFirstRow()) {
        throw new Error('这段记忆已不存在');
      }
      return mapVisit(rows);
    } finally {
      rows.close();
    }
  }

  recordVisit(draft: VisitDraft): Promise<RecordedVisit> {
    validateVisit(draft);
    return this.serialize(async () => {
      const transaction = await this.store.createTransaction();
      try {
        const replay = await transaction.querySql('SELECT place_id FROM visits WHERE id = ?', [draft.requestId]);
        let replayPlaceId: string = '';
        try {
          if (replay.goToFirstRow()) {
            replayPlaceId = replay.getString(0);
          }
        } finally {
          replay.close();
        }
        if (replayPlaceId) {
          await transaction.commit();
          return new RecordedVisit(replayPlaceId, draft.requestId, false);
        }
        let placeId: string = draft.existingPlaceId;
        let isNewPlace: boolean = false;
        const normalizedName = draft.name.trim().toLocaleLowerCase();
        const candidates = await transaction.querySql(placeId ? 'SELECT id FROM places WHERE id = ?' :
          'SELECT id FROM places WHERE normalized_name = ? AND latitude = ? AND longitude = ? AND coordinate_system = ?',
          placeId ? [placeId] : [normalizedName, draft.latitude, draft.longitude, draft.coordinateSystem]);
        try {
          if (candidates.goToFirstRow()) {
            placeId = candidates.getString(0);
          } else if (placeId) {
            throw new Error('原地点已不存在，请重新选择');
          } else {
            placeId = draft.newPlaceId;
            isNewPlace = true;
          }
        } finally {
          candidates.close();
        }
        const now = Date.now();
        if (isNewPlace) {
          await transaction.execute(`INSERT INTO places
            (id,name,normalized_name,latitude,longitude,coordinate_system,address,country,country_code,province,city,district,created_at,updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`,
            [placeId, draft.name.trim(), normalizedName, draft.latitude, draft.longitude, draft.coordinateSystem,
              draft.address.trim(), draft.country.trim(), draft.countryCode, draft.province, draft.city.trim(), draft.district, now, now]);
        }
        await transaction.execute(`INSERT INTO visits
          (id,place_id,visited_at,local_date,utc_offset_minutes,diary,mood,source,created_at,updated_at)
          VALUES (?,?,?,?,?,?,?,?,?,?)`,
          [draft.requestId, placeId, draft.visitedAt, visitLocalDate(draft.visitedAt, draft.utcOffsetMinutes),
            draft.utcOffsetMinutes, draft.diary, draft.mood, draft.source, now, now]);
        await transaction.execute('UPDATE places SET updated_at = ? WHERE id = ?', [now, placeId]);
        await transaction.commit();
        return new RecordedVisit(placeId, draft.requestId, isNewPlace);
      } catch (error) {
        await transaction.rollback();
        throw error as Error;
      }
    });
  }

  updateMemory(visitId: string, diary: string, mood: number): Promise<void> {
    validateMemory(diary, mood);
    return this.serialize(async () => {
      const count = await this.store.execute('UPDATE visits SET diary = ?, mood = ?, updated_at = ? WHERE id = ?',
        [diary, mood, Date.now(), visitId]);
      if (count === 0) {
        throw new Error('这段记忆已不存在');
      }
    });
  }

  deleteVisit(visitId: string): Promise<void> {
    return this.serialize(async () => {
      await this.store.execute('DELETE FROM visits WHERE id = ?', [visitId]);
    });
  }
}
