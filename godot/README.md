# NanikaTukuru 音響ラボ — Godot 版

Web（GitHub Pages）版と同じミニ音響ラボの **Godot 4** 移植です。Windows デスクトップでの実行・エクスポートを想定しています。

## 必要環境

- Godot **4.2 以降**（4.3 / 4.4 でも可）
- Windows（日本語 UI は Yu Gothic UI / Meiryo などシステムフォントを使用）

## 開き方

1. Godot を起動
2. **Import** → このフォルダの `project.godot` を選択
3. F5（または Play）で実行

## 構成

| パス | 内容 |
|------|------|
| `project.godot` | プロジェクト設定 |
| `scenes/main.tscn` | メインシーン |
| `scripts/audio_lab.gd` | オシレータ／ノイズ生成 + Lab バス（Filter / Delay / Spectrum） |
| `scripts/visualizer.gd` | 波形・スペクトル描画 |
| `scripts/main.gd` | UI（Web 版パネル相当） |

## Web 版との対応

| Web | Godot |
|-----|--------|
| `OscillatorNode` + ノイズバッファ | `AudioStreamGenerator` |
| `BiquadFilterNode` | `AudioEffectLow/High/BandPassFilter` |
| `DelayNode` | `AudioEffectDelay` |
| `AnalyserNode` | `AudioEffectSpectrumAnalyzer` + 生成時リングバッファ |
| HTML / CSS / Canvas | Control UI + `_draw()` |

## Windows 向けエクスポート

1. Godot メニュー **Editor → Manage Export Templates** でテンプレートを入れる
2. **Project → Export…** → Windows Desktop
3. 出力先例: `../export/NanikaTukuruAudioLab.exe`

`export_presets.cfg` を同梱しています（パスは環境に合わせて変更可）。

## 補足

- オーディオバス `Lab` は実行時にスクリプトで作成します（`default_bus_layout.tres` 不要）
- Web 版はリポジトリルートのまま残してあり、こちらは `godot/` 配下で併存します
