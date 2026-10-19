/* Plugin-owned translations supplement OPNsense gettext without replacing its catalogs. */
import zhCN from '../locales/zh-CN.json' with {type: 'json'};

export function localizeText(text, language = globalThis.document?.documentElement?.lang || 'en') {
  // Match the server-rendered UI locale, never the browser's preferred language.
  if (!/^zh(?:[-_](?:cn|hans)(?:[-_].*)?)?$/i.test(language)) return {...text};
  return Object.fromEntries(Object.entries(text).map(([key, value]) => [key, zhCN[key] ?? value]));
}
