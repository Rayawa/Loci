import { hdsEffect } from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Haptics } from '../../service/haptics/Haptics';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct ActionButton {
  @Require @Param label: string;
  @Param highlighted: boolean = false;
  @Param available: boolean = true;
  @Param compact: boolean = false;
  @Param haptic: boolean = true;
  @Event onAction: () => void = () => {};
  @Local pressed: boolean = false;

  build() {
    Button(this.label, { type: ButtonType.Normal, stateEffect: false })
      .width('100%').height(this.compact ? 42 : 48).borderRadius(Theme.cardRadius)
      .fontSize(this.compact ? 13 : 16)
      .fontWeight(this.highlighted ? FontWeight.Medium : FontWeight.Regular)
      .fontColor(this.highlighted ? Theme.onAccent : Theme.ink)
      .backgroundColor(this.highlighted ? Theme.accent : Theme.surfaceAlt)
      .border({ width: this.highlighted ? 0 : 1, color: Theme.line })
      .shadow(this.highlighted ? { radius: 10, color: Theme.shadow, offsetY: 2 } : { radius: 0, color: Color.Transparent })
      .enabled(this.available)
      .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
      .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
      .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 6, 96))
      .compositingFilter(pressLightFieldFilter(this.pressed))
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) { this.pressed = true; }
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.pressed = false; }
      })
      .accessibilityRole(AccessibilityRoleType.BUTTON)
      .accessibilityText(this.label)
      .onClick(() => {
        if (this.haptic) { Haptics.confirm(); }
        this.onAction();
      })
  }
}
