import { UIAbility } from '@kit.AbilityKit';
import { abilityDelegatorRegistry } from '@kit.TestKit';
import { Hypium } from '@ohos/hypium';
import atlasPersistenceTest from '../test/AtlasPersistence.test';

// No test window is needed; ArkData uses this ability's real Stage context.
export default class TestAbility extends UIAbility {
  onCreate(): void {
    Hypium.hypiumTest(abilityDelegatorRegistry.getAbilityDelegator(),
      abilityDelegatorRegistry.getArguments(), () => atlasPersistenceTest(this.context));
  }
}
