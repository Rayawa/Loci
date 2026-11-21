import { PageMotion } from '../navigation/PageMotion';
import { SheetSession } from '../navigation/SheetSession';
import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { AddVisitSheet } from '../components/AddVisitSheet';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { sheetTitle } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';

@ComponentV2
export struct VisitEditorPage {
  @Local motion: PageMotion = new PageMotion();
  aboutToDisappear(): void { this.motion.stop(); }
  @Require @Param atlas: AtlasViewModel;
  @Require @Param session: SheetSession;
  @Event onSaved: (record: RecordedVisit) => void = () => {};
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local saveVersion: number = 0;
  private back(): boolean { this.session.requestClose(); return true; }
  build() {
    HdsNavDestination() {
      Column() {
      if (this.atlas.draft) {
        AddVisitSheet({ model: this.atlas, draft: this.atlas.draft, saveVersion: this.saveVersion,
          onEditingState: (dirty: boolean, saving: boolean) => { this.session.dirty = dirty; this.session.saving = saving; },
          onSaved: (record: RecordedVisit) => { this.session.dirty = false; this.session.finish(); this.onSaved(record); } })
      }
      }.width('100%').height('100%').opacity(this.motion.visible ? 1 : 0).translate({ y: this.motion.visible ? 0 : 12 })
    }.titleMode(HdsNavDestinationTitleMode.MODAL).backgroundColor(Theme.background).transition(pageTransition())
      .titleBar(sheetTitle('到访', this.experience.materialLevel,
        [{ label: '保存', icon: Icons.save, isEnabled: !!this.atlas.draft && !this.session.saving,
          action: () => { this.saveVersion++; } }]))
      .onWillShow(() => this.motion.prepare()).onShown(() => this.motion.enter(this.getUIContext()))
      .onHidden(() => this.motion.stop()).onBackPressed(() => this.back())
  }
}
