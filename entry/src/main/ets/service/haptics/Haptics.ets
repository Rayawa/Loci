import { vibrator } from '@kit.SensorServiceKit';

export class Haptics {
  static async confirm(): Promise<void> {
    try {
      await vibrator.startVibration({ type: 'time', duration: 18 }, { usage: 'touch' });
    } catch (_) {
      // A failed or unsupported haptic must never turn a committed memory into a failed save.
    }
  }
}
