import { hdsEffect } from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { Activity } from '../../domain/model/Activity';
import { categoryName, dayClockText, durationText } from '../../domain/service/ActivityRules';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Haptics } from '../../service/haptics/Haptics';
import { categoryColor } from '../theme/ActivityStyle';
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

  private spanMinutes(): number {
    return Math.max(0, this.record.endMinute - this.record.startMinute);
  }

  build() {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row({ space: 10 }) {
        Stack({ alignContent: Alignment.Center }) {
          Row()
            .width(10)
            .height(10)
            .borderRadius(5)
            .backgroundColor(categoryColor(this.record.categoryId))
        }
        .width(18)
        .height(18)
        .borderRadius(9)
        .backgroundColor(Theme.surfaceAlt)
        .margin({ top: 3 })
        .flexShrink(0)

        Column({ space: 4 }) {
          Row({ space: 6 }) {
            Text(this.time())
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor(Theme.muted)
            if (this.spanMinutes() > 0) {
              Text(durationText(this.spanMinutes()))
                .fontSize(11)
                .fontColor(Theme.muted)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .borderRadius(6)
                .backgroundColor(Theme.surfaceAlt)
            }
            Text(categoryName(this.record.categoryId))
              .fontSize(11)
              .fontWeight(FontWeight.Medium)
              .fontColor(categoryColor(this.record.categoryId))
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
              .backgroundColor(Theme.surfaceAlt)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Text(this.record.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Theme.ink)
            .lineHeight(22)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Start)
            .width('100%')

          if (this.record.note.trim().length > 0) {
            Text(this.record.note.trim())
              .fontSize(12)
              .fontColor(Theme.muted)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('›')
          .fontSize(18)
          .fontColor(Theme.muted)
          .accessibilityLevel('no')
      }
      .width('100%')
      .padding({ left: 10, right: 10, top: 10, bottom: 10 })
      .alignItems(VerticalAlign.Top)
    }
    .id('activity-' + this.record.id)
    .width('100%')
    .backgroundColor(this.pressed ? Theme.surfaceAlt : Color.Transparent)
    .borderRadius(14)
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT))
    .compositingFilter(pressLightFieldFilter(this.pressed))
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      Haptics.confirm();
      this.onOpen();
    })
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`${this.time()} ${this.record.title}，${categoryName(this.record.categoryId)}，点击编辑`)
  }
}
