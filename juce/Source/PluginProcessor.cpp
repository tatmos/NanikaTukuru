#include "PluginProcessor.h"
#include "PluginEditor.h"

namespace
{
juce::StringArray waveChoices() { return { "sine", "triangle", "sawtooth", "square" }; }
juce::StringArray filterChoices() { return { "lowpass", "highpass", "bandpass" }; }
}

NanikaTukuruAudioProcessor::NanikaTukuruAudioProcessor()
    : AudioProcessor (BusesProperties()
                          .withOutput ("Output", juce::AudioChannelSet::stereo(), true)),
      apvts (*this, nullptr, "PARAMS", createParameterLayout())
{
    playingParam = apvts.getRawParameterValue ("playing");
    waveParam = apvts.getRawParameterValue ("wave");
    freqParam = apvts.getRawParameterValue ("freq");
    oscGainParam = apvts.getRawParameterValue ("oscGain");
    noiseGainParam = apvts.getRawParameterValue ("noiseGain");
    filterTypeParam = apvts.getRawParameterValue ("filterType");
    cutoffParam = apvts.getRawParameterValue ("cutoff");
    qParam = apvts.getRawParameterValue ("q");
    delayTimeParam = apvts.getRawParameterValue ("delayTime");
    delayFbParam = apvts.getRawParameterValue ("delayFb");
    delayWetParam = apvts.getRawParameterValue ("delayWet");
    masterParam = apvts.getRawParameterValue ("master");
}

juce::AudioProcessorValueTreeState::ParameterLayout NanikaTukuruAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    params.push_back (std::make_unique<juce::AudioParameterBool> (
        juce::ParameterID { "playing", 1 }, "Playing", true));

    params.push_back (std::make_unique<juce::AudioParameterChoice> (
        juce::ParameterID { "wave", 1 }, "Wave", waveChoices(), 2));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "freq", 1 }, "Frequency",
        juce::NormalisableRange<float> (55.0f, 1760.0f, 1.0f, 0.4f), 440.0f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "oscGain", 1 }, "Osc Gain",
        juce::NormalisableRange<float> (0.0f, 1.0f, 0.01f), 0.35f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "noiseGain", 1 }, "Noise Gain",
        juce::NormalisableRange<float> (0.0f, 0.4f, 0.01f), 0.08f));

    params.push_back (std::make_unique<juce::AudioParameterChoice> (
        juce::ParameterID { "filterType", 1 }, "Filter Type", filterChoices(), 0));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "cutoff", 1 }, "Cutoff",
        juce::NormalisableRange<float> (80.0f, 12000.0f, 10.0f, 0.35f), 2400.0f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "q", 1 }, "Q",
        juce::NormalisableRange<float> (0.1f, 18.0f, 0.1f, 0.4f), 0.9f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "delayTime", 1 }, "Delay Time",
        juce::NormalisableRange<float> (0.0f, 1.0f, 0.01f), 0.22f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "delayFb", 1 }, "Delay Feedback",
        juce::NormalisableRange<float> (0.0f, 0.85f, 0.01f), 0.28f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "delayWet", 1 }, "Delay Wet",
        juce::NormalisableRange<float> (0.0f, 1.0f, 0.01f), 0.35f));

    params.push_back (std::make_unique<juce::AudioParameterFloat> (
        juce::ParameterID { "master", 1 }, "Master",
        juce::NormalisableRange<float> (0.0f, 1.0f, 0.01f), 0.55f));

    return { params.begin(), params.end() };
}

void NanikaTukuruAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    currentSampleRate = sampleRate;
    juce::dsp::ProcessSpec spec {
        sampleRate,
        static_cast<juce::uint32> (samplesPerBlock),
        1u
    };

    filter.reset();
    filter.prepare (spec);
    lastFilterType = -1;
    updateFilter();

    delayLine.reset();
    delayLine.prepare (spec);
    delayLine.setMaximumDelayInSamples (static_cast<int> (sampleRate * 1.5));

    phase = 0.0f;
}

bool NanikaTukuruAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
        && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    return true;
}

float NanikaTukuruAudioProcessor::renderOscSample()
{
    const auto waveIndex = static_cast<int> (waveParam->load());
    float s = 0.0f;

    switch (static_cast<Wave> (waveIndex))
    {
        case Wave::sine:     s = std::sin (phase * juce::MathConstants<float>::twoPi); break;
        case Wave::triangle: s = 2.0f * std::abs (2.0f * phase - 1.0f) - 1.0f; break;
        case Wave::square:   s = phase < 0.5f ? 1.0f : -1.0f; break;
        case Wave::sawtooth:
        default:             s = 2.0f * phase - 1.0f; break;
    }

    const float freq = freqParam->load();
    phase += freq / static_cast<float> (currentSampleRate);
    if (phase >= 1.0f)
        phase -= std::floor (phase);

    return s;
}

