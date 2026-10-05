import { ActionButton } from '../components/ActionButton';
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
            StatePanel({ title: '暂时无法完成', message: this.model.error, action: '刷新地点',
              onAction: () => this.model.retryPlaces() })
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
          } else if (this.model.filteredPlaces().length === 0) {
            StatePanel({ title: '这一段足迹还没有地点', message: '换一个城市或年份，重新看看自己的世界。',
              action: '显示全部地点', onAction: () => this.model.clearFilters() })
          } else {
            Scroll() {
              Row({ space: 8 }) {
                ForEach(this.model.filteredPlaces(), (place: Place) => {
                  ActionButton({ label: `${place.name} · ${place.visitCount}`, compact: true,
                    onAction: () => { this.model.selectedPlaceId = place.id; this.model.focus = place; } }).width(160)
                }, (place: Place) => place.id)
              }
            }.scrollable(ScrollDirection.Horizontal).width('100%').height(44)
          }

        }
      }.width('100%').padding({ top: 16, left: Theme.pagePadding, right: Theme.pagePadding, bottom: Theme.pagePadding })
    }.height('100%').width('100%')
  }
}
