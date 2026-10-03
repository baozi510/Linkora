# Linkora 网络协议测试实验室

本目录只用于本地开发测试，不得把这里的账号、密码和密钥用于任何真实服务。所有共享默认只读，媒体样本与生成的密钥均被 Git 忽略。

## 覆盖矩阵

| 协议 | 状态 | WSL 端口 | 用户 | 凭据 |
| --- | --- | ---: | --- | --- |
| WebDAV | Basic Auth、只读 | 19080 | `linkora` | `LinkoraTest123!` |
| WebDAV | 匿名、只读 | 19081 | 无 | 无 |
| SMB 2/3 | 密码、只读，Share=`Media` | 1445 | `linkora` | `LinkoraTest123!` |
| SMB 2/3 | Guest、只读，Share=`GuestMedia` | 1446 | guest | 无 |
| SFTP | 密码、只读 | 12222 | `linkora` | `LinkoraTest123!` |
| SFTP | Ed25519 密钥、只读 | 12223 | `linkora` | `/var/lib/linkora-protocol-lab/secrets/sftp_client_ed25519` |
| FTP | 密码、只读 | 12121 | `linkora` | `LinkoraTest123!` |
| FTP | 匿名、只读 | 12122 | anonymous | 无密码 |
| NFS v4 | 匿名主机授权、只读 | 12049 | 无 | 无 |

FTP 密码服务的被动端口为 `21100-21109`，匿名服务为 `21200-21209`。`LAB_HOST_IP` 必须是客户端能够访问的 IPv4 地址。

NFS 样本会复制到 WSL 的 `/var/lib/linkora-protocol-lab/media`。不能直接导出 `/mnt/d`，因为 Windows DrvFS 不支持 Linux NFS export。

SFTP 客户端密钥与固定服务端主机密钥保存在 WSL 的 `/var/lib/linkora-protocol-lab/secrets`。不能放在 `/mnt/d`，因为 DrvFS 权限会使 OpenSSH 拒绝读取私钥。

`setup.sh` 会生成 `Movies`、`Series`、`Clips` 多级目录，并复制短视频样本。它们用于验证客户端的根列表、进入目录、含空格文件名和视频播放，不是产品数据。

## 启停

在 WSL 中执行：

```sh
cd /mnt/d/Linkora/test-lab/protocols
./scripts/setup.sh
./scripts/up.sh
./scripts/status.sh
./scripts/endpoints.sh
./scripts/verify.sh
```

`endpoints.sh` 会输出当前 WSL IP、各协议地址和 SFTP 主机指纹。WSL 重启后 IP 可能变化，模拟器连接前应重新执行一次。`verify.sh` 会实际检查认证、匿名访问、错误密码、WebDAV Range、SFTP 主机密钥和 NFS 只读约束。

模拟器可用 `endpoints.sh` 输出的 `Direct MP4` 地址验证网络直链播放。本机 2026-08-31 的验收结果为：应用预检返回 HTTP 200，播放器进入播放中状态，识别视频为 640 × 360、时长 10 秒。

停止服务但保留容器数据：

```sh
docker compose stop
```

删除本实验室容器和网络，不删除媒体样本与密钥：

```sh
./scripts/down.sh
```

## 故障状态

- 错误凭据：对任意认证服务使用错误密码或错误密钥。
- 服务离线：`docker compose stop <service>`，恢复使用 `docker compose start <service>`。
- NFS 拒绝访问：`docker compose -f compose.yml -f compose.nfs-denied.yml up -d --force-recreate nfs-readonly`。
- 恢复 NFS 开放只读：`docker compose -f compose.yml up -d --force-recreate nfs-readonly`。
- 连接被拒绝：使用相邻的未监听端口，例如 WebDAV `19082`。

## 与播放器实现的边界

本实验室已经证明协议服务端、认证方式和测试样本可用，但不等于每个协议的所有高级能力都已覆盖。当前应用已完成 HTTP/HTTPS 直链预检与播放器网络缓冲，WebDAV 的认证、目录列表、多级目录导航和文件播放，以及 SMB 2/3 的密码/Guest 认证、共享自动发现、目录导航、文件读取和渐进式缓存播放。SMB 的共享目录可以留空；此时应用通过 `IPC$` 枚举可见的磁盘共享，并将共享显示为根层文件夹。SFTP、FTP、NFS 已接入目录浏览和渐进式缓存播放；FTP 当前支持普通 FTP 被动模式，FTPS/主动模式仍会给出明确提示。开发客户端时以本目录的稳定端点和 `verify.sh` 为回归基线。

## 安全规则

- 仅在可信开发网络运行。
- 不向公网路由这些端口。
- SMB 强制最低 SMB2；不提供 SMB1。
- SFTP 固定服务端主机密钥，客户端应验证指纹。
- FTP 是明文协议，只用于验证风险提示和兼容性。
- NFS 容器需要 `privileged`，只允许在本地测试环境使用。
