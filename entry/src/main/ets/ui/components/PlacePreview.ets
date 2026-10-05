import { ActionButton } from './ActionButton';
import { contentEnterTransition } from '../../common/motion';
import { Place } from '../../domain/model/Atlas';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct PlacePreview {
  @Require @Param place: Place;
  @Event onOpen: () => void = () => {};
  @Event onRevisit: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      Row() {
        Column({ space: 6 }) {
          Text(this.place.name).fontSize(22).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
          Text(`${this.place.city || '我的地点'} · 来过 ${this.place.visitCount} 次`).fontSize(13).fontColor(Theme.muted)
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        ActionButton({ label: '查看记忆', compact: true, onAction: () => this.onOpen() }).width(96)
      }.width('100%')
      Row() {
        Text(this.place.lastVisitedAt ? `最近到访 ${new Date(this.place.lastVisitedAt).toLocaleDateString()}` : '还没有到访记录')
          .fontSize(12).fontColor(Theme.muted).layoutWeight(1)
        ActionButton({ label: '再次来到这里', compact: true, highlighted: true, onAction: () => this.onRevisit() }).width(130)
      }.width('100%')
    }.padding(Theme.pagePadding).backgroundColor(Theme.surface).borderRadius(Theme.cardRadius).width('100%').shadow({ radius: 8, color: Theme.shadow, offsetY: 2 }).transition(contentEnterTransition())
  }
}
