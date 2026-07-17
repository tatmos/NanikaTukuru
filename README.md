# NanikaTukuru 音響ラボ

ブラウザと Godot（Windows）の両方で動くミニ音響ラボです。  
[note 記事「元エンジニアがAIでバイブコーディングしてみた話」](https://note.com/tatmos/n/n92960b7b18da) のサンプル用リポジトリです。

**Web 公開 URL（Pages 有効化後）:** https://tatmos.github.io/NanikaTukuru/

## できること（Web / Godot 共通）

- オシレータ（sine / triangle / sawtooth / square）
- ホワイトノイズのミックス
- フィルタ（lowpass / highpass / bandpass）
- ディレイ（時間・フィードバック・ウェット）
- 波形・スペクトルのリアルタイム表示

## フォルダ構成

```
NanikaTukuru/
├── index.html          # Web 公開サイト入口（GitHub Pages）
├── css/ / js/          # Web Audio + Canvas 実装
├── godot/              # Godot 4 移植（Windows 向け）
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   └── README.md
├── docs/
│   ├── 企画書.md
│   └── agent-log.md
└── README.md
```

## Web 版（GitHub Pages）

フレームワークやビルドなしの静的 HTML / CSS / JS です。

```bash
python -m http.server 8080
```

http://localhost:8080 を開きます（ES modules のため `file://` 不可）。

Pages: Settings → Pages → `main` / `/ (root)` → https://tatmos.github.io/NanikaTukuru/

## Godot 版（Windows）

1. Godot 4.2+ で `godot/project.godot` を Import
2. F5 で実行
3. Windows 向けエクスポート手順は [godot/README.md](godot/README.md)

技術対応表も同ファイルにあります。

## ドキュメント

- [企画書](docs/企画書.md)
- [Agent やり取り記録](docs/agent-log.md)
