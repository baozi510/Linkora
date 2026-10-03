#include <node_api.h>

#include <cerrno>
#include <cctype>
#include <chrono>
#include <cstdio>
#include <cstring>
#include <fcntl.h>
#include <netdb.h>
#include <sstream>
#include <string>
#include <sys/select.h>
#include <sys/socket.h>
#include <unistd.h>
#include <utility>
#include <vector>
#include "remote_reader.h"

namespace {

constexpr long kTimeoutMs = 8000;

struct FtpIo {
    std::chrono::steady_clock::time_point deadline =
        std::chrono::steady_clock::now() + std::chrono::milliseconds(kTimeoutMs);
    const std::atomic<bool> *cancelled = nullptr;
};

bool WaitSocket(int fd, bool writing, const FtpIo &io)
{
    if (fd < 0 || fd >= FD_SETSIZE) return false;
    for (;;) {
        if ((io.cancelled != nullptr && io.cancelled->load()) ||
            std::chrono::steady_clock::now() >= io.deadline) return false;
        const auto remaining = std::chrono::duration_cast<std::chrono::microseconds>(
            io.deadline - std::chrono::steady_clock::now()).count();
        if (remaining <= 0) return false;
        fd_set ready;
        FD_ZERO(&ready); FD_SET(fd, &ready);
        timeval timeout{};
        timeout.tv_usec = static_cast<long>(std::min<int64_t>(remaining, 100000));
        const int result = select(fd + 1, writing ? nullptr : &ready, writing ? &ready : nullptr,
            nullptr, &timeout);
        if (result > 0) return true;
        if (result < 0 && errno != EINTR) return false;
    }
}

struct ConnectionOptions {
    std::string host;
    int32_t port = 21;
    std::string rootPath;
    std::string username;
    std::string password;
    int32_t securityMode = 0;
    int32_t passiveMode = 0;
    std::string encoding;
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

bool ConnectSocket(const std::string &host, int32_t port, int &socketFd, std::string &error,
    const FtpIo *operation = nullptr)
{
    const FtpIo fallback;
    const FtpIo &io = operation == nullptr ? fallback : *operation;
    addrinfo hints{};
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_family = AF_UNSPEC;
    addrinfo *addresses = nullptr;
    const std::string portText = std::to_string(port);
    if (getaddrinfo(host.c_str(), portText.c_str(), &hints, &addresses) != 0) {
        error = "FTP_RESOLVE: 无法解析服务器地址";
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
        const int result = connect(candidate, address->ai_addr, address->ai_addrlen);
        bool connected = result == 0;
        if (result < 0 && errno == EINPROGRESS) {
            connected = WaitSocket(candidate, true, io);
            if (connected) {
                int socketError = 0;
                socklen_t length = sizeof(socketError);
                getsockopt(candidate, SOL_SOCKET, SO_ERROR, &socketError, &length);
                connected = socketError == 0;
            }
        }
        if (connected) {
            fcntl(candidate, F_SETFL, flags);
            timeval timeout{};
            timeout.tv_sec = kTimeoutMs / 1000;
            timeout.tv_usec = (kTimeoutMs % 1000) * 1000;
            setsockopt(candidate, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
            setsockopt(candidate, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));
            socketFd = candidate;
            freeaddrinfo(addresses);
            return true;
        }
        close(candidate);
    }
    freeaddrinfo(addresses);
    error = "FTP_CONNECT: 连接服务器超时或被拒绝";
    return false;
}

bool SendAll(int socketFd, const std::string &value, const FtpIo *operation = nullptr)
{
    const FtpIo fallback;
    const FtpIo &io = operation == nullptr ? fallback : *operation;
    size_t offset = 0;
    while (offset < value.size()) {
        if (!WaitSocket(socketFd, true, io)) return false;
        const ssize_t count = send(socketFd, value.data() + offset, value.size() - offset,
            MSG_DONTWAIT | MSG_NOSIGNAL);
        if (count < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) continue;
        if (count <= 0) {
            return false;
        }
        offset += static_cast<size_t>(count);
    }
    return true;
}

bool ReadLine(int socketFd, std::string &line, const FtpIo &io)
{
    line.clear();
    char character = 0;
    for (;;) {
        if (!WaitSocket(socketFd, false, io)) return false;
        const ssize_t count = recv(socketFd, &character, 1, MSG_DONTWAIT);
        if (count < 0 && (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK)) continue;
        if (count <= 0) {
            return false;
        }
        if (character == '\n') {
            return true;
        }
        if (character != '\r') {
            line.push_back(character);
        }
        if (line.size() > 16384) {
            return false;
        }
    }
}

struct FtpResponse {
    int code = 0;
    std::string text;
};

bool ReadResponse(int socketFd, FtpResponse &response, const FtpIo *operation = nullptr)
{
    const FtpIo fallback;
    const FtpIo &io = operation == nullptr ? fallback : *operation;
    std::string line;
    if (!ReadLine(socketFd, line, io) || line.size() < 3 ||
        !std::isdigit(static_cast<unsigned char>(line[0])) ||
        !std::isdigit(static_cast<unsigned char>(line[1])) ||
        !std::isdigit(static_cast<unsigned char>(line[2]))) {
        return false;
    }
    response.code = std::stoi(line.substr(0, 3));
    response.text = line;
    if (line.size() > 3 && line[3] == '-') {
        const std::string prefix = line.substr(0, 3);
        do {
            if (!ReadLine(socketFd, line, io) || response.text.size() + line.size() + 1 > 65536) {
                return false;
            }
            response.text += "\n" + line;
        } while (line.size() < 4 || line.compare(0, 3, prefix) != 0 || line[3] != ' ');
    }
    return true;
}

bool Command(int controlFd, const std::string &command, FtpResponse &response, std::string &error,
    const FtpIo *operation = nullptr)
{
    const FtpIo fallback;
    const FtpIo *io = operation == nullptr ? &fallback : operation;
    if (!SendAll(controlFd, command + "\r\n", io) || !ReadResponse(controlFd, response, io)) {
        error = "FTP_IO: 控制连接读取失败";
        return false;
    }
    if (response.code >= 400) {
        error = "FTP_COMMAND(" + std::to_string(response.code) + "): " + response.text;
        return false;
    }
    return true;
}

class FtpSession {
public:
    explicit FtpSession(const std::atomic<bool> *cancelled = nullptr) { io_.cancelled = cancelled; }
    void BeginOperation() { io_.deadline = std::chrono::steady_clock::now() +
        std::chrono::milliseconds(kTimeoutMs); }
    const FtpIo *Io() const { return &io_; }
    ~FtpSession()
    {
        if (controlFd_ >= 0) {
            // Closing transport is enough; never wait for a peer while disposing a cancelled reader.
            close(controlFd_);
        }
    }

