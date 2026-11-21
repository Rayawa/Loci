import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { contentEnterTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Visit } from '../../domain/model/Atlas';
import { Haptics } from '../../service/haptics/Haptics';
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
        Row({ space: 8 }) {
          SymbolGlyph(Icons.journal)
            .fontSize(15)
            .fontColor([Theme.accent])
          Text(this.visit.localDate)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ink)
            .layoutWeight(1)
          if (this.visit.mood) {
            Text(MOOD_NAMES[this.visit.mood])
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.accent)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .borderRadius(8)
              .backgroundColor(Theme.surfaceAlt)
          }
          Text('›')
            .fontSize(18)
            .fontColor(Theme.muted)
            .accessibilityLevel('no')
        }.width('100%').alignItems(VerticalAlign.Center)

        Text(this.visit.diary || '还没有写下文字，打开这段记忆继续记录。')
          .fontSize(15)
          .lineHeight(22)
          .fontColor(this.visit.diary ? Theme.ink : Theme.muted)
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }.padding(Theme.pagePadding).width('100%').alignItems(HorizontalAlign.Start)
    }
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.cardRadius)
    .border({ width: 1, color: Theme.line })
    .width('100%')
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressed))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`${this.visit.localDate}的记忆，${MOOD_NAMES[this.visit.mood]}，${this.visit.diary ? '有日记' : '尚无日记'}`)
    .onClick(() => {
      Haptics.confirm();
      this.onOpen();
    })
    .transition(contentEnterTransition())
    .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
  }
}
