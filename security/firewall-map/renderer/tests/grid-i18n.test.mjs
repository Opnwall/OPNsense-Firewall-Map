import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
const source = fs.readFileSync(new URL('../../src/opnsense/www/js/firewall-map-grid-i18n.js', import.meta.url), 'utf8');
function adapter(lang) {
  const context = {document: {documentElement: {lang}}};
  vm.createContext(context); vm.runInContext(source, context);
  return context.FirewallMapGridI18n;
}
test('modern per-grid translations survive redraws and keep pagination placeholders', () => {
  const grid = {translations: {infos: 'Showing {{ctx.start}} to {{ctx.end}}'}};
  adapter('zh-CN').apply({data: () => grid});
  const format = (s, ctx) => s.replace(/{{ctx\.(\w+)}}/g, (_, k) => ctx[k]);
  assert.equal(format(grid.translations.infos, {start:1,end:11}), '显示第 1 至 11 条');
  assert.equal(format(grid.translations.infosTotal, {start:0,end:0,totalRows:0}), '显示第 0 至 0 条，共 0 条');
  assert.equal(adapter('zh-CN').tableOptions().langs['zh-cn'].pagination.next_title, '下一页');
});
test('English and Traditional Chinese grids retain system labels', () => {
  for (const language of ['en', 'zh-TW']) {
    const grid = {translations: {infos:'original'}};
    adapter(language).apply({data: () => grid});
    assert.equal(grid.translations.infos,'original');
    assert.equal(Object.keys(adapter(language).tableOptions()).length,0);
  }
});
