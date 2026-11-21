@ObservedV2
export class AppLifecycle {
  static readonly shared: AppLifecycle = new AppLifecycle();
  @Trace foreground: boolean = true;
}
