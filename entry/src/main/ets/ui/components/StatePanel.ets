import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { ActionButton } from './ActionButton';
import { contentEnterTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct StatePanel {
  @Param title: string = '';
  @Param message: string = '';
  @Param loading: boolean = false;
  @Param action: string = '';
  @Param icon: Resource | undefined = undefined;
  @Event onAction: () => void = () => {};
  @Local pressed: boolean = false;

  build() {
    Column({ space: 12 }) {
      if (this.loading) {
        LoadingProgress().width(28).height(28).color(Theme.accent)
      } else if (this.icon) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph(this.icon).fontSize(24).fontColor([Theme.accent])
        }
        .width(48)
        .height(48)
        .borderRadius(Theme.pillRadius)
        .backgroundColor(Theme.surfaceAlt)
        .border({ width: 1, color: Theme.line })
      }
      if (this.title) {
        Text(this.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor(Theme.ink).textAlign(TextAlign.Center)
      }
      if (this.message) {
        Text(this.message).fontSize(14).fontColor(Theme.muted).textAlign(TextAlign.Center)
      }
      if (this.action) {
        ActionButton({ label: this.action, highlighted: true, onAction: () => this.onAction() })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(Theme.surface)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 12, color: Theme.shadow, offsetY: 3 })
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressed))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) { this.pressed = true; }
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.pressed = false; }
    })
    .transition(contentEnterTransition())
    .accessibilityGroup(!this.action)
  }
}
