@echo off
:: ======================================================
::  Denuvo Hypervisor Prep Tool
::  Description: Enables Hyper-V and Disables VBS/HVCI
::  Author: Your GitHub Username
:: ======================================================

setlocal enabledelayedexpansion

:: 0. Check for Admin Rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] ERROR: Administrative privileges required.
    echo [!] Please right-click and "Run as administrator".
    pause
    exit /b
)

echo ======================================================
echo    WINDOWS PREPARATION FOR HYPERVISOR CRACKS
echo ======================================================

:: 1. Check Windows Edition (Requires Pro/Enterprise)
systeminfo | findstr /B /C:"OS Name" | findstr "Pro Enterprise" >nul
if %errorLevel% neq 0 (
    echo [!] WARNING: This script is intended for Pro/Enterprise editions.
    echo [!] Some features might not work on Home edition.
)

:: 2. Enable Hyper-V Features
echo [*] Checking Hyper-V status...
dism /online /get-features /format:table | findstr "Microsoft-Windows-Hyper-V" | findstr "Enabled" >nul
if %errorLevel% neq 0 (
    echo [!] Hyper-V is DISABLED. Activating...
    dism /online /enable-feature /featurename:Microsoft-Windows-Hyper-V -All /norestart
) else (
    echo [OK] Hyper-V is already active.
)

:: 3. Disable VBS / Memory Integrity (HVCI)
echo [*] Checking VBS/HVCI status...
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2>nul | findstr "0x1" >nul
if %errorLevel% equ 0 (
    echo [!] VBS/HVCI is ENABLED. Disabling for game compatibility...
    
    :: Registry tweaks to kill VBS
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v "LsaCfgFlags" /t REG_DWORD /d 0 /f >nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v "EnableVirtualizationBasedSecurity" /t REG_DWORD /d 0 /f >nul
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v "Enabled" /t REG_DWORD /d 0 /f >nul
    
    :: Set Hypervisor launch type
    bcdedit /set hypervisorlaunchtype auto >nul
) else (
    echo [OK] VBS/HVCI is already disabled.
)

echo ======================================================
echo    PROCESS COMPLETED
echo ======================================================
echo [!] Ensure "SVM Mode" (AMD) or "VT-x" (Intel) is ENABLED in BIOS.
echo [!] A system RESTART is required to apply changes.
echo ======================================================

set /p choice="Would you like to restart your PC now? (y/n): "
if /i "%choice%"=="y" (
    echo Restarting in 10 seconds...
    shutdown /r /t 10
) else (
    echo Please remember to restart manually.
    pause
)