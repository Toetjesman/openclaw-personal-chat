#define MyAppName "OpenClaw Personal Chat"
#define MyAppPublisher "OpenClaw"
#define MyAppExeName "OpenClawChat.cmd"
#ifndef MyAppVersion
#define MyAppVersion "0.1.1"
#endif
#ifndef SourceRoot
#define SourceRoot "..\..\"
#endif
#ifndef OutputDir
#define OutputDir "..\..\release"
#endif

[Setup]
AppId={{F6D67F6D-9E9A-4C05-A528-1B3863B62A63}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\OpenClawPersonalChat
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
UsePreviousAppDir=yes
UsePreviousTasks=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutputDir}
OutputBaseFilename=OpenClawPersonalChat-Setup-{#MyAppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayName={#MyAppName}
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: checkedonce
Name: "autostart"; Description: "Start OpenClaw Gateway when I sign in"; GroupDescription: "Startup:"; Flags: unchecked

[Files]
Source: "{#SourceRoot}\*"; DestDir: "{app}\repo"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: ".git\*,node_modules\*,ui\node_modules\*,.artifacts\*,.local-run\*,.vscode\*,dist-runtime\*,coverage\*,release\*,tmp\*,*.log,*.tgz,*.tar.gz,*.zip"
Source: "{#SourceRoot}\installer\windows\bin\OpenClawChat.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceRoot}\installer\windows\bin\StartOpenClawGateway.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceRoot}\installer\windows\scripts\*.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion

[Icons]
Name: "{group}\OpenClaw Chat"; Filename: "{app}\OpenClawChat.cmd"; WorkingDir: "{app}\repo"
Name: "{group}\Start OpenClaw Gateway"; Filename: "{app}\StartOpenClawGateway.cmd"; WorkingDir: "{app}\repo"
Name: "{commondesktop}\OpenClaw Chat"; Filename: "{app}\OpenClawChat.cmd"; WorkingDir: "{app}\repo"; Tasks: desktopicon

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\Setup-OpenClawPersonalChat.ps1"" -InstallRoot ""{app}"" -RepoRoot ""{app}\repo"" -CreateAutostart ""{code:GetAutostartFlag}"" -AppVersion ""{#MyAppVersion}"""; Flags: runhidden waituntilterminated
Filename: "{app}\OpenClawChat.cmd"; Description: "Open OpenClaw Chat"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\scripts\Remove-OpenClawPersonalChat.ps1"""; Flags: runhidden waituntilterminated

[Code]
function GetAutostartFlag(Param: String): String;
begin
  if WizardIsTaskSelected('autostart') then
    Result := 'true'
  else
    Result := 'false';
end;
