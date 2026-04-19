# Implementation Plan — Slide Presentation
## SAP Bug Tracking Management System (ZBUG_WS)

---

## Ràng buộc kỹ thuật Marp → PPTX

| Quy tắc | Lý do |
| :--- | :--- |
| **Không dùng `<div>`, `<span>`, HTML tags** | PPTX export render thành text thô |
| **Không dùng `<style scoped>`** | Không áp dụng được trong PPTX |
| **Chỉ dùng Markdown thuần** | Table, bullet, bold, italic, blockquote, code block |
| **Giới hạn nội dung mỗi slide** | Tối đa ~10 dòng text hoặc 1 bảng 8 hàng |
| **Tách slide khi quá dài** | Dùng `---` để ngắt |

---

## Cấu trúc Slide — 16 Slides

### Slide 01 — Cover (Title)
**Class:** `title`
**Nội dung:**
- H1: SAP Bug Tracking Management System
- H2: ZBUG_WS — v5.0
- Text: Nhóm ZBUG | FPT University Capstone | Tháng 4 năm 2026

---

### Slide 02 — Nhóm Dự án
**H2:** Nhóm Dự án
**Nội dung:** Bảng 5 thành viên

| Cột | Nội dung |
| :--- | :--- |
| Tài khoản | DEV-089 / DEV-242 / DEV-061 / DEV-118 / DEV-237 |
| Họ tên | Hoàng Anh / Linh / Hiếu / Ka / Đức |
| Vai trò SAP | Manager / Developer / Developer / Tester / Developer |
| Trách nhiệm | CSDL + logic lõi / Bug Detail + FM / Bug List + Search / Email + QA / State + Auto-Assign |

**Footer:** Tổng ~35 ngày-người | SAP S40, Client 324, ABAP 7.70

---

### Slide 03 — Bối Cảnh & Vấn Đề
**H2:** Bối Cảnh & Vấn Đề
**Nội dung:** 2 nhóm bullet

**Vấn đề thực tế (4 bullets):**
- Báo cáo lỗi phân tán qua bảng tính, email, Zalo
- Dev nhận phân công không rõ ưu tiên hay module
- Manager không thấy phân bổ workload thời gian thực
- Không có bằng chứng có cấu trúc về báo cáo & sửa lỗi

**Giải pháp ZBUG_WS (4 bullets):**
- Chạy native trên SAP — không cần license bổ sung
- Truy cập qua 1 T-code duy nhất: `ZBUG_WS`
- Dữ liệu lưu trong bảng ABAP (`ZBUG_TRACKER`, ...)
- UI là SAP GUI thuần túy (Module Pool / Dynpro)

---

### Slide 04 — So Sánh ZPG vs ZBUG_WS
**H2:** So Sánh: Hệ Thống Tham Chiếu vs ZBUG_WS
**Nội dung:** Bảng so sánh 10 tính năng

| Tính năng | ZPG | ZBUG_WS |
| :--- | :---: | :---: |
| Module Pool (Type M) | ✗ | ✓ |
| Vòng đời 10 trạng thái + Popup | ✗ | ✓ |
| Auto-assign theo module/workload | ✗ | ✓ |
| Phân quyền tập trung (FM) | ✗ | ✓ |
| Audit log đầy đủ | ✗ | ✓ |
| Email CL_BCS | ✗ | ✓ |
| PDF SmartForm | ✗ | ✓ |
| Dashboard Header realtime | ✗ | ✓ |
| Bug Search Engine | ✗ | ✓ |
| Quản lý Dự án | ✗ | ✓ |

---

### Slide 05 — Tổng Quan Hệ Thống (Screen Map)
**H2:** Tổng Quan Hệ Thống
**Nội dung:** Bảng màn hình + bullet cấu trúc code

**Bảng màn hình (7 hàng):**

