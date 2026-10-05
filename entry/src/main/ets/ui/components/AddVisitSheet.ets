import { ActionButton } from './ActionButton';
import { Place, RecordedVisit, VisitDraft } from '../../domain/model/Atlas';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { MoodSelector } from './MoodSelector';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct AddVisitSheet {
  @Require @Param model: AtlasViewModel;
  @Require @Param draft: VisitDraft;
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
    try {
      this.onSaved(await this.model.save(this.draft));
    } catch (error) {
      this.error = (error as Error).message || '保存失败，内容已保留，请重试';
    } finally {
      this.saving = false;
      this.onEditingState(true, false);
    }
  }

  build() {
    Scroll() {
      Column({ space: 18 }) {
        Text(this.existingId ? '再次来到这里' : '在这里留下记忆').fontSize(26).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
        Text('地点承载时间，每次到访都是新的记忆。').fontSize(14).fontColor(Theme.muted)
        if (!this.draft.existingPlaceId && this.model.nearby(this.draft).length > 0) {
          Text('附近已有地点，你可以选择再次到访').fontSize(13).fontColor(Theme.muted)
          ForEach(this.model.nearby(this.draft), (place: Place) => {
            ActionButton({ label: `${this.existingId === place.id ? '已选择 · ' : ''}${place.name} · ${place.visitCount} 次`,
              highlighted: this.existingId === place.id, onAction: () => { this.existingId = place.id; this.changed(); } })
          }, (place: Place) => place.id)
          ActionButton({ label: '记录为一个新地点', onAction: () => { this.existingId = ''; this.changed(); } })
        }
        if (!this.existingId) {
          TextInput({ text: this.name, placeholder: '给这个地点一个名字' }).maxLength(120).onChange((value: string) => { this.name = value; this.changed(); })
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
        TextArea({ text: this.diary, placeholder: '此刻想记住什么？' }).height(140).maxLength(100000)
          .onChange((value: string) => { this.diary = value; this.changed(); }).id('newDiary').accessibilityText('这次到访的日记')
        if (this.error) {
          Text(this.error).fontColor(Theme.ink).fontSize(14)
        }
        ActionButton({ label: this.saving ? '正在保存…' : '保存这段记忆', highlighted: true,
          available: !this.saving, onAction: () => this.save() }).id('saveVisit')
      }.padding({ left: Theme.pagePadding, right: Theme.pagePadding, top: 20, bottom: 36 }).width('100%').enabled(!this.saving)
    }.width('100%').height('100%').backgroundColor(Theme.surface)
  }
}
