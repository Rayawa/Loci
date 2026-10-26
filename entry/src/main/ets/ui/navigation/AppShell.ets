import { curves, SegmentButtonV2Items } from '@kit.ArkUI';
import { BlurStrategy, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { HuaweiAccount } from '../../service/account/HuaweiAccount';
import { vibration } from '../../common/vibration';
import { HDS_MATERIAL_TYPE_ADAPTIVE } from '../../common/platformCompatibility';
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
  @Local model: AtlasViewModel = new AtlasViewModel();
  @Local journal: JournalViewModel = new JournalViewModel();
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local activeTab: number = 0;
  @Local rootVisible: boolean = true;
  @Local filterOpen: boolean = false;
  @Local sheetVisible: boolean = false;
  @Local journalViews: number[] = [0];
  @Local placeViews: number[] = [0];
  @Local statisticsViews: number[] = [0];
  private tabsController: HdsTabsController = new HdsTabsController();
  private pageStack: NavPathStack = new NavPathStack();
  private dayTimer: number = -1;
  private journalItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '列表' }, { text: '周视图' }]);
  private placeItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '地图' }, { text: '地点' }]);
  private statisticsItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '每日' }, { text: '本周' }]);

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.experience.initialize(context); this.model.initialize(context); this.journal.initialize(context);
    HuaweiAccount.shared.initialize(context);
    this.dayTimer = setInterval(() => {
      if (this.rootVisible && this.journal.ready) { this.journal.checkDayChange(); }
    }, 30000);
  }
  aboutToDisappear(): void { if (this.dayTimer >= 0) { clearInterval(this.dayTimer); } }

  @Builder destination(name: string, parameter: Object, stack: NavPathStack) {
    if (name === Routes.Activity) {
      ActivityEditorPage({ model: this.journal, atlas: this.model, recordId: (parameter as EntityRoute).id, stack: stack })

    } else if (name === Routes.Visit) {
      VisitEditorPage({ atlas: this.model, stack: stack, onSaved: (record: RecordedVisit) => this.visitSaved(record) })
    } else if (name === Routes.Routine) {
      DayRoutinePage({ model: this.journal, localDate: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Place) {
      PlaceDetailPage({ atlas: this.model, placeId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Memory) {
      MemoryPage({ atlas: this.model, visitId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Settings) { SettingsPage() }
    else if ([Routes.Account, Routes.Sync, Routes.Changelog, Routes.About].includes(name)) {
      InformationPage({ kind: name, stack: stack })
    }
  }
  @Builder rootDestination(name: string, parameter: Object) { this.destination(name, parameter, this.pageStack) }

  @Monitor('model.notice', 'model.error')
  onUserMessage(): void {
    const message = this.model.error || this.model.notice;
    if (message) { showToastSafely(this.getUIContext().getPromptAction(), message); }
  }
  @Monitor('model.showAdd')
  onAddChanged(): void {
    if (this.model.showAdd) {
      this.filterOpen = false; this.sheetVisible = false;
      this.pageStack.pushPathByName(Routes.Visit, new EntityRoute(''));
    }
  }
  private dismissSheet(action: DismissSheetAction): void { action.dismiss(); }
  @Builder addVisit() { MapFilters({ model: this.model }) }
  private visitSaved(record: RecordedVisit): void {
    if (record.isNewPlace) {
      this.placeViews = [0]; if (this.activeTab !== 1) { this.tabsController.changeIndex(1); }
    } else { this.pageStack.pushPathByName(Routes.Memory, new EntityRoute(record.visitId)); }
  }
  private titleMenus(): TitleAction[] {
    if (this.activeTab === 1) {
      const ready = this.model.ready && !this.model.loading && !this.model.locating && !this.model.selectingMap && !this.model.showAdd;
      return [
        { label: '记录这里', icon: Icons.add, isEnabled: ready, action: () => this.model.recordHere() },
        { label: '当前位置', icon: Icons.locate, isEnabled: ready, action: () => this.model.locateOnMap() },
        { label: '筛选', icon: Icons.filter, isEnabled: this.model.ready,
          action: () => { this.filterOpen = true; this.sheetVisible = true; } }
      ];
    }
    if (this.activeTab !== 0) { return []; }
    return [{ label: '新增', icon: Icons.add, isEnabled: this.journal.ready,
      action: () => this.pageStack.pushPathByName(Routes.Activity, new EntityRoute('')) }];
  }
  private selectView(index: number): void {
    if (this.activeTab === 0) { this.journalViews = [index]; }
    else if (this.activeTab === 1) { this.placeViews = [index]; }
    else if (this.activeTab === 2) { this.statisticsViews = [index]; }
  }
  @Builder placesContent() {
    if (!this.model.loading && !this.model.ready && this.model.error) {
      Column() {
        Blank().height(110)
        StatePanel({ title: '暂时无法打开地点', message: this.model.error, action: '重试',
          onAction: () => this.model.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
      }.width('100%').padding(Theme.pagePadding)
    } else {
      MapPage({ model: this.model, stack: this.pageStack, viewIndex: this.placeViews[0],
        active: this.activeTab === 1 && this.rootVisible && !this.sheetVisible })
    }
  }
  private tabStyle(icon: Resource, label: string): BottomTabBarStyle {
    return new BottomTabBarStyle({ normal: Icons.modifier(icon).fontColor([Theme.muted]),
      selected: Icons.modifier(icon).fontColor([Theme.accent]) }, label)
      .labelStyle({ selectedColor: Theme.accent, unselectedColor: Theme.muted });
  }
  @Builder mainTabs() {
    // Dashboard's floating tabs and motion, with V2 owner-preserving builder closures.
    HdsTabs({ controller: this.tabsController, index: this.activeTab }) {
      TabContent() {
        JournalPage({ model: this.journal, atlas: this.model, stack: this.pageStack, viewIndex: this.journalViews[0],
          onSelectList: () => { this.journalViews = [0]; } })
      }.tabBar(this.tabStyle(Icons.journal, '记录'))
        .opacity(this.activeTab === 0 ? 1 : 0.92)
        .scale({ x: this.activeTab === 0 ? 1 : 0.985, y: this.activeTab === 0 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('记录标签页')
      TabContent() { this.placesContent() }.tabBar(this.tabStyle(Icons.map, '地点'))
        .opacity(this.activeTab === 1 ? 1 : 0.92)
        .scale({ x: this.activeTab === 1 ? 1 : 0.985, y: this.activeTab === 1 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('地点标签页')
      TabContent() {
        StatisticsPage({ model: this.journal, weekly: this.statisticsViews[0] === 1 })
      }.tabBar(this.tabStyle(Icons.statistics, '统计'))
        .opacity(this.activeTab === 2 ? 1 : 0.92)
        .scale({ x: this.activeTab === 2 ? 1 : 0.985, y: this.activeTab === 2 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('统计标签页')
      TabContent() { ProfilePage({ stack: this.pageStack, active: this.activeTab === 3 && this.rootVisible }) }.tabBar(this.tabStyle(Icons.person, '我的'))
        .opacity(this.activeTab === 3 ? 1 : 0.92)
        .scale({ x: this.activeTab === 3 ? 1 : 0.985, y: this.activeTab === 3 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('我的标签页')
    }.barPosition(BarPosition.End).barWidth(250).cachedMaxCount(4, TabsCacheMode.CACHE_LATEST_SWITCHED)
      .scrollable(false).vertical(false).barOverlap(true).blurStrategy(BlurStrategy.ENABLE)
      .barFloatingStyle({ barBottomMargin: 28, lightColor: $r('app.color.diff_content'),
        gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
        systemMaterialEffect: { materialType: HDS_MATERIAL_TYPE_ADAPTIVE, materialLevel: this.experience.materialLevel } })
      .onChange((index: number) => { this.activeTab = index; this.journal.checkDayChange(); vibration.dotVibration(); })
      .width('100%').height('100%').backgroundColor(Theme.background)
  }
  build() {
    HdsNav({ stack: this.pageStack, title: ['记录', '地点', '统计', '我的'][this.activeTab], menus: this.titleMenus(),
      showSegment: this.activeTab !== 3,
      segmentItems: this.activeTab === 0 ? this.journalItems : this.activeTab === 1 ? this.placeItems : this.statisticsItems,
      selectedIndexes: this.activeTab === 0 ? this.journalViews : this.activeTab === 1 ? this.placeViews : this.statisticsViews,
      onSegmentSelected: (index: number) => this.selectView(index),
      onRootVisibleChanged: (visible: boolean) => { this.rootVisible = visible; if (visible) { this.journal.checkDayChange(); } },
      content: () => { this.mainTabs() }, destination: (name: string, parameter: Object) => { this.rootDestination(name, parameter) } })
      .bindSheet(this.sheetVisible!!, this.addVisit(), { height: SheetSize.LARGE, showClose: true,
        backgroundColor: Theme.surface, maskColor: Theme.scrim, blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS, onWillDismiss: (action: DismissSheetAction) => this.dismissSheet(action),
        onDisappear: () => { this.filterOpen = false; } })
  }
}
