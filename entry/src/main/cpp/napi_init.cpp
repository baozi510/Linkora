#include <node_api.h>

#include <cerrno>
#include <cstdio>
#include <fcntl.h>
#include <string>
#include <utility>
#include <vector>
#include "remote_reader.h"

extern "C" {
#include "smb2/smb2.h"
#include "smb2/libsmb2.h"
#include "smb2/libsmb2-share-enum.h"
#include "smb2/libsmb2-raw.h"
}

namespace {

struct ConnectionOptions {
    std::string host;
    int32_t port = 445;
    std::string share;
    std::string path;
    std::string username;
    std::string password;
    std::string domain;
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

class SmbSession {
public:
    ~SmbSession()
    {
        if (context_ != nullptr) {
            if (connected_) {
                smb2_disconnect_share(context_);
            }
            smb2_destroy_context(context_);
        }
    }

    bool Connect(const ConnectionOptions &options, std::string &error)
    {
        context_ = smb2_init_context();
        if (context_ == nullptr) {
            error = "SMB_INIT: 无法初始化 SMB 客户端";
            return false;
        }
        smb2_set_timeout(context_, 8);
        smb2_set_authentication(context_, SMB2_SEC_NTLMSSP);
        const char *effectiveUser = options.username.empty() ? "Guest" : options.username.c_str();
        smb2_set_security_mode(context_, SMB2_NEGOTIATE_SIGNING_ENABLED);
        smb2_set_user(context_, effectiveUser);
        // libsmb2 uses a null password to request a real anonymous NTLMSSP session.
        // An empty-but-non-null password is a different login and can produce an invalid
        // signing key when Samba maps that failed account to guest.
        smb2_set_password(context_, options.username.empty() ? nullptr : options.password.c_str());
        if (!options.domain.empty()) {
            smb2_set_domain(context_, options.domain.c_str());
        }

        std::string server = options.host;
        if (options.port > 0 && options.port != 445) {
            server += ":" + std::to_string(options.port);
        }
        if (smb2_connect_share(context_, server.c_str(), options.share.c_str(), effectiveUser) != 0) {
            char statusCode[24] = {0};
            std::snprintf(statusCode, sizeof(statusCode), "0x%08x",
                static_cast<uint32_t>(smb2_get_nterror(context_)));
            error = "SMB_CONNECT(" + std::string(statusCode) + "): " + LastError();
            return false;
        }
        connected_ = true;
        return true;
    }

    smb2_context *Get() const
    {
        return context_;
    }

