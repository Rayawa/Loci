import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { util } from '@kit.ArkTS';
import getDiskStorageInstance, { DiskStorageInstance } from '../../../main/ets/common/DiskStorage';

export default function diskStorageTest(context: common.UIAbilityContext): void {
  describe('DashboardDiskStorage', () => {
    let name: string = '';
    let store: DiskStorageInstance;
    beforeEach(() => {
      name = `loci-settings-test-${util.generateRandomUUID()}`;
      const instance = getDiskStorageInstance(name, context);
      if (!instance) { throw new Error('无法创建独立设置库'); }
      store = instance;
    });
    afterEach(async () => { await store.destroy(); await preferences.deletePreferences(context, name); });

    it('persistedLevelSurvivesInstanceRecreation', 0, async () => {
      await store.set('vibrationLevel', 2);
      await store.destroy();
      const reopened = getDiskStorageInstance(name, context);
      if (!reopened) { throw new Error('无法重开独立设置库'); }
      store = reopened;
      expect(await store.get('vibrationLevel', 1)).assertEqual(2);
    });

    it('writesAndRemovalKeepMemoryAndDiskCoherent', 0, async () => {
      await store.set('lightFieldLevel', 1);
      expect(await store.get('lightFieldLevel', 0)).assertEqual(1);
      await store.set('lightFieldLevel', 2);
      expect(await store.get('lightFieldLevel', 0)).assertEqual(2);
      await store.remove('lightFieldLevel');
      expect(await store.has('lightFieldLevel')).assertFalse();
      expect(await store.get('lightFieldLevel', 1)).assertEqual(1);
    });
  });
}
