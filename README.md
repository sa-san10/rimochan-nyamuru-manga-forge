# rimochan-nyamuru-manga-forge 🐹🐱🔨

**自然言語で頼むと、漫画の原稿が出てくる**——Claude Code 用のスキルです。

ネームの設計から作画・回収・検品までを一本のパイプラインにまとめました。
「5ページで、こういう話の漫画を描いて」と書けば、`page1.png ... page5.png` が出てきます。

```
あなたの一言
   ↓  Claude Code がネームを設計
OMNY（漫画ネームYAML・絶対座標でコマ割り）
   ↓  OMAY（作画・レイアウト規則）と一緒に画像生成AIへ
完成原稿 page1.png, page2.png, ...
```

たとえば同梱のサンプルネーム [`examples/sample-2page.omny.yaml`](examples/sample-2page.omny.yaml) を焼くと、この2枚が出てきます：

<p align="center">
  <img src="examples/output-sample/page1.png" alt="サンプル出力 1ページ目：なんでもない日のコンビニ帰り" width="49%">
  <img src="examples/output-sample/page2.png" alt="サンプル出力 2ページ目：雨上がりの空に虹" width="49%">
</p>

リファレンス画像は使っていません。ネームの YAML（コマ割り座標・フキダシの形・背景詳細度・`materials.note` の文章）だけからこの原稿になります。
1ページ目ラストの「ヒキ」を2ページ目冒頭の大ゴマで受けるメクリ構成も、ネームで指定したとおりです。

---

## これは何で、何ではないか

- ✅ **ネームを構造化データで書き、それを原稿に焼く**ためのパイプラインです
- ✅ ページ数・コマ割り・フキダシの形・背景の描き込み量まで**データとして指定**できます
- ✅ 1つの会話でページを焼き続けるので、**キャラデザと画風がページ間で一貫**します
- ❌ 画像生成モデルそのものではありません（作画は codex / ChatGPT image に投げます）
- ❌ ワンクリックで傑作が出る魔法ではありません。**ネームの良さがそのまま出ます**

