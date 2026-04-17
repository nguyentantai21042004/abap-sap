---
marp: true
theme: workshop
paginate: true
size: 16:9
---

<!-- _class: title -->

# SAP Bug Tracking Management System

## ZBUG_WS — v5.0

**Nhóm ZBUG** | FPT University Capstone | Tháng 4 năm 2026

---

## Nhóm Dự Án

| Tài khoản | Họ tên | Mã SV | Vai trò | Trách nhiệm chính |
| :--- | :--- | :--- | :--- | :--- |
| `DEV-237` | Nguyễn Ngọc Đức | SE183121 | **Leader** | Vòng đời trạng thái, Auto-Assign, Quản lý Dự án |
| `DEV-089` | Nguyễn Hoàng Anh | SE173545 | Developer | Thiết kế CSDL, logic ABAP lõi, tài liệu |
| `DEV-242` | Nguyễn Hà Linh | SS170495 | Developer | Màn hình Bug Detail (0300), FM tạo & ghi log |
| `DEV-061` | Nguyễn Trọng Hiếu | SE180504 | Developer | Bug List + Dashboard (0200), Search Engine |
| `DEV-118` | Bùi Anh Kha | SE181730 | Tester / QC | Email, Upload bằng chứng, SmartForms, QA |

**Tổng nỗ lực:** ~35 ngày-người | **Hệ thống:** SAP S40, Client 324, ABAP 7.70

---

## Bối Cảnh & Vấn Đề

Triển khai SAP ERP song song nhiều module (MM, SD, FI, CO...) mà **không có công cụ theo dõi lỗi tập trung:**

**Hậu quả thực tế:**

- Báo cáo lỗi phân tán qua bảng tính, email, Zalo
- Developer nhận phân công không rõ ưu tiên hay module
- Manager không thấy phân bổ workload theo thời gian thực
- Không có bằng chứng có cấu trúc về báo cáo & xác nhận sửa lỗi

**Giải pháp — ZBUG_WS:**

- Chạy **native trên SAP** — không cần license bổ sung
- Truy cập qua **1 T-code duy nhất:** `ZBUG_WS`
- Toàn bộ dữ liệu trong bảng ABAP, UI là SAP GUI Dynpro

---

## So Sánh: Hệ Thống Tham Chiếu vs ZBUG_WS

| Tính năng | ZPG (Tham chiếu) | ZBUG_WS v5.0 |
| :--- | :---: | :---: |
| Kiến trúc Module Pool (Type M) | ✗ | ✓ |
| Vòng đời 10 trạng thái + Popup chuyển đổi | ✗ | ✓ |
| Auto-assign theo SAP module / workload | ✗ | ✓ |
| Phân quyền tập trung qua Function Module | ✗ | ✓ |
| Audit log đầy đủ (`ZBUG_HISTORY`) | ✗ | ✓ |
| Thông báo email qua `CL_BCS` | ✗ | ✓ |
| Xuất PDF SmartForm | ✗ | ✓ |
| Dashboard Header realtime | ✗ | ✓ |
| Bug Search Engine (0210/0220) | ✗ | ✓ |
| Module Quản lý Dự án | ✗ | ✓ |

---

## Tổng Quan Hệ Thống — Bản Đồ Màn Hình

| Màn hình | Tên | Mới v5.0 |
| :---: | :--- | :---: |
| **0410** | Tìm kiếm Dự án — điểm vào T-code | ✓ |
| **0400** | Danh sách Dự án (ALV Grid) | |
| **0200** | Bug List + Dashboard Header realtime | ✓ |
| **0300** | Bug Detail — Tab Strip 6 tab | |
| **0370** | Popup Chuyển Trạng Thái (Modal Dialog) | ✓ |
| **0500** | Chi tiết Dự án + phân công người dùng | |
| **0210/0220** | Bug Search — lọc đa trường + kết quả ALV | ✓ |

**Gói:** `ZBUGTRACK` | **Chương trình:** `Z_BUG_WORKSPACE_MP` | **6 ABAP Includes**

---

## Cấu Trúc Code — 6 ABAP Include

| Include | Nội dung |
| :--- | :--- |
| `Z_BUG_WS_TOP` | Khai báo toàn cục, kiểu dữ liệu, hằng số 10 trạng thái |
| `Z_BUG_WS_F00` | Field catalog cho 5 ALV grid, class `LCL_EVENT_HANDLER` |
| `Z_BUG_WS_PBO` | Process Before Output — tất cả 9 màn hình |
| `Z_BUG_WS_PAI` | Process After Input — toàn bộ fcode handler |
| `Z_BUG_WS_F01` | Business Logic: save, change_status, auto_assign, email, history |
| `Z_BUG_WS_F02` | Helper: 10 F4 search help, long text API, SMW0 download |

