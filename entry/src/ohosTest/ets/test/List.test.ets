import { common } from '@kit.AbilityKit';
import activityPersistenceTest from './ActivityPersistence.test';
import atlasPersistenceTest from './AtlasPersistence.test';
import atlasViewModelTest from './AtlasViewModel.test';
import diskStorageTest from './DiskStorage.test';

export default function testsuite(context: common.UIAbilityContext): void {
  activityPersistenceTest(context);
  atlasPersistenceTest(context);
  atlasViewModelTest(context);
  diskStorageTest(context);
}
