# Windows Hypervisor Prep Tool

This script is designed to prepare Windows 11 Pro/Enterprise for running specific game repacks that require a custom hypervisor environment. It automates the activation of Hyper-V and the deactivation of security features that usually block these cracks.

### What it does:
- Checks for administrative privileges (required for system changes).
- Verifies if the OS is Pro or Enterprise edition.
- Enables all Hyper-V related components using DISM and PowerShell.
- Disables VBS (Virtualization-Based Security) and HVCI (Memory Integrity) via Registry.
- Configures the hypervisor to launch automatically on boot.

### Usage:
1. Download the `Denuvo_HyperV_Setup.bat` file.
2. Right-click the file and select "Run as administrator".
3. Follow the on-screen instructions.
4. Restart your PC when prompted.

### Requirements:
- Windows 11 Pro, Enterprise, or Education (Home edition is not supported).
- SVM Mode (for AMD CPUs) or VT-x (for Intel CPUs) must be enabled in BIOS.
- Administrative access.

### Important Notes:
This script modifies system registry keys and boot configuration. Use it only if you understand why you need to disable VBS/HVCI. Disabling these features reduces the system's protection against certain types of malware, but is often necessary for specific software compatibility.

Tested on: Windows 11 Pro (Insider Build 26200), AMD Ryzen AI series.
