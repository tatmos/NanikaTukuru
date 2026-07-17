#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_dsp/juce_dsp.h>
#include <array>
#include <atomic>

class NanikaTukuruAudioProcessor final : public juce::AudioProcessor
{
public:
    static constexpr int scopeSize = 2048;

    NanikaTukuruAudioProcessor();
    ~NanikaTukuruAudioProcessor() override = default;

    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override {}
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override { return true; }

    const juce::String getName() const override { return JucePlugin_Name; }
    bool acceptsMidi() const override { return false; }
    bool producesMidi() const override { return false; }
    bool isMidiEffect() const override { return false; }
    double getTailLengthSeconds() const override { return 2.0; }

    int getNumPrograms() override { return 1; }
    int getCurrentProgram() override { return 0; }
    void setCurrentProgram (int) override {}
    const juce::String getProgramName (int) override { return {}; }
    void changeProgramName (int, const juce::String&) override {}

    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;

    juce::AudioProcessorValueTreeState& getAPVTS() noexcept { return apvts; }
    void copyScopeSamples (std::array<float, scopeSize>& dest) const;

    static juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

private:
    enum class Wave { sine, triangle, sawtooth, square };
    enum class FilterMode { lowpass, highpass, bandpass };

    float renderOscSample();
    void updateFilter();
    void pushScopeSample (float sample);

    juce::AudioProcessorValueTreeState apvts;

    std::atomic<float>* playingParam = nullptr;
    std::atomic<float>* waveParam = nullptr;
    std::atomic<float>* freqParam = nullptr;
    std::atomic<float>* oscGainParam = nullptr;
    std::atomic<float>* noiseGainParam = nullptr;
    std::atomic<float>* filterTypeParam = nullptr;
    std::atomic<float>* cutoffParam = nullptr;
    std::atomic<float>* qParam = nullptr;
    std::atomic<float>* delayTimeParam = nullptr;
    std::atomic<float>* delayFbParam = nullptr;
    std::atomic<float>* delayWetParam = nullptr;
    std::atomic<float>* masterParam = nullptr;

    double currentSampleRate = 44100.0;
    float phase = 0.0f;

    juce::dsp::StateVariableTPTFilter<float> filter;
    int lastFilterType = -1;
    float lastCutoff = -1.0f;
    float lastQ = -1.0f;

    juce::dsp::DelayLine<float, juce::dsp::DelayLineInterpolationTypes::Linear> delayLine { 192000 };
    juce::Random random;

    std::array<float, scopeSize> scopeBuffer {};
    std::atomic<int> scopeWrite { 0 };

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NanikaTukuruAudioProcessor)
};
