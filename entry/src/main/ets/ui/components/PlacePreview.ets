import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { contentEnterTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Place } from '../../domain/model/Atlas';
import { Theme } from '../theme/Theme';
import { ActionButton } from './ActionButton';

@ComponentV2
export struct PlacePreview {
  @Require @Param place: Place;
  @Param revisitAvailable: boolean = true;
  @Param newMemoryAvailable: boolean = false;
  @Event onMemory: () => void = () => {};
  @Event onOpen: () => void = () => {};
  @Event onRevisit: () => void = () => {};
  @Local pressed: boolean = false;

  build() {
    Column({ space: 12 }) {
      Row({ space: 12 }) {
        Stack({ alignContent: Alignment.Center }) {
          SymbolGlyph(Icons.flag).fontSize(20).fontColor([Theme.accent])
        }
        .width(42)
        .height(42)
        .borderRadius(12)
        .backgroundColor(Theme.surfaceAlt)
        .border({ width: 1, color: Theme.line })
        .flexShrink(0)

        Column({ space: 4 }) {
          Text(this.place.name)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Theme.ink)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(`${this.place.city || '我的地点'} · 来过 ${this.place.visitCount} 次`)
            .fontSize(13)
            .fontColor(Theme.muted)
            .maxLines(1)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)

        ActionButton({
          label: this.newMemoryAvailable ? '继续写记忆' : '查看记忆',
          compact: true,
          onAction: () => {
            if (this.newMemoryAvailable) {
              this.onMemory();
            } else {
              this.onOpen();
            }
          },
        })
          .width(this.newMemoryAvailable ? 112 : 96)
      }.width('100%').alignItems(VerticalAlign.Center)

      Divider().color(Theme.chartGrid)

      Row({ space: 10 }) {
        Text(this.place.lastVisitedAt ? `最近到访 ${new Date(this.place.lastVisitedAt).toLocaleDateString()}` : '还没有到访记录')
          .fontSize(12)
          .fontColor(Theme.muted)
          .layoutWeight(1)
        ActionButton({
          label: '再次来到这里',
          compact: true,
          highlighted: true,
          available: this.revisitAvailable,
          onAction: () => this.onRevisit(),
        }).width(130)
      }.width('100%').alignItems(VerticalAlign.Center)
    }
    .padding(16)
    .backgroundColor(Theme.surface)
    .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    .borderRadius(Theme.panelRadius)
    .border({ width: 1, color: Theme.line })
    .width('100%')
    .shadow({ radius: 16, color: Theme.shadow, offsetY: 4 })
    .scale({ x: this.pressed ? 0.99 : 1, y: this.pressed ? 0.99 : 1 })
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
    .transition(contentEnterTransition())
  }
}
