# HexWAV-Fixer – Fix "E-8305: Unsupported File Format" on Pioneer Devices  

<br>

## 🚀 Introduction

If you're using **Pioneer CDJs or XDJs**, you might have encountered the dreaded **"E-8305: Unsupported File Format"** error when playing WAV files. This frustrating issue affects certain Pioneer devices, preventing them from playing otherwise valid WAV files.  

💡 **HexWAV-Fixer** is a simple PowerShell script that **automatically scans and fixes WAV files** so they play flawlessly—without losing metadata, grids, or hot cues.  

## ✅ Features  

📌 **Fixes the "E-8305" error** by correcting specific WAV file headers.  
📌 **Keeps all metadata intact**, including Rekordbox playlists, grids, and hot cues.  
📌 **Works on USB drives & folders** – scan and patch files in bulk.  
📌 **Super easy to use** – just run a single PowerShell command!  

---
<br>

## 🛠️ Installation & Usage  

### 🔹 **Quick Install (Recommended)**  

Run this command in **PowerShell** to download and execute the script automatically:  
```powershell
irm https://raw.githubusercontent.com/obamosaurus/WAV-HexPatcher/refs/heads/main/hexPatcher.ps1 | iex
```

### 🔹 **Manual Download**  

1️⃣ **Download the script**: Available directly on this GitHub page.  
2️⃣ **Run it in PowerShell**: Right-click the script and select **Run with PowerShell**.  

---
<br>

## 🔬 What’s Going Wrong?  

### ⚠️ **The Root Problem**  

Certain Pioneer DJ devices **cannot read specific WAV files** due to an incorrect value in the file header.  

This issue arises because some encoding tools, like **FFmpeg**, assign an unsupported format identifier (`wFormatTag`) that Pioneer devices don’t recognize. Some music-ripping software also causes this problem.  

### ❌ **Affected Devices**  

The following Pioneer models (and possibly more) may struggle with certain WAV files:  
📌 **CDJ-2000NXS2**  
📌 **XDJ-RX2**  
📌 **XDJ-1000 Series**  

Some firmware updates have attempted to fix this, but **many devices still reject files if their `wFormatTag` is set to `0xFEFF` instead of `0x0100`**.  

---
<br>

## 🔍 How HexWAV-Fixer Works  

WAV files contain a **header section** before the actual audio data. The `wFormatTag` field at **offset `0x14` (20 bytes) and `0x15` (21 bytes)`** determines the audio format:  

✅ **Correct Value**: `01 00` (Standard PCM – Plays normally)  
❌ **Incorrect Value**: `FE FF` (Extensible Format – Causes "E-8305" error)  

**HexWAV-Fixer scans all WAV files in the selected directory and:**  
✔ **Lists files and their HEX values** at the relevant offset.  
✔ **Highlights incorrect values** (displayed in orange/yellow).  
✔ **Fixes all affected files** by replacing `FE FF` with `01 00`.  

💡 This fix **does not alter audio data, metadata, or hot cues**, ensuring your playlists and grids remain intact!  

---
<br>

## 🔎 **More About the Issue**  

This problem has been researched by [Auragami](https://github.com/Auragami), who offers a similar tool for modifying WAV headers. However, **his method doesn’t modify files inside the playlist**, meaning you’ll lose hot cues and grids in Rekordbox.  

For more discussions on this, check out:  
[Reddit thread on Pioneer DJ Error E-8305](https://www.reddit.com/r/Rekordbox/comments/12zsadj/pioneer_dj_error_e8305_unsupported_file_format/)  

---
<br>

## 🤝 Credits & Additional Tools  

🔹 **Big thanks to [Auragami](https://github.com/Auragami/WavFix)** for researching this issue and providing an alternative solution.  
🔹 **Inspired by discussions in the [Rekordbox Reddit community](https://www.reddit.com/r/Rekordbox/comments/12zsadj/pioneer_dj_error_e8305_unsupported_file_format/).**  

⭐ **If this tool helped you, consider starring the repo and sharing it with others!**  
