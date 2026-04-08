# CONTEXT & STATUS — Z_BUG_WORKSPACE_MP

> **Cập nhật lần cuối:** 09/04/2026 (session 2)
> **Mục đích:** File này dùng để handoff giữa các agent/session. Đọc file này trước khi làm bất cứ thứ gì với dự án.

---

## 1. DỰ ÁN LÀ GÌ?

Hệ thống **Bug Tracking tập trung** chạy trên SAP ERP bằng ABAP thuần túy.
- **SAP System:** S40, Client 324, ABAP 770
- **Package:** `ZBUGTRACK`
- **T-code entry point:** `ZBUG_HOME`

Dự án đang ở **Phase 3: Module Pool Integration** — chuyển toàn bộ UI từ SE38 Selection Screen sang Dynpro Module Pool, thêm Project entity, chuẩn hóa 9-state bug lifecycle.

---

## 2. CHƯƠNG TRÌNH MẪU THAM CHIẾU

Có 2 chương trình mẫu trong repo (tham khảo để hiểu pattern):

| Thư mục | Program | Vai trò |
|---------|---------|---------|
| `ZPG_BUGTRACKING_MAIN/` | `ZPG_BUGTRACKING_MAIN` | Bug List + Project List ALV, Selection Screen |
| `ZPG_BUGTRACKING_DETAIL/` | `ZPG_BUGTRACKING_DETAIL` | Bug/Project Detail + Tab Strip + Evidence upload |

**Mục tiêu:** Chương trình `Z_BUG_WORKSPACE_MP` của mình phải **ngang hàng hoặc tốt hơn** 2 chương trình này về:
- Cấu trúc Module Pool (Dynpro thay Selection Screen)
- Tab Strip đầy đủ (Bug Detail + Project Detail)
- ALV Grid với hotspot, color coding, toolbar
- Permission logic chi tiết hơn (9-state + Project membership)
- GOS file attachment thay ZTB_EVD approach

---

## 3. KIẾN TRÚC MỤC TIÊU

```
Program: Z_BUG_WORKSPACE_MP (Module Pool, Type M)
│
├── Include: Z_BUG_WS_TOP   → Global declarations, types, ALV objects
├── Include: Z_BUG_WS_F00   → ALV field catalog + LCL_EVENT_HANDLER class
├── Include: Z_BUG_WS_PBO   → Process Before Output modules
├── Include: Z_BUG_WS_PAI   → Process After Input modules (user commands)
├── Include: Z_BUG_WS_F01   → Business logic FORMs (SQL, save, history...)
└── Include: Z_BUG_WS_F02   → Helpers: F4, Long Text, Popup, GOS
│
├── Screen 0100  → Hub / Router (chọn Bug List hoặc Project List)
├── Screen 0200  → Bug List (ALV Grid, toolbar theo role)
├── Screen 0300  → Bug Detail (Tab Strip, 6 subscreens)
│   ├── Subscreen 0310  → Tab: Bug Info (fields chính)
│   ├── Subscreen 0320  → Tab: Description (Long Text)
│   ├── Subscreen 0330  → Tab: Dev Note (Long Text)
│   ├── Subscreen 0340  → Tab: Tester Note (Long Text)
│   ├── Subscreen 0350  → Tab: Evidence (GOS attachment)
│   └── Subscreen 0360  → Tab: History (ALV readonly)
├── Screen 0400  → Project List (ALV Grid)
└── Screen 0500  → Project Detail + User Assignment (Table Control)
```

**Tables:**
| Table | Status | Fields |
|-------|--------|--------|
| `ZBUG_TRACKER` | Cập nhật (+13 fields) | +PROJECT_ID, SEVERITY, VERIFY_TESTER_ID, IS_DEL, ERNAM/DAT/ZET, AENAM/DAT/ZET |
| `ZBUG_USERS` | Cập nhật (+4 fields) | +AENAM/DAT/ZET, IS_DEL |
| `ZBUG_PROJECT` | **Tạo mới** | 16 fields |
| `ZBUG_USER_PROJEC` | **Tạo mới** | 9 fields (M:N User↔Project) |
| `ZBUG_HISTORY` | Giữ nguyên | Chang log |

**9-State Bug Lifecycle:**
```
New(1) → Assigned(2) → InProgress(3) → Pending(4) → Fixed(5) → Resolved(6) → Closed(7)
       ↘ Waiting(W) [tự động khi không có Dev rảnh]
                                       ↘ Rejected(R) [Dev từ chối]
```

