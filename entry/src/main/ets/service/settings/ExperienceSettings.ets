import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { deviceInfo } from '@kit.BasicServicesKit';

export enum ExperienceOption {
  Vibration = 'vibrationLevel', LightField = 'lightFieldLevel', Material = 'immersiveMaterialLevel'
}

@ObservedV2
export class ExperienceSettings {
  static readonly shared: ExperienceSettings = new ExperienceSettings();
  @Trace vibrationLevel: number = 1;
  @Trace lightFieldLevel: number = 1;
  @Trace materialLevel: number = 1;
  @Trace ready: boolean = false;
  @Trace error: string = '';
  private store?: preferences.Preferences;
  private opening?: Promise<void>;
  private writes: Promise<void> = Promise.resolve();

  initialize(context: common.Context): Promise<void> {
    if (!this.opening) { this.opening = this.open(context); }
    return this.opening;
  }

  private async open(context: common.Context): Promise<void> {
    try {
      this.store = await preferences.getPreferences(context, 'loci-experience');
      this.vibrationLevel = this.level(await this.store.get(ExperienceOption.Vibration, 1));
      this.lightFieldLevel = this.level(await this.store.get(ExperienceOption.LightField, 1));
      this.materialLevel = this.level(await this.store.get(ExperienceOption.Material, 1));
      AppStorage.setOrCreate(ExperienceOption.Vibration, this.vibrationLevel);
      AppStorage.setOrCreate(ExperienceOption.LightField, this.lightFieldLevel);
      AppStorage.setOrCreate(ExperienceOption.Material, this.materialLevel);
      this.ready = true;
      this.error = '';
    } catch (_) {
      this.error = '暂时无法读取体验设置，请重试';
      this.opening = undefined;
    }
  }

  private level(value: preferences.ValueType): number {
    return typeof value === 'number' && Number.isInteger(value) && value >= 0 && value <= 2 ? value : 1;
  }

  static supportsHdr(): boolean { return deviceInfo.sdkApiVersion >= 24; }

  update(option: ExperienceOption, value: number): void {
    if (!this.ready || !Number.isInteger(value) || value < 0 || value > 2) { return; }
    if (option === ExperienceOption.LightField && value === 2 && !ExperienceSettings.supportsHdr()) { value = 1; }
    if (option === ExperienceOption.Vibration) { this.vibrationLevel = value; }
    else if (option === ExperienceOption.LightField) { this.lightFieldLevel = value; }
    else { this.materialLevel = value; }
    AppStorage.setOrCreate(option, value);
    const captured = value;
    this.writes = this.writes.then(async () => {
      if (!this.store) { throw new Error('设置未就绪'); }
      await this.store.put(option, captured);
      await this.store.flush();
      this.error = '';
    }).catch(() => { this.error = '本次设置已应用，但暂时无法保存，重启后可能恢复原值'; });
  }
}
