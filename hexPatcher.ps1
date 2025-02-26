Clear-Host

# Initialize global path for "Contents" folder
$global:ContentsPath = $null

# Function: Show MainMenu
function Show-MainMenu {
    Write-Host ""
    Write-Host "---------------------------------"
    Write-Host "1 - Set USB Path"
    Write-Host "2 - Set Custom Path"
    Write-Host "3 - Check HEX and Overwrite"
    Write-Host "0 - Exit"
    Write-Host "---------------------------------"
    Write-Host ""
}

# Function: Retry --> back to mainmenu or exit
function PromptRetry {
    $retry = Read-Host "`nPress 1 for MainMenu / 0 to Exit"
    if ($retry -eq "0") { Exit }
}

# Function: Option 1 – Find USB devices
function SetPathFromUSB {
    $usbDrives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    if (-not $usbDrives) {
        Write-Host "`nNo USB drives found" -ForegroundColor Red
        PromptRetry
        return
    }
    
    Write-Host ""
    Write-Host "Found USB drives:" -ForegroundColor Cyan
    $i = 1
    $driveMap = @{}
    foreach ($drive in $usbDrives) {
        Write-Host "$i - $($drive.DeviceID)"
        $driveMap[$i] = $drive.DeviceID
        $i++
    }
    Write-Host ""
    $choice = Read-Host "Select drive by entering the corresponding number"
    if ($driveMap.ContainsKey([int]$choice)) {
        $driveLetter = $driveMap[[int]$choice]
        $tempPath = "$driveLetter\Contents"
        if (Test-Path $tempPath) {
            # Check folder for content
            $items = Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue |
                     Where-Object { $_.Name -notin @("System Volume Information", "$RECYCLE.BIN") }
            if ($items) {
                $global:ContentsPath = $tempPath
                Write-Host "`nPath successfully set to: $global:ContentsPath" -ForegroundColor Green
            }
            else {
                Write-Host "`nFolder 'Contents' is empty" -ForegroundColor Red
            }
        }
        else {
            Write-Host "`nFolder 'Contents' does not exist on selected drive" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`nInvalid choice" -ForegroundColor Red
    }
    PromptRetry
}

# Function: Option 2 – Set custom path
function SetCustomPath {
    Write-Host ""
    $tempPath = Read-Host "Enter a path that ends with 'Contents' (example `"C:\Users\Name\Backup\Contents`")"
    if ($tempPath -notmatch "Contents$") {
        Write-Host "`nPath must end with 'Contents'" -ForegroundColor Red
    }
    elseif (Test-Path $tempPath) {
        $items = Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -notin @("System Volume Information", "$RECYCLE.BIN") }
        if ($items) {
            $global:ContentsPath = $tempPath
            Write-Host "`nPath successfully set to: $global:ContentsPath" -ForegroundColor Green
        }
        else {
            Write-Host "`nFolder is empty" -ForegroundColor Red
        }
    }
    else {
        Write-Host "`nSpecified path does not exist" -ForegroundColor Red
    }
    PromptRetry
}

# Function: Option 3 – Check Hex-Values and change if needed 
function CheckHex {
    if (-not $global:ContentsPath) {
        Write-Host "`nNo valid path found. First set path using 1/2 in menu." -ForegroundColor Red
        PromptRetry
        return
    }
    
    Write-Host "`nChecking WAV files in folder: $global:ContentsPath" -ForegroundColor Cyan
    $wavFiles = Get-ChildItem -Path $global:ContentsPath -Filter "*.wav" -Recurse -File
    if (-not $wavFiles) {
        Write-Host "`nNo WAV files found at specified path" -ForegroundColor Red
        PromptRetry
        return
    }
    
    $totalFiles = $wavFiles.Count
    $filesNotCorrect = 0

    foreach ($file in $wavFiles) {
        try {
            $fs = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
            $buffer = New-Object byte[] 2
            $fs.Read($buffer, 0, 2) | Out-Null
            $fs.Close()
            
            $hexString = ("{0:X2} {1:X2}" -f $buffer[0], $buffer[1])
            if ($hexString -eq "01 00") {
                Write-Host "$($file.FullName): $hexString" -ForegroundColor DarkGreen
            }
            else {
                Write-Host "$($file.FullName): $hexString" -ForegroundColor DarkYellow
                $filesNotCorrect++
            }
        }
        catch {
            Write-Host "Error reading file: $($file.FullName)" -ForegroundColor Red
        }
    }
    
    Write-Host "`nOverview:" -ForegroundColor Cyan
    Write-Host "Found WAV files: $totalFiles"
    Write-Host "Files not containing '01 00': $filesNotCorrect"
    
    if ($filesNotCorrect -gt 0) {
        $overwriteChoice = Read-Host "`nChange all files that dont contain '01 00' at 0x14 0x15? (Y/N)"
        if ($overwriteChoice -match "^[Yy]") {
            foreach ($file in $wavFiles) {
                try {
                    $fs = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)
                    $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
                    $buffer = New-Object byte[] 2
                    $fs.Read($buffer, 0, 2) | Out-Null
                    $currentHex = ("{0:X2} {1:X2}" -f $buffer[0], $buffer[1])
                    if ($currentHex -ne "01 00") {
                        $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
                        $newBytes = [byte[]](0x01, 0x00)
                        $fs.Write($newBytes, 0, 2)
                        Write-Host "Changed: $($file.FullName)" -ForegroundColor Green
                    }
                    $fs.Close()
                }
                catch {
                    Write-Host "Error changing file: $($file.FullName)" -ForegroundColor Red
                }
            }
            Write-Host "`nProcess complete!" -ForegroundColor Green
        }
    }
    else {
        Write-Host "`nAll files found already have been set to '01 00'" -ForegroundColor Green
    }
    
    PromptRetry
}

# Main Loop
while ($true) {
    Show-MainMenu
    $mainChoice = Read-Host "Your choice (0-3)"
    
    switch ($mainChoice) {
        "1" { SetPathFromUSB }
        "2" { SetCustomPath }
        "3" { CheckHex }
        "0" { Exit }
        default { Write-Host "`nInvalid choice" -ForegroundColor Red }
    }
}
