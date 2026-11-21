import { showToastSafely } from '../../common/safeUi';
import { Place, RecordedVisit, VisitDraft } from '../../domain/model/Atlas';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { ActionButton } from './ActionButton';
import { MoodSelector } from './MoodSelector';

@ComponentV2
export struct AddVisitSheet {
  @Require @Param model: AtlasViewModel;
  @Require @Param draft: VisitDraft;
  @Param saveVersion: number = 0;
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

  @Monitor('saveVersion')
  onSaveRequested(): void {
    if (this.saveVersion > 0) {
      this.save();
    }
  }

  @Monitor('error')
  onErrorChanged(): void {
    if (this.error) {
      showToastSafely(this.getUIContext().getPromptAction(), this.error);
    }
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

  private changed(): void {
    this.onEditingState(true, this.saving);
  }

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
      Column({ space: 14 }) {
        if (!this.draft.existingPlaceId && this.model.nearby(this.draft).length > 0) {
          Column({ space: 10 }) {
            Text('已有地点')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ink)
              .width('100%')
            ForEach(this.model.nearby(this.draft), (place: Place) => {
              ActionButton({
                label: `${this.existingId === place.id ? '已选择 · ' : ''}${place.name} · ${place.visitCount} 次`,
                highlighted: this.existingId === place.id,
                onAction: () => {
                  this.existingId = place.id;
                  this.changed();
                },
              })
            }, (place: Place) => place.id)
            ActionButton({
              label: '新地点',
              highlighted: !this.existingId,
              compact: true,
              onAction: () => {
                this.existingId = '';
                this.changed();
              },
            })
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.surface)
          .borderRadius(Theme.panelRadius)
          .border({ width: 1, color: Theme.line })
          .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
        }

        if (!this.existingId) {
          Column({ space: 10 }) {
            Text('地点信息')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor(Theme.ink)
              .width('100%')
            TextInput({ text: this.name, placeholder: '地点名称' })
              .maxLength(120)
              .backgroundColor(Theme.surfaceAlt)
              .borderRadius(Theme.pillRadius)
              .onChange((value: string) => {
                this.name = value;
                this.changed();
              })
              .id('placeName')
              .accessibilityText('地点名称')
            Row({ space: 10 }) {
              TextInput({ text: this.city, placeholder: '城市' })
                .layoutWeight(1)
                .maxLength(120)
                .backgroundColor(Theme.surfaceAlt)
                .borderRadius(Theme.pillRadius)
                .onChange((value: string) => {
                  this.city = value;
                  this.changed();
                })
                .accessibilityText('城市')
              TextInput({ text: this.country, placeholder: '国家或地区' })
                .layoutWeight(1)
                .maxLength(120)
                .backgroundColor(Theme.surfaceAlt)
                .borderRadius(Theme.pillRadius)
                .onChange((value: string) => {
                  this.country = value;
                  this.changed();
                })
                .accessibilityText('国家或地区')
            }
            TextInput({ text: this.address, placeholder: '地址（可选）' })
              .maxLength(500)
              .backgroundColor(Theme.surfaceAlt)
              .borderRadius(Theme.pillRadius)
              .onChange((value: string) => {
                this.address = value;
                this.changed();
              })
              .accessibilityText('地点地址')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Theme.surface)
          .borderRadius(Theme.panelRadius)
          .border({ width: 1, color: Theme.line })
          .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
        }

        Column({ space: 10 }) {
          Text('到访日期')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ink)
            .width('100%')
          DatePicker({ selected: new Date(this.visitedAt), end: new Date() })
            .height(110)
            .onDateChange((date: Date) => {
              this.visitedAt = Math.min(date.getTime(), Date.now());
              this.changed();
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })

        Column({ space: 14 }) {
          MoodSelector({
            value: this.mood,
            onSelect: (value: number) => {
              this.mood = value;
              this.changed();
            },
          })
          Divider().color(Theme.chartGrid)
          TextArea({ text: this.diary, placeholder: '记忆' })
            .height(140)
            .maxLength(100000)
            .backgroundColor(Theme.surfaceAlt)
            .borderRadius(Theme.pillRadius)
            .onChange((value: string) => {
              this.diary = value;
              this.changed();
            })
            .id('newDiary')
            .accessibilityText('这次到访的日记')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Theme.surface)
        .borderRadius(Theme.panelRadius)
        .border({ width: 1, color: Theme.line })
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
      }
      .padding({ left: Theme.pagePadding, right: Theme.pagePadding, top: 12, bottom: 40 })
      .width('100%')
      .enabled(!this.saving)
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Top)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    .backgroundColor(Theme.background)
  }
}
