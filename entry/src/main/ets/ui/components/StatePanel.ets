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
        Button(this.action).onClick(() => this.onAction()).backgroundColor(Theme.accent)
      }
    }.width('100%').padding(24).backgroundColor(Theme.surface).borderRadius(24)
  }
}