| Màn hình | Tên | Mới v5.0 |
| :--- | :--- | :---: |
| 0410 | Tìm kiếm Dự án (điểm vào) | ✓ |
| 0400 | Danh sách Dự án | |
| 0200 | Bug List + Dashboard Header | ✓ |
| 0300 | Bug Detail (6 tab) | |
| 0370 | Popup Chuyển Trạng thái | ✓ |
| 0500 | Chi tiết Dự án | |
| 0210/0220 | Bug Search | ✓ |

**Footer:** Gói `ZBUGTRACK` | Chương trình `Z_BUG_WORKSPACE_MP` | 6 ABAP Includes

---

### Slide 06 — Cấu Trúc Code ABAP
**H2:** Cấu Trúc Code — 6 ABAP Include
**Nội dung:** Bảng 6 include

| Include | Nội dung |
| :--- | :--- |
| `Z_BUG_WS_TOP` | Khai báo toàn cục, kiểu dữ liệu, hằng số 10 trạng thái |
| `Z_BUG_WS_F00` | Field catalog ALV cho 5 grid, class `LCL_EVENT_HANDLER` |
| `Z_BUG_WS_PBO` | Process Before Output — tất cả 9 màn hình |
| `Z_BUG_WS_PAI` | Process After Input — toàn bộ fcode handler |
| `Z_BUG_WS_F01` | Business Logic: save, change_status, auto_assign, email, history |
| `Z_BUG_WS_F02` | Helper: 10 F4 search help, long text API, popup, SMW0 download |

**Footer:** Triển khai thủ công qua SE38: paste → Ctrl+F2 (check) → Ctrl+F3 (activate)

---

### Slide 07 — Vòng Đời Lỗi 10 Trạng Thái
**H2:** Vòng Đời Lỗi — 10 Trạng Thái (v5.0)
**Nội dung:** Bảng trạng thái + quy tắc bullet

**Bảng 10 trạng thái:**

| Mã | Tên | Chuyển đến |
| :--- | :--- | :--- |
| `1` | New | Assigned (2), Waiting (W) |
| `2` | Assigned | In Progress (3), Rejected (R) |
| `3` | In Progress | Fixed (5), Suspended (4), Rejected (R) |
| `4` | Suspended | Assigned (2) |
| `5` | Fixed | Final Testing (6), Waiting (W) |
| `6` | Final Testing | Resolved (V), In Progress (3) |
| `V` | Resolved | — (kết thúc) |
| `R` | Rejected | — (kết thúc) |
| `W` | Waiting | Assigned (2), Final Testing (6) |
| `7` | Closed | — (legacy, tương thích ngược) |

**Quy tắc:** STATUS luôn khóa trên màn hình 0300 — chỉ đổi qua Popup 0370

---

### Slide 08 — Engine Tự Động Phân Công
**H2:** Engine Tự Động Phân Công
**Nội dung:** Code block Giai đoạn A + Giai đoạn B

```
Giai đoạn A — Khi tạo lỗi (BUG_TYPE = 'C'):
  SELECT Dev từ ZBUG_USER_PROJEC (role='D', cùng project)
  JOIN ZBUG_USERS (sap_module = bug.module, is_active='X')
  COUNT active bugs (status IN '2','3','4','6') mỗi dev
  → Chọn dev workload thấp nhất VÀ < 5
  ✓ Tìm thấy  → STATUS='2' (Assigned), gửi email
  ✗ Không có  → STATUS='W' (Waiting), báo Manager
```

```
Giai đoạn B — Khi chuyển Fixed (5):
  SELECT Tester từ project (role='T', cùng module)
  COUNT bugs Final Testing đang active
  → Chọn tester workload thấp nhất VÀ < 5
  ✓ Tìm thấy  → VERIFY_TESTER_ID, STATUS='6'
  ✗ Không có  → STATUS='W' (Waiting)
```

---

### Slide 09 — Kiểm Soát Phân Quyền Theo Vai Trò
**H2:** Kiểm Soát Phân Quyền — Screen Groups
**Nội dung:** Bảng screen groups

