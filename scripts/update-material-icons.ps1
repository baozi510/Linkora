param(
  [string]$PythonCommand = 'python'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$generator = Join-Path $PSScriptRoot 'material-icons/generate.py'

& $PythonCommand $generator --project-root $projectRoot
if ($LASTEXITCODE -ne 0) {
  throw "Material icon generation failed with exit code $LASTEXITCODE."
}
