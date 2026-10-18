#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / deliver.sh
#   検品済みの原稿PNGを、ユーザー希望の場所へ納品する
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 使い方:
#   ./scripts/deliver.sh -f <回収済みdir> -t <納品先dir> [オプション]
#
# 必須:
#   -f, --from <dir>       回収済みディレクトリ（out/<作品名>）
#   -t, --to <dir>         納品先ディレクトリ（無ければ作る）
#
# オプション:
#   -n, --omny <path>      ネーム（OMNY）も一緒に納品して資産として残す。
#                          forge.sh が出力先に残す <OMNY名>.used.omny.yaml（実際に渡したネーム）を渡す
#   --force                納品先に同名の page*.png があっても上書きする
#   -h, --help             このヘルプ
#
# 例:
#   ./scripts/deliver.sh -f out/my -t ~/Desktop/my -n out/my/my.used.omny.yaml
#
# ⚠️ 納品は検品（SKILL.md ⑤）が終わってから。
#    納品先に前回の納品物があると止まる（黙って上書きしない）。
# ============================================================
set -uo pipefail

FROM=""; TO=""; OMNY=""; FORCE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--from) FROM="$2"; shift 2;;
    -t|--to)   TO="$2"; shift 2;;
    -n|--omny) OMNY="$2"; shift 2;;
    --force)   FORCE=1; shift;;
    -h|--help) awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

[[ -z "$FROM" || -z "$TO" ]] && { echo "ERROR: -f <回収済みdir> と -t <納品先dir> は必須なのだ" >&2; exit 1; }
[[ -d "$FROM" ]] || { echo "ERROR: 回収済みディレクトリが見つからない: $FROM" >&2; exit 1; }

shopt -s nullglob
PAGES=("$FROM"/page*.png)
shopt -u nullglob
[[ ${#PAGES[@]} -eq 0 ]] && { echo "ERROR: $FROM に page*.png が無いのだ。先に forge.sh で焼いてほしいのだ" >&2; exit 1; }

mkdir -p "$TO"

# 上書きガード（前回の納品物を黙って消さない）
if [[ "$FORCE" != "1" ]]; then
  for f in "${PAGES[@]}"; do
    b="$(basename "$f")"
    if [[ -e "$TO/$b" ]]; then
      echo "⚠️ 納品先に $b が既にあるのだ: $TO" >&2
      echo "   上書きしてよければ --force を付けて再実行してほしいのだ" >&2
      exit 3
    fi
  done
fi

for f in "${PAGES[@]}"; do
  cp "$f" "$TO/"
done

if [[ -n "$OMNY" ]]; then
  if [[ -f "$OMNY" ]]; then
    cp "$OMNY" "$TO/"
  else
    echo "WARN: OMNYが見つからないので飛ばすのだ: $OMNY" >&2
  fi
fi

echo "✅ 納品したのだ: ${#PAGES[@]} 枚 → $TO"
ls -la "$TO"/page*.png | awk '{print "   " $9, $5"B"}'
[[ -n "$OMNY" && -f "$TO/$(basename "$OMNY")" ]] && echo "   $TO/$(basename "$OMNY") (ネーム)"
exit 0
