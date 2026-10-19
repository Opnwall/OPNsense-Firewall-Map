#!/usr/bin/env python3
"""One version and release-note source for both publication channels."""
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SERIES = '26.7'
ABI = 'FreeBSD:15:amd64'


def version(root=ROOT):
    text = (root / 'security/firewall-map/Makefile').read_text()
    def field(key):
        return re.search(r'^' + key + r'\s*=\s*([^\s#]+)', text, re.M)[1]
    base, revision = field('PLUGIN_VERSION'), field('PLUGIN_REVISION')
    if not re.fullmatch(r'\d+(?:\.\d+)+', base) or not revision.isdigit():
        raise ValueError('Invalid package version')
    return base + ('_' + revision if int(revision) else '')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def describe(root=ROOT):
    value = version(root)
    tag = 'firewall-map-' + value
    notes = root / 'releases' / (tag + '.md')
    if not notes.is_file() or not notes.read_text().strip():
        raise ValueError('Add release notes at ' + str(notes))
    return dict(version=value, tag=tag, package=f'os-firewall-map-{value}.pkg',
                series=SERIES, abi=ABI,
                source_commit=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip())


def bundle(directory):
    directory = Path(directory)
    meta = describe()
    archive = directory / meta['package']
    meta['sha256'] = digest(archive)
    (directory / 'SHA256SUMS').write_text(f"{meta['sha256']}  {meta['package']}\n")
    (directory / 'release.json').write_text(json.dumps(meta, indent=2) + '\n')
    notes = (ROOT / 'releases' / (meta['tag'] + '.md')).read_text().rstrip()
    # Each version's notes describe behavior; install/version/checksum are generated once.
    notes += f'''\n\n## 安装包与签名源\n\n版本：**{meta['version']}**；平台：OPNsense {SERIES} / {ABI}。\n本页安装包与 OpnwallDashboardPlus 签名源使用同一构建产物。\n\n```sh\npkg update -r OpnwallDashboardPlus\npkg upgrade -y -r OpnwallDashboardPlus os-firewall-map\n```\n\n独立安装前备份并校验 SHA256SUMS，再执行 `pkg add -f ./{meta['package']}`。\nmacOS 可用 `shasum -a 256 -c SHA256SUMS` 校验；FreeBSD 用 `sha256 -q {meta['package']}` 与文件中的摘要比较。\n升级后刷新地图和仪表盘。\n\n```text\n{meta['sha256']}  {meta['package']}\n```\n\n源码提交：`{meta['source_commit']}`。\n'''
    (directory / 'RELEASE_NOTES.md').write_text(notes)
    return meta


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['metadata', 'bundle'])
    parser.add_argument('directory', nargs='?')
    args = parser.parse_args()
    result = describe() if args.command == 'metadata' else bundle(args.directory)
    if args.command == 'metadata':
        ref, kind = os.getenv('GITHUB_REF_NAME'), os.getenv('GITHUB_REF_TYPE')
        if kind == 'tag' and ref != result['tag']:
            raise SystemExit('Tag must equal Makefile version: ' + result['tag'])
        if os.getenv('GITHUB_EVENT_NAME') == 'workflow_dispatch' and ref != 'main':
            raise SystemExit('Manual releases must run from main')
        if os.getenv('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as stream:
                for key, value in result.items():
                    stream.write(f'{key}={value}\n')
    print(json.dumps(result))
