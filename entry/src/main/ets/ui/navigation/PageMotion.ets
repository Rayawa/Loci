import { UIContext } from '@kit.ArkUI';
import { runPageEnterAnimation } from '../../common/motion';

@ObservedV2
export class PageMotion {
  @Trace visible: boolean = false;
  private timer: number = -1;

  prepare(): void { this.stop(); this.visible = false; }
  enter(context: UIContext): void {
    this.prepare();
    this.timer = setTimeout(() => {
      this.timer = -1;
      runPageEnterAnimation(context, () => { this.visible = true; });
    }, 0);
  }
  stop(): void {
    if (this.timer >= 0) { clearTimeout(this.timer); this.timer = -1; }
  }
}
