#include <node_api.h>

#include <cerrno>
#include <cstdio>
#include <fcntl.h>
#include <sys/stat.h>
#include <string>
#include <utility>
#include <vector>
#include "remote_reader.h"

extern "C" {
#include <nfsc/libnfs.h>
}

namespace {

struct ConnectionOptions {
    std::string host;
    int32_t port = 2049;
    std::string rootPath;
    int32_t version = 0;
};

struct NativeEntry {
    std::string name;
    bool directory = false;
    uint64_t size = 0;
    uint64_t modifiedAt = 0;
};

struct AsyncContext {
    napi_async_work work = nullptr;
    napi_deferred deferred = nullptr;
    ConnectionOptions options;
    std::string remotePath;
    std::string localPath;
    std::vector<NativeEntry> entries;
    uint64_t bytesWritten = 0;
    std::string error;
};

class NfsSession {
public:
    ~NfsSession()
    {
        if (context_ != nullptr) {
            if (mounted_) {
                nfs_umount(context_);
            }
            nfs_destroy_context(context_);
        }
    }

    bool Connect(const ConnectionOptions &options, std::string &error)
    {
        context_ = nfs_init_context();
        if (context_ == nullptr) {
            error = "NFS_INIT: 无法初始化 NFS 客户端";
            return false;
        }
        nfs_set_timeout(context_, 8000); // libnfs uses milliseconds, in whole-second increments.
        nfs_set_autoreconnect(context_, 0);
        nfs_set_readonly(context_, 1);
        if (options.port > 0) {
            nfs_set_nfsport(context_, options.port);
        }
        if (options.version == 3) {
            if (nfs_set_version(context_, 3) != 0) {
                error = "NFS_VERSION: NFSv3 不可用";
                return false;
            }
        } else if (options.version == 4) {
            if (nfs_set_version(context_, 4) != 0) {
                error = "NFS_VERSION: NFSv4 不可用";
                return false;
            }
        } else {
            // The application currently exposes NFSv4 as the automatic choice.
            // It works with the lab endpoint because only the NFS service port is published.
            nfs_set_version(context_, 4);
        }
        if (nfs_mount(context_, options.host.c_str(), "/") != 0) {
            error = "NFS_MOUNT: " + LastError();
            return false;
        }
        mounted_ = true;
        return true;
    }

    struct nfs_context *Get() const
    {
        return context_;
    }

    std::string LastError() const
    {
        const char *message = context_ == nullptr ? nullptr : nfs_get_error(context_);
        return message == nullptr || message[0] == '\0' ? "未知 NFS 错误" : std::string(message);
    }

private:
    struct nfs_context *context_ = nullptr;
    bool mounted_ = false;
};

bool ReadString(napi_env env, napi_value value, std::string &result)
{
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) {
        return false;
    }
    std::vector<char> buffer(length + 1, '\0');
    if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &length) != napi_ok) {
        return false;
    }
    result.assign(buffer.data(), length);
    return true;
}

bool ReadConnectionArgs(napi_env env, size_t argc, napi_value *argv, ConnectionOptions &options)
{
    if (argc < 4 || !ReadString(env, argv[0], options.host) ||
        napi_get_value_int32(env, argv[1], &options.port) != napi_ok ||
        !ReadString(env, argv[2], options.rootPath) ||
        napi_get_value_int32(env, argv[3], &options.version) != napi_ok) {
        return false;
    }
    return !options.host.empty() && options.port > 0 && options.port <= 65535 &&
        (options.version == 0 || options.version == 3 || options.version == 4);
}

void Reject(napi_env env, napi_deferred deferred, const std::string &message)
{
    napi_value text;
    napi_value error;
    napi_create_string_utf8(env, message.c_str(), NAPI_AUTO_LENGTH, &text);
    napi_create_error(env, nullptr, text, &error);
    napi_reject_deferred(env, deferred, error);
}

