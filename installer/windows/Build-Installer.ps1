param(
  [string]$Version = "0.1.4",
  [string]$OutputDir = (Join-Path (Resolve-Path ".").Path "release")
)

$ErrorActionPreference = "Stop"

function Resolve-Iscc {
  $cmd = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }
  $candidates = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
  )
  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }
  throw "Inno Setup 6 was not found. Install it from https://jrsoftware.org/isinfo.php and run this script again."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$iss = Join-Path $PSScriptRoot "OpenClawPersonalChat.iss"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

Push-Location $repoRoot
try {
  if (Get-Command "npm" -ErrorAction SilentlyContinue) {
    npm exec -- esbuild ui/src/ui/app-chat.ts --bundle --format=esm --platform=browser --outfile="$env:TEMP\openclaw-app-chat-check.mjs" --external:lit --external:@lit/* | Out-Host
  }
} finally {
  Pop-Location
}

$iscc = Resolve-Iscc
& $iscc "/DSourceRoot=$repoRoot" "/DOutputDir=$OutputDir" "/DMyAppVersion=$Version" $iss
