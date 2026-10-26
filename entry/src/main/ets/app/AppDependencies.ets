import { common } from '@kit.AbilityKit';
import { relationalStore } from '@kit.ArkData';
import { ActivityRepository } from '../domain/repository/ActivityRepository';
import { RdbActivityRepository } from '../data/repository/RdbActivityRepository';
import { AtlasDatabase } from '../data/database/AtlasDatabase';
import { RdbAtlasRepository } from '../data/repository/RdbAtlasRepository';
import { AtlasRepository } from '../domain/repository/AtlasRepository';

export class AppDependencies {
  private static opening?: Promise<AtlasRepository>;
  private static store?: relationalStore.RdbStore;

  static repository(context: common.UIAbilityContext): Promise<AtlasRepository> {
    if (!AppDependencies.opening) {
      AppDependencies.opening = AppDependencies.open(context);
    }
    return AppDependencies.opening;
  }

  private static activities?: ActivityRepository;
  static async activityRepository(context: common.UIAbilityContext): Promise<ActivityRepository> {
    await AppDependencies.repository(context);
    if (!AppDependencies.activities) {
      if (!AppDependencies.store) { throw new Error('本地数据尚未准备好'); }
      AppDependencies.activities = new RdbActivityRepository(AppDependencies.store);
    }
    return AppDependencies.activities;
  }

  private static async open(context: common.UIAbilityContext): Promise<AtlasRepository> {
    try {
      AppDependencies.store = await AtlasDatabase.open(context);
      return new RdbAtlasRepository(AppDependencies.store);
    } catch (error) {
      AppDependencies.opening = undefined;
      throw error as Error;
    }
  }
}
