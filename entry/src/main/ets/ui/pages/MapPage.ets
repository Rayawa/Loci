import { Place } from '../../domain/model/Atlas';
import { MapCanvas } from '../components/MapCanvas';
import { PlacePreview } from '../components/PlacePreview';
import { StatePanel } from '../components/StatePanel';
import { EntityRoute, Routes } from '../navigation/Routes';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';

@ComponentV2
export struct MapPage {
  @Require @Param model: AtlasViewModel;
  @Require @Param stack: NavPathStack;

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      MapCanvas({ places: this.model.filteredPlaces(), selectedId: this.model.selectedPlaceId, focus: this.model.focus,
        onSelect: (id: string) => { this.model.selectedPlaceId = id; },
        onLongPress: (coordinate) => this.model.selectMap(coordinate) })
      Column() {
        if (this.model.loading) {
          StatePanel({ title: '正在打开你的世界', loading: true })
        } else {
          if (this.model.error) {
            Text(this.model.error).fontSize(13).fontColor(Theme.ink).padding(14).backgroundColor(Theme.surface).borderRadius(16)
          }
          if (this.model.selectedPlace()) {
            PlacePreview({ place: this.model.selectedPlace() as Place,
              onOpen: () => this.stack.pushPathByName(Routes.Place, new EntityRoute(this.model.selectedPlaceId)),
              onRevisit: () => {
                const place = this.model.selectedPlace();
                if (place) {
                  this.model.revisit(place);
                }
              } })
          } else if (this.model.places.length === 0) {
            StatePanel({ title: '世界很大，记忆从这里开始', message: '记录此刻所在的地点，或长按地图补记曾经到过的地方。' })
          } else {
            Scroll() {
              Row({ space: 8 }) {
                ForEach(this.model.filteredPlaces(), (place: Place) => {
                  Button(`${place.name} · ${place.visitCount}`)
                    .backgroundColor(Theme.surface).fontColor(Theme.ink).onClick(() => {
                      this.model.selectedPlaceId = place.id;
                      this.model.focus = place;
                    })
                }, (place: Place) => place.id)
              }
            }.scrollable(ScrollDirection.Horizontal).width('100%').height(44)
          }

        }
      }.width('100%').padding({ top: 16, left: 18, right: 18, bottom: 18 })
    }.height('100%').width('100%')
  }
}
