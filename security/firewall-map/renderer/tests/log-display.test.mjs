import assert from 'node:assert/strict';
import fs from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
const source = fs.readFileSync(new URL('../../src/opnsense/www/js/firewall-map-log.js', import.meta.url), 'utf8');
function display(language) {
  const context = {document: {documentElement: {lang: language}}};
  vm.createContext(context); vm.runInContext(source, context);
  return context.FirewallMapLogDisplay;
}
test('log display translates historical DNS failures without rewriting originals', () => {
  const d = display('zh-CN');
  const raw = 'GeoLite2-City: <urlopen error [Errno 2] Name could not be resolved at this time> (unreachable)';
  assert.match(d.translate(raw), /DNS 错误/);
  assert.match(d.translate(' ' + raw), /DNS 错误/);
  assert.match(d.translate(' collector started: a map is open'), /采集器已启动/);
  assert.match(d.line(raw), /title="GeoLite2-City:/);
  assert.equal(display('en').translate(raw), raw);
  assert.equal(d.severity('Warning'), '警告');
  assert.match(d.translate('geolocation download failed (4 in a row): next try in 15 min'), /4 次.*15 分钟/);
  assert.match(d.translate('GeoLite2-ASN downloaded: 8.6 MB, built 2026-10-18'), /下载成功/);
});
test('unknown or hostile log lines remain escaped, not executable HTML', () => {
  assert.equal(display('zh-CN').translate('unrecognized'), 'unrecognized');
  const html = display('zh-CN').line('<img src=x onerror=alert(1)>');
  assert.ok(!html.includes('<img'));
  assert.ok(html.includes('&lt;img'));
});
