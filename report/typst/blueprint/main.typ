// ============================================================
// main.typ — Entry point
// Business Blueprint
// Mirrors: Blueprint_Template.docx
//
// Usage:
//   typst compile main.typ
//   typst watch main.typ       (live preview)
// ============================================================

#import "template.typ": blueprint, placeholder, hline
#import "cover.typ": cover-page

// ── ① Fill in your document info here ────────────────────
#let project-name = "SAP Bug Tracking Management System"
#let module       = "ZBUGTRACK (Custom Development)"
#let created-by   = "DEV-089"
#let version      = "5.0"
#let doc-date     = "April 2026"
// ─────────────────────────────────────────────────────────

// ── ② Cover page (no page number) ────────────────────────
#cover-page(
  project-name: project-name,
  module:       module,
  created-by:   created-by,
  version:      version,
  date:         doc-date,
)

// ── ③ Apply global styles ─────────────────────────────────
#show: blueprint.with(
  project-name: project-name,
  module:       module,
  created-by:   created-by,
  version:      version,
  date:         doc-date,
)

// ── ④ Front matter (Change History + Signatures) ─────────
#set page(numbering: "i")
#counter(page).update(1)

#include "sections/00_frontmatter.typ"

// ── ⑤ Table of Contents ───────────────────────────────────
#outline(
  title: [Table of Contents],
  depth: 3,
  indent: 1.5em,
)
#pagebreak()

// ── ⑥ Body ────────────────────────────────────────────────
#set page(numbering: "1")
#counter(page).update(1)

#include "sections/01_overview.typ"
#include "sections/02_org_structure.typ"
#include "sections/03_business_process.typ"
#include "sections/04_reports.typ"
