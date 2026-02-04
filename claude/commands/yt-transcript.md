---
description: Extract and summarize YouTube video transcripts
argument-hint: "<youtube-url> [--raw]"
---

Extract subtitles from YouTube videos using yt-dlp, then summarize or return raw text.

## Usage

- `/yt-transcript <url>` → Extract + summarize (default)
- `/yt-transcript <url> --raw` → Extract only, no summary

## Implementation Steps

### 1. Parse Arguments

Check $ARGUMENTS for:
- YouTube URL (required, first argument)
- `--raw` flag (optional)

If no URL provided, show usage and exit.

### 2. Check Dependencies

Verify yt-dlp is installed:
```bash
if ! command -v yt-dlp &> /dev/null; then
  echo "❌ yt-dlp not found. Install with: brew install yt-dlp"
  exit 1
fi
```

### 3. Extract Subtitles

Use yt-dlp to download subtitles (prefer French, fallback to English):
```bash
yt-dlp --write-auto-subs --sub-langs "fr,en" --sub-format vtt --skip-download -o "/tmp/yt_%(id)s" "$URL"
```

### 4. Parse VTT File

- Locate the downloaded VTT file: `/tmp/yt_*.vtt` or `/tmp/yt_*.fr.vtt` or `/tmp/yt_*.en.vtt`
- Read and clean the VTT content:
  - Remove VTT headers (`WEBVTT`, `Kind:`, etc.)
  - Strip timestamp lines (format: `00:00:00.000 --> 00:00:00.000`)
  - Remove duplicate consecutive lines
  - Remove empty lines
  - Trim whitespace

### 5. Handle Output

**If `--raw` flag present**:
- Return the cleaned transcript text directly

**Otherwise (default behavior)**:
- Use the cleaned transcript as input for summarization
- Format output with V{n} prefix (where n is incremental version)
- Structure: Brief overview → Key points → Takeaways

### 6. Cleanup

Remove temporary VTT files after processing:
```bash
rm -f /tmp/yt_*.vtt
```

## Error Handling

- **No subtitles available**: Inform user that the video has no auto-generated or manual subtitles
- **Invalid URL**: Show usage message
- **yt-dlp missing**: Suggest installation via brew
- **File not found**: Check if extraction succeeded before parsing

## Example Output Format

**With summary (default)**:
```
V1: [Video Title]

📺 Overview: [Brief description]

🔑 Key Points:
├── Point 1
├── Point 2
└── Point 3

💡 Takeaways: [Main insights]
```

**With --raw flag**:
```
[Clean transcript text without timestamps or duplicates]
```
