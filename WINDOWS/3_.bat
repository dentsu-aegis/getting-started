@setlocal enableextensions
@cd /d "%~dp0"
@echo off
set mypath="%~dp0"
bash /mnt/c/Users/%USERNAME%/src/getting-started/WINDOWS/scripts/Linux.1.wsl.sh %1
bash /mnt/c/Users/%USERNAME%/src/getting-started/WINDOWS/scripts/Linux.2.wsl.sh %USERNAME% %1
Pause