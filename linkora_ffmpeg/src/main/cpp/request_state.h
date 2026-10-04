#pragma once
#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>

namespace linkora_ffmpeg {
using Clock = std::chrono::steady_clock;
enum class RequestStatus { Active, Cancelled, Timeout, Completed };
class RequestState {
public:
    explicit RequestState(Clock::time_point deadline) : deadline_(deadline) {}
    void Cancel() { auto expected = RequestStatus::Active; status_.compare_exchange_strong(expected, RequestStatus::Cancelled); }
    RequestStatus Poll(Clock::time_point now = Clock::now()) {
        if (now >= deadline_) { auto expected = RequestStatus::Active; status_.compare_exchange_strong(expected, RequestStatus::Timeout); }
        return status_.load();
    }
    void Finish(Clock::time_point now = Clock::now()) {
        Poll(now); auto expected = RequestStatus::Active; status_.compare_exchange_strong(expected, RequestStatus::Completed);
    }
private:
    const Clock::time_point deadline_;
    std::atomic<RequestStatus> status_{RequestStatus::Active};
};
inline bool ValidId(const std::string &id) {
    if (id.empty() || id.size() > 128) return false;
    return std::all_of(id.begin(), id.end(), [](unsigned char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '_';
    });
}
inline bool ValidInput(const std::string &input) {
    if (input.empty() || input.size() > 4096 || input.find_first_of(std::string("\r\n\0", 3)) != std::string::npos) return false;
    if (input[0] == '/') return input.size() > 1 && input[1] != '/' && input.find(':') == std::string::npos;
    const std::string prefix = "http://127.0.0.1:";
    if (input.compare(0, prefix.size(), prefix) != 0) return false;
    const auto slash = input.find('/', prefix.size());
    if (slash == std::string::npos || slash == prefix.size() || slash + 1 == input.size()) return false;
    unsigned port = 0;
    for (size_t i = prefix.size(); i < slash; ++i) {
        if (input[i] < '0' || input[i] > '9') return false;
        port = port * 10 + input[i] - '0'; if (port > 65535) return false;
    }
    return port > 0 && ValidId(input.substr(slash + 1));
}
struct Dimensions { int width = 0; int height = 0; };
inline std::string BoundedMetadataText(const char *value, size_t max) {
    if (!value) return "";
    std::string result(value, strnlen(value, max));
    if (result.empty()) return result;
    size_t start = result.size() - 1;
    while (start > 0 && (static_cast<unsigned char>(result[start]) & 0xc0) == 0x80) --start;
    const auto lead = static_cast<unsigned char>(result[start]);
    const size_t needed = lead < 0x80 ? 1 : lead < 0xe0 ? 2 : lead < 0xf0 ? 3 : 4;
    if (result.size() - start < needed) result.resize(start);
    return result;
}
inline size_t FrameBytes(int width, int height) {
    if (width < 1 || height < 1 || width > 4096 || height > 4096) return 0;
    const uint64_t bytes = static_cast<uint64_t>(width) * height * 4;
    return bytes <= 32 * 1024 * 1024 ? static_cast<size_t>(bytes) : 0;
}
inline Dimensions Fit(int width, int height, int maxWidth, int maxHeight, double sar = 1) {
    if (width < 1 || height < 1 || !FrameBytes(maxWidth, maxHeight) || !std::isfinite(sar) || sar <= 0) return {};
    const double displayWidth = width * sar;
    if (!std::isfinite(displayWidth)) return {};
    const double scale = std::min({1.0, width / displayWidth, maxWidth / displayWidth, static_cast<double>(maxHeight) / height});
    return {std::max(1, static_cast<int>(std::floor(displayWidth * scale))),
        std::max(1, static_cast<int>(std::floor(height * scale)))};
}
}
