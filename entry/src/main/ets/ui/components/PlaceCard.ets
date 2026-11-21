import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Place } from '../../domain/model/Atlas';
import { Haptics } from '../../service/haptics/Haptics';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct PlaceCard {
  @Require @Param place: Place;
  @Event onOpen: () => void = () => {};
  @Local pressed: boolean = false;

  private subtitle(): string {
    const location = [this.place.city, this.place.country]
      .filter((part: string) => part.length > 0)
      .join(' · ') || '我的地点';
    if (this.place.lastVisitedAt) {
      return `${location} · 最近 ${new Date(this.place.lastVisitedAt).toLocaleDateString()}`;
    }
    return location;
  }

  build() {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        SymbolGlyph(Icons.flag)
          .fontSize(20)
          .fontColor([Theme.accent])
      }
      .width(44)
      .height(44)
      .borderRadius(12)
      .backgroundColor(Theme.surfaceAlt)
      .border({ width: 1, color: Theme.line })
      .flexShrink(0)

      Column({ space: 4 }) {
        Text(`${this.place.name} · ${this.place.visitCount} 次到访`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Theme.ink)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        Text(this.subtitle())
          .fontSize(12)
          .fontColor(Theme.muted)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')

        if (this.place.visitedYears.length > 0) {
          Row({ space: 6 }) {
            ForEach(this.place.visitedYears.slice(0, 3), (year: string) => {
              Text(year)
                .fontSize(11)
                .fontColor(Theme.accent)
                .padding({ left: 7, right: 7, top: 2, bottom: 2 })
                .borderRadius(6)
                .backgroundColor(Theme.surfaceAlt)
            }, (year: string) => year)
          }.width('100%')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Image($r('app.media.profile_right'))
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .accessibilityLevel('no')
    }
    .width('100%')
    .padding(14)
    .borderRadius(Theme.cardRadius)
    .backgroundColor(Theme.surface)
    .border({ width: 1, color: Theme.line })
    .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressed))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick((): void => {
      Haptics.confirm();
      this.onOpen();
    })
    .accessibilityRole(AccessibilityRoleType.BUTTON)
    .accessibilityText(`${this.place.name}，到访 ${this.place.visitCount} 次，${this.subtitle()}，点击查看详情`)
  }
}
