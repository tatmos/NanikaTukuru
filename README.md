# NanikaTukuru 音響ラボ

ブラウザ・Godot・JUCE（VST3）で動くミニ音響ラボです。  
[note 記事「元エンジニアがAIでバイブコーディングしてみた話」](https://note.com/tatmos/n/n92960b7b18da) のサンプル用リポジトリです。

**Web 公開 URL（Pages 有効化後）:** https://tatmos.github.io/NanikaTukuru/

## できること（各版共通）

- オシレータ（sine / triangle / sawtooth / square）
- ホワイトノイズのミックス
- フィルタ（lowpass / highpass / bandpass）
- ディレイ（時間・フィードバック・ウェット）
- 波形（＋ Web/Godot はスペクトル）表示

## フォルダ構成

```
NanikaTukuru/
├── index.html / css/ / js/   # Web（GitHub Pages）
├── godot/                    # Godot 4（Windows）
├── juce/                     # JUCE 8（VST3 + Standalone）
├── docs/
│   ├── 企画書.md
│   └── agent-log.md
└── README.md
```

## Web 版

```bash
python -m http.server 8080
```

http://localhost:8080 （ES modules のため `file://` 不可）

Pages: Settings → Pages → `main` / `/ (root)`

## Godot 版

[godot/README.md](godot/README.md) — `godot/project.godot` を Import して F5

## JUCE / VST3 版

[juce/README.md](juce/README.md) — CMake で VST3 と Standalone をビルド

```powershell
cd juce
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

## ドキュメント

- [企画書](docs/企画書.md)
- [Agent やり取り記録](docs/agent-log.md)
