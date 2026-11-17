#!/usr/bin/env python3
"""Record committed ground/XD revisions, or check the saved baseline."""
import argparse
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def revision(path):
    try:
        head = subprocess.check_output(['git', '-C', str(path), 'rev-parse', '--verify', 'HEAD'], stderr=subprocess.DEVNULL, text=True).strip()
    except subprocess.CalledProcessError:
        raise SystemExit(str(path)+': 尚未首次提交，请先 git commit')
    dirty = subprocess.check_output(['git', '-C', str(path), 'status', '--porcelain'], text=True)
    if dirty:
        raise SystemExit(str(path)+': 有未提交改动，请先提交再记录基线')
    return head


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    path = ROOT/'versions.lock.json'
    data = json.loads(path.read_text())
    heads = {'xd': revision(ROOT.parent/'xd-uav-system'), 'ground': revision(ROOT.parent/'ground_station')}
    for name, head in heads.items():
        if args.check and data[name]['commit'] != head:
            raise SystemExit(name+': 与记录版本不一致')
        data[name]['commit'] = head
    if not args.check:
        data['status'] = 'source_revisions_recorded_runtime_integration_pending'
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps(heads, indent=2))


if __name__ == '__main__':
    main()
