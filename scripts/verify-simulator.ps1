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

if (-not (Test-Path -LiteralPath $hvigor)) {
  throw "DevEco Studio build tool was not found under: $StudioRoot"
}

$env:DEVECO_SDK_HOME = $sdkRoot
$env:JAVA_HOME = $javaRoot
$env:Path = "$(Join-Path $javaRoot 'bin');$env:Path"

Push-Location (Join-Path $PSScriptRoot '..')
try {
  & $node (Join-Path $PSScriptRoot 'check-simulator-product.cjs')
  if ($LASTEXITCODE -ne 0) {
    throw 'Simulator product static checks failed.'
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
  & $hvigor $seqTask --mode module -p module=entry@simulator -p product=simulator -p buildMode=$BuildMode --no-daemon
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
      $_.FullName -match '\.so$' -or $_.FullName -match '(^|/)libs?/'
    } | ForEach-Object { $_.FullName })

    if ($nativeEntries.Count -gt 0) {
      $nativeEntries | ForEach-Object { Write-Host "Unexpected native entry: $_" }
      throw 'Simulator HAP still contains native libraries.'
    }
  } finally {
    $zip.Dispose()
  }

  Write-Host "Simulator HAP verified: $($hap.FullName)"
  Write-Host 'No native .so entries were found in the simulator HAP.'
} finally {
  Pop-Location
}
