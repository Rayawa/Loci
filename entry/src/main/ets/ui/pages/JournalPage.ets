import { common } from '@kit.AbilityKit';
import { Activity } from '../../domain/model/Activity';
import { dayClockText, dateKey } from '../../domain/service/ActivityRules';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { ActivityCard } from '../components/ActivityCard';
import { DateNavigator } from '../components/DateNavigator';
import { StatePanel } from '../components/StatePanel';
import { WeekTimeline } from '../components/WeekTimeline';
import { Theme } from '../theme/Theme';
import { JournalViewModel } from '../viewmodel/JournalViewModel';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { EntityRoute, Routes } from '../navigation/Routes';

@ComponentV2
export struct JournalPage {
  @Require @Param model: JournalViewModel;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param stack: NavPathStack;
  @Param viewIndex: number = 0;
  @Event onSelectList: () => void = () => {};
  @Local animStep: number = 0;
  private timers: number[] = [];
  aboutToAppear(): void { this.timers = startStaggerEnterAnimation(this.getUIContext(), 2, (step: number) => { this.animStep = step; }); }
  aboutToDisappear(): void { cancelStaggerEnterAnimation(this.timers); }
  private open(record: Activity): void { this.stack.pushPathByName(Routes.Activity, new EntityRoute(record.id)); }
  private routine(): void { this.stack.pushPathByName(Routes.Routine, new EntityRoute(this.model.selectedDate)); }

  @Builder boundary(label: string, waking: boolean) {
    Button({ type: ButtonType.Normal, stateEffect: false }) {
      Row({ space: 10 }) {
        Text('•').fontSize(16).fontColor(Theme.muted)
        Text(`${dayClockText(waking ? this.model.routine().wakeMinute : this.model.routine().sleepMinute)}  ${label}`).fontSize(16).fontColor(Theme.muted)
      }.width('100%').padding({ left: 4, right: 4, top: 10, bottom: 10 })
    }.width('100%').backgroundColor(Color.Transparent).borderRadius(8).onClick(() => this.routine())
      .accessibilityText(`${label} ${dayClockText(waking ? this.model.routine().wakeMinute : this.model.routine().sleepMinute)}，设置作息`)
  }
  @Builder pageContent() {
    Scroll() {
      Column({ space: 18 }) {
        Blank().height(100).width('100%')
        DateNavigator({ model: this.model, weekly: this.viewIndex === 1 })
          .opacity(this.animStep >= 1 ? 1 : 0)
        if (this.model.loading) { LoadingProgress().width(28).height(28) }
        else if (this.model.error) {
          StatePanel({ title: this.model.error, action: '重试', onAction: () => this.model.retry(this.getUIContext().getHostContext() as common.UIAbilityContext) })
        } else if (this.viewIndex === 1) {
          WeekTimeline({ model: this.model, onDay: (day: string) => { this.model.selectDate(day); this.onSelectList(); }, onOpen: (record: Activity) => this.open(record) })
        } else {
          Column({ space: 0 }) {
            this.boundary('睡觉', false)
            Column({ space: 0 }) {
              if (!this.model.dayRecords().length) { Text('暂无记录').fontSize(15).fontColor(Theme.muted).width('100%').padding({ top: 12, bottom: 12, left: 14 }) }
              ForEach(this.model.dayRecords(), (record: Activity) => {
                ActivityCard({ record: record, onOpen: () => this.open(record) })
              }, (record: Activity) => `${record.id}-${record.updatedAt}`)
            }.width('calc(100% - 10vp)').padding({ left: 12 }).border({ width: { left: 1 }, color: Theme.line }).margin({ left: 10 })
            this.boundary('起床', true)
          }.width('100%').opacity(this.animStep >= 2 ? 1 : 0)
        }
        Blank().height(110).width('100%')
      }.padding({ left: Theme.pagePadding, right: Theme.pagePadding }).width('100%')
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
  }
  build() {
    if (this.viewIndex === 0) {
      Stack() { this.pageContent() }.width('100%').height('100%')
        .priorityGesture(PanGesture({ direction: PanDirection.Horizontal, distance: 45 })
          .onActionEnd((event: GestureEvent) => this.model.moveDay(event.offsetX < 0 ? 1 : -1)))
    } else { this.pageContent() }
  }
}
