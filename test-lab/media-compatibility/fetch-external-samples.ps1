param(
  [string]$OutputDirectory = (Join-Path $PSScriptRoot 'samples')
)

$ErrorActionPreference = 'Stop'
$sourceUrl = 'https://samples.ffmpeg.org/A-codecs/lossless/luckynight.ape'
$expectedSha256 = '6A7B79A6D530E9847C18119D627BD43C8D27DCEFB3EC7EC979B9B6306E34AC15'
$targetPath = Join-Path $OutputDirectory 'audio_ape.ape'

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
Invoke-WebRequest -Uri $sourceUrl -OutFile $targetPath

$actualSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $targetPath).Hash
if ($actualSha256 -ne $expectedSha256) {
  throw "APE sample checksum mismatch. Expected $expectedSha256, got $actualSha256."
}

Write-Output "Downloaded verified APE sample to $targetPath"
