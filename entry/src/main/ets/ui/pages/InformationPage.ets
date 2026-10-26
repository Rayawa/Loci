import { AppIcon } from '../components/AppIcon';
import { common } from '@kit.AbilityKit';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { APP_VERSION } from '../../common/constants';
import { pageTransition } from '../../common/motion';
import { HuaweiAccount } from '../../service/account/HuaweiAccount';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { ActionButton } from '../components/ActionButton';
import { Theme } from '../theme/Theme';
import { destinationTitle } from '../theme/NavigationStyle';
import { EntityRoute, Routes } from '../navigation/Routes';

@ComponentV2
export struct InformationPage {
  @Require @Param kind: string;
  @Require @Param stack: NavPathStack;
  @Local account: HuaweiAccount = HuaweiAccount.shared;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  private title(): string {
    return this.kind === Routes.Account ? '华为账号' : this.kind === Routes.Sync ? '云同步' : this.kind === Routes.Changelog ? '更新日志' : '关于';
  }
  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 18 }) {
          Blank().height(100).width('100%')
          AppIcon({ iconSize: 84 })
          Text(this.title()).fontSize(28).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
          Column({ space: 16 }) {
            if (this.kind === Routes.Account) {
              Text(this.account.authorized ? '华为账号已授权' : '使用华为账号登录').fontSize(20).fontColor(Theme.ink).width('100%')
              Text(this.account.configured ? '授权后连接账号，记录暂存本机。' : '账号服务尚未开通。')
                .fontSize(15).fontColor(Theme.muted).width('100%')
              if (this.account.authorized) {
                ActionButton({ label: '退出本次授权会话', onAction: () => this.account.logout() })
              } else {
                ActionButton({ label: this.account.busy ? '正在登录…' : this.account.configured ? '华为账号登录' : '账号服务尚未开放',
                  highlighted: true, available: this.account.configured && !this.account.busy,
                  onAction: () => this.account.login(this.getUIContext().getHostContext() as common.UIAbilityContext) })
              }
              if (this.account.message) { Text(this.account.message).fontSize(14).fontColor(Theme.muted).width('100%') }
            } else if (this.kind === Routes.Sync) {
              Text('云同步尚未启用').fontSize(20).fontColor(Theme.ink).width('100%')
              Text('记录保存在本机。')
                .fontSize(15).fontColor(Theme.muted).width('100%')
              ActionButton({ label: '查看华为账号', onAction: () => this.stack.pushPathByName(Routes.Account, new EntityRoute('')) })
            } else if (this.kind === Routes.Changelog) {
              Text('每日记录重构 · 2026.10.22').fontSize(20).fontColor(Theme.ink).width('100%')
              Text('新增每日时间记录、日期切换和日历跳转。\n\n支持本地文本提取、分类、事项、起止时间、可选地点与备注。\n\n新增列表、周视图、分类统计与单项周柱状图。\n\n地点是独立一级标签，保留原有地图、地点和到访历史。\n\n账号与云同步入口已建立，服务开通后启用。')
                .fontSize(15).fontColor(Theme.muted).width('100%')
            } else {
              Text('时迹').fontSize(30).fontWeight(FontWeight.Medium).fontColor(Theme.accent)
              Text('时间与地点').fontSize(18).fontColor(Theme.ink)
              Text(`版本 ${APP_VERSION}`).fontSize(13).fontColor(Theme.muted)
              Text('Designed & Developed by Ray Chen (Rayawa)\nCopyright © 2026. All rights reserved.').fontSize(12).fontColor(Theme.muted).textAlign(TextAlign.Center)
            }
          }.width('100%').padding(18).backgroundColor(Theme.surface).borderRadius(16)
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
          Blank().height(110).width('100%')
        }.width('100%').padding({ left: Theme.pagePadding, right: Theme.pagePadding })
      }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }.titleMode(HdsNavDestinationTitleMode.MINI).titleBar(destinationTitle(this.title(), this.experience.materialLevel))
      .transition(pageTransition()).backgroundColor(Theme.background)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
