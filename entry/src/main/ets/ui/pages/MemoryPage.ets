import { destinationTitle } from '../theme/NavigationStyle';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { MoodSelector } from '../components/MoodSelector';
import { StatePanel } from '../components/StatePanel';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { MemoryViewModel } from '../viewmodel/MemoryViewModel';

@ComponentV2
export struct MemoryPage {
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param visitId: string;
  @Require @Param stack: NavPathStack;
  @Local model: MemoryViewModel = new MemoryViewModel();

  aboutToAppear(): void {
    this.model.load(this.atlas.getRepository(), this.visitId);
  }

  private onBack(): boolean {
    if (this.model.saving) {
      return true;
    }
    if (!this.model.dirty()) {
      return false;
    }
    this.getUIContext().showAlertDialog({
      title: '保留这段记忆？', message: '还有尚未保存的修改。',
      primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃修改', action: () => this.stack.pop() }
    });
    return true;
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 24 }) {
          if (this.model.loading) {
            StatePanel({ title: '打开这段记忆', loading: true })
          } else if (!this.model.visit) {
            StatePanel({ title: '暂时无法读取', message: this.model.error, action: '重试',
              onAction: () => this.model.load(this.atlas.getRepository(), this.visitId) })
          } else {
            Text(this.model.visit.localDate).fontSize(30).fontWeight(FontWeight.Medium).fontColor(Theme.ink).width('100%')
            Text('每次来到这里，都有不同的心境。').fontSize(14).fontColor(Theme.muted).width('100%')
            MoodSelector({ value: this.model.mood, onSelect: (value: number) => { this.model.mood = value; } }).enabled(!this.model.saving)
            TextArea({ text: this.model.diary, placeholder: '写下想要留下的片段…' }).height(320).maxLength(100000)
              .onChange((value: string) => { this.model.diary = value; this.model.notice = ''; })
              .enabled(!this.model.saving).id('memoryDiary').accessibilityText('日记正文')
            if (this.model.error || this.model.notice) {
              Text(this.model.error || this.model.notice).fontColor(Theme.ink).fontSize(14)
            }

          }
        }.padding(Theme.pagePadding).width('100%')
      }.height('100%').width('100%').backgroundColor(Theme.background)
    }.titleMode(HdsNavDestinationTitleMode.MINI).transition(pageTransition()).titleBar(destinationTitle('这一段记忆', this.experience.materialLevel)).onBackPressed(() => this.onBack())
      .toolbarConfiguration([{ value: this.model.saving ? '正在保存…' : '保存记忆',
        symbolIcon: Icons.modifier(Icons.save),
        status: this.model.saving || this.model.loading || !this.model.visit || !this.model.dirty() ? ToolbarItemStatus.DISABLED : ToolbarItemStatus.NORMAL,
        action: () => this.model.save(this.atlas.getRepository()) }])
  }
}
