import { abilityDelegatorRegistry, TestRunner } from '@kit.TestKit';

export default class OpenHarmonyTestRunner implements TestRunner {
  onPrepare(): void {}
  async onRun(): Promise<void> {
    const delegator = abilityDelegatorRegistry.getAbilityDelegator();
    const args = abilityDelegatorRegistry.getArguments();
    try {
      // Start the native test ability so ArkData receives an actual Stage context.
      await delegator.startAbility({ bundleName: args.bundleName, moduleName: 'entry_test', abilityName: 'TestAbility' });
    } catch (error) {
      delegator.finishTest((error as Error).message || '测试能力启动失败', -1, () => {});
    }
  }
}
