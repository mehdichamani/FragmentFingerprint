<#
.SYNOPSIS
    Interactive TUI script for managing Xray Fragment Fingerprint.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$XrayExe = Join-Path $ScriptDir "xray.exe"
$ConfigFile = Join-Path $ScriptDir "config.json"
$VbsPath = Join-Path $ScriptDir "run_hidden.vbs"
$TaskName = "XrayFragment"

function Show-Header {
    Clear-Host
    $statusText = "STOPPED"
    $statusColor = "DarkGray"
    
    $procs = Get-Process -Name "xray" -ErrorAction SilentlyContinue
    if ($procs) {
        $count = $procs.Count
        $pids = ($procs | ForEach-Object { $_.Id }) -join ", "
        $statusText = "RUNNING ($count process(es), PID: $pids)"
        $statusColor = "Green"
    }

    $taskScheduled = "NO"
    $taskColor = "DarkGray"
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) {
        $taskScheduled = "YES (" + $task.State + ")"
        $taskColor = "Cyan"
    }

    $version = "Unknown"
    if (Test-Path $XrayExe) {
        try {
            $verOutput = & $XrayExe version 2>$null
            if ($verOutput -match "Xray (\S+)") {
                $version = $matches[1]
            }
        } catch {}
    }

    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                XRAY FRAGMENT FINGERPRINT MANAGER               " -ForegroundColor Yellow -BackgroundColor Black
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " Working Dir    : $ScriptDir" -ForegroundColor Gray
    Write-Host " Xray Version   : $version" -ForegroundColor Gray
    Write-Host -NoNewline " Status         : "
    Write-Host "$statusText" -ForegroundColor $statusColor
    Write-Host -NoNewline " Task Scheduler : "
    Write-Host "$taskScheduled" -ForegroundColor $taskColor
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Start-TerminalInstance {
    Show-Header
    Write-Host "[1] STARTING XRAY IN THIS TERMINAL..." -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop Xray and return to menu." -ForegroundColor DarkGray
    Write-Host "----------------------------------------------------------------" -ForegroundColor Gray
    
    if (-not (Test-Path $XrayExe)) {
        Write-Host "Error: xray.exe not found at $XrayExe" -ForegroundColor Red
        Pause-Menu
        return
    }

    # Check if config exists
    if (Test-Path $ConfigFile) {
        & $XrayExe run -c $ConfigFile
    } else {
        & $XrayExe run
    }
    
    Write-Host ""
    Write-Host "Xray stopped." -ForegroundColor Yellow
    Pause-Menu
}

