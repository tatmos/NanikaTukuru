# NanikaTukuru 音響ラボ — JUCE / VST3 版

Web / Godot 版と同じミニ音響ラボの **JUCE 8** 移植です。  
**VST3** と **Standalone** をビルドできます。

## できること

- Playing オン／オフ（生成ゲート）
- オシレータ（sine / triangle / sawtooth / square）+ 周波数・量
- ノイズ量
- フィルタ（lowpass / highpass / bandpass）+ カットオフ / Q
- ディレイ（時間・フィードバック・ウェット）
- マスター音量
- 波形スコープ（Editor）

## 必要環境（Windows）

- Visual Studio 2022（C++ デスクトップ開発）
- CMake 3.22+（VS 付属可）
- Git（CMake が JUCE を FetchContent で取得）
- 初回ビルド時にネットワーク接続（JUCE 取得用）

VST3 SDK は JUCE がビルド時に扱います（通常は追加作業不要）。

## ビルド手順

Developer PowerShell for VS 2022、または「x64 Native Tools」相当の環境で:

```powershell
cd juce
cmake -B build -G "Visual Studio 17 2022" -A x64
cmake --build build --config Release
```

成果物の目安:

| 形式 | 場所の例 |
|------|----------|
| Standalone | `build/NanikaTukuruAudioLab_artefacts/Release/Standalone/NanikaTukuru Audio Lab.exe` |
| VST3 | `build/NanikaTukuruAudioLab_artefacts/Release/VST3/NanikaTukuru Audio Lab.vst3` |

`COPY_PLUGIN_AFTER_BUILD` が有効なため、ビルド後に共通の VST3 フォルダへコピーされることがあります（ユーザープラグインディレクトリ）。

## DAW での使い方

1. インストゥルメント／シンセとしてロード
2. **Playing** がオンだと音が出る（デフォルトオン）
3. パラメータはオートメーション可能（APVTS）

## Web / Godot との対応

| Web / Godot | JUCE |
|-------------|------|
| Osc + Noise | `processBlock` 内でサンプル生成 |
| Biquad / AudioEffectFilter | `juce::dsp::StateVariableTPTFilter` |
| DelayNode / AudioEffectDelay | `juce::dsp::DelayLine` |
| Canvas / `_draw` | `ScopeComponent` |
| スライダー UI | `AudioProcessorEditor` + APVTS |

## ライセンス注意

- JUCE 自体のライセンス（個人／教育／商用）を確認してください
- VST は Steinberg の商標です。配布時は表記に従ってください

## フォルダ

```
juce/
├── CMakeLists.txt
├── README.md
└── Source/
    ├── PluginProcessor.h/.cpp
    ├── PluginEditor.h/.cpp
    └── ScopeComponent.h/.cpp
```
