# Windows installer

This folder contains the Windows packaging path for OpenClaw Personal Chat.

## Build prerequisites

- Windows 10/11
- Node.js 22.19+
- Inno Setup 6, including `ISCC.exe`

## Build

From the repository root:

```powershell
  powershell -ExecutionPolicy Bypass -File .\installer\windows\Build-Installer.ps1 -Version 0.1.1
```

The installer is written to:

```text
release\OpenClawPersonalChat-Setup-0.1.1.exe
```

## What the installer does

- Installs this repository into `%LOCALAPPDATA%\OpenClawPersonalChat\repo`.
- Reuses the same Inno Setup `AppId`, so running a newer installer updates the existing OpenClaw Personal Chat install instead of creating a second app.
- Reuses the previous install directory and selected tasks when Windows/Inno has a previous install record.
- Stops the local OpenClaw Gateway before updating files and restarts it when the launcher opens.
- Creates Start Menu shortcuts.
- Optionally creates a desktop shortcut.
- Optionally creates a logon scheduled task for the local OpenClaw Gateway.
- Detects an existing local `openclaw` command and reuses its current config, auth profiles, API keys, sessions, and Gateway token.
- Installs the bundled OpenClaw runtime tarball with `npm install -g --force`, so same-version UI/runtime fixes still replace the old local runtime.
- Writes `install-info.json` and setup logs under `%LOCALAPPDATA%\OpenClawPersonalChat` to record whether the run was an upgrade or a fresh install.

The installer does not include or write DeepSeek API keys, OpenClaw tokens, or other secrets. Existing OpenClaw credentials are auto-detected and reused.

## User flow

1. Run `OpenClawPersonalChat-Setup-<version>.exe`.
2. Click the desktop shortcut `OpenClaw Chat`.
3. The launcher detects the existing OpenClaw install and opens its dashboard URL with the local token.
4. Use the local chat UI at `http://127.0.0.1:18789/`.
