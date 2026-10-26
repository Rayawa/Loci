import { AppIcon } from '../components/AppIcon';
import { common } from '@kit.AbilityKit';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { cancelStaggerEnterAnimation, pageTransition, startStaggerEnterAnimation } from '../../common/motion';
import { APP_VERSION, LIST_PAGE_HORIZONTAL_PADDING, LIST_SECTION_SPACING, LIST_SECTION_TITLE_START_PADDING } from '../../common/constants';
import { showToastSafely } from '../../common/safeUi';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { ExperiencePanel } from '../components/ExperiencePanel';
import { StatePanel } from '../components/StatePanel';
import { destinationTitle } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct SettingsPage {
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local animStep: number = 0;
  private enterAnimationTimers: number[] = [];

  private startEnterAnimation(): void {
    cancelStaggerEnterAnimation(this.enterAnimationTimers);
    this.animStep = 0;
    this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 3, (step: number): void => {
      this.animStep = step;
    });
  }

  @Monitor('experience.error')
  onErrorChanged(): void {
    if (this.experience.error) { showToastSafely(this.getUIContext().getPromptAction(), this.experience.error); }
  }

  aboutToDisappear(): void { cancelStaggerEnterAnimation(this.enterAnimationTimers); this.enterAnimationTimers = []; }

  @Builder appIdentity() {
    Column({ space: 8 }) {
      AppIcon({ iconSize: 100 }).margin({ bottom: 10 })
      Text('时迹').fontSize(30).fontWeight(800).fontColor(Theme.accent).textAlign(TextAlign.Center)
      Text('每日时间记录').fontSize(20).fontWeight(600).fontColor(Theme.muted).textAlign(TextAlign.Center)
    }.width('100%').padding({ top: 18, bottom: 18, left: 12, right: 12 })
      .opacity(this.animStep >= 1 ? 1 : 0).translate({ y: this.animStep >= 1 ? 0 : 20 })
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: LIST_SECTION_SPACING }) {
          Blank().height(100).width('100%')
          this.appIdentity()
          Divider().color($r('app.color.border'))
          Column({ space: 8 }) {
            Text('设置').fontSize(14).fontWeight(FontWeight.Bold).fontColor(Theme.accent)
              .width('100%').padding({ left: LIST_SECTION_TITLE_START_PADDING })
            ExperiencePanel()
            if (!this.experience.ready && this.experience.error) {
              StatePanel({ title: '暂时无法读取设置', action: '重试',
                onAction: () => this.experience.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
            }
          }.width('100%').opacity(this.animStep >= 2 ? 1 : 0).translate({ y: this.animStep >= 2 ? 0 : 20 })
          Divider().color($r('app.color.border'))
          Column({ space: 5 }) {
            Text(`版本 ${APP_VERSION}`).fontSize(12).fontColor(Theme.muted)
            Text('Designed & Developed by Ray Chen (Rayawa)').fontSize(12).fontColor(Theme.muted).textAlign(TextAlign.Center)
            Text('Copyright © 2026. All rights reserved.').fontSize(12).fontColor(Theme.muted).textAlign(TextAlign.Center)
          }.width('100%').padding({ top: 14 }).opacity(this.animStep >= 3 ? 1 : 0)
            .translate({ y: this.animStep >= 3 ? 0 : 20 })
          Blank().height(110).width('100%')
        }.padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
          .width('100%').constraintSize({ maxWidth: 1440 })
      }.width('100%').height('100%').scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }.titleMode(HdsNavDestinationTitleMode.MINI).transition(pageTransition())
      .titleBar(destinationTitle('设置', this.experience.materialLevel)).backgroundColor(Theme.background)
      .width('100%').height('100%')
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      .onActive(() => this.startEnterAnimation())
  }
}
