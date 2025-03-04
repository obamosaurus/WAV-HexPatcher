# Load required assemblies for Windows Forms, Drawing and VB InputBox support
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName Microsoft.VisualBasic

# Initialize global variable for the Contents folder path
$global:ContentsPath = $null

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "WAV File HEX Checker"
$form.Size = New-Object System.Drawing.Size(1300,600)
$form.StartPosition = "CenterScreen"

# Create buttons on the left side
$btnSetUSB = New-Object System.Windows.Forms.Button
$btnSetUSB.Location = New-Object System.Drawing.Point(20,20)
$btnSetUSB.Size = New-Object System.Drawing.Size(150,30)
$btnSetUSB.Text = "Set USB Path"

$btnSetCustom = New-Object System.Windows.Forms.Button
$btnSetCustom.Location = New-Object System.Drawing.Point(200,20)
$btnSetCustom.Size = New-Object System.Drawing.Size(150,30)
$btnSetCustom.Text = "Set Custom Path"

$btnCheckHex = New-Object System.Windows.Forms.Button
$btnCheckHex.Location = New-Object System.Drawing.Point(380,20)
$btnCheckHex.Size = New-Object System.Drawing.Size(150,30)
$btnCheckHex.Text = "Check HEX"

$btnFixData = New-Object System.Windows.Forms.Button
$btnFixData.Location = New-Object System.Drawing.Point(560,20)
$btnFixData.Size = New-Object System.Drawing.Size(150,30)
$btnFixData.Text = "Fix Data"

# Create buttons on the right side
# Calculate positions assuming form width is ~1300px
$btnClearConsole = New-Object System.Windows.Forms.Button
$btnClearConsole.Location = New-Object System.Drawing.Point(970,20)
$btnClearConsole.Size = New-Object System.Drawing.Size(150,30)
$btnClearConsole.Text = "Clear Console"

$btnHelp = New-Object System.Windows.Forms.Button
$btnHelp.Location = New-Object System.Drawing.Point(1130,20)
$btnHelp.Size = New-Object System.Drawing.Size(150,30)
$btnHelp.Text = "Help"

# Create a RichTextBox for logging output
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(20,80)
$logBox.Size = New-Object System.Drawing.Size(1240,480)
$logBox.ReadOnly = $true
$logBox.Font = New-Object System.Drawing.Font("Consolas",10)

# Helper function for colored log output
function Write-LogColor {
    param(
        [string]$msg,
        [System.Drawing.Color]$color = [System.Drawing.Color]::Black
    )
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor = $color
    $logBox.AppendText($msg + [Environment]::NewLine)
    $logBox.SelectionColor = $logBox.ForeColor
    $logBox.ScrollToCaret()
}

