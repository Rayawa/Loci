import { HdsNavDestination, HdsNavDestinationTitleMode } from '@kit.UIDesignKit';
import { RecordedVisit } from '../../domain/model/Atlas';
import { ExperienceSettings } from '../../service/settings/ExperienceSettings';
import { AddVisitSheet } from '../components/AddVisitSheet';
import { AtlasViewModel } from '../viewmodel/AtlasViewModel';
import { destinationActions } from '../theme/NavigationStyle';
import { Theme } from '../theme/Theme';
import { Icons } from '../../common/icons';
import { pageTransition } from '../../common/motion';

@ComponentV2
export struct VisitEditorPage {
  @Require @Param atlas: AtlasViewModel;
  @Require @Param stack: NavPathStack;
  @Event onSaved: (record: RecordedVisit) => void = () => {};
  @Local experience: ExperienceSettings = ExperienceSettings.shared;
  @Local dirty: boolean = false;
  @Local saving: boolean = false;
  @Local saveVersion: number = 0;
  aboutToDisappear(): void { this.atlas.showAdd = false; }
  private back(): boolean {
    if (this.saving) { return true; } if (!this.dirty) { return false; }
    this.getUIContext().showAlertDialog({ title: '放弃修改？', message: '',
      primaryButton: { value: '继续编辑', action: () => {} },
      secondaryButton: { value: '放弃', action: () => { this.dirty = false; this.stack.pop(); } } }); return true;
  }
  build() {
    HdsNavDestination() {
      if (this.atlas.draft) {
        AddVisitSheet({ model: this.atlas, draft: this.atlas.draft, saveVersion: this.saveVersion,
          onEditingState: (dirty: boolean, saving: boolean) => { this.dirty = dirty; this.saving = saving; },
          onSaved: (record: RecordedVisit) => { this.dirty = false; this.stack.pop(); this.onSaved(record); } })
      }
    }.titleMode(HdsNavDestinationTitleMode.MINI).backgroundColor(Theme.background).transition(pageTransition())
      .titleBar(destinationActions('到访', this.experience.materialLevel,
        [{ label: '保存', icon: Icons.save, isEnabled: !!this.atlas.draft && !this.saving,
          action: () => { this.saveVersion++; } }]))
      .onBackPressed(() => this.back())
      .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
  }
}
