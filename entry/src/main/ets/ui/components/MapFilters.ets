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
        Button('全部城市').width('100%').backgroundColor(this.model.city ? Theme.background : Theme.accent)
          .fontColor(this.model.city ? Theme.ink : Color.White).onClick(() => this.model.city = '')
        ForEach(this.cities(), (city: string) => {
          Button(city).width('100%').backgroundColor(this.model.city === city ? Theme.accent : Theme.background)
            .fontColor(this.model.city === city ? Color.White : Theme.ink).onClick(() => this.model.city = city)
        }, (city: string) => city)
        Text('年份').fontSize(15).fontColor(Theme.muted).width('100%')
        Button('全部年份').width('100%').backgroundColor(this.model.year ? Theme.background : Theme.accent)
          .fontColor(this.model.year ? Theme.ink : Color.White).onClick(() => this.model.year = '')
        ForEach(this.years(), (year: string) => {
          Button(year).width('100%').backgroundColor(this.model.year === year ? Theme.accent : Theme.background)
            .fontColor(this.model.year === year ? Color.White : Theme.ink).onClick(() => this.model.year = year)
        }, (year: string) => year)
        Text(`当前显示 ${this.model.filteredPlaces().length} 个地点`).fontSize(14).fontColor(Theme.muted)
      }.padding(24).width('100%')
    }.height('100%').width('100%').backgroundColor(Theme.surface)
  }
}
