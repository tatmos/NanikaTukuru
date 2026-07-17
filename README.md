# NanikaTukuru 音響ラボ

ブラウザだけで動くミニ音響ラボです。  
[note 記事「元エンジニアがAIでバイブコーディングしてみた話」](https://note.com/tatmos/n/n92960b7b18da) のサンプル用リポジトリです。

**公開 URL（Pages 有効化後）:** https://tatmos.github.io/NanikaTukuru/

## できること

- オシレータ（sine / triangle / sawtooth / square）
- ホワイトノイズのミックス
- フィルタ（lowpass / highpass / bandpass）
- ディレイ（時間・フィードバック・ウェット）
- 波形・スペクトルのリアルタイム表示

フレームワークやビルドは使いません。GitHub Pages 向けの静的 HTML / CSS / JS です。

## フォルダ構成

```
NanikaTukuru/
├── index.html          # 公開サイト入口
├── css/styles.css
├── js/
│   ├── main.js
│   ├── audio-lab.js
│   └── visualizer.js
├── docs/
│   ├── 企画書.md       # 企画・スコープ
│   └── agent-log.md    # Agent とのやり取り記録
└── README.md
```

記事で触れている「企画・コード・ドキュメントを一箇所にまとめる」形の最小例です。

## ローカルで見る

ES modules を使っているため、`index.html` を直接ダブルクリック（`file://`）ではなく、ローカルサーバー経由で開いてください。

```bash
# Python がある場合
python -m http.server 8080
```

ブラウザで http://localhost:8080 を開きます。

## GitHub Pages で公開する

1. このリポジトリを GitHub に push する
2. GitHub → **Settings** → **Pages**
3. **Source**: Deploy from a branch
4. **Branch**: `main` / フォルダ `/ (root)` を選んで Save
5. 数分待つと https://tatmos.github.io/NanikaTukuru/ で見られる

## ドキュメント

- [企画書](docs/企画書.md)
- [Agent やり取り記録](docs/agent-log.md)
