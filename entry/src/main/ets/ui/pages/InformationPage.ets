import { common } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { hdsEffect, HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { APP_VERSION } from '../../common/constants';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { HuaweiAccount } from '../../service/account/HuaweiAccount';
import { Haptics } from '../../service/haptics/Haptics';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { ActionButton } from '../components/ActionButton';
import { AppIcon } from '../components/AppIcon';
import { DetailTag } from '../components/DetailTag';
import { PageMotion } from '../navigation/PageMotion';
import { Routes } from '../navigation/Routes';
import { SheetSession } from '../navigation/SheetSession';
import { destinationTitle, sheetTitle } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';

const CHANGELOG_ITEMS: string[] = [
  '新增每日时间记录、日期切换和日历跳转。',
  '支持本地文本提取、分类、事项、起止时间、可选地点与备注。',
  '新增列表、周视图、分类统计与单项周柱状图。',
  '地点是独立一级标签，保留原有地图、地点和到访历史。',
  '账号与云同步入口已建立，服务开通后启用。',
];

@ComponentV2
export struct InformationPage {
  @Param session: SheetSession | undefined = undefined;
  @Event onOpenAccount: () => void = () => {};
  @Local motion: PageMotion = new PageMotion();
  @Require @Param kind: string;
  @Require @Param stack: NavPathStack;
  @Local account: HuaweiAccount = HuaweiAccount.shared;
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local pressed: boolean = false;

  aboutToDisappear(): void {
    this.motion.stop();
  }

  private back(): boolean {
    if (this.session) {
      this.session.requestClose();
      return true;
    }
    Haptics.back();
    return false;
  }

  private title(): string {
    return this.kind === Routes.Account ? '华为账号' :
      this.kind === Routes.Sync ? '云同步' :
      this.kind === Routes.Changelog ? '更新日志' : '关于';
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 14 }) {
          Blank().height(8).width('100%')
          if (this.kind === Routes.Account) {
            Column({ space: 16 }) {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  SymbolGlyph(Icons.person).fontSize(22).fontColor([Theme.accent])
                }
                .width(44)
                .height(44)
                .borderRadius(12)
                .backgroundColor(Theme.surfaceAlt)
                .border({ width: 1, color: Theme.line })

                Column({ space: 4 }) {
                  Text(this.account.authorized ? '华为账号已授权' : '使用华为账号登录')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.ink)
                  Text(this.account.authorized ? '已授权' : this.account.configured ? '待登录' : '未开通')
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.account.authorized ? Theme.accentGreen : Theme.muted)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                    .backgroundColor(this.account.authorized ? Theme.successBg : Theme.surfaceAlt)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.width('100%')

              Text(this.account.configured ? '授权后连接账号，记录暂存本机。' : '账号服务尚未开通。')
                .fontSize(15)
                .fontColor(Theme.muted)
                .width('100%')

              if (this.account.authorized) {
                ActionButton({ label: '退出本次授权会话', onAction: () => this.account.logout() })
              } else {
                ActionButton({
                  label: this.account.busy ? '正在登录…' : this.account.configured ? '华为账号登录' : '账号服务尚未开放',
                  highlighted: true,
                  available: this.account.configured && !this.account.busy,
                  onAction: () => this.account.login(this.getUIContext().getHostContext() as common.UIAbilityContext),
                })
              }
              if (this.account.message) {
                Text(this.account.message).fontSize(14).fontColor(Theme.muted).width('100%')
              }
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
          } else if (this.kind === Routes.Sync) {
            Column({ space: 16 }) {
              Row({ space: 12 }) {
                Stack({ alignContent: Alignment.Center }) {
                  Image($r('app.media.profile_sync')).width(24).height(24).objectFit(ImageFit.Contain)
                }
                .width(44)
                .height(44)
                .borderRadius(12)
                .backgroundColor(Theme.surfaceAlt)
                .border({ width: 1, color: Theme.line })

                Column({ space: 4 }) {
                  Text('云同步尚未启用')
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.ink)
                  Text('未启用')
                    .fontSize(11)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.muted)
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                    .backgroundColor(Theme.surfaceAlt)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.width('100%')

              Text('记录保存在本机。')
                .fontSize(15)
                .fontColor(Theme.muted)
                .width('100%')

              ActionButton({ label: '查看华为账号', highlighted: true, onAction: () => this.onOpenAccount() })
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
          } else if (this.kind === Routes.Changelog) {
            Column({ space: 12 }) {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text('每日记录重构')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(Theme.ink)
                  Text('正式版')
                    .fontSize(12)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor(Theme.accentOrange)
                    .fontColor(Theme.surface)
                    .borderRadius(6)
                }
                Text('2026.10.22')
                  .fontSize(13)
                  .fontColor(Theme.muted)
              }.width('100%').alignItems(HorizontalAlign.Start)

              Column({ space: 6 }) {
                ForEach(CHANGELOG_ITEMS, (item: string) => {
                  Row({ space: 6 }) {
                    Text('•')
                      .fontSize(16)
                      .fontWeight(600)
                      .fontColor(Theme.muted)
                    Text(item)
                      .fontSize(15)
                      .lineHeight(21)
                      .fontColor(Theme.ink)
                      .layoutWeight(1)
                  }.width('100%').alignItems(VerticalAlign.Top)
                }, (item: string) => item)
              }.width('100%')
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
            .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
            .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
            .compositingFilter(pressLightFieldFilter(this.pressed))
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) {
                this.pressed = true;
              } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressed = false;
              }
            })
          } else {
            Column({ space: 16 }) {
              Row({ space: 16 }) {
                AppIcon({ iconSize: 60 })
                Column({ space: 4 }) {
                  Text('时迹').fontSize(22).fontWeight(FontWeight.Bold).fontColor(Theme.ink)
                  Text('时间与地点').fontSize(14).fontColor(Theme.muted)
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }.width('100%')

              Divider().color(Theme.chartGrid)

              Row({ space: 8 }) {
                DetailTag({ label: '版本', value: APP_VERSION }).layoutWeight(1)
                DetailTag({ label: '平台', value: 'HarmonyOS' }).layoutWeight(1)
              }.width('100%')

              Text('Designed & Developed by Ray Chen (Rayawa)\nCopyright © 2026. All rights reserved.')
                .fontSize(12)
                .fontColor(Theme.muted)
                .textAlign(TextAlign.Center)
                .width('100%')
            }
            .width('100%')
            .padding(18)
            .backgroundColor(Theme.surface)
            .borderRadius(Theme.panelRadius)
            .border({ width: 1, color: Theme.line })
            .shadow({ radius: 8, color: Theme.shadow, offsetY: 2 })
          }
          Blank().height(110).width('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: Theme.contentMaxWidth })
        .padding({ left: Theme.pagePadding, right: Theme.pagePadding })
      }
      .opacity(this.motion.visible ? 1 : 0)
      .translate({ y: this.motion.visible ? 0 : 12 })
      .id('informationScroll')
      .width('100%')
      .height('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .titleBar(this.session
      ? sheetTitle(this.title(), this.experience.materialLevel, [])
      : destinationTitle(this.title(), this.experience.materialLevel))
    .transition(pageTransition())
    .backgroundColor(Theme.background)
    .onWillShow(() => this.motion.prepare())
    .onShown(() => this.motion.enter(this.getUIContext()))
    .onHidden(() => this.motion.stop())
    .onBackPressed(() => this.back())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
