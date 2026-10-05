import { vibration } from '../../common/vibration';

// Loci emits business events; feedback comes from Dashboard's unchanged implementation.
export class Haptics {
  static confirm(): void { vibration.dotVibration(); }
  static back(): void { vibration.backVibration(); }
  static error(): void { vibration.errorVibration(); }
}
