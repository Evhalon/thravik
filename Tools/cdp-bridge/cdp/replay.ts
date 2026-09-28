// Chrome attaches to a tab whose hidden Web Inspector already turned the
// domains on, and WebKit ignores an enable for an enabled domain — so Chrome
// would never hear about the execution contexts, console messages, scripts
// or style sheets that came before it. Turning a domain off and straight
// back on makes WebKit replay that state, once per session.

import type { Session } from "./session";

export async function replay(s: Session, domain: string) {
  if (s.state.replayed.has(domain)) return;
  s.state.replayed.add(domain);
  await s.call(`${domain}.disable`).catch(() => {});
  await s.call(`${domain}.enable`);
}
