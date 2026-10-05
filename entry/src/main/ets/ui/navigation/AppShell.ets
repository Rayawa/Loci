import { HdsNavigation, HdsNavigationTitleMode, HdsTabs } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { MapFilters } from '../components/MapFilters';
import { common } from '@kit.AbilityKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { AddVisitSheet } from '../components/AddVisitSheet';
import { StatePanel } from '../components/StatePanel';
import { MapPage } from '../pages/MapPage';
import { PlaceDetailPage } from '../pages/PlaceDetailPage';
import { MemoryPage } from '../pages/MemoryPage';
import { SettingsPage } from '../pages/SettingsPage';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { EntityRoute, Routes } from './Routes';

@ComponentV2
export struct AppShell {
  @Local model: AtlasViewModel = new AtlasViewModel();
  @Local activeTab: number = 0;
  @Local filterOpen: boolean = false;
  @Local sheetVisible: boolean = false;
  @Local draftDirty: boolean = false;
  @Local draftSaving: boolean = false;
  private stack: NavPathStack = new NavPathStack();

  aboutToAppear(): void {
    this.initialize();
  }

  private initialize(): void {
    this.model.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext);
  }

  @Builder
  destination(name: string, parameter: Object) {
    if (name === Routes.Place) {
      PlaceDetailPage({ atlas: this.model, placeId: (parameter as EntityRoute).id, stack: this.stack })
    } else if (name === Routes.Memory) {
      MemoryPage({ atlas: this.model, visitId: (parameter as EntityRoute).id, stack: this.stack })
    } else if (name === Routes.Settings) {
      SettingsPage()
    }
  }

  @Monitor('model.showAdd')
  onAddChanged(): void {
    if (this.model.showAdd) { this.draftDirty = false; this.draftSaving = false; this.filterOpen = false; this.sheetVisible = true; }
    else if (!this.filterOpen) { this.sheetVisible = false; }
  }

  private dismissSheet(action: DismissSheetAction): void {
    if (this.draftSaving) { return; }
    if (this.filterOpen || !this.draftDirty) { action.dismiss(); return; }
    this.getUIContext().showAlertDialog({
      title: '保留这段记忆？', message: '关闭后，尚未保存的内容会丢失。',
      primaryButton: { value: '继续记录', action: () => {} },
      secondaryButton: { value: '放弃记录', action: () => action.dismiss() }
    });
  }

  @Builder
  addVisit() {
    if (this.filterOpen) {
      MapFilters({ model: this.model })
    } else if (this.model.draft) {
      AddVisitSheet({ model: this.model, draft: this.model.draft,
        onEditingState: (dirty: boolean, saving: boolean) => { this.draftDirty = dirty; this.draftSaving = saving; },
        onSaved: (record: RecordedVisit) => {
        this.stack.pushPathByName(Routes.Memory, new EntityRoute(record.visitId));
      } })
    }
  }

  build() {
    HdsNavigation(this.stack) {
      if (!this.model.loading && !this.model.ready && this.model.error) {
        StatePanel({ title: '暂时无法打开足迹', message: this.model.error, action: '重试', onAction: () => this.initialize() })
      } else {
        HdsTabs({ barPosition: BarPosition.End }) {
          TabContent() {
            MapPage({ model: this.model, stack: this.stack })
          }.tabBar('地图')
          TabContent() {
            StatePanel({ title: '旅行记忆尚未开放', message: '你的地点记忆，会成为每一段旅程的起点。' })
          }.tabBar('旅行')
          TabContent() {
            StatePanel({ title: '足迹浏览尚未开放', message: '先从一个地点开始，慢慢留下自己的世界。' })
          }.tabBar('足迹')
        }.height('100%').width('100%').barBackgroundColor(Theme.surface).scrollable(false).onChange((index: number) => { this.activeTab = index; })
      }
    }.titleBar({ content: { title: { mainTitle: 'Loci', subTitle: '你的世界，在这里留下记忆' },
      menu: { value: [{ content: { icon: new SymbolGlyphModifier($r('sys.symbol.gearshape')), label: '设置',
        action: () => this.stack.pushPathByName(Routes.Settings, new EntityRoute('')) } }] } } })
      .titleMode(HdsNavigationTitleMode.MINI).hideBackButton(true)
      .navDestination(this.destination).mode(NavigationMode.Auto)
      .toolbarConfiguration([
        { value: this.model.locating ? '正在定位' : '记录这里', symbolIcon: new SymbolGlyphModifier($r('sys.symbol.plus')),
          status: !this.model.ready || this.model.loading || this.model.locating ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL,
          action: () => this.model.recordHere() },
        { value: '当前位置', symbolIcon: new SymbolGlyphModifier($r('sys.symbol.location_north_up_right')),
          status: !this.model.ready || this.model.loading || this.model.locating ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL,
          action: () => this.model.locateOnMap() },
        { value: '筛选', status: !this.model.ready ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL, symbolIcon: new SymbolGlyphModifier($r('sys.symbol.slider_horizontal_2_square')),
          action: () => { this.filterOpen = true; this.sheetVisible = true; } }
      ]).hideToolBar(this.activeTab !== 0)
      .backgroundColor(Theme.background)
      .bindSheet(this.sheetVisible!!, this.addVisit(), { height: SheetSize.LARGE, showClose: true, backgroundColor: Theme.surface,
        onWillDismiss: (action: DismissSheetAction) => this.dismissSheet(action),
        onDisappear: () => { this.model.showAdd = false; this.filterOpen = false; this.draftDirty = false; this.draftSaving = false; } })
  }
}
