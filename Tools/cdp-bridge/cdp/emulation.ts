// Emulation: the Rendering drawer's media and user-preference switches, and
// the user agent. Device metrics and touch are not something a WebKit page
// can be told from here.

import type { Session } from "./session";

const PREFERENCES: Record<string, { name: string; values: Record<string, string> }> = {
  "prefers-color-scheme": { name: "PrefersColorScheme", values: { dark: "Dark", light: "Light" } },
  "prefers-reduced-motion": { name: "PrefersReducedMotion", values: { reduce: "Reduce", "no-preference": "NoPreference" } },
  "prefers-contrast": { name: "PrefersContrast", values: { more: "More", "no-preference": "NoPreference" } },
};

export function installEmulation(s: Session) {
  s.handle("Emulation.setUserAgentOverride", (p) => s.call("Page.overrideUserAgent", p.userAgent ? { value: p.userAgent } : {}));
  s.handle("Emulation.setEmulatedMedia", async (p) => {
    await s.call("Page.setEmulatedMedia", { media: p.media ?? "" });
    const features: any[] = p.features ?? [];
    for (const [feature, preference] of Object.entries(PREFERENCES)) {
      const value = features.find((f) => f.name === feature)?.value;
      const mapped = value ? preference.values[value] : undefined;
      await s.call("Page.overrideUserPreference", mapped ? { name: preference.name, value: mapped } : { name: preference.name });
    }
  });
}
