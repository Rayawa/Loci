import { PageBack } from '../ui/navigation/SheetSession';
import { AppShell } from '../ui/navigation/AppShell';

@Entry
@ComponentV2
struct Index {
  onBackPress(): boolean { return PageBack.handle(); }

  build() {
    Stack() {
      AppShell()
    }.width('100%').height('100%')
  }
}
