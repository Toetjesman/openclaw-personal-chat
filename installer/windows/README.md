# Windows installer

This folder contains the Windows packaging path for OpenClaw Personal Chat.

## Build prerequisites

- Windows 10/11
- Node.js 22.19+
- Inno Setup 6, including `ISCC.exe`

## Build

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\installer\windows\Build-Installer.ps1 -Version 0.1.0
```

The installer is written to:

```text
release\OpenClawPersonalChat-Setup-0.1.0.exe
```

## What the installer does

- Installs this repository into `%LOCALAPPDATA%\OpenClawPersonalChat\repo`.
- Creates Start Menu shortcuts.
- Optionally creates a desktop shortcut.
- Optionally creates a logon scheduled task for the local OpenClaw Gateway.
- Detects an existing local `openclaw` command and reuses its current config, auth profiles, API keys, sessions, and Gateway token.
- If OpenClaw is missing, attempts `npm install -g openclaw`; the user still completes normal OpenClaw onboarding for API keys on that laptop.

The installer does not include or write DeepSeek API keys, OpenClaw tokens, or other secrets. Existing OpenClaw credentials are auto-detected and reused.

## User flow

1. Run `OpenClawPersonalChat-Setup-<version>.exe`.
2. Click the desktop shortcut `OpenClaw Chat`.
3. The launcher detects the existing OpenClaw install and opens its dashboard URL with the local token.
4. Use the local chat UI at `http://127.0.0.1:18789/`.
