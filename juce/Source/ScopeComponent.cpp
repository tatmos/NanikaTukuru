#include "ScopeComponent.h"

ScopeComponent::ScopeComponent (NanikaTukuruAudioProcessor& p)
    : processor (p)
{
    startTimerHz (30);
}

void ScopeComponent::timerCallback()
{
    processor.copyScopeSamples (samples);
    repaint();
}

void ScopeComponent::paint (juce::Graphics& g)
{
    auto bounds = getLocalBounds().toFloat();

    juce::ColourGradient bg (
        juce::Colour::fromString ("ff101814"), bounds.getCentreX(), bounds.getY(),
        juce::Colour::fromString ("ff1a2a24"), bounds.getCentreX(), bounds.getBottom(), false);
    g.setGradientFill (bg);
    g.fillRect (bounds);

    g.setColour (juce::Colour::fromString ("14f8fcf9"));
    for (float x = 0.0f; x < bounds.getWidth(); x += 60.0f)
        g.drawVerticalLine (juce::roundToInt (x), bounds.getY(), bounds.getBottom());
    for (float y = 0.0f; y < bounds.getHeight(); y += 40.0f)
        g.drawHorizontalLine (juce::roundToInt (y), bounds.getX(), bounds.getRight());

    juce::Path wave;
    const int n = static_cast<int> (samples.size());
    for (int i = 0; i < n; ++i)
    {
        const float x = bounds.getX() + bounds.getWidth() * (static_cast<float> (i) / static_cast<float> (n - 1));
        const float y = bounds.getY() + bounds.getHeight() * 0.42f
                        + samples[static_cast<size_t> (i)] * bounds.getHeight() * 0.32f;
        if (i == 0)
            wave.startNewSubPath (x, y);
        else
            wave.lineTo (x, y);
    }

    g.setColour (juce::Colour::fromString ("ff5eead4"));
    g.strokePath (wave, juce::PathStrokeType (2.0f));
}
