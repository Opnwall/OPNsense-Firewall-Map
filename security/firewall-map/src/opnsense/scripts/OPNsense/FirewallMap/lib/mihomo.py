"""Optional, bounded localhost Mihomo source. DNS locations are explicitly estimates.

PF remains authoritative for firewall states. These are application connections,
not PF states; they are only added to live summaries, never PF snapshot details.
"""
import ipaddress
import json
import threading
import time
import urllib.parse
import urllib.request
from datetime import datetime


CONFIG = '/usr/local/etc/mihomo/config.yaml'
MAX_CONNECTIONS = 2000
MAX_VISIBLE = 100
MAX_BODY = 4 * 1024 * 1024


def public(value):
    try:
        address = ipaddress.ip_address(value)
        return address.is_global and not address.is_multicast
    except (ValueError, TypeError):
        return False


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Source:
    def __init__(self):
        self.lock = threading.Lock()
        self.rows = []
        self.status = {'state': 'starting'}
        self.previous = {}
        self.dns = {}
        self.thread = None
        # Never inherit HTTP_PROXY: credentials are sent only to loopback.
        self.opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), _NoRedirect())

    def request(self, path, secret, port):
        request = urllib.request.Request('http://127.0.0.1:%d%s' % (port, path),
                                         headers={'Authorization': 'Bearer ' + secret})
        with self.opener.open(request, timeout=0.8) as response:
            data = response.read(MAX_BODY + 1)
        if len(data) > MAX_BODY:
            raise ValueError('response size limit')
        return json.loads(data)

    def poll(self):
        import yaml  # optional source: a missing dependency cannot stop PF collection
        with open(CONFIG) as handle:
            config = yaml.safe_load(handle)
        port = int(str(config.get('external-controller', '')).rsplit(':', 1)[-1])
        secret = str(config.get('secret', ''))
        document = self.request('/connections', secret, port)
        now = time.monotonic()
        previous, rows, skipped, unresolved = {}, [], 0, 0
        dns_budget = 4
        connections = document.get('connections', [])
        if not isinstance(connections, list):
            raise ValueError('invalid connections')
        for connection in connections[:MAX_CONNECTIONS]:
            metadata = connection.get('metadata') or {}
            chains = connection.get('chains') or []
            # Direct connections remain the responsibility of the PF source.
            if not chains or chains[0] in ('DIRECT', 'REJECT', 'REJECT-DROP'):
                continue
            identity = str(connection.get('id', ''))
            uploaded = max(0, int(connection.get('upload', 0)))
            downloaded = max(0, int(connection.get('download', 0)))
            previous[identity] = (now, uploaded, downloaded)
            old = self.previous.get(identity)
            dt = max(0.1, now - old[0]) if old else 1
            up = max(0, uploaded - old[1]) / dt if old else 0
            down = max(0, downloaded - old[2]) / dt if old else 0
            host = str(metadata.get('host') or '')[:253]
            address = metadata.get('destinationIP')
            evidence = 'connection-ip'
            if not public(address):
                evidence = 'dns-estimate'
                cached = self.dns.get(host)
                if cached and cached[0] > now:
                    address = cached[1]
                elif host and dns_budget:
                    dns_budget -= 1
                    try:
                        answer = self.request('/dns/query?' + urllib.parse.urlencode({'name': host, 'type': 'A'}), secret, port)
                        record = next((a for a in answer.get('Answer', [])
                                       if a.get('type') == 1 and public(a.get('data'))), None)
                        address = record['data'] if record else None
                        ttl = max(30, min(300, int(record.get('TTL', 30)))) if record else 30
                        self.dns[host] = (now + ttl, address)
                    except Exception:
                        self.dns[host] = (now + 10, None)
                        address = None
                else:
                    address = None
            if not public(address):
                unresolved += 1
                continue
            owner = metadata.get('sourceIP')
            try:
                ipaddress.ip_address(owner)
            except (ValueError, TypeError):
                skipped += 1
                continue
            try:
                age = max(0, time.time() - datetime.fromisoformat(connection['start']).timestamp())
            except (KeyError, ValueError):
                age = 0
            port_number = str(metadata.get('destinationPort') or '')
            protocol = str(metadata.get('network') or 'tcp').lower()
            label = 'Mihomo: ' + ' → '.join(reversed(chains))
            if evidence == 'dns-estimate':
                label += ' · DNS-estimated location'
            rows.append({'id': identity, 'remote': address, 'host': host, 'owner': owner,
                         'evidence': evidence, 'chains': chains, 'label': label,
                         'sampled': old is not None,
                         'flow': {'rate': up + down, 'rate_in': down, 'rate_out': up,
                                  'packet_rate': 0, 'states': 0, 'protocols': [protocol],
                                  'services': ['Mihomo'], 'service_ports': {'Mihomo': port_number + '/' + protocol},
                                  'inside': [owner], 'owner': owner, 'egress': 'Mihomo',
                                  'initiated': 'local', 'targets': [], 'age': age,
                                  'transferred': [downloaded, uploaded], 'rule': None}})
        # Aggregate application sessions by client and target; never count a PF state.
        grouped = {}
        for row in rows:
            key = (row['owner'], row['remote'])
            if key not in grouped:
                grouped[key] = row
                row['sessions'] = 1
                row['sampled_sessions'] = int(row['sampled'])
                continue
            total = grouped[key]
            total['sessions'] += 1
            total['sampled_sessions'] += int(row['sampled'])
            for field in ('rate', 'rate_in', 'rate_out'):
                total['flow'][field] += row['flow'][field]
            total['flow']['transferred'] = [a+b for a,b in zip(total['flow']['transferred'], row['flow']['transferred'])]
            total['flow']['protocols'] = sorted(set(total['flow']['protocols'] + row['flow']['protocols']))
            if row['evidence'] == 'dns-estimate':
                total['evidence'] = 'dns-estimate'
                if 'DNS' not in total['label']:
                    total['label'] += ' · DNS-estimated location'
        rows = list(grouped.values())
        rows.sort(key=lambda row: row['flow']['rate'], reverse=True)
        self.previous = previous
        self.dns = {h: v for h, v in self.dns.items() if v[0] > now}
        with self.lock:
            self.rows = rows[:MAX_VISIBLE]
            self.status = {'state': 'ok', 'updated_at': time.time(), 'connections': len(connections),
                           'visible': len(self.rows), 'unresolved': unresolved, 'skipped': skipped,
                           'omitted': max(0, len(connections) - MAX_CONNECTIONS) + max(0, len(rows) - MAX_VISIBLE),
                           'scope': 'live-only', 'dns_locations': 'estimated; not the SOCKS server resolved IP'}

    def run(self):
        while True:
            try:
                self.poll()
            except Exception as error:
                with self.lock:
                    self.rows = []
                    self.status = {'state': 'unavailable', 'error': type(error).__name__}
            time.sleep(2)

    def read(self):
        with self.lock:
            if self.thread is None:
                self.thread = threading.Thread(target=self.run, name='firewallmap-mihomo', daemon=True)
                self.thread.start()
            if time.time() - self.status.get('updated_at', time.time()) > 10:
                return [], {'state': 'stale'}
            return list(self.rows), dict(self.status)


SOURCE = Source()


def append_visible(visible, local_addresses):
    rows, status = SOURCE.read()
    # Use the firewall's public anchor; preserve client identity in owner/inside.
    origin = next((address for address in sorted(local_addresses) if public(address)), None)
    if origin is None:
        return list(visible), {}, status
    result, labels = list(visible), {}
    pairs = {(local, remote, flow.get('owner')) for _, local, remote, flow, _ in visible}
    for row in rows:
        key = (origin, row['remote'], row['owner'])
        if key in pairs:
            continue
        pairs.add(key)
        result.append((row['flow']['rate'], origin, row['remote'], row['flow'], 1.0 if row['flow']['rate'] > 0 else 0.0))
        labels[(row['remote'], row['owner'])] = row
    return result, labels, status
