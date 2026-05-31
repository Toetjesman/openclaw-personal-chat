param(
  [string]$InstallRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"

function Test-Command {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Resolve-RepoRoot {
  param([string]$Root)
  $candidate = Join-Path $Root "repo"
  if (Test-Path (Join-Path $candidate "openclaw.mjs")) {
    return $candidate
  }
  return (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
}

function Test-GatewayListening {
  try {
    $response = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:18789/" -TimeoutSec 2
    return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500)
  } catch {
    return $false
  }
}

if (Test-GatewayListening) {
  exit 0
}

if (-not (Test-Command "node")) {
  Start-Process "https://nodejs.org/en/download"
  throw "Node.js 22.19+ is required before OpenClaw can run."
}

$repoRoot = Resolve-RepoRoot -Root $InstallRoot
$logDir = Join-Path $InstallRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$globalOpenClaw = Get-Command "openclaw" -ErrorAction SilentlyContinue
if ($globalOpenClaw) {
  Start-Process -FilePath "openclaw.cmd" -ArgumentList @("gateway") -WorkingDirectory $repoRoot -RedirectStandardOutput (Join-Path $logDir "gateway.out.log") -RedirectStandardError (Join-Path $logDir "gateway.err.log") -WindowStyle Hidden | Out-Null
  exit 0
}

Start-Process -FilePath "node.exe" -ArgumentList @((Join-Path $repoRoot "openclaw.mjs"), "gateway") -WorkingDirectory $repoRoot -RedirectStandardOutput (Join-Path $logDir "gateway.out.log") -RedirectStandardError (Join-Path $logDir "gateway.err.log") -WindowStyle Hidden | Out-Null