---

## 4. TRẠNG THÁI TRIỂN KHAI (09/04/2026)

### PHASE A — DATABASE HARDENING

| Bước | Nội dung | Status |
|------|---------|--------|
| A1 | Tạo 4 Domains mới (`ZDOM_PROJECT_ID`, `ZDOM_PRJ_STATUS`, `ZDOM_SEVERITY`, `ZDOM_IS_DEL`) | ✅ Xong |
| A1 | Tạo 6 Data Elements mới (`ZDE_PROJECT_ID`, `ZDE_PRJ_NAME`, etc.) | ✅ Xong |
| A2 | Tạo bảng `ZBUG_PROJECT` (16 fields) | ✅ Xong |
| A3 | Tạo bảng `ZBUG_USER_PROJEC` (9 fields) | ✅ Xong |
| A4 | Update `ZBUG_TRACKER` (+13 fields + SE14 Adjust) | ✅ Xong |
| A4 | Chạy backfill script `Z_BUG_BACKFILL_AUDIT` | ✅ Xong |
| A5 | Update `ZBUG_USERS` (+4 fields) | ✅ Xong |
| A6 | Tạo Message Class `ZBUG_MSG` (33 messages, EN+VI) | ✅ Xong |
| A7 | Tạo Text Object `ZBUG` (3 Text IDs: Z001/Z002/Z003) | ✅ Xong |
| A8 | Chạy migration report `Z_BUG_MIGRATE_STATUS` (1 lần duy nhất) | ✅ Xong |

### PHASE B — BUSINESS LOGIC UPDATE

| Bước | Nội dung | Status |
|------|---------|--------|
| B1 | Mở rộng `Z_BUG_CHECK_PERMISSION` (thêm IV_PROJECT_ID + membership check) | ❓ Chưa xác nhận |
| B2 | Cập nhật `Z_BUG_CREATE` (thêm PROJECT_ID + SEVERITY params) | ❓ Chưa xác nhận |
| B3 | Rewrite `Z_BUG_UPDATE_STATUS` (full 9-state transition validation) | ❓ Chưa xác nhận |
| B4 | GOS File Storage Integration | ❓ Chưa xác nhận |
| B5 | Tạo SmartForm `ZBUG_EMAIL_FORM` | ❓ Chưa xác nhận |
| B6 | Cập nhật `Z_BUG_SEND_EMAIL` | ❓ Chưa xác nhận |
| B7 | Soft delete logic trong tất cả FMs | ❓ Chưa xác nhận |
| B8 | Cập nhật `Z_BUG_AUTO_ASSIGN` (IS_DEL + project filter + Waiting fallback) | ❓ Chưa xác nhận |
| B9 | Tạo mới FM `Z_BUG_REASSIGN` | ❓ Chưa xác nhận |

### PHASE C — MODULE POOL UI ← **ĐANG LÀM**

| Bước | Nội dung | Status |
|------|---------|--------|
| C1 | Tạo program `Z_BUG_WORKSPACE_MP` (Type M) + 6 includes | ✅ **Đã tạo** |
| C2 | Code include `Z_BUG_WS_TOP` | 🔄 Đang gõ |
| C3 | Screen 0100 (Hub/Router) | 🔄 Một phần |
| C4 | Screen 0200 + `Z_BUG_WS_F01` (Bug List + select_bug_data) | 🔴 **Lỗi line 267** — chưa fix |
| C5 | Screen 0300 (Tab Strip, 6 subscreens 0310-0360) | 🔄 Một phần |
| C6 | Screen 0400 (Project List) | ❓ Chưa rõ |
| C7 | Screen 0500 (Project Detail + Table Control) | ❓ Chưa rõ |
| C8 | GUI Status (SE41): STATUS_0100/0200/0300/0400/0500 | ❓ Chưa rõ |
| C9 | F4 Search Help + History Tab ALV | ❓ Chưa rõ |
| C10 | POPUP_TO_CONFIRM + ALV Color-Coding | ❓ Chưa rõ |
| C11 | Deprecate T-codes cũ (ZBUG_CREATE, ZBUG_LIST...) | ❌ Chưa làm |

### PHASE D — EXCEL & ADVANCED FEATURES

