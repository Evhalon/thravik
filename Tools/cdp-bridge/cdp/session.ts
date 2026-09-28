// One Chrome DevTools session, bridged through the hidden copy of WebKit's
// own Web Inspector that Redent opens for a tab.
//
// Nothing crosses unexamined. Every command Chrome sends has a handler that
// answers it — usually by asking WebKit through `call` and reshaping the
// answer — and only events a handler translated reach Chrome.
//
// The Web Inspector frontend keeps using the same backend, so the ids this
// session puts on the wire are negative; the frontend's are positive.

import { SessionState } from "./state";

export type Message = { id?: number; method?: string; params?: any; result?: any; error?: any };
export type Transport = { toBackend(raw: string): void; toTools(raw: string): void };
type Handler = (params: any, method: string) => unknown;
type EventHandler = (params: any) => void;
type Pending = { resolve: (v: any) => void; reject: (e: any) => void };

export class ProtocolError extends Error {}

export function isSessionID(id: unknown): boolean {
  return typeof id === "number" && id < 0;
}

function domainOf(method: string | undefined): string {
  return method?.split(".")[0] ?? "";
}

export class Session {
  readonly state = new SessionState();
  private handlers = new Map<string, Handler>();
  private eventHandlers = new Map<string, EventHandler>();
  private pending = new Map<number, Pending>();
  private lastId = 0;
  private enabledDomains = new Set<string>();
  private innerTargetId: string | null;
  private queued: Message[] = [];
  // Every page backend this tab has, including a provisional one still
  // loading a cross-origin navigation. Frame targets are left out.
  private pageTargetIds = new Set<string>();
  // The Target.sendMessageToTarget wrapper is acknowledged on its own; the
  // real answer arrives separately through Target.dispatchMessageFromTarget.
  private wrappedIds = new Set<number>();

  constructor(private transport: Transport, pageTargetId: string | null) {
    this.innerTargetId = pageTargetId;
    if (pageTargetId) this.pageTargetIds.add(pageTargetId);
  }

  /** Answers a Chrome command. A handler's return value is the result. */
  handle(method: string, handler: Handler) {
    this.handlers.set(method, handler);
  }

  /** Reacts to a WebKit event. */
  on(event: string, handler: EventHandler) {
    this.eventHandlers.set(event, handler);
  }

  /** Asks WebKit's backend for this tab's page. */
  call(method: string, params: any = {}): Promise<any> {
    return new Promise((resolve, reject) => {
      const id = --this.lastId;
      this.pending.set(id, { resolve, reject });
      this.send({ id, method, params });
    });
  }

  /** Sends Chrome an event, if Chrome turned that domain on. */
  emit(method: string, params: any) {
    if (!this.enabledDomains.has(domainOf(method))) return;
    this.transport.toTools(JSON.stringify({ method, params }));
  }

  isPageTarget(id: unknown): boolean {
    return typeof id === "string" && this.pageTargetIds.has(id);
  }

  async fromTools(raw: string) {
    let msg: Message;
    try {
      msg = JSON.parse(raw);
    } catch {
      return;
    }
    const method = msg.method ?? "";
    if (method.endsWith(".enable")) this.enabledDomains.add(domainOf(method));
    const handler = this.handlers.get(method) ?? this.handlers.get("*");
    try {
      const result = handler ? await handler(msg.params ?? {}, method) : {};
      if (method.endsWith(".disable")) this.enabledDomains.delete(domainOf(method));
      this.reply({ id: msg.id, result: result ?? {} });
    } catch (e: any) {
      this.reply({ id: msg.id, error: { code: -32000, message: e?.message ?? String(e) } });
    }
  }

  /** A message on the page target: an answer this session owns, or an
   *  event everyone sees. */
  fromBackend(msg: Message) {
    if (typeof msg.id !== "number") return this.dispatchEvent(msg);
    this.settle(msg);
  }

  /** A message on the outer connection: a Target event, or the wrapper's
   *  acknowledgement — which only matters when it failed, because then no
   *  inner answer will follow. */
  fromOuter(msg: Message) {
    if (typeof msg.id !== "number") return this.onTargetDomain(msg);
    if (this.wrappedIds.delete(msg.id) && msg.error) this.settle(msg);
  }

  private settle(msg: Message) {
    const id = msg.id ?? 0;
    const pending = this.pending.get(id);
    if (!pending) return;
    this.pending.delete(id);
    if (msg.error) pending.reject(new ProtocolError(msg.error.message ?? "WebKit error"));
    else pending.resolve(msg.result ?? {});
  }

  private dispatchEvent(msg: Message) {
    try {
      this.eventHandlers.get(msg.method ?? "")?.(msg.params ?? {});
    } catch {
      // One malformed event must not end the session.
    }
  }

  private onTargetDomain(msg: Message) {
    const info = msg.params?.targetInfo;
    if (msg.method === "Target.targetCreated" && info?.type === "page") {
      this.pageTargetIds.add(info.targetId);
      if (!this.innerTargetId) this.retarget(info.targetId);
    }
    if (msg.method === "Target.targetDestroyed") this.pageTargetIds.delete(msg.params?.targetId);
    // A cross-origin navigation swaps the page's backend; follow it.
    if (msg.method === "Target.didCommitProvisionalTarget" && typeof msg.params?.newTargetId === "string") {
      this.retarget(msg.params.newTargetId);
    }
  }

  private retarget(id: string) {
    this.innerTargetId = id;
    const queued = this.queued;
    this.queued = [];
    queued.forEach((m) => this.send(m));
  }

  private send(m: Message) {
    if (!this.innerTargetId) {
      this.queued.push(m);
      return;
    }
    if (typeof m.id === "number") this.wrappedIds.add(m.id);
    this.transport.toBackend(JSON.stringify({
      id: m.id,
      method: "Target.sendMessageToTarget",
      params: { message: JSON.stringify(m), targetId: this.innerTargetId },
    }));
  }

  private reply(m: Message) {
    if (typeof m.id === "number") this.transport.toTools(JSON.stringify(m));
  }
}
