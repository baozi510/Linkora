#include <node_api.h>

#include <cerrno>
#include <cstdio>
#include <cstring>
#include <cstdint>
#include <fcntl.h>
#include <netdb.h>
#include <mutex>
#include <string>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>
#include <utility>
#include <vector>
#include "remote_reader.h"

extern "C" {
#include <libssh2.h>
#include <libssh2_sftp.h>
}

namespace {

constexpr long kTimeoutMs = 8000;

struct ConnectionOptions {
    std::string host;
    int32_t port = 22;
    std::string path;
    std::string username;
    std::string password;
    std::string privateKeyPath;
    std::string passphrase;
    std::string expectedFingerprint;
    int32_t hostKeyPolicy = 0;
    int32_t authMode = 0;
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
    std::string fingerprint;
    std::string error;
};

std::once_flag g_libssh2Init;

std::string LastSessionError(LIBSSH2_SESSION *session, int code)
{
    char *message = nullptr;
    int messageLength = 0;
    if (session != nullptr && libssh2_session_last_error(session, &message, &messageLength, 0) != 0 &&
        message != nullptr && messageLength > 0) {
        return std::string(message, static_cast<size_t>(messageLength));
    }
    return "错误码 " + std::to_string(code);
}

bool ConnectSocket(const std::string &host, int32_t port, int &socketFd, std::string &error)
{
    addrinfo hints{};
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_family = AF_UNSPEC;
    addrinfo *addresses = nullptr;
    const std::string portText = std::to_string(port);
    const int resolveResult = getaddrinfo(host.c_str(), portText.c_str(), &hints, &addresses);
    if (resolveResult != 0) {
        error = "SFTP_RESOLVE: 无法解析服务器地址";
        return false;
    }
    for (addrinfo *address = addresses; address != nullptr; address = address->ai_next) {
        const int candidate = socket(address->ai_family, address->ai_socktype, address->ai_protocol);
        if (candidate < 0) {
            continue;
        }
        const int flags = fcntl(candidate, F_GETFL, 0);
        if (flags < 0 || fcntl(candidate, F_SETFL, flags | O_NONBLOCK) < 0) {
            close(candidate);
            continue;
        }
        const int connectResult = connect(candidate, address->ai_addr, address->ai_addrlen);
        if (connectResult == 0) {
            fcntl(candidate, F_SETFL, flags);
            socketFd = candidate;
            freeaddrinfo(addresses);
            return true;
        }
        if (errno != EINPROGRESS) {
            close(candidate);
            continue;
        }
        fd_set writable;
        FD_ZERO(&writable);
        FD_SET(candidate, &writable);
        timeval timeout{};
        timeout.tv_sec = kTimeoutMs / 1000;
        timeout.tv_usec = (kTimeoutMs % 1000) * 1000;
        const int ready = select(candidate + 1, nullptr, &writable, nullptr, &timeout);
        if (ready > 0 && FD_ISSET(candidate, &writable)) {
            int socketError = 0;
            socklen_t socketErrorLength = sizeof(socketError);
            getsockopt(candidate, SOL_SOCKET, SO_ERROR, &socketError, &socketErrorLength);
            if (socketError == 0) {
                fcntl(candidate, F_SETFL, flags);
                socketFd = candidate;
                freeaddrinfo(addresses);
                return true;
            }
        }
        close(candidate);
    }
    freeaddrinfo(addresses);
    error = "SFTP_CONNECT: 连接服务器超时或被拒绝";
    return false;
}

std::string Fingerprint(const char *hash)
{
    if (hash == nullptr) {
        return "";
    }
    static constexpr char hex[] = "0123456789abcdef";
    std::string result = "SHA256:";
    for (size_t index = 0; index < 32; ++index) {
        const unsigned char value = static_cast<unsigned char>(hash[index]);
        result.push_back(hex[value >> 4]);
        result.push_back(hex[value & 0x0f]);
        if (index + 1 < 32) {
            result.push_back(':');
        }
    }
    return result;
}

std::string NormalizeFingerprint(const std::string &value)
{
    std::string result;
    for (char character : value) {
        if (character != ' ' && character != '\t' && character != '\r' && character != '\n') {
            result.push_back(character);
        }
    }
    return result;
}

class SftpSession {
public:
    ~SftpSession()
    {
        if (sftp_ != nullptr) {
            libssh2_sftp_shutdown(sftp_);
        }
        if (session_ != nullptr) {
            libssh2_session_disconnect(session_, "Linkora closing SFTP session");
            libssh2_session_free(session_);
        }
        if (socketFd_ >= 0) {
            close(socketFd_);
        }
    }

