import { SymbolGlyphModifier } from '@kit.ArkUI';

// All navigation and actions resolve their system symbols here.
export class Icons {
  static readonly map: Resource = $r('sys.symbol.map');
  static readonly trips: Resource = $r('sys.symbol.airplane');
  static readonly atlas: Resource = $r('sys.symbol.flag');
  static readonly settings: Resource = $r('sys.symbol.gearshape');
  static readonly add: Resource = $r('sys.symbol.plus');
  static readonly locate: Resource = $r('sys.symbol.location_north_up_right');
  static readonly filter: Resource = $r('sys.symbol.slider_horizontal_2_square');
  static readonly save: Resource = $r('sys.symbol.checkmark');
  static readonly flag: Resource = $r('sys.symbol.flag');
  static readonly vibration: Resource = $r('app.media.vibrate');
  static readonly material: Resource = $r('app.media.immersive');
  static readonly light: Resource = $r('app.media.light');
  static readonly marker: Resource = $r('app.media.loci_flag');

  static modifier(icon: Resource): SymbolGlyphModifier { return new SymbolGlyphModifier(icon); }
}
