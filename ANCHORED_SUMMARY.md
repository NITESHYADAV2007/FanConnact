## Goal
- Apply the exact header, sidebar, CSS, and scripts from `livematches.html` to 10 sport pages, preserving only each page's `<title>`, sidebar active link, and main content.

## Constraints & Preferences
- All 10 files must have identical `<head>`, `<body>` tag, full header/sidebar shell (`<!-- BEGIN: MainHeader -->` to `<!-- END: SidebarNav -->`), scripts at bottom.
- Only per‑page diffs: `<title>` text, `nav-link-active` class on the matching sport’s sidebar `<a>`, and everything inside `<main>`.
- Keep all existing `<main>` content verbatim (match cards, sections, etc.).
- Remove any `pt-20` from main containers (header is sticky now, not fixed).

## Progress
### Done
- [x] Identified all 10 files to update: `cricket.html`, `football.html`, `basketball.html`, `tennis.html`, `hockey.html`, `kabbaddi.html`, `e-sports.html`, `baseball.html`, `vollyeball.html`, `tabletennis.html`.
- [x] Read `livematches.html` as reference template.
- [x] Read all 10 target files to understand current structure and extract existing `<main>` content.
- [x] Built `_rebuild.py` to process all 10 files with:
  - Common shell from `livematches.html` (head, body, header, sidebar, scripts)
  - Per‑page extracted `<main>` content preserved verbatim
  - Correct `<title>` per sport
  - `nav-link-active` class on the correct sidebar link only
  - `pt-20` removal from main containers
- [x] Verified all 10 files: correct title, 1 active link each, main content preserved, no `pt-20`, all required features present.

### Summary
All 10 files have been successfully upgraded to the consistent layout. Each file now shares the same head/body/header/sidebar/scripts structure from `livematches.html`, with only the title, sidebar active link, and main content differing per sport.
