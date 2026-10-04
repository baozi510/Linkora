# FFmpeg dual-ABI bootstrap evidence

Source: FFmpeg8.1.3/n8.1.3; commit1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7; tag object23151b11c75aa44d9ab8db796a53c76acf00f6c0. Source fetch02 + already-pinned03 exit0. No patches.

Both actual build commands completed exit0:

```bash
scripts/ffmpeg/build-harmony.sh x86_64 /d/Linkora-validation/artifacts/simulator-validation/native-sdk
scripts/ffmpeg/build-harmony.sh arm64-v8a /d/Linkora-validation/artifacts/simulator-validation/native-sdk
```

Environment preparation on this Windows host:

1. Native SDK installed at `C:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\native` (SDK26.0.0.105). A local ignored directory junction `artifacts/simulator-validation/native-sdk` references that exact directory, avoiding spaces in make tool paths.
2. Git Bash at `C:\Program Files\Git\bin\bash.exe`.
3. Actual MSYS2 GNU make4.4.1-3 copied to ignored local build-tools; package from https://mirror.msys2.org/msys/x86_64/make-4.4.1-3-x86_64.pkg.tar.zst, verifiedSHA256 `af0bdba17f06fe037f0194069adaa31a8fe45f1a11381501896aea1fae37bd5d`. No machine-wide installation or fake tools.
4. Call installed `C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\Tools\VsDevCmd.bat -arch=amd64` in a child cmd environment before Bash.
5. Put `/d/Linkora-validation/artifacts/simulator-validation/build-tools/usr/bin` first on Bash PATH.
6. Set configure's `host_cc` environment to `/d/Linkora-validation/artifacts/simulator-validation/native-sdk/llvm/bin/clang.exe --target=x86_64-pc-windows-msvc`. This compiles build-host programs with genuine Windows headers/libs; target compiler wrappers always separately force OHOS target/sysroot. No production script change was needed for host compiler selection.
7. Resolve and verify both build/prebuilt target paths remain under this checkout's third_party/ffmpeg before the build script removes generated output. Each ABI was a fresh configure/build/install.

Target cc wrappers use `--target=x86_64-linux-ohos` or `--target=aarch64-linux-ohos`, explicit real SDK sysroot. Recorded config files below contain exact flags. `--target-os=linux` is an explicit bootstrap assumption; both builds succeeded with no HarmonyOS patches.

Actual results for each ABI:

- Four real static archives, avformat/avcodec/avutil/swscale; all archive members checked via SDK llvm-readelf -h, only expected ELF machine.
- 133 installed include files, including avformat.h/avcodec.h/avutil.h/swscale.h and generated config headers.
- Build manifest with pin/ABI/triple/sysroot/profile.
- config.h: LGPL version2.1-or-later; GPL,NONFREE,SHARED,FFMPEG,FFPROBE,FFPLAY,ENCODERS,MUXERS,HWACCELS all0; STATIC1.
- No .exe or .so anywhere in either prefix. Installed share/examples are source examples, not programs.
- No headers/libs committed or packaged in Linkora; generated artifacts remain under ignored third_party/ffmpeg/prebuilt/{ABI}.

Audit JSON records size/SHA256 and ELF machine for every archive. Manifest/config/profile excerpts are committed next to this document. Full local evidence retained at `D:\Linkora-validation\artifacts\simulator-validation`:

- ffmpeg-fetch-01.txt: original invalid-refspec failure.
- ffmpeg-fetch-02.txt / ffmpeg-fetch-03.txt: successful exact pin.
- ffmpeg-x86_64-build-01.txt / ffmpeg-x86_64-config-01.log: missing gcc incorrectly summarized as missingC11.
- ffmpeg-x86_64-build-02.txt / ffmpeg-x86_64-config-02.log: MSVC cl rejected GNU std flags.
- ffmpeg-x86_64-build-03.txt / ffmpeg-x86_64-config-03.log: full successful x86 build/configure.
- ffmpeg-arm64-build.txt / ffmpeg-arm64-config.log: full successful arm64 build/configure.

FFmpegMediaProbe/FFmpegThumbnailExtractor integration, runtime probe/frame decode, MediaProxy-to-FFmpeg smoke, FFmpeg license packaging/integration acceptance gate, and System-vs-FFmpeg benchmark remain NOT RUN. Bootstrap build success does not satisfy all integration exit criteria and does not authorize the next phase.
