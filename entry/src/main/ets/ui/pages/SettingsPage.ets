import { HdsNavDestination } from '@kit.UIDesignKit';
import { Theme } from '../theme/Theme';

@ComponentV2
export struct SettingsPage {
  build() {
    HdsNavDestination() {
      Column({ space: 20 }) {
        Text('属于你的个人地图').fontSize(28).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
        Text('地点、到访和记忆保存在这台设备上。每次到访都是独立的记忆，同一个地点会随着时间积累历史。')
          .fontSize(16).fontColor(Theme.muted)
        Text('只有你点击“记录这里”时，Loci 才申请当前位置。你也可以长按地图补记，无需在现场验证。')
          .fontSize(16).fontColor(Theme.muted)
        Text('Loci 1.0 · Local Atlas').fontSize(13).fontColor(Theme.muted)
      }.padding(24).width('100%').alignItems(HorizontalAlign.Start)
    }.titleBar({ content: { title: { mainTitle: '设置' } } }).backgroundColor(Theme.background)
  }
}
