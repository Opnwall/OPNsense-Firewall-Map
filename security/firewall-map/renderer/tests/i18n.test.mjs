import assert from 'node:assert/strict';
import fs from 'node:fs';
import {test} from 'node:test';
import {localizeText} from '../src/i18n.js';
import {DEFAULT_TEXT, textTable} from '../src/text.js';
import {statusParts} from '../src/host.js';

const zh = JSON.parse(fs.readFileSync(new URL('../locales/zh-CN.json', import.meta.url)));
const xml = fs.readFileSync(new URL('../../src/opnsense/www/js/widgets/Metadata/FirewallMap.xml', import.meta.url), 'utf8');
const messages = Object.fromEntries([...xml.matchAll(/<([a-z0-9_]+)>([^<]*)<\/\1>/g)].map(m => [m[1], m[2]]));

test('zh-CN/zh_CN/zh-Hans use the catalog; other UI languages retain their translations', () => {
  for (const locale of ['zh-CN', 'zh_CN', 'zh-Hans', 'zh-Hans-CN']) {
    assert.equal(localizeText(DEFAULT_TEXT, locale).map_show_idle, '显示空闲连接');
  }
  for (const locale of ['en', 'de', 'zh-TW', 'zh-Hant']) {
    assert.equal(localizeText(DEFAULT_TEXT, locale).map_show_idle, 'Show idle connections');
  }
});

test('catalog placeholders match their source strings', () => {
  const placeholders = value => [...value.matchAll(/\{\w+\}/g)].map(m => m[0]).sort();
  for (const [key, translation] of Object.entries(zh)) {
    if (key in messages) assert.deepEqual(placeholders(translation), placeholders(messages[key]), key);
  }
  for (const key of Object.keys(DEFAULT_TEXT).filter(key => /^map_(?:transferring|idle|pending|show_idle|hide_idle|dns_estimate|application_connection|proxy_chain)/.test(key))) {
    assert.equal(typeof zh[key], 'string', key);
  }
});

test('showing idle sessions does not inflate transmitting count in either locale', () => {
  for (const locale of ['en', 'zh-CN']) {
    const text = localizeText({...textTable({}), ...messages}, locale);
    const summary = {sources: {mihomo: {state: 'ok'}}, connection_activity: {},
      flows: [{source: 'mihomo', rate: 128}],
      idle_flows: [{source: 'mihomo', rate: 0, transfer_state: 'idle'}, {rate: 0, transfer_state: 'pending'}]};
    const settings = {blocks: false};
    const hidden = statusParts(summary, summary, settings, text);
    const shown = statusParts(summary, {...summary, flows: [...summary.flows, ...summary.idle_flows]}, settings, text);
    assert.deepEqual(hidden, shown);
    assert.match(shown.join(' '), locale === 'en' ? /1 transferring/ : /1 正在传输/);
    assert.equal(shown.length, 3);
  }
});

test('every widget and renderer message has a Chinese translation', () => {
  const block = xml.slice(xml.indexOf('<translations>'), xml.indexOf('</translations>'));
  for (const [, key] of block.matchAll(/<([a-z0-9_]+)>([^<]*)<\/\1>/g)) {
    assert.ok(zh[key], key);
  }
});
