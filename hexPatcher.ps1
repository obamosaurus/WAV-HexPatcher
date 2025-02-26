# Set USB target path (Example: F:\Contents)
$FolderPath = "yourUSB:\Contents"

# Get all WAV files in the target folder and subdirectories
$wavFiles = Get-ChildItem -Path $FolderPath -Filter "*.wav" -Recurse -File

foreach ($wavFile in $wavFiles) {
    $Path = $wavFile.FullName

    # Open the file with read/write access
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)

    # move file pointer (seek) to offset (0x14 = 20, 0x15 = 21)
    $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null

    # Read the current two bytes
    $buffer = New-Object byte[] 2
    $fs.Read($buffer, 0, 2) | Out-Null

    # Check if the bytes are "FE FF" (Little Endian)
    if ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF) {
        # Set the new bytes "01 00"
        $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
        $newBytes = [byte[]](0x01, 0x00)
        $fs.Write($newBytes, 0, 2)
        Write-Host "Changed: $Path"
    } else {
        Write-Host "Skipped (no FE FF at 0x14): $Path"
    }

    # Close the file stream
    $fs.Close()
}

Write-Host "`nProcess Complete."
