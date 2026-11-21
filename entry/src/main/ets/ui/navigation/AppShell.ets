import { AppLifecycle } from '../../service/app/AppLifecycle';
import { HdsNavigation, HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { SheetRequest, SheetSession, PageBack } from './SheetSession';
import { sheetTitle } from '../theme/NavigationStyle';
import { Haptics } from '../../service/haptics/Haptics';
import { curves, SegmentButtonV2Items } from '@kit.ArkUI';
import { BlurStrategy, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { HuaweiAccount } from '../../service/account/HuaweiAccount';
import { vibration } from '../../common/vibration';
import { HDS_MATERIAL_TYPE_ADAPTIVE, SUPPORTS_HARMONY_API_23 } from '../../common/platformCompatibility';
import { showToastSafely } from '../../common/safeUi';
import { VisitEditorPage } from '../pages/VisitEditorPage';
import { MapFilters } from '../components/MapFilters';
import { MapPage } from '../pages/MapPage';
import { StatePanel } from '../components/StatePanel';
import { PlaceDetailPage } from '../pages/PlaceDetailPage';
import { MemoryPage } from '../pages/MemoryPage';
import { SettingsPage } from '../pages/SettingsPage';
import { JournalPage } from '../pages/JournalPage';
import { StatisticsPage } from '../pages/StatisticsPage';
import { ProfilePage } from '../pages/ProfilePage';
import { InformationPage } from '../pages/InformationPage';
import { DayRoutinePage } from '../pages/DayRoutinePage';
import { ActivityEditorPage } from '../pages/ActivityEditorPage';
import { Icons } from '../../common/icons';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { HdsNav, TitleAction } from './HdsNav';
import { EntityRoute, Routes } from './Routes';

@ComponentV2
export struct AppShell {
  @Local lifecycle: AppLifecycle = AppLifecycle.shared;
  @Local model: AtlasViewModel = new AtlasViewModel();
  @Local journal: JournalViewModel = new JournalViewModel();
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local activeTab: number = 0;
  @Local scrollToTopTab: number = -1;
  @Local scrollToTopVersion: number = 0;
  @Local rootVisible: boolean = true;
  @Local sheetVisible: boolean = false;
  @Local journalViews: number[] = [0];
  @Local placeViews: number[] = [0];
  @Local statisticsViews: number[] = [0];
  @Local sheetOptions: SheetOptions = {};
  private nextSheetTimer: number = -1;
  @Local sheetSession: SheetSession = new SheetSession(0, () => {}, () => {});
  @Local sheetStack: NavPathStack = new NavPathStack();
  private sheetToken: number = 0;
  private sheetMounted: boolean = false;
  private returnFocusId: string = 'rootContent';
  private sheetKind: string = '';
  private pendingSheet: SheetRequest | undefined = undefined;
  private dismissAction: DismissSheetAction | undefined = undefined;
  private confirmingClose: boolean = false;
  private afterSheetClose: (() => void) | undefined = undefined;
  private disposed: boolean = false;
  private tabsController: HdsTabsController = new HdsTabsController();
  private pageStack: NavPathStack = new NavPathStack();
  private dayTimer: number = -1;
  private journalItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '列表', accessibilityText: '列表视图' }, { text: '周视图', accessibilityText: '周视图' }]);
  private placeItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '地图', accessibilityText: '地图视图' }, { text: '地点', accessibilityText: '地点列表' }]);
  private statisticsItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '每日', accessibilityText: '每日统计' }, { text: '本周', accessibilityText: '本周统计' }]);

  aboutToAppear(): void {
    this.disposed = false;
    PageBack.handle = () => this.back();
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.experience.initialize(context); this.model.initialize(context); this.journal.initialize(context);
    HuaweiAccount.shared.initialize(context);
    this.startDayTimer();
  }
  @Monitor('lifecycle.foreground')
  onForegroundChanged(): void {
    if (this.lifecycle.foreground) {
      this.journal.checkDayChange(); this.startDayTimer();
      if (this.model.ready) { this.model.refresh().catch(() => { this.model.placesError = '暂时无法刷新地点'; }); }
    }
    else if (this.dayTimer >= 0) { clearInterval(this.dayTimer); this.dayTimer = -1; }
  }
  private startDayTimer(): void {
    if (this.dayTimer >= 0 || !this.lifecycle.foreground) { return; }
    this.dayTimer = setInterval(() => {
      if (this.rootVisible && this.journal.ready) { this.journal.checkDayChange(); }
    }, 30000);
  }
  aboutToDisappear(): void {
    this.disposed = true; PageBack.handle = () => false;
    if (this.nextSheetTimer >= 0) { clearTimeout(this.nextSheetTimer); this.nextSheetTimer = -1; }
    if (this.dayTimer >= 0) { clearInterval(this.dayTimer); this.dayTimer = -1; }
  }
  private back(): boolean {
    if (this.sheetMounted) { this.requestSheetClose(this.sheetSession.token); return true; }
    // Native destinations handle their own back lifecycle before the @Entry fallback.
    Haptics.back(); return false;
  }

  @Builder destination(name: string, parameter: Object, stack: NavPathStack) {
    if (name === Routes.Place) {
      PlaceDetailPage({ atlas: this.model, placeId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Memory) {
      MemoryPage({ atlas: this.model, visitId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Settings) { SettingsPage({ onShortOperation: (kind: string) => this.openSheet(kind) }) }
    else if ([Routes.Account, Routes.Sync, Routes.Changelog, Routes.About].includes(name)) {
      InformationPage({ kind: name, stack: stack })
    }
  }
  @Builder rootDestination(name: string, parameter: Object) { this.destination(name, parameter, this.pageStack) }

  @Monitor('model.notice', 'model.error')
  onUserMessage(): void {
    const message = this.model.error || this.model.notice;
    if (message && this.lifecycle.foreground) { showToastSafely(this.getUIContext().getPromptAction(), message); }
  }
  @Monitor('model.showAdd')
  onAddChanged(): void {
    if (this.model.showAdd) { this.openSheet(Routes.Visit); }
  }
  private openSheet(kind: string, id: string = ''): void {
    if (this.disposed) { return; }
    if (this.sheetMounted) {
      this.pendingSheet = new SheetRequest(kind, id);
      this.requestSheetClose(this.sheetSession.token); return;
    }
    const token = ++this.sheetToken;
    this.sheetKind = kind; this.sheetMounted = true;
    this.returnFocusId = kind === Routes.Activity ? (id ? 'activity-' + id : 'title-新增') :
      kind === Routes.Routine ? 'routine-wake' :
      kind === Routes.Visit ? (this.pageStack.size() ? 'title-到访' : 'title-记录这里') :
      kind === Routes.Sync ? 'profile-云同步' : kind === Routes.Account ? 'profile-account' : 'title-筛选';
    this.sheetSession = new SheetSession(token, () => this.requestSheetClose(token), () => this.closeSheet(token, true));
    this.sheetStack = new NavPathStack(); this.sheetStack.pushPathByName(kind, new EntityRoute(id), false);
    this.sheetOptions = this.optionsFor(token);
    this.sheetVisible = true; Haptics.confirm();
  }
  private closeSheet(token: number, saved: boolean = false): void {
    if (token !== this.sheetSession.token || !this.sheetVisible) { return; }
    this.confirmingClose = false;
    if (saved) { Haptics.confirm(); } else { Haptics.back(); }
    this.sheetVisible = false;
    const action = this.dismissAction; this.dismissAction = undefined;
    if (action) { action.dismiss(); }
  }
  private requestSheetClose(token: number): void {
    if (token !== this.sheetSession.token || !this.sheetVisible || this.confirmingClose) { return; }
    if (this.sheetSession.saving) { this.pendingSheet = undefined; this.dismissAction = undefined; return; }
    if (!this.sheetSession.dirty) { this.closeSheet(token); return; }
    this.confirmingClose = true;
    this.getUIContext().showAlertDialog({ title: '放弃修改？', message: '尚未保存的修改将被放弃。',
      primaryButton: { value: '继续编辑', action: () => {
        this.confirmingClose = false; this.pendingSheet = undefined; this.dismissAction = undefined;
      } },
      secondaryButton: { value: '放弃', action: () => this.closeSheet(token) },
      cancel: () => { this.confirmingClose = false; this.pendingSheet = undefined; this.dismissAction = undefined; }
    });
  }
  private optionsFor(token: number): SheetOptions {
    return { height: SheetSize.LARGE, showClose: false, backgroundColor: Theme.surface,
      maskColor: Theme.scrim, blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      onWillDismiss: (action: DismissSheetAction) => {
        if (token !== this.sheetSession.token) { return; }
        this.dismissAction = action; this.requestSheetClose(token);
      },
      onDisappear: () => this.sheetDisappeared(token) };
  }
  private sheetDisappeared(token: number): void {
    if (token !== this.sheetSession.token || !this.sheetMounted) { return; }
    // Do not create the next native sheet until this instance has finished disappearing.
    this.sheetMounted = false; this.sheetVisible = false; this.dismissAction = undefined;
    this.confirmingClose = false;
    if (this.sheetKind === Routes.Visit) { this.model.showAdd = false; }
    const next = this.pendingSheet; this.pendingSheet = undefined;
    const afterClose = this.afterSheetClose; this.afterSheetClose = undefined;
    if (this.disposed) { return; }
    this.nextSheetTimer = setTimeout(() => {
      this.nextSheetTimer = -1;
      if (this.disposed || token !== this.sheetSession.token) { return; }
      if (next) { this.openSheet(next.kind, next.id); }
      else if (afterClose) { afterClose(); }
      else {
        try { this.getUIContext().getFocusController().requestFocus(this.returnFocusId); } catch (_) {
          try { this.getUIContext().getFocusController().requestFocus('rootContent'); } catch (_) {}
        }
      }
    }, 0);
  }
  @Builder sheetDestination(name: string, parameter: Object) {
    if (name === Routes.Activity) {
      ActivityEditorPage({ model: this.journal, atlas: this.model, recordId: (parameter as EntityRoute).id, session: this.sheetSession })
    } else if (name === Routes.Routine) {
      DayRoutinePage({ model: this.journal, localDate: (parameter as EntityRoute).id, session: this.sheetSession })
    } else if (name === Routes.Visit) {
      VisitEditorPage({ atlas: this.model, session: this.sheetSession,
        onSaved: (record: RecordedVisit) => this.visitSaved(record) })

    } else if (name === Routes.Account || name === Routes.Sync) {
      InformationPage({ kind: name, stack: this.pageStack, session: this.sheetSession,
        onOpenAccount: () => this.openSheet(Routes.Account) })
    } else {
      HdsNavDestination() { MapFilters({ model: this.model }) }
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .titleBar(sheetTitle('筛选', this.experience.materialLevel,
          [{ label: '完成', icon: Icons.save, isEnabled: true, action: () => this.sheetSession.requestClose() }]))
        .onBackPressed(() => { this.sheetSession.requestClose(); return true; })
    }
  }
  @Builder sheetContent() {
    // A new session owns a new native navigation instance, including when bindSheet caches its builder.
    ForEach([this.sheetSession.token], (token: number) => {
      HdsNavigation(this.sheetStack) { Column() {} }
        .mode(NavigationMode.Stack).hideTitleBar(true).navDestination(this.sheetDestination)
        .width('100%').height('100%').backgroundColor(Theme.surface)
    }, (token: number) => token.toString())
  }
  private visitSaved(record: RecordedVisit): void {
    this.afterSheetClose = () => {
      if (record.isNewPlace) {
        this.placeViews = [0]; if (this.activeTab !== 1) { this.tabsController.changeIndex(1); }
      } else { this.pageStack.pushPathByName(Routes.Memory, new EntityRoute(record.visitId)); }
    };
  }
  private titleMenus(): TitleAction[] {
    if (this.activeTab === 1) {
      const ready = this.model.ready && !this.model.loading && !this.model.locating && !this.model.selectingMap && !this.model.showAdd;
      return [
        { label: '记录这里', icon: Icons.add, isEnabled: ready, action: () => this.model.recordHere() },
        { label: '当前位置', icon: Icons.locate, isEnabled: ready, action: () => this.model.locateOnMap() },
        { label: '筛选', icon: Icons.filter, isEnabled: this.model.ready,
          action: () => this.openSheet('Filters') }
      ];
    }
    if (this.activeTab !== 0) { return []; }
    return [{ label: '新增', icon: Icons.add, isEnabled: this.journal.ready,
      action: () => this.openSheet(Routes.Activity) }];
  }
  private selectView(index: number): void {
    if (this.activeTab === 0) { this.journalViews = [index]; }
    else if (this.activeTab === 1) { this.placeViews = [index]; }
    else if (this.activeTab === 2) { this.statisticsViews = [index]; }
  }
  @Builder placesContent() {
    if (!this.model.loading && !this.model.ready && this.model.error) {
      Column() {
        Blank().height(8)
        StatePanel({ title: '暂时无法打开地点', message: this.model.error, action: '重试',
          onAction: () => this.model.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
      }.width('100%').padding(Theme.pagePadding)
    } else {
      MapPage({ model: this.model, stack: this.pageStack, viewIndex: this.placeViews[0],
        active: this.lifecycle.foreground && this.activeTab === 1 && this.rootVisible && !this.sheetVisible,
        scrollToTopVersion: this.scrollToTopTab === 1 ? this.scrollToTopVersion : 0 })
    }
  }
  private tabStyle(icon: Resource, label: string): BottomTabBarStyle {
    return new BottomTabBarStyle({ normal: Icons.modifier(icon).fontColor([Theme.muted]),
      selected: Icons.modifier(icon).fontColor([Theme.accent]) }, label)
      .labelStyle({ selectedColor: Theme.accent, unselectedColor: Theme.muted });
  }
  private handleTabBarClick(index: number): void {
    if (index !== this.activeTab) { return; }
    Haptics.confirm();
    this.scrollToTopTab = index;
    this.scrollToTopVersion++;
  }
  @Builder mainTabContents() {
      TabContent() {
        JournalPage({ model: this.journal, viewIndex: this.journalViews[0],
          scrollToTopVersion: this.scrollToTopTab === 0 ? this.scrollToTopVersion : 0,
          onSelectList: () => { this.journalViews = [0]; },
          onEdit: (id: string) => this.openSheet(Routes.Activity, id), onRoutine: (date: string) => this.openSheet(Routes.Routine, date) })
      }.tabBar(this.tabStyle(Icons.journal, '记录'))
        .opacity(this.activeTab === 0 ? 1 : 0.92)
        .scale({ x: this.activeTab === 0 ? 1 : 0.985, y: this.activeTab === 0 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('记录标签页')
      TabContent() { this.placesContent() }.tabBar(this.tabStyle(Icons.map, '地点'))
        .opacity(this.activeTab === 1 ? 1 : 0.92)
        .scale({ x: this.activeTab === 1 ? 1 : 0.985, y: this.activeTab === 1 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('地点标签页')
      TabContent() {
        StatisticsPage({ model: this.journal, weekly: this.statisticsViews[0] === 1,
          scrollToTopVersion: this.scrollToTopTab === 2 ? this.scrollToTopVersion : 0 })
      }.tabBar(this.tabStyle(Icons.statistics, '统计'))
        .opacity(this.activeTab === 2 ? 1 : 0.92)
        .scale({ x: this.activeTab === 2 ? 1 : 0.985, y: this.activeTab === 2 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('统计标签页')
      TabContent() {
        ProfilePage({ stack: this.pageStack, onShortOperation: (kind: string) => this.openSheet(kind),
          active: this.lifecycle.foreground && this.activeTab === 3 && this.rootVisible,
          scrollToTopVersion: this.scrollToTopTab === 3 ? this.scrollToTopVersion : 0 })
      }.tabBar(this.tabStyle(Icons.person, '我的'))
        .opacity(this.activeTab === 3 ? 1 : 0.92)
        .scale({ x: this.activeTab === 3 ? 1 : 0.985, y: this.activeTab === 3 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('我的标签页')
  }
  @Builder mainTabs() {
    if (SUPPORTS_HARMONY_API_23) {
      HdsTabs({ controller: this.tabsController, index: this.activeTab }) { this.mainTabContents() }
      .cachedMaxCount(4, TabsCacheMode.CACHE_LATEST_SWITCHED)
      .barFloatingStyle({ barBottomMargin: 28, lightColor: $r('app.color.diff_content'),
        gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
        systemMaterialEffect: { materialType: HDS_MATERIAL_TYPE_ADAPTIVE, materialLevel: this.experience.materialLevel } })
      .barPosition(BarPosition.End).barWidth(250)
      .scrollable(false).vertical(false).barOverlap(true).blurStrategy(BlurStrategy.ENABLE)
      .onTabBarClick((index: number) => this.handleTabBarClick(index))
      .onChange((index: number) => { this.activeTab = index; this.journal.checkDayChange(); vibration.dotVibration(); })
      .width('100%').height('100%').backgroundColor(Theme.background).id('rootContent').focusable(true)
      .accessibilityText('主界面四个标签页，依次为记录、地点、统计和我的')
    } else {
      HdsTabs({ controller: this.tabsController, index: this.activeTab }) { this.mainTabContents() }
      .padding({ bottom: 28 })
      .barPosition(BarPosition.End).barWidth(250)
      .scrollable(false).vertical(false).barOverlap(true).blurStrategy(BlurStrategy.ENABLE)
      .barBackgroundColor(Theme.surface)
      .barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
      .onTabBarClick((index: number) => this.handleTabBarClick(index))
      .onChange((index: number) => { this.activeTab = index; this.journal.checkDayChange(); vibration.dotVibration(); })
      .width('100%').height('100%').backgroundColor(Theme.background).id('rootContent').focusable(true)
      .accessibilityText('主界面四个标签页，依次为记录、地点、统计和我的')
    }
  }
  build() {
    HdsNav({ stack: this.pageStack, title: ['记录', '地点', '统计', '我的'][this.activeTab], menus: this.titleMenus(),
      showSegment: this.activeTab !== 3,
      segmentItems: this.activeTab === 0 ? this.journalItems : this.activeTab === 1 ? this.placeItems : this.statisticsItems,
      selectedIndexes: this.activeTab === 0 ? this.journalViews : this.activeTab === 1 ? this.placeViews : this.statisticsViews,
      onSegmentSelected: (index: number) => this.selectView(index),
      onRootVisibleChanged: (visible: boolean) => { this.rootVisible = visible; if (visible) { this.journal.checkDayChange(); } },
      content: () => { this.mainTabs() }, destination: (name: string, parameter: Object) => { this.rootDestination(name, parameter) } })
      .bindSheet(this.sheetVisible!!, this.sheetContent(), this.sheetOptions)
  }
}
