cmake_minimum_required(VERSION 3.22)

project(NanikaTukuruAudioLab VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)
FetchContent_Declare(
  juce
  GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
  GIT_TAG 8.0.8
  GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(juce)

juce_add_plugin(NanikaTukuruAudioLab
  COMPANY_NAME "tatmos"
  BUNDLE_ID "com.tatmos.nanikatukuru.audiolab"
  IS_SYNTH TRUE
  NEEDS_MIDI_INPUT FALSE
  NEEDS_MIDI_OUTPUT FALSE
  IS_MIDI_EFFECT FALSE
  EDITOR_WANTS_KEYBOARD_FOCUS FALSE
  COPY_PLUGIN_AFTER_BUILD TRUE
  PLUGIN_MANUFACTURER_CODE Tatm
  PLUGIN_CODE NtkL
  FORMATS VST3 Standalone
  PRODUCT_NAME "NanikaTukuru Audio Lab"
  PLUGIN_DESCRIPTION "Mini signal desk — oscillator, noise, filter, delay"
)

target_sources(NanikaTukuruAudioLab
  PRIVATE
    Source/PluginProcessor.cpp
    Source/PluginProcessor.h
    Source/PluginEditor.cpp
    Source/PluginEditor.h
    Source/ScopeComponent.cpp
    Source/ScopeComponent.h
)

target_compile_definitions(NanikaTukuruAudioLab
  PUBLIC
    JUCE_WEB_BROWSER=0
    JUCE_USE_CURL=0
    JUCE_VST3_CAN_REPLACE_VST2=0
)

target_link_libraries(NanikaTukuruAudioLab
  PRIVATE
    juce::juce_audio_utils
    juce::juce_dsp
  PUBLIC
    juce::juce_recommended_config_flags
    juce::juce_recommended_warning_flags
)