void NanikaTukuruAudioProcessor::updateFilter()
{
    const int type = static_cast<int> (filterTypeParam->load());
    const float cutoff = cutoffParam->load();
    const float q = qParam->load();

    if (type == lastFilterType && std::abs (cutoff - lastCutoff) < 0.01f && std::abs (q - lastQ) < 0.001f)
        return;

    lastFilterType = type;
    lastCutoff = cutoff;
    lastQ = q;

    using F = juce::dsp::StateVariableTPTFilterType;
    switch (static_cast<FilterMode> (type))
    {
        case FilterMode::highpass: filter.setType (F::highpass); break;
        case FilterMode::bandpass: filter.setType (F::bandpass); break;
        case FilterMode::lowpass:
        default:                   filter.setType (F::lowpass); break;
    }

    filter.setCutoffFrequency (cutoff);
    // Web Q 0.1–18 → resonance-ish; StateVariable uses resonance typically around 1/Q style.
    // JUCE setResonance expects values roughly >= 0.1; map Q directly with clamp.
    filter.setResonance (juce::jlimit (0.1f, 10.0f, q));
}

void NanikaTukuruAudioProcessor::pushScopeSample (float sample)
{
    const int w = scopeWrite.load (std::memory_order_relaxed);
    scopeBuffer[static_cast<size_t> (w)] = sample;
    scopeWrite.store ((w + 1) % scopeSize, std::memory_order_relaxed);
}

void NanikaTukuruAudioProcessor::copyScopeSamples (std::array<float, scopeSize>& dest) const
{
    const int start = scopeWrite.load (std::memory_order_relaxed);
    for (int i = 0; i < scopeSize; ++i)
        dest[static_cast<size_t> (i)] = scopeBuffer[static_cast<size_t> ((start + i) % scopeSize)];
}

void NanikaTukuruAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midi)
{
    juce::ignoreUnused (midi);
    juce::ScopedNoDenormals noDenormals;

    buffer.clear();
    updateFilter();

    const bool playing = playingParam->load() >= 0.5f;
    const float oscGain = oscGainParam->load();
    const float noiseGain = noiseGainParam->load();
    const float delayTime = delayTimeParam->load();
    const float delayFb = delayFbParam->load();
    const float delayWet = delayWetParam->load();
    const float master = masterParam->load();
    const float dryGain = 1.0f - delayWet * 0.5f;

    const int numSamples = buffer.getNumSamples();
    const int numChannels = buffer.getNumChannels();
    const float delaySamples = juce::jlimit (
        1.0f,
        static_cast<float> (delayLine.getMaximumDelayInSamples() - 1),
        delayTime * static_cast<float> (currentSampleRate));

    delayLine.setDelay (delaySamples);

    for (int i = 0; i < numSamples; ++i)
    {
        float sample = 0.0f;

        if (playing)
        {
            const float osc = renderOscSample() * oscGain;
            const float noise = (random.nextFloat() * 2.0f - 1.0f) * noiseGain;
            sample = osc + noise;
        }

        // Mono filter then expand
        sample = filter.processSample (0, sample);

        const float delayed = delayLine.popSample (0);
        const float toDelay = sample + delayed * delayFb;
        delayLine.pushSample (0, juce::jlimit (-1.0f, 1.0f, toDelay));

        sample = sample * dryGain + delayed * delayWet;
        sample *= master;
        sample = juce::jlimit (-1.0f, 1.0f, sample);

        pushScopeSample (sample);

        for (int ch = 0; ch < numChannels; ++ch)
            buffer.setSample (ch, i, sample);
    }

    // Keep filter stereo state warm for multi-channel hosts
    for (int ch = 1; ch < numChannels; ++ch)
        juce::ignoreUnused (ch);
}

void NanikaTukuruAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    if (auto xml = apvts.copyState().createXml())
        copyXmlToBinary (*xml, destData);
}

void NanikaTukuruAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    if (auto xml = getXmlFromBinary (data, sizeInBytes))
        if (xml->hasTagName (apvts.state.getType()))
            apvts.replaceState (juce::ValueTree::fromXml (*xml));
}

juce::AudioProcessorEditor* NanikaTukuruAudioProcessor::createEditor()
{
    return new NanikaTukuruAudioProcessorEditor (*this);
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new NanikaTukuruAudioProcessor();
}
