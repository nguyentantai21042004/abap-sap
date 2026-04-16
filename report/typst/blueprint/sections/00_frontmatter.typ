// ============================================================
// 00_frontmatter.typ — Change History & Signature tables
// Mirrors: Blueprint_Template.docx frontmatter
// ============================================================
#import "../template.typ": placeholder, hline

// ── Change History ────────────────────────────────────────
#align(center)[
  #table(
    columns: (2.5cm, 3cm, 1fr, 2.5cm, 1.5cm, 1.5cm),
    align: center,
    [*Changed date*],
    [*Items have been changed*],
    [*Changed content / Reason*],
    [*Updated by*],
    [*Type (A/C/D)*],
    [*Version*],
    [], [], [], [], [], [],
    [], [], [], [], [], [],
    table.cell(
      colspan: 6,
      align: left,
    )[_*A* -- Create   *C* -- Change   *D* -- Delete_],
  )
]

#v(1cm)

// ── Advisor Signature ─────────────────────────────────────
#table(
  columns: (2.5cm, 1fr, 3cm, 2.5cm, 3cm),
  align: center,
  table.cell(colspan: 5, align: left)[*Advisor Signature*],
  [],              [*Full name & Role*], [*Signature*], [*Date*], [*Note*],
  [*Created by*],  [],                   [],             [],       [],
  [*Reviewed by*], [],                   [],             [],       [],
  [*Approved by*], [],                   [],             [],       [],
)

#v(0.8cm)

// ── FU Signature ──────────────────────────────────────────
#table(
  columns: (2.5cm, 1fr, 3cm, 2.5cm, 3cm),
  align: center,
  table.cell(colspan: 5, align: left)[*FU Signature*],
  [],              [*Full name & Role*], [*Signature*], [*Date*], [*Note*],
  [*Reviewed by*], [],                   [],             [],       [],
  [*Approved by*], [],                   [],             [],       [],
)

#pagebreak()