function Add-ToTaskScheduler {
    Show-Header
    Write-Host "[2] ADDING TO TASK SCHEDULER (Startup on Logon)..." -ForegroundColor Yellow
    Write-Host ""

    # Ensure run_hidden.vbs exists
    $vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "$ScriptDir"
WshShell.Run """$XrayExe""", 0, False
"@
    Set-Content -Path $VbsPath -Value $vbsContent -Encoding ASCII
    Write-Host "[✓] Verified $VbsPath" -ForegroundColor Green

    try {
        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$VbsPath`"" -WorkingDirectory $ScriptDir
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERNAME"
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit 0
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
        
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        
        Write-Host "[✓] Task '$TaskName' registered successfully!" -ForegroundColor Green
        Write-Host "    It will automatically start silently every time you log in." -ForegroundColor Gray
        
        $ans = Read-Host "Would you like to start the background task now? (Y/n)"
        if ($ans -eq "" -or $ans -match "^[Yy]") {
            Start-ScheduledTask -TaskName $TaskName
            Start-Sleep -Seconds 1
            Write-Host "[✓] Task started." -ForegroundColor Green
        }
    } catch {
        Write-Host "[X] Failed to register task: $_" -ForegroundColor Red
    }
    
    Pause-Menu
}

function Remove-FromTaskScheduler {
    Show-Header
    Write-Host "[3] REMOVING FROM TASK SCHEDULER..." -ForegroundColor Yellow
    Write-Host ""

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "Task '$TaskName' is not registered in Task Scheduler." -ForegroundColor DarkYellow
    } else {
        try {
            Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "[✓] Task '$TaskName' unregistered successfully." -ForegroundColor Green
        } catch {
            Write-Host "[X] Error removing task: $_" -ForegroundColor Red
        }
    }

    Pause-Menu
}

function Download-LatestXray {
    Show-Header
    Write-Host "[4] DOWNLOADING LATEST XRAY-CORE FROM GITHUB..." -ForegroundColor Yellow
    Write-Host ""

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

    # Check if proxy is needed / available
    $apiUrl = "https://api.github.com/repos/XTLS/Xray-core/releases/latest"
    Write-Host "Fetching latest release metadata from $apiUrl..." -ForegroundColor Gray

    try {
        $headers = @{
            "User-Agent" = "PowerShell-Xray-Updater"
        }
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 15
        $tagName = $release.tag_name
        Write-Host "[✓] Latest version detected: $tagName" -ForegroundColor Green

        # Look for Windows 64-bit release
        $asset = $release.assets | Where-Object { $_.name -like "Xray-windows-64.zip" }
        if (-not $asset) {
            $asset = $release.assets | Where-Object { $_.name -like "*windows*64*.zip" } | Select-Object -First 1
        }

        if (-not $asset) {
            Write-Host "[X] Could not find 64-bit Windows ZIP archive in release assets." -ForegroundColor Red
            Pause-Menu
            return
        }

        $downloadUrl = $asset.browser_download_url
        $zipFile = Join-Path $ScriptDir "xray_update_temp.zip"
        $extractDir = Join-Path $ScriptDir "xray_update_temp"

        Write-Host "Downloading $($asset.name) ($([math]::Round($asset.size/1MB, 2)) MB)..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

        Write-Host "Extracting files..." -ForegroundColor Gray
        if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
        Expand-Archive -Path $zipFile -DestinationPath $extractDir -Force

        # Stop any running xray process before replacing
        $procs = Get-Process -Name "xray" -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Host "Stopping running Xray process before replacing binary..." -ForegroundColor DarkYellow
            taskkill /F /IM xray.exe 2>$null | Out-Null
            Start-Sleep -Seconds 1
        }

        # Backup old xray.exe
        if (Test-Path $XrayExe) {
            $backup = Join-Path $ScriptDir "xray.exe.bak"
            Copy-Item -Path $XrayExe -Destination $backup -Force
            Write-Host "[✓] Created backup at xray.exe.bak" -ForegroundColor DarkGray
        }

        # Copy new xray.exe and dat files
        $updatedFiles = @("xray.exe", "geoip.dat", "geosite.dat")
        foreach ($file in $updatedFiles) {
            $sourceFile = Join-Path $extractDir $file
            if (Test-Path $sourceFile) {
                Copy-Item -Path $sourceFile -Destination $ScriptDir -Force
                Write-Host "[✓] Updated $file" -ForegroundColor Green
            }
        }

        # Cleanup
        Remove-Item $zipFile -Force -ErrorAction SilentlyContinue
        Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host ""
        Write-Host "[✓] Xray successfully updated to $tagName!" -ForegroundColor Green
    } catch {
        Write-Host "[X] Error downloading/updating Xray: $_" -ForegroundColor Red
        Write-Host "Note: If GitHub API has rate limits or network issues, ensure your proxy or connection is accessible." -ForegroundColor Gray
    }

    Pause-Menu
}

function Stop-Processes {
    Show-Header
    Write-Host "[5] STOPPING XRAY PROCESSES..." -ForegroundColor Yellow
    Write-Host ""

    $procs = Get-Process -Name "xray" -ErrorAction SilentlyContinue
    if (-not $procs) {
        Write-Host "No running xray.exe instances found." -ForegroundColor DarkYellow
    } else {
        $count = $procs.Count
        taskkill /F /IM xray.exe
        Start-Sleep -Seconds 1
        Write-Host "[✓] Stopped $count xray instance(s)." -ForegroundColor Green
    }

    Pause-Menu
}

function Pause-Menu {
    Write-Host ""
    Write-Host "Press any key to return to menu..." -ForegroundColor DarkGray
    [void][System.Console]::ReadKey($true)
}

# Main Loop
while ($true) {
    Show-Header
    Write-Host "Please select an option:" -ForegroundColor White
    Write-Host "  [1] Start Xray in this terminal (Foreground)" -ForegroundColor Cyan
    Write-Host "  [2] Add to Task Scheduler (Auto-start on Windows login)" -ForegroundColor Green
    Write-Host "  [3] Remove from Task Scheduler" -ForegroundColor Yellow
    Write-Host "  [4] Download / Update latest Xray-core from GitHub" -ForegroundColor Magenta
    Write-Host "  [5] Stop all running Xray instances" -ForegroundColor Red
    Write-Host "  [0] Exit" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "Enter option [0-5]"
    switch ($choice) {
        "1" { Start-TerminalInstance }
        "2" { Add-ToTaskScheduler }
        "3" { Remove-FromTaskScheduler }
        "4" { Download-LatestXray }
        "5" { Stop-Processes }
        "0" { 
            Clear-Host
            exit 
        }
        default { 
            Write-Host "Invalid choice, please select 0 to 5." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
