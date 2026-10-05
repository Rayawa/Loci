import { Theme } from '../theme/Theme';
import { hdsEffect } from '@kit.UIDesignKit';
import { Haptics } from '../../service/haptics/Haptics';

export const MOOD_NAMES: string[] = ['未记录', '低落', '疲惫', '平静', '愉快', '雀跃'];

@ComponentV2
export struct MoodSelector {
  @Param value: number = 0;
  @Event onSelect: (mood: number) => void = () => {};
  @Local pressedMood: number = 0;

  build() {
    Column({ space: 12 }) {
      Text('这一刻的心情').fontSize(14).fontColor(Theme.muted).width('100%')
      Row({ space: 6 }) {
        ForEach([1, 2, 3, 4, 5], (mood: number) => {
          Button(MOOD_NAMES[mood], { type: ButtonType.Normal, stateEffect: false })
            .layoutWeight(1).height(42).borderRadius(14).fontSize(13)
            .backgroundColor(this.value === mood ? Theme.accent : Theme.background)
            .fontColor(this.value === mood ? Color.White : Theme.ink)
            .accessibilityText(`${MOOD_NAMES[mood]}${this.value === mood ? '，已选择' : ''}`)
            .visualEffect(new hdsEffect.HdsEffectBuilder().pressShadow(this.pressedMood === mood ?
              hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE).buildEffect())
            .onTouch((event: TouchEvent) => { this.pressedMood = event.type === TouchType.Down ? mood : 0; })
            .onClick(() => { this.onSelect(this.value === mood ? 0 : mood); Haptics.confirm(); })
        }, (mood: number) => mood.toString())
      }.width('100%')
    }.width('100%')
  }
}
