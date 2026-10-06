# Linkora Analysis Benchmark Report

Records: 240

> Benchmark data is descriptive evidence. Policy changes require a separate GPT review.

## Aggregate

| Operation | Requirement | Engine | Source | N | Success | Complete | P50 ms | P95 ms | Avg prepare | Avg probe/extract | Avg encode | Avg write | Avg bytes | Avg ranges | Avg WebP bytes | Avg memory |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| analysis.metadata | advanced | ffmpeg | webdav | 40 | 100.0% | 100.0% | 230 | 391 | 111 | 149 | - | - | 686381 | 2.0 | - | - |
| analysis.metadata | advanced | system | webdav | 40 | 100.0% | 0.0% | 331 | 464 | 110 | 245 | - | - | 543841 | 2.5 | - | - |
| analysis.metadata | list | ffmpeg | webdav | 40 | 100.0% | 100.0% | 245 | 404 | 112 | 158 | - | - | 673274 | 2.0 | - | - |
| analysis.metadata | list | system | webdav | 40 | 100.0% | 100.0% | 366 | 454 | 114 | 248 | - | - | 543841 | 2.5 | - | - |
| analysis.thumbnail | thumbnail | ffmpeg | webdav | 40 | 100.0% | 100.0% | 1030 | 1894 | - | 1296 | 80 | 2 | 7190498 | 3.0 | 7051 | - |
| analysis.thumbnail | thumbnail | system | webdav | 40 | 100.0% | 100.0% | 719 | 794 | - | 641 | 72 | 2 | 681500 | 3.0 | 6495 | - |

## Per case

| Case | Operation | Requirement | Engine | N | Success | Complete | P50 ms | P95 ms | Avg bytes | Avg ranges |
| --- | --- | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| mkv-hevc-aac | analysis.metadata | advanced | ffmpeg | 20 | 100.0% | 100.0% | 208 | 229 | 262144 | 1.0 |
| mkv-hevc-aac | analysis.metadata | advanced | system | 20 | 100.0% | 0.0% | 303 | 331 | 532480 | 2.0 |
| mkv-hevc-aac | analysis.metadata | list | ffmpeg | 20 | 100.0% | 100.0% | 218 | 244 | 262144 | 1.0 |
| mkv-hevc-aac | analysis.metadata | list | system | 20 | 100.0% | 100.0% | 327 | 366 | 532480 | 2.0 |
| mkv-hevc-aac | analysis.thumbnail | thumbnail | ffmpeg | 20 | 100.0% | 100.0% | 1842 | 1906 | 9993577 | 3.0 |
| mkv-hevc-aac | analysis.thumbnail | thumbnail | system | 20 | 100.0% | 100.0% | 694 | 752 | 794692 | 3.0 |
| mp4-h264-aac | analysis.metadata | advanced | ffmpeg | 20 | 100.0% | 100.0% | 358 | 398 | 1110619 | 3.0 |
| mp4-h264-aac | analysis.metadata | advanced | system | 20 | 100.0% | 0.0% | 426 | 473 | 555201 | 3.0 |
| mp4-h264-aac | analysis.metadata | list | ffmpeg | 20 | 100.0% | 100.0% | 352 | 409 | 1084404 | 3.0 |
| mp4-h264-aac | analysis.metadata | list | system | 20 | 100.0% | 100.0% | 411 | 471 | 555201 | 3.0 |
| mp4-h264-aac | analysis.thumbnail | thumbnail | ffmpeg | 20 | 100.0% | 100.0% | 926 | 995 | 4387419 | 3.0 |
| mp4-h264-aac | analysis.thumbnail | thumbnail | system | 20 | 100.0% | 100.0% | 761 | 828 | 568308 | 3.0 |
