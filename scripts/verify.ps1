param(
  [string]$StudioRoot = 'C:\Program Files\Huawei\DevEco Studio'
)

$ErrorActionPreference = 'Stop'

$sdkRoot = Join-Path $StudioRoot 'sdk'
$hvigor = Join-Path $StudioRoot 'tools\hvigor\bin\hvigorw.bat'
$javaRoot = Join-Path $StudioRoot 'jbr'
$testResult = Join-Path $PSScriptRoot '..\entry\.test\default\intermediates\test\coverage_data\test_result.txt'

if (-not (Test-Path -LiteralPath $hvigor)) {
  throw "DevEco Studio build tool was not found under: $StudioRoot"
}

$env:DEVECO_SDK_HOME = $sdkRoot
$env:JAVA_HOME = $javaRoot
$env:Path = "$(Join-Path $javaRoot 'bin');$env:Path"

Push-Location (Join-Path $PSScriptRoot '..')
try {
  $uiSource = Get-ChildItem -LiteralPath 'entry\src\main\ets' -Recurse -Filter '*.ets'
  $legacyPatterns = @(
    '^\s*@Component\s*$',
    '@State\b',
    '@Prop\b',
    '@Watch\b',
    '@StorageProp\b',
    '\$\$this\.',
    '\bAppStorage\.'
  )
  $legacyUsage = $uiSource | Select-String -Pattern $legacyPatterns
  $plainOutputs = $uiSource | Select-String -Pattern `
    '^\s+(on[A-Z][A-Za-z0-9]*|load[A-Z][A-Za-z0-9]*):\s*\([^)]*\)\s*=>.*=\s*'

  if ($legacyUsage -or $plainOutputs) {
    @($legacyUsage) + @($plainOutputs) | ForEach-Object { Write-Host $_ }
    throw 'ArkUI state management V1 usage remains.'
  }

  & (Join-Path $StudioRoot 'tools\node\node.exe') (Join-Path $PSScriptRoot 'check-local-persistence.cjs') $StudioRoot
  if ($LASTEXITCODE -ne 0) {
    throw 'Local persistence regression checks failed.'
  }

  & (Join-Path $StudioRoot 'tools\node\node.exe') (Join-Path $PSScriptRoot 'check-network-media-probe.cjs') --unit
  if ($LASTEXITCODE -ne 0) { throw 'HTTP range adapter regression checks failed.' }

  & (Join-Path $StudioRoot 'tools\node\node.exe') (Join-Path $PSScriptRoot 'check-network-media-list.cjs')
  if ($LASTEXITCODE -ne 0) { throw 'Network media list/cache regression checks failed.' }

  & $hvigor test --mode module -p module=entry@default -p product=default --no-daemon
  if ($LASTEXITCODE -ne 0) {
    throw 'Unit-test compilation failed.'
  }

  $result = Get-Content -LiteralPath $testResult -Raw
  if ($result -match 'Failure: [1-9]' -or $result -match 'Error: [1-9]') {
    throw "Unit tests reported a failure. See: $testResult"
  }

  foreach ($buildMode in @('debug', 'release')) {
    foreach ($harModule in @('linkora_core', 'linkora_proxy', 'linkora_media_probe')) {
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
  }

  Write-Host 'Verification completed: local persistence checks, unit tests, Debug/Release core/proxy/media-probe HAR and Debug/Release HAP passed.'
} finally {
  Pop-Location
}
