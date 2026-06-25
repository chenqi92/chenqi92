#!/usr/bin/env bash
# 用 GitHub 公开数据生成终端风格统计卡片 metrics/terminal.svg
# 仅读公开信息，默认 GITHUB_TOKEN 即可，无需 PAT
# 用法: bash scripts/gen-stats-svg.sh <github_user>
set -euo pipefail

USER="${1:-chenqi92}"
OUT="metrics/terminal.svg"

# 账户信息
U="$(gh api "users/${USER}")"
followers="$(jq -r '.followers' <<<"$U")"
public_repos="$(jq -r '.public_repos' <<<"$U")"
following="$(jq -r '.following' <<<"$U")"
created="$(jq -r '.created_at' <<<"$U")"
created_year="${created:0:4}"

# 自有非 fork 仓库聚合（分页后用 jq -s add 合并成单个数组）
REPOS="$(gh api --paginate "users/${USER}/repos?per_page=100&type=owner" | jq -s 'add')"
stars="$(jq '[.[] | select(.fork==false) | .stargazers_count] | add // 0' <<<"$REPOS")"
orig_repos="$(jq '[.[] | select(.fork==false)] | length' <<<"$REPOS")"
forks="$(jq '[.[] | select(.fork==false) | .forks_count] | add // 0' <<<"$REPOS")"

# GitHub 年龄与截至月份
now_year="$(date -u +%Y)"
age="$((now_year - created_year))"
asof="$(date -u +%Y-%m)"

mkdir -p metrics
cat >"$OUT" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 860 330" width="860" height="330" font-family="'JetBrains Mono','Fira Code','Cascadia Code',ui-monospace,'SFMono-Regular',Menlo,Consolas,'PingFang SC','Microsoft YaHei','Noto Sans CJK SC',sans-serif">
  <!-- window -->
  <rect x="0.5" y="0.5" width="859" height="329" rx="12" fill="#0d1117" stroke="#30363d"/>
  <!-- title bar -->
  <rect x="1" y="1" width="858" height="40" rx="11" fill="#161b22"/>
  <rect x="1" y="22" width="858" height="19" fill="#161b22"/>
  <line x1="1" y1="41" x2="859" y2="41" stroke="#30363d"/>
  <circle cx="26" cy="21" r="6" fill="#ff5f56"/>
  <circle cx="48" cy="21" r="6" fill="#ffbd2e"/>
  <circle cx="70" cy="21" r="6" fill="#27c93f"/>
  <text x="430" y="26" fill="#8b949e" font-size="13" text-anchor="middle">programApe@github: ~/dev — gh-metrics</text>

  <!-- heading -->
  <text x="26" y="78" font-size="15"><tspan fill="#27c93f">\$</tspan><tspan fill="#c9d1d9" dx="9">gh-metrics --summary</tspan></text>

  <!-- dividers -->
  <line x1="215.5" y1="118" x2="215.5" y2="212" stroke="#21262d"/>
  <line x1="430.5" y1="118" x2="430.5" y2="212" stroke="#21262d"/>
  <line x1="645.5" y1="118" x2="645.5" y2="212" stroke="#21262d"/>

  <!-- tiles -->
  <g text-anchor="middle">
    <text x="108" y="170" font-size="42" font-weight="700" fill="#39d353">${stars}</text>
    <text x="108" y="198" font-size="13" fill="#8b949e">获得 Star</text>

    <text x="323" y="170" font-size="42" font-weight="700" fill="#39d353">${public_repos}</text>
    <text x="323" y="198" font-size="13" fill="#8b949e">公开仓库</text>

    <text x="538" y="170" font-size="42" font-weight="700" fill="#39d353">${followers}</text>
    <text x="538" y="198" font-size="13" fill="#8b949e">关注者</text>

    <text x="753" y="170" font-size="42" font-weight="700" fill="#39d353">${age}<tspan font-size="22" fill="#56b6c2">y</tspan></text>
    <text x="753" y="198" font-size="13" fill="#8b949e">GitHub 年龄</text>
  </g>

  <!-- secondary line -->
  <text x="26" y="248" font-size="13.5" fill="#abb2bf">原创仓库 <tspan fill="#c9d1d9">${orig_repos}</tspan>  ·  Fork <tspan fill="#c9d1d9">${forks}</tspan>  ·  Following <tspan fill="#c9d1d9">${following}</tspan>  ·  主力语言 <tspan fill="#dea584">Rust</tspan> / <tspan fill="#3178c6">TypeScript</tspan> / <tspan fill="#f05138">Swift</tspan></text>

  <!-- note -->
  <text x="26" y="278" font-size="12.5" fill="#6e7681"># 截至 ${asof} · 基于 GitHub 公开数据自动统计</text>

  <!-- cursor -->
  <text x="26" y="312" font-size="15"><tspan fill="#27c93f">\$</tspan></text>
  <rect x="44" y="301" width="9" height="15" fill="#27c93f">
    <animate attributeName="opacity" values="1;1;0;0" dur="1.1s" repeatCount="indefinite"/>
  </rect>
</svg>
SVG

echo "wrote ${OUT}: stars=${stars} public_repos=${public_repos} followers=${followers} orig=${orig_repos} forks=${forks} following=${following} age=${age}"
