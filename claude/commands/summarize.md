---
description: Auto-summarize new files in Downloads/Summarize
argument-hint: "[file/folder] (default: ~/Downloads/Summarize)"
---

Automatically process unsummarized files, append to resume, clean up, and optionally save to Notion.

## Default Behavior (No Arguments)

When invoked without arguments (`/summarize`):

1. **Scan** `~/Downloads/Summarize/Pending/` for all supported files
2. **Identify unsummarized files** by comparing with existing `*_Resume_*.md` (in parent dir)
3. **Detect duplicates** by content similarity (skip if already summarized)
4. **Process each** unsummarized file and append to resume
5. **Clean up** source files after successful summarization (delete from Pending/)
6. **Ask user** which summaries to save to Notion Tasks

## With Arguments

- **File path**: Process single file (e.g., `/summarize article.pdf`)
- **Folder path**: Process all files in folder (e.g., `/summarize ~/Documents/Articles/`)

## Input Detection

Automatically detect input type:
- **PDF**: Use PDF skill for extraction (preferred) or Read tool for < 32MB files
- **SRT**: Extract text content, ignore timestamps
- **MHTML**: Decode quoted-printable, extract substantive paragraphs
- **TXT**: Direct read
- **URL**: Use WebFetch

## Output Format

Generate structured summary with **readable spacing**:

```markdown
## **{Type}{Number}. {Title}**
*({Source Type} - {Context})*

📍 **Contexte** - [1 phrase résumant l'enjeu]

📝 **Fait**

**{Sous-section 1}**
- Point clé 1
- Point clé 2
- Point clé 3

**{Sous-section 2}**
- Point clé 1
- Point clé 2

**{Sous-section 3}**
- Point clé 1
- Point clé 2

[Si données denses sans sous-sections naturelles, utiliser paragraphes courts séparés par lignes vides]

👿 **Détracteur** - [Point de vue opposé ou limite de l'analyse] ([Consensus: majoritaire/minoritaire/à débattre])

🔖 **Action**

- Implication 1
- Implication 2
- Ce qu'il faut surveiller/anticiper
```

**Types**: V (vidéo), P (PDF/article), A (autre)
**Numbering**: Séquentiel par type (V1, V2... P1, P2...)

## Arguments

Parse `$ARGUMENTS`:
- **No arguments**: Process `~/Downloads/Summarize/` (default)
- **File/folder path**: Process specified location

## Processing Workflow

### Phase 1: Discovery

1. **Determine target directory**:
   - If `$ARGUMENTS` provided → use specified path
   - Else → use `~/Downloads/Summarize/Pending/`

2. **Find resume file**:
   - Search for `*_Resume_*.md` in parent directory (`~/Downloads/Summarize/`)
   - If not found → create `{YYYYMMDD}_Resume.md` in parent

3. **List all source files**:
   - Supported: `.pdf`, `.srt`, `.mhtml`, `.txt`
   - Exclude: `*_Resume_*.md`, `extract_*.py`, `*_extract.txt`

4. **Identify unsummarized files**:
   - Read resume file content
   - For each source file, check if similar content/title appears in resume
   - **Duplicate detection**:
     - Extract title/date from filename (e.g., "Réveil Courrier du 3 janvier")
     - Search resume for matching title/date
     - Skip if found (avoid processing same content from different sources)
   - Mark files NOT found in resume as "to process"

### Phase 2: Summarization

For each unsummarized file:

1. **Detect input type** from file extension

2. **Extract content**:
   - PDF: Use PDF skill for extraction (preferred) or Read tool for smaller files
   - SRT: Read + strip timestamps (lines matching `\d{2}:\d{2}:\d{2}`)
   - MHTML: Decode quoted-printable encoding, extract `<p>` tags > 50 chars
   - TXT: Direct read

3. **Generate summary**:
   - Analyze content
   - Create structured summary with bullet points and spacing
   - Use **bold** for sub-sections and key terms (NOT entire sentences)
   - Group related points under sub-headings

4. **Append to resume**:
   - Add `---` separator
   - Append summary to resume file

### Phase 3: Cleanup

1. **Delete processed source files**:
   - Only delete files from `Pending/` that were successfully summarized
   - Keep: resume file (parent dir), extract scripts, temp extracts
   - **Also delete duplicates** that were skipped (they're already in resume)
   - Show list of deleted files to user

### Phase 4: Notion Sync

1. **Ask user** via AskUserQuestion:
   - Show list of all NEW summaries created this session
   - Multi-select: "Which summaries should be saved to Notion Tasks?"
   - Options: One option per summary title

2. **For selected summaries**:
   - Create page in 💥 Tasks database
   - Title: `📚 Résumé {Title from summary}`
   - Content: Full summary in Notion-flavored markdown
   - Properties: Priority=Quick, Done=No

## Technical Notes

**File operations**:
- Always append, never overwrite existing summaries
- Use Read tool before Edit/Write
- Add horizontal rule `---` separator between summaries

**Formatting**:
- Blank lines between sections for readability
- Bullet lists for multiple related points
- Bold for sub-sections, numbers, key actors/concepts
- Short paragraphs (3-4 lines max) if not using bullets

**Error handling**:
- Missing dependencies (pdftotext): Install via `brew install poppler`
- Unsupported format: Inform user, suggest manual processing
- Parse errors: Show partial extraction + error context

## Examples

```bash
# Default: Process all new files in ~/Downloads/Summarize/
/summarize

# Process specific folder
/summarize ~/Documents/Research/

# Process single file
/summarize ~/Downloads/article.pdf
```

## Typical Output

```
🔍 Scanning ~/Downloads/Summarize/Pending/...
Found resume: ~/Downloads/Summarize/Courrier_International_Resume_2024-12-24.md
Found 5 files:
  - new_article.pdf (new)
  - interview.srt (new)
  - report.mhtml (new)
  - duplicate_reveil_28dec.pdf (duplicate - skipping)
  - duplicate_reveil_28dec.mhtml (duplicate - skipping)

📝 Processing new_article.pdf...
   ✓ Summary appended (P6)

📝 Processing interview.srt...
   ✓ Summary appended (V6)

📝 Processing report.mhtml...
   ✓ Summary appended (P7)

🧹 Cleaning up Pending/ files...
   Deleted: new_article.pdf
   Deleted: interview.srt
   Deleted: report.mhtml
   Deleted: duplicate_reveil_28dec.pdf (duplicate)
   Deleted: duplicate_reveil_28dec.mhtml (duplicate)

💾 Save to Notion?
   Which summaries should be saved to Notion Tasks? [multi-select]
   □ P6. New Article Title
   □ V6. Interview Title
   □ P7. Report Title
```

## Style

- **Language**: Titles in EN, content matches source language
- **Tone**: Pragmatic, frugal, actionable (match user's CLAUDE.md guidelines)
- **Spacing**: Generous blank lines, bullet points, readable structure
- **Emphasis**: Bold for key terms/numbers/sub-sections, NOT for entire sentences
- **Concision**: Dense information per line, but well-spaced overall
