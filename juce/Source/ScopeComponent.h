#pragma once

#include <juce_gui_basics/juce_gui_basics.h>
#include "PluginProcessor.h"

class ScopeComponent final : public juce::Component, private juce::Timer
{
public:
    explicit ScopeComponent (NanikaTukuruAudioProcessor& processor);
    void paint (juce::Graphics& g) override;

private:
    void timerCallback() override;

    NanikaTukuruAudioProcessor& processor;
    std::array<float, NanikaTukuruAudioProcessor::scopeSize> samples {};

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (ScopeComponent)
};
