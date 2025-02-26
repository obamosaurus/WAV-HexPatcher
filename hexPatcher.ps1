# Set target path
$FolderPath = "D:\Contents"

# Get all WAV files in subdirs
$wavFiles = Get-ChildItem -Path $FolderPath -Filter "*.wav" -Recurse -File

foreach ($wavFile in $wavFiles) {
    $Path = $wavFile.FullName

    # Open file (rw)
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite)

    # Seek to offset (0x14, 0x15)
    $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null

    $buffer = New-Object byte[] 2
    $fs.Read($buffer, 0, 2) | Out-Null

    # Check if values !== 01 00 at 0x14/0x15
    if ($buffer[0] -eq 0xFE -and $buffer[1] -eq 0xFF) {
        $fs.Seek(20, [System.IO.SeekOrigin]::Begin) | Out-Null
        $newBytes = [byte[]](0x01, 0x00)
        $fs.Write($newBytes, 0, 2)
        Write-Host "Changed: $Path"
    }

    $fs.Close()
}
