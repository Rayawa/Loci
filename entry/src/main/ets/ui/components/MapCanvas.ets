import { ActionButton } from './ActionButton';
import { common } from '@kit.AbilityKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { MapComponent, map, mapCommon } from '@kit.MapKit';
import { Place } from '../../domain/model/Atlas';
import { PlaceMapController } from '../../service/map/PlaceMapController';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct MapCanvas {
  @Param places: Place[] = [];
  @Param selectedId: string = '';
  @Param focus: Place | undefined = undefined;
  @Event onSelect: (id: string) => void = () => {};
  @Event onLongPress: (coordinate: mapCommon.LatLng) => void = () => {};
  @Local error: string = '';
  @Local retryKey: number = 0;
  private mapController?: PlaceMapController;
  private events?: map.MapEventManager;
  private active: boolean = true;
  private options: mapCommon.MapOptions = {
    position: { target: { latitude: 39.925, longitude: 116.397 }, zoom: 11 },
    zoomControlsEnabled: false,
    dayNightMode: mapCommon.DayNightMode.AUTO
  };
  private markerClick: (marker: map.Marker) => void = (marker: map.Marker) => {
    const id = this.mapController?.placeId(marker) ?? '';
    if (id) {
      this.onSelect(id);
    }
  };
  private longClick: (position: mapCommon.LatLng) => void = (position: mapCommon.LatLng) => this.onLongPress(position);
  private callbackFor(key: number): AsyncCallback<map.MapComponentController> {
    return (error, controller) => {
      if (!this.active || key !== this.retryKey) { return; }
      if (error) {
        this.error = '地图暂不可用。你的本地记忆仍可查看，请稍后重试';
        return;
      }
      this.error = '';
      this.mapController = new PlaceMapController(controller, this.getUIContext().getHostContext() as common.UIAbilityContext);
      this.events = controller.getEventManager();
      this.events.on('markerClick', this.markerClick);
      this.events.on('mapLongClick', this.longClick);
      this.sync();
      if (this.focus) {
        this.focusMap(this.focus);
      } else if (this.places.length > 0) {
        this.focusMap(this.places[0]);
      }
    };
  }

  private focusMap(place: Place): void {
    this.mapController?.focus(place).catch(() => { this.error = '暂时无法移动到这个地点，请重试'; });
  }

  @Monitor('places', 'selectedId')
  onPlacesChanged(): void {
    this.sync();
  }

  @Monitor('focus')
  onFocusChanged(): void {
    if (this.focus) {
      this.focusMap(this.focus);
    }
  }

  private sync(): void {
    this.mapController?.sync(this.places, this.selectedId).catch(() => {
      this.error = '地点标记暂未更新，请重试';
    });
  }

  private release(): void {
    this.events?.off('markerClick', this.markerClick);
    this.events?.off('mapLongClick', this.longClick);
    this.mapController?.dispose();
    this.events = undefined;
    this.mapController = undefined;
  }

  aboutToDisappear(): void {
    this.active = false;
    this.release();
  }

  aboutToAppear(): void { this.active = true; }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      ForEach([this.retryKey], () => {
        MapComponent({ mapOptions: this.options, mapCallback: this.callbackFor(this.retryKey) }).width('100%').height('100%')
      }, (key: number) => key.toString())
      if (this.error) {
        Column({ space: 8 }) {
          Text(this.error).fontSize(14).fontColor(Theme.ink)
          ActionButton({ label: '重试地图', highlighted: true, onAction: () => {
            this.release();
            this.error = '';
            this.retryKey++;
          } })
        }.padding(Theme.pagePadding).margin({ top: 90, left: 24, right: 24 }).backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
      }
    }.width('100%').height('100%')
  }
}
