import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { initializeSettings, getAllSettings, getUsername, setUsername, setVibrationLevel, setLightFieldLevel,
  setImmersiveMaterialLevel } from '../../common/storage';

export enum ExperienceOption {
  Vibration = 'vibrationLevel', LightField = 'lightFieldLevel', Material = 'immersiveMaterialLevel'
}

@ObservedV2
export class ExperienceSettings {
  static readonly shared: ExperienceSettings = new ExperienceSettings();
  @Trace vibrationLevel: number = 1;
  @Trace lightFieldLevel: number = 1;
  @Trace materialLevel: number = 1;
  @Trace username: string = '';
  @Trace ready: boolean = false;
  @Trace error: string = '';
  private opening?: Promise<void>;
  private writes: Promise<void> = Promise.resolve();

  initialize(context: common.Context): Promise<void> {
    if (!this.opening) { this.opening = this.open(context); }
    return this.opening;
  }

  private async open(context: common.Context): Promise<void> {
    try {
      initializeSettings(context);
      const settings = await getAllSettings();
      this.vibrationLevel = settings.vibrationLevel;
      this.lightFieldLevel = settings.lightFieldLevel;
      this.materialLevel = settings.immersiveMaterialLevel;
      this.username = await getUsername();
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

  static supportsHdr(): boolean { return deviceInfo.sdkApiVersion >= 24; }

  updateUsername(value: string): void {
    if (!this.ready) { return; }
    const captured = value.trim();
    this.username = captured;
    this.writes = this.writes.then(() => setUsername(captured)).catch(() => {
      this.error = '暂时无法保存用户名，请重试';
    });
  }

  update(option: ExperienceOption, value: number): void {
    if (!this.ready || !Number.isInteger(value) || value < 0 || value > 2) { return; }
    if (option === ExperienceOption.LightField && value === 2 && !ExperienceSettings.supportsHdr()) { value = 1; }
    if (option === ExperienceOption.Vibration) { this.vibrationLevel = value; }
    else if (option === ExperienceOption.LightField) { this.lightFieldLevel = value; }
    else { this.materialLevel = value; }
    const captured = value;
    this.writes = this.writes.then(async () => {
      if (option === ExperienceOption.Vibration) { await setVibrationLevel(captured); }
      else if (option === ExperienceOption.LightField) { await setLightFieldLevel(captured); }
      else { await setImmersiveMaterialLevel(captured); }
      this.error = '';
    }).catch(() => { this.error = '本次设置已应用，但暂时无法保存，重启后可能恢复原值'; });
  }
}
