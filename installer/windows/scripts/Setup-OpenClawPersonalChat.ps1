param(
  [Parameter(Mandatory = $true)][string]$InstallRoot,
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [string]$CreateAutostart = "false"
)

$ErrorActionPreference = "Stop"

function Test-Command {
  param([string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Stop-OpenClawGatewayForUpgrade {
  try {
    $connections = Get-NetTCPConnection -LocalAddress "127.0.0.1" -LocalPort 18789 -State Listen -ErrorAction SilentlyContinue
    foreach ($connection in $connections) {
      if ($connection.OwningProcess) {
        Stop-Process -Id $connection.OwningProcess -Force -ErrorAction SilentlyContinue
      }
    }
    if ($connections) {
      Start-Sleep -Seconds 2
    }
  } catch {
    # Older Windows installs or restricted environments may not expose Get-NetTCPConnection.
  }
}

function Get-DesiredOpenClawVersion {
  $packageJsonPath = Join-Path $RepoRoot "package.json"
  if (-not (Test-Path $packageJsonPath)) {
    return $null
  }
  try {
    return ((Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json).version)
  } catch {
    return $null
  }
}

function Get-InstalledOpenClawVersion {
  $globalPackageJsonPath = Join-Path $env:APPDATA "npm\node_modules\openclaw\package.json"
  if (Test-Path $globalPackageJsonPath) {
    try {
      return ((Get-Content -LiteralPath $globalPackageJsonPath -Raw | ConvertFrom-Json).version)
    } catch {
      return $null
    }
  }
  if (-not (Test-Command "openclaw")) {
    return $null
  }
  try {
    $versionOutput = & openclaw --version 2>$null | Out-String
    if ($versionOutput -match "OpenClaw\s+([0-9]+\.[0-9]+\.[0-9]+)") {
      return $Matches[1]
    }
  } catch {
    return $null
  }
  return $null
}

$logDir = Join-Path $InstallRoot "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
Remove-Item -LiteralPath (Join-Path $logDir "setup-warning.txt") -ErrorAction SilentlyContinue

if (-not (Test-Command "node")) {
  Set-Content -Path (Join-Path $logDir "setup-warning.txt") -Value "Node.js is missing. Install Node.js 22.19+ before starting OpenClaw Personal Chat."
  exit 0
}

$statusPath = Join-Path $logDir "detected-openclaw.txt"
$existingOpenClawPath = $null
if (Test-Command "openclaw") {
  $existingOpenClawPath = (Get-Command "openclaw").Source
}

Stop-OpenClawGatewayForUpgrade

$desiredVersion = Get-DesiredOpenClawVersion
$installedVersion = Get-InstalledOpenClawVersion
$runtimeInstallSkipped = $false

$npmCommand = Get-Command "npm.cmd" -ErrorAction SilentlyContinue
if (-not $npmCommand) {
  $npmCommand = Get-Command "npm" -ErrorAction SilentlyContinue
}

if ($runtimeInstallSkipped) {
  Set-Content -Path (Join-Path $logDir "npm-install-openclaw.log") -Value "OpenClaw $installedVersion is already installed; runtime install skipped."
} elseif ($npmCommand) {
  try {
    $npmOutPath = Join-Path $logDir "npm-install-openclaw.log"
    $npmErrPath = Join-Path $logDir "npm-install-openclaw.err.log"
    $packOutPath = Join-Path $logDir "npm-pack-openclaw.log"
    $packErrPath = Join-Path $logDir "npm-pack-openclaw.err.log"
    $packProcess = Start-Process -FilePath $npmCommand.Source -ArgumentList @("pack", $RepoRoot, "--pack-destination", $logDir, "--ignore-scripts") -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $packOutPath -RedirectStandardError $packErrPath
    if ($packProcess.ExitCode -ne 0) {
      $errorText = if (Test-Path $packErrPath) { Get-Content -LiteralPath $packErrPath -Raw } else { "" }
      throw "npm pack exited with code $($packProcess.ExitCode). $errorText"
    }
    $tarball = Get-ChildItem -LiteralPath $logDir -Filter "openclaw-*.tgz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $tarball) {
      throw "npm pack completed but no openclaw tarball was found."
    }
    $npmProcess = Start-Process -FilePath $npmCommand.Source -ArgumentList @("install", "-g", "--force", "--", $tarball.FullName) -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $npmOutPath -RedirectStandardError $npmErrPath
    if ($npmProcess.ExitCode -ne 0) {
      $errorText = if (Test-Path $npmErrPath) { Get-Content -LiteralPath $npmErrPath -Raw } else { "" }
      throw "npm install exited with code $($npmProcess.ExitCode). $errorText"
    }
  } catch {
    $installedVersionAfterFailure = Get-InstalledOpenClawVersion
    if (-not ($desiredVersion -and $installedVersionAfterFailure -eq $desiredVersion)) {
      Set-Content -Path (Join-Path $logDir "setup-warning.txt") -Value "Could not install OpenClaw Personal Chat runtime: $($_.Exception.Message)"
    }
  }
} else {
  Set-Content -Path (Join-Path $logDir "setup-warning.txt") -Value "npm is missing. Install Node.js 22.19+ with npm before starting OpenClaw Personal Chat."
}

if (Test-Command "openclaw") {
  $openclawPath = (Get-Command "openclaw").Source
  $status = ""
  try {
    $status = & openclaw status --json 2>&1 | Out-String
  } catch {
    $status = "OpenClaw status is unavailable until the Gateway is started."
  }
  Set-Content -Path $statusPath -Value @(
    "OpenClaw command: $openclawPath"
    $(if ($existingOpenClawPath) { "Existing OpenClaw command before install: $existingOpenClawPath" } else { "No previous OpenClaw command was detected before install." })
    "Installed runtime source: $RepoRoot"
    "Existing OpenClaw config, auth profiles, tokens, and API keys are reused from the user's normal OpenClaw profile."
    "No API keys or secrets were written by this installer."
    ""
    $status
  )
} else {
  Set-Content -Path $statusPath -Value @(
    "OpenClaw command was not found after install."
    "No API keys or secrets were written by this installer."
    "Install Node.js/npm and rerun this installer."
  )
}

if ($CreateAutostart -eq "true") {
  $taskName = "OpenClaw Personal Chat Gateway"
  $cmdPath = Join-Path $InstallRoot "StartOpenClawGateway.cmd"
  $action = New-ScheduledTaskAction -Execute $cmdPath
  $trigger = New-ScheduledTaskTrigger -AtLogOn
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Starts the local OpenClaw Gateway for OpenClaw Personal Chat." -Force | Out-Null
}

exit 0