    std::string LastError() const
    {
        const char *message = context_ == nullptr ? nullptr : smb2_get_error(context_);
        return message == nullptr || message[0] == '\0' ? "未知 SMB 错误" : std::string(message);
    }

private:
    smb2_context *context_ = nullptr;
    bool connected_ = false;
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
    if (argc < 7 || !ReadString(env, argv[0], options.host) ||
        napi_get_value_int32(env, argv[1], &options.port) != napi_ok ||
        !ReadString(env, argv[2], options.share) || !ReadString(env, argv[3], options.path) ||
        !ReadString(env, argv[4], options.username) || !ReadString(env, argv[5], options.password) ||
        !ReadString(env, argv[6], options.domain)) {
        return false;
    }
    return !options.host.empty() && options.port > 0 && options.port <= 65535;
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
    SmbSession session;
    ConnectionOptions connection = context->options;
    const bool enumerateShares = connection.share.empty();
    if (enumerateShares) {
        connection.share = "IPC$";
        connection.path.clear();
    }
    if (!session.Connect(connection, context->error)) {
        return;
    }
    if (enumerateShares) {
        srvsvc_NetrShareEnum_rep *reply = smb2_share_enum_sync(session.Get(), SHARE_INFO_1);
        if (reply == nullptr) {
            context->error = "SMB_SHARE_ENUM: " + session.LastError();
            return;
        }
        if (reply->status != 0) {
            char statusCode[24] = {0};
            std::snprintf(statusCode, sizeof(statusCode), "0x%08x", reply->status);
            context->error = "SMB_SHARE_ENUM(" + std::string(statusCode) + "): " + session.LastError();
            smb2_free_data(session.Get(), reply);
            return;
        }
        const srvsvc_SHARE_INFO_1_CONTAINER &shares = reply->ses.ShareEnum.Level1;
        for (uint32_t index = 0; index < shares.EntriesRead; ++index) {
            const srvsvc_SHARE_INFO_1 &share = shares.share_info_1[index];
            if (share.netname == nullptr ||
                (share.type & 3U) != SRVSVC_SHARE_TYPE_DISKTREE ||
                (share.type & SRVSVC_SHARE_TYPE_HIDDEN) != 0) {
                continue;
            }
            NativeEntry entry;
            entry.name = share.netname;
            entry.directory = true;
            context->entries.push_back(std::move(entry));
        }
        smb2_free_data(session.Get(), reply);
        return;
    }
    const char *path = context->options.path.empty() ? "" : context->options.path.c_str();
    smb2dir *directory = smb2_opendir(session.Get(), path);
    if (directory == nullptr) {
        context->error = "SMB_LIST: " + session.LastError();
        return;
    }
    while (smb2dirent *item = smb2_readdir(session.Get(), directory)) {
        if (item->name == nullptr || std::string(item->name) == "." || std::string(item->name) == "..") {
            continue;
        }
        NativeEntry entry;
        entry.name = item->name;
        entry.directory = item->st.smb2_type == SMB2_TYPE_DIRECTORY;
        entry.size = item->st.smb2_size;
        entry.modifiedAt = item->st.smb2_mtime * 1000ULL + item->st.smb2_mtime_nsec / 1000000ULL;
        context->entries.push_back(std::move(entry));
    }
    smb2_closedir(session.Get(), directory);
}

void CompleteList(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "SMB_CANCELLED: 目录读取已取消" : context->error);
    } else {
        napi_value array;
        napi_create_array_with_length(env, context->entries.size(), &array);
        for (size_t index = 0; index < context->entries.size(); ++index) {
            const NativeEntry &entry = context->entries[index];
            napi_value object;
            napi_value value;
            napi_create_object(env, &object);
            napi_create_string_utf8(env, entry.name.c_str(), NAPI_AUTO_LENGTH, &value);
            napi_set_named_property(env, object, "name", value);
            napi_get_boolean(env, entry.directory, &value);
            napi_set_named_property(env, object, "isDirectory", value);
            napi_create_double(env, static_cast<double>(entry.size), &value);
            napi_set_named_property(env, object, "size", value);
            napi_create_double(env, static_cast<double>(entry.modifiedAt), &value);
            napi_set_named_property(env, object, "modifiedAt", value);
            napi_set_element(env, array, index, object);
        }
        napi_resolve_deferred(env, context->deferred, array);
    }
    napi_delete_async_work(env, context->work);
    delete context;
}

void ExecuteDownload(napi_env, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    SmbSession session;
    if (!session.Connect(context->options, context->error)) {
        return;
    }
    smb2fh *file = smb2_open(session.Get(), context->remotePath.c_str(), O_RDONLY);
    if (file == nullptr) {
        context->error = "SMB_OPEN: " + session.LastError();
        return;
    }
    FILE *output = std::fopen(context->localPath.c_str(), "wb");
    if (output == nullptr) {
        context->error = "LOCAL_WRITE: 无法创建播放缓存文件";
        smb2_close(session.Get(), file);
        return;
    }

    std::vector<uint8_t> buffer(1024 * 1024);
    uint64_t offset = 0;
    bool succeeded = true;
    for (;;) {
        int count = smb2_pread(session.Get(), file, buffer.data(), static_cast<uint32_t>(buffer.size()), offset);
        if (count == -EAGAIN) {
            continue;
        }
        if (count < 0) {
            context->error = "SMB_READ: " + session.LastError();
            succeeded = false;
            break;
        }
        if (count == 0) {
            break;
        }
        if (std::fwrite(buffer.data(), 1, static_cast<size_t>(count), output) != static_cast<size_t>(count)) {
            context->error = "LOCAL_WRITE: 播放缓存写入失败";
            succeeded = false;
            break;
        }
        std::fflush(output);
        offset += static_cast<uint64_t>(count);
    }
    std::fclose(output);
    smb2_close(session.Get(), file);
    if (!succeeded) {
        std::remove(context->localPath.c_str());
        return;
    }
    context->bytesWritten = offset;
}

