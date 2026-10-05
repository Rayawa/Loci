import { HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { ScrollEffectType } from '@kit.UIDesignKit';
import { HDS_MATERIAL_TYPE_ADAPTIVE, HDS_TITLE_SIZE_SMALL, SUPPORTS_HARMONY_API_23 } from '../../common/platformCompatibility';

// Titlebar style copied from Dashboard's AppDetailPage; only title and level are parameters.
export function navigationTitle(title: string, materialLevel: number = 1): HdsNavigationTitleBarOptions {
  return {
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: false,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
                    materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
                    materialLevel: materialLevel,
                } : undefined,
            },
    content: { title: { mainTitle: title, mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined } }
  };
}

export function destinationTitle(title: string, materialLevel: number = 1): HdsNavigationTitleBarOptions {
  const shared = navigationTitle(title, materialLevel);
  return { style: shared.style, content: shared.content };
}
