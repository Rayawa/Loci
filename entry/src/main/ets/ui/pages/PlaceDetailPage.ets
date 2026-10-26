import { destinationActions, PageAction } from '../theme/NavigationStyle';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { Visit } from '../../domain/model/Atlas';
import { StatePanel } from '../components/StatePanel';
import { MapCanvas } from '../components/MapCanvas';
import { VisitCard } from '../components/VisitCard';
import { EntityRoute, Routes } from '../navigation/Routes';
import { Theme } from '../theme/Theme';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { PlaceHistoryViewModel } from '../viewmodel/PlaceHistoryViewModel';

@ComponentV2
export struct PlaceDetailPage {
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Require @Param atlas: AtlasViewModel;
  @Require @Param placeId: string;
  @Require @Param stack: NavPathStack;
  @Local model: PlaceHistoryViewModel = new PlaceHistoryViewModel();
  @Local activeMap: boolean = false;

  private load(): void {
    this.model.load(this.atlas.getRepository(), this.placeId);
  }

  private actions(): PageAction[] {
    return [{ label: '到访', icon: Icons.add,
      isEnabled: !!this.model.place && !this.atlas.locating && !this.atlas.selectingMap && !this.atlas.showAdd,
      action: () => { if (this.model.place) { this.atlas.revisit(this.model.place); } } }];
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 20 }) {
          Blank().height(100).width('100%')
          if (this.model.loading) {
            StatePanel({ title: '展开地点的记忆', loading: true })
          } else if (this.model.error) {
            StatePanel({ title: '暂时无法读取', message: this.model.error, action: '重试', onAction: () => this.load() })
          } else if (this.model.place) {
            Column({ space: 8 }) {
              Text(this.model.place.name).fontSize(32).fontWeight(FontWeight.Medium).fontColor(Theme.ink)
              Text([this.model.place.city, this.model.place.country].filter((part: string) => part.length > 0).join(' · ') || '我的地点')
                .fontSize(15).fontColor(Theme.muted)
              if (this.model.place.address) {
                Text(this.model.place.address).fontSize(14).fontColor(Theme.muted)
              }
            }.width('100%').alignItems(HorizontalAlign.Start)
            MapCanvas({ places: [this.model.place], focus: this.model.place, selectedId: this.placeId, controlTop: 14, presenting: this.activeMap })
              .height(180).clip(true).borderRadius(Theme.cardRadius)
            Row() {
              Column({ space: 6 }) {
                Text(`${this.model.place.visitCount} 次到访`).fontSize(22).fontColor(Theme.ink)
                Text(this.model.place.firstVisitedAt ? `第一次 ${new Date(this.model.place.firstVisitedAt).toLocaleDateString()}` : '等待下一段记忆')
                  .fontSize(12).fontColor(Theme.muted)
                if (this.model.place.lastVisitedAt) {
                  Text(`最近 ${new Date(this.model.place.lastVisitedAt).toLocaleDateString()}`).fontSize(12).fontColor(Theme.muted)
                }
              }.layoutWeight(1).alignItems(HorizontalAlign.Start)

            }.width('100%')
            Text('到访记录').fontSize(16).fontColor(Theme.muted).width('100%')
            if (this.model.visits.length === 0) {
              StatePanel({ title: '暂无到访' })
            }
            ForEach(this.model.visits, (visit: Visit) => {
              VisitCard({ visit: visit,
                onOpen: () => this.stack.pushPathByName(Routes.Memory, new EntityRoute(visit.id)) })
            }, (visit: Visit) => visit.id)
          }
          Blank().height(110).width('100%')
        }.width('100%').padding(Theme.pagePadding)
      }.height('100%').width('100%').backgroundColor(Theme.background)
    }.titleMode(HdsNavDestinationTitleMode.MINI).transition(pageTransition()).titleBar(destinationActions('地点', this.experience.materialLevel, this.actions()))
      .onActive(() => { this.activeMap = true; this.load(); }).onInactive(() => { this.activeMap = false; })
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])

  }
}
