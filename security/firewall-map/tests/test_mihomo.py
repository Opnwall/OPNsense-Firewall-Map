"""Application counters must not become PF states or fabricated first-sample traffic."""
import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src/opnsense/scripts/OPNsense/FirewallMap'))
from lib import mihomo


class MihomoTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        config = Path(self.temp.name) / 'config.yaml'
        config.write_text('external-controller: 0.0.0.0:9090\nsecret: test-only\n')
        patch = mock.patch.object(mihomo, 'CONFIG', str(config))
        patch.start()
        self.addCleanup(patch.stop)
        self.source = mihomo.Source()
        self.connection = {'id': 'one', 'upload': 100, 'download': 200,
                           'metadata': {'sourceIP': '192.168.1.2', 'destinationIP': '8.8.8.8',
                                        'destinationPort': '443', 'network': 'tcp'},
                           'chains': ['node', 'Auto']}
        self.document = {'connections': [self.connection]}
        self.source.request = mock.Mock(side_effect=lambda *args: copy.deepcopy(self.document))

    def sample(self, when):
        with mock.patch.object(mihomo.time, 'monotonic', return_value=when):
            self.source.poll()
        return self.source.rows

    def test_first_sample_idle_transfer_idle_and_close(self):
        rows = self.sample(10)
        self.assertEqual(rows[0]['flow']['rate'], 0)
        self.assertEqual(rows[0]['sampled_sessions'], 0)
        rows = self.sample(12)
        self.assertEqual(rows[0]['sampled_sessions'], 1)
        self.assertEqual(rows[0]['flow']['rate'], 0)
        self.connection['download'] += 1000
        self.connection['upload'] += 200
        rows = self.sample(14)
        self.assertEqual(rows[0]['flow']['rate_in'], 500)
        self.assertEqual(rows[0]['flow']['rate_out'], 100)
        self.assertEqual(rows[0]['flow']['states'], 0)
        self.assertEqual(rows[0]['flow']['service_ports'], {'Mihomo': '443/tcp'})
        self.assertEqual(self.sample(16)[0]['flow']['rate'], 0)
        self.document['connections'] = []
        self.assertEqual(self.sample(18), [])
        self.assertEqual(self.source.previous, {})

    def test_counter_reset_never_creates_negative_rates(self):
        self.sample(10)
        self.connection['download'] = self.connection['upload'] = 0
        self.assertEqual(self.sample(12)[0]['flow']['rate'], 0)

    def test_sessions_aggregate_by_client_and_target_without_double_counting(self):
        second = copy.deepcopy(self.connection)
        second['id'] = 'two'
        self.document['connections'].append(second)
        self.sample(10)
        self.connection['download'] += 100
        second['download'] += 300
        rows = self.sample(12)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['sessions'], 2)
        self.assertEqual(rows[0]['flow']['rate_in'], 200)
        self.assertEqual(rows[0]['flow']['transferred'][0], 800)

    def test_direct_connections_are_left_to_pf(self):
        self.connection['chains'] = ['DIRECT']
        self.assertEqual(self.sample(10), [])

    def test_dns_fallback_is_explicitly_estimated_and_never_maps_fake_ip(self):
        self.connection['metadata'].update(destinationIP='', host='example.org')
        self.source.request.side_effect = lambda path, *args: copy.deepcopy(self.document) if path == '/connections' else {
            'Answer': [{'type': 1, 'data': '198.18.1.1', 'TTL': 60},
                       {'type': 1, 'data': '8.8.8.8', 'TTL': 60}]}
        rows = self.sample(10)
        self.assertEqual(rows[0]['remote'], '8.8.8.8')
        self.assertEqual(rows[0]['evidence'], 'dns-estimate')

    def test_idle_activity_zero_and_source_failure_preserves_pf(self):
        self.sample(10)
        self.sample(12)
        self.source.thread = True  # do not start a live background worker in this test
        pf = [(1, '1.1.1.1', '9.9.9.9', {'owner': None}, 1)]
        with mock.patch.object(mihomo, 'SOURCE', self.source):
            visible, labels, status = mihomo.append_visible(pf, {'1.1.1.1'})
            self.assertEqual(visible[0], pf[0])
            self.assertEqual(visible[1][-1], 0)
            self.source.request.side_effect = OSError('offline')
            with mock.patch.object(mihomo.time, 'sleep', side_effect=InterruptedError):
                with self.assertRaises(InterruptedError):
                    self.source.run()
            visible, labels, status = mihomo.append_visible(pf, {'1.1.1.1'})
            self.assertEqual(visible, pf)
            self.assertEqual(status['state'], 'unavailable')
            self.assertNotIn('test-only', json.dumps(status))


if __name__ == '__main__':
    unittest.main()