**Triển khai:** SE38 → paste code → Ctrl+F2 (check) → Ctrl+F3 (activate)

---

## Vòng Đời Lỗi — 10 Trạng Thái (v5.0)

| Mã | Tên | Chuyển đến được |
| :---: | :--- | :--- |
| `1` | New | Assigned (2), Waiting (W) |
| `2` | Assigned | In Progress (3), Rejected (R) |
| `3` | In Progress | Fixed (5), Suspended (4), Rejected (R) |
| `4` | Suspended | Assigned (2) |
| `5` | Fixed | Final Testing (6), Waiting (W) |
| `6` | Final Testing | Resolved (V), In Progress (3) |
| `V` | Resolved | — kết thúc |
| `R` | Rejected | — kết thúc |
| `W` | Waiting | Assigned (2), Final Testing (6) |
| `7` | Closed | — legacy, tương thích ngược |

> **Quy tắc:** STATUS luôn khóa trên màn hình 0300 — chỉ thay đổi qua Popup 0370

---

## Engine Tự Động Phân Công

**Giai đoạn A — Khi tạo lỗi (BUG_TYPE = `C`):**

```
SELECT Dev từ ZBUG_USER_PROJEC (role='D', cùng project)
JOIN ZBUG_USERS WHERE sap_module = bug.module AND is_active='X'
COUNT active bugs (status IN '2','3','4','6') cho mỗi dev
→ Chọn dev có workload thấp nhất VÀ workload < 5
  Tìm thấy  →  STATUS = '2' (Assigned), gửi email
  Không có  →  STATUS = 'W' (Waiting), báo Manager
```

**Giai đoạn B — Khi chuyển sang Fixed (5):**

```
SELECT Tester từ project (role='T', cùng SAP module)
COUNT bugs Final Testing đang active cho mỗi tester
→ Chọn tester workload thấp nhất VÀ workload < 5
  Tìm thấy  →  VERIFY_TESTER_ID, STATUS = '6' (Final Testing)
  Không có  →  STATUS = 'W' (Waiting)
```

---

## Kiểm Soát Phân Quyền — Screen Groups

| Group | Trường bị ảnh hưởng | Điều kiện khóa |
| :---: | :--- | :--- |
| `STS` | STATUS | **Luôn khóa** — chỉ đổi qua Popup 0370 |
| `BID` | BUG_ID | Luôn khóa — tự tạo (`BUG0000001`) |
| `PRJ` | PROJECT_ID | Khóa sau khi đặt từ context dự án |
| `FNC` | BUG_TYPE, PRIORITY, SEVERITY | Khóa với role Developer |
| `DEV` | DEV_ID, VERIFY_TESTER_ID | Khóa với role Tester |
| `TST` | TESTER_ID | Khóa với role Developer |
| `EDT` | Tất cả trường editable | Khóa ở chế độ Display |

**Cơ chế:** `LOOP AT SCREEN ... MODIFY SCREEN` trong module PBO

---

## Quản Lý Bằng Chứng & Thông Báo Email

**Bằng chứng — lưu trong `ZBUG_EVIDENCE` (RAWSTRING):**

| Template SMW0 | File | Người dùng | Thời điểm |
| :--- | :--- | :--- | :--- |
| `ZBT_TMPL_01` | Bug_report.xlsx | Tester | Khi tạo / báo cáo lỗi |
| `ZBT_TMPL_02` | fix_report.xlsx | Developer | Bắt buộc trước khi → Fixed |
| `ZBT_TMPL_03` | confirm_report.xlsx | Tester | Khi xác nhận Final Testing |

**Email tự động — CL_BCS API:**

| Sự kiện | Người nhận |
| :--- | :--- |
| CREATE / ASSIGN | Dev được phân công + Manager |
| STATUS_CHANGE | Dev + Tester liên quan |
| REJECT | Tester báo cáo lỗi ban đầu |

---

## Kết Quả UAT Vòng 1 (11–13/04/2026)

**Tổng quan:**

| Tổng ca | Đạt | Thất bại | Bị chặn | Tỷ lệ đạt |
| :---: | :---: | :---: | :---: | :---: |
| 64 | 53 | **11** | 0 | 82.8% |

**Top 4 lỗi nghiêm trọng nhất:**