void ExecuteList(napi_env, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    NfsSession session;
    if (!session.Connect(context->options, context->error)) {
        return;
    }
    const std::string path = context->options.rootPath.empty() ? "/" : context->options.rootPath;
    struct nfsdir *directory = nullptr;
    if (nfs_opendir(session.Get(), path.c_str(), &directory) != 0 || directory == nullptr) {
        context->error = "NFS_LIST: " + session.LastError();
        return;
    }
    while (struct nfsdirent *item = nfs_readdir(session.Get(), directory)) {
        if (item->name == nullptr || std::string(item->name) == "." ||
            std::string(item->name) == "..") {
            continue;
        }
        NativeEntry entry;
        entry.name = item->name;
        entry.directory = item->type == 2; // NF3DIR
        entry.size = item->size;
        entry.modifiedAt = static_cast<uint64_t>(item->mtime.tv_sec) * 1000ULL +
            static_cast<uint64_t>(item->mtime.tv_usec) / 1000ULL;
        context->entries.push_back(std::move(entry));
    }
    nfs_closedir(session.Get(), directory);
}

void ExecuteDownload(napi_env, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    NfsSession session;
    if (!session.Connect(context->options, context->error)) {
        return;
    }
    struct nfsfh *file = nullptr;
    if (nfs_open(session.Get(), context->remotePath.c_str(), O_RDONLY, &file) != 0 || file == nullptr) {
        context->error = "NFS_OPEN: " + session.LastError();
        return;
    }
    FILE *output = std::fopen(context->localPath.c_str(), "wb");
    if (output == nullptr) {
        context->error = "LOCAL_WRITE: 无法创建播放缓存文件";
        nfs_close(session.Get(), file);
        return;
    }
    std::vector<char> buffer(1024 * 1024);
    bool succeeded = true;
    for (;;) {
        const int count = nfs_read(session.Get(), file, buffer.data(), buffer.size());
        if (count == 0) {
            break;
        }
        if (count < 0) {
            context->error = "NFS_READ: " + session.LastError();
            succeeded = false;
            break;
        }
        if (std::fwrite(buffer.data(), 1, static_cast<size_t>(count), output) !=
            static_cast<size_t>(count)) {
            context->error = "LOCAL_WRITE: 播放缓存写入失败";
            succeeded = false;
            break;
        }
        std::fflush(output);
        context->bytesWritten += static_cast<uint64_t>(count);
    }
    std::fclose(output);
    nfs_close(session.Get(), file);
    if (!succeeded) {
        std::remove(context->localPath.c_str());
    }
}

void SetEntry(napi_env env, napi_value object, const NativeEntry &entry)
{
    napi_value value;
    napi_create_string_utf8(env, entry.name.c_str(), NAPI_AUTO_LENGTH, &value);
    napi_set_named_property(env, object, "name", value);
    napi_get_boolean(env, entry.directory, &value);
    napi_set_named_property(env, object, "isDirectory", value);
    napi_create_double(env, static_cast<double>(entry.size), &value);
    napi_set_named_property(env, object, "size", value);
    napi_create_double(env, static_cast<double>(entry.modifiedAt), &value);
    napi_set_named_property(env, object, "modifiedAt", value);
}

void CompleteList(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "NFS_CANCELLED: 目录读取已取消" :
            context->error);
    } else {
        napi_value array;
        napi_create_array_with_length(env, context->entries.size(), &array);
        for (size_t index = 0; index < context->entries.size(); ++index) {
            napi_value object;
            napi_create_object(env, &object);
            SetEntry(env, object, context->entries[index]);
            napi_set_element(env, array, index, object);
        }
        napi_resolve_deferred(env, context->deferred, array);
    }
    napi_delete_async_work(env, context->work);
    delete context;
}

void CompleteDownload(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "NFS_CANCELLED: 文件读取已取消" :
            context->error);
    } else {
        napi_value value;
        napi_create_double(env, static_cast<double>(context->bytesWritten), &value);
        napi_resolve_deferred(env, context->deferred, value);
    }
    napi_delete_async_work(env, context->work);
    delete context;
}

