"""Synthetic Phase 2 fixtures and independent host ffprobe truth. No downloads."""
import argparse
import hashlib
import json
import pathlib
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("directory", type=pathlib.Path)
parser.add_argument("--ffmpeg", default="/usr/bin/ffmpeg")
parser.add_argument("--ffprobe", default="/usr/bin/ffprobe")
args = parser.parse_args()
args.directory.mkdir(parents=True, exist_ok=True)
def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True).stdout
def generate(name, hevc=False, depth=8, transfer="bt709", primaries="bt709", multi=False, subtitle=False, long=False):
    duration = "60" if long else "4"
    command = [args.ffmpeg, "-hide_banner", "-loglevel", "error", "-y", "-f", "lavfi", "-i",
               f"testsrc2=size=640x360:rate=24:duration={duration}", "-f", "lavfi", "-i",
               f"sine=frequency=440:sample_rate=48000:duration={duration}"]
    if multi:
        command += ["-f", "lavfi", "-i", f"sine=frequency=880:sample_rate=48000:duration={duration}"]
    if subtitle:
        srt = args.directory / "synthetic.srt"
        srt.write_text("1\n00:00:00,000 --> 00:00:03,000\nLinkora synthetic subtitle\n", encoding="utf-8")
        command += ["-i", str(srt)]
    command += ["-map", "0:v", "-map", "1:a"]
    if multi: command += ["-map", "2:a"]
    if subtitle: command += ["-map", "2:s", "-c:s", "ass", "-metadata:s:s:0", "language=eng", "-metadata:s:s:0", "title=Synthetic ASS"]
    command += ["-c:v", "libx265" if hevc else "libx264", "-preset", "ultrafast", "-threads", "2",
                "-pix_fmt", "yuv420p10le" if depth == 10 else "yuv420p", "-g", "240" if long else "24",
                "-color_primaries", primaries, "-color_trc", transfer, "-colorspace", "bt2020nc" if primaries == "bt2020" else "bt709"]
    if hevc: command += ["-x265-params", "pools=2:frame-threads=2:log-level=error"]
    else: command += ["-crf", "18"]
    command += ["-c:a", "aac", "-ac", "2", "-metadata:s:a:0", "language=eng", "-metadata:s:a:0", "title=Synthetic English"]
    if multi: command += ["-metadata:s:a:1", "language=fra", "-metadata:s:a:1", "title=Synthetic French"]
    command += ["-t", duration, str(args.directory / name)]
    run(command)

specs = [("h264.mp4", {}), ("hevc.mkv", {"hevc": True}), ("main10.mkv", {"hevc": True, "depth": 10}),
         ("hdr10.mkv", {"hevc": True, "depth": 10, "transfer": "smpte2084", "primaries": "bt2020"}),
         ("hlg.mkv", {"hevc": True, "depth": 10, "transfer": "arib-std-b67", "primaries": "bt2020"}),
         ("multi.mkv", {"multi": True}), ("subtitle.mkv", {"subtitle": True}), ("long-gop.mkv", {"long": True})]
fixtures = []
for name, options in specs:
    generate(name, **options)
    file = args.directory / name
    truth = json.loads(run([args.ffprobe, "-v", "error", "-show_format", "-show_streams", "-of", "json", str(file)]))
    truth["format"].pop("filename", None)
    fixtures.append({"name": name, "sha256": hashlib.sha256(file.read_bytes()).hexdigest(), "truth": truth})
encoders = run([args.ffmpeg, "-hide_banner", "-encoders"])
result = {"generator": run([args.ffmpeg, "-version"]).splitlines()[0],
          "truthTool": run([args.ffprobe, "-version"]).splitlines()[0], "fixtures": fixtures,
          "bitmapSubtitle": {"status": "NOT RUN", "reason": "No PGS encoder or owned bitmap subtitle source", "pgsEncoderAvailable": "pgssub" in encoders}}
(args.directory.parent / "fixture-truth.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print(f"Generated {len(fixtures)} owned synthetic fixtures; independent truth saved")
