#!/usr/bin/env python3
"""Record feed ancestry in main without importing files or rewriting either branch."""
import argparse
import subprocess
from pathlib import Path


def git(repo, *args):
    return subprocess.check_output(['git', *args], cwd=repo, text=True).strip()


def record(repo, attempts=3):
    for attempt in range(attempts):
        git(repo, 'fetch', 'origin',
            '+refs/heads/main:refs/remotes/origin/main',
            '+refs/heads/packages:refs/remotes/origin/packages')
        main = git(repo, 'rev-parse', 'refs/remotes/origin/main')
        feed = git(repo, 'rev-parse', 'refs/remotes/origin/packages')
        ancestor = subprocess.run(['git', 'merge-base', '--is-ancestor', feed, main], cwd=repo)
        if ancestor.returncode == 0:
            print('Signed feed history already recorded; no commit needed')
            return
        if ancestor.returncode != 1:
            ancestor.check_returncode()
        tree = git(repo, 'rev-parse', main + '^{tree}')
        commit = git(repo, '-c', 'user.name=github-actions[bot]', '-c',
            'user.email=41898282+github-actions[bot]@users.noreply.github.com',
            'commit-tree', tree, '-p', main, '-p', feed, '-m',
            'Record signed feed publication history without importing package files')
        # Ordinary fast-forward push: a concurrent main update is never overwritten.
        result = subprocess.run(['git', 'push', 'origin', commit + ':refs/heads/main'], cwd=repo)
        if result.returncode == 0:
            print('Recorded signed feed history with unchanged source tree: ' + commit)
            return
        if attempt + 1 == attempts:
            result.check_returncode()
        print('Push failed; refetching current branches before retry')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repository', nargs='?', type=Path, default=Path('.'))
    record(parser.parse_args().repository.resolve())