napi_value QueueWork(napi_env env, AsyncContext *context, const char *name,
    napi_async_execute_callback execute, napi_async_complete_callback complete)
{
    napi_value promise;
    napi_value resourceName;
    napi_create_promise(env, &context->deferred, &promise);
    napi_create_string_utf8(env, name, NAPI_AUTO_LENGTH, &resourceName);
    if (napi_create_async_work(env, nullptr, resourceName, execute, complete, context, &context->work) !=
            napi_ok || napi_queue_async_work(env, context->work) != napi_ok) {
        Reject(env, context->deferred, "NFS_NATIVE: 无法启动 NFS 后台任务");
        if (context->work != nullptr) {
            napi_delete_async_work(env, context->work);
        }
        delete context;
    }
    return promise;
}

napi_value List(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value argv[4];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options)) {
        delete context;
        napi_throw_type_error(env, nullptr, "NFS 参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraNfsList", ExecuteList, CompleteList);
}

napi_value Download(napi_env env, napi_callback_info info)
{
    size_t argc = 6;
    napi_value argv[6];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options) || argc < 6 ||
        !ReadString(env, argv[4], context->remotePath) || !ReadString(env, argv[5], context->localPath) ||
        context->remotePath.empty() || context->localPath.empty()) {
        delete context;
        napi_throw_type_error(env, nullptr, "NFS 文件参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraNfsDownload", ExecuteDownload, CompleteDownload);
}

class NfsRemoteFile final : public remote_reader::File {
public:
    std::unique_ptr<NfsSession> session;
    nfsfh *file = nullptr;
    ~NfsRemoteFile() override { Close(); }
    bool Read(uint64_t offset, std::vector<uint8_t> &buffer, std::string &error) override
    {
        const int count = nfs_pread(session->Get(), file, buffer.data(), buffer.size(), offset);
        if (count < 0) { error = "NFS_READ: remote read failed"; return false; }
        buffer.resize(static_cast<size_t>(count)); return true;
    }
    void Close() override
    {
        if (file != nullptr && session != nullptr) nfs_close(session->Get(), file);
        file = nullptr; session.reset();
    }
};
napi_value OpenReader(napi_env env, napi_callback_info info)
{
    size_t argc = 5; napi_value argv[5];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    ConnectionOptions options; std::string path;
    if (!ReadConnectionArgs(env, argc, argv, options) || argc != 5 ||
        !ReadString(env, argv[4], path) || path.empty() || !remote_reader::SafeText(path) ||
        !remote_reader::SafeText(options.host) || !remote_reader::SafeText(options.rootPath)) {
        napi_throw_type_error(env, nullptr, "NFS_READER: invalid parameters"); return nullptr;
    }
    return remote_reader::Open(env, [options, path](std::string &error) -> std::shared_ptr<remote_reader::File> {
        auto reader = std::make_shared<NfsRemoteFile>(); reader->session = std::make_unique<NfsSession>();
        if (!reader->session->Connect(options, error)) return nullptr;
        nfs_stat_64 stat{};
        if (nfs_open(reader->session->Get(), path.c_str(), O_RDONLY, &reader->file) != 0) {
            error = "NFS_OPEN: file unavailable"; return nullptr;
        }
        if (nfs_fstat64(reader->session->Get(), reader->file, &stat) != 0) {
            error = "NFS_FSTAT: metadata unavailable"; return nullptr;
        }
        if (!S_ISREG(stat.nfs_mode)) { error = "NFS_FILE_TYPE: not a regular file"; return nullptr; }
        reader->size = stat.nfs_size; return reader;
    });
}
napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor descriptors[] = {
        { "list", nullptr, List, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "download", nullptr, Download, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "openReader", nullptr, OpenReader, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "read", nullptr, remote_reader::Read, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "cancel", nullptr, remote_reader::Cancel, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "closeReader", nullptr, remote_reader::Close, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(descriptors) / sizeof(descriptors[0]), descriptors);
    return exports;
}

} // namespace

NAPI_MODULE(linkora_nfs, Init)
