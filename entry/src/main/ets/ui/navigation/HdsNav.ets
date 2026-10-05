import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { Haptics } from '../../service/haptics/Haptics';
import { navigationTitle } from '../theme/NavigationStyle';
import { Icons } from '../../common/icons';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct HdsNav {
  @Require @Param stack: NavPathStack;
  @Require @Param title: string;
  @Param actions: ToolbarItem[] = [];
  @Event onSettings: () => void = () => {};
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @BuilderParam content: () => void = this.empty;
  @BuilderParam destination: (name: string, parameter: Object) => void = this.emptyDestination;

  @Builder empty() { Blank() }
  @Builder emptyDestination(name: string, parameter: Object) { Blank() }

  build() {
    HdsNavigation(this.stack) {
      Column() { this.content() }.width('100%').height('100%').padding({ top: 56 })
    }
      .mode(NavigationMode.Auto).navDestination(this.destination)
      .titleMode(HdsNavigationTitleMode.MINI).hideBackButton(true)
      .titleBar({ style: navigationTitle(this.title, this.experience.materialLevel).style,
        content: { title: navigationTitle(this.title).content?.title,
          menu: { value: [{ content: { label: '设置', icon: Icons.settings, action: () => this.onSettings() } }] } } })
      .toolbarConfiguration(this.actions).hideToolBar(this.actions.length === 0)
      .customNavContentTransition((_from: NavContentInfo, _to: NavContentInfo, operation: NavigationOperation) => {
        if (operation === NavigationOperation.POP) { Haptics.back(); }
        return undefined;
      })
      .width('100%').height('100%').backgroundColor(Theme.background)
  }
}
