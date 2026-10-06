import { HdsNavigation, HdsNavigationTitleMode } from '@kit.UIDesignKit';
import { SegmentButtonV2Items } from '@kit.ArkUI';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { Haptics } from '../../service/haptics/Haptics';
import { navigationTitle } from '../theme/NavigationStyle';
import { HdsTitleBarSegment } from '../components/HdsTitleBarSegment';
import { Theme } from '../theme/Theme';

export interface TitleAction {
  label: string;
  icon: Resource;
  isEnabled: boolean;
  action: () => void;
}
interface TitleMenuItem { content: TitleAction; }

@ComponentV2
export struct HdsNav {
  @Require @Param stack: NavPathStack;
  @Require @Param title: string;
  @Param menus: TitleAction[] = [];
  @Require @Param segmentItems: SegmentButtonV2Items;
  @Param selectedIndexes: number[] = [0];
  @Event onSegmentSelected: (index: number) => void = () => {};
  @Event onRootVisibleChanged: (visible: boolean) => void = () => {};
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @BuilderParam content: () => void = this.empty;
  @BuilderParam destination: (name: string, parameter: Object) => void = this.emptyDestination;

  @Builder empty() { Blank() }
  @Builder emptyDestination(name: string, parameter: Object) { Blank() }
  @Builder segment() {
    Column() {
      HdsTitleBarSegment({ items: this.segmentItems, selectedIndexes: this.selectedIndexes,
        maxFontScale: 2, segmentHeight: 48, normalWidth: '50%', experimentalWidth: '50%', experimentalHeight: 52,
        onSelected: (index: number) => this.onSegmentSelected(index), onItemClicked: () => Haptics.confirm() })
        .align(Alignment.Center).margin({ top: 8 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  build() {
    HdsNavigation(this.stack) {
      Stack() { this.content() }.width('100%').height('100%').backgroundColor(Theme.background)
    }
      .mode(NavigationMode.Stack).navDestination(this.destination)
      .titleMode(HdsNavigationTitleMode.MINI).hideBackButton(true)
      .onNavBarStateChange((visible: boolean) => this.onRootVisibleChanged(visible))
      .titleBar({ style: navigationTitle(this.title, this.experience.materialLevel).style,
        content: { title: navigationTitle(this.title).content?.title,
          menu: { value: this.menus.map((item: TitleAction): TitleMenuItem => ({ content: item })) },
          stackBuilder: () => { this.segment() } } })
      .customNavContentTransition((_from: NavContentInfo, _to: NavContentInfo, operation: NavigationOperation) => {
        if (operation === NavigationOperation.POP) { Haptics.back(); }
        return undefined;
      })
      .width('100%').height('100%').backgroundColor(Theme.background)
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
