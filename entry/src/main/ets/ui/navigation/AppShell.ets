import { curves, SegmentButtonV2Items } from '@kit.ArkUI';
import { BlurStrategy, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { vibration } from '../../common/vibration';
import { HDS_MATERIAL_TYPE_ADAPTIVE } from '../../common/platformCompatibility';
import { showToastSafely } from '../../common/safeUi';
import { AddVisitSheet } from '../components/AddVisitSheet';
import { MapFilters } from '../components/MapFilters';
import { StatePanel } from '../components/StatePanel';
import { MapPage } from '../pages/MapPage';
import { PlaceDetailPage } from '../pages/PlaceDetailPage';
import { MemoryPage } from '../pages/MemoryPage';
import { SettingsPage } from '../pages/SettingsPage';
import { Icons } from '../../common/icons';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { HdsNav, TitleAction } from './HdsNav';
import { EntityRoute, Routes } from './Routes';

@ComponentV2
export struct AppShell {
  @Local model: AtlasViewModel = new AtlasViewModel();
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local activeTab: number = 0;
  @Local rootVisible: boolean = true;
  @Local filterOpen: boolean = false;
  @Local sheetVisible: boolean = false;
  @Local draftDirty: boolean = false;
  @Local draftSaving: boolean = false;
  private tabsController: HdsTabsController = new HdsTabsController();
  private pageStack: NavPathStack = new NavPathStack();
  @Local mapViews: number[] = [0];
  @Local tripsViews: number[] = [0];
  @Local atlasViews: number[] = [0];
  private mapItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '地图' }, { text: '地点' }]);
  private tripsItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '旅程' }, { text: '轨迹' }]);
  private atlasItems: SegmentButtonV2Items = new SegmentButtonV2Items([{ text: '城市' }, { text: '国家' }, { text: '时间' }]);

  aboutToAppear(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.experience.initialize(context);
    this.model.initialize(context);
  }

  @Builder destination(name: string, parameter: Object, stack: NavPathStack) {
    if (name === Routes.Place) {
      PlaceDetailPage({ atlas: this.model, placeId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Memory) {
      MemoryPage({ atlas: this.model, visitId: (parameter as EntityRoute).id, stack: stack })
    } else if (name === Routes.Settings) {
      SettingsPage()
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
      this.draftDirty = false; this.draftSaving = false; this.filterOpen = false; this.sheetVisible = true;
    } else if (!this.filterOpen) { this.sheetVisible = false; }
  }

  private dismissSheet(action: DismissSheetAction): void {
    if (this.draftSaving) { return; }
    if (this.filterOpen || !this.draftDirty) { action.dismiss(); return; }
    this.getUIContext().showAlertDialog({ title: '保留这段记忆？', message: '关闭后，尚未保存的内容会丢失。',
      primaryButton: { value: '继续记录', action: () => {} },
      secondaryButton: { value: '放弃记录', action: () => action.dismiss() } });
  }

  @Builder addVisit() {
    if (this.filterOpen) { MapFilters({ model: this.model }) }
    else if (this.model.draft) {
      AddVisitSheet({ model: this.model, draft: this.model.draft,
        onEditingState: (dirty: boolean, saving: boolean) => { this.draftDirty = dirty; this.draftSaving = saving; },
        onSaved: (record: RecordedVisit) => {
          if (record.isNewPlace) {
            this.mapViews = [0];
            if (this.activeTab !== 0) { this.tabsController.changeIndex(0); }
          } else { this.pageStack.pushPathByName(Routes.Memory, new EntityRoute(record.visitId)); }
        } })
    }
  }

  private titleMenus(): TitleAction[] {
    const ready = this.model.ready && !this.model.loading && !this.model.locating && !this.model.selectingMap;
    const settings: TitleAction = { label: '设置', icon: Icons.settings, isEnabled: true,
      action: () => this.pageStack.pushPathByName(Routes.Settings, new EntityRoute('')) };
    if (this.activeTab !== 0) { return [settings]; }
    return [
      { label: '记录这里', icon: Icons.add, isEnabled: ready, action: () => this.model.recordHere() },
      { label: '当前位置', icon: Icons.locate, isEnabled: ready, action: () => this.model.locateOnMap() },
      { label: '筛选', icon: Icons.filter, isEnabled: this.model.ready,
        action: () => { vibration.dotVibration(); this.filterOpen = true; this.sheetVisible = true; } }, settings
    ];
  }

  private selectView(index: number): void {
    if (this.activeTab === 0) { this.mapViews = [index]; }
    else if (this.activeTab === 1) { this.tripsViews = [index]; }
    else { this.atlasViews = [index]; }
  }

  @Builder mapContent() {
    if (!this.model.loading && !this.model.ready && this.model.error) {
      StatePanel({ title: '暂时无法打开足迹', message: this.model.error, action: '重试',
        onAction: () => this.model.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
    } else { MapPage({ model: this.model, stack: this.pageStack, viewIndex: this.mapViews[0], active: this.activeTab === 0 && this.rootVisible && !this.sheetVisible }) }
  }
  @Builder tripsContent() {
    StatePanel({ title: this.tripsViews[0] === 0 ? '旅行记忆尚未开放' : '轨迹记录尚未开放', message: '你的地点记忆，会成为每一段旅程的起点。' }).margin({ top: 110, left: 14, right: 14 })
  }
  @Builder atlasContent() {
    StatePanel({ title: ['城市足迹尚未开放', '国家足迹尚未开放', '时间轴尚未开放'][this.atlasViews[0]], message: '先从一个地点开始，慢慢留下自己的世界。' }).margin({ top: 110, left: 14, right: 14 })
  }

  private tabStyle(icon: Resource, label: string): BottomTabBarStyle {
    return new BottomTabBarStyle({ normal: Icons.modifier(icon).fontColor([Theme.muted]),
      selected: Icons.modifier(icon).fontColor([Theme.accent]) }, label)
      .labelStyle({ selectedColor: Theme.accent, unselectedColor: Theme.muted });
  }

  @Builder mainTabs() {
    // BuilderParam closures preserve AppShell as the owner of its V2 state.
    // Floating-bar settings follow Dashboard.mainTabsView verbatim.
    HdsTabs({ controller: this.tabsController, index: this.activeTab }) {
      TabContent() {
        this.mapContent()
      }.tabBar(this.tabStyle(Icons.map, '地图'))
        .opacity(this.activeTab === 0 ? 1 : 0.92)
        .scale({ x: this.activeTab === 0 ? 1 : 0.985, y: this.activeTab === 0 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('地图标签页')
      TabContent() {
        this.tripsContent()
      }.tabBar(this.tabStyle(Icons.trips, '旅行'))
        .opacity(this.activeTab === 1 ? 1 : 0.92)
        .scale({ x: this.activeTab === 1 ? 1 : 0.985, y: this.activeTab === 1 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('旅行标签页')
      TabContent() {
        this.atlasContent()
      }.tabBar(this.tabStyle(Icons.atlas, '足迹'))
        .opacity(this.activeTab === 2 ? 1 : 0.92)
        .scale({ x: this.activeTab === 2 ? 1 : 0.985, y: this.activeTab === 2 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).accessibilityText('足迹标签页')
    }.barPosition(BarPosition.End).barWidth(250).cachedMaxCount(3, TabsCacheMode.CACHE_LATEST_SWITCHED)
      .scrollable(false).vertical(false).barOverlap(true).blurStrategy(BlurStrategy.ENABLE)
      .barFloatingStyle({ barBottomMargin: 28, lightColor: $r('app.color.diff_content'),
        gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
        systemMaterialEffect: { materialType: HDS_MATERIAL_TYPE_ADAPTIVE, materialLevel: this.experience.materialLevel } })
      .onChange((index: number) => { this.activeTab = index; vibration.dotVibration(); })
      .width('100%').height('100%').backgroundColor(Theme.background)
  }

  build() {
    HdsNav({ stack: this.pageStack, title: ['地图', '旅行', '足迹'][this.activeTab], menus: this.titleMenus(),
      segmentItems: this.activeTab === 0 ? this.mapItems : this.activeTab === 1 ? this.tripsItems : this.atlasItems,
      selectedIndexes: this.activeTab === 0 ? this.mapViews : this.activeTab === 1 ? this.tripsViews : this.atlasViews,
      onSegmentSelected: (index: number) => this.selectView(index),
      onRootVisibleChanged: (visible: boolean) => { this.rootVisible = visible; },
      content: () => { this.mainTabs() }, destination: (name: string, parameter: Object) => { this.rootDestination(name, parameter) } })
      .bindSheet(this.sheetVisible!!, this.addVisit(), { height: SheetSize.LARGE, showClose: true,
        backgroundColor: Theme.surface, maskColor: Theme.scrim, blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS, onWillDismiss: (action: DismissSheetAction) => this.dismissSheet(action),
        onDisappear: () => { this.model.showAdd = false; this.filterOpen = false; this.draftDirty = false; this.draftSaving = false; } })
  }
}
