import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('feed_history', Path(__file__).resolve().parents[1] / 'record-feed-history.py')
history = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(history)


class FeedHistoryTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.remote, self.repo = self.root / 'remote.git', self.root / 'work'
        subprocess.run(['git', 'init', '--bare', str(self.remote)], check=True, capture_output=True)
        subprocess.run(['git', 'init', '-b', 'main', str(self.repo)], check=True, capture_output=True)
        self.git('config', 'user.name', 'Test')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('remote', 'add', 'origin', str(self.remote))
        (self.repo / 'source').write_text('source')
        self.git('add', 'source')
        self.git('commit', '-m', 'Source')
        self.main = self.git('rev-parse', 'HEAD')
        self.tree = self.git('rev-parse', 'HEAD^{tree}')
        # The real feed began as an unrelated root; preserve that case.
        self.feed = self.git('commit-tree', self.tree, '-m', 'Feed root')
        self.git('push', 'origin', 'HEAD:refs/heads/main', self.feed + ':refs/heads/packages')

    def git(self, *args):
        return history.git(self.repo, *args)

    def remote_main(self):
        return subprocess.check_output(['git', '--git-dir', str(self.remote), 'rev-parse', 'main'], text=True).strip()

    def test_preserves_tree_and_feed_and_is_idempotent(self):
        history.record(self.repo)
        merged = self.remote_main()
        self.assertEqual(self.git('rev-parse', merged + '^{tree}'), self.tree)
        self.assertEqual(self.git('show', '-s', '--format=%P', merged).split(), [self.main, self.feed])
        self.assertEqual(self.git('rev-parse', 'origin/packages'), self.feed)
        history.record(self.repo)
        self.assertEqual(self.remote_main(), merged)

    def test_concurrent_main_update_is_preserved_on_retry(self):
        real_run = subprocess.run
        updated = None

        def racing_run(args, **kwargs):
            nonlocal updated
            if args[:3] == ['git', 'push', 'origin'] and updated is None:
                (self.repo / 'source').write_text('new user changes')
                self.git('add', 'source')
                new_tree = self.git('write-tree')
                updated = self.git('commit-tree', new_tree, '-p', self.main, '-m', 'Concurrent user change')
                real_run(['git', 'push', 'origin', updated + ':refs/heads/main'], cwd=self.repo, check=True, capture_output=True)
            return real_run(args, **kwargs)

        with patch.object(history.subprocess, 'run', side_effect=racing_run):
            history.record(self.repo)
        merged = self.remote_main()
        self.assertEqual(self.git('show', '-s', '--format=%P', merged).split(), [updated, self.feed])
        self.assertEqual(self.git('show', merged + ':source'), 'new user changes')
