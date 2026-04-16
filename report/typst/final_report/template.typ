// ============================================================
// template.typ — FPT University Capstone Project Report
// Mirrors: Final Project Report_FHU.docx
// ============================================================

#let report(
  project-name: "[Project name (Code)]",
  group-name: "<Group Name>",
  members: (),
  supervisor: "",
  ext-supervisor: "",
  date: "August 2023",
  body,
) = {

  // ── Page setup ──────────────────────────────────────────
  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 2cm),
    numbering: "1",
    number-align: center,
  )

  // ── Base text ────────────────────────────────────────────
  set text(
    font: ("Times New Roman", "Georgia", "Linux Libertine"),
    size: 12pt,
    lang: "en",
  )

  set par(
    justify: true,
    leading: 1em,
    spacing: 1.2em,
  )

  // ── Heading styles ───────────────────────────────────────
  // Level 1 → Roman numeral chapters  (I. II. III. ...)
  set heading(numbering: none)   // manual numbering in each section file

  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(1em)
    text(size: 14pt, weight: "bold", it.body)
    v(0.5em)
  }

  show heading.where(level: 2): it => {
    v(0.8em)
    text(size: 13pt, weight: "bold", it.body)
    v(0.3em)
  }

  show heading.where(level: 3): it => {
    v(0.6em)
    text(size: 12pt, weight: "bold", it.body)
    v(0.2em)
  }

  show heading.where(level: 4): it => {
    v(0.4em)
    text(size: 12pt, weight: "bold", style: "italic", it.body)
    v(0.1em)
  }

  // ── Table style ──────────────────────────────────────────
  set table(
    stroke: 0.5pt + black,
    inset: 6pt,
  )

  show table.cell.where(y: 0): set text(weight: "bold")

  // ── Figure caption ───────────────────────────────────────
  set figure(gap: 0.8em)
  show figure.caption: set text(size: 10pt, style: "italic")

  // ── Pass body ────────────────────────────────────────────
  body
}

// ── Reusable helpers ─────────────────────────────────────────

/// Italic placeholder text (fills [Fill ... here] blocks)
#let placeholder(msg) = text(style: "italic", fill: gray, [\[#msg\]])

/// Section separator line
#let hline() = line(length: 100%, stroke: 0.5pt)

/// Simple two-column label/value row
#let field(label, value) = grid(
  columns: (3cm, 1fr),
  gutter: 0.5em,
  text(weight: "bold", label + ":"),
  value,
)