| Bước | Nội dung | Status |
|------|---------|--------|
| D1 | Excel Template trên SMW0 (`ZTEMPLATE_PROJECT.xlsx`) | ❌ Chưa làm |
| D2 | Download Template Button | ❌ Chưa làm |
| D3 | Upload Excel Logic (`TEXT_CONVERT_XLS_TO_SAP`) | ❌ Chưa làm |
| D4 | Message Class Migration (đồng bộ hardcoded → ZBUG_MSG) | ❌ Chưa làm |
| D5 | Dashboard Statistics (Optional) | ❌ Chưa làm |

### PHASE E — TESTING & GO-LIVE

| Bước | Nội dung | Status |
|------|---------|--------|
| E1 | Chuyển T-code `ZBUG_HOME` → `Z_BUG_WORKSPACE_MP` Screen 0100 | ❌ Chưa làm |
| E2 | Unit Test — từng Function Module trong SE37 | ❌ Chưa làm |
| E3 | Integration Test — Full Workflow (tất cả 9 paths) | ❌ Chưa làm |
| E4 | Permission Matrix Test (Tester/Dev/Manager) | ❌ Chưa làm |
| E5 | Feature-Specific Tests (GOS, Long Text, Email, Excel) | ❌ Chưa làm |
| E6 | Clean Test Data + Demo Day Rehearsal | ❌ Chưa làm |

---

## 5. LỖI ĐANG GẶP — SYNTAX_ERROR

### Thông tin lỗi (từ screenshot 07/04/2026)

```
Category  : ABAP programming error
Error     : SYNTAX_ERROR
Program   : Z_BUG_WORKSPACE_MP
Include   : Z_BUG_WS_F01  ← file CODE_F01.md
Line      : 267
```

### Mô tả lỗi

```
In PERFORM or CALL FUNCTION "ADD_HISTORY_ENTRY",
the actual parameter "GS_BUG_DETAIL-STATUS" is incompatible
with the formal parameter "PV_OLD"
```

### Nguyên nhân

Trong `Z_BUG_WS_F01`, line 267 là call sau:
```abap
PERFORM add_history_entry USING gv_current_bug_id 'ST' gs_bug_detail-status ls_field-value 'Status updated via popup'.
```

FORM `add_history_entry` được định nghĩa trong CODE_F01.md như sau:
```abap
FORM add_history_entry USING pv_bug_id TYPE zde_bug_id
                           pv_type   TYPE char2
                           pv_old          ← untyped (generic)
                           pv_new          ← untyped (generic)
                           pv_reason.
```

**Vấn đề:** Nếu người dùng đã type `pv_old` thành một kiểu cụ thể (ví dụ `TYPE char50`) thì `GS_BUG_DETAIL-STATUS` (CHAR1) có thể không pass được do **CHAR1 → CHAR50 incompatible by reference**. Hoặc nếu define `USING VALUE(pv_old) TYPE string`, CHAR1 cũng sẽ incompatible.

### Cách fix

**Option 1 (khuyến nghị):** Đảm bảo `pv_old` và `pv_new` là **untyped** trong FORM definition:
```abap
FORM add_history_entry USING pv_bug_id TYPE zde_bug_id
                             pv_type   TYPE char2
                             pv_old                    " KHÔNG có TYPE → generic
                             pv_new                    " KHÔNG có TYPE → generic
                             pv_reason.
```

**Option 2:** Dùng biến trung gian khi call:
```abap
DATA: lv_old_status TYPE string,
      lv_new_status TYPE string.
lv_old_status = gs_bug_detail-status.
lv_new_status = ls_field-value.
PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_status lv_new_status 'Status updated via popup'.
```

**Option 3:** Type tất cả params là `TYPE string` (nhất quán nhất):
```abap
FORM add_history_entry USING pv_bug_id TYPE zde_bug_id
                             pv_type   TYPE char2
                             pv_old    TYPE string
                             pv_new    TYPE string
                             pv_reason TYPE string.
```
Khi gọi thì convert trước: `CONV string( gs_bug_detail-status )`.

---

## 6. CODE GUIDES — VỊ TRÍ & CÁCH DÙNG

Tất cả code đã được soạn sẵn trong `analysis/guides/`, copy thẳng vào SAP:

