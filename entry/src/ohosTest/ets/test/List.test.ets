import { common } from '@kit.AbilityKit';
import atlasPersistenceTest from './AtlasPersistence.test';
import atlasViewModelTest from './AtlasViewModel.test';
import diskStorageTest from './DiskStorage.test';

export default function testsuite(context: common.UIAbilityContext): void {
  atlasPersistenceTest(context);
  atlasViewModelTest(context);
  diskStorageTest(context);
}
