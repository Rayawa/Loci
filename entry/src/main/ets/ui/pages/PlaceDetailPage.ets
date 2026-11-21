import { curves } from '@kit.ArkUI';
import { hdsEffect, HdsNavDestination, HdsNavDestinationTitleMode, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Place, Visit } from '../../domain/model/Atlas';
import { AppLifecycle } from '../../service/app/AppLifecycle';
import { Haptics } from '../../service/haptics/Haptics';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { DetailTag } from '../components/DetailTag';
import { MapCanvas } from '../components/MapCanvas';
import { PressInteraction } from '../components/PressInteraction';
import { RollingNumber } from '../components/RollingNumber';
import { StaggerEnter } from '../components/StaggerEnter';
import { StatePanel } from '../components/StatePanel';
import { VisitCard } from '../components/VisitCard';
import { PageMotion } from '../navigation/PageMotion';
import { EntityRoute, Routes } from '../navigation/Routes';
import { destinationActions, PageAction } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { PlaceHistoryViewModel } from '../viewmodel/PlaceHistoryViewModel';

@ComponentV2
export struct PlaceDetailPage {
  @Local lifecycle: AppLifecycle = AppLifecycle.shared;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param placeId: string;
  @Require @Param stack: NavPathStack;
  @Local model: PlaceHistoryViewModel = new PlaceHistoryViewModel();
  @Local motion: PageMotion = new PageMotion();
  @Local activeMap: boolean = false;
  @Local tab: number = 0;
  @Local contentWidth: number = 0;
  @Local interaction: PressInteraction = new PressInteraction();
  private tabsController: HdsTabsController = new HdsTabsController();

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
  }

  aboutToDisappear(): void {
    this.motion.stop();
    this.interaction.dispose();
  }

  private load(): void {
    this.model.load(this.atlas.getRepository(), this.placeId);
  }

  private actions(): PageAction[] {
    return [{
      label: '到访',
      icon: Icons.add,
      isEnabled: !!this.model.place && !this.atlas.locating && !this.atlas.selectingMap && !this.atlas.showAdd,
      action: () => {
        if (this.model.place) {
          this.atlas.revisit(this.model.place);
        }
      },
    }];
  }

  private locationSubtitle(place: Place): string {
    return [place.city, place.country].filter((part: string) => part.length > 0).join(' · ') || '我的地点';
  }

  @Builder
  identityCard(place: Place) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(Icons.flag).fontSize(22).fontColor([Theme.accent])
      }
      .width(46)
      .height(46)
      .borderRadius(12)
      .backgroundColor(Theme.surfaceAlt)
      .border({ width: 1, color: Theme.line })
      .flexShrink(0)

      Column({ space: 4 }) {
        Text(place.name)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ink)
          .width('100%')
        Text(this.locationSubtitle(place))
          .fontSize(14)
          .fontColor(Theme.muted)
          .width('100%')
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
    .scale({
      x: this.interaction.pressedKey === 'identity' ? 0.985 : 1,
      y: this.interaction.pressedKey === 'identity' ? 0.985 : 1,
    })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(
      this.interaction.pressedKey === 'identity', hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'identity'))
    .onTouch((event: TouchEvent) => this.interaction.touch('identity', event))
  }

  @Builder
  bentoMetrics(place: Place) {
    GridRow({ columns: 2, gutter: { x: 10, y: 10 } }) {
      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('到访次数').fontSize(12).fontColor(Theme.muted).width('100%')
          Row({ space: 6 }) {
            RollingNumber({ value: place.visitCount, fontSize: 24, color: Theme.accent, accessibilityLabel: '到访次数' })
            Text('次').fontSize(13).fontColor(Theme.muted)
          }.width('100%').alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
        .scale({
          x: this.interaction.pressedKey === 'metric-visits' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'metric-visits' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'metric-visits', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'metric-visits'))
        .onTouch((event: TouchEvent) => this.interaction.touch('metric-visits', event))
      }

      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('足迹年份').fontSize(12).fontColor(Theme.muted).width('100%')
          Row({ space: 6 }) {
            RollingNumber({ value: place.visitedYears.length, fontSize: 24, color: Theme.accentPurple, accessibilityLabel: '足迹年份数' })
            Text('年').fontSize(13).fontColor(Theme.muted)
          }.width('100%').alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
        .scale({
          x: this.interaction.pressedKey === 'metric-years' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'metric-years' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'metric-years', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'metric-years'))
        .onTouch((event: TouchEvent) => this.interaction.touch('metric-years', event))
      }
    }.width('100%')
  }

  @Builder
  detailTagsCard(place: Place) {
    if (place.address || place.firstVisitedAt || place.lastVisitedAt) {
      Column({ space: 10 }) {
        Text('地点档案')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor(Theme.ink)
          .width('100%')
        if (place.firstVisitedAt) {
          DetailTag({ label: '首次到访', value: new Date(place.firstVisitedAt).toLocaleDateString() })
        }
        if (place.lastVisitedAt) {
          DetailTag({ label: '最近到访', value: new Date(place.lastVisitedAt).toLocaleDateString() })
        }
        if (place.address) {
          DetailTag({ label: '详细地址', value: place.address })
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Theme.surface)
      .borderRadius(Theme.panelRadius)
      .border({ width: 1, color: Theme.line })
      .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
    }
  }

  @Builder
  mapCard(place: Place) {
    MapCanvas({
      places: [place],
      focus: place,
      selectedId: this.placeId,
      controlTop: 14,
      presenting: this.lifecycle.foreground && this.activeMap && this.tab === 0 && !this.atlas.showAdd,
    })
      .height(240)
      .clip(true)
      .borderRadius(Theme.panelRadius)
      .border({ width: 1, color: Theme.line })
      .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
  }

  @Builder
  overview() {
    Scroll() {
      if (this.model.place) {
        if (this.contentWidth >= Theme.wideBreakpoint) {
          Row({ space: 16 }) {
            Column({ space: 14 }) {
              this.identityCard(this.model.place)
              this.bentoMetrics(this.model.place)
              this.detailTagsCard(this.model.place)
            }.layoutWeight(5)

            Column({ space: 14 }) {
              this.mapCard(this.model.place)
            }.layoutWeight(5)
          }
          .width('100%')
          .constraintSize({ maxWidth: Theme.contentMaxWidth })
          .padding(Theme.pagePadding)
          .alignItems(VerticalAlign.Top)
        } else {
          Column({ space: 14 }) {
            this.identityCard(this.model.place)
            this.mapCard(this.model.place)
            this.bentoMetrics(this.model.place)
            this.detailTagsCard(this.model.place)
            Blank().height(24).width('100%')
          }
          .width('100%')
          .constraintSize({ maxWidth: Theme.contentMaxWidth })
          .padding(Theme.pagePadding)
        }
      }
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }

  @Builder
  history() {
    List({ space: 12 }) {
      if (!this.model.visits.length) {
        ListItem() {
          StatePanel({ title: '暂无到访', message: '点击右上角 + 记录一次来到这里的足迹', icon: Icons.flag })
        }
      }
      ForEach(this.model.visits, (visit: Visit, index: number) => {
        ListItem() {
          StaggerEnter({
            order: index,
            speed: 2,
            content: () => {
              VisitCard({
                visit: visit,
                onOpen: () => this.stack.pushPathByName(Routes.Memory, new EntityRoute(visit.id)),
              })
            },
          })
        }
      }, (visit: Visit) => visit.id)
      ListItem() {
        Row().height(40).width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .padding(Theme.pagePadding)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .accessibilityText('到访记录列表')
  }

  build() {
    HdsNavDestination() {
      Column() {
        Blank().height(8).width('100%')
        if (this.model.loading) {
          Column() {
            StatePanel({ title: '正在读取地点', loading: true })
          }.width('100%').padding(Theme.pagePadding)
        } else if (this.model.error) {
          Column() {
            StatePanel({ title: '暂时无法读取', message: this.model.error, action: '重试', onAction: () => this.load() })
          }.width('100%').padding(Theme.pagePadding)
        } else {
          HdsTabs({ controller: this.tabsController, index: this.tab }) {
            TabContent() { this.overview() }.tabBar(SubTabBarStyle.of('地点'))
            TabContent() { this.history() }.tabBar(SubTabBarStyle.of('到访记录'))
          }
          .barPosition(BarPosition.Start)
          .barMode(BarMode.Fixed)
          .onTabBarClick((index: number) => { this.tabsController.changeIndex(index); })
          .onChange((index: number) => { this.tab = index; Haptics.confirm(); })
          .layoutWeight(1)
          .width('100%')
          .accessibilityText('地点详情视图')
        }
      }
      .width('100%')
      .height('100%')
      .opacity(this.motion.visible ? 1 : 0)
      .translate({ y: this.motion.visible ? 0 : 12 })
      .onAreaChange((_old: Area, area: Area) => { this.contentWidth = Number(area.width); })
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .titleBar(destinationActions('地点', this.experience.materialLevel, this.actions()))
    .onWillShow(() => this.motion.prepare())
    .onShown(() => { this.activeMap = true; this.load(); this.motion.enter(this.getUIContext()); })
    .onHidden(() => { this.activeMap = false; this.motion.stop(); })
    .onBackPressed(() => { Haptics.back(); return false; })
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
