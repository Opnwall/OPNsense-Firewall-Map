import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import metadata
import publish


class ReleaseTest(unittest.TestCase):
    def test_version_derives_from_makefile_revision(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / 'security/firewall-map/Makefile'
            path.parent.mkdir(parents=True)
            path.write_text('PLUGIN_VERSION= 1.2\nPLUGIN_REVISION= 7\n')
            self.assertEqual(metadata.version(root), '1.2_7')
            path.write_text('PLUGIN_VERSION= 1.2\nPLUGIN_REVISION= 0\n')
            self.assertEqual(metadata.version(root), '1.2')

    def test_published_version_is_immutable(self):
        publish.check_immutable(None, 'new')
        publish.check_immutable('same', 'same')
        with self.assertRaisesRegex(ValueError, 'PLUGIN_REVISION'):
            publish.check_immutable('old', 'new')

    def test_bundle_rejects_release_feed_divergence(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            meta = dict(metadata.describe(), sha256=metadata.digest(__file__))
            package = root / meta['package']
            package.write_bytes(Path(__file__).read_bytes())
            (root / 'release.json').write_text(json.dumps(meta))
            (root / 'SHA256SUMS').write_text(f"{meta['sha256']}  {meta['package']}\n")
            feed = root / 'repo' / metadata.SERIES / metadata.ABI
            feed.mkdir(parents=True)
            (feed / package.name).write_bytes(b'different')
            manifest = json.dumps({'name':'os-firewall-map','version':meta['version'],'abi':metadata.ABI})
            with patch.object(publish, 'run', return_value=manifest):
                with self.assertRaisesRegex(ValueError, 'Release/feed'):
                    publish.inspect_bundle(root)
            (feed / package.name).write_bytes(package.read_bytes())
            for name in ['data','packagesite']:
                (feed / (name + '.pkg')).write_bytes(b'catalog')
                (feed / (name + '.tzst')).write_bytes(b'catalog')
            with patch.object(publish, 'run', return_value=manifest):
                publish.inspect_bundle(root)
                (feed / 'data.tzst').write_bytes(b'old')
                with self.assertRaisesRegex(ValueError, 'Stale catalog'):
                    publish.inspect_bundle(root)


if __name__ == '__main__':
    unittest.main()
