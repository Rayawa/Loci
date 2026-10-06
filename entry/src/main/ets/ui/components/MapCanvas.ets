import { ActionButton } from './ActionButton';
import { common } from '@kit.AbilityKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { MapComponent, map, mapCommon } from '@kit.MapKit';
import { Place } from '../../domain/model/Atlas';
import { PlaceMapController } from '../../service/map/PlaceMapController';
import { Theme } from '../theme/Theme';
import { showToastSafely } from '../../common/safeUi';

@ComponentV2
export struct MapCanvas {
  @Param places: Place[] = [];
  @Param selectedId: string = '';
  @Param focus: Place | undefined = undefined;
  @Param controlTop: number = 112;
  @Param presenting: boolean = true;
  @Param revealId: string = '';
  @Event onReveal: (id: string) => void = () => {};
  @Event onSelect: (id: string) => void = () => {};
  @Event onLongPress: (coordinate: mapCommon.LatLng) => void = () => {};
  @Local error: string = '';
  @Local retryKey: number = 0;
  @Local loaded: boolean = false;
  private mapController?: PlaceMapController;
  private events?: map.MapEventManager;
  private loadHandler?: () => void;
  private loadTimer: number = -1;
  private active: boolean = true;
  private revealingId: string = '';
  private options: mapCommon.MapOptions = {
    position: { target: { latitude: 39.925, longitude: 116.397 }, zoom: 11 },
    zoomControlsEnabled: false,
    dayNightMode: mapCommon.DayNightMode.AUTO
  };
  private markerClick: (marker: map.Marker) => void = (marker: map.Marker) => {
    if (!this.active || !this.loaded || !this.presenting) { return; }
    const id = this.mapController?.placeId(marker) ?? '';
    if (id) { this.onSelect(id); }
  };
  private longClick: (position: mapCommon.LatLng) => void = (position: mapCommon.LatLng) => {
    if (this.active && this.loaded && this.presenting) { this.onLongPress(position); }
  };

  private clearLoadTimer(): void {
    if (this.loadTimer !== -1) { clearTimeout(this.loadTimer); this.loadTimer = -1; }
  }
  @Monitor('error')
  onErrorChanged(): void {
    if (this.error && this.active && this.presenting) {
      showToastSafely(this.getUIContext().getPromptAction(), this.error, 2500, 'Map');
    }
  }

  private watchLoad(key: number): void {
    this.clearLoadTimer();
    this.loadTimer = setTimeout(() => {
      this.loadTimer = -1;
      if (!this.active || key !== this.retryKey || this.loaded) { return; }
      this.error = '地图暂不可用，请稍后重试。你的地点和记忆仍保存在本机。';
    }, 15000);
  }

  private callbackFor(key: number): AsyncCallback<map.MapComponentController> {
    return (error, controller) => {
      if (!this.active || key !== this.retryKey) { return; }
      if (error) {
        this.clearLoadTimer();
        this.error = '地图暂不可用。你的本地记忆仍可查看，请稍后重试';
        return;
      }
      try {
        this.mapController = new PlaceMapController(controller, this.getUIContext().getHostContext() as common.UIAbilityContext);
        this.events = controller.getEventManager();
        this.loadHandler = () => {
          if (!this.active || key !== this.retryKey || this.loaded) { return; }
          this.clearLoadTimer();
          this.loaded = true;
          this.error = '';
          // Region routing and coordinate rectification must be ready before placing flags.
          this.sync();
          const focus = this.focus ?? this.places[0];
          if (focus && (!this.revealId || focus.id !== this.revealId)) { this.focusMap(focus); }
        };
        this.events.on('mapLoad', this.loadHandler);
        this.events.on('markerClick', this.markerClick);
        this.events.on('mapLongClick', this.longClick);
      } catch (_) {
        this.clearLoadTimer();
        this.error = '暂时无法准备地图，请重试';
      }
    };
  }

  private focusMap(place: Place): void {
    if (!this.loaded) { return; }
    const key = this.retryKey;
    this.mapController?.focus(place).catch(() => {
      if (this.active && key === this.retryKey) { this.error = '暂时无法移动到这个地点，请重试'; }
    });
  }

  @Monitor('places', 'selectedId', 'revealId', 'presenting')
  onPlacesChanged(): void { this.sync(); }

  @Monitor('focus')
  onFocusChanged(): void {
    if (this.focus && (!this.revealId || this.focus.id !== this.revealId)) { this.focusMap(this.focus); }
  }

  private sync(): void {
    if (!this.loaded) { return; }
    const key = this.retryKey;
    this.mapController?.sync(this.places, this.selectedId, this.revealId).then(() => this.revealSavedPlace(key)).catch(() => {
      if (this.active && key === this.retryKey) { this.error = '地点标记暂未更新，请重试'; }
    });
  }

  private async revealSavedPlace(key: number): Promise<void> {
    const id = this.revealId;
    const controller = this.mapController;
    const place = this.places.find((item: Place) => item.id === id);
    if (!this.active || key !== this.retryKey || !this.presenting || !this.loaded || !id || !place || !controller || this.revealingId === id) { return; }
    this.revealingId = id;
    try {
      await controller.focus(place);
      if (!this.active || !this.presenting || key !== this.retryKey || controller !== this.mapController || id !== this.revealId) { return; }
      if (controller.reveal(id)) { this.onReveal(id); }
    } finally {
      if (key === this.retryKey && this.revealingId === id) { this.revealingId = ''; }
    }
  }

  private release(): void {
    this.clearLoadTimer();
    const events = this.events;
    const loadHandler = this.loadHandler;
    const controller = this.mapController;
    this.loadHandler = undefined;
    this.events = undefined;
    this.mapController = undefined;
    this.loaded = false;
    this.revealingId = '';
    // A failed native map may already be destroyed. One failed cleanup must not interrupt the others.
    const cleanup: Array<() => void> = [
      () => { if (loadHandler) { events?.off('mapLoad', loadHandler); } },
      () => { events?.off('markerClick', this.markerClick); },
      () => { events?.off('mapLongClick', this.longClick); },
      () => { controller?.dispose(); }
    ];
    cleanup.forEach((operation: () => void) => {
      try { operation(); } catch (_) { console.warn('[Loci][MapCanvas] Native map cleanup failed'); }
    });
  }

  aboutToDisappear(): void { this.active = false; this.release(); }
  aboutToAppear(): void { this.active = true; this.watchLoad(this.retryKey); }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      ForEach([this.retryKey], (key: number) => {
        MapComponent({ mapOptions: this.options, mapCallback: this.callbackFor(key) }).width('100%').height('100%')
      }, (key: number) => key.toString())
      if (this.error) {
        Column({ space: 8 }) {
          ActionButton({ label: '重试地图', highlighted: true, compact: true, onAction: () => {
            this.retryKey++;
            this.release();
            this.error = '';
            this.watchLoad(this.retryKey);
          } })
        }.padding(8).margin({ top: this.controlTop, left: Theme.pagePadding, right: Theme.pagePadding })
          .backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
      } else if (!this.loaded) {
        Row({ space: 8 }) {
          LoadingProgress().width(20).height(20).color(Theme.accent)
          Text('正在打开地图').fontSize(14).fontColor(Theme.ink)
        }.padding(Theme.pagePadding).margin({ top: this.controlTop, left: Theme.pagePadding, right: Theme.pagePadding })
          .backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
          .accessibilityText('正在打开地图')
      }
    }.width('100%').height('100%')
  }
}
