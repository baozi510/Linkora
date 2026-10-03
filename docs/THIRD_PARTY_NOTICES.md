# 第三方资源说明

## Google Material Symbols

- 用途：Linkora 非播放器页面的操作、导航和列表图标。
- 样式：Material Symbols Outlined，固定为 24 optical size、400 weight、0 grade；空心和实心分别生成静态 TTF 子集。
- 来源：https://fonts.google.com/icons
- 上游仓库：https://github.com/google/material-design-icons
- 许可：Apache License 2.0。
- 本地资源：`entry/src/main/resources/rawfile/font/linkora_material_symbols_*.ttf`。
- 生成清单与脚本：`scripts/material-icons/icons.json`、`scripts/update-material-icons.ps1`。

页面只能通过 `AppIconName` 使用这些资源，避免散落引用导致图标风格和主题着色不一致。SVG 文件暂时作为迁移回退保留，确认字体方案稳定后再单独清理。

## libsmb2

- 用途：SMB 2/3 服务器认证、目录读取和远程文件读取。
- 上游仓库：https://github.com/sahlberg/libsmb2
- 版本：7.0.0，提交 `b3d560c02fb1268320d2fd1c17fe841b0d93b85f`。
- 许可：GNU Lesser General Public License v2.1。
- 本地源码：`entry/src/main/cpp/third_party/libsmb2`。

Linkora 将 libsmb2 作为 Native 静态依赖链接进应用模块；发布包应保留上游版权与 LGPL v2.1 许可文本。上游完整许可文件位于本地源码目录的 `COPYING`。

## libssh2

- 用途：SFTP 的 SSH 会话、认证、目录读取和远程文件读取。
- 上游仓库：https://github.com/libssh2/libssh2
- 版本：1.11.1，提交 `a312b43325e3383c865a87bb1d26cb52e3292641`。
- 许可：BSD 3-Clause。
- 本地源码：`entry/src/main/cpp/third_party/libssh2`。

## Mbed TLS

- 用途：为 libssh2 提供 mbedTLS 加密后端。
- 上游仓库：https://github.com/Mbed-TLS/mbedtls
- 版本：3.6.7，提交 `068ff080b369adfac81509f9b57b2afabaf82dc5`。
- 许可：Apache License 2.0。
- 本地源码：`entry/src/main/cpp/third_party/mbedtls`，构建所需 framework 子模块位于其 `framework` 目录。