| Group | Trường bị ảnh hưởng | Điều kiện khóa |
| :--- | :--- | :--- |
| `STS` | STATUS | **Luôn khóa** — chỉ đổi qua popup 0370 |
| `BID` | BUG_ID | Luôn khóa — tự tạo (BUG0000001) |
| `PRJ` | PROJECT_ID | Khóa sau khi đặt từ context dự án |
| `FNC` | BUG_TYPE, PRIORITY, SEVERITY | Khóa với role Developer |
| `DEV` | DEV_ID, VERIFY_TESTER_ID | Khóa với role Tester |
| `TST` | TESTER_ID | Khóa với role Developer |
| `EDT` | Tất cả editable fields | Khóa ở chế độ Display |

**Cơ chế:** `LOOP AT SCREEN ... MODIFY SCREEN` trong module PBO

---

### Slide 10 — Quản Lý Bằng Chứng & Email
**H2:** Quản Lý Bằng Chứng & Thông Báo Email
**Nội dung:** 2 bảng

**Bảng bằng chứng (3 hàng):**

| Template SMW0 | File | Người dùng | Thời điểm |
| :--- | :--- | :--- | :--- |
| `ZBT_TMPL_01` | Bug_report.xlsx | Tester | Khi tạo lỗi |
| `ZBT_TMPL_02` | fix_report.xlsx | Developer | Trước khi → Fixed |
| `ZBT_TMPL_03` | confirm_report.xlsx | Tester | Khi xác nhận Final Testing |

**Bảng email (4 sự kiện):**

| Sự kiện | Người nhận |
| :--- | :--- |
| CREATE | Dev được phân công + Manager |
| ASSIGN / REASSIGN | Dev được phân công |
| STATUS_CHANGE | Dev + Tester liên quan |
| REJECT | Tester báo cáo lỗi |

---

### Slide 11 — Kết Quả UAT Vòng 1
**H2:** Kết Quả UAT Vòng 1 (11–13/04/2026)
**Nội dung:** Bảng kết quả + bảng top bugs

**Bảng tổng hợp:**

| Tổng ca | Đạt | Thất bại | Bị chặn | Tỷ lệ |
| :---: | :---: | :---: | :---: | :---: |
| 64 | 53 | 11 | 0 | 82.8% |

**Top 4 lỗi nghiêm trọng:**

| ID | Mô tả | Mức độ |
| :--- | :--- | :--- |
| UAT-01 | Custom Control không giải phóng → Short dump khi chuyển tab | Critical |
| UAT-09 | Không có ma trận chuyển đổi → cho phép đảo ngược trạng thái | Critical |
| UAT-11 | Manager bypass ma trận — gán trạng thái trực tiếp | Critical |
| UAT-08 | Long text biến mất sau save & reopen | High |

**Footer:** Tất cả 11 lỗi đã sửa trong Giai đoạn F v5.0 (hoàn tất 16/04/2026)

---

### Slide 12 — QC Test Plan Tổng Quan
**H2:** QC Test Plan — 20 Test Suites
**Nội dung:** Bảng suites quan trọng

| TC | Suite | Số ca |
| :--- | :--- | :---: |
| TC-01 | Luồng Điều hướng (tất cả screen transitions) | 20 |
| TC-08 | Chuyển trạng thái (10 TT + Popup 0370) | 30 |
| TC-09 | Engine Tự động Phân công (Phase A + B) | 9 |
| TC-15 | Kiểm soát Truy cập theo Vai trò (RBAC) | 16 |
| TC-11 | Dashboard Metrics (accuracy + refresh) | 12 |
| TC-10 | Bug Search 0210/0220 | 15 |
| TC-19 | Hồi quy — Không tái phát 11 lỗi UAT | 19 |
| TC-20 | Trường hợp Biên & Ranh giới | 20 |
| ... | Các suite còn lại (TC-02 đến TC-18) | ~69 |
| | **Tổng cộng** | **~210** |

**Mục tiêu:** ≥ 95% pass | 0 blocked | UAT Vòng 2 sau deploy

---

### Slide 13 — Timeline 6 Giai Đoạn
**H2:** Timeline Dự Án — 6 Giai Đoạn
**Nội dung:** Bảng giai đoạn

