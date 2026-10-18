# ============================================================
# rimochan-nyamuru-manga-forge / lib_style.sh
#   画風ファイル（styles/*.yaml）を扱う関数。forge.sh と styles.sh から source する
#   Copyright (c) 2026 sa-san10 / MIT License
# ============================================================
#
# 画風ファイルを探す場所（先に見つかったほうを使う）:
#   1. $MANGA_FORGE_STYLES（自分だけの画風フォルダ。任意）
#   2. <リポジトリ>/styles
# ============================================================

STYLE_DIRS=()
[[ -n "${MANGA_FORGE_STYLES:-}" && -d "${MANGA_FORGE_STYLES}" ]] && STYLE_DIRS+=("$MANGA_FORGE_STYLES")
STYLE_DIRS+=("$HERE/styles")

# style_get <ファイル> <キー> … 1行の値（key: "value"）を取り出す
style_get() {
  sed -n "s/^$2:[[:space:]]*\"\(.*\)\"[[:space:]]*\$/\1/p" "$1" | head -1 | tr -d '\r'
}

# style_files … 一覧に出す画風ファイル（_ で始まるものは除く）
style_files() {
  local d f
  for d in "${STYLE_DIRS[@]}"; do
    for f in "$d"/*.yaml; do
      [[ -f "$f" ]] || continue
      [[ "$(basename "$f")" == _* ]] && continue
      echo "$f"
    done
  done
}

# style_find <ファイル名・名前・パス> … 画風ファイルのパスを返す
style_find() {
  local q="$1" d f
  [[ -f "$q" ]] && { echo "$q"; return 0; }
  for d in "${STYLE_DIRS[@]}"; do
    [[ -f "$d/$q.yaml" ]] && { echo "$d/$q.yaml"; return 0; }
  done
  while IFS= read -r f; do
    [[ "$(style_get "$f" name)" == "$q" ]] && { echo "$f"; return 0; }
  done < <(style_files)
  return 1
}

# style_check <ファイル> … 書式の誤りを標準出力に1行ずつ出す（無ければ何も出さない）
style_check() {
  local f="$1" line
  [[ -n "$(style_get "$f" name)" ]] || echo "name が無い（name: \"…\" の1行で書く）"
  line="$(style_get "$f" line)"
  if [[ -z "$line" ]]; then
    echo "line が無い（line: \"画風: …\" の1行で書く）"
  else
    [[ "$line" == 画風:* ]] || echo "line が「画風: 」で始まっていない"
    [[ "$line" == *'"'* ]] && echo "line の中にダブルクォートがある（「」を使う）"
  fi
  [[ "$(style_get "$f" memo)" == *'"'* ]] && echo "memo の中にダブルクォートがある（「」を使う）"
  return 0
}

# style_apply <OMNYファイル> <画風の行> … 画風の行を meta.style_notes の先頭に入れた OMNY を標準出力に出す
#   すでに「画風:」で始まる行があれば、それと差し替える（同じネームを別の画風で刷り直すため）
#   style_notes が見つからなければ 1 を返す
style_apply() {
  awk -v L="$2" '
    function ind(s) { match(s, /^ */); return RLENGTH }
    function item(n,   s, i) { s = ""; for (i = 0; i < n; i++) s = s " "; return s "- \"" L "\"" }
    BEGIN { state = 0; done = 0 }
    # state 0: style_notes を探す / 1: 直後の行を待つ / 2: style_notes の中
    state == 0 && !done && /^ *style_notes:[ \t]*(\[\][ \t]*)?(#.*)?\r?$/ {
      base = ind($0)
      if ($0 ~ /\[\]/) {
        sub(/:[ \t]*\[\][ \t]*/, ":")
        print
        print item(base + 2)
        done = 1; next
      }
      print; state = 1; done = 1; next
    }
    state == 1 {
      if ($0 ~ /^[ \t]*\r?$/ || $0 ~ /^ *#/) { held = held $0 "\n"; next }
      n = ($0 ~ /^ *- / && ind($0) > base) ? ind($0) : base + 2
      print item(n)
      printf "%s", held; held = ""
      state = 2
    }
    state == 2 {
      if ($0 !~ /^[ \t]*\r?$/ && $0 !~ /^ *#/ && ind($0) <= base) { state = 0 }
      else if ($0 ~ /^ *- *"?画風[:：]/) { next }
    }
    { print }
    END {
      if (state == 1) { print item(base + 2); printf "%s", held }
      if (!done) exit 1
    }
  ' "$1"
}
