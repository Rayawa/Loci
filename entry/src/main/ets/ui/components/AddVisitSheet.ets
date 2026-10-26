import { ActionButton } from './ActionButton';
import { showToastSafely } from '../../common/safeUi';
import { Place, RecordedVisit, VisitDraft } from '../../domain/model/Atlas';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { MoodSelector } from './MoodSelector';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct AddVisitSheet {
  @Require @Param model: AtlasViewModel;
  @Require @Param draft: VisitDraft;
  @Param saveVersion: number = 0;
  @Monitor('saveVersion')
  onSaveRequested(): void { if (this.saveVersion > 0) { this.save(); } }
  @Event onSaved: (record: RecordedVisit) => void = () => {};
  @Event onEditingState: (dirty: boolean, saving: boolean) => void = () => {};
  @Local name: string = '';
  @Local city: string = '';
  @Local country: string = '';
  @Local address: string = '';
  @Local diary: string = '';
  @Local mood: number = 0;
  @Local visitedAt: number = Date.now();
  @Local existingId: string = '';
  @Local saving: boolean = false;
  @Local error: string = '';
  @Monitor('error')
  onErrorChanged(): void {
    if (this.error) { showToastSafely(this.getUIContext().getPromptAction(), this.error); }
  }

  aboutToAppear(): void {
    this.name = this.draft.name;
    this.city = this.draft.city;
    this.country = this.draft.country;
    this.address = this.draft.address;
    this.existingId = this.draft.existingPlaceId;
    this.visitedAt = this.draft.visitedAt;
    this.diary = this.draft.diary;
    this.mood = this.draft.mood;
  }

  private changed(): void { this.onEditingState(true, this.saving); }

  private async save(): Promise<void> {
    if (this.saving) {
      return;
    }
    this.saving = true;
    this.onEditingState(true, true);
    this.error = '';
    this.draft.name = this.name;
    this.draft.city = this.city;
    this.draft.country = this.country;
    this.draft.address = this.address;
    this.draft.existingPlaceId = this.existingId;
    this.draft.diary = this.diary;
    this.draft.mood = this.mood;
    this.draft.visitedAt = this.visitedAt;
    this.draft.utcOffsetMinutes = -new Date(this.visitedAt).getTimezoneOffset();
    try {
      this.onSaved(await this.model.save(this.draft));
    } catch (error) {
      this.error = (error as Error).message || '保存失败';
    } finally {
      this.saving = false;
      this.onEditingState(true, false);
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        if (!this.draft.existingPlaceId && this.model.nearby(this.draft).length > 0) {
          Text('已有地点').fontSize(13).fontColor(Theme.muted)
          ForEach(this.model.nearby(this.draft), (place: Place) => {
            ActionButton({ label: `${this.existingId === place.id ? '已选择 · ' : ''}${place.name} · ${place.visitCount} 次`,
              highlighted: this.existingId === place.id, onAction: () => { this.existingId = place.id; this.changed(); } })
          }, (place: Place) => place.id)
          ActionButton({ label: '新地点', onAction: () => { this.existingId = ''; this.changed(); } })
        }
        if (!this.existingId) {
          TextInput({ text: this.name, placeholder: '地点名称' }).maxLength(120).onChange((value: string) => { this.name = value; this.changed(); })
            .id('placeName').accessibilityText('地点名称')
          Row({ space: 10 }) {
            TextInput({ text: this.city, placeholder: '城市' }).layoutWeight(1).maxLength(120).onChange((value: string) => { this.city = value; this.changed(); })
              .accessibilityText('城市')
            TextInput({ text: this.country, placeholder: '国家或地区' }).layoutWeight(1).maxLength(120).onChange((value: string) => { this.country = value; this.changed(); })
              .accessibilityText('国家或地区')
          }
          TextInput({ text: this.address, placeholder: '地址（可选）' }).maxLength(500).onChange((value: string) => { this.address = value; this.changed(); })
            .accessibilityText('地点地址')
        }
        Text('到访日期').fontSize(14).fontColor(Theme.muted).width('100%')
        DatePicker({ selected: new Date(this.visitedAt), end: new Date() }).height(110)
          .onDateChange((date: Date) => { this.visitedAt = Math.min(date.getTime(), Date.now()); this.changed(); })
        MoodSelector({ value: this.mood, onSelect: (value: number) => { this.mood = value; this.changed(); } })
        TextArea({ text: this.diary, placeholder: '记忆' }).height(140).maxLength(100000)
          .onChange((value: string) => { this.diary = value; this.changed(); }).id('newDiary').accessibilityText('这次到访的日记')

      }.padding({ left: Theme.pagePadding, right: Theme.pagePadding, top: 100, bottom: 40 }).width('100%').enabled(!this.saving)
    }.width('100%').height('100%').backgroundColor(Theme.surface)
  }
}
