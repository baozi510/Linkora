#include "analysis.h"
#include <node_api.h>
#include <memory>
#include <mutex>
#include <cstring>
#include <new>
extern "C" {
#include <libavutil/log.h>
}

namespace {
using namespace linkora_ffmpeg;
struct Key {
    napi_env env; std::string id;
    bool operator<(const Key &other) const {
        return env == other.env ? id < other.id : std::less<napi_env>()(env, other.env);
    }
};
std::mutex registryMutex;
std::map<Key, std::shared_ptr<RequestState>> requests;
struct Work {
    napi_env env = nullptr; napi_async_work work = nullptr; napi_deferred deferred = nullptr;
    std::string id, input; int timeout = 0, width = 0, height = 0; int64_t time = 0; bool frame = false;
    std::shared_ptr<RequestState> state;
    Probe probe; Frame pixels; Failure failure;
};
void Checked(napi_status status) { if (status != napi_ok) throw Failure{"FF_SIZE_REJECTED", "NAPI result allocation failed"}; }
napi_value Object(napi_env env) { napi_value value; Checked(napi_create_object(env, &value)); return value; }
void String(napi_env env, napi_value object, const char *key, const std::string &text) {
    napi_value value; Checked(napi_create_string_utf8(env, text.c_str(), text.size(), &value)); Checked(napi_set_named_property(env, object, key, value));
}
void Number(napi_env env, napi_value object, const char *key, double number) {
    napi_value value; Checked(napi_create_double(env, number, &value)); Checked(napi_set_named_property(env, object, key, value));
}
void Boolean(napi_env env, napi_value object, const char *key, bool flag) {
    napi_value value; Checked(napi_get_boolean(env, flag, &value)); Checked(napi_set_named_property(env, object, key, value));
}
napi_value StreamValue(napi_env env, const Stream &stream) {
    auto value = Object(env);
    Number(env, value, "index", stream.index); Number(env, value, "id", stream.id);
    String(env, value, "codec", stream.codec); String(env, value, "profile", stream.profile);
    Number(env, value, "level", stream.level); Number(env, value, "width", stream.width); Number(env, value, "height", stream.height);
    Number(env, value, "frameRate", stream.frameRate); Number(env, value, "bitrate", stream.bitrate);
    Number(env, value, "bitDepth", stream.bitDepth); Number(env, value, "dolbyVisionProfile", stream.dolbyVisionProfile);
    Boolean(env, value, "hasDolbyVisionConfiguration", stream.hasDolbyVisionConfiguration);
    Number(env, value, "channels", stream.channels); Number(env, value, "sampleRate", stream.sampleRate);
    String(env, value, "pixelFormat", stream.pixelFormat); String(env, value, "colorPrimaries", stream.colorPrimaries);
    String(env, value, "transfer", stream.transfer); String(env, value, "colorSpace", stream.colorSpace);
    String(env, value, "channelLayout", stream.channelLayout); String(env, value, "language", stream.language);
    String(env, value, "title", stream.title); String(env, value, "kind", stream.kind);
    Boolean(env, value, "isDefault", stream.isDefault); Boolean(env, value, "isForced", stream.isForced);
    return value;
}
void Streams(napi_env env, napi_value object, const char *key, const std::vector<Stream> &streams) {
    napi_value array; Checked(napi_create_array_with_length(env, streams.size(), &array));
    for (size_t i = 0; i < streams.size(); ++i) Checked(napi_set_element(env, array, i, StreamValue(env, streams[i])));
    Checked(napi_set_named_property(env, object, key, array));
}
napi_value ProbeValue(napi_env env, const Probe &probe) {
    auto value = Object(env);
    String(env, value, "container", probe.container); Number(env, value, "durationMs", probe.durationMs);
    Number(env, value, "bitrate", probe.bitrate); Number(env, value, "sizeBytes", probe.sizeBytes);
    Streams(env, value, "video", probe.video); Streams(env, value, "audio", probe.audio); Streams(env, value, "subtitles", probe.subtitles);
    napi_value chapters; Checked(napi_create_array_with_length(env, probe.chapters.size(), &chapters));
    for (size_t i = 0; i < probe.chapters.size(); ++i) {
        auto chapter = Object(env); Number(env, chapter, "startMs", probe.chapters[i].startMs);
        Number(env, chapter, "endMs", probe.chapters[i].endMs); String(env, chapter, "title", probe.chapters[i].title);
        Checked(napi_set_element(env, chapters, i, chapter));
    }
    Checked(napi_set_named_property(env, value, "chapters", chapters));
    auto tags = Object(env);
    for (const auto &tag : probe.tags) {
        // Use data-property definition rather than invoking the JS __proto__ setter.
        napi_value text; Checked(napi_create_string_utf8(env, tag.second.c_str(), tag.second.size(), &text));
        napi_property_descriptor property = {tag.first.c_str(), nullptr, nullptr, nullptr, nullptr, text, napi_default_jsproperty, nullptr};
        Checked(napi_define_properties(env, tags, 1, &property));
    }
    Checked(napi_set_named_property(env, value, "tags", tags)); return value;
}
napi_value FrameValue(napi_env env, const Frame &frame) {
    const auto bytes = FrameBytes(frame.width, frame.height);
    if (!bytes || frame.pixels.size() != bytes) throw Failure{"FF_SIZE_REJECTED", "Invalid RGBA output size"};
    auto value = Object(env); Number(env, value, "width", frame.width); Number(env, value, "height", frame.height);
    Number(env, value, "timeMs", frame.timeMs); String(env, value, "pixelFormat", "rgba_8888");
    void *data = nullptr; napi_value buffer;
    Checked(napi_create_arraybuffer(env, bytes, &data, &buffer)); std::memcpy(data, frame.pixels.data(), bytes);
    Checked(napi_set_named_property(env, value, "pixels", buffer)); return value;
}
void Reject(napi_env env, napi_deferred deferred, const Failure &failure) {
    napi_value message, error;
    if (napi_create_string_utf8(env, failure.code.c_str(), failure.code.size(), &message) != napi_ok ||
        napi_create_error(env, nullptr, message, &error) != napi_ok) return;
    String(env, error, "code", failure.code); String(env, error, "detail", failure.detail.substr(0, 256));
    napi_reject_deferred(env, deferred, error);
}
void Remove(const Work &work) {
    std::lock_guard<std::mutex> lock(registryMutex);
    const auto found = requests.find(Key{work.env, work.id});
    if (found != requests.end() && found->second == work.state) requests.erase(found);
}
void Execute(napi_env, void *data) {
    auto &work = *static_cast<Work *>(data);
    try {
        if (work.frame) work.pixels = ExtractFrame(work.input, *work.state, work.timeout, work.time, work.width, work.height);
        else work.probe = ProbeInput(work.input, *work.state, work.timeout);
    } catch (const Failure &failure) { work.failure = failure; }
    catch (const std::bad_alloc &) { work.failure = {"FF_SIZE_REJECTED", "Allocation rejected"}; }
    catch (...) { work.failure = {"FF_DECODE_FAILED", "Native operation failed"}; }
    work.state->Finish();
    if (work.state->Poll() == RequestStatus::Cancelled) work.failure = {"FF_CANCELLED", ""};
    if (work.state->Poll() == RequestStatus::Timeout) work.failure = {"FF_TIMEOUT", ""};
}
void Complete(napi_env env, napi_status status, void *data) {
    std::unique_ptr<Work> work(static_cast<Work *>(data)); Remove(*work);
    if (!env) return;
    try {
        if (status != napi_ok && work->failure.code.empty()) work->failure = {"FF_CANCELLED", ""};
        if (!work->failure.code.empty()) Reject(env, work->deferred, work->failure);
        else Checked(napi_resolve_deferred(env, work->deferred, work->frame ? FrameValue(env, work->pixels) : ProbeValue(env, work->probe)));
    } catch (const Failure &failure) { try { Reject(env, work->deferred, failure); } catch (...) {} }
    catch (...) { try { Reject(env, work->deferred, {"FF_SIZE_REJECTED", "Result allocation failed"}); } catch (...) {} }
    napi_delete_async_work(env, work->work);
}
bool ReadString(napi_env env, napi_value value, std::string &output, size_t max) {
    size_t bytes = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &bytes) != napi_ok || bytes > max) return false;
    output.resize(bytes + 1); size_t copied = 0;
    if (napi_get_value_string_utf8(env, value, output.data(), output.size(), &copied) != napi_ok || copied != bytes) return false;
    output.resize(bytes); return true;
}
bool ReadNumber(napi_env env, napi_value value, double &number) {
    return napi_get_value_double(env, value, &number) == napi_ok && std::isfinite(number) && std::floor(number) == number;
}
napi_value Start(napi_env env, napi_callback_info info, bool frame) {
    size_t count = frame ? 6 : 3; napi_value args[6] = {}; napi_value promise; napi_deferred deferred;
    if (napi_create_promise(env, &deferred, &promise) != napi_ok) return nullptr;
    try {
        std::unique_ptr<Work> work(new Work()); work->env = env; work->deferred = deferred; work->frame = frame;
        double timeout = 0, time = 0, width = 0, height = 0;
        if (napi_get_cb_info(env, info, &count, args, nullptr, nullptr) != napi_ok || count != (frame ? 6u : 3u) ||
            !ReadString(env, args[0], work->id, 128) || !ValidId(work->id) ||
            !ReadString(env, args[1], work->input, 4096) || !ValidInput(work->input) ||
            !ReadNumber(env, args[frame ? 5 : 2], timeout) || timeout < 1 || timeout > 120000) {
            Reject(env, deferred, {"FF_INVALID_INPUT", "Invalid id, input or deadline"}); return promise;
        }
        if (frame && (!ReadNumber(env, args[2], time) || time < 0 || time > 604800000 ||
            !ReadNumber(env, args[3], width) || !ReadNumber(env, args[4], height) ||
            width < 1 || width > 4096 || height < 1 || height > 4096 || !FrameBytes(width, height))) {
            Reject(env, deferred, {"FF_SIZE_REJECTED", "Invalid timestamp or frame bounds"}); return promise;
        }
        work->timeout = timeout; work->time = time; work->width = width; work->height = height;
        work->state = std::make_shared<RequestState>(Clock::now() + std::chrono::milliseconds(work->timeout));
        {
            std::lock_guard<std::mutex> lock(registryMutex);
            size_t active = 0; for (const auto &entry : requests) if (entry.first.env == env) ++active;
            if (active >= 16 || !requests.emplace(Key{env, work->id}, work->state).second) {
                Reject(env, deferred, {"FF_INVALID_INPUT", "Request id active or request limit reached"}); return promise;
            }
        }
        napi_value name;
        auto status = napi_create_string_utf8(env, "LinkoraFFmpeg", NAPI_AUTO_LENGTH, &name);
        if (status == napi_ok) status = napi_create_async_work(env, nullptr, name, Execute, Complete, work.get(), &work->work);
        if (status == napi_ok) status = napi_queue_async_work(env, work->work);
        if (status != napi_ok) {
            Remove(*work); if (work->work) napi_delete_async_work(env, work->work);
            Reject(env, deferred, {"FF_OPEN_FAILED", "Unable to queue native work"}); return promise;
        }
        work.release();
    } catch (...) { try { Reject(env, deferred, {"FF_SIZE_REJECTED", "Request allocation failed"}); } catch (...) {} }
    return promise;
}
napi_value ProbeCall(napi_env env, napi_callback_info info) { return Start(env, info, false); }
napi_value FrameCall(napi_env env, napi_callback_info info) { return Start(env, info, true); }
napi_value Cancel(napi_env env, napi_callback_info info) {
    size_t count = 1; napi_value argument, result; std::string id;
    if (napi_get_cb_info(env, info, &count, &argument, nullptr, nullptr) == napi_ok && count == 1 && ReadString(env, argument, id, 128)) {
        std::lock_guard<std::mutex> lock(registryMutex);
        const auto found = requests.find(Key{env, id}); if (found != requests.end()) found->second->Cancel();
    }
    napi_get_undefined(env, &result); return result;
}
void Cleanup(void *data) {
    const auto env = static_cast<napi_env>(data); std::lock_guard<std::mutex> lock(registryMutex);
    for (auto entry = requests.begin(); entry != requests.end();) {
        if (entry->first.env == env) { entry->second->Cancel(); entry = requests.erase(entry); } else ++entry;
    }
}
napi_value Init(napi_env env, napi_value exports) {
    // FFmpeg logs can include locator/headers. This module's hidden static FFmpeg is intentionally silent.
    av_log_set_level(AV_LOG_QUIET);
    napi_property_descriptor properties[] = {
        {"probe", nullptr, ProbeCall, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"extractFrame", nullptr, FrameCall, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"cancel", nullptr, Cancel, nullptr, nullptr, nullptr, napi_default, nullptr}
    };
    if (napi_define_properties(env, exports, 3, properties) != napi_ok || napi_add_env_cleanup_hook(env, Cleanup, env) != napi_ok) return nullptr;
    return exports;
}
napi_module module = {1, 0, nullptr, Init, "linkora_ffmpeg", nullptr, {0}};
__attribute__((constructor)) void Register() { napi_module_register(&module); }
}