    bool Connect(const ConnectionOptions &options, std::string &error)
    {
        BeginOperation();
        if (options.securityMode == 2 || options.securityMode == 3) {
            error = "FTP_TLS_UNSUPPORTED: 当前 FTP 客户端暂不支持 FTPS";
            return false;
        }
        if (!ConnectSocket(options.host, options.port, controlFd_, error, &io_)) {
            return false;
        }
        FtpResponse response;
        if (!ReadResponse(controlFd_, response, &io_) || response.code >= 400) {
            error = "FTP_GREETING: 服务器未返回有效欢迎信息";
            return false;
        }
        const std::string user = options.username.empty() ? "anonymous" : options.username;
        if (!Command(controlFd_, "USER " + user, response, error, &io_)) {
            return false;
        }
        if (response.code == 331 || response.code == 332) {
            const std::string password = options.password.empty() ? "anonymous@" : options.password;
            if (!Command(controlFd_, "PASS " + password, response, error, &io_)) {
                error = "FTP_AUTH: 账号或密码不正确，或者当前账号没有访问权限";
                return false;
            }
        }
        if (response.code < 200 || response.code >= 300) {
            error = "FTP_AUTH: 账号或密码不正确，或者当前账号没有访问权限";
            return false;
        }
        if (!Command(controlFd_, "TYPE I", response, error, &io_)) {
            return false;
        }
        return true;
    }

