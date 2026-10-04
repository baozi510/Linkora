param(
  [string]$Destination = 'third_party/ffmpeg/source'
)

$ErrorActionPreference = 'Stop'

$Tag = 'n8.1.3'
$ExpectedCommit = '1041abdc962f4cc4f394aa8de9dc5236c0c3b9e7'
$Remote = 'https://github.com/FFmpeg/FFmpeg.git'

if (Test-Path -LiteralPath $Destination) {
  $existing = (& git -C $Destination rev-parse HEAD 2>$null | Out-String).Trim()
  if ($existing -eq $ExpectedCommit) {
    Write-Host "FFmpeg source already pinned at $ExpectedCommit"
    exit 0
  }
  throw "Destination exists but is not the pinned FFmpeg commit: $existing"
}

$parent = Split-Path -Parent $Destination
if ($parent) {
  New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

git clone --filter=blob:none --no-checkout $Remote $Destination
if ($LASTEXITCODE -ne 0) { throw 'FFmpeg clone failed.' }

git -C $Destination fetch --depth 1 origin "refs/tags/${Tag}:refs/tags/${Tag}"
if ($LASTEXITCODE -ne 0) { throw "Unable to fetch $Tag." }

git -C $Destination checkout --detach $Tag
if ($LASTEXITCODE -ne 0) { throw "Unable to checkout $Tag." }

$actual = (& git -C $Destination rev-parse HEAD | Out-String).Trim()
if ($actual -ne $ExpectedCommit) {
  throw "FFmpeg pin mismatch. Expected $ExpectedCommit, got $actual"
}

Write-Host "FFmpeg $Tag pinned successfully at $actual"
