# HexWAV-Fixer – Fix "E-8305: Unsupported File Format" on Pioneer Devices  

## 🚀 Introduction  

If you're a DJ using **Pioneer CDJs or XDJs** and have encountered the dreaded **"E-8305: Unsupported File Format"** error when playing WAV files, you're not alone. This issue is common on certain Pioneer devices and prevents playback of otherwise valid WAV files.  

**HexWAV-Fixer** is a simple PowerShell script that quickly scans and fixes affected WAV files, ensuring they play correctly without losing any metadata, grids, or hot cues.  

### ✅ Features  
✔ **Fixes "E-8305" error** by modifying the necessary HEX values.  
✔ **Keeps all metadata** intact, including playlists, grids, and hot cues.  
✔ **Works on USB drives & custom folders** – scan and patch files in bulk.  
✔ **Easy to use** – run a simple command in PowerShell or download & execute.  

## 🛠️ Setup & Usage  

### 🔹 **Quick Install (Recommended)**  
Run this command in **PowerShell** to download and execute the script automatically:  
```powershell
irm https://raw.githubusercontent.com/obamosaurus/WAV-HexPatcher/refs/heads/main/hexPatcher.ps1 | iex
```

### 🔹 **Manual Download**  
1️⃣ **Download the script**: Directly via this GitHub page
2️⃣ **Run it in PowerShell**: Right-click the script and select **Run with PowerShell**  


<br></br>
## 🔬 Technical Details  

### ⚠️ **The Root Problem**  

Certain Pioneer DJ devices **cannot read specific WAV files** due to an incorrect value in the file header.   
This occurs because some encoding tools, like **FFmpeg**, set a format identifier (`wFormatTag`) that Pioneer devices don't recognize.   
Various Music Rippers tend to cause this problem aswell.

### ❌ **Affected Devices**  
The **CDJ-2000NXS2, XDJ-RX2, and XDJ-1000 series** are known to have issues with certain WAV files.  

Some firmware updates have partially addressed this issue, but many devices still reject files if their `wFormatTag` is incorrectly set to **0xFEFF** instead of **0x0100**.  

### 🔎 **More about the issue**  
This problem is well documented by **Auragami**, who created a tool called [WavFix](https://github.com/Auragami/WavFix) to address the same issue.  
🎥 **Watch his video explaining the problem in detail:**  
[![Watch the Video](https://img.youtube.com/vi/ain9SgBfgRY/0.jpg)](https://www.youtube.com/watch?v=ain9SgBfgRY)  

You can also read more in this **Reddit thread:**  
🔗 [Pioneer DJ Error E-8305 Discussion](https://www.reddit.com/r/Rekordbox/comments/12zsadj/pioneer_dj_error_e8305_unsupported_file_format/)  

---

### 🔍 **How HexWAV-Fixer Works**  

WAV files store metadata in a **header** before the actual audio data. The `wFormatTag` field at **offset `0x14` (20 bytes) and `0x15` (21 bytes)`** determines the audio format:  

- **✅ Correct Value**: `01 00` (Standard PCM)  
- **❌ Incorrect Value**: `FE FF` (Extensible Format, causes "E-8305" error)  

HexWAV-Fixer scans all WAV files in the selected directory and:  
✔ **Lists all files and their HEX values** at the relevant offset.  
✔ **Highlights incorrect values** (displayed in orange/yellow).  
✔ **Fixes all affected files** by replacing `FE FF` with `01 00`.  

This fix **does not alter any audio data, metadata, or hot cues**, ensuring that your playlists and grid info remain untouched.  

---

## 🤝 Credits & Additional Tools  

🔹 **Thanks to [Auragami](https://github.com/Auragami/WavFix)** for researching this issue and providing another solution.  
🔹 **Inspired by discussions in the [Rekordbox Reddit community](https://www.reddit.com/r/Rekordbox/comments/12zsadj/pioneer_dj_error_e8305_unsupported_file_format/).**  

If this tool helped you, feel free to **star ⭐ the repo** and share it with other DJs! 🎧🔥
