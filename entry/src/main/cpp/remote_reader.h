#pragma once
#include <node_api.h>
#include <algorithm>
#include <atomic>
#include <cmath>
#include <cstring>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <vector>

// Only shared lifecycle plumbing; protocol operations stay in their existing libraries.
namespace remote_reader {
constexpr uint64_t kMaxSafe = 9007199254740991ULL;
constexpr size_t kBlock = 256 * 1024;
struct File {
    uint64_t size = 0;
    std::atomic<bool> cancelled{false};
    std::mutex io;
    virtual ~File() = default;
    virtual bool Read(uint64_t offset, std::vector<uint8_t> &buffer, std::string &error) = 0;
    virtual void Close() = 0;
};
static std::mutex registryMutex;
static std::unordered_map<uint64_t, std::shared_ptr<File>> files;
static uint64_t nextHandle = 1;

inline bool Integer(napi_env env, napi_value value, uint64_t &result)
{
    double number = 0;
    if (napi_get_value_double(env, value, &number) != napi_ok || !std::isfinite(number) ||
        number < 0 || number > static_cast<double>(kMaxSafe) || std::floor(number) != number) return false;
    result = static_cast<uint64_t>(number);
    return true;
}
inline bool SafeText(const std::string &value)
{
    return value.size() <= 4096 && value.find_first_of("\r\n") == std::string::npos &&
        value.find('\0') == std::string::npos;
}
inline std::shared_ptr<File> Find(uint64_t handle)
{
    std::lock_guard<std::mutex> lock(registryMutex);
    const auto found = files.find(handle);
    return found == files.end() ? nullptr : found->second;
}
struct Work {
    napi_async_work work = nullptr;
    napi_deferred deferred = nullptr;
    std::shared_ptr<File> file;
    std::vector<uint8_t> bytes;
    std::string error;
    bool opening = false;
    bool reading = false;
    std::function<void(Work &)> action;
};
inline void Execute(napi_env, void *data)
{
    auto &job = *static_cast<Work *>(data);
    try { job.action(job); }
    catch (...) { job.error = "REMOTE_IO: operation failed"; }
    if (job.opening && (job.file == nullptr || job.file->size > kMaxSafe || !job.error.empty())) {
        if (job.file != nullptr) job.file->Close();
        job.file.reset();
        if (job.error.empty()) job.error = "REMOTE_SIZE: unavailable or too large";
    }
}
inline void Complete(napi_env env, napi_status status, void *data)
{
    auto *job = static_cast<Work *>(data);
    if (status != napi_ok && job->error.empty()) job->error = "REMOTE_CANCELLED";
    if (!job->error.empty()) {
        napi_value text, error;
        napi_create_string_utf8(env, job->error.c_str(), NAPI_AUTO_LENGTH, &text);
        napi_create_error(env, nullptr, text, &error);
        napi_reject_deferred(env, job->deferred, error);
    } else {
        napi_value result;
        if (job->opening) {
            uint64_t handle;
            { std::lock_guard<std::mutex> lock(registryMutex); handle = nextHandle++; files.emplace(handle, job->file); }
            napi_create_object(env, &result);
            napi_value value;
            napi_create_double(env, static_cast<double>(handle), &value);
            napi_set_named_property(env, result, "handle", value);
            napi_create_double(env, static_cast<double>(job->file->size), &value);
            napi_set_named_property(env, result, "size", value);
        } else if (job->reading) {
            void *buffer = nullptr;
            napi_create_arraybuffer(env, job->bytes.size(), &buffer, &result);
            if (!job->bytes.empty()) std::memcpy(buffer, job->bytes.data(), job->bytes.size());
        } else napi_get_undefined(env, &result);
        napi_resolve_deferred(env, job->deferred, result);
    }
    napi_delete_async_work(env, job->work);
    delete job;
}
inline napi_value Queue(napi_env env, Work *job)
{
    napi_value promise, name;
    napi_create_promise(env, &job->deferred, &promise);
    napi_create_string_utf8(env, "LinkoraRemoteReader", NAPI_AUTO_LENGTH, &name);
    if (napi_create_async_work(env, nullptr, name, Execute, Complete, job, &job->work) != napi_ok ||
        napi_queue_async_work(env, job->work) != napi_ok) {
        job->error = "REMOTE_QUEUE: cannot start worker";
        Complete(env, napi_ok, job);
    }
    return promise;
}
inline napi_value Open(napi_env env, std::function<std::shared_ptr<File>(std::string &)> open)
{
    auto *job = new Work();
    job->opening = true;
    job->action = [open](Work &work) { work.file = open(work.error); };
    return Queue(env, job);
}
inline napi_value Read(napi_env env, napi_callback_info info)
{
    size_t argc = 3; napi_value argv[3];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    uint64_t handle = 0, offset = 0, length = 0;
    if (argc != 3 || !Integer(env, argv[0], handle) || !Integer(env, argv[1], offset) ||
        !Integer(env, argv[2], length) || length == 0 || length > kBlock) {
        napi_throw_range_error(env, nullptr, "REMOTE_RANGE: invalid read"); return nullptr;
    }
    auto *job = new Work(); job->file = Find(handle); job->reading = true;
    job->action = [offset, length](Work &work) {
        if (work.file == nullptr) { work.error = "REMOTE_CLOSED"; return; }
        auto &file = *work.file;
        std::unique_lock<std::mutex> lock(file.io, std::try_to_lock);
        if (!lock.owns_lock()) { work.error = "REMOTE_BUSY: concurrent read"; return; }
        if (file.cancelled) { work.error = "REMOTE_CANCELLED"; return; }
        if (offset > file.size) { work.error = "REMOTE_RANGE: offset beyond file"; return; }
        work.bytes.resize(static_cast<size_t>(std::min<uint64_t>(length, file.size - offset)));
        if (!work.bytes.empty() && !file.Read(offset, work.bytes, work.error) && work.error.empty()) {
            work.error = "REMOTE_READ";
        }
        if (file.cancelled) work.error = "REMOTE_CANCELLED";
    };
    return Queue(env, job);
}
inline napi_value Cancel(napi_env env, napi_callback_info info)
{
    size_t argc = 1; napi_value argv[1]; uint64_t handle = 0;
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc == 1 && Integer(env, argv[0], handle)) {
        const auto file = Find(handle); if (file != nullptr) file->cancelled = true;
    }
    napi_value result; napi_get_undefined(env, &result); return result;
}
inline napi_value Close(napi_env env, napi_callback_info info)
{
    size_t argc = 1; napi_value argv[1]; uint64_t handle = 0;
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    if (argc != 1 || !Integer(env, argv[0], handle)) {
        napi_throw_type_error(env, nullptr, "REMOTE_HANDLE: invalid handle"); return nullptr;
    }
    auto *job = new Work();
    { std::lock_guard<std::mutex> lock(registryMutex);
      const auto found = files.find(handle);
      if (found != files.end()) { job->file = found->second; files.erase(found); } }
    if (job->file != nullptr) job->file->cancelled = true;
    job->action = [](Work &work) {
        if (work.file == nullptr) return;
        std::lock_guard<std::mutex> lock(work.file->io);
        work.file->Close();
    };
    return Queue(env, job);
}
} // namespace remote_reader
