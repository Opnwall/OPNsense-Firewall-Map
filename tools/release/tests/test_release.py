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

    def test_new_draft_uses_creation_response_when_list_lags(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder, feed = root / 'signed', root / 'feed'
            folder.mkdir()
            package = 'os-firewall-map-1.2_7.pkg'
            relative = Path('repo') / metadata.SERIES / metadata.ABI / package
            (feed / relative).parent.mkdir(parents=True)
            (folder / package).write_bytes(b'package')
            (feed / relative).write_bytes(b'package')
            (folder / 'SHA256SUMS').write_text('checksum')
            (folder / 'RELEASE_NOTES.md').write_text('release notes')
            meta = dict(version='1.2_7', tag='firewall-map-1.2_7', package=package,
                        source_commit='source', sha256=metadata.digest(folder / package))
            calls = []

            def command(*args, cwd=None):
                calls.append(args)
                if '--slurp' in args:
                    return '[[]]'  # The list still omits the newly created draft.
                if '--method' in args:
                    return json.dumps(dict(tag_name=meta['tag'], draft=True, assets=[]))
                if args[:3] == ('gh', 'release', 'download'):
                    target = Path(args[args.index('--dir') + 1])
                    for name in [package, 'SHA256SUMS']:
                        (target / name).write_bytes((folder / name).read_bytes())
                if args[:2] == ('gh', 'api') or args[:2] == ('git', 'hash-object'):
                    return 'blob'
                return ''

            with patch.object(publish, 'inspect_bundle', return_value=(meta, relative)), \
                    patch.object(publish, 'run', side_effect=command), \
                    patch.dict('os.environ', GITHUB_REPOSITORY='owner/repo'), \
                    patch.object(sys, 'argv', ['publish.py', str(folder), str(feed)]):
                publish.main()
            self.assertEqual(sum('--slurp' in call for call in calls), 1)
            self.assertTrue(any('--method' in call and 'draft=true' in call for call in calls))
            self.assertTrue(any(call[:3] == ('gh', 'release', 'edit') for call in calls))

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
