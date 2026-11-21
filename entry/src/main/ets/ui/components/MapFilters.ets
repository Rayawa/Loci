import { curves, LengthMetrics } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Place } from '../../domain/model/Atlas';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { ActionButton } from './ActionButton';
import { PressInteraction } from './PressInteraction';

@ComponentV2
export struct MapFilters {
  @Require @Param model: AtlasViewModel;
  @Local interaction: PressInteraction = new PressInteraction();

  aboutToAppear(): void {
    this.interaction.attach(this.getUIContext());
  }

  aboutToDisappear(): void {
    this.interaction.dispose();
  }

  private cities(): string[] {
    return Array.from(new Set<string>(this.model.places.map((place: Place) => place.city).filter((city: string) => city.length > 0))).sort();
  }

  private years(): string[] {
    const years = new Set<string>();
    this.model.places.forEach((place: Place) => place.visitedYears.forEach((year: string) => years.add(year)));
    return Array.from(years).sort().reverse();
  }

  @Builder
  filterChip(key: string, label: string, selected: boolean, onSelect: () => void) {
    Button(label, { type: ButtonType.Normal, stateEffect: false })
      .height(36)
      .padding({ left: 14, right: 14 })
      .borderRadius(Theme.pillRadius)
      .fontSize(13)
      .fontWeight(selected ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(selected ? Theme.onAccent : Theme.ink)
      .backgroundColor(selected ? Theme.accent : Theme.surfaceAlt)
      .border({ width: selected ? 0 : 1, color: Theme.line })
      .scale({
        x: this.interaction.pressedKey === key ? 0.96 : 1,
        y: this.interaction.pressedKey === key ? 0.96 : 1,
      })
      .animation({ duration: 120, curve: curves.springMotion(0.35, 0.9) })
      .visualEffect(pressVisualEffect(
        this.interaction.pressedKey === key, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
      .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === key))
      .onTouch((event: TouchEvent) => this.interaction.touch(key, event))
      .onClick(() => {
        this.interaction.activate(key);
        onSelect();
      })
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityText(`${label}${selected ? '，已选择' : ''}`)
  }

  build() {
    Scroll() {
      Column({ space: 14 }) {
        Column({ space: 12 }) {
          Text('按城市筛选')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ink)
            .width('100%')
          Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
            this.filterChip('city-all', '全部城市', !this.model.city, () => { this.model.city = ''; })
            ForEach(this.cities(), (city: string) => {
              this.filterChip(`city-${city}`, city, this.model.city === city, () => { this.model.city = city; })
            }, (city: string) => city)
          }.width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

        Column({ space: 12 }) {
          Text('按年份筛选')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ink)
            .width('100%')
          Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(8) } }) {
            this.filterChip('year-all', '全部年份', !this.model.year, () => { this.model.year = ''; })
            ForEach(this.years(), (year: string) => {
              this.filterChip(`year-${year}`, year, this.model.year === year, () => { this.model.year = year; })
            }, (year: string) => year)
          }.width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

        Column({ space: 12 }) {
          Text(`当前显示 ${this.model.filteredPlaces().length} 个地点`)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.muted)
            .width('100%')
            .textAlign(TextAlign.Center)
          if (this.model.city || this.model.year) {
            ActionButton({
              label: '清除全部筛选',
              compact: true,
              onAction: () => this.model.clearFilters(),
            })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

        Blank().height(24).width('100%')
      }
      .padding({ top: 12, left: Theme.pagePadding, right: Theme.pagePadding, bottom: 16 })
      .width('100%')
    }
    .height('100%')
    .width('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(Theme.background)
  }
}