| GĐ | Tên | Kết quả chính | Trạng thái |
| :---: | :--- | :--- | :---: |
| A | Cơ sở CSDL | 5 bảng, domain, number range `ZNRO_BUG` | ✅ Xong |
| B | Logic nghiệp vụ | 6 Function Module | ✅ Xong |
| C | Giao diện Module Pool | 8 màn hình, GUI Status, ALV | ✅ Xong |
| D | Tính năng nâng cao | SmartForms, Excel upload, F4, long text | ✅ Xong |
| E | Kiểm thử | QC 140 ca, UAT 64 ca, 11 bugs tìm thấy | ✅ Xong |
| F | Nâng cao v5.0 | 10-state lifecycle, Popup 0370, Dashboard | ⏳ Deploy chờ |

**Footer:** Code v5.0 hoàn tất 16/04/2026 | Deploy F11–F17 đang chờ thực hiện

---

### Slide 14 — Kế Hoạch Triển Khai v5.0
**H2:** Triển Khai v5.0 — 7 Bước (F11–F17)
**Nội dung:** Bảng bước triển khai

| Bước | Công cụ | Nội dung |
| :--- | :--- | :--- |
| F11 | SE51 | Tạo 4 màn hình mới: 0410, 0370, 0210, 0220 |
| F12 | SE41 | Tạo 4 GUI Status + Title Bar mới; cập nhật STATUS_0200 |
| F13 | SE38 | Copy 6 ABAP includes v5.0: check (Ctrl+F2) + activate (Ctrl+F3) |
| F14 | SE93 | Đổi màn hình ban đầu T-code: 0400 → **0410** |
| F15 | SE11 | Tạo bảng `ZBUG_EVIDENCE` (11 trường, RAWSTRING content) |
| F16 | SE38 | Chạy script migration: `status='6'` → `status='V'` + COMMIT WORK |
| F17 | SMW0 | Upload 3 file mẫu: ZBT_TMPL_01/02/03 |

**Xác minh cuối:** Chạy `/nZBUG_WS` → màn hình 0410 xuất hiện đầu tiên

---

### Slide 15 — Tổng Kết
**H2:** Tổng Kết
**Nội dung:** 2 nhóm bullet (dùng heading H3 thay div)

**Đã đạt được (6 bullets):**
- Bug Tracking chạy native trên SAP — không cần license bổ sung
- Vòng đời 10 trạng thái được thực thi theo vai trò qua Popup 0370
- Auto-assign 2 giai đoạn dựa trên SAP module + workload
- Audit log bất biến — mọi thay đổi ghi vào ZBUG_HISTORY
- Dashboard realtime trên màn hình 0200
- 11 lỗi UAT → sửa hoàn toàn trong v5.0

**Còn lại (4 bullets):**
- Triển khai v5.0 lên SAP (F11–F17)
- Chạy QC Test đầy đủ 20 suites (~210 ca)
- UAT Vòng 2 — xác nhận cuối cùng
- 3 thành viên ký xác nhận chấp thuận

---

### Slide 16 — Q&A (Cover cuối)
**Class:** `title`
**Nội dung:**
- H2: Cảm Ơn & Hỏi Đáp
- Text: ZBUG_WS v5.0 — SAP Bug Tracking Management System
- Text: Nhóm ZBUG | FPT University | Tháng 4 năm 2026

---

## Checklist PPTX-safe

- [x] Không có `<div>`, `<span>` hay bất kỳ HTML tag nào
- [x] Không có `<style scoped>`
- [x] Chỉ dùng Markdown: `#`, `##`, `###`, `-`, `|table|`, ` ```code``` `, `**bold**`, `_italic_`, `> blockquote`
- [x] Mỗi slide tối đa 1 bảng lớn hoặc ~8-10 dòng text
- [x] `<!-- _class: title -->` chỉ dùng cho slide cover/Q&A
- [x] Theme: `workshop` (từ `workshop-theme.css`)
