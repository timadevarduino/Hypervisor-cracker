@echo off
chcp 65001 >nul
title Hyper-V Enabler & VBS Fixer
setlocal enabledelayedexpansion

set "LOGFILE=%TEMP%\HyperV_Fix.log"
echo [%DATE% %TIME%] Script started. > "%LOGFILE%"

:: Check for Administrator privileges
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo [+] Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%~dp0"

cls
echo ======================================================
echo       Hyper-V Enabler & VBS Disabler Tool
echo ======================================================
echo Log file: %LOGFILE%
echo.

:: Check architecture (x64 required)
echo [*] Checking system architecture...
reg Query "HKLM\Hardware\Description\System\CentralProcessor\0" | find /i "x86" > Nul && (
    echo [!] ERROR: 64-bit ^(x64^) system is required!
    pause
    exit /b
)
echo [OK] Architecture: x64.
echo.

:: Check Windows Edition and install packages if Home
echo [*] Checking Windows edition...
systeminfo | findstr /B /C:"OS Name" > "%temp%\os_info.txt"
findstr /i "Home" "%temp%\os_info.txt" >nul
if %errorLevel% equ 0 (
    echo [!] Windows Home edition detected. Installing Hyper-V packages...
    for /f %%f in ('dir /b /s "%SystemRoot%\servicing\Packages\*Hyper-V*.mum" 2^>nul') do (
        dism /online /norestart /add-package:"%%f" >> "%LOGFILE%" 2>&1
    )
    for /f %%f in ('dir /b /s "%SystemRoot%\servicing\Packages\*Containers*.mum" 2^>nul') do (
        dism /online /norestart /add-package:"%%f" >> "%LOGFILE%" 2>&1
    )
    echo [OK] Packages installed for Windows Home.
) else (
    echo [OK] Standard edition detected (Pro/Enterprise).
)
del "%temp%\os_info.txt" >nul 2>&1

:: Enable Hyper-V and related features
echo.
echo [*] Enabling Hyper-V and virtualization features...
set FEATURES=Microsoft-Windows-Hyper-V-All Microsoft-Windows-Hyper-V Microsoft-Windows-Hyper-V-Tools-All Microsoft-Windows-Hyper-V-Management-PowerShell VirtualMachinePlatform Containers Microsoft-Windows-Subsystem-Linux

for %%F in (%FEATURES%) do (
    echo [+] Enabling: %%F
    dism /online /enable-feature /featurename:%%F /all /limitaccess /norestart >> "%LOGFILE%" 2>&1
)
echo [OK] Features processed.

:: Disable VBS, HVCI, and Core Isolation
echo.
echo [*] Disabling VBS, HVCI and Core Isolation...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "HVCIMsiLocked" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v "RequirePlatformSecurityFeatures" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPL" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "RunAsPPLBoot" /t REG_DWORD /d 0 /f >> "%LOGFILE%" 2>&1
echo [OK] Security policies updated.

:: Configure BCD and services
echo.
echo [*] Configuring BCD and system services...
bcdedit /set hypervisorlaunchtype auto >> "%LOGFILE%" 2>&1
bcdedit /set nx OptIn >> "%LOGFILE%" 2>&1

sc config vmms start= auto >> "%LOGFILE%" 2>&1
sc config vmcompute start= auto >> "%LOGFILE%" 2>&1
sc config HvHost start= auto >> "%LOGFILE%" 2>&1
sc config vmbusstart start= system >> "%LOGFILE%" 2>&1
echo [OK] Services configured.

:: Hardware virtualization check
echo.
echo [*] Hardware virtualization status:
echo -----------------------------------------------------
systeminfo | findstr /C:"Virtualization Enabled In Firmware:"
systeminfo | findstr /C:"Hyper-V Requirements:"
echo -----------------------------------------------------

echo ======================================================
echo                  COMPLETED SUCCESSFULLY
echo ======================================================
echo [!] A system RESTART is required to apply changes!
echo [!] Make sure virtualization ^(SVM / VT-x^) is enabled in BIOS.
echo ======================================================
echo.

set /p choice="Restart PC now? (y/n): "
if /i "%choice%"=="y" (
    echo Restarting in 10 seconds...
    shutdown /r /t 10
) else (
    echo Please restart your computer manually.
    pause
)
