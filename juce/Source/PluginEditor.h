#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include "PluginProcessor.h"
#include "ScopeComponent.h"

class NanikaTukuruAudioProcessorEditor final : public juce::AudioProcessorEditor
{
public:
    explicit NanikaTukuruAudioProcessorEditor (NanikaTukuruAudioProcessor&);
    ~NanikaTukuruAudioProcessorEditor() override = default;

    void paint (juce::Graphics&) override;
    void resized() override;

private:
    using SliderAttachment = juce::AudioProcessorValueTreeState::SliderAttachment;
    using ComboAttachment = juce::AudioProcessorValueTreeState::ComboBoxAttachment;
    using ButtonAttachment = juce::AudioProcessorValueTreeState::ButtonAttachment;

    NanikaTukuruAudioProcessor& processorRef;
    ScopeComponent scope;

    juce::Label brandLabel;
    juce::Label headlineLabel;

    juce::ToggleButton playingButton { "Playing" };
    juce::ComboBox waveBox;
    juce::ComboBox filterBox;

    juce::Slider freqSlider, oscGainSlider, noiseGainSlider;
    juce::Slider cutoffSlider, qSlider;
    juce::Slider delayTimeSlider, delayFbSlider, delayWetSlider, masterSlider;

    juce::Label freqLabel, oscGainLabel, noiseGainLabel;
    juce::Label cutoffLabel, qLabel;
    juce::Label delayTimeLabel, delayFbLabel, delayWetLabel, masterLabel;
    juce::Label waveLabel, filterLabel;

    std::unique_ptr<ButtonAttachment> playingAttachment;
    std::unique_ptr<ComboAttachment> waveAttachment;
    std::unique_ptr<ComboAttachment> filterAttachment;
    std::unique_ptr<SliderAttachment> freqAttachment;
    std::unique_ptr<SliderAttachment> oscGainAttachment;
    std::unique_ptr<SliderAttachment> noiseGainAttachment;
    std::unique_ptr<SliderAttachment> cutoffAttachment;
    std::unique_ptr<SliderAttachment> qAttachment;
    std::unique_ptr<SliderAttachment> delayTimeAttachment;
    std::unique_ptr<SliderAttachment> delayFbAttachment;
    std::unique_ptr<SliderAttachment> delayWetAttachment;
    std::unique_ptr<SliderAttachment> masterAttachment;

    void setupSlider (juce::Slider& slider, juce::Label& label, const juce::String& text);
    void setupLabel (juce::Label& label, const juce::String& text, float size, juce::Colour colour);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (NanikaTukuruAudioProcessorEditor)
};
