import { curves, LengthMetrics } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { ActionButton } from '../components/ActionButton';
import { Place } from '../../domain/model/Atlas';
import { MapCanvas } from '../components/MapCanvas';
import { PlaceCard } from '../components/PlaceCard';
import { PlacePreview } from '../components/PlacePreview';
import { PressInteraction } from '../components/PressInteraction';
import { RollingNumber } from '../components/RollingNumber';
import { StaggerEnter } from '../components/StaggerEnter';
import { StatePanel } from '../components/StatePanel';
import { EntityRoute, Routes } from '../navigation/Routes';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';

@ComponentV2
export struct MapPage {
  @Require @Param model: AtlasViewModel;
  @Require @Param stack: NavPathStack;
  @Param viewIndex: number = 0;
  @Param active: boolean = true;
  @Param scrollToTopVersion: number = 0;
  @Local contentWidth: number = 0;
  @Local interaction: PressInteraction = new PressInteraction();
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
  }

  aboutToDisappear(): void {
    this.interaction.dispose();
  }

  @Monitor('scrollToTopVersion')
  onScrollToTop(): void {
    if (this.scrollToTopVersion <= 0 || this.viewIndex !== 1) {
      return;
    }
    try {
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
    } catch (_) {}
  }

  private totalVisits(places: Place[]): number {
    return places.reduce((sum: number, item: Place) => sum + item.visitCount, 0);
  }

  @Builder
  placesSummary(places: Place[]) {
    GridRow({ columns: 2, gutter: { x: 10, y: 10 } }) {
      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('探索地点')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
          Row({ space: 6 }) {
            RollingNumber({
              value: places.length,
              fontSize: 24,
              color: Theme.accent,
              accessibilityLabel: '探索地点数',
            })
            Text('处')
              .fontSize(13)
              .fontColor(Theme.muted)
          }.width('100%').alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'places-sum' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'places-sum' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'places-sum', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'places-sum'))
        .onTouch((event: TouchEvent) => this.interaction.touch('places-sum', event))
        .accessibilityText(`探索地点 ${places.length} 处`)
      }

      GridCol({ span: 1 }) {
        Column({ space: 6 }) {
          Text('累计到访')
            .fontSize(12)
            .fontColor(Theme.muted)
            .width('100%')
          Row({ space: 6 }) {
            RollingNumber({
              value: this.totalVisits(places),
              fontSize: 24,
              color: Theme.accentCyan,
              accessibilityLabel: '累计到访次数',
            })
            Text('次')
              .fontSize(13)
              .fontColor(Theme.muted)
          }.width('100%').alignItems(VerticalAlign.Bottom)
        }
        .width('100%')
        .padding(14)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.cardRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
        .scale({
          x: this.interaction.pressedKey === 'visits-sum' ? 0.985 : 1,
          y: this.interaction.pressedKey === 'visits-sum' ? 0.985 : 1,
        })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
          this.interaction.pressedKey === 'visits-sum', hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'visits-sum'))
        .onTouch((event: TouchEvent) => this.interaction.touch('visits-sum', event))
        .accessibilityText(`累计到访 ${this.totalVisits(places)} 次`)
      }
    }.width('100%')
  }

  @Builder
  activeFiltersBar() {
    if (this.model.city || this.model.year) {
      Flex({
        wrap: FlexWrap.Wrap,
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center,
        space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) },
      }) {
        Row({ space: 8 }) {
          if (this.model.city) {
            Text(`城市 · ${this.model.city}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.accent)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(10)
              .backgroundColor(Theme.surfaceAlt)
              .border({ width: 1, color: Theme.line })
          }
          if (this.model.year) {
            Text(`年份 · ${this.model.year}`)
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.accent)
              .padding({ left: 10, right: 10, top: 5, bottom: 5 })
              .borderRadius(10)
              .backgroundColor(Theme.surfaceAlt)
              .border({ width: 1, color: Theme.line })
          }
        }

        Button('重置筛选', { type: ButtonType.Normal, stateEffect: false })
          .height(30)
          .padding({ left: 12, right: 12 })
          .borderRadius(10)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.onAccent)
          .backgroundColor(Theme.accent)
          .scale({
            x: this.interaction.pressedKey === 'clear-filter' ? 0.95 : 1,
            y: this.interaction.pressedKey === 'clear-filter' ? 0.95 : 1,
          })
          .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.interaction.pressedKey === 'clear-filter', hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
          .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'clear-filter'))
          .onTouch((event: TouchEvent) => this.interaction.touch('clear-filter', event))
          .onClick(() => {
            this.interaction.activate('clear-filter');
            this.model.clearFilters();
          })
          .accessibilityRole(AccessibilityRoleType.BUTTON)
          .accessibilityText('重置筛选')
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Theme.surface)
      .borderRadius(Theme.cardRadius)
      .border({ width: 1, color: Theme.line })
    }
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MapCanvas({
        places: this.model.filteredPlaces(),
        selectedId: this.model.selectedPlaceId,
        focus: this.model.focus,
        revealId: this.model.unlockPlaceId,
        presenting: this.active && this.viewIndex === 0,
        onReveal: (id: string) => this.model.markPlaceRevealed(id),
        onSelect: (id: string) => { this.model.selectedPlaceId = id; },
        onLongPress: (coordinate) => this.model.selectMap(coordinate),
      })
        .visibility(this.viewIndex === 0 ? Visibility.Visible : Visibility.Hidden)

      if (this.viewIndex === 1) {
        Scroll(this.scroller) {
          Column({ space: 14 }) {
            Blank().height(8).width('100%')
            if (this.model.filteredPlaces().length > 0) {
              this.placesSummary(this.model.filteredPlaces())
            }
            this.activeFiltersBar()
            if (this.model.filteredPlaces().length === 0) {
              if (this.model.places.length > 0) {
                StatePanel({
                  title: '没有符合筛选的地点',
                  message: '换一个城市或年份，重新看看自己的世界。',
                  icon: Icons.filter,
                  action: '显示全部地点',
                  onAction: () => this.model.clearFilters(),
                })
              } else {
                StatePanel({
                  title: '暂无地点',
                  message: '切换到地图点击右上角记录这里，或长按地图添加地点',
                  icon: Icons.map,
                })
              }
            } else {
              GridRow({ columns: this.contentWidth >= 720 ? 2 : 1, gutter: { x: 12, y: 12 } }) {
                ForEach(this.model.filteredPlaces(), (place: Place, index: number) => {
                  GridCol({ span: 1 }) {
                    StaggerEnter({
                      order: index,
                      speed: 2,
                      content: () => {
                        PlaceCard({
                          place: place,
                          onOpen: () => this.stack.pushPathByName(Routes.Place, new EntityRoute(place.id)),
                        })
                      },
                    })
                  }
                }, (place: Place) => place.id)
              }.width('100%')
            }
            Blank().height(110).width('100%')
          }
          .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
          .width('100%')
          .constraintSize({ maxWidth: Theme.contentMaxWidth })
        }
        .id('placesList')
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        .backgroundColor(Theme.background)
      }

      if (this.viewIndex === 0) {
        Column() {
          if (this.model.loading) {
            StatePanel({ title: '正在打开你的世界', loading: true })
          } else {
            if (this.model.placesError) {
              ActionButton({ label: '刷新地点', compact: true, onAction: () => this.model.retryPlaces() })
            }
            if (this.model.selectedPlace()) {
              PlacePreview({
                place: this.model.selectedPlace() as Place,
                newMemoryAvailable: this.model.recentVisit?.isNewPlace === true && this.model.recentVisit?.placeId === this.model.selectedPlaceId,
                onMemory: () => {
                  if (this.model.recentVisit) {
                    this.stack.pushPathByName(Routes.Memory, new EntityRoute(this.model.recentVisit.visitId));
                  }
                },
                revisitAvailable: !this.model.locating && !this.model.selectingMap,
                onOpen: () => this.stack.pushPathByName(Routes.Place, new EntityRoute(this.model.selectedPlaceId)),
                onRevisit: () => {
                  const place = this.model.selectedPlace();
                  if (place) {
                    this.model.revisit(place);
                  }
                },
              })
            } else if (this.model.places.length === 0) {
              StatePanel({ title: '暂无地点', icon: Icons.map })
            } else if (this.model.filteredPlaces().length === 0) {
              StatePanel({
                title: '这一段足迹还没有地点',
                message: '换一个城市或年份，重新看看自己的世界。',
                icon: Icons.filter,
                action: '显示全部地点',
                onAction: () => this.model.clearFilters(),
              })
            } else {
              Scroll() {
                Row({ space: 8 }) {
                  ForEach(this.model.filteredPlaces(), (place: Place) => {
                    Button({ type: ButtonType.Normal, stateEffect: false }) {
                      Row({ space: 8 }) {
                        Row()
                          .width(8)
                          .height(8)
                          .borderRadius(4)
                          .backgroundColor(Theme.accent)
                        Text(place.name)
                          .fontSize(13)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(Theme.ink)
                          .maxLines(1)
                        Text(`${place.visitCount}次`)
                          .fontSize(11)
                          .fontColor(Theme.accent)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                          .borderRadius(8)
                          .backgroundColor(Theme.surfaceAlt)
                      }.padding({ left: 12, right: 12, top: 8, bottom: 8 }).alignItems(VerticalAlign.Center)
                    }
                    .height(40)
                    .backgroundColor(Theme.surface)
                    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
                    .borderRadius(16)
                    .border({ width: 1, color: Theme.line })
                    .shadow({ radius: 10, color: Theme.shadow, offsetY: 3 })
                    .scale({
                      x: this.interaction.pressedKey === `chip-${place.id}` ? 0.96 : 1,
                      y: this.interaction.pressedKey === `chip-${place.id}` ? 0.96 : 1,
                    })
                    .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
                    .visualEffect(pressVisualEffect(
                      this.interaction.pressedKey === `chip-${place.id}`, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === `chip-${place.id}`))
                    .onTouch((event: TouchEvent) => this.interaction.touch(`chip-${place.id}`, event))
                    .onClick(() => {
                      this.interaction.activate(`chip-${place.id}`);
                      this.model.selectedPlaceId = place.id;
                      this.model.focus = place;
                    })
                    .accessibilityRole(AccessibilityRoleType.BUTTON)
                    .accessibilityText(`${place.name}，到访 ${place.visitCount} 次，点击定位`)
                  }, (place: Place) => place.id)
                }.padding({ top: 4, bottom: 4 })
              }
              .scrollable(ScrollDirection.Horizontal)
              .scrollBar(BarState.Off)
              .width('100%')
              .height(48)
            }
          }
        }.width('100%').padding({ top: 16, left: Theme.pagePadding, right: Theme.pagePadding, bottom: 110 })
      }
    }
    .height('100%')
    .width('100%')
    .onAreaChange((_old: Area, area: Area) => {
      this.contentWidth = Number(area.width);
    })
  }
}
