import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { SCHEMA_V1, SCHEMA_VERSION } from '../migration/Schema';

export class AtlasDatabase {
  static async open(context: common.Context, name: string = 'loci.db'): Promise<relationalStore.RdbStore> {
    const store = await relationalStore.getRdbStore(context, {
      name: name,
      securityLevel: relationalStore.SecurityLevel.S3
    });
    try {
      await store.executeSql('PRAGMA foreign_keys = ON');
      if (store.version > SCHEMA_VERSION) {
        throw new Error('数据来自更高版本，请更新 Loci 后再打开');
      }
      if (store.version === 0) {
        const transaction = await store.createTransaction();
        try {
          for (const sql of SCHEMA_V1) {
            await transaction.execute(sql);
          }
          await transaction.execute(`PRAGMA user_version = ${SCHEMA_VERSION}`);
          await transaction.commit();
        } catch (error) {
          await transaction.rollback();
          throw error as Error;
        }
      }
      return store;
    } catch (error) {
      await store.close();
      throw error as Error;
    }
  }
}
