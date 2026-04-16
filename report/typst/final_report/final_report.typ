// ============================================================
// final_report.typ — Entry point
// FPT University Capstone Project — Final Report
// Mirrors: Final Project Report_FHU.docx
//
// Usage:
//   typst compile final_report.typ
//   typst watch final_report.typ   (live preview)
// ============================================================

#import "template.typ": report, placeholder, hline, field
#import "cover.typ": cover-page

// ── ① Fill in your project info here ─────────────────────
#let project-name   = "SAP Bug Tracking Management System (ZBUG_WS)"
#let group-name     = "Group ZBUG"
#let members        = (
  "DEV-089 — Manager | SE11, SE38, SE80, SE93",
  "DEV-242 — Developer | SE38, SE51, SE80",
  "DEV-061 — Developer | ALV Grid & SmartForms",
  "DEV-118 — Tester | Bug Management, Testing",
  "DEV-237 — Developer | SE38, SE51, SE80, SE41",
)
#let supervisor     = ""
#let ext-supervisor = ""
#let report-date    = "April 2026"
// ─────────────────────────────────────────────────────────

// ── ② Cover page (no page number) ────────────────────────
#cover-page(
  project-name:   project-name,
  group-name:     group-name,
  members:        members,
  supervisor:     supervisor,
  ext-supervisor: ext-supervisor,
  date:           report-date,
)

// ── ③ Apply global styles from template ──────────────────
#show: report.with(
  project-name:   project-name,
  group-name:     group-name,
  members:        members,
  supervisor:     supervisor,
  ext-supervisor: ext-supervisor,
  date:           report-date,
)

// ── ④ Table of Contents ───────────────────────────────────
#set page(numbering: "i")
#counter(page).update(1)

#outline(
  title: [Table of Contents],
  depth: 3,
  indent: 1.5em,
)
#pagebreak()

// ── ⑤ Body (Arabic page numbers from here) ───────────────
#set page(numbering: "1")
#counter(page).update(1)

#include "sections/acknowledgement.typ"
#include "sections/acronyms.typ"
#include "sections/01_introduction.typ"
#include "sections/02_management.typ"
#include "sections/03_requirements.typ"
#include "sections/04_design.typ"
#include "sections/05_testing.typ"
#include "sections/06_release.typ"