    bool Connect(const ConnectionOptions &options, std::string &fingerprint, std::string &error)
    {
        std::call_once(g_libssh2Init, []() { libssh2_init(0); });
        if (!ConnectSocket(options.host, options.port, socketFd_, error)) {
            return false;
        }
        session_ = libssh2_session_init();
        if (session_ == nullptr) {
            error = "SFTP_INIT: 无法初始化 SSH 会话";
            return false;
        }
        libssh2_session_set_blocking(session_, 1);
        libssh2_session_set_timeout(session_, kTimeoutMs);
        int result = libssh2_session_handshake(session_, socketFd_);
        if (result != 0) {
            error = "SFTP_HANDSHAKE: " + LastSessionError(session_, result);
            return false;
        }
        fingerprint = Fingerprint(libssh2_hostkey_hash(session_, LIBSSH2_HOSTKEY_HASH_SHA256));
        if (options.hostKeyPolicy == 1 && !options.expectedFingerprint.empty() &&
            NormalizeFingerprint(fingerprint) != NormalizeFingerprint(options.expectedFingerprint)) {
            error = "SFTP_HOSTKEY: 服务器主机指纹不匹配（当前指纹 " + fingerprint + "）";
            return false;
        }
        if (options.username.empty()) {
            error = "SFTP_AUTH: 请输入用户名";
            return false;
        }
        if (options.authMode == 1) {
            if (options.privateKeyPath.empty()) {
                error = "SFTP_AUTH: 未选择私钥文件";
                return false;
            }
            result = libssh2_userauth_publickey_fromfile(session_, options.username.c_str(), nullptr,
                options.privateKeyPath.c_str(), options.passphrase.empty() ? nullptr : options.passphrase.c_str());
        } else {
            result = libssh2_userauth_password(session_, options.username.c_str(), options.password.c_str());
        }
        if (result != 0 || !libssh2_userauth_authenticated(session_)) {
            error = "SFTP_AUTH: 账号或密码不正确，或者当前账号没有访问权限（" +
                LastSessionError(session_, result) + "）";
            return false;
        }
        sftp_ = libssh2_sftp_init(session_);
        if (sftp_ == nullptr) {
            error = "SFTP_INIT: 无法初始化 SFTP 子系统（" + LastSessionError(session_, -1) + "）";
            return false;
        }
        return true;
    }

    LIBSSH2_SFTP *GetSftp() const
    {
        return sftp_;
    }

private:
    int socketFd_ = -1;
    LIBSSH2_SESSION *session_ = nullptr;
    LIBSSH2_SFTP *sftp_ = nullptr;
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
    if (argc < 10 || !ReadString(env, argv[0], options.host) ||
        napi_get_value_int32(env, argv[1], &options.port) != napi_ok ||
        !ReadString(env, argv[2], options.path) || !ReadString(env, argv[3], options.username) ||
        !ReadString(env, argv[4], options.password) || !ReadString(env, argv[5], options.privateKeyPath) ||
        !ReadString(env, argv[6], options.passphrase) || !ReadString(env, argv[7], options.expectedFingerprint) ||
        napi_get_value_int32(env, argv[8], &options.hostKeyPolicy) != napi_ok ||
        napi_get_value_int32(env, argv[9], &options.authMode) != napi_ok) {
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
    SftpSession session;
    if (!session.Connect(context->options, context->fingerprint, context->error)) {
        return;
    }
    const std::string path = context->options.path.empty() ? "/" : context->options.path;
    LIBSSH2_SFTP_HANDLE *directory = libssh2_sftp_opendir(session.GetSftp(), path.c_str());
    if (directory == nullptr) {
        context->error = "SFTP_LIST: 无法读取目录（" + path + "）";
        return;
    }
    char name[1024] = {0};
    char longEntry[4096] = {0};
    LIBSSH2_SFTP_ATTRIBUTES attributes{};
    for (;;) {
        std::memset(&attributes, 0, sizeof(attributes));
        const int result = libssh2_sftp_readdir_ex(directory, name, sizeof(name), longEntry,
            sizeof(longEntry), &attributes);
        if (result == 0) {
            break;
        }
        if (result < 0) {
            context->error = "SFTP_LIST: 目录读取失败";
            break;
        }
        const std::string entryName(name, static_cast<size_t>(result));
        if (entryName == "." || entryName == "..") {
            continue;
        }
        NativeEntry entry;
        entry.name = entryName;
        entry.directory = (attributes.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) != 0 &&
            LIBSSH2_SFTP_S_ISDIR(attributes.permissions);
        if ((attributes.flags & LIBSSH2_SFTP_ATTR_SIZE) != 0) {
            entry.size = attributes.filesize;
        }
        if ((attributes.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != 0) {
            entry.modifiedAt = static_cast<uint64_t>(attributes.mtime) * 1000ULL;
        }
        context->entries.push_back(std::move(entry));
    }
    libssh2_sftp_closedir(directory);
}

void CompleteList(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "SFTP_CANCELLED: 目录读取已取消" : context->error);
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
    SftpSession session;
    if (!session.Connect(context->options, context->fingerprint, context->error)) {
        return;
    }
    LIBSSH2_SFTP_HANDLE *file = libssh2_sftp_open(session.GetSftp(), context->remotePath.c_str(),
        LIBSSH2_FXF_READ, 0);
    if (file == nullptr) {
        context->error = "SFTP_OPEN: 无法打开远程文件";
        return;
    }
    FILE *output = std::fopen(context->localPath.c_str(), "wb");
    if (output == nullptr) {
        context->error = "LOCAL_WRITE: 无法创建播放缓存文件";
        libssh2_sftp_close(file);
        return;
    }
    std::vector<char> buffer(1024 * 1024);
    bool succeeded = true;
    for (;;) {
        const ssize_t count = libssh2_sftp_read(file, buffer.data(), buffer.size());
        if (count == 0) {
            break;
        }
        if (count < 0) {
            context->error = "SFTP_READ: 远程文件读取失败";
            succeeded = false;
            break;
        }
        if (std::fwrite(buffer.data(), 1, static_cast<size_t>(count), output) != static_cast<size_t>(count)) {
            context->error = "LOCAL_WRITE: 播放缓存写入失败";
            succeeded = false;
            break;
        }
        std::fflush(output);
        context->bytesWritten += static_cast<uint64_t>(count);
    }
    std::fclose(output);
    libssh2_sftp_close(file);
    if (!succeeded) {
        std::remove(context->localPath.c_str());
    }
}

void CompleteDownload(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "SFTP_CANCELLED: 文件读取已取消" : context->error);
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
        Reject(env, context->deferred, "SFTP_NATIVE: 无法启动 SFTP 后台任务");
        if (context->work != nullptr) {
            napi_delete_async_work(env, context->work);
        }
        delete context;
    }
    return promise;
}

