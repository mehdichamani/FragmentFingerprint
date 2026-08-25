# Running in Startup (Hidden) - Help & Instructions

This guide provides built-in Windows methods to run `xray.exe` automatically on startup in the background (hidden), along with instructions on how to start, stop, and manage the process.

---

## Method 1: Task Scheduler (Recommended)

Uses Windows Task Scheduler to start `xray.exe` silently when you log into Windows.

### 1. Setup (Run Silently on Startup)
Run the following in **PowerShell**:

```powershell
$vbsPath = "C:\Users\Mehdi\projects\FragmentFingerprint\run_hidden.vbs"
$workDir = "C:\Users\Mehdi\projects\FragmentFingerprint"
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbsPath`"" -WorkingDirectory $workDir
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERNAME"
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
Register-ScheduledTask -TaskName "XrayFragment" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force
```

---

### 2. How to Start / Stop / Remove

- **Start manually:**
  ```powershell
  Start-ScheduledTask -TaskName "XrayFragment"
  ```

- **Stop running instance:**
  ```powershell
  Stop-ScheduledTask -TaskName "XrayFragment"
  # Or force kill:
  taskkill /F /IM xray.exe
  ```

- **Check if running:**
  ```powershell
  Get-Process -Name "xray" -ErrorAction SilentlyContinue
  ```

- **Disable / Remove from startup:**
  ```powershell
  Unregister-ScheduledTask -TaskName "XrayFragment" -Confirm:$false
  ```

---

## Method 2: VBScript + Windows Startup Folder

Uses a hidden VBScript runner placed directly in the Windows user startup folder.

### 1. Setup
1. Press `Win + R`, type `shell:startup`, and press **Enter** (this opens your Startup folder).
2. Create a file named `start_xray_hidden.vbs` inside that folder with this content:

```vbscript
Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\Mehdi\AppData\Local\Programs\fragment fingerprint"
WshShell.Run "xray.exe", 0, False
```
*(Note: `0` specifies hidden mode without any pop-up console window).*

---

### 2. How to Stop / Remove

- **Stop immediately:**
  Create a file called `stop_xray.bat` (e.g. on Desktop or in this folder) with:
  ```cmd
  taskkill /F /IM xray.exe
  ```
  Double-click it anytime to terminate the background process.

- **Disable from startup:**
  Delete or move `start_xray_hidden.vbs` out of the `shell:startup` folder.
