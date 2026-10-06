import { Icons } from '../../common/icons';
import { common } from '@kit.AbilityKit';
import { map, mapCommon } from '@kit.MapKit';
import { CoordinateSystem, Place } from '../../domain/model/Atlas';
import { CONTENT_ENTER_DURATION_MS } from '../../common/constants';

export class PlaceMapController {
  private markers: Map<string, map.Marker> = new Map();
  private identities: Map<string, string> = new Map();
  private queue: Promise<void> = Promise.resolve();
  private disposed: boolean = false;
  private revealed: Set<string> = new Set();

  private controller: map.MapComponentController;
  private context: common.UIAbilityContext;
  constructor(controller: map.MapComponentController, context: common.UIAbilityContext) {
    this.controller = controller; this.context = context;
  }

  placeId(marker: map.Marker): string {
    return this.identities.get(marker.getId()) ?? '';
  }

  sync(places: Place[], selectedId: string, revealId: string = ''): Promise<void> {
    this.queue = this.queue.catch(() => {}).then(async () => {
      if (this.disposed) {
        return;
      }
      const ids = new Set<string>(places.map((place: Place) => place.id));
      this.markers.forEach((marker: map.Marker, placeId: string) => {
        if (!ids.has(placeId)) {
          marker.remove();
          this.identities.delete(marker.getId());
          this.markers.delete(placeId);
        }
      });
      for (const place of places) {
        if (this.disposed) {
          return;
        }
        let marker = this.markers.get(place.id);
        if (!marker) {
          const positions = await map.rectifyCoordinate(this.context, [{
            coordinateType: place.coordinateSystem === CoordinateSystem.GCJ02 ? mapCommon.CoordinateType.GCJ02 : mapCommon.CoordinateType.WGS84,
            location: { latitude: place.latitude, longitude: place.longitude }
          }]);
          if (this.disposed) {
            return;
          }
          if (positions.length !== 1) {
            throw new Error('地点坐标暂不可用');
          }
          marker = await this.controller.addMarker({
            position: positions[0].location,
            title: place.name,
            snippet: `来到这里 ${place.visitCount} 次`,
            clickable: true,
            visible: place.id !== revealId,
            icon: Icons.marker,
            anchorU: 0.22, anchorV: 1
          });
          if (this.disposed) {
            marker.remove();
            return;
          }
          this.markers.set(place.id, marker);
          this.identities.set(marker.getId(), place.id);
        }
        const visible = place.id !== revealId || this.revealed.has(place.id);
        marker.setVisible(visible);
        marker.setSnippet(`来到这里 ${place.visitCount} 次${place.id === selectedId ? ' · 已选择' : ''}`);
        marker.setZIndex(place.id === selectedId ? 10 : 1);
        if (visible && place.id === selectedId) {
          marker.setInfoWindowVisible(true);
        } else {
          marker.setInfoWindowVisible(false);
        }
      }
    });
    return this.queue;
  }

  async focus(place: Place): Promise<void> {
    if (this.disposed) { return; }
    const positions = await map.rectifyCoordinate(this.context, [{
      coordinateType: place.coordinateSystem === CoordinateSystem.GCJ02 ? mapCommon.CoordinateType.GCJ02 : mapCommon.CoordinateType.WGS84,
      location: { latitude: place.latitude, longitude: place.longitude }
    }]);
    if (!this.disposed && positions.length === 1) {
      await this.controller.animateCameraStatus(map.newLatLng(positions[0].location, 15), 500);
    }
  }

  reveal(id: string): boolean {
    const marker = this.markers.get(id);
    if (this.disposed || !marker) { return false; }
    marker.setVisible(true);
    if (!this.revealed.has(id)) {
      try {
        const animation = new map.AlphaAnimation(0.2, 1);
        animation.setDuration(CONTENT_ENTER_DURATION_MS);
        animation.setFillMode(map.AnimationFillMode.FORWARDS);
        animation.setRepeatCount(0);
        marker.setAnimation(animation);
        marker.startAnimation();
      } catch (_) { console.warn('[Loci][PlaceMapController] Flag animation unavailable; marker remains visible'); }
      this.revealed.add(id);
    }
    return true;
  }

  dispose(): void {
    this.disposed = true;
    this.markers.forEach((marker: map.Marker) => {
      try { marker.remove(); } catch (_) { console.warn('[Loci][PlaceMapController] Native marker cleanup failed'); }
    });
    this.markers.clear();
    this.identities.clear();
    this.revealed.clear();
  }
}
