param(
  [string]$StudioRoot = 'C:\Program Files\Huawei\DevEco Studio'
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

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$buildProfile = Join-Path $projectRoot 'build-profile.json5'
$backup = Join-Path $projectRoot 'build-profile.json5.bak'

Copy-Item -LiteralPath $buildProfile -Destination $backup -Force

try {
  $content = Get-Content -LiteralPath $buildProfile -Raw
  $signingOverlay = @"
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "C:\\Users\\pugdudu\\.ohos\\config\\default_Linkora_sv3r0SeWGTnM86w19AGlL3mRoSIn_jQhwTzuJIJgWZA=.cer",
          "keyAlias": "debugKey",
          "keyPassword": "0000001BB8A29177399A4B693808FE88FED0311AA9BBED4AECCCBE1483FC45C159D832BE803081D2D33210",
          "profile": "C:\\Users\\pugdudu\\.ohos\\config\\default_Linkora_sv3r0SeWGTnM86w19AGlL3mRoSIn_jQhwTzuJIJgWZA=.p7b",
          "signAlg": "SHA256withECDSA",
          "storeFile": "C:\\Users\\pugdudu\\.ohos\\config\\default_Linkora_sv3r0SeWGTnM86w19AGlL3mRoSIn_jQhwTzuJIJgWZA=.p12",
          "storePassword": "0000001BA3ABBB365D659DB161066A0464057988C27283209857C32C263F2157CB38142EAF4EAA4F55A93A"
        }
      }
    ],
"@
  $newContent = $content -replace '"signingConfigs"\s*:\s*\[\s*\],', $signingOverlay
  $newContent = $newContent -replace '("name"\s*:\s*"default",\r?\n)(\s*"buildOption")', "`$1        `"signingConfig`": `"default`",`n`$2"

  Set-Content -LiteralPath $buildProfile -Value $newContent -Encoding UTF8

  Push-Location $projectRoot
  try {
    Write-Host "Assembling signed debug HAP..."
    & $hvigor assembleHap --mode module -p module=entry@default -p product=default -p buildMode=debug --no-daemon
    if ($LASTEXITCODE -ne 0) {
      throw "assembleHap failed with exit code $LASTEXITCODE"
    }
  } finally {
    Pop-Location
  }

  $signedHap = Join-Path $projectRoot 'entry\build\default\outputs\default\entry-default-signed.hap'
  if (-not (Test-Path -LiteralPath $signedHap)) {
    throw "Signed HAP not found at expected location: $signedHap"
  }
  Write-Host "SUCCESS: Signed HAP ready at $signedHap"
} finally {
  if (Test-Path -LiteralPath $backup) {
    Copy-Item -LiteralPath $backup -Destination $buildProfile -Force
    Remove-Item -LiteralPath $backup -Force
    Write-Host "Cleaned up build-profile.json5 overlay."
  }
}
