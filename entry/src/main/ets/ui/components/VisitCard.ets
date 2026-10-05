import { hdsEffect } from '@kit.UIDesignKit';
import { Visit } from '../../domain/model/Atlas';
import { MOOD_NAMES } from './MoodSelector';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct VisitCard {
  @Require @Param visit: Visit;
  @Event onOpen: () => void = () => {};
  @Local pressed: boolean = false;

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Column({ space: 10 }) {
        Row() {
          Text(this.visit.localDate).fontSize(17).fontWeight(FontWeight.Medium).fontColor(Theme.ink).layoutWeight(1)
          if (this.visit.mood) {
            Text(MOOD_NAMES[this.visit.mood]).fontSize(12).fontColor(Theme.accent)
          }
        }.width('100%')
        Text(this.visit.diary || '还没有写下文字，打开这段记忆继续记录。').fontSize(15).fontColor(Theme.muted)
          .maxLines(4).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
      }.padding(20).width('100%').alignItems(HorizontalAlign.Start)
    }.backgroundColor(Theme.surface).borderRadius(22).width('100%')
      .visualEffect(new hdsEffect.HdsEffectBuilder().pressShadow(this.pressed ?
        hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE).buildEffect())
      .onTouch((event: TouchEvent) => { this.pressed = event.type === TouchType.Down; })
      .accessibilityText(`${this.visit.localDate}的记忆，${MOOD_NAMES[this.visit.mood]}，${this.visit.diary ? '有日记' : '尚无日记'}`)
      .onClick(() => this.onOpen())
  }
}