| File guide | Copy vào SAP include | T-code |
|-----------|---------------------|--------|
| `CODE_TOP.md` | `Z_BUG_WS_TOP` | SE80 |
| `CODE_F00.md` | `Z_BUG_WS_F00` | SE80 |
| `CODE_F01.md` | `Z_BUG_WS_F01` | SE80 |
| `CODE_F02.md` | `Z_BUG_WS_F02` | SE80 |
| `CODE_PBO.md` | `Z_BUG_WS_PBO` | SE80 |
| `CODE_PAI.md` | `Z_BUG_WS_PAI` | SE80 |
| `phase-a-database.md` | Step-by-step SE11/SE91/SE75 | SE11 |
| `phase-b-business-logic.md` | Step-by-step SE37 FM updates | SE37 |
| `phase-c-module-pool.md` | Step-by-step SE80 screens | SE80 |
| `phase-d-advanced-features.md` | Excel/Email | SMW0, SE37 |
| `phase-e-testing.md` | T-code + UAT | SE93 |

> **Thứ tự include bắt buộc trong main program:**
> ```abap
> PROGRAM z_bug_workspace_mp.
> INCLUDE z_bug_ws_top.    " 1. Global data
> INCLUDE z_bug_ws_f00.    " 2. Event class (PHẢI trước PBO/PAI)
> INCLUDE z_bug_ws_pbo.    " 3. PBO
> INCLUDE z_bug_ws_pai.    " 4. PAI
> INCLUDE z_bug_ws_f01.    " 5. Business logic
> INCLUDE z_bug_ws_f02.    " 6. Helpers
> ```

---

## 7. ĐIỂM KHÁC BIỆT SO VỚI CHƯƠNG TRÌNH MẪU (ZPG_BUGTRACKING_*)

| Tính năng | ZPG_BUGTRACKING_* (mẫu) | Z_BUG_WORKSPACE_MP (target) |
|-----------|------------------------|------------------------------|
| Status model | ~5 states đơn giản | **9 states** với transition validation |
| Project entity | `ZTB_PROJECT` | `ZBUG_PROJECT` + `ZBUG_USER_PROJEC` (M:N) |
| File attachment | `ZTB_EVD` (table tự tạo) | **GOS** (Generic Object Services — SAP standard) |
| Email | Không rõ | SmartForm + CL_BCS |
| Permission | Role check cơ bản | Role + Project membership check |
| Long Text | SAVE_TEXT (SAPScript) | Text Object `ZBUG` (Z001/Z002/Z003) |
| History | Có | Có + filter theo Action Type/Date |
| Soft Delete | Không có (hard delete) | `IS_DEL = 'X'` trên tất cả entities |
| Auto-assign | Không có | Có (workload-based + Waiting fallback) |
| Severity | Không có | 5 levels (Dump/VeryHigh/High/Normal/Minor) |
| Multi-language | Không có | Message Class `ZBUG_MSG` (EN + VI) |

---

## 8. THÔNG TIN HỆ THỐNG & ACCOUNTS

| Account | Password | Quyền |
|---------|----------|-------|
| `DEV-089` | `@Anhtuoi123` | SE11, SE38, SE80, SE93 — account chính |
| `DEV-061` | `@57Dt766` | ALV Grid & SmartForms |
| `DEV-118` | `Qwer123@` | Quản lý lỗi, Testing |
| `DEV-242` | `12345678` | Email config (SCOT, SOST) |
| `DEV-237` | `toiyeufpt` | GOS attachments |

**SAP System:** S40 | **Client:** 324 | **Network:** EBS_SAP

---

## 9. CHECKLIST TRƯỚC KHI TIẾP TỤC (Next session)

Câu hỏi cần xác nhận với user trước khi code thêm:

- [x] Phase A đã làm xong chưa? (Tables có trong SE11 không?) → **Xong hoàn toàn**
- [x] Migration script `Z_BUG_MIGRATE_STATUS` đã chạy chưa? → **Xong**
- [x] Message Class `ZBUG_MSG` đã có trong SE91 chưa? → **Xong**
- [ ] Syntax error ở line 267 đã được fix chưa? → **Chưa fix** — xem Section 5
- [ ] Các screens (0100-0500) đã tạo trong SE80 chưa? → **Một phần**
- [ ] GUI Status trong SE41 đã tạo chưa? → Chưa xác nhận

---

*File này được tạo bởi OpenCode agent ngày 09/04/2026. Cập nhật mỗi khi hoàn thành một bước hoặc phát hiện issue mới.*
