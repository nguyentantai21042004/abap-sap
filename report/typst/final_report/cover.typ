// ============================================================
// cover.typ — Cover page
// Mirrors the cover of Final Project Report_FHU.docx
// ============================================================

#import "template.typ": hline, placeholder, field

#let cover-page(
  project-name: "[Project name (Code)]",
  group-name: "<Group Name>",
  members: (),
  supervisor: "",
  ext-supervisor: "",
  date: "August 2023",
) = {
  set page(numbering: none)

  align(center)[
    // ── Header logos / ministry ──────────────────────────
    #grid(
      columns: (1fr, 1fr),
      align(center)[
        // Placeholder for university logo
        #rect(width: 3cm, height: 1.5cm, stroke: none)[
          #align(center + horizon)[
            #text(size: 8pt, weight: "bold")[LOGO]
          ]
        ]
      ],
      align(center)[
        #text(weight: "bold")[MINISTRY OF EDUCATION AND TRAINING]
      ],
    )

    #v(1cm)
    #hline()
    #v(0.3cm)
    #text(size: 16pt, weight: "bold")[FPT UNIVERSITY]
    #v(0.3cm)
    #hline()
    #v(1cm)

    // ── Document type ─────────────────────────────────────
    #text(size: 13pt)[Capstone Project Document]
    #v(0.5cm)

    // ── Project name ──────────────────────────────────────
    #rect(
      width: 80%,
      stroke: none,
      fill: luma(230),
      inset: 14pt,
    )[
      #text(size: 14pt, weight: "bold")[#project-name]
    ]

    #v(2cm)

    // ── Group info table ──────────────────────────────────
    #align(center)[
      #table(
        columns: (3cm, 9cm),
        align: (left, left),
        table.header(
          table.cell(colspan: 2, align: center)[
            #text(weight: "bold")[#group-name]
          ],
        ),
        [*Group Members*],
        {
          if members.len() == 0 {
            [_\<Member name\> \<RollNo\> \<Student code\>_]
          } else {
            members.map(mbr => text(mbr)).join(linebreak())
          }
        },
        [*Supervisor*],    [#supervisor],
        [*Ext Supervisor*],[#ext-supervisor],
      )
    ]

    #v(3cm)

    // ── Date ──────────────────────────────────────────────
    #text(size: 12pt)[--- Hanoi, #date ---]
  ]

  pagebreak()
}
