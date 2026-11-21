import { UIContext } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { MIN_PRESS_FEEDBACK_MS } from '../../common/constants';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { Haptics } from '../../service/haptics/Haptics';
import { Theme } from '../theme/Theme';

/** 一个按压状态驱动缩放与光场；取消、离页与兜底计时均会释放。 */
@ObservedV2
export class PressInteraction {
  @Trace pressedKey: string = '';
  private startedAt: number = 0;
  private timer: number = -1;
  private context?: UIContext;

  constructor(context?: UIContext) {
    this.context = context;
  }

  attach(context: UIContext): void {
    this.context = context;
  }

  private setPressed(key: string): void {
    if (!this.context) {
      this.pressedKey = key;
      return;
    }
    try {
      this.context.animateTo({ duration: 120, curve: Curve.EaseOut }, (): void => {
        this.pressedKey = key;
      });
    } catch (_) {
      this.pressedKey = key;
    }
  }

  private clearTimer(): void {
    if (this.timer >= 0) {
      clearTimeout(this.timer);
      this.timer = -1;
    }
  }

  private begin(key: string): void {
    this.clearTimer();
    this.setPressed(key);
    this.startedAt = Date.now();
    this.timer = setTimeout((): void => this.dispose(), 800);
  }

  private release(): void {
    this.clearTimer();
    const remaining = Math.max(0, MIN_PRESS_FEEDBACK_MS - (Date.now() - this.startedAt));
    if (remaining === 0) {
      this.setPressed('');
    } else {
      this.timer = setTimeout((): void => {
        this.clearTimer();
        this.setPressed('');
      }, remaining);
    }
  }

  touch(key: string, event: TouchEvent): void {
    if (event.type === TouchType.Down) {
      this.begin(key);
    } else if (this.pressedKey === key) {
      if (event.type === TouchType.Cancel) {
        this.dispose();
      } else if (event.type === TouchType.Up) {
        this.release();
      }
    }
  }

  activate(key: string): void {
    if (this.pressedKey !== key) {
      this.begin(key);
    }
    this.release();
    Haptics.confirm();
  }

  dispose(): void {
    this.clearTimer();
    this.pressedKey = '';
  }
}

export class PressSelectStyle implements AttributeModifier<SelectAttribute> {
  private pressed: boolean;

  constructor(pressed: boolean = false) {
    this.pressed = pressed;
  }

  applyNormalAttribute(select: SelectAttribute): void {
    select
      .backgroundColor(Theme.surfaceAlt)
      .fontColor(Theme.ink)
      .optionBgColor(Theme.surface)
      .optionFontColor(Theme.accent)
      .selectedOptionBgColor(Theme.surfaceAlt)
      .selectedOptionFontColor(Theme.accent)
      .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
      .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
      .compositingFilter(pressLightFieldFilter(this.pressed));
  }
}
