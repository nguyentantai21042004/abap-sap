// ============================================================
// template.typ — FPT University Capstone Project Report (VI)
// ============================================================

#let report(
  project-name: "[Tên dự án (Mã)]",
  group-name: "<Tên nhóm>",
  members: (),
  supervisor: "",
  ext-supervisor: "",
  date: "Tháng 8 năm 2023",
  body,
) = {

  // ── Thiết lập trang ──────────────────────────────────────
  set page(
    paper: "a4",
    margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 2cm),
    numbering: "1",
    number-align: center,
  )

  // ── Văn bản cơ sở ────────────────────────────────────────
  set text(
    font: ("Times New Roman", "Georgia"),
    size: 12pt,
    lang: "vi",
  )

  set par(
    justify: true,
    leading: 1em,
    spacing: 1.2em,
  )

  // ── Kiểu tiêu đề ─────────────────────────────────────────
  set heading(numbering: none)

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

  // ── Kiểu bảng ────────────────────────────────────────────
  set table(
    stroke: 0.5pt + black,
    inset: 6pt,
  )

  show table.cell.where(y: 0): set text(weight: "bold")
  show table.cell: set par(justify: false)

  // ── Chú thích hình ───────────────────────────────────────
  set figure(gap: 0.8em)
  show figure.caption: set text(size: 10pt, style: "italic")

  // ── Truyền nội dung ──────────────────────────────────────
  body
}

// ── Các hàm tiện ích ─────────────────────────────────────────

/// Văn bản giữ chỗ (in nghiêng, màu xám)
#let placeholder(msg) = text(style: "italic", fill: gray, [\[#msg\]])

/// Đường kẻ phân cách phần
#let hline() = line(length: 100%, stroke: 0.5pt)

/// Hàng nhãn/giá trị hai cột đơn giản
#let field(label, value) = grid(
  columns: (3cm, 1fr),
  gutter: 0.5em,
  text(weight: "bold", label + ":"),
  value,
)

/// Khung giữ chỗ sơ đồ — hiển thị hộp đứt nét với tiêu đề và đường dẫn file Mermaid.
#let diagram-placeholder(caption, mmd-file) = block(
  width: 100%,
  inset: (x: 16pt, y: 20pt),
  stroke: (paint: luma(170), thickness: 0.5pt, dash: "dashed"),
  fill: luma(252),
  radius: 3pt,
)[
  #align(center)[
    #text(size: 11pt, weight: "bold")[#caption]
    #v(0.4em)
    #text(size: 9pt, style: "italic", fill: luma(130))[
      (Nguồn sơ đồ: #raw(mmd-file))
    ]
  ]
]
