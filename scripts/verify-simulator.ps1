param(
  [string]$StudioRoot = 'C:\Program Files\Huawei\DevEco Studio',
  [ValidateSet('debug', 'release')]
  [string]$BuildMode = 'debug'
)

$ErrorActionPreference = 'Stop'

$sdkRoot = Join-Path $StudioRoot 'sdk'
$hvigor = Join-Path $StudioRoot 'tools\hvigor\bin\hvigorw.bat'
$javaRoot = Join-Path $StudioRoot 'jbr'
$node = Join-Path $StudioRoot 'tools\node\node.exe'
$ohpm = Join-Path $StudioRoot 'tools\ohpm\bin\ohpm.bat'

if (-not (Test-Path -LiteralPath $hvigor)) {
  throw "DevEco Studio build tool was not found under: $StudioRoot"
}
if (-not (Test-Path -LiteralPath $ohpm)) {
  throw "DevEco Studio ohpm was not found under: $StudioRoot"
}

$env:DEVECO_SDK_HOME = $sdkRoot
$env:JAVA_HOME = $javaRoot
$env:Path = "$(Join-Path $StudioRoot 'tools\node');$(Join-Path $javaRoot 'bin');$env:Path"

Push-Location (Join-Path $PSScriptRoot '..')
try {
  & $node (Join-Path $PSScriptRoot 'check-simulator-product.cjs')
  if ($LASTEXITCODE -ne 0) {
    throw 'Simulator product static checks failed.'
  }

  & $node (Join-Path $PSScriptRoot 'check-audio-metadata-smoke.cjs')
  if ($LASTEXITCODE -ne 0) {
    throw 'Audio-only metadata diagnostic static checks failed.'
  }

  $taskOutput = (& $hvigor tasks --no-daemon 2>&1 | Out-String)
  $seqTask = ($taskOutput -split "\r?\n" |
    ForEach-Object { ($_ -split '\s+')[0].Trim() } |
    Where-Object { $_ -match '^assembleHap.*Seq$' } |
    Select-Object -First 1)

  if ([string]::IsNullOrWhiteSpace($seqTask)) {
    Write-Host $taskOutput
    throw 'No assembleHap*Seq task found. Run project Sync so the multi-target package plugin is installed.'
  }

  Write-Host "Using multi-target task: $seqTask"
  & $hvigor $seqTask --mode project -p module=entry@simulator -p product=simulator -p buildMode=$BuildMode --no-daemon
  if ($LASTEXITCODE -ne 0) {
    throw "Simulator HAP build failed via $seqTask."
  }

  $haps = @(Get-ChildItem -LiteralPath 'entry\build' -Recurse -Filter '*.hap')
  $hap = $haps |
    Where-Object { $_.Name -like 'linkora-simulator*.hap' } |
    Sort-Object LastWriteTimeUtc |
    Select-Object -Last 1
  if ($null -eq $hap) {
    $hap = $haps |
      Where-Object { $_.FullName -match '[\\/]simulator[\\/]' } |
      Sort-Object LastWriteTimeUtc |
      Select-Object -Last 1
  }
  if ($null -eq $hap) {
    throw 'Simulator HAP was not found under entry/build.'
  }

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [System.IO.Compression.ZipFile]::OpenRead($hap.FullName)
  try {
    $nativeEntries = @($zip.Entries | Where-Object {
      $_.FullName -match '\.so$'
    } | ForEach-Object { $_.FullName })

    $forbiddenNative = @($nativeEntries | Where-Object {
      $_ -match '(libmpv|mpv_wrapper|liblinkora_(smb|sftp|ftp|nfs))'
    })
    if ($forbiddenNative.Count -gt 0) {
      $forbiddenNative | ForEach-Object { Write-Host "Forbidden production-native entry: $_" }
      throw 'Simulator HAP contains arm64-only playback/network native libraries.'
    }

    $unknownNative = @($nativeEntries | Where-Object {
      $_ -notmatch '(^|/)liblinkora_ffmpeg\.so$'
    })
    if ($unknownNative.Count -gt 0) {
      $unknownNative | ForEach-Object { Write-Host "Unexpected native entry: $_" }
      throw 'Simulator HAP contains an unapproved native library.'
    }
  } finally {
    $zip.Dispose()
  }

  & $node (Join-Path $PSScriptRoot 'check-ffmpeg-artifact.cjs') $hap.FullName x86_64
  if ($LASTEXITCODE -ne 0) { throw 'Simulator FFmpeg native ELF/ABI audit failed.' }

  Write-Host "Simulator HAP verified: $($hap.FullName)"
  if ($nativeEntries.Count -eq 0) {
    Write-Host 'Simulator HAP currently contains no native .so files.'
  } else {
    Write-Host 'Simulator HAP native whitelist passed (FFmpeg analyzer only).'
  }
} finally {
  try {
    Write-Host 'Restoring the default dependency graph after simulator target resolution...'
    & $ohpm install
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to restore the default ohpm dependency graph after simulator verification.'
    }
  } finally {
    Pop-Location
  }
}
