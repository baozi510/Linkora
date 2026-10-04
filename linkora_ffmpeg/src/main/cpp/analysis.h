#pragma once
#include "request_state.h"
#include <map>
#include <vector>

namespace linkora_ffmpeg {
struct Stream {
    int index = 0, id = 0, level = 0, width = 0, height = 0, bitDepth = 0, dolbyVisionProfile = 0;
    int channels = 0, sampleRate = 0;
    double frameRate = 0, bitrate = 0;
    std::string codec, profile, pixelFormat, colorPrimaries, transfer, colorSpace, channelLayout;
    std::string kind = "unknown", language, title;
    bool isDefault = false, isForced = false;
    bool hasDolbyVisionConfiguration = false;
};
struct Chapter { double startMs = 0, endMs = 0; std::string title; };
struct Probe {
    std::string container; double durationMs = 0, bitrate = 0, sizeBytes = 0;
    std::vector<Stream> video, audio, subtitles;
    std::vector<Chapter> chapters;
    std::map<std::string, std::string> tags;
};
struct Frame { int width = 0, height = 0; double timeMs = 0; std::vector<uint8_t> pixels; };
struct Failure { std::string code, detail; };
Probe ProbeInput(const std::string &input, RequestState &state, int timeoutMs);
Frame ExtractFrame(const std::string &input, RequestState &state, int timeoutMs,
    int64_t timeMs, int maxWidth, int maxHeight);
}
