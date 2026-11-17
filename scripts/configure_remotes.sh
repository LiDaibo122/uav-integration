#!/usr/bin/env bash
# Configure local origins only; never creates repositories or pushes.
set -euo pipefail
owner="${1:-}"
if [[ ! "$owner" =~ ^[A-Za-z0-9][A-Za-z0-9-]{0,38}$ ]]; then
  printf '用法：bash scripts/configure_remotes.sh 你的GitHub用户名\n' >&2
  exit 2
fi
workspace="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
configure() {
  local directory="$1" name="$2" current url
  url="https://github.com/${owner}/${name}.git"
  git -C "$directory" rev-parse --git-dir >/dev/null
  current="$(git -C "$directory" remote get-url origin 2>/dev/null || true)"
  if [[ -n "$current" && "$current" != "$url" ]]; then
    printf '保留已有 origin：%s -> %s\n需要更换时请人工使用 git remote set-url。\n' "$directory" "$current" >&2
    return 1
  fi
  if [[ -z "$current" ]]; then git -C "$directory" remote add origin "$url"; fi
  git -C "$directory" config remote.pushDefault origin
  printf '\n%s\n' "$directory"
  git -C "$directory" remote -v
}
# Preflight all origins before changing any repository.
for pair in 'xd-uav-system:xd-uav-system' 'ground_station:uav-ground-station' 'uav-integration:uav-integration'; do
  directory="$workspace/${pair%%:*}"
  git -C "$directory" rev-parse --git-dir >/dev/null
  current="$(git -C "$directory" remote get-url origin 2>/dev/null || true)"
  expected="https://github.com/${owner}/${pair#*:}.git"
  if [[ -n "$current" && "$current" != "$expected" ]]; then
    printf '已有不同 origin，未作修改：%s -> %s\n' "$directory" "$current" >&2
    exit 1
  fi
done
configure "$workspace/xd-uav-system" xd-uav-system
configure "$workspace/ground_station" uav-ground-station
configure "$workspace/uav-integration" uav-integration
printf '\n本地 remote 已配置；未创建远程仓库、未推送。\n'
