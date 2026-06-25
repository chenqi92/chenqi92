#!/usr/bin/env bash
# 用 GitHub 真实语言字节生成技术栈条形图 assets/skills.svg
# 聚合自有非 fork 仓库的 languages 字节，过滤标记类语言，取前 6，按比例画条
# 仅读公开信息，默认 GITHUB_TOKEN 即可，无需 PAT
# 用法: bash scripts/gen-skills-svg.sh <github_user>
set -euo pipefail

USER="${1:-chenqi92}"
OUT="assets/skills.svg"
TRACK=664   # 条形轨道宽度（x=170 起）

# Linguist 配色（个别过暗的在深色底上做了提亮）
color_for() {
  case "$1" in
    TypeScript)   echo "#3178c6";;
    JavaScript)   echo "#f1e05a";;
    Dart)         echo "#00b4ab";;
    Rust)         echo "#dea584";;
    Swift)        echo "#f05138";;
    C)            echo "#a8b1bb";;
    "C++")        echo "#f34b7d";;
    Java)         echo "#e3a33c";;
    Python)       echo "#4b8bbe";;
    Kotlin)       echo "#a97bff";;
    Go)           echo "#00add8";;
    Vue)          echo "#41b883";;
    "C#")         echo "#2ea043";;
    Shell)        echo "#89e051";;
    Ruby)         echo "#e0506a";;
    PHP)          echo "#8993be";;
    Astro)        echo "#ff5d01";;
    "Objective-C") echo "#438eff";;
    *)            echo "#8b949e";;
  esac
}

# 标记 / 配置类语言不计入「主要技术栈」
DENY="HTML CSS SCSS Less Stylus Vue MDX Markdown TeX Roff Batchfile Dockerfile Makefile CMake Gnuplot Jupyter HCL"

repos="$(gh api --paginate "users/${USER}/repos?per_page=100&type=owner" --jq '.[] | select(.fork==false) | .full_name')"

agg="$(
  for r in $repos; do
    gh api "repos/${r}/languages" --jq 'to_entries[] | "\(.key)\t\(.value)"'
  done | awk -F'\t' '{a[$1]+=$2} END{for(k in a) printf "%d\t%s\n", a[k], k}'
)"

top="$(
  echo "$agg" \
    | awk -F'\t' -v deny="$DENY" 'BEGIN{n=split(deny,d," ");for(i=1;i<=n;i++)D[d[i]]=1} !($2 in D)' \
    | sort -rn | head -6
)"

names=(); bytes=()
while IFS=$'\t' read -r b n; do
  [ -z "${n:-}" ] && continue
  bytes+=("$b"); names+=("$n")
done <<< "$top"

max="${bytes[0]}"

# 生成 6 行条形
rows=""
for i in "${!names[@]}"; do
  name="${names[$i]}"
  col="$(color_for "$name")"
  fill=$(( bytes[i] * TRACK / max ))
  [ "$fill" -lt 36 ] && fill=36
  ry=$(( 105 + i * 33 ))
  ly=$(( 117 + i * 33 ))
  rows+="    <text x=\"26\" y=\"${ly}\" fill=\"#abb2bf\">${name}</text>
    <rect x=\"170\" y=\"${ry}\" width=\"${TRACK}\" height=\"14\" rx=\"7\" fill=\"#21262d\"/>
    <rect x=\"170\" y=\"${ry}\" width=\"${fill}\" height=\"14\" rx=\"7\" fill=\"${col}\"/>
"
done

mkdir -p assets
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
  <text x="430" y="26" fill="#8b949e" font-size="13" text-anchor="middle">programApe@github: ~/dev — langstat</text>

  <!-- heading -->
  <text x="26" y="78" font-size="15"><tspan fill="#27c93f">\$</tspan><tspan fill="#c9d1d9" dx="9">langstat --top</tspan><tspan fill="#6e7681" dx="14" font-size="13"># 主要技术栈 · 按代码量</tspan></text>

  <!-- bars -->
  <g font-size="14.5">
${rows}  </g>

  <!-- cursor -->
  <text x="26" y="312" font-size="15"><tspan fill="#27c93f">\$</tspan></text>
  <rect x="44" y="301" width="9" height="15" fill="#27c93f">
    <animate attributeName="opacity" values="1;1;0;0" dur="1.1s" repeatCount="indefinite"/>
  </rect>
</svg>
SVG

echo "wrote ${OUT}: ${names[*]} (max=${max} bytes)"