    int ControlFd() const
    {
        return controlFd_;
    }

    bool OpenDataSocket(const ConnectionOptions &options, int &dataFd, std::string &error)
    {
        if (options.passiveMode == 2) {
            error = "FTP_MODE_UNSUPPORTED: 当前暂不支持 FTP 主动模式，请使用被动模式或自动";
            return false;
        }
        FtpResponse response;
        if (Command(controlFd_, "EPSV", response, error, &io_) && response.code == 229) {
            int port = ParseEpsvPort(response.text);
            if (port > 0 && ConnectSocket(options.host, port, dataFd, error, &io_)) {
                return true;
            }
        }
        error.clear();
        if (!Command(controlFd_, "PASV", response, error, &io_) || response.code != 227) {
            return false;
        }
        std::string host;
        int port = 0;
        if (!ParsePasv(response.text, host, port)) {
            error = "FTP_PASV: 服务器返回的被动模式地址无效";
            return false;
        }
        return ConnectSocket(host, port, dataFd, error, &io_);
    }

private:
    static int ParseEpsvPort(const std::string &text)
    {
        const size_t open = text.find('(');
        if (open == std::string::npos || open + 1 >= text.size()) {
            return 0;
        }
        const char delimiter = text[open + 1];
        size_t end = text.find(delimiter, open + 2);
        if (end == std::string::npos) return 0;
        end = text.find(delimiter, end + 1);
        if (end == std::string::npos) return 0;
        end = text.find(delimiter, end + 1);
        if (end == std::string::npos || end <= open + 1) return 0;
        size_t start = end;
        while (start > open + 1 && std::isdigit(static_cast<unsigned char>(text[start - 1]))) {
            --start;
        }
        if (start == end) return 0;
        return std::stoi(text.substr(start, end - start));
    }

    static bool ParsePasv(const std::string &text, std::string &host, int &port)
    {
        const size_t open = text.find('(');
        const size_t closePosition = text.find(')', open == std::string::npos ? 0 : open);
        if (open == std::string::npos || closePosition == std::string::npos) return false;
        std::string value = text.substr(open + 1, closePosition - open - 1);
        std::vector<int> values;
        std::stringstream stream(value);
        std::string part;
        while (std::getline(stream, part, ',')) {
            try {
                values.push_back(std::stoi(part));
            } catch (...) {
                return false;
            }
        }
        if (values.size() != 6) return false;
        host = std::to_string(values[0]) + "." + std::to_string(values[1]) + "." +
            std::to_string(values[2]) + "." + std::to_string(values[3]);
        port = values[4] * 256 + values[5];
        return port > 0 && port <= 65535;
    }