napi_value List(napi_env env, napi_callback_info info)
{
    size_t argc = 10;
    napi_value argv[10];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options)) {
        delete context;
        napi_throw_type_error(env, nullptr, "SFTP 参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraSftpList", ExecuteList, CompleteList);
}

napi_value Download(napi_env env, napi_callback_info info)
{
    size_t argc = 12;
    napi_value argv[12];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadConnectionArgs(env, argc, argv, context->options) || argc < 12 ||
        !ReadString(env, argv[10], context->remotePath) || !ReadString(env, argv[11], context->localPath) ||
        context->remotePath.empty() || context->localPath.empty()) {
        delete context;
        napi_throw_type_error(env, nullptr, "SFTP 文件参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraSftpDownload", ExecuteDownload, CompleteDownload);
}

class SftpRemoteFile final : public remote_reader::File {
public:
    std::unique_ptr<SftpSession> session;
    LIBSSH2_SFTP_HANDLE *file = nullptr;
    ~SftpRemoteFile() override { Close(); }
    bool Read(uint64_t offset, std::vector<uint8_t> &buffer, std::string &error) override
    {
        libssh2_sftp_seek64(file, offset);
        const ssize_t count = libssh2_sftp_read(file, reinterpret_cast<char *>(buffer.data()), buffer.size());
        if (count < 0) { error = "SFTP_READ: remote read failed"; return false; }
        buffer.resize(static_cast<size_t>(count)); return true;
    }
    void Close() override
    {
        if (file != nullptr) libssh2_sftp_close(file);
        file = nullptr; session.reset();
    }
};
napi_value OpenReader(napi_env env, napi_callback_info info)
{
    size_t argc = 11; napi_value argv[11];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    ConnectionOptions options; std::string path;
    if (!ReadConnectionArgs(env, argc, argv, options) || argc != 11 ||
        !ReadString(env, argv[10], path) || path.empty() || !remote_reader::SafeText(path) ||
        !remote_reader::SafeText(options.host) || !remote_reader::SafeText(options.username) ||
        !remote_reader::SafeText(options.password) || !remote_reader::SafeText(options.privateKeyPath) ||
        !remote_reader::SafeText(options.expectedFingerprint) ||
        (options.hostKeyPolicy == 1 && options.expectedFingerprint.empty())) {
        napi_throw_type_error(env, nullptr, "SFTP_READER: invalid parameters or missing trusted fingerprint"); return nullptr;
    }
    return remote_reader::Open(env, [options, path](std::string &error) -> std::shared_ptr<remote_reader::File> {
        auto reader = std::make_shared<SftpRemoteFile>(); reader->session = std::make_unique<SftpSession>();
        std::string fingerprint;
        if (!reader->session->Connect(options, fingerprint, error)) return nullptr;
        reader->file = libssh2_sftp_open(reader->session->GetSftp(), path.c_str(), LIBSSH2_FXF_READ, 0);
        LIBSSH2_SFTP_ATTRIBUTES stat{};
        if (reader->file == nullptr || libssh2_sftp_fstat(reader->file, &stat) != 0 ||
            !(stat.flags & LIBSSH2_SFTP_ATTR_SIZE) ||
            ((stat.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) && !LIBSSH2_SFTP_S_ISREG(stat.permissions))) {
            error = "SFTP_STAT: file unavailable"; return nullptr;
        }
        reader->size = stat.filesize; return reader;
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

NAPI_MODULE(linkora_sftp, Init)