| ID | Mô tả | Mức độ |
| :--- | :--- | :--- |
| UAT-01 | Custom Control không giải phóng → Short dump khi chuyển tab | Critical |
| UAT-09 | Không có ma trận chuyển đổi → cho phép đảo ngược trạng thái | Critical |
| UAT-11 | Manager bypass ma trận — gán trạng thái trực tiếp | Critical |
| UAT-08 | Long text biến mất sau khi save & reopen | High |

> Tất cả 11 lỗi đã phân tích nguyên nhân và sửa trong **Giai đoạn F v5.0** (hoàn tất 16/04/2026)

---

## QC Test Plan — 20 Test Suites

| TC | Suite | Số ca |
| :--- | :--- | :---: |
| TC-01 | Luồng Điều hướng (tất cả screen transitions) | 20 |
| TC-08 | Chuyển trạng thái — 10 TT + Popup 0370 | 30 |
| TC-09 | Engine Tự động Phân công (Phase A + B) | 9 |
| TC-15 | Kiểm soát Truy cập theo Vai trò (RBAC) | 16 |
| TC-11 | Dashboard Metrics (accuracy + realtime refresh) | 12 |
| TC-10 | Bug Search 0210/0220 — bộ lọc đa trường | 15 |
| TC-19 | Hồi quy — Xác minh 11 lỗi UAT không tái phát | 19 |
| TC-20 | Trường hợp Biên & Ranh giới | 20 |
| TC-02 đến TC-18 | Các suite còn lại | ~69 |
| | **Tổng cộng (ước tính)** | **~210** |

**Mục tiêu:** ≥ 95% pass | 0 blocked | UAT Vòng 2 sau deploy

---

## Timeline Dự Án — 6 Giai Đoạn

| GĐ | Tên | Kết quả chính | Trạng thái |
| :---: | :--- | :--- | :---: |
| **A** | Cơ sở CSDL | 5 bảng tùy chỉnh, domain, number range | ✅ Xong |
| **B** | Logic nghiệp vụ | 6 Function Module (Create, AutoAssign, Email...) | ✅ Xong |
| **C** | Giao diện Module Pool | 8 màn hình, GUI Status, ALV Grid | ✅ Xong |
| **D** | Tính năng nâng cao | SmartForms, Excel upload, F4, long text API | ✅ Xong |
| **E** | Kiểm thử | QC 140 ca, UAT 64 ca, phát hiện 11 lỗi | ✅ Xong |
| **F** | Nâng cao v5.0 | 10-state lifecycle, Popup 0370, Dashboard | ⏳ Deploy chờ |

**Code v5.0 hoàn tất:** 16/04/2026 | **Deploy F11–F17:** chờ thực hiện

---

## Kế Hoạch Triển Khai v5.0 — 7 Bước

| Bước | Công cụ | Nội dung |
| :--- | :---: | :--- |
| **F11** | SE51 | Tạo 4 màn hình mới: 0410, 0370, 0210, 0220 |
| **F12** | SE41 | Tạo 4 GUI Status + Title Bar; cập nhật STATUS_0200 |
| **F13** | SE38 | Copy 6 ABAP includes v5.0 → check → activate |
| **F14** | SE93 | Đổi màn hình ban đầu: 0400 → **0410** |
| **F15** | SE11 | Tạo bảng `ZBUG_EVIDENCE` (RAWSTRING, 11 trường) |
| **F16** | SE38 | Migration: `status='6'` → `status='V'` + COMMIT WORK |
| **F17** | SMW0 | Upload 3 file mẫu: ZBT_TMPL_01 / 02 / 03 |

**Xác minh:** `/nZBUG_WS` → Màn hình 0410 xuất hiện đầu tiên

---

## Tổng Kết

**Đã đạt được:**

- Hệ thống Bug Tracking chạy **native trên SAP** — không cần license bổ sung
- Vòng đời **10 trạng thái** được thực thi theo vai trò qua Popup 0370
- **Auto-assign 2 giai đoạn** dựa trên SAP module + workload
- **Audit log bất biến** — mọi thay đổi ghi vào `ZBUG_HISTORY`
- **Dashboard realtime** trên màn hình 0200
- **11 lỗi UAT** → phân tích và sửa hoàn toàn trong v5.0

**Còn lại:**

- Triển khai v5.0 lên SAP (F11–F17)
- Chạy QC Test đầy đủ 20 suites (~210 ca)
- UAT Vòng 2 → 3 thành viên ký xác nhận chấp thuận

---

<!-- _class: title -->

## Cảm Ơn & Hỏi Đáp

**ZBUG_WS v5.0** — SAP Bug Tracking Management System

_Nhóm ZBUG | FPT University | Tháng 4 năm 2026_
