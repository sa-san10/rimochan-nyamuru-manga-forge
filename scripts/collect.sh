#!/usr/bin/env bash
# ============================================================
# rimochan-nyamuru-manga-forge / collect.sh
#   codex が生成した画像を page1.png, page2.png ... として回収する
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 使い方:
#   ./scripts/collect.sh --log <forge.log> --out <出力先dir> [--pages N] [--session <UUID>]
#
# なぜ専用スクリプトが必要か:
#   codex は生成画像を ~/.codex/generated_images/<UUID>/ に置く。
#   「最新フォルダを取る」方式は複数の codex を並走させると混ざるので、
#   **必ずログに出てきた自分のUUIDのフォルダから取る**のが鉄則なのだ。
#   UUID は codex の session id と同じなので、forge.sh は --session でも渡す。
#   （docs/pitfalls.md 参照）
# ============================================================
set -uo pipefail

LOG=""; OUT=""; PAGES=""; SESSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --log)   LOG="$2"; shift 2;;
    --out)   OUT="$2"; shift 2;;
    --pages) PAGES="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown option: $1" >&2; exit 1;;
  esac
done

[[ -f "$LOG" ]] || { echo "ERROR: ログが見つからない: $LOG" >&2; exit 1; }
[[ -n "$OUT" ]] || { echo "ERROR: --out が必要なのだ" >&2; exit 1; }
mkdir -p "$OUT"

GEN_ROOT="${CODEX_IMAGE_DIR:-$HOME/.codex/generated_images}"

# ログから「generated_images/<UUID>」を拾う（自分のセッションのものだけ）
UUIDS=$(grep -oiE 'generated_images[/\\][0-9a-f-]{36}' "$LOG" \
        | grep -oiE '[0-9a-f-]{36}' | sort -u)
# session id のフォルダも候補に足す（ログにパスが出なかった回の取りこぼし対策）
[[ -n "$SESSION" ]] && UUIDS=$(printf '%s\n%s\n' "$UUIDS" "$SESSION" | grep -v '^$' | sort -u)

if [[ -z "$UUIDS" ]]; then
  echo "⚠️ ログに生成画像のパスが出ていないのだ。" >&2
  echo "   → 宣言だけで終わった可能性が高いのだ（docs/pitfalls.md の【罠1】を見てほしいのだ）" >&2
  exit 2
fi

# 生成順（mtime古い順）＝ページ順に並べて回収
FILES=()
while IFS= read -r u; do
  d="$GEN_ROOT/$u"
  [[ -d "$d" ]] || continue
  while IFS= read -r f; do FILES+=("$f"); done < <(ls -tr "$d"/*.png 2>/dev/null)
done <<< "$UUIDS"

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "⚠️ UUIDフォルダにPNGが無いのだ: $UUIDS" >&2
  exit 2
fi

i=1
for f in "${FILES[@]}"; do
  cp "$f" "$OUT/page$i.png"
  i=$((i+1))
done
GOT=$((i-1))

echo "✅ 回収したのだ: $GOT 枚 → $OUT"
ls -la "$OUT"/page*.png | awk '{print "   " $9, $5"B"}'

if [[ -n "$PAGES" && "$GOT" != "$PAGES" ]]; then
  cat >&2 <<EOS

⚠️ ページ数($PAGES)と画像枚数($GOT)が一致しないのだ。
   ・多い場合 → 作画AIが自主的にリテイクした可能性（1ページを2回描いた等）
   ・少ない場合 → どこかのページで生成に失敗した可能性
   👉 各PNGを開いて右上のページ番号（例「3/10」）を見て並べ直してほしいのだ。
      枚数＝ページ数の前提は当てにならないのだ（docs/pitfalls.md 【罠5】）
EOS
fi
