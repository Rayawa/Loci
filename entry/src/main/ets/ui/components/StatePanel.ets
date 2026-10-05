import { ActionButton } from './ActionButton';
import { contentEnterTransition } from '../../common/motion';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct StatePanel {
  @Param title: string = '';
  @Param message: string = '';
  @Param loading: boolean = false;
  @Param action: string = '';
  @Event onAction: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      if (this.loading) {
        LoadingProgress().width(28).height(28).color(Theme.accent)
      }
      Text(this.title).fontSize(20).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
      Text(this.message).fontSize(14).fontColor(Theme.muted).textAlign(TextAlign.Center)
      if (this.action) {
        ActionButton({ label: this.action, highlighted: true, onAction: () => this.onAction() })
      }
    }.width('100%').padding(Theme.pagePadding).backgroundColor(Theme.surface).borderRadius(Theme.cardRadius)
      .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 }).transition(contentEnterTransition())
  }
}
