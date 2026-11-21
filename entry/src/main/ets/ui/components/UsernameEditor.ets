import { getDeviceName } from '../../common/storage';
import { vibration } from '../../common/vibration';
import { Theme } from '../theme/Theme';

// Dashboard UsernameEditor layout; writes are acknowledged before marking the draft committed.
@ComponentV2
export struct UsernameEditor {
  @Param initialUsername: string = '';
  @Param narrow: boolean = false;
  @Param active: boolean = true;
  @Event onCommit: (value: string) => Promise<boolean> = async () => false;
  @Local draftUsername: string = '';
  @Local showHelp: boolean = false;
  @Local saving: boolean = false;
  @Local saveError: string = '';
  private editing: boolean = false;
  private lastCommittedUsername: string = '';

  aboutToAppear(): void {
    this.draftUsername = this.initialUsername;
    this.lastCommittedUsername = this.initialUsername.trim();
  }
  aboutToDisappear(): void { this.commitDraft(); }
  @Monitor('initialUsername')
  onInitialUsernameChanged(): void {
    if (this.editing || this.saving || this.draftUsername.trim() !== this.lastCommittedUsername) { return; }
    this.draftUsername = this.initialUsername; this.lastCommittedUsername = this.initialUsername.trim();
  }
  @Monitor('active')
  onActiveChanged(): void { if (!this.active) { this.commitDraft(); } }

  private async commitDraft(): Promise<void> {
    const username = this.draftUsername.trim();
    if (this.saving || username === this.lastCommittedUsername) { return; }
    this.saving = true; this.saveError = '';
    try {
      if (await this.onCommit(username)) { this.lastCommittedUsername = username; this.draftUsername = username; }
      else { this.saveError = '暂时无法保存用户名，请重试'; }
    } catch (_) { this.saveError = '暂时无法保存用户名，请重试'; } finally { this.saving = false; }
  }

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      Text('用户名').fontSize(16).fontColor(Theme.ink).maxLines(2).accessibilityText('用户名')
      Row({ space: 8 }) {
        TextInput({ text: this.draftUsername, placeholder: getDeviceName() })
          .layoutWeight(1).constraintSize({ minWidth: 120 }).height(40).maxLength(120)
          .enableKeyboardOnFocus(false)
          .backgroundColor(Theme.surfaceAlt).enabled(!this.saving).showError(this.saveError).id('usernameSetting')
          .onChange((value: string) => { this.draftUsername = value; })
          .onEditChange((isEditing: boolean) => { this.editing = isEditing; if (!isEditing) { this.commitDraft(); } })
          .onSubmit(() => this.commitDraft())
          .accessibilityText(`用户名输入框，当前用户名为${this.draftUsername || getDeviceName()}`)
        Image($r('app.media.question')).height(22).width(22).objectFit(ImageFit.Contain)
          .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.9 })
          .onClick(() => { vibration.dotVibration(); this.showHelp = !this.showHelp; })
          .bindPopup(this.showHelp, {
            message: '此名称用于标识本机记录；留空时显示设备名称',
            onStateChange: (event) => { if (!event.isVisible) { this.showHelp = false; } }
          }).accessibilityText('查看用户名说明')
      }.width(this.narrow ? '100%' : 204).margin({ top: this.narrow ? 4 : 0 })
    }.padding({ right: 7 }).width('100%').accessibilityGroup(false).accessibilityLevel('no')
      .accessibilityText(`用户名设置，当前${this.draftUsername || getDeviceName()}`)
  }
}
