import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { map, mapCommon } from '@kit.MapKit';
import { CoordinateSystem, VisitDraft, VisitSource } from '../../domain/model/Atlas';

export interface VisitLocationSource {
  locate(includeAddress?: boolean): Promise<VisitDraft>;
  select(position: mapCommon.LatLng): Promise<VisitDraft>;
}

export class LocationService implements VisitLocationSource {
  private context: common.UIAbilityContext;
  constructor(context: common.UIAbilityContext) { this.context = context; }

  async locate(includeAddress: boolean = true): Promise<VisitDraft> {
    const permissions: Permissions[] = ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION'];
    const authorization = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(this.context, permissions);
    // Approximate-only permission is insufficient to choose a physical place reliably.
    if (authorization.authResults.length < 2 || authorization.authResults[0] !== 0 || authorization.authResults[1] !== 0) {
      throw new Error('记录当前位置需要精确定位。你也可以长按地图选择地点');
    }
    const location = await geoLocationManager.getCurrentLocation({
      priority: geoLocationManager.LocationRequestPriority.FIRST_FIX,
      timeoutMs: 10000
    });
    const draft = new VisitDraft();
    draft.source = VisitSource.CurrentLocation;
    const coordinates = await map.rectifyCoordinate(this.context, [{
      coordinateType: mapCommon.CoordinateType.WGS84,
      location: { latitude: location.latitude, longitude: location.longitude }
    }]);
    if (coordinates.length !== 1) {
      throw new Error('暂时无法确认地图坐标，请重试');
    }
    draft.latitude = coordinates[0].location.latitude;
    draft.longitude = coordinates[0].location.longitude;
    draft.coordinateSystem = coordinates[0].coordinateType === mapCommon.CoordinateType.GCJ02 ?
      CoordinateSystem.GCJ02 : CoordinateSystem.WGS84;
    if (!includeAddress) {
      return draft;
    }
    try {
      const addresses = await geoLocationManager.getAddressesFromLocation({
        latitude: location.latitude, longitude: location.longitude, maxItems: 1
      });
      if (addresses.length > 0) {
        const address = addresses[0];
        draft.name = address.placeName ?? '';
        draft.address = (address.descriptions ?? []).join(' ');
        draft.country = address.countryName ?? '';
        draft.countryCode = address.countryCode ?? '';
        draft.province = address.administrativeArea ?? '';
        draft.city = address.locality ?? address.subAdministrativeArea ?? '';
        draft.district = address.subLocality ?? '';
      }
    } catch (_) {
      // Geocoding is optional: keep the real coordinate and let the user name it.
    }
    return draft;
  }

  async select(position: mapCommon.LatLng): Promise<VisitDraft> {
    const result = await map.rectifyCoordinate(this.context, [{
      coordinateType: mapCommon.CoordinateType.GCJ02, location: position
    }]);
    if (result.length !== 1) {
      throw new Error('暂时无法确认地图坐标，请重试');
    }
    const draft = new VisitDraft();
    draft.latitude = position.latitude;
    draft.longitude = position.longitude;
    draft.coordinateSystem = result[0].coordinateType === mapCommon.CoordinateType.GCJ02 ?
      CoordinateSystem.GCJ02 : CoordinateSystem.WGS84;
    return draft;
  }
}