# Function: Set USB Path via GUI
function SetPathFromUSB_GUI {
    Write-LogColor ">> Searching for USB drives..." ([System.Drawing.Color]::Blue)
    $usbDrives = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 2 }
    if (-not $usbDrives) {
        [System.Windows.Forms.MessageBox]::Show("No USB drives found.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    # Create a new form for USB drive selection
    $formUSB = New-Object System.Windows.Forms.Form
    $formUSB.Text = "Select USB Drive"
    $formUSB.Size = New-Object System.Drawing.Size(300,200)
    $formUSB.StartPosition = "CenterParent"
    
    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(20,20)
    $listBox.Size = New-Object System.Drawing.Size(240,80)
    
    $driveMap = @{}
    $i = 1
    foreach ($drive in $usbDrives) {
        $displayText = "$i - $($drive.DeviceID)"
        $listBox.Items.Add($displayText)
        $driveMap[$i] = $drive.DeviceID
        $i++
    }
    
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Location = New-Object System.Drawing.Point(20,120)
    $btnOK.Size = New-Object System.Drawing.Size(80,30)
    $btnOK.Text = "OK"
    $btnOK.Add_Click({
        if ($listBox.SelectedIndex -ge 0) {
            $selected = $listBox.SelectedItem
            if ($selected -match "^(\d+)\s-\s(.+)$") {
                $index = [int]$matches[1]
                $driveLetter = $driveMap[$index]
                $tempPath = "$driveLetter\Contents"
                if (Test-Path $tempPath) {
                    $items = Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue |
                             Where-Object { $_.Name -notin @("System Volume Information", "$RECYCLE.BIN") }
                    if ($items) {
                        $global:ContentsPath = $tempPath
                        Write-LogColor ">> Path set to: $global:ContentsPath" ([System.Drawing.Color]::Green)
                    }
                    else {
                        [System.Windows.Forms.MessageBox]::Show("Folder 'Contents' is empty.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
                    }
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show("Folder 'Contents' does not exist on the selected drive.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            $formUSB.Close()
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Please select a drive.","Warning",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    })
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Location = New-Object System.Drawing.Point(180,120)
    $btnCancel.Size = New-Object System.Drawing.Size(80,30)
    $btnCancel.Text = "Cancel"
    $btnCancel.Add_Click({ $formUSB.Close() })
    
    $formUSB.Controls.Add($listBox)
    $formUSB.Controls.Add($btnOK)
    $formUSB.Controls.Add($btnCancel)
    $formUSB.ShowDialog() | Out-Null
}

# Function: Set a custom path via GUI
function SetCustomPath_GUI {
    $tempPath = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a path that ends with 'Contents' (e.g. C:\Users\Name\Backup\Contents)", "Set Custom Path", "")
    if ([string]::IsNullOrWhiteSpace($tempPath)) {
        return
    }
    if ($tempPath -notmatch "Contents$") {
        [System.Windows.Forms.MessageBox]::Show("Path must end with 'Contents'.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    if (Test-Path $tempPath) {
        $items = Get-ChildItem -Path $tempPath -Force -ErrorAction SilentlyContinue |
                 Where-Object { $_.Name -notin @("System Volume Information", "$RECYCLE.BIN") }
        if ($items) {
            $global:ContentsPath = $tempPath
            Write-LogColor ">> Path set to: $global:ContentsPath" ([System.Drawing.Color]::Green)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("Folder is empty.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Specified path does not exist.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# Function: Check HEX in WAV files (no overwrite)
function CheckHex_GUI {
    if (-not $global:ContentsPath) {
        [System.Windows.Forms.MessageBox]::Show("No valid path found. Please set a path using 'Set USB Path' or 'Set Custom Path'.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    Write-LogColor ">> Starting HEX check in folder: $global:ContentsPath" ([System.Drawing.Color]::Blue)
    $wavFiles = Get-ChildItem -Path $global:ContentsPath -Filter "*.wav" -Recurse -File
    if (-not $wavFiles) {
        [System.Windows.Forms.MessageBox]::Show("No WAV files found at the specified path.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
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
                Write-LogColor "File: $($file.FullName)" ([System.Drawing.Color]::DarkGreen)
                Write-LogColor "    HEX @0x14/0x15: [$hexString]" ([System.Drawing.Color]::DarkGreen)
            }
            else {
                Write-LogColor "File: $($file.FullName)" ([System.Drawing.Color]::DarkOrange)
                Write-LogColor "    HEX @0x14/0x15: [$hexString]  <-- needs update" ([System.Drawing.Color]::DarkOrange)
                $filesNotCorrect++
            }
        }
        catch {
            Write-LogColor "Error reading file: $($file.FullName)" ([System.Drawing.Color]::Red)
        }
    }
    
    Write-LogColor "----------------------------------------" ([System.Drawing.Color]::Blue)
    Write-LogColor "Total WAV files found: $totalFiles" ([System.Drawing.Color]::Blue)
    Write-LogColor "Files needing update : $filesNotCorrect" ([System.Drawing.Color]::Blue)
    
    if ($filesNotCorrect -eq 0) {
        Write-LogColor "No Actions Needed" ([System.Drawing.Color]::Green)
    }
}

# Function: Fix HEX in WAV files that don't contain '01 00'
function OverwriteHex_GUI {
    if (-not $global:ContentsPath) {
        [System.Windows.Forms.MessageBox]::Show("No valid path found. Please set a path using 'Set USB Path' or 'Set Custom Path'.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    Write-LogColor ">> Preparing to fix files in folder: $global:ContentsPath" ([System.Drawing.Color]::Blue)
    $wavFiles = Get-ChildItem -Path $global:ContentsPath -Filter "*.wav" -Recurse -File
    if (-not $wavFiles) {
        [System.Windows.Forms.MessageBox]::Show("No WAV files found at the specified path.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    $filesToOverwrite = @()
    foreach ($file in $wavFiles) {
        try {
            $fs = [System.IO.File]::Open($file.FullName, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
            $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
            $buffer = New-Object byte[] 2
            $fs.Read($buffer, 0, 2) | Out-Null
            $fs.Close()
            
            $hexString = ("{0:X2} {1:X2}" -f $buffer[0], $buffer[1])
            if ($hexString -ne "01 00") {
                $filesToOverwrite += $file
            }
        }
        catch {
            Write-LogColor "Error reading file: $($file.FullName)" ([System.Drawing.Color]::Red)
        }
    }
    
    if ($filesToOverwrite.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("All files already have '01 00' set.","Information",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show("There are $($filesToOverwrite.Count) files that will be fixed. Proceed?","Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        foreach ($file in $filesToOverwrite) {
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
                    Write-LogColor "Fixed file: $($file.FullName)" ([System.Drawing.Color]::Green)
                }
                $fs.Close()
            }
            catch {
                Write-LogColor "Error fixing file: $($file.FullName)" ([System.Drawing.Color]::Red)
            }
        }
        Write-LogColor ">> Fix process complete!" ([System.Drawing.Color]::Green)
    }
}

# Help button event handler: show instructions in a message box.
$btnHelp.Add_Click({
    $helpMessage = "Steps to use this tool:" + [Environment]::NewLine + [Environment]::NewLine +
                   "1. Set a path:" + [Environment]::NewLine +
                   "   - Use 'Set USB Path' to choose your RekordBox USB-drive with your playlists inside." + [Environment]::NewLine +
                   "   - Or use 'Set Custom Path' to enter a full path ending with 'Contents'. (As in example)" + [Environment]::NewLine + [Environment]::NewLine +
                   "2. Perform a HEX check:" + [Environment]::NewLine +
                   "   - Click 'Check HEX' to display all files and wich need to be changed." + [Environment]::NewLine + [Environment]::NewLine +
                   "3. Fix data if needed:" + [Environment]::NewLine +
                   "   - Click 'Fix Data' to update all files that are incorrectly formatted." 
    [System.Windows.Forms.MessageBox]::Show($helpMessage,"Help", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

# Attach event handlers to other buttons
$btnSetUSB.Add_Click({ SetPathFromUSB_GUI })
$btnSetCustom.Add_Click({ SetCustomPath_GUI })
$btnCheckHex.Add_Click({ CheckHex_GUI })
$btnFixData.Add_Click({ OverwriteHex_GUI })
$btnClearConsole.Add_Click({ $logBox.Clear() })

# Controls to the main form
$form.Controls.Add($btnSetUSB)
$form.Controls.Add($btnSetCustom)
$form.Controls.Add($btnCheckHex)
$form.Controls.Add($btnFixData)
$form.Controls.Add($btnClearConsole)
$form.Controls.Add($btnHelp)
$form.Controls.Add($logBox)

# Display the form
[void]$form.ShowDialog()
