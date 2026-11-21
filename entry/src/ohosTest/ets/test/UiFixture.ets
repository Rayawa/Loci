import { common } from '@kit.AbilityKit';
import { initializeSettings, getUsername, setUsername } from '../../../main/ets/common/storage';
import { util } from '@kit.ArkTS';
import { AtlasDatabase } from '../../../main/ets/data/database/AtlasDatabase';
import { RdbAtlasRepository } from '../../../main/ets/data/repository/RdbAtlasRepository';
import { VisitDraft } from '../../../main/ets/domain/model/Atlas';

/** Seed the page database before reloading its models; remove only this run's unique rows. */
export class UiFixture {
  static title: string = '';
  static placeId: string = '';
  private static originalUsername: string | undefined = undefined;
  private static context: common.Context | undefined = undefined;

  static async create(context: common.Context): Promise<void> {
    UiFixture.context = context;
    initializeSettings(context); UiFixture.originalUsername = await getUsername();
    UiFixture.title = 'Loci_UI_' + Date.now();
    UiFixture.placeId = util.generateRandomUUID();
    const store = await AtlasDatabase.open(UiFixture.context);
    try {
      const draft = new VisitDraft(); draft.requestId = util.generateRandomUUID(); draft.newPlaceId = UiFixture.placeId;
      draft.name = UiFixture.title; draft.latitude = 31.2; draft.longitude = 121.5;
      draft.city = 'UI验证'; draft.diary = 'UI fixture';
      await new RdbAtlasRepository(store).recordVisit(draft);
    } finally { await store.close(); }
  }

  static async cleanup(): Promise<void> {
    if (!UiFixture.context || !UiFixture.placeId) { return; }
    const store = await AtlasDatabase.open(UiFixture.context);
    try {
      await store.executeSql('DELETE FROM activities WHERE title IN (?,?)', [UiFixture.title, UiFixture.title + '_edited']);
      await store.executeSql('DELETE FROM visits WHERE place_id = ?', [UiFixture.placeId]);
      await store.executeSql('DELETE FROM places WHERE id = ?', [UiFixture.placeId]);
    } finally { await store.close(); }
    if (UiFixture.originalUsername !== undefined) { await setUsername(UiFixture.originalUsername); UiFixture.originalUsername = undefined; }
    UiFixture.context = undefined;
  }
}
