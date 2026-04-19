// ============================================================
// 00_frontmatter.typ — Lịch sử Thay đổi & Bảng Chữ ký
// Mirrors: Blueprint_Template.docx frontmatter
// ============================================================
#import "../template.typ": placeholder, hline

// ── Lịch sử Thay đổi ─────────────────────────────────────
#align(center)[
  #table(
    columns: (2.5cm, 3cm, 1fr, 2.5cm, 1.5cm, 1.5cm),
    align: center,
    [*Ngày thay đổi*],
    [*Mục đã thay đổi*],
    [*Nội dung / Lý do thay đổi*],
    [*Cập nhật bởi*],
    [*Loại (A/C/D)*],
    [*Phiên bản*],
    [], [], [], [], [], [],
    [], [], [], [], [], [],
    table.cell(
      colspan: 6,
      align: left,
    )[_*A* -- Tạo mới   *C* -- Sửa đổi   *D* -- Xóa_],
  )
]

#v(1cm)

// ── Chữ ký Cố vấn ────────────────────────────────────────
#table(
  columns: (2.5cm, 1fr, 3cm, 2.5cm, 3cm),
  align: center,
  table.cell(colspan: 5, align: left)[*Chữ ký Cố vấn*],
  [],              [*Họ tên & Vai trò*], [*Chữ ký*], [*Ngày*], [*Ghi chú*],
  [*Tạo bởi*],    [],                    [],          [],       [],
  [*Xem xét bởi*],[],                    [],          [],       [],
  [*Phê duyệt bởi*],[],                  [],          [],       [],
)

#v(0.8cm)

// ── Chữ ký FU ────────────────────────────────────────────
#table(
  columns: (2.5cm, 1fr, 3cm, 2.5cm, 3cm),
  align: center,
  table.cell(colspan: 5, align: left)[*Chữ ký FU*],
  [],              [*Họ tên & Vai trò*], [*Chữ ký*], [*Ngày*], [*Ghi chú*],
  [*Xem xét bởi*],[],                    [],          [],       [],
  [*Phê duyệt bởi*],[],                  [],          [],       [],
)

#pagebreak()