ネームを人間が編集したい場合は、姉妹プロジェクトの
[**Nyamuru Manga Name Studio**](https://github.com/sa-san10/nyamuru-manga-name-studio)（ブラウザで動くネーム編集PWA）を使えます。
同じ OMNY 形式なので、Studio で整えたネームをそのままこの forge に流せます。

---

## 必要なもの

| 要件 | 備考 |
|---|---|
| [Claude Code](https://claude.com/claude-code) | スキルとして読み込みます |
| `codex` CLI | 作画を担当。画像生成が使えるプランでログイン済みであること |
| bash | Windows は Git Bash でOK（実際にそこで開発しています） |
| リファレンス画像（任意） | キャラの立ち絵。無くてもAIが想像で描きます |

セットアップは [`docs/setup.md`](docs/setup.md) を見てください。

---

## 5分で試す

```bash
git clone https://github.com/sa-san10/rimochan-nyamuru-manga-forge
cd rimochan-nyamuru-manga-forge

# 同梱のサンプルネーム（2ページ）を焼いてみる
./scripts/forge.sh -n examples/sample-2page.omny.yaml
```

`out/sample-2page/page1.png` と `page2.png` ができます。
出来上がりの例は**冒頭に貼った2枚**（[`examples/output-sample/`](examples/output-sample/)）がそのまま実物です。
10ページの作品なら10〜20分ほどかかります（1枚ずつ順番に描くので）。

自分のキャラで描きたいときは立ち絵を渡します（最大3枚推奨）:

```bash
./scripts/forge.sh -n my.omny.yaml \
  -r chars/hero.png -r chars/rival.png \
  -m "画風はクレヨン画。主人公は必ず赤いマフラーを付けている"
```

できた原稿は好きな場所へ納品できます（ネームも一緒に残すと資産になります）:

```bash
./scripts/deliver.sh -f out/my -t ~/Desktop/my -n my.omny.yaml
```

---

## Claude Code のスキルとして使う

こちらが本来の使い方です。**ネームを書くところから任せられます。**

```bash
# ユーザー全体で使う場合
cp -r . ~/.claude/skills/manga-forge

# または特定のプロジェクトだけで使う場合
cp -r . <your-project>/.claude/skills/manga-forge
```

あとは Claude Code に自然言語で頼みます:

> 5ページの漫画を描いて。テーマは「引っ越しの日に、古い机の引き出しから昔の手紙が出てくる話」。
> 最後は静かに終わらせて。キャラは `chars/` の立ち絵を使って。

Claude Code が
①ストーリーを書き ②OMNY にコマ割りを設計し ③`forge.sh` で焼き ④全ページを見て検品し
⑤希望の場所へ納品する——ところまでやります。

---

## リポジトリの中身

```
SKILL.md                    Claude Code スキル本体（これが読まれます）
omay/standard.omay.yaml     作画・演出ルールとレイアウト仕様（OMAY）
omay/styles.md              画風パレット（12種の呪文）
prompts/ndm-v10.md          ネーム生成プロンプト（OMNYの書き方の全仕様）
scripts/forge.sh            OMNY → 原稿PNG を焼くドライバ
scripts/collect.sh          生成画像をページ順に回収
scripts/deliver.sh          検品済みの原稿を希望の場所へ納品
examples/                   サンプルネーム
docs/setup.md               codex CLI の準備
docs/characters.md          自分のキャラ・背景を登録する
docs/pitfalls.md            ⚠️ ハマりどころ全集（先に読むと数日助かります）
```

### 📌 `docs/pitfalls.md` を先に読んでください

AIに漫画を描かせると、たいてい同じ場所で転びます。
「宣言だけして画像を作らずに終わる」「続きを頼んだら別作品の会話を掴む」
「bbox どおりの位置に絵が来ない」——**全部踏んだので書いてあります**。

---

## OMNY / OMAY について

- **OMNY**（Open Manga Name YAML）— 漫画のネームを表すデータ形式。ページ・コマの絶対座標・フキダシの形と位置・人物の配置・背景の詳細度を持ちます
- **OMAY**（Open Manga Artwork YAML）— それを「どう描くか」の規則。作画AIに渡す共通ルールです

ネームが構造化データになっていると、原稿を焼くだけでなく
**コマに挙動をつける／別の画風で刷り直す／編集ツールで開く**といった後工程が全部つながります。

このリポジトリ内では [`prompts/ndm-v10.md`](prompts/ndm-v10.md) と
[`omay/standard.omay.yaml`](omay/standard.omay.yaml) が正です。
仕様の大本（上流）は [Nyamuru Manga Name Studio](https://github.com/sa-san10/nyamuru-manga-name-studio) にあります（詳しくは下の「大本リポジトリとの関係」）。

---

## 名前について

`rimochan` は、このパイプラインを毎日使って漫画を描き続けている
Claude Code エージェント **リモちゃん** の名前です。
`nyamuru`（にゃむる）はデータモデルの名前で、マスコットは猫の妖精 **にゃむるたん**。

ここに書かれているハマりどころは、全部リモちゃんが実際に転んだ記録です。

---

## ライセンス

- コード・ドキュメント・OMAY / OMNY 仕様: **MIT License**（[LICENSE](LICENSE)）
- キャラクター「にゃむるたん」: **CC BY 4.0** — 作者 sa-san10

作画に使う画像生成サービスの利用規約は、各自でご確認ください。

---

## 大本リポジトリとの関係（Nyamuru Manga Name Studio）

このスキルの OMNY / OMAY / ワークフローの**大本（上流）**は
[**Nyamuru Manga Name Studio**](https://github.com/sa-san10/nyamuru-manga-name-studio)（ブラウザで OMNY を編集する PWA）です。
仕様書とプロンプトは Studio の `src/content/` で管理されており、このリポジトリはそのスナップショットを
「Claude Code スキル＋bash パイプライン」として実装し直したものです。

### ファイルの対応表

| このリポジトリ | Studio 側（`src/content/`） | 中身 |
|---|---|---|
| `omay/standard.omay.yaml` | `standard.omay.yaml` | OMAY（作画・演出ルールとレイアウト仕様） |
| `prompts/ndm-v10.md` | `nyamuru-manga-generation-prompt-v10.md`（仕様本体は `nyamuru-data-model-v10.md`） | ネーム生成プロンプト＝OMNYの書き方 |
| `SKILL.md` ＋ `scripts/` | `agent-manga-generation-workflow.md` | エージェント用の生成ワークフロー |
| `examples/sample-2page.omny.yaml` | `sample.omny.yaml` | サンプルネーム（それぞれ独自の内容） |

### この forge 側で足したもの

Studio のワークフローを実運用（毎日焼く）に耐えるようにした部分が、このリポジトリの独自分です：

- **成果物強制ブロック**（宣言だけで終わる問題への対策。`docs/pitfalls.md` 罠1）
- **page1=新規セッション／page2以降=page1 の session id を名指しした resume** によるページ間一貫性の担保（罠3・4。`--last` を使わないので他の codex 呼び出しと並走しても混ざらない）
- `--skip-git-repo-check` で git の外のフォルダからでも動く（罠11）
- **ログのUUIDからの画像回収**（`collect.sh`。罠7）
- ハマりどころ全集（`docs/pitfalls.md`）と画風パレット（`omay/styles.md`）

なお検品の考え方が少し違います：Studio のワークフローはフキダシ内テキストの校正を人間の後工程に委ねますが、
このスキルでは**エージェントが全ページを目で見て検品**し、気になるページだけ再生成する運用です。

### 最新の仕様・ワークフローの取り込み方

Studio 側で仕様が更新されたら、次の手順でこちらへ取り込みます：

1. Studio の `src/content/` の差分を見る（OMAY の `spec_version` / OMNY の `schema_version` が上がっていたら要注意）
2. `standard.omay.yaml` を `omay/standard.omay.yaml` へ上書きコピー
3. 生成プロンプトの差分を `prompts/ndm-v10.md` へ反映する（§D の出力方法など **forge 固有の追記を消さないよう、丸ごと上書きではなく差分マージ**で）
4. `spec_version` と `schema_version` の一致を確認する（bg やマージン等の数値はプロンプトと OMAY の両方に意図的に二重掲載されているので、**必ず両方揃えて**直す）
5. サンプルを焼き直して検品する: `./scripts/forge.sh -n examples/sample-2page.omny.yaml`

両リポジトリとも同じ作者（sa-san10）の MIT ライセンスなので、仕様ファイルの相互コピーに特別な手続きは要りません
（キャラクター「にゃむるたん」のみ CC BY 4.0）。

Studio で人の手で詰めたネームは、同じ OMNY 形式なのでそのままこの forge に流せます。
