// ============================================================
// final_report.typ — Điểm vào (Entry point)
// FPT University Capstone — Báo cáo Cuối kỳ (Tiếng Việt)
// ============================================================

#import "template.typ": report, placeholder, hline, field
#import "cover.typ": cover-page

// ── ① Thông tin dự án ────────────────────────────────────
#let project-name   = "SAP Bug Tracking Management System (ZBUG_WS)"
#let group-name     = "Nhóm ZBUG"
#let members        = (
  "DEV-089 — Trưởng nhóm | SE11, SE38, SE80, SE93",
  "DEV-242 — Lập trình viên | SE38, SE51, SE80",
  "DEV-061 — Lập trình viên | ALV Grid & SmartForms",
  "DEV-118 — Kiểm thử viên | Quản lý lỗi, Kiểm thử",
  "DEV-237 — Lập trình viên | SE38, SE51, SE80, SE41",
)
#let supervisor     = ""
#let ext-supervisor = ""
#let report-date    = "Tháng 4 năm 2026"
// ─────────────────────────────────────────────────────────

// ── ② Trang bìa (không có số trang) ──────────────────────
#cover-page(
  project-name:   project-name,
  group-name:     group-name,
  members:        members,
  supervisor:     supervisor,
  ext-supervisor: ext-supervisor,
  date:           report-date,
)

// ── ③ Áp dụng kiểu dáng toàn cục từ template ─────────────
#show: report.with(
  project-name:   project-name,
  group-name:     group-name,
  members:        members,
  supervisor:     supervisor,
  ext-supervisor: ext-supervisor,
  date:           report-date,
)

// ── ④ Mục lục ─────────────────────────────────────────────
#set page(numbering: "i")
#counter(page).update(1)

#outline(
  title: [Mục lục],
  depth: 3,
  indent: 1.5em,
)
#pagebreak()

// ── ⑤ Nội dung chính (số trang Ả Rập từ đây) ────────────
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
