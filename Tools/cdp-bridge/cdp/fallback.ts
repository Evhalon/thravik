// Chrome's DevTools turns on and configures far more than a WebKit page can
// offer. A command nothing here handles is acknowledged when it only
// configures something, and refused when Chrome expects data back — Chrome
// treats a refused query as "not available" and carries on.

import type { Session } from "./session";
import { ProtocolError } from "./session";

const QUERY = /^(get|query|search|take|capture|resolve|request|describe|compile|evaluate|call|collect|load|print)/;

export function installFallback(s: Session) {
  s.handle("*", (_params, method) => {
    if (QUERY.test(method.split(".")[1] ?? "")) throw new ProtocolError(`'${method}' is not available in WebKit`);
    return {};
  });
}
