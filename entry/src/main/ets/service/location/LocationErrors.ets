import { BusinessError } from '@kit.BasicServicesKit';

// Location Kit and Map Kit fail at different stages of the same user action.
// Keep service diagnostics out of user-facing Toasts.
export function locationFailureMessage(error: BusinessError): string {
  switch (error.code) {
    case 201:
      return '需要允许精确定位，也可以长按地图选择地点';
    case 3301100:
      return '请开启系统定位服务后重试，也可以长按地图选择地点';
    case 3301000:
      return '定位服务暂不可用，请稍后重试';
    case 3301200:
      return '暂时无法获取当前位置，请稍后重试，也可以长按地图补记';
    case 1002600004:
    case 1002600013:
      return '地图尚未准备好，暂时无法确认位置，请稍后重试';
    default:
      return '暂时无法确认位置，请稍后重试，也可以长按地图补记';
  }
}
