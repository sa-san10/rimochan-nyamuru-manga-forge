#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / styles.sh
#   画風ファイル（styles/*.yaml）の一覧・中身の表示・書式の確認
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 使い方:
#   ./scripts/styles.sh                一覧（forge.sh -s に渡す名前・表示名・試し焼き）
#   ./scripts/styles.sh show <画風>    1つの画風の中身を表示
#   ./scripts/styles.sh check          全部の画風ファイルの書き方を確かめる
#
# 自分だけの画風フォルダを使うときは、環境変数 MANGA_FORGE_STYLES にそのフォルダを入れる。
# 同じ名前の画風があれば、そちらが先に使われる。
# ============================================================
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HERE/scripts/lib_style.sh"

case "${1:-list}" in
  list)
    while IFS= read -r f; do
      t="$(style_get "$f" tested)"
      printf '%-16s %s%s\n' "$(basename "$f" .yaml)" "$(style_get "$f" name)" "${t:+（$t）}"
    done < <(style_files)
    ;;
  show)
    [[ -n "${2:-}" ]] || { echo "使い方: styles.sh show <画風>" >&2; exit 1; }
    f="$(style_find "$2")" || { echo "画風が見つからないのだ: $2" >&2; exit 1; }
    echo "# $f"; cat "$f"
    ;;
  check)
    ng=0
    while IFS= read -r f; do
      r="$(style_check "$f")"
      [[ -z "$r" ]] && continue
      ng=1; echo "NG: $f"; echo "$r" | sed 's/^/    /'
    done < <(style_files)
    [[ $ng -eq 0 ]] && echo "OK: $(style_files | wc -l | tr -d ' ') 件"
    exit $ng
    ;;
  -h|--help)
    awk 'NR > 1 && !/^#/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"
    ;;
  *) echo "unknown command: $1（-h でヘルプ）" >&2; exit 1;;
esac
