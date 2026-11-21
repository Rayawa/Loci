import { HdsNavigationTitleBarOptions } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { ScrollEffectType } from '@kit.UIDesignKit';
import { HDS_MATERIAL_TYPE_ADAPTIVE, HDS_TITLE_SIZE_SMALL, SUPPORTS_HARMONY_API_23 } from '../../common/platformCompatibility';

// Titlebar style copied from Dashboard's AppDetailPage; only title and level are parameters.
export function navigationTitle(title: string, materialLevel: number = 1): HdsNavigationTitleBarOptions {
  return {
    // API 20+: HDS owns system and title-bar safe areas, including window changes.
    avoidLayoutSafeArea: true,
    enableComponentSafeArea: true,
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
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
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
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
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
  return shared;
}

export interface PageAction {
  label: string;
  icon: Resource;
  isEnabled: boolean;
  action: () => void;
}

interface NativePageAction extends PageAction { componentId: string; }
interface PageMenuItem { content: NativePageAction; }

export function destinationActions(title: string, level: number, actions: PageAction[]): HdsNavigationTitleBarOptions {
  const shared = destinationTitle(title, level);
  return { avoidLayoutSafeArea: shared.avoidLayoutSafeArea, enableComponentSafeArea: shared.enableComponentSafeArea, style: shared.style, content: { title: shared.content?.title,
    menu: { maxCount: 2, value: actions.map((action: PageAction): PageMenuItem => ({ content: { label: action.label, icon: action.icon, isEnabled: action.isEnabled, action: action.action, componentId: `title-${action.label}` } })) } } };
}

/** Sheet close belongs to the native title bar, avoiding a second overlay close button. */
export function sheetTitle(title: string, level: number, actions: PageAction[]): HdsNavigationTitleBarOptions {
  const shared = destinationActions(title, level, actions);
  // bindSheet already places its content below the system safe area.
  return { avoidLayoutSafeArea: false, enableComponentSafeArea: true, style: shared.style, content: { title: shared.content?.title, menu: shared.content?.menu,
    backIcon: { icon: $r('sys.symbol.xmark'), label: '关闭', componentId: 'sheet-close' } } };
}
