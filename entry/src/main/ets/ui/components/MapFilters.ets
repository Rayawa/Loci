import { ActionButton } from './ActionButton';
import { Place } from '../../domain/model/Atlas';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';

@ComponentV2
export struct MapFilters {
  @Require @Param model: AtlasViewModel;

  private cities(): string[] {
    return Array.from(new Set<string>(this.model.places.map((place: Place) => place.city).filter((city: string) => city.length > 0))).sort();
  }

  private years(): string[] {
    const years = new Set<string>();
    this.model.places.forEach((place: Place) => place.visitedYears.forEach((year: string) => years.add(year)));
    return Array.from(years).sort().reverse();
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text('回到某一段足迹').fontSize(26).fontColor(Theme.ink)
        Text('城市').fontSize(15).fontColor(Theme.muted).width('100%')
        ActionButton({ label: '全部城市', highlighted: !this.model.city, onAction: () => this.model.city = '' })
        ForEach(this.cities(), (city: string) => {
          ActionButton({ label: city, highlighted: this.model.city === city, onAction: () => this.model.city = city })
        }, (city: string) => city)
        Text('年份').fontSize(15).fontColor(Theme.muted).width('100%')
        ActionButton({ label: '全部年份', highlighted: !this.model.year, onAction: () => this.model.year = '' })
        ForEach(this.years(), (year: string) => {
          ActionButton({ label: year, highlighted: this.model.year === year, onAction: () => this.model.year = year })
        }, (year: string) => year)
        Text(`当前显示 ${this.model.filteredPlaces().length} 个地点`).fontSize(14).fontColor(Theme.muted)
      }.padding(Theme.pagePadding).width('100%')
    }.height('100%').width('100%').backgroundColor(Theme.surface)
  }
}
