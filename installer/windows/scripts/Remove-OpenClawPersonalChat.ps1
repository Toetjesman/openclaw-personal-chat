$ErrorActionPreference = "SilentlyContinue"
Unregister-ScheduledTask -TaskName "OpenClaw Personal Chat Gateway" -Confirm:$false | Out-Null
