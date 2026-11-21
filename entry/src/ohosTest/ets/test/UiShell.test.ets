import { fileIo } from '@kit.CoreFileKit';
import { UiFixture } from './UiFixture';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { Driver, ON, On, Component, MatchPattern, abilityDelegatorRegistry } from '@kit.TestKit';
import { window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { describe, beforeAll, beforeEach, afterAll, afterEach, it, expect } from '@ohos/hypium';

export default function uiShellTest(): void {
  describe('LociShell', () => {
    let driver: Driver;
    let appWindow: window.Window;
    let keepScreenOn: boolean = false;
    let caseNumber = 0;
    let stage: string = '';
    const runId: string = String(Date.now());
    let fixtureTitle: string = '';
    const bundle = 'top.rayawa.loci';
    const settle = async (): Promise<void> => { await driver.delayMs(750); await driver.waitForIdle(150, 5000); };
    const focusApp = async (): Promise<void> => {
      // startAbility can resolve before the native window is registered, especially after a Sheet closes.
      for (let attempt = 0; attempt < 30; attempt++) {
        const target = await driver.findWindow({ bundleName: bundle });
        if (target) { await target.focus(); return; }
        await driver.delayMs(500);
      }
      throw new Error('Application window did not become ready');
    };
    const recordFailure = async (): Promise<void> => {
        await driver.screenCap('/data/storage/el2/base/cache/loci-failure-' + runId + '-' + caseNumber + '.png');
        if (deviceInfo.sdkApiVersion >= 26) { await driver.dumpLayout('/data/storage/el2/base/cache/loci-failure-' + runId + '-' + caseNumber + '.json'); }
        else if (appWindow) {
          const file = fileIo.openSync('/data/storage/el2/base/cache/loci-inspector-' + runId + '-' + caseNumber + '.json', fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
          try { fileIo.writeSync(file.fd, appWindow.getUIContext().getFilteredInspectorTree()); } finally { fileIo.closeSync(file); }
        }
    };
    const find = async (on: On): Promise<Component> => {
      const node = await driver.findComponent(on.inWindow(bundle));
      if (!node) { await recordFailure(); throw new Error('Missing UI element in case ' + caseNumber + ' at ' + stage); }
      return node;
    };
    const tap = async (text: string): Promise<void> => { await (await find(ON.text(text))).click(); await settle(); };
    const id = async (value: string): Promise<void> => {
      const node = await find(ON.id(value)); await node.click(); await settle();
    };
    const scrollTo = async (scroll: Component, target: On): Promise<void> => {
      const viewport = await scroll.getBounds();
      let top = viewport.top; let bottom = viewport.bottom;
      for (const bar of await driver.findComponents(ON.type('TabBar').inWindow(bundle)) || []) {
        const bounds = await bar.getBounds();
        if (bounds.bottom > bounds.top && bounds.top > (viewport.top + viewport.bottom) / 2) { bottom = Math.min(bottom, bounds.top); }
      }
      for (const title of await driver.findComponents(ON.id('HdsTitleBar').inWindow(bundle)) || []) {
        const bounds = await title.getBounds();
        if (bounds.bottom > bounds.top && bounds.bottom < (viewport.top + viewport.bottom) / 2) { top = Math.max(top, bounds.bottom); }
      }
      const inset = Math.max(80, viewport.bottom - bottom + 24, top - viewport.top + 24);
      for (let attempt = 0; attempt < 8; attempt++) {
        const present = await driver.findComponent(target);
        if (present) {
          const bounds = await present.getBounds();
          if (bounds.top >= top + 24 && bounds.bottom <= bottom - 24 && bounds.bottom > bounds.top) { return; }
          // scrollSearch may stop as soon as a clipped label becomes visible under an overlapping bar.
          // Move it fully into the unobscured viewport before the caller is allowed to click it.
          const x = Math.round((viewport.left + viewport.right) / 2);
          const height = bottom - top;
          const towardBottom = bounds.bottom > bottom - 24;
          const from = towardBottom ? bottom - 64 : top + 64;
          const to = towardBottom ? top + height * 0.4 : bottom - height * 0.4;
          await driver.swipe(x, Math.round(from), x, Math.round(to), 800);
        } else {
          await scroll.scrollSearch(target, true, Math.round(inset));
        }
        await settle();
      }
      await recordFailure(); throw new Error('Target did not become fully visible at ' + stage);
    };
    const back = async (): Promise<void> => { await driver.pressBack(); await settle(); };
    const root = async (): Promise<void> => {
      for (let attempt = 0; attempt < 8; attempt++) {
        const discard = await driver.findComponent(ON.text('放弃').inWindow(bundle));
        if (discard) { await discard.click(); await settle(); continue; }
        const sheet = await driver.findComponent(ON.type('SheetPage').inWindow(bundle));
        const destination = await driver.findComponent(ON.type('BackButton').inWindow(bundle));
        if (!sheet && !destination) { return; }
        await back();
      }
      throw new Error('Cannot restore root');
    };
    const tab = async (text: string): Promise<void> => {
      const nodes = await driver.findComponents(ON.text(text).inWindow(bundle));
      if (!nodes?.length) { throw new Error('Missing root tab: ' + text); }
      // Native bottom tab labels are lower than the title and inner tabs.
      let target = nodes[0]; let bottom = -1;
      for (const node of nodes) { const rect = await node.getBounds(); if (rect.top > bottom) { target = node; bottom = rect.top; } }
      await target.click(); await settle();
    };
    beforeAll(async () => {
      driver = Driver.create();
      const delegator = abilityDelegatorRegistry.getAbilityDelegator();
      await focusApp();
      await settle();
      const ability = await delegator.getCurrentTopAbility();
      appWindow = await window.getLastWindow(ability.context);
      keepScreenOn = appWindow.getWindowProperties().isKeepScreenOn;
      await appWindow.setWindowKeepScreenOn(true);
      const owner = appWindow.getUIContext().getHostContext();
      if (!owner) { throw new Error('Missing application window context'); }
      await UiFixture.create(owner); fixtureTitle = UiFixture.title;
      await appWindow.loadContent('pages/Index'); await settle();

    });
    beforeEach(async () => {
      caseNumber++; stage = '';
      await abilityDelegatorRegistry.getAbilityDelegator().startAbility({ bundleName: bundle, abilityName: 'EntryAbility' });
      await focusApp(); await settle();
      await root(); await tab('记录'); await tap('列表');
    });
    afterEach(async () => {
      const path = '/data/storage/el2/base/cache/loci-ui-' + runId + '-' + caseNumber;
      if (deviceInfo.sdkApiVersion >= 26) { await driver.dumpLayout(path + '.json'); }
      await driver.screenCap(path + '.png');
    });
    afterAll(async () => {
      try { if (driver) { await root(); } } finally {
        await UiFixture.cleanup();
        if (appWindow) { await appWindow.setWindowKeepScreenOn(keepScreenOn); }
      }
    });

    it('rootTabsAndSegmentsPreserveSelection', 0, async () => {
      await tap('周视图'); expect(await driver.findComponent(ON.text('列表').inWindow(bundle)) !== null).assertTrue();
      await tab('统计'); await tap('本周'); await tab('我的'); await tab('记录');
      expect(await driver.findComponent(ON.id('weekTimeline').inWindow(bundle)) !== null).assertTrue();
      await tap('列表');
    });
    it('sheetDirtyBackCancelDiscardAndRepeatedOpen', 0, async () => {
      await id('title-新增');
      const input = await find(ON.id('activityInput')); await input.inputText('8:00-9:00 Loci_UI_unsaved');
      // Keyboard back must keep the form; a second back requests dismissal.
      await back();
      if (!await driver.findComponent(ON.text('放弃').inWindow(bundle))) { await back(); }
      await tap('继续编辑'); expect(await (await find(ON.id('activityInput'))).getText()).assertContain('Loci_UI_unsaved');
      await back(); await tap('放弃');
      for (let attempt = 0; attempt < 6; attempt++) {
        await id('title-新增'); expect(await driver.findComponent(ON.id('activityInput').inWindow(bundle)) !== null).assertTrue();
        await back();
      }
    });
    it('sheetCloseButtonAndSideSwipeShareDirtyGuard', 0, async () => {
      await id('title-新增'); await (await find(ON.id('activityInput'))).inputText('8:00 Loci_UI_swipe');
      await back();
      if (await driver.findComponent(ON.text('继续编辑').inWindow(bundle))) { await tap('继续编辑'); }
      await id('sheet-close'); await tap('继续编辑');
      const bounds = await (await find(ON.type('SheetPage'))).getBounds();
      await driver.swipe(bounds.left + 2, Math.round(bounds.top + (bounds.bottom - bounds.top) * 0.8),
        Math.round((bounds.left + bounds.right) / 2), Math.round(bounds.top + (bounds.bottom - bounds.top) * 0.8), 2500);
      await settle(); await tap('放弃');
      expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) === null).assertTrue();
    });
    it('invalidSaveKeepsInputAndError', 0, async () => {
      await id('title-新增'); await (await find(ON.id('activityInput'))).inputText('invalid_record');
      await id('title-保存');
      expect(await (await find(ON.id('activityInput'))).getText()).assertEqual('invalid_record');
      expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) !== null).assertTrue();
      await back(); if (!await driver.findComponent(ON.text('放弃').inWindow(bundle))) { await back(); }
      await tap('放弃');
    });
    it('routineUsesSheetAndBackWithoutChanges', 0, async () => {
      const nodes = await driver.findComponents(ON.type('Text').inWindow(bundle));
      let opened = false;
      for (const node of nodes || []) {
        if ((await node.getText()).includes('起床')) { await node.click(); opened = true; break; }
      }
      expect(opened).assertTrue(); await settle();
      expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) !== null).assertTrue();
      await back(); expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) === null).assertTrue();
    });
    it('profileAccountAndInformationCanReenter', 0, async () => {
      stage = 'profile account entry'; await tab('我的');
      const scroll = await find(ON.id('profileScroll'));
      const account = ON.id('profile-account').inWindow(bundle);
      await scrollTo(scroll, account); await id('profile-account');
      await find(ON.type('SheetPage')); await back();
      await scrollTo(await find(ON.id('profileScroll')), ON.text('云同步').inWindow(bundle));
      stage = 'sync to account sheet handoff'; await tap('云同步'); await tap('查看华为账号');
      expect((await driver.findComponents(ON.type('SheetPage').inWindow(bundle))).length).assertEqual(1);
      await find(ON.text('华为账号')); await back();
      for (let index = 0; index < 3; index++) {
        await scrollTo(await find(ON.id('profileScroll')), ON.text('关于').inWindow(bundle));
        stage = 'information reentry ' + index; await tap('关于'); await find(ON.id('informationScroll')); await back();
      }
    });
    it('activitySaveEditDeleteRoundTrip', 0, async () => {
      await id('title-新增'); await (await find(ON.id('activityInput'))).inputText('8:00-9:00 ' + fixtureTitle);
      await id('title-保存');
      const entry = ON.text(fixtureTitle, MatchPattern.CONTAINS).inWindow(bundle);
      await scrollTo(await find(ON.id('journalScroll')), entry);
      await (await find(entry)).click(); await settle();
      const input = await find(ON.id('activityInput')); expect(await input.getText()).assertContain(fixtureTitle);
      await input.clearText(); await input.inputText('9:00-10:00 ' + fixtureTitle + '_edited'); await id('title-保存');
      const edited = ON.text(fixtureTitle + '_edited', MatchPattern.CONTAINS).inWindow(bundle);
      await scrollTo(await find(ON.id('journalScroll')), edited); await (await find(edited)).click(); await settle();
      await id('title-删除'); await tap('删除');
      expect(await driver.findComponent(edited) === null).assertTrue();
    });
    it('placeInnerTabsMemoryDirtyBackAndRevisitSheet', 0, async () => {
      stage = 'root place segment';
      await tab('地点');
      if (deviceInfo.sdkApiVersion >= 26) { await driver.dumpLayout('/data/storage/el2/base/cache/loci-before-place-' + runId + '.json'); }
      await (await find(ON.text('地点').type('Button'))).click(); await settle();
      const place = ON.text(fixtureTitle + ' · 1 次到访').inWindow(bundle);
      stage = 'place list';
      const scroll = await find(ON.id('placesList')); await scrollTo(scroll, place); await (await find(place)).click(); await settle();
      expect(await driver.findComponent(ON.text(fixtureTitle).inWindow(bundle)) !== null).assertTrue();
      stage = 'history tab'; await driver.delayMs(1500);
      const historyTab = await find(ON.text('到访记录').type('Text'));
      const historyBounds = await historyTab.getBounds();
      await driver.click(Math.round((historyBounds.left + historyBounds.right) / 2), Math.round((historyBounds.top + historyBounds.bottom) / 2));
      await settle();
      stage = 'memory card'; await (await find(ON.text('UI fixture'))).click(); await settle();
      stage = 'memory editor'; const diary = await find(ON.id('memoryDiary')); await diary.inputText(' changed');
      await back(); if (!await driver.findComponent(ON.text('放弃修改').inWindow(bundle))) { await back(); }
      stage = 'memory keep editing'; await tap('继续编辑'); expect(await (await find(ON.id('memoryDiary'))).getText()).assertContain('changed');
      stage = 'memory discard'; await back(); await tap('放弃修改');
      stage = 'revisit sheet'; await id('title-到访'); expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) !== null).assertTrue(); await back();
      expect(await driver.findComponent(ON.text('到访记录').inWindow(bundle)) !== null).assertTrue(); await back();
    });
    it('usernameInlineCommitAndRestore', 0, async () => {
      await tab('我的');
      await scrollTo(await find(ON.id('profileScroll')), ON.id('usernameSetting').inWindow(bundle));
      const input = await find(ON.id('usernameSetting').type('TextInput'));
      const original = await input.getText();
      try {
        await input.clearText(); await input.inputText(fixtureTitle + '_username');
        expect(await driver.findComponent(ON.type('SheetPage').inWindow(bundle)) === null).assertTrue();
        await tab('记录'); await tab('我的');
        await scrollTo(await find(ON.id('profileScroll')), ON.id('usernameSetting').inWindow(bundle));
        expect(await (await find(ON.id('usernameSetting'))).getText()).assertEqual(fixtureTitle + '_username');
      } finally {
        await tab('我的');
        await scrollTo(await find(ON.id('profileScroll')), ON.id('usernameSetting').inWindow(bundle));
        const restore = await find(ON.id('usernameSetting')); await restore.clearText();
        if (original) { await restore.inputText(original); }
        await tab('记录');
      }
    });
    it('appearanceLargeFontRotationAndForeground', 0, async () => {
      const ability = await abilityDelegatorRegistry.getAbilityDelegator().getCurrentTopAbility();
      const context = ability.context.getApplicationContext();
      const fontScale = ability.context.config.fontSizeScale ?? 1;
      const orientation = appWindow.getPreferredOrientation();
      try {
        context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT); await settle();
        await tab('统计'); await driver.screenCap('/data/storage/el2/base/cache/loci-light-statistics-' + runId + '.png');
        context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK); await settle();
        await tab('我的'); await driver.screenCap('/data/storage/el2/base/cache/loci-dark-profile-' + runId + '.png');
        context.setFontSizeScale(2); await settle();
        await driver.screenCap('/data/storage/el2/base/cache/loci-large-font-' + runId + '.png');
        await tab('记录'); expect(await driver.findComponent(ON.id('title-新增').inWindow(bundle)) !== null).assertTrue();
        await appWindow.setPreferredOrientation(window.Orientation.LANDSCAPE); await settle();
        const rect = appWindow.getWindowProperties().windowRect;
        expect(rect.width > rect.height).assertTrue();
        await driver.screenCap('/data/storage/el2/base/cache/loci-landscape-' + runId + '.png');
        await id('title-新增'); await back();
        await driver.pressHome();
        await abilityDelegatorRegistry.getAbilityDelegator().startAbility({ bundleName: bundle, abilityName: 'EntryAbility' });
        await focusApp(); await settle(); expect(await driver.findComponent(ON.id('title-新增').inWindow(bundle)) !== null).assertTrue();
      } finally {
        context.setFontSizeScale(fontScale);
        context.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        await appWindow.setPreferredOrientation(orientation);
      }
    });
  });
}