    int controlFd_ = -1;
    FtpIo io_;
};

bool ReadData(int dataFd, std::string &data)
{
    char buffer[8192];
    for (;;) {
        const ssize_t count = recv(dataFd, buffer, sizeof(buffer), 0);
        if (count == 0) return true;
        if (count < 0) return false;
        data.append(buffer, static_cast<size_t>(count));
        if (data.size() > 8 * 1024 * 1024) return false;
    }
}

uint64_t ParseSize(const std::string &value)
{
    try {
        return static_cast<uint64_t>(std::stoull(value));
    } catch (...) {
        return 0;
    }
}

void ParseMlsd(const std::string &data, std::vector<NativeEntry> &entries)
{
    std::stringstream stream(data);
    std::string line;
    while (std::getline(stream, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        const size_t separator = line.find(' ');
        if (separator == std::string::npos || separator + 1 >= line.size()) continue;
        const std::string facts = line.substr(0, separator);
        NativeEntry entry;
        entry.name = line.substr(separator + 1);
        std::stringstream factStream(facts);
        std::string fact;
        while (std::getline(factStream, fact, ';')) {
            const size_t equals = fact.find('=');
            if (equals == std::string::npos) continue;
            const std::string key = fact.substr(0, equals);
            const std::string value = fact.substr(equals + 1);
            if (key == "Type") entry.directory = value == "dir" || value == "cdir" || value == "pdir";
            if (key == "Size") entry.size = ParseSize(value);
        }
        if (entry.name != "." && entry.name != ".." && !entry.name.empty()) entries.push_back(std::move(entry));
    }
}

void ParseList(const std::string &data, std::vector<NativeEntry> &entries)
{
    std::stringstream stream(data);
    std::string line;
    while (std::getline(stream, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.size() < 10 || (line[0] != 'd' && line[0] != '-' && line[0] != 'l')) continue;
        std::stringstream fields(line);
        std::vector<std::string> tokens;
        std::string token;
        while (fields >> token) tokens.push_back(token);
        if (tokens.size() < 9) continue;
        NativeEntry entry;
        entry.directory = tokens[0][0] == 'd';
        entry.size = ParseSize(tokens[4]);
        const size_t nameStart = line.find(tokens[8]);
        entry.name = nameStart == std::string::npos ? tokens[8] : line.substr(nameStart);
        if (entry.name != "." && entry.name != "..") entries.push_back(std::move(entry));
    }
}

bool ChangeDirectory(FtpSession &session, const std::string &path, std::string &error)
{
    if (path.empty() || path == "/" || path == ".") return true;
    FtpResponse response;
    return Command(session.ControlFd(), "CWD " + path, response, error);
}

bool ListDirectory(FtpSession &session, const ConnectionOptions &options,
    std::vector<NativeEntry> &entries, std::string &error)
{
    if (!ChangeDirectory(session, options.rootPath, error)) {
        error = "FTP_PATH: 远程目录不存在或无权访问";
        return false;
    }
    int dataFd = -1;
    FtpResponse response;
    if (!session.OpenDataSocket(options, dataFd, error)) return false;
    bool usedMlsd = false;
    if (SendAll(session.ControlFd(), "MLSD\r\n") && ReadResponse(session.ControlFd(), response) &&
        response.code >= 100 && response.code < 200) {
        usedMlsd = true;
    } else {
        close(dataFd);
        dataFd = -1;
        if (!session.OpenDataSocket(options, dataFd, error) ||
            !SendAll(session.ControlFd(), "LIST\r\n") || !ReadResponse(session.ControlFd(), response) ||
            response.code < 100 || response.code >= 200) {
            error = "FTP_LIST: 无法读取远程目录";
            return false;
        }
    }
    std::string data;
    const bool readSucceeded = ReadData(dataFd, data);
    close(dataFd);
    if (!readSucceeded || !ReadResponse(session.ControlFd(), response) || response.code >= 400) {
        error = "FTP_LIST: 目录数据读取失败";
        return false;
    }
    if (usedMlsd) ParseMlsd(data, entries);
    else ParseList(data, entries);
    return true;
}

void ExecuteList(napi_env, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    FtpSession session;
    if (!session.Connect(context->options, context->error)) return;
    ListDirectory(session, context->options, context->entries, context->error);
}

void ExecuteDownload(napi_env, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    FtpSession session;
    if (!session.Connect(context->options, context->error)) return;
    int dataFd = -1;
    if (!session.OpenDataSocket(context->options, dataFd, context->error)) return;
    FtpResponse response;
    if (!SendAll(session.ControlFd(), "RETR " + context->remotePath + "\r\n") ||
        !ReadResponse(session.ControlFd(), response) || response.code < 100 || response.code >= 200) {
        close(dataFd);
        context->error = "FTP_OPEN: 无法打开远程文件";
        return;
    }
    FILE *output = std::fopen(context->localPath.c_str(), "wb");
    if (output == nullptr) {
        close(dataFd);
        context->error = "LOCAL_WRITE: 无法创建播放缓存文件";
        return;
    }
    char buffer[1024 * 1024];
    bool succeeded = true;
    for (;;) {
        const ssize_t count = recv(dataFd, buffer, sizeof(buffer), 0);
        if (count == 0) break;
        if (count < 0 || std::fwrite(buffer, 1, static_cast<size_t>(count), output) != static_cast<size_t>(count)) {
            context->error = count < 0 ? "FTP_READ: 远程文件读取失败" : "LOCAL_WRITE: 播放缓存写入失败";
            succeeded = false;
            break;
        }
        std::fflush(output);
        context->bytesWritten += static_cast<uint64_t>(count);
    }
    std::fclose(output);
    close(dataFd);
    if (!ReadResponse(session.ControlFd(), response) || response.code >= 400) succeeded = false;
    if (!succeeded) std::remove(context->localPath.c_str());
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

void Reject(napi_env env, napi_deferred deferred, const std::string &message)
{
    napi_value text;
    napi_value error;
    napi_create_string_utf8(env, message.c_str(), NAPI_AUTO_LENGTH, &text);
    napi_create_error(env, nullptr, text, &error);
    napi_reject_deferred(env, deferred, error);
}

void CompleteList(napi_env env, napi_status status, void *data)
{
    auto *context = static_cast<AsyncContext *>(data);
    if (status != napi_ok || !context->error.empty()) {
        Reject(env, context->deferred, context->error.empty() ? "FTP_CANCELLED: 目录读取已取消" : context->error);
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
        Reject(env, context->deferred, context->error.empty() ? "FTP_CANCELLED: 文件读取已取消" : context->error);
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
        Reject(env, context->deferred, "FTP_NATIVE: 无法启动 FTP 后台任务");
        if (context->work != nullptr) napi_delete_async_work(env, context->work);
        delete context;
    }
    return promise;
}

bool ReadString(napi_env env, napi_value value, std::string &result)
{
    size_t length = 0;
    if (napi_get_value_string_utf8(env, value, nullptr, 0, &length) != napi_ok) return false;
    std::vector<char> buffer(length + 1, '\0');
    if (napi_get_value_string_utf8(env, value, buffer.data(), buffer.size(), &length) != napi_ok) return false;
    result.assign(buffer.data(), length);
    return true;
}

bool ReadArgs(napi_env env, size_t argc, napi_value *argv, ConnectionOptions &options)
{
    if (argc < 8 || !ReadString(env, argv[0], options.host) ||
        napi_get_value_int32(env, argv[1], &options.port) != napi_ok ||
        !ReadString(env, argv[2], options.rootPath) || !ReadString(env, argv[3], options.username) ||
        !ReadString(env, argv[4], options.password) ||
        napi_get_value_int32(env, argv[5], &options.securityMode) != napi_ok ||
        napi_get_value_int32(env, argv[6], &options.passiveMode) != napi_ok ||
        !ReadString(env, argv[7], options.encoding)) return false;
    return !options.host.empty() && options.port > 0 && options.port <= 65535;
}

napi_value List(napi_env env, napi_callback_info info)
{
    size_t argc = 8;
    napi_value argv[8];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadArgs(env, argc, argv, context->options)) {
        delete context;
        napi_throw_type_error(env, nullptr, "FTP 参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraFtpList", ExecuteList, CompleteList);
}

napi_value Download(napi_env env, napi_callback_info info)
{
    size_t argc = 10;
    napi_value argv[10];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    auto *context = new AsyncContext();
    if (!ReadArgs(env, argc, argv, context->options) || argc < 10 ||
        !ReadString(env, argv[8], context->remotePath) || !ReadString(env, argv[9], context->localPath) ||
        context->remotePath.empty() || context->localPath.empty()) {
        delete context;
        napi_throw_type_error(env, nullptr, "FTP 文件参数不完整");
        return nullptr;
    }
    return QueueWork(env, context, "LinkoraFtpDownload", ExecuteDownload, CompleteDownload);
}

class FtpRemoteFile final : public remote_reader::File {
public:
    ConnectionOptions options;
    std::string path;
    std::unique_ptr<FtpSession> session;
    int dataFd = -1;
    uint64_t cursor = 0;
    ~FtpRemoteFile() override { Close(); }
    bool Read(uint64_t offset, std::vector<uint8_t> &buffer, std::string &error) override
    {
        if (dataFd >= 0 && cursor != offset) Close();
        if (session == nullptr) {
            session = std::make_unique<FtpSession>(&cancelled);
            if (!session->Connect(options, error)) return false;
        } else session->BeginOperation();
        if (dataFd < 0) {
            FtpResponse response;
            if (!session->OpenDataSocket(options, dataFd, error) ||
                !Command(session->ControlFd(), "REST " + std::to_string(offset), response, error, session->Io()) ||
                response.code != 350 || !Command(session->ControlFd(), "RETR " + path, response, error, session->Io()) ||
                (response.code != 125 && response.code != 150)) {
                error = "FTP_RANGE: server cannot start range transfer"; Close(); return false;
            }
            cursor = offset;
        }
        const ssize_t count = WaitSocket(dataFd, false, *session->Io()) ?
            recv(dataFd, buffer.data(), buffer.size(), MSG_DONTWAIT) : -1;
        if (count < 0) { error = "FTP_READ: transfer failed or timed out"; Close(); return false; }
        buffer.resize(static_cast<size_t>(count)); cursor += static_cast<uint64_t>(count);
        // A discontinuous read discards the whole control session, so 426/226 cannot poison the next command.
        // ponytail: reconnect on seek; retain control with correct ABOR sequencing if seek-heavy playback needs it.
        if (count == 0 || cursor >= size) Close();
        return true;
    }
    void Close() override
    {
        if (dataFd >= 0) { shutdown(dataFd, SHUT_RDWR); close(dataFd); dataFd = -1; }
        session.reset();
    }
};
napi_value OpenReader(napi_env env, napi_callback_info info)
{
    size_t argc = 9; napi_value argv[9];
    napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
    ConnectionOptions options; std::string path;
    if (!ReadArgs(env, argc, argv, options) || argc != 9 ||
        !ReadString(env, argv[8], path) || path.empty() || !remote_reader::SafeText(path) ||
        !remote_reader::SafeText(options.host) || !remote_reader::SafeText(options.username) ||
        !remote_reader::SafeText(options.password) || !remote_reader::SafeText(options.rootPath)) {
        napi_throw_type_error(env, nullptr, "FTP_READER: invalid parameters"); return nullptr;
    }
    return remote_reader::Open(env, [options, path](std::string &error) -> std::shared_ptr<remote_reader::File> {
        auto reader = std::make_shared<FtpRemoteFile>(); reader->options = options; reader->path = path;
        reader->session = std::make_unique<FtpSession>(&reader->cancelled);
        FtpResponse response;
        if (options.passiveMode == 2) { error = "FTP_MODE_UNSUPPORTED"; return nullptr; }
        if (!reader->session->Connect(options, error) ||
            !Command(reader->session->ControlFd(), "SIZE " + path, response, error, reader->session->Io()) || response.code != 213) {
            if (error.empty()) error = "FTP_SIZE: file unavailable";
            return nullptr;
        }
        const std::string value = response.text.substr(4);
        if (value.empty() || value.find_first_not_of("0123456789") != std::string::npos) {
            error = "FTP_SIZE: invalid size"; return nullptr;
        }
        try { reader->size = std::stoull(value); } catch (...) { error = "FTP_SIZE: too large"; return nullptr; }
        return reader;
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

NAPI_MODULE(linkora_ftp, Init)
