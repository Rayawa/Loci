import { AppIcon } from '../components/AppIcon';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { APP_VERSION, LIST_PAGE_HORIZONTAL_PADDING, LIST_SECTION_SPACING, LIST_SECTION_CONTENT_GAP,
  LIST_SECTION_TITLE_START_PADDING, LIST_SECTION_DIVIDER_VERTICAL_MARGIN } from '../../common/constants';
import { showToastSafely } from '../../common/safeUi';
import { Icons } from '../../common/icons';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { HuaweiAccount } from '../../service/account/HuaweiAccount';
import { ExperiencePanel } from '../components/ExperiencePanel';
import { ProfileRow } from '../components/ProfileRow';
import { EntityRoute, Routes } from '../navigation/Routes';
import { Theme } from '../theme/Theme';

// Dashboard MyPage: identity → inline settings → grouped actions → version information.
@ComponentV2
export struct ProfilePage {
  @Require @Param stack: NavPathStack;
  @Param active: boolean = false;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local account: HuaweiAccount = HuaweiAccount.shared;
  @Local animStep: number = 0;
  @Local contentWidth: number = 0;
  private timers: number[] = [];
  private enterAnimationPlayed: boolean = false;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void { this.startAnimationOnce(); }
  @Monitor('active')
  onActiveChanged(): void { this.startAnimationOnce(); }
  @Monitor('experience.error')
  onErrorChanged(): void {
    if (this.active && this.experience.error) { showToastSafely(this.getUIContext().getPromptAction(), this.experience.error); }
  }
  private startAnimationOnce(): void {
    if (!this.active || this.enterAnimationPlayed) { return; }
    this.enterAnimationPlayed = true;
    this.timers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number) => { this.animStep = step; });
  }
  aboutToDisappear(): void { cancelStaggerEnterAnimation(this.timers); this.timers = []; }
  private open(route: string): void { this.stack.pushPathByName(route, new EntityRoute('')); }
  private requiredStep(group: string): number {
    if (this.contentWidth >= 840) {
      if (group === 'identity' || group === 'information' || group === 'settings') { return 1; }
      return group === 'account' ? 2 : 3;
    }
    if (group === 'identity') { return 1; }
    if (group === 'settings') { return 2; }
    if (group === 'account') { return 3; }
    return group === 'help' ? 4 : 5;
  }

  @Builder appIdentity() {
    Column({ space: LIST_SECTION_CONTENT_GAP }) {
      AppIcon({ iconSize: 100 }).margin({ bottom: 10 })
        .accessibilityText('时迹应用图标')
      Text('时迹').fontSize(30).fontWeight(800).fontColor(Theme.accent).textAlign(TextAlign.Center)
      Text('时间与地点').fontSize(20).fontWeight(600).fontColor(Theme.muted).textAlign(TextAlign.Center)
    }.width('100%').padding({ top: 18, bottom: 18, left: 12, right: 12 })
      .opacity(this.animStep >= this.requiredStep('identity') ? 1 : 0)
      .translate({ y: this.animStep >= this.requiredStep('identity') ? 0 : 20 })
      .accessibilityGroup(true).accessibilityText('时迹应用图标和名称')
  }
  @Builder sectionTitle(title: string) {
    Text(title).fontSize(14).fontWeight(FontWeight.Bold).fontColor(Theme.accent)
      .width('100%').padding({ left: LIST_SECTION_TITLE_START_PADDING })
  }
  @Builder itemDivider() {
    Divider().color($r('app.color.v3_chart_grid')).margin({ left: 16, right: 16 })
  }
  @Builder sectionDivider(group: string) {
    Divider().margin({ top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN, bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN })
      .color($r('app.color.border')).opacity(this.animStep >= this.requiredStep(group) ? 1 : 0)
  }
  @Builder settingsSection() {
    Column({ space: 8 }) {
      this.sectionTitle('设置')
      ExperiencePanel({ active: this.active })
    }.width('100%').opacity(this.animStep >= this.requiredStep('settings') ? 1 : 0)
      .translate({ y: this.animStep >= this.requiredStep('settings') ? 0 : 20 })
  }
  @Builder accountSection() {
    Column({ space: 8 }) {
      this.sectionTitle('账号与同步')
      Column() {
        ProfileRow({ title: this.account.authorized ? '华为账号 · 已授权' : '华为账号登录',
          icon: Icons.user, onOpen: () => this.open(Routes.Account) })
        this.itemDivider()
        ProfileRow({ title: '云同步', icon: $r('app.media.profile_sync'), onOpen: () => this.open(Routes.Sync) })
      }.width('100%').borderRadius(16).backgroundColor(Theme.surface)
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 }).clip(true)
    }.width('100%').opacity(this.animStep >= this.requiredStep('account') ? 1 : 0)
      .translate({ y: this.animStep >= this.requiredStep('account') ? 0 : 20 })
  }
  @Builder helpSection() {
    Column({ space: 8 }) {
      this.sectionTitle('帮助')
      Column() {
        ProfileRow({ title: '更新日志', icon: $r('app.media.profile_log'), onOpen: () => this.open(Routes.Changelog) })
        this.itemDivider()
        ProfileRow({ title: '关于', icon: $r('app.media.profile_info'), onOpen: () => this.open(Routes.About) })
      }.width('100%').borderRadius(16).backgroundColor(Theme.surface)
        .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 }).clip(true)
    }.width('100%').opacity(this.animStep >= this.requiredStep('help') ? 1 : 0)
      .translate({ y: this.animStep >= this.requiredStep('help') ? 0 : 20 })
  }
  @Builder settingsAndLinks() {
    Column({ space: LIST_SECTION_SPACING }) {
      this.settingsSection()
      this.sectionDivider('account')
      this.accountSection()
      this.sectionDivider('help')
      this.helpSection()
    }.width('100%')
  }
  @Builder versionInformation() {
    Column({ space: 5 }) {
      Text(`版本 ${APP_VERSION}`).fontSize(12).fontColor(Theme.muted)
      Text('Designed & Developed by Ray Chen (Rayawa)').fontSize(12).fontColor(Theme.muted).textAlign(TextAlign.Center)
      Text('Copyright © 2026. All rights reserved.').fontSize(12).fontColor(Theme.muted).textAlign(TextAlign.Center)
    }.width('100%').padding({ top: 14 })
      .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
      .translate({ y: this.animStep >= this.requiredStep('information') ? 0 : 20 })
  }

  build() {
    Stack() {
      if (this.contentWidth >= 840) {
        Row({ space: 16 }) {
          Column() {
            Blank().height(100).width('100%')
            Column({ space: 14 }) {
              this.appIdentity()
              this.sectionDivider('information')
              this.versionInformation()
            }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Center)
          }.layoutWeight(4).height('100%').padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
          Divider().vertical(true).height('100%').color($r('app.color.border'))
          Scroll(this.scroller) {
            Column() {
              Blank().height(110).width('100%')
              this.settingsAndLinks()
              Blank().height(110).width('100%')
            }.width('100%').padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
          }.layoutWeight(6).height('100%').align(Alignment.Top).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
        }.width('100%').height('100%').constraintSize({ maxWidth: 1440 }).alignItems(VerticalAlign.Top)
          .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
      } else {
        Scroll(this.scroller) {
          Column({ space: LIST_SECTION_SPACING }) {
            Blank().height(100).width('100%')
            this.appIdentity()
            this.sectionDivider('settings')
            this.settingsAndLinks()
            this.sectionDivider('information')
            this.versionInformation()
            Blank().height(110).width('100%')
          }.width('100%').constraintSize({ maxWidth: 1440 })
            .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
        }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }
    }.width('100%').height('100%').backgroundColor(Theme.background)
      .onAreaChange((_old: Area, area: Area) => { this.contentWidth = Number(area.width); })
  }
}
