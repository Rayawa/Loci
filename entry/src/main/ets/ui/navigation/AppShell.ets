import { curves } from '@kit.ArkUI';
import { BlurStrategy, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { vibration } from '../../common/vibration';
import { HDS_MATERIAL_TYPE_ADAPTIVE } from '../../common/platformCompatibility';
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
import { HdsNav } from './HdsNav';
import { EntityRoute, Routes } from './Routes';

@ComponentV2
export struct AppShell {
  @Local model: AtlasViewModel = new AtlasViewModel();
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local activeTab: number = 0;
  @Local filterOpen: boolean = false;
  @Local sheetVisible: boolean = false;
  @Local draftDirty: boolean = false;
  @Local draftSaving: boolean = false;
  private tabsController: HdsTabsController = new HdsTabsController();
  private mapStack: NavPathStack = new NavPathStack();
  private tripsStack: NavPathStack = new NavPathStack();
  private atlasStack: NavPathStack = new NavPathStack();

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
  @Builder mapDestination(name: string, parameter: Object) { this.destination(name, parameter, this.mapStack) }
  @Builder tripsDestination(name: string, parameter: Object) { this.destination(name, parameter, this.tripsStack) }
  @Builder atlasDestination(name: string, parameter: Object) { this.destination(name, parameter, this.atlasStack) }

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
          this.mapStack.pushPathByName(Routes.Memory, new EntityRoute(record.visitId));
        } })
    }
  }

  private mapToolbar(): ToolbarItem[] {
    const disabled = !this.model.ready || this.model.loading || this.model.locating;
    return [
      { value: this.model.locating ? '正在定位' : '记录这里', symbolIcon: Icons.modifier(Icons.add),
        status: disabled ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL, action: () => this.model.recordHere() },
      { value: '当前位置', symbolIcon: Icons.modifier(Icons.locate),
        status: disabled ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL, action: () => this.model.locateOnMap() },
      { value: '筛选', symbolIcon: Icons.modifier(Icons.filter),
        status: !this.model.ready ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL,
        action: () => { vibration.dotVibration(); this.filterOpen = true; this.sheetVisible = true; } }
    ];
  }

  @Builder mapContent() {
    if (!this.model.loading && !this.model.ready && this.model.error) {
      StatePanel({ title: '暂时无法打开足迹', message: this.model.error, action: '重试',
        onAction: () => this.model.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
    } else { MapPage({ model: this.model, stack: this.mapStack }) }
  }
  @Builder tripsContent() {
    StatePanel({ title: '旅行记忆尚未开放', message: '你的地点记忆，会成为每一段旅程的起点。' })
  }
  @Builder atlasContent() {
    StatePanel({ title: '足迹浏览尚未开放', message: '先从一个地点开始，慢慢留下自己的世界。' })
  }

  private tabStyle(icon: Resource, label: string): BottomTabBarStyle {
    return new BottomTabBarStyle({ normal: Icons.modifier(icon).fontColor([Theme.muted]),
      selected: Icons.modifier(icon).fontColor([Theme.accent]) }, label)
      .labelStyle({ selectedColor: Theme.accent, unselectedColor: Theme.muted });
  }

  build() {
    // BuilderParam closures preserve AppShell as the owner of its V2 state.
    // Floating-bar settings follow Dashboard.mainTabsView verbatim.
    HdsTabs({ controller: this.tabsController, index: this.activeTab }) {
      TabContent() {
        HdsNav({ stack: this.mapStack, title: '地图', actions: this.mapToolbar(), content: () => { this.mapContent() },
          destination: (name: string, parameter: Object) => { this.mapDestination(name, parameter) }, onSettings: () => this.mapStack.pushPathByName(Routes.Settings, new EntityRoute('')) })
      }.tabBar(this.tabStyle(Icons.map, '地图'))
        .opacity(this.activeTab === 0 ? 1 : 0.92)
        .scale({ x: this.activeTab === 0 ? 1 : 0.985, y: this.activeTab === 0 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).padding({ bottom: Theme.tabInset }).accessibilityText('地图标签页')
      TabContent() {
        HdsNav({ stack: this.tripsStack, title: '旅行', content: () => { this.tripsContent() },
          destination: (name: string, parameter: Object) => { this.tripsDestination(name, parameter) }, onSettings: () => this.tripsStack.pushPathByName(Routes.Settings, new EntityRoute('')) })
      }.tabBar(this.tabStyle(Icons.trips, '旅行'))
        .opacity(this.activeTab === 1 ? 1 : 0.92)
        .scale({ x: this.activeTab === 1 ? 1 : 0.985, y: this.activeTab === 1 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).padding({ bottom: Theme.tabInset }).accessibilityText('旅行标签页')
      TabContent() {
        HdsNav({ stack: this.atlasStack, title: '足迹', content: () => { this.atlasContent() },
          destination: (name: string, parameter: Object) => { this.atlasDestination(name, parameter) }, onSettings: () => this.atlasStack.pushPathByName(Routes.Settings, new EntityRoute('')) })
      }.tabBar(this.tabStyle(Icons.atlas, '足迹'))
        .opacity(this.activeTab === 2 ? 1 : 0.92)
        .scale({ x: this.activeTab === 2 ? 1 : 0.985, y: this.activeTab === 2 ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 }).padding({ bottom: Theme.tabInset }).accessibilityText('足迹标签页')
    }.barPosition(BarPosition.End).barWidth(250).cachedMaxCount(3, TabsCacheMode.CACHE_LATEST_SWITCHED)
      .scrollable(false).vertical(false).barOverlap(true).blurStrategy(BlurStrategy.ENABLE)
      .barFloatingStyle({ barBottomMargin: 28, lightColor: $r('app.color.diff_content'),
        gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
        systemMaterialEffect: { materialType: HDS_MATERIAL_TYPE_ADAPTIVE, materialLevel: this.experience.materialLevel } })
      .onChange((index: number) => { this.activeTab = index; vibration.dotVibration(); })
      .width('100%').height('100%').backgroundColor(Theme.background)
      .bindSheet(this.sheetVisible!!, this.addVisit(), { height: SheetSize.LARGE, showClose: true,
        backgroundColor: Theme.surface, maskColor: Theme.scrim, blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS, onWillDismiss: (action: DismissSheetAction) => this.dismissSheet(action),
        onDisappear: () => { this.model.showAdd = false; this.filterOpen = false; this.draftDirty = false; this.draftSaving = false; } })
  }
}
