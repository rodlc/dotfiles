---
description: Unified PDF operations
argument-hint: "<action> <file> [options]"
---

PDF manipulation skill. Actions:

- `summarize <file>` → Résumé structuré (délègue à /summarize)
- `extract <file>` → Extraction texte/tables (PDF skill)
- `forms <file>` → Extraire champs formulaire (PDF skill)
- `fill <file> <data>` → Remplir formulaire (PDF skill)
- `merge <files...>` → Fusionner PDFs (PDF skill)
- `split <file>` → Séparer pages (PDF skill)
- `create <template.html>` → Générer PDF depuis HTML (weasyprint)

## Usage Examples

```bash
# Extraire les champs d'un formulaire
/pdf forms ~/Documents/PER_Yomoni.pdf

# Fusionner plusieurs PDFs
/pdf merge doc1.pdf doc2.pdf -o combined.pdf

# Créer un PDF depuis un template HTML
/pdf create ~/Templates/attestation.html

# Résumer un document (utilise /summarize)
/pdf summarize ~/Downloads/article.pdf

# Extraire le texte
/pdf extract ~/Documents/report.pdf

# Diviser un PDF en pages
/pdf split ~/Documents/large.pdf
```

## Implementation Notes

- **summarize**: Delegates to /summarize skill (already configured)
- **extract, forms, fill, merge, split**: Use document-skills PDF tools
- **create**: Uses weasyprint for HTML→PDF conversion (niche use case for administrative documents)

## Action Dispatch

Parse `$ARGUMENTS` to determine action:

1. First token = action (`summarize`, `extract`, `forms`, `fill`, `merge`, `split`, `create`)
2. Remaining tokens = file paths and options

### summarize action
- Delegate to `/summarize` skill with file path

### extract action
- Use PDF skill to extract text and tables
- Output extracted content

### forms action
- Use PDF skill to extract form fields
- Display field names and current values

### fill action
- Parse data (JSON object or key=value pairs)
- Use PDF skill to fill form fields
- Save filled PDF

### merge action
- Accept multiple file paths
- Use PDF skill to merge PDFs
- Save to `-o` output file or default name

### split action
- Use PDF skill to split PDF into separate pages
- Save to directory or numbered files

### create action
- Use weasyprint to convert HTML template to PDF
- Handle CSS and assets
- Save to output file

## Error Handling

- **Missing file**: Inform user, check path
- **Unsupported action**: Show usage examples
- **Tool not available**:
  - PDF skill: Check plugin installation
  - weasyprint: Suggest `brew install weasyprint`

## Style

- Language: Match user context (EN for formal, FR for informal)
- Tone: Pragmatic, concise, actionable
- Output: Show file paths, confirm operations
