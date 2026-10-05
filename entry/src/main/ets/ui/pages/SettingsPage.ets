import { common } from '@kit.AbilityKit';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { cancelStaggerEnterAnimation, pageTransition, startStaggerEnterAnimation } from '../../common/motion';
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
    this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 2, (step: number): void => {
      this.animStep = step;
    });
  }

  aboutToDisappear(): void {
    cancelStaggerEnterAnimation(this.enterAnimationTimers);
    this.enterAnimationTimers = [];
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          ExperiencePanel().opacity(this.animStep >= 1 ? 1 : 0).translate({ y: this.animStep >= 1 ? 0 : 20 })
          if (this.experience.error) {
            if (!this.experience.ready) {
              StatePanel({ title: '暂时无法读取体验设置', message: this.experience.error, action: '重试',
                onAction: () => this.experience.initialize(this.getUIContext().getHostContext() as common.UIAbilityContext) })
            } else { Text(this.experience.error).fontColor(Theme.muted).fontSize(13) }
          }
          Column({ space: 14 }) {
            Text('属于你的个人地图').fontSize(28).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
            Text('地点、到访和记忆保存在这台设备上。每次到访都是独立的记忆，同一个地点会随着时间积累历史。')
              .fontSize(16).fontColor(Theme.muted)
            Text('只有你点击“记录这里”时，Loci 才申请当前位置。你也可以长按地图补记，无需在现场验证。')
              .fontSize(16).fontColor(Theme.muted)
            Text('Loci 1.0 · Local Atlas').fontSize(13).fontColor(Theme.muted)
          }.width('100%').alignItems(HorizontalAlign.Start)
            .opacity(this.animStep >= 2 ? 1 : 0).translate({ y: this.animStep >= 2 ? 0 : 20 })
        }.padding(Theme.pagePadding).width('100%').alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%')
    }.titleMode(HdsNavDestinationTitleMode.MINI).transition(pageTransition())
      .titleBar(destinationTitle('设置', this.experience.materialLevel)).backgroundColor(Theme.background)
      .onActive(() => this.startEnterAnimation())
  }
}
