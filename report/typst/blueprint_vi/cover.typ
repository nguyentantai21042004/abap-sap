// ============================================================
// cover.typ — Trang bìa Tài liệu Thiết kế Nghiệp vụ
// Mirrors: Blueprint_Template.docx cover
// ============================================================

#let cover-page(
  project-name: "",
  module: "",
  created-by: "",
  version: "1.0",
  date: "",
) = {
  set page(numbering: none, header: none)

  // ── Outer border box ─────────────────────────────────────
  rect(width: 100%, height: 100%, stroke: 1.5pt)[
    #align(center + horizon)[
      #v(2cm)

      // ── Title block ──────────────────────────────────────
      #rect(
        width: 80%,
        stroke: 1.5pt,
        inset: 20pt,
        fill: luma(230),
      )[
        #align(center)[
          #text(size: 20pt, weight: "bold")[TÀI LIỆU THIẾT KẾ NGHIỆP VỤ]
        ]
      ]

      #v(2cm)

      // ── Document information table ────────────────────────
      #align(center)[
        #table(
          columns: (5cm, 8cm),
          align: (left, left),
          stroke: 0.5pt,
          table.cell(colspan: 2, align: center)[*Thông tin Tài liệu*],
          [Tên Dự án],    [#project-name],
          [Module],       [#module],
          [Tạo bởi],      [#created-by],
          [Phiên bản],    [#version],
          [Ngày],         [#date],
        )
      ]
    ]
  ]

  pagebreak()
}
