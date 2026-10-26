import { DrawableDescriptor } from '@kit.ArkUI';

@ComponentV2
export struct AppIcon {
  @Param iconSize: number = 100;
  @Local drawable: DrawableDescriptor | undefined = undefined;
  aboutToAppear(): void {
    try {
      this.drawable = this.getUIContext().getHostContext()?.resourceManager.getDrawableDescriptor($r('app.media.layered_image').id);
    } catch (_) { this.drawable = undefined; }
  }
  build() {
    Stack() {
      if (this.drawable) { Image(this.drawable).width(this.iconSize).height(this.iconSize).objectFit(ImageFit.Contain) }
      else {
        Image($r('app.media.app_icon_background')).width(this.iconSize).height(this.iconSize)
        Image($r('app.media.app_icon_foreground')).width(this.iconSize).height(this.iconSize)
      }
    }.width(this.iconSize).height(this.iconSize).borderRadius(this.iconSize * 0.22).clip(true).accessibilityText('时迹图标')
  }
}
