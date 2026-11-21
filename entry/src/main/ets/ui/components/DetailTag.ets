import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct DetailTag {
  @Require @Param label: string;
  @Require @Param value: string;
  @Local pressed: boolean = false;

  build() {
    Row({ space: 7 }) {
      Text(this.label)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(Theme.accent)
        .flexShrink(0)
        .accessibilityText(this.label)
      Scroll() {
        Row() {
          Text(this.value)
            .fontSize(12)
            .fontColor(Theme.ink)
            .maxLines(1)
            .textAlign(TextAlign.Start)
            .accessibilityText(`${this.label}${this.value}`)
        }
        .constraintSize({ minWidth: '100%' })
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .height(20)
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.None)
      .accessibilityText(`${this.label}详情，可左右滑动查看`)
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 10, right: 10, top: 7, bottom: 7 })
    .width('100%')
    .height(36)
    .borderRadius(Theme.pillRadius)
    .backgroundColor(Theme.surfaceAlt)
    .border({ width: 1, color: Theme.chartGrid })
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(
      this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
    .compositingFilter(pressLightFieldFilter(this.pressed))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .accessibilityGroup(true)
    .accessibilityText(`${this.label}，${this.value}`)
  }
}