void CompleteDownload(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "SMB_CANCELLED: 文件读取已取消" : context->error);
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
    if (napi_create_async_work(env, nullptr, resourceName, execute, complete, context, &context->work) != napi_ok ||
        napi_queue_async_work(env, context->work) != napi_ok) {
        Reject(env, context->deferred, "SMB_NATIVE: 无法启动 SMB 后台任务");
        if (context->work != nullptr) {
            napi_delete_async_work(env, context->work);
        }
        delete context;
    }
    return promise;
}

napi_value List(napi_env env, napi_callback_info info)
{
    size_t argc = 7;
    napi_value argv[7];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options)) {
        delete context;
        napi_throw_type_error(env, nullptr, "SMB 参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraSmbList", ExecuteList, CompleteList);
}

napi_value Download(napi_env env, napi_callback_info info)
{
    size_t argc = 9;
    napi_value argv[9];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options) || context->options.share.empty() || argc < 9 ||
        !ReadString(env, argv[7], context->remotePath) || !ReadString(env, argv[8], context->localPath) ||
        context->remotePath.empty() || context->localPath.empty()) {
        delete context;
        napi_throw_type_error(env, nullptr, "SMB 文件参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraSmbDownload", ExecuteDownload, CompleteDownload);
}

class SmbRemoteFile final : public remote_reader::File {
public:
    std::unique_ptr<SmbSession> session;
    smb2fh *file = nullptr;
    ~SmbRemoteFile() override { Close(); }
    bool Read(uint64_t offset, std::vector<uint8_t> &buffer, std::string &error) override
    {
        const int count = smb2_pread(session->Get(), file, buffer.data(), buffer.size(), offset);
        if (count < 0) { error = "SMB_READ: remote read failed"; return false; }
        buffer.resize(static_cast<size_t>(count)); return true;
    }
    void Close() override
    {
        if (file != nullptr && session != nullptr) smb2_close(session->Get(), file);
        file = nullptr; session.reset();
    }
};

napi_value OpenReader(napi_env env, napi_callback_info info)
{
    size_t argc = 8; napi_value argv[8];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    ConnectionOptions options; std::string path;
    if (!ReadConnectionArgs(env, argc, argv, options) || argc != 8 || options.share.empty() ||
        !ReadString(env, argv[7], path) || path.empty() || !remote_reader::SafeText(path) ||
        !remote_reader::SafeText(options.host) || !remote_reader::SafeText(options.share) ||
        !remote_reader::SafeText(options.username) || !remote_reader::SafeText(options.password) ||
        !remote_reader::SafeText(options.domain)) {
        napi_throw_type_error(env, nullptr, "SMB_READER: invalid parameters"); return nullptr;
    }
    return remote_reader::Open(env, [options, path](std::string &error) -> std::shared_ptr<remote_reader::File> {
        auto reader = std::make_shared<SmbRemoteFile>();
        reader->session = std::make_unique<SmbSession>();
        if (!reader->session->Connect(options, error)) return nullptr;
        reader->file = smb2_open(reader->session->Get(), path.c_str(), O_RDONLY);
        smb2_stat_64 stat{};
        if (reader->file == nullptr || smb2_fstat(reader->session->Get(), reader->file, &stat) != 0 ||
            stat.smb2_type != SMB2_TYPE_FILE) { error = "SMB_STAT: file unavailable"; return nullptr; }
        reader->size = stat.smb2_size; return reader;
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

NAPI_MODULE(linkora_smb, Init)
