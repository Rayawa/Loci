import { hdsEffect } from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { Activity } from '../../domain/model/Activity';
import { dayClockText } from '../../domain/service/ActivityRules';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct ActivityCard {
  @Require @Param record: Activity;
  @Param placeName: string = '';
  @Event onOpen: () => void = () => {};
  @Local pressed: boolean = false;
  private time(): string {
    return `${dayClockText(this.record.startMinute)}${this.record.endMinute !== this.record.startMinute ? `–${dayClockText(this.record.endMinute)}` : ''}`;
  }
  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row({ space: 10 }) {
        Text('•').fontSize(16).fontColor(Theme.muted)
        Text() {
          Span(`${this.time()}  `).fontColor(Theme.muted)
          Span(this.record.title).fontColor(Theme.ink)
        }.fontSize(16).lineHeight(25).layoutWeight(1).textAlign(TextAlign.Start)
      }.width('100%').padding({ left: 4, right: 4, top: 8, bottom: 8 }).alignItems(VerticalAlign.Top)
    }.width('100%').backgroundColor(Color.Transparent).borderRadius(8)
      .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
      .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
      .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT))
      .compositingFilter(pressLightFieldFilter(this.pressed))
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) { this.pressed = true; }
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.pressed = false; }
      }).onClick(() => this.onOpen()).accessibilityText(`${this.time()} ${this.record.title}，编辑`)
  }
}
