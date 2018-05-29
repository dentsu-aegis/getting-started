@setlocal enableextensions
@cd /d "%~dp0"
PowerShell.exe -ExecutionPolicy UnRestricted -File .\scripts\dev_environment_windows_base.ps1 %1
Pause