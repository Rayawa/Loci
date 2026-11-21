/** One edit session per native sheet. Old asynchronous callbacks cannot close its successor. */
@ObservedV2
export class SheetSession {
  @Trace dirty: boolean = false;
  @Trace saving: boolean = false;
  readonly token: number;
  requestClose: () => void;
  finish: () => void;

  constructor(token: number, requestClose: () => void, finish: () => void) {
    this.token = token;
    this.requestClose = requestClose;
    this.finish = finish;
  }
}

export class SheetRequest {
  kind: string;
  id: string;
  constructor(kind: string, id: string = '') { this.kind = kind; this.id = id; }
}

/** @Entry owns the actual page lifecycle; child tabs do not have onBackPress lifecycles. */
export class PageBack {
  static handle: () => boolean = () => false;
}
