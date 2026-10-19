# Mihomo connections and connection activity

The fork adds an optional application connection source to Firewall Map+, alongside PF.
It activates automatically when `/usr/local/etc/mihomo/config.yaml` exists and the local
Mihomo controller can be read. It does not configure or start Mihomo, change routing,
or expose another API listener. Without a working controller, PF collection continues.

The collector reads the controller port and secret from that YAML using PyYAML, connects
only to loopback with proxy inheritance and redirects disabled, and never publishes the
secret. The package declares the matching OPNsense Python YAML dependency. The config
must have a TCP controller listening on IPv4 loopback (or a wildcard including loopback).
An interface-specific or Unix-socket-only controller is not supported.

## What is displayed

- Proxy connections from `/connections`, grouped by client and target; DIRECT remains a PF source.
- Actual `destinationIP` when it is public. A missing IP can use the controller's DNS query
  API to estimate a location. These locations are marked **DNS-estimated location** in
  details; they are not proof of the IP resolved by the remote SOCKS server.
- Domain, proxy chain, cumulative bytes and upload/download rates from adjacent counter samples.
  These are application bytes and connection counts, not PF states or interface totals.
- **Transferring**: at least one positive byte delta in the sampled client/target group.
- **Idle**: the group has a previous sample but no byte delta.
- **Awaiting sample**: a newly observed group, without a rate measurement yet.

Both the full map and dashboard hide idle connections by default. **Show idle connections**
reveals them without increasing the transferring count. The widget's pause icon controls
this view; its status is at the upper left so short widgets do not clip the counters.

PF collection, classification, threat history and native snapshot details retain their
existing scope. Mihomo connections are live-only and do not add synthetic PF state details
to snapshots. Activity counts cover located groups that fit the display budget; they are
not an inventory of every connection. Connections shorter than a sampling period can be
missed. PF's existing idle-fade behavior is unchanged.

## Bounds and failure behavior

A daemon thread polls roughly every two seconds, with a 0.8-second request timeout,
a 4 MiB response bound, at most 2,000 input connections, four DNS lookups per poll,
and 100 client/target groups. Location estimates cache for 30–300 seconds. The source
reports unresolved/omitted counts in `sources.mihomo`, clears rows on API failure and
expires stale results after ten seconds. API failures never interrupt the PF sampler.

## Localization

English source messages remain in `Metadata/FirewallMap.xml` and use the existing gettext
path. `renderer/locales/zh-CN.json` supplies plugin-owned Simplified Chinese fallback
translations for the new controls and common map text, without replacing OPNsense catalogs.
The server-rendered `<html lang>` selects the locale; browser language preferences do not
override the configured UI language. `zh-CN`, `zh_CN` and `zh-Hans` use Simplified Chinese;
other languages keep their gettext messages or the English defaults.

Change source modules under `renderer/`, not the generated `src/opnsense/www/js` bundles.
Run `sh tools/build-renderer.sh` to rebuild and test. Python tests:

```sh
python3 -m unittest discover -s security/firewall-map/tests
```

## 简体中文使用说明

1. 在 OPNsense 中选择简体中文界面，刷新完整地图和仪表盘。
2. 默认地图仅显示正在传输的 Mihomo 连接；状态栏分别显示传输、空闲和等待采样数量。
3. 完整地图点击“显示空闲连接”；仪表盘点击暂停图标，可查看空闲连接。
4. 速率按约两秒内的字节变化计算；首次出现的连接需等待下一次采样。
5. “DNS 估算位置”不代表远端 SOCKS 节点实际解析到的 IP；统计值也不等于接口总流量。
6. 本修改需要重新构建/安装此 fork 的插件包；仓库代码更新不会自动更新现有设备。
