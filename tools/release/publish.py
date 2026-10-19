#!/usr/bin/env python3
"""Promote one verified artifact to a signed feed and a GitHub Release.

A draft is prepared first, the feed is pushed with an optimistic lock, then the Release
is made public. Retrying this job with the SAME artifact resumes partial publication.
Published versions are immutable; rebuilding an existing version never overwrites it.
"""
import argparse
import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from metadata import ABI, SERIES, describe, digest


def run(*args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def inspect_bundle(folder):
    meta = json.loads((folder / 'release.json').read_text())
    for key, value in describe().items():
        if meta.get(key) != value:
            raise ValueError('Artifact/source mismatch: ' + key)
    package = folder / meta['package']
    if digest(package) != meta['sha256']:
        raise ValueError('Artifact checksum mismatch')
    expected = f"{meta['sha256']}  {meta['package']}\n"
    if (folder / 'SHA256SUMS').read_text() != expected:
        raise ValueError('SHA256SUMS mismatch')
    manifest = json.loads(run('tar', '-xOf', str(package), '+COMPACT_MANIFEST'))
    if (manifest['name'], manifest['version'], manifest['abi']) != ('os-firewall-map', meta['version'], ABI):
        raise ValueError('Package manifest mismatch')
    relative = Path('repo') / SERIES / ABI / meta['package']
    if digest(folder / relative) != meta['sha256']:
        raise ValueError('Release/feed package mismatch')
    for name in ['data', 'packagesite']:
        parent = (folder / relative).parent
        if (parent / (name + '.pkg')).read_bytes() != (parent / (name + '.tzst')).read_bytes():
            raise ValueError('Stale catalog alias: ' + name)
    return meta, relative


def check_immutable(existing, expected):
    if existing and existing != expected:
        raise ValueError('Version already published with a different checksum; bump PLUGIN_REVISION')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('folder', type=Path)
    parser.add_argument('feed', type=Path)
    parser.add_argument('--verify-only', action='store_true')
    args = parser.parse_args()
    folder, feed = args.folder.resolve(), args.feed.resolve()
    meta, relative = inspect_bundle(folder)
    if args.verify_only:
        print('Verified artifact identity, manifest, checksums and catalog aliases (no publication)')
        return
    repository = os.environ['GITHUB_REPOSITORY']
    tag, package_name = meta['tag'], meta['package']
    current = feed / relative
    check_immutable(digest(current) if current.exists() else None, meta['sha256'])
    # Refuse downgrade even when a previously published artifact is being replayed.
    def version_key(value):
        base, _, revision = value.partition('_')
        return tuple(map(int, base.split('.'))), int(revision or 0)
    for path in current.parent.glob('os-firewall-map-*.pkg'):
        other = path.name.removeprefix('os-firewall-map-').removesuffix('.pkg')
        if version_key(other) > version_key(meta['version']):
            raise ValueError('Refusing feed downgrade')
    # Distinguish a missing release from authentication, network or API failures.
    releases = json.loads(run('gh', 'api', '--paginate', '--slurp', f'repos/{repository}/releases'))
    release = next((r for page in releases for r in page if r['tag_name'] == tag), None)
    if release:
        if not release['draft'] and not any(a['name'] == package_name for a in release['assets']):
            raise ValueError('Published Release is missing its package; manual repair required')
        for asset in release['assets']:
            if asset['name'] == package_name:
                if asset.get('digest'):
                    check_immutable(asset['digest'].removeprefix('sha256:'), meta['sha256'])
                else:
                    with tempfile.TemporaryDirectory() as directory:
                        run('gh', 'release', 'download', tag, '--repo', repository, '--pattern', package_name, '--dir', directory)
                        check_immutable(digest(Path(directory) / package_name), meta['sha256'])
    elif not current.exists():
        # Ensure no unrelated feed commit will be overwritten after signing.
        if run('git', 'rev-parse', 'HEAD', cwd=feed) != (folder / 'feed-base.txt').read_text().strip():
            raise ValueError('Feed changed during signing; restart from the signing job')
    if not release:
        run('gh', 'release', 'create', tag, '--repo', repository, '--target', meta['source_commit'],
            '--title', f"Firewall Map {meta['version']}", '--notes-file', str(folder / 'RELEASE_NOTES.md'), '--draft')
        pages = json.loads(run('gh', 'api', '--paginate', '--slurp', f'repos/{repository}/releases'))
        release = next(r for page in pages for r in page if r['tag_name'] == tag)
    for name in [package_name, 'SHA256SUMS']:
        asset = next((a for a in release['assets'] if a['name'] == name), None)
        if asset and asset.get('digest'):
            check_immutable(asset['digest'].removeprefix('sha256:'), digest(folder / name))
        elif not asset:
            run('gh', 'release', 'upload', tag, str(folder / name), '--repo', repository)
    # Verify actual uploaded bytes, including resumed drafts, before making the feed visible.
    with tempfile.TemporaryDirectory() as directory:
        run('gh', 'release', 'download', tag, '--repo', repository, '--pattern', package_name,
            '--pattern', 'SHA256SUMS', '--dir', directory)
        for name in [package_name, 'SHA256SUMS']:
            if digest(Path(directory) / name) != digest(folder / name):
                raise ValueError('Uploaded asset mismatch: ' + name)
    if not current.exists():
        if run('git', 'rev-parse', 'HEAD', cwd=feed) != (folder / 'feed-base.txt').read_text().strip():
            raise ValueError('Feed changed during signing')
        shutil.copytree(folder / 'repo', feed / 'repo', dirs_exist_ok=True)
        # Remove superseded archives only for this package and ABI; other packages are preserved.
        for path in current.parent.glob('os-firewall-map-*.pkg'):
            if path.name != package_name:
                path.unlink()
        run('git', 'config', 'user.name', 'github-actions[bot]', cwd=feed)
        run('git', 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com', cwd=feed)
        run('git', 'add', 'repo', cwd=feed)
        run('git', 'commit', '-m', f"Publish signed Firewall Map {meta['version']}", cwd=feed)
        run('git', 'push', 'origin', 'HEAD:packages', cwd=feed)  # no force; races fail safely
    # Confirm the pushed Git blob matches the release artifact (avoid raw-URL cache).
    remote = run('gh', 'api', f'repos/{repository}/contents/{relative.as_posix()}?ref=packages', '--jq', '.sha')
    if remote != run('git', 'hash-object', str(folder / package_name)):
        raise ValueError('Published feed package mismatch')
    run('gh', 'release', 'edit', tag, '--repo', repository, '--notes-file', str(folder / 'RELEASE_NOTES.md'),
        '--draft=false', '--latest')
    print(f"Published {tag}; feed and Release SHA256 {meta['sha256']}")


if __name__ == '__main__':
    main()
