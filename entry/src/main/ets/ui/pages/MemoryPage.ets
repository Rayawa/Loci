import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';
import { showToastSafely } from '../../common/safeUi';
import { Haptics } from '../../service/haptics/Haptics';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { MoodSelector } from '../components/MoodSelector';
import { StatePanel } from '../components/StatePanel';
import { PageMotion } from '../navigation/PageMotion';
import { destinationActions, PageAction } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { MemoryViewModel } from '../viewmodel/MemoryViewModel';

@ComponentV2
export struct MemoryPage {
  @Local motion: PageMotion = new PageMotion();
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param visitId: string;
  @Require @Param stack: NavPathStack;
  @Local model: MemoryViewModel = new MemoryViewModel();

  aboutToDisappear(): void {
    this.motion.stop();
  }

  @Monitor('model.error', 'model.notice')
  onUserMessage(): void {
    const message = this.model.error || this.model.notice;
    if (message) {
      showToastSafely(this.getUIContext().getPromptAction(), message);
    }
  }

  aboutToAppear(): void {
    this.model.load(this.atlas.getRepository(), this.visitId);
  }

  private onBack(): boolean {
    Haptics.back();
    if (this.model.saving) {
      return true;
    }
    if (!this.model.dirty()) {
      return false;
    }
    this.getUIContext().showAlertDialog({
      title: '保留这段记忆？',
      message: '还有尚未保存的修改。',
      primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃修改', action: () => this.stack.pop() },
    });
    return true;
  }

  private actions(): PageAction[] {
    return [{
      label: '保存',
      icon: Icons.save,
      isEnabled: !this.model.saving && !this.model.loading && !!this.model.visit && this.model.dirty(),
      action: () => this.model.save(this.atlas.getRepository()),
    }];
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Blank().height(8).width('100%')
          if (this.model.loading) {
            StatePanel({ title: '打开这段记忆', loading: true })
          } else if (!this.model.visit) {
            StatePanel({
              title: '暂时无法读取',
              message: this.model.error,
              action: '重试',
              onAction: () => this.model.load(this.atlas.getRepository(), this.visitId),
            })
          } else {
            Column({ space: 14 }) {
              Row({ space: 8 }) {
                SymbolGlyph(Icons.journal).fontSize(16).fontColor([Theme.accent])
                Text(this.model.visit.localDate)
                  .fontSize(17)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Theme.ink)
                  .layoutWeight(1)
              }.width('100%')

              Divider().color(Theme.chartGrid)

              MoodSelector({
                value: this.model.mood,
                onSelect: (value: number) => { this.model.mood = value; },
              }).enabled(!this.model.saving)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })

            Column({ space: 10 }) {
              Row() {
                Text('记忆正文')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Theme.ink)
                  .layoutWeight(1)
                Text(`${this.model.diary.length} 字`)
                  .fontSize(12)
                  .fontColor(Theme.muted)
              }.width('100%')

              TextArea({ text: this.model.diary, placeholder: '记忆' })
                .height(320)
                .maxLength(100000)
                .backgroundColor(Theme.surfaceAlt)
                .borderRadius(Theme.pillRadius)
                .onChange((value: string) => {
                  this.model.diary = value;
                  this.model.notice = '';
                })
                .enabled(!this.model.saving)
                .id('memoryDiary')
                .accessibilityText('日记正文')
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 10, color: Theme.shadow, offsetY: 2 })
          }
          Blank().height(110).width('100%')
        }
        .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
        .width('100%')
        .constraintSize({ maxWidth: Theme.contentMaxWidth })
      }
      .opacity(this.motion.visible ? 1 : 0)
      .translate({ y: this.motion.visible ? 0 : 12 })
      .height('100%')
      .width('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .backgroundColor(Theme.background)
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .titleBar(destinationActions('记忆', this.experience.materialLevel, this.actions()))
    .onBackPressed(() => this.onBack())
    .onWillShow(() => this.motion.prepare())
    .onShown(() => this.motion.enter(this.getUIContext()))
    .onHidden(() => this.motion.stop())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
