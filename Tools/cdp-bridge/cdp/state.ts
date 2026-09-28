// What one session remembers about the page between messages: WebKit's
// events leave out fields Chrome requires, and some of them are only known
// from an earlier event.

/** Bounded so a long-lived page cannot grow the map without end. */
const REQUEST_LIMIT = 2000;

export type TrackedRequest = {
  type: string;
  frameId?: string;
  loaderId?: string;
  postData?: string;
  response?: any;
  lastTimestamp?: number;
};

export class SessionState {
  /** The main frame's default execution context; console messages carry it. */
  mainContextId = 0;
  mainFrameId = "";
  mainFrameURL = "";
  readonly requests = new Map<string, TrackedRequest>();
  /** Script ids to URLs; a paused call frame names its script by id only. */
  readonly scripts = new Map<string, string>();
  /** Chrome hears about scripts only once it turned its debugger on. */
  debuggerEnabled = false;
  /** Domains whose earlier state WebKit already replayed to this session. */
  readonly replayed = new Set<string>();
  private contextsByFrame = new Map<string, number[]>();
  private originsByFrame = new Map<string, string>();

  addContext(id: number, frameId: string) {
    this.contextsByFrame.set(frameId, [...(this.contextsByFrame.get(frameId) ?? []), id]);
    if (this.mainFrameId ? frameId === this.mainFrameId : !this.mainContextId) this.mainContextId = id;
  }

  /** Forgets a frame's contexts and returns them; they died with its document. */
  dropContexts(frameId: string): number[] {
    const ids = this.contextsByFrame.get(frameId) ?? [];
    this.contextsByFrame.delete(frameId);
    if (ids.includes(this.mainContextId)) this.mainContextId = 0;
    return ids;
  }

  /** A main-frame navigation ends every context in the tab. */
  resetContexts() {
    this.contextsByFrame.clear();
    this.mainContextId = 0;
  }

  setOrigin(frameId: string, origin: string) {
    this.originsByFrame.set(frameId, origin);
  }

  origin(frameId: string): string {
    return this.originsByFrame.get(frameId) ?? "";
  }

  readonly isAnnounced = (scriptId: string): boolean => this.debuggerEnabled && this.scripts.has(scriptId);

  track(id: string, request: TrackedRequest) {
    if (this.requests.size >= REQUEST_LIMIT) {
      const oldest = this.requests.keys().next().value;
      if (oldest !== undefined) this.requests.delete(oldest);
    }
    this.requests.set(id, request);
  }
}
