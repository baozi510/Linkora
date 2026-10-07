param(
  [string]$StudioRoot = 'C:\Program Files\Huawei\DevEco Studio'
)

$ErrorActionPreference = 'Stop'

$sdkRoot = Join-Path $StudioRoot 'sdk'
$hvigor = Join-Path $StudioRoot 'tools\hvigor\bin\hvigorw.bat'
$javaRoot = Join-Path $StudioRoot 'jbr'
$node = Join-Path $StudioRoot 'tools\node\node.exe'
$testResult = Join-Path $PSScriptRoot '..\entry\.test\default\intermediates\test\coverage_data\test_result.txt'

if (-not (Test-Path -LiteralPath $hvigor)) {
  throw "DevEco Studio build tool was not found under: $StudioRoot"
}

$env:DEVECO_SDK_HOME = $sdkRoot
$env:JAVA_HOME = $javaRoot
$env:Path = "$(Join-Path $javaRoot 'bin');$env:Path"

Push-Location (Join-Path $PSScriptRoot '..')
try {
  & $node (Join-Path $PSScriptRoot 'check-architecture-boundaries.cjs')
  if ($LASTEXITCODE -ne 0) {
    throw 'Architecture boundary checks failed.'
  }

  & $node (Join-Path $PSScriptRoot 'check-architecture-boundaries.test.cjs')
  if ($LASTEXITCODE -ne 0) { throw 'Architecture guard fixture checks failed.' }

  & $node (Join-Path $PSScriptRoot 'check-simulator-product.cjs')
  if ($LASTEXITCODE -ne 0) { throw 'Simulator product isolation checks failed.' }

  & $node (Join-Path $PSScriptRoot 'check-ffmpeg-phase1.cjs') $StudioRoot
  if ($LASTEXITCODE -ne 0) { throw 'FFmpeg Phase1 pure tests failed.' }
  & $node (Join-Path $PSScriptRoot 'check-ffmpeg-phase1.cjs') $StudioRoot --phase2
  if ($LASTEXITCODE -ne 0) { throw 'Analysis Phase2 pure tests failed.' }
  & $node --test (Join-Path $PSScriptRoot 'check-ffmpeg-artifact.test.cjs')
  if ($LASTEXITCODE -ne 0) { throw 'FFmpeg artifact guard tests failed.' }

  $mainArkTsSource = Get-ChildItem -LiteralPath 'entry\src\main\ets' -Recurse -Filter '*.ets'
  $legacyPatterns = @(
    '^\s*@Component\s*$',
    '@State\b',
    '@Prop\b',
    '@Watch\b',
    '@StorageProp\b',
    '\$\$this\.',
    '\bAppStorage\.'
  )
  $legacyUsage = $mainArkTsSource | Select-String -Pattern $legacyPatterns
  # Plain onX/loadX callback fields are an ArkUI component migration concern.
  # Keep this guard scoped to actual UI surfaces so service method parameters
  # such as NetworkMediaAnalysisCoordinator.inspect(..., onMetadata = ...)
  # cannot be misclassified as ArkUI state-management V1 output fields.
  $arkUiSource = @(
    Get-ChildItem -LiteralPath 'entry\src\main\ets\components' -Recurse -Filter '*.ets'
    Get-ChildItem -LiteralPath 'entry\src\main\ets\pages' -Recurse -Filter '*.ets'
  )
  $plainOutputs = $arkUiSource | Select-String -Pattern `
    '^\s+(on[A-Z][A-Za-z0-9]*|load[A-Z][A-Za-z0-9]*):\s*\([^)]*\)\s*=>.*=\s*'

  if ($legacyUsage -or $plainOutputs) {
    @($legacyUsage) + @($plainOutputs) | ForEach-Object { Write-Host $_ }
    throw 'ArkUI state management V1 usage remains.'
  }

  & $node (Join-Path $PSScriptRoot 'check-local-persistence.cjs') $StudioRoot
  if ($LASTEXITCODE -ne 0) {
    throw 'Local persistence regression checks failed.'
  }

  & $node (Join-Path $PSScriptRoot 'check-network-media-probe.cjs') --unit
  if ($LASTEXITCODE -ne 0) { throw 'HTTP range adapter regression checks failed.' }

  & $node (Join-Path $PSScriptRoot 'check-network-media-list.cjs')
  if ($LASTEXITCODE -ne 0) { throw 'Network media list/cache regression checks failed.' }

  & $node (Join-Path $PSScriptRoot 'check-mpv-playback-port.cjs') $StudioRoot
  if ($LASTEXITCODE -ne 0) { throw 'MPV adapter event-mapping regression checks failed.' }

  & $hvigor test --mode module -p module=entry@default -p product=default --no-daemon
  if ($LASTEXITCODE -ne 0) {
    throw 'Unit-test compilation failed.'
  }

  $result = Get-Content -LiteralPath $testResult -Raw
  if ($result -match 'Failure: [1-9]' -or $result -match 'Error: [1-9]') {
    throw "Unit tests reported a failure. See: $testResult"
  }

  foreach ($buildMode in @('debug', 'release')) {
    foreach ($harModule in @('linkora_core', 'linkora_proxy', 'linkora_media_probe', 'linkora_ffmpeg')) {
      & $hvigor assembleHar --mode module -p module=$harModule@default -p product=default `
        -p buildMode=$buildMode --no-daemon
      if ($LASTEXITCODE -ne 0) {
        throw "$harModule $buildMode HAR build failed."
      }
    }

    & $hvigor assembleHap --mode module -p module=entry@default -p product=default `
      -p buildMode=$buildMode --no-daemon
    if ($LASTEXITCODE -ne 0) {
      throw "$buildMode HAP build failed."
    }
    $hap = Get-ChildItem -LiteralPath 'entry\build\default\outputs' -Recurse -Filter '*unsigned.hap' |
      Sort-Object LastWriteTimeUtc | Select-Object -Last 1
    if ($null -eq $hap) { throw 'Default unsigned HAP missing for native ABI audit.' }
    & $node (Join-Path $PSScriptRoot 'check-ffmpeg-artifact.cjs') $hap.FullName arm64-v8a
    if ($LASTEXITCODE -ne 0) { throw "$buildMode default native ABI audit failed." }
  }

  Write-Host 'Verification completed: architecture boundaries, persistence checks, unit tests, HAR and HAP builds passed.'
} finally {
  Pop-Location
}
