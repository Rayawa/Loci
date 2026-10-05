import { Visit } from '../../domain/model/Atlas';
import { AtlasRepository } from '../../domain/repository/AtlasRepository';
import { Haptics } from '../../service/haptics/Haptics';

@ObservedV2
export class MemoryViewModel {
  @Trace visit: Visit | undefined = undefined;
  @Trace diary: string = '';
  @Trace mood: number = 0;
  @Trace loading: boolean = true;
  @Trace saving: boolean = false;
  @Trace error: string = '';
  @Trace notice: string = '';
  private originalDiary: string = '';
  private originalMood: number = 0;

  dirty(): boolean {
    return this.diary !== this.originalDiary || this.mood !== this.originalMood;
  }

  async load(repository: AtlasRepository, visitId: string): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.visit = await repository.getVisit(visitId);
      this.diary = this.visit.diary;
      this.mood = this.visit.mood;
      this.originalDiary = this.diary;
      this.originalMood = this.mood;
    } catch (error) {
      this.error = (error as Error).message || '无法读取这段记忆';
    } finally {
      this.loading = false;
    }
  }

  async save(repository: AtlasRepository): Promise<void> {
    if (!this.visit || this.saving || !this.dirty()) {
      return;
    }
    this.saving = true;
    this.error = '';
    try {
      const diary = this.diary;
      const mood = this.mood;
      await repository.updateMemory(this.visit.id, diary, mood);
      this.originalDiary = diary;
      this.originalMood = mood;
      this.notice = '记忆已保存';
      Haptics.confirm();
    } catch (error) {
      this.error = (error as Error).message || '保存失败，内容仍在这里，请重试';
    } finally {
      this.saving = false;
    }
  }
}
