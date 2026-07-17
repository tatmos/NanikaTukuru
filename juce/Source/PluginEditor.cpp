#include "PluginEditor.h"

namespace Colours
{
const juce::Colour bgA = juce::Colour::fromString ("ffdfe8e2");
const juce::Colour ink = juce::Colour::fromString ("ff14201b");
const juce::Colour inkSoft = juce::Colour::fromString ("ff3d4f46");
const juce::Colour signal = juce::Colour::fromString ("ff0b7f72");
const juce::Colour meter = juce::Colour::fromString ("ffd97706");
}

NanikaTukuruAudioProcessorEditor::NanikaTukuruAudioProcessorEditor (NanikaTukuruAudioProcessor& p)
    : AudioProcessorEditor (&p),
      processorRef (p),
      scope (p)
{
    setSize (720, 640);
    setResizable (true, true);
    setResizeLimits (640, 560, 1200, 900);

    setupLabel (brandLabel, "NanikaTukuru", 28.0f, Colours::ink);
    setupLabel (headlineLabel, "Signal desk (VST3 / JUCE)", 16.0f, Colours::signal);
    addAndMakeVisible (brandLabel);
    addAndMakeVisible (headlineLabel);
    addAndMakeVisible (scope);

    playingButton.setColour (juce::ToggleButton::textColourId, Colours::ink);
    playingButton.setColour (juce::ToggleButton::tickColourId, Colours::signal);
    addAndMakeVisible (playingButton);

    waveLabel.setText ("Wave", juce::dontSendNotification);
    filterLabel.setText ("Filter", juce::dontSendNotification);
    for (auto* l : { &waveLabel, &filterLabel })
    {
        l->setColour (juce::Label::textColourId, Colours::inkSoft);
        addAndMakeVisible (*l);
    }

    waveBox.addItemList ({ "sine", "triangle", "sawtooth", "square" }, 1);
    filterBox.addItemList ({ "lowpass", "highpass", "bandpass" }, 1);
    addAndMakeVisible (waveBox);
    addAndMakeVisible (filterBox);

    setupSlider (freqSlider, freqLabel, "Frequency Hz");
    setupSlider (oscGainSlider, oscGainLabel, "Osc Gain");
    setupSlider (noiseGainSlider, noiseGainLabel, "Noise");
    setupSlider (cutoffSlider, cutoffLabel, "Cutoff Hz");
    setupSlider (qSlider, qLabel, "Q");
    setupSlider (delayTimeSlider, delayTimeLabel, "Delay s");
    setupSlider (delayFbSlider, delayFbLabel, "Feedback");
    setupSlider (delayWetSlider, delayWetLabel, "Wet");
    setupSlider (masterSlider, masterLabel, "Master");

    auto& apvts = processorRef.getAPVTS();
    playingAttachment = std::make_unique<ButtonAttachment> (apvts, "playing", playingButton);
    waveAttachment = std::make_unique<ComboAttachment> (apvts, "wave", waveBox);
    filterAttachment = std::make_unique<ComboAttachment> (apvts, "filterType", filterBox);
    freqAttachment = std::make_unique<SliderAttachment> (apvts, "freq", freqSlider);
    oscGainAttachment = std::make_unique<SliderAttachment> (apvts, "oscGain", oscGainSlider);
    noiseGainAttachment = std::make_unique<SliderAttachment> (apvts, "noiseGain", noiseGainSlider);
    cutoffAttachment = std::make_unique<SliderAttachment> (apvts, "cutoff", cutoffSlider);
    qAttachment = std::make_unique<SliderAttachment> (apvts, "q", qSlider);
    delayTimeAttachment = std::make_unique<SliderAttachment> (apvts, "delayTime", delayTimeSlider);
    delayFbAttachment = std::make_unique<SliderAttachment> (apvts, "delayFb", delayFbSlider);
    delayWetAttachment = std::make_unique<SliderAttachment> (apvts, "delayWet", delayWetSlider);
    masterAttachment = std::make_unique<SliderAttachment> (apvts, "master", masterSlider);
}

void NanikaTukuruAudioProcessorEditor::setupLabel (juce::Label& label, const juce::String& text, float size, juce::Colour colour)
{
    label.setText (text, juce::dontSendNotification);
    label.setFont (juce::FontOptions (size, juce::Font::bold));
    label.setColour (juce::Label::textColourId, colour);
    label.setJustificationType (juce::Justification::centredLeft);
}

void NanikaTukuruAudioProcessorEditor::setupSlider (juce::Slider& slider, juce::Label& label, const juce::String& text)
{
    slider.setSliderStyle (juce::Slider::LinearHorizontal);
    slider.setTextBoxStyle (juce::Slider::TextBoxRight, false, 64, 20);
    slider.setColour (juce::Slider::thumbColourId, Colours::meter);
    slider.setColour (juce::Slider::trackColourId, Colours::signal.withAlpha (0.35f));
    slider.setColour (juce::Slider::backgroundColourId, Colours::ink.withAlpha (0.15f));
    addAndMakeVisible (slider);

    label.setText (text, juce::dontSendNotification);
    label.setColour (juce::Label::textColourId, Colours::inkSoft);
    label.attachToComponent (&slider, false);
    addAndMakeVisible (label);
}

void NanikaTukuruAudioProcessorEditor::paint (juce::Graphics& g)
{
    g.fillAll (Colours::bgA);
    g.setColour (Colours::signal);
    g.fillRect (0, 0, getWidth(), 4);
}

void NanikaTukuruAudioProcessorEditor::resized()
{
    auto area = getLocalBounds().reduced (18);
    brandLabel.setBounds (area.removeFromTop (34));
    headlineLabel.setBounds (area.removeFromTop (24));
    area.removeFromTop (8);
    scope.setBounds (area.removeFromTop (180));
    area.removeFromTop (12);

    auto topRow = area.removeFromTop (28);
    playingButton.setBounds (topRow.removeFromLeft (110));
    topRow.removeFromLeft (12);
    waveLabel.setBounds (topRow.removeFromLeft (48));
    waveBox.setBounds (topRow.removeFromLeft (140));
    topRow.removeFromLeft (12);
    filterLabel.setBounds (topRow.removeFromLeft (48));
    filterBox.setBounds (topRow.removeFromLeft (140));

    area.removeFromTop (18);

    auto place = [&area] (juce::Slider& s)
    {
        area.removeFromTop (16); // room for attached label
        s.setBounds (area.removeFromTop (28));
        area.removeFromTop (4);
    };

    place (freqSlider);
    place (oscGainSlider);
    place (noiseGainSlider);
    place (cutoffSlider);
    place (qSlider);
    place (delayTimeSlider);
    place (delayFbSlider);
    place (delayWetSlider);
    place (masterSlider);
}
