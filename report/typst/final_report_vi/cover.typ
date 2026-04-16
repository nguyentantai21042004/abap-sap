// ============================================================
// cover.typ — Trang bìa (Tiếng Việt)
// ============================================================

#import "template.typ": hline, placeholder, field

#let cover-page(
  project-name: "[Tên dự án (Mã)]",
  group-name: "<Tên nhóm>",
  members: (),
  supervisor: "",
  ext-supervisor: "",
  date: "Tháng 8 năm 2023",
) = {
  set page(numbering: none)

  align(center)[
    // ── Header logo / bộ ──────────────────────────────────
    #grid(
      columns: (1fr, 1fr),
      align(center)[
        #rect(width: 3cm, height: 1.5cm, stroke: none)[
          #align(center + horizon)[
            #text(size: 8pt, weight: "bold")[LOGO]
          ]
        ]
      ],
      align(center)[
        #text(weight: "bold")[BỘ GIÁO DỤC VÀ ĐÀO TẠO]
      ],
    )

    #v(1cm)
    #hline()
    #v(0.3cm)
    #text(size: 16pt, weight: "bold")[ĐẠI HỌC FPT]
    #v(0.3cm)
    #hline()
    #v(1cm)

    // ── Loại tài liệu ─────────────────────────────────────
    #text(size: 13pt)[Tài liệu Đồ án Tốt nghiệp]
    #v(0.5cm)

    // ── Tên dự án ──────────────────────────────────────────
    #rect(
      width: 80%,
      stroke: none,
      fill: luma(230),
      inset: 14pt,
    )[
      #text(size: 14pt, weight: "bold")[#project-name]
    ]

    #v(2cm)

    // ── Bảng thông tin nhóm ────────────────────────────────
    #align(center)[
      #table(
        columns: (3cm, 9cm),
        align: (left, left),
        table.header(
          table.cell(colspan: 2, align: center)[
            #text(weight: "bold")[#group-name]
          ],
        ),
        [*Thành viên nhóm*],
        {
          if members.len() == 0 {
            [_\<Họ tên\> \<Mã số SV\>_]
          } else {
            members.map(mbr => text(mbr)).join(linebreak())
          }
        },
        [*Giảng viên hướng dẫn*],    [#supervisor],
        [*Giảng viên hướng dẫn ngoài*],[#ext-supervisor],
      )
    ]

    #v(3cm)

    // ── Ngày ──────────────────────────────────────────────
    #text(size: 12pt)[--- Hà Nội, #date ---]
  ]

  pagebreak()
}
