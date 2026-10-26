import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { SCHEMA_V1, SCHEMA_V2, SCHEMA_V3, SCHEMA_V4, SCHEMA_VERSION } from '../migration/Schema';

export class AtlasDatabase {
  static async open(context: common.Context, name: string = 'loci.db'): Promise<relationalStore.RdbStore> {
    const store = await relationalStore.getRdbStore(context, {
      name: name,
      securityLevel: relationalStore.SecurityLevel.S3
    });
    try {
      await store.executeSql('PRAGMA foreign_keys = ON');
      if (store.version > SCHEMA_VERSION) {
        throw new Error('数据来自更高版本，请更新时迹');
      }
      if (store.version < SCHEMA_VERSION) {
        const transaction = await store.createTransaction();
        try {
          if (store.version === 0) {
            for (const sql of SCHEMA_V1) { await transaction.execute(sql); }
          }
          if (store.version < 2) {
            const invalid = await transaction.querySql(`SELECT id FROM visits v
              WHERE NOT EXISTS (SELECT 1 FROM places p WHERE p.id = v.place_id) LIMIT 1`);
            try {
              if (invalid.rowCount > 0) { throw new Error('地点与到访数据关联异常，已保留原数据库'); }
            } finally { invalid.close(); }
            for (const sql of SCHEMA_V2) { await transaction.execute(sql); }
          }
          if (store.version < 3) {
            for (const sql of SCHEMA_V3) { await transaction.execute(sql); }
          }
          if (store.version < 4) {
            for (const sql of SCHEMA_V4) { await transaction.execute(sql); }
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
