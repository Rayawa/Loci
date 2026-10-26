import { TextModifier } from '@kit.ArkUI';
import { HdsListItemCard, IconSize, PrefixIcon, SuffixCustomBuilder } from '@kit.UIDesignKit';
import { LIST_ITEM_PREFIX_MARGIN, LIST_ITEM_SUFFIX_MARGIN } from '../../common/constants';
import { Haptics } from '../../service/haptics/Haptics';
import { Theme } from '../theme/Theme';

// Dashboard MyPage.MoreRow adapted to ArkUI V2.
@ComponentV2
export struct ProfileRow {
  @Require @Param title: string;
  @Require @Param icon: Resource;
  @Event onOpen: () => void = () => {};
  @Builder suffix() {
    Image($r('app.media.profile_right')).width(20).height(20).objectFit(ImageFit.Contain).accessibilityText('进入')
  }
  build() {
    HdsListItemCard({
      prefixItem: new PrefixIcon({ iconSize: IconSize.SYSTEM_ICON, iconValue: { image: this.icon } }),
      textItem: { primaryText: { text: this.title, modifier: new TextModifier().fontSize(16).fontColor(Theme.ink) } },
      suffixItem: new SuffixCustomBuilder(() => { this.suffix() }),
      onClick: () => { Haptics.confirm(); this.onOpen(); }, cardHeight: 54,
      cardBackgroundColor: Theme.surface, cardBorderRadius: 0, hoverBorderRadius: 12,
      cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN, cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
      accessibilityOptions: { accessibilityText: `进入${this.title}` }
    })
  }
}
