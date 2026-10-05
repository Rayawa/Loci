import { Theme } from '../theme/Theme';
import { ActionButton } from './ActionButton';
import { Haptics } from '../../service/haptics/Haptics';

export const MOOD_NAMES: string[] = ['未记录', '低落', '疲惫', '平静', '愉快', '雀跃'];

@ComponentV2
export struct MoodSelector {
  @Param value: number = 0;
  @Event onSelect: (mood: number) => void = () => {};

  build() {
    Column({ space: 12 }) {
      Text('这一刻的心情').fontSize(14).fontColor(Theme.muted).width('100%')
      Row({ space: 6 }) {
        ForEach([1, 2, 3, 4, 5], (mood: number) => {
          ActionButton({ label: MOOD_NAMES[mood], highlighted: this.value === mood, compact: true,
            onAction: () => { this.onSelect(this.value === mood ? 0 : mood); Haptics.confirm(); } })
            .layoutWeight(1).accessibilityText(`${MOOD_NAMES[mood]}${this.value === mood ? '，已选择' : ''}`)
        }, (mood: number) => mood.toString())
      }.width('100%')
    }.width('100%')
  }
}
