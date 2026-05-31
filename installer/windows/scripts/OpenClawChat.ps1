param(
  [string]$InstallRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms

function Resolve-RepoRoot {
  param([string]$Root)
  $candidate = Join-Path $Root "repo"
  if (Test-Path (Join-Path $candidate "openclaw.mjs")) {
    return $candidate
  }
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
}

function Wait-ForGateway {
  $deadline = (Get-Date).AddSeconds(35)
  do {
    try {
      $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:18789/" -TimeoutSec 2
      if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
        return $true
      }
    } catch {
      Start-Sleep -Milliseconds 700
    }
  } while ((Get-Date) -lt $deadline)
  return $false
}

$repoRoot = Resolve-RepoRoot -Root $InstallRoot
$startScript = Join-Path $PSScriptRoot "Start-OpenClawGateway.ps1"
& $startScript -InstallRoot $InstallRoot | Out-Null

if (-not (Wait-ForGateway)) {
  [System.Windows.Forms.MessageBox]::Show(
    "OpenClaw Gateway kon niet worden gestart. Open 'Start OpenClaw Gateway' of run 'openclaw doctor'.",
    "OpenClaw Chat",
    "OK",
    "Warning"
  ) | Out-Null
  exit 1
}

$dashboardOutput = ""
try {
  Push-Location $repoRoot
  if (Get-Command "openclaw" -ErrorAction SilentlyContinue) {
    $dashboardOutput = & openclaw dashboard --no-open 2>&1 | Out-String
  } else {
    $dashboardOutput = & node (Join-Path $repoRoot "openclaw.mjs") dashboard --no-open 2>&1 | Out-String
  }
} finally {
  Pop-Location
}

$urlMatch = [regex]::Match($dashboardOutput, "https?://127\.0\.0\.1:18789/[^\s]+")
if ($urlMatch.Success) {
  Start-Process $urlMatch.Value
  exit 0
}

Start-Process "http://127.0.0.1:18789/chat"
