import { STAGGER_ENTER_DELAY_MS, STAGGER_ENTER_INTERVAL_MS } from '../../common/constants';
import { contentEnterTransition, runPageEnterAnimation } from '../../common/motion';

/** 每次挂载只播放一次；列表延迟封顶，避免长列表等待过久。 */
@ComponentV2
export struct StaggerEnter {
  @BuilderParam content: () => void = this.emptyContent;
  @Param order: number = 0;
  @Param speed: number = 1;
  @Local entered: boolean = false;
  private timer: number = -1;

  @Builder
  emptyContent(): void {}

  private start(): void {
    this.entered = false;
    if (this.timer >= 0) {
      clearTimeout(this.timer);
    }
    this.timer = setTimeout((): void => {
      this.timer = -1;
      runPageEnterAnimation(this.getUIContext(), (): void => {
        this.entered = true;
      }, this.speed);
    }, (STAGGER_ENTER_DELAY_MS + Math.min(6, Math.max(0, this.order)) * STAGGER_ENTER_INTERVAL_MS) / this.speed);
  }

  aboutToDisappear(): void {
    if (this.timer >= 0) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
  }

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .opacity(this.entered ? 1 : 0)
    .translate({ y: this.entered ? 0 : 18 })
    .transition(contentEnterTransition(10, this.speed))
    .onAppear((): void => this.start())
  }
}
