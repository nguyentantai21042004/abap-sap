# Status Lifecycle & Role-Based Permissions — Z_BUG_WORKSPACE_MP

> **Version:** v5.0 | **Cập nhật:** 13/04/2026
> **Mục đích:** Tài liệu chính thức mô tả vòng đời trạng thái Bug, Project, phân quyền theo vai trò.
> **Đây là tài liệu QUAN TRỌNG NHẤT** — mọi code thay đổi status/transition/permission phải tuân theo file này.

---

## 1. HỆ THỐNG VAI TRÒ (ROLE SYSTEM)

Vai trò được xác định từ bảng `ZBUG_USERS`, field `ROLE` (CHAR 1):

| Code | Vai trò | Mô tả |
|------|---------|-------|
| `M` | **Manager** | Quản lý dự án, gán task, kiểm soát toàn bộ |
| `D` | **Developer** | Nhận bug, sửa lỗi, upload bằng chứng |
| `T` | **Tester** | Báo lỗi, kiểm thử, xác nhận kết quả |

### Vai trò trong context dự án (ZBUG_USER_PROJEC):

Mỗi user được gán vào project với một ROLE cụ thể. Cùng 1 user có thể là Manager ở project A nhưng Developer ở project B.

**Bảng `ZBUG_USER_PROJEC`** lưu mapping User ↔ Project ↔ Role:
- Key: `MANDT + USER_ID + PROJECT_ID`
- Field `ROLE` (CHAR 1): M/D/T

### Xác định role khi login:

```abap
SELECT SINGLE role FROM zbug_users INTO @gv_role
  WHERE user_id = @sy-uname AND is_del <> 'X' AND is_active = 'X'.
```

---

## 2. VÒNG ĐỜI BUG (BUG STATUS LIFECYCLE)

### 2.1. Danh sách trạng thái (10 states)

| Code | Tên | Hằng số ABAP | Mô tả |
|------|-----|-------------|-------|
| `1` | **New** | `gc_st_new` | Bug vừa được tạo bởi Tester/Manager |
| `W` | **Waiting** | `gc_st_waiting` | Không tìm được Dev/Tester phù hợp → đợi Manager gán thủ công |
| `2` | **Assigned** | `gc_st_assigned` | Đã gán cho Developer (thủ công hoặc auto) |
| `3` | **In Progress** | `gc_st_inprogress` | Developer đang xử lý |
| `4` | **Pending** | `gc_st_pending` | Tạm dừng (cần thêm info, blocked, etc.) |
| `5` | **Fixed** | `gc_st_fixed` | Developer đã sửa xong, đợi kiểm thử |
| `R` | **Rejected** | `gc_st_rejected` | Developer từ chối (không phải bug, duplicate, etc.) |
| `6` | **Final Testing** | `gc_st_finaltesting` | Final Tester đang kiểm tra lại |
| `V` | **Resolved** | `gc_st_resolved` | Final Tester xác nhận bug đã fix xong — **TRẠNG THÁI KẾT THÚC** |
| `7` | **Closed** | `gc_st_closed` | Legacy — giữ cho backward compatibility |

### 2.2. Sơ đồ chuyển trạng thái (State Machine)

```
                          ┌──────────┐
              Auto-assign │          │ Manager gán
  ┌─────────────────────▶│ Assigned │◀─────────────────┐
  │        (có Dev)       │   (2)    │                  │
  │                       └────┬─────┘                  │
  │                            │                        │
  │                    Dev nhận │                        │
  │                            ▼                        │
┌─┴───┐              ┌────────────────┐          ┌──────┴──┐
│ New │──Auto-assign─▶│  In Progress   │◀────────│ Pending │
│ (1) │  (có Dev)     │     (3)        │ Manager │   (4)   │
└──┬──┘               └──┬──────┬──┬──┘ reassign └─────────┘
   │                     │      │  │                  ▲
   │ Auto-assign         │      │  │                  │
   │ (ko có Dev)         │      │  └──────────────────┘
   ▼                     │      │         Dev tạm dừng
┌─────────┐              │      │
│ Waiting │              │      │
│  (W)    │──Manager────▶│      │
└─────────┘   gán        │      │
   │                     │      │
   │ Manager ───────────▶│      ▼
   │ (sang Final Test)   │  ┌───────┐
   │                     │  │ Fixed │ ── Dev upload evidence
   │                     │  │  (5)  │
   │                     │  └───┬───┘
   │                     │      │
   │                     │      │ Auto-assign Tester
   │                     │      ▼
   │                     │  ┌──────────────┐
   │                     │  │Final Testing │
   │                     └─▶│     (6)      │◀── Manager gán từ Waiting
   │                        └──┬───────┬───┘
   │                           │       │
   │               Test PASS   │       │ Test FAIL
   │                           ▼       ▼
   │                    ┌──────────┐  (quay lại In Progress 3)
   │                    │ Resolved │
   │                    │   (V)    │ ← TRẠNG THÁI KẾT THÚC
   │                    └──────────┘
   │
   │           ┌──────────┐
   └──────────▶│ Rejected │ ← Developer từ chối (cần ghi lý do)
               │   (R)    │
               └──────────┘
```

### 2.3. Bảng chuyển trạng thái chi tiết (Transition Matrix)

| Trạng thái hiện tại | Chuyển được sang | Ai có quyền | Điều kiện bắt buộc |
|---------------------|-----------------|-------------|-------------------|
| **1 — New** | 2 (Assigned) | Manager | `DEVELOPER_ID` bắt buộc nhập |
| **1 — New** | W (Waiting) | Manager | — |
| **W — Waiting** | 2 (Assigned) | Manager | `DEVELOPER_ID` bắt buộc |
| **W — Waiting** | 6 (Final Testing) | Manager | `DEVELOPER_ID` + `FINAL_TESTER_ID` bắt buộc |
| **2 — Assigned** | 3 (In Progress) | Developer (được gán) / Manager | — |
| **2 — Assigned** | R (Rejected) | Developer (được gán) / Manager | `TRANS_NOTE` bắt buộc (lý do từ chối) → lưu vào Dev Note (Z002) |
| **3 — In Progress** | 5 (Fixed) | Developer (được gán) / Manager | **Evidence bắt buộc** (file upload) |
| **3 — In Progress** | 4 (Pending) | Developer (được gán) / Manager | — |
| **3 — In Progress** | R (Rejected) | Developer (được gán) / Manager | `TRANS_NOTE` bắt buộc |
| **4 — Pending** | 2 (Assigned) | Manager | `DEVELOPER_ID` bắt buộc (có thể đổi Dev mới) |
| **5 — Fixed** | 6 (Final Testing) | **Tự động** (auto-assign Tester) | Nếu không có Tester → W (Waiting) |
| **6 — Final Testing** | V (Resolved) | Final Tester (được gán) / Manager | `TRANS_NOTE` bắt buộc (ghi kết quả test) |
| **6 — Final Testing** | 3 (In Progress) | Final Tester (được gán) / Manager | `TRANS_NOTE` bắt buộc (lý do fail) |

### 2.4. Popup chuyển trạng thái — Field Matrix (Screen 0370)

Khi user nhấn "Change Status" trên Bug Detail (Screen 0300), popup Screen 0370 hiện ra với các field:

**Read-only fields (luôn hiển thị):**
- `BUG_ID` + `TITLE`
- `REPORTER` (tester_id)
- `CURRENT_STATUS` + `CURRENT_STATUS_TEXT`

**Input fields (enable/disable theo trạng thái hiện tại):**

| Trạng thái hiện tại | NEW_STATUS | DEVELOPER_ID | FINAL_TESTER_ID | TRANS_NOTE | BTN_UPLOAD |
|---------------------|-----------|-------------|----------------|-----------|-----------|
| 1 — New | Dropdown: 2, W | **MỞ** (bắt buộc nếu →2) | KHÓA | KHÓA | KHÓA |
| W — Waiting | Dropdown: 2, 6 | **MỞ** (bắt buộc) | **MỞ** (bắt buộc nếu →6) | KHÓA | KHÓA |
| 2 — Assigned | Dropdown: 3, R | KHÓA | KHÓA | **MỞ** (bắt buộc nếu →R) | KHÓA |
| 3 — In Progress | Dropdown: 5, 4, R | KHÓA | KHÓA | **MỞ** (ghi giải pháp) | **MỞ** (bắt buộc nếu →5) |
| 4 — Pending | Dropdown: 2 | **MỞ** (bắt buộc, có thể đổi Dev) | KHÓA | KHÓA | KHÓA |
| 6 — Final Testing | Dropdown: V, 3 | KHÓA | KHÓA | **MỞ** (kết quả test) | KHÓA |

### 2.5. Hệ thống Auto-Assign

#### Giai đoạn A: Bug mới tạo (1 → 2 hoặc W)

```
Trigger: Bug mới tạo (status = 1)
  │
  ├── Lấy danh sách Developer từ ZBUG_USER_PROJEC
  │     WHERE project_id = bug.project_id
  │       AND role = 'D'
  │
  ├── Lọc theo Module: user.sap_module = bug.sap_module (INNER JOIN ZBUG_USERS)
  │
  ├── Tính workload: COUNT bugs WHERE dev_id = user AND status IN (2,3,4,6)
  │
  ├── Chọn: workload thấp nhất VÀ < 5
  │
  ├── CÓ người phù hợp:
  │     → Set DEV_ID = user
  │     → Status: 1 → 2 (Assigned)
  │     → Log history
  │
  └── KHÔNG CÓ ai:
        → Status: 1 → W (Waiting)
        → Log history
        → Thông báo cho Manager
```

#### Giai đoạn B: Bug Fixed (5 → 6 hoặc W)

```
Trigger: Developer chuyển status sang 5 (Fixed) qua popup Screen 0370
  │
  ├── Lấy danh sách Tester từ ZBUG_USER_PROJEC
  │     WHERE project_id = bug.project_id
  │       AND role = 'T'
  │
  ├── Lọc theo Module: user.sap_module = bug.sap_module (INNER JOIN ZBUG_USERS)
  │
  ├── Tính workload: COUNT bugs WHERE verify_tester_id = user AND status = 6
  │
  ├── Chọn: workload thấp nhất VÀ < 5
  │
  ├── CÓ người phù hợp:
  │     → Set VERIFY_TESTER_ID = user
  │     → Status: 5 → 6 (Final Testing)
  │     → Log history
  │
  └── KHÔNG CÓ ai:
        → Status: 5 → W (Waiting)
        → Log history
        → Thông báo cho Manager
```

---

## 3. VÒNG ĐỜI DỰ ÁN (PROJECT STATUS LIFECYCLE)

### 3.1. Danh sách trạng thái (4 states)

| Code | Tên | Mô tả |
|------|-----|-------|
| `1` | **Opening** | Dự án mới tạo, đang chuẩn bị |
| `2` | **In Process** | Đang thực hiện |
| `3` | **Done** | Hoàn thành — chỉ khi TẤT CẢ bugs Resolved/Closed |
| `4` | **Cancelled** | Hủy bỏ |

### 3.2. Sơ đồ chuyển trạng thái

```
┌──────────┐     Manager      ┌──────────────┐     Manager     ┌────────┐
│ Opening  │ ───────────────▶ │ In Process   │ ──────────────▶ │  Done  │
│   (1)    │                  │    (2)       │  (all bugs OK)  │  (3)   │
└──────────┘                  └──────┬───────┘                 └────────┘
                                     │
                              Manager│
                                     ▼
                              ┌──────────────┐
                              │  Cancelled   │
                              │    (4)       │
                              └──────────────┘
```

### 3.3. Quy tắc chuyển trạng thái

| Từ | Sang | Ai có quyền | Điều kiện |
|----|------|-------------|-----------|
| 1 (Opening) | 2 (In Process) | Manager | — |
| 2 (In Process) | 3 (Done) | Manager | Tất cả bug phải Resolved (`V`) hoặc Closed (`7`) |
| 2 (In Process) | 4 (Cancelled) | Manager | — |
| 3 (Done) | 2 (In Process) | Manager | Reopen project nếu phát hiện bug mới |
| 1 (Opening) | 4 (Cancelled) | Manager | — |

### 3.4. Validation logic:

```abap
" Block Done if open bugs
IF gs_project-project_status = '3'. " Done
  SELECT COUNT(*) FROM zbug_tracker INTO @lv_open_bugs
    WHERE project_id = @gs_project-project_id
      AND is_del <> 'X'
      AND status <> @gc_st_resolved
      AND status <> @gc_st_closed
      AND status <> @gc_st_rejected.
  IF lv_open_bugs > 0.
    MESSAGE |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed.|
      TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDIF.
```

---

## 4. PHÂN QUYỀN THEO VAI TRÒ (ROLE-BASED ACCESS MATRIX)

### 4.1. Quyền trên Project

| Hành động | Manager (M) | Developer (D) | Tester (T) |
|-----------|:-----------:|:-------------:|:----------:|
| Xem tất cả Project | ✅ | ❌ (chỉ assigned) | ❌ (chỉ assigned) |
| Tạo Project | ✅ | ❌ | ❌ |
| Sửa Project | ✅ | ❌ | ❌ |
| Xóa Project | ✅ | ❌ | ❌ |
| Add/Remove User | ✅ | ❌ | ❌ |
| Upload Excel | ✅ | ❌ | ❌ |
| Download Template | ✅ | ❌ | ❌ |

### 4.2. Quyền trên Bug

| Hành động | Manager (M) | Developer (D) | Tester (T) |
|-----------|:-----------:|:-------------:|:----------:|
| Xem tất cả Bug | ✅ | ❌ (chỉ assigned) | ❌ (chỉ created/verify) |
| Tạo Bug | ✅ | ❌ | ✅ |
| Xóa Bug | ✅ | ❌ | ❌ |
| Sửa Bug Info | ✅ | ✅ (hạn chế) | ✅ (hạn chế) |
| Change Status | Theo matrix | Theo matrix | Theo matrix |
| Upload Evidence | ✅ | ✅ (Fix file) | ✅ (Report file) |
| Delete Evidence | ✅ | ✅ | ✅ |
| Send Email | ✅ | ✅ | ✅ |
| Download Templates | ✅ | ❌ | ✅ |

### 4.3. Quyền sửa Bug Info fields theo vai trò

| Field | Manager | Developer | Tester |
|-------|:-------:|:---------:|:------:|
| BUG_ID | ❌ (auto) | ❌ | ❌ |
| PROJECT_ID | ❌ (locked) | ❌ | ❌ |
| TITLE | ✅ | ✅ | ✅ |
| DESC_TEXT | ✅ | ✅ | ✅ |
| SAP_MODULE | ✅ | ❌ (FNC group) | ✅ |
| BUG_TYPE | ✅ | ❌ (FNC group) | ✅ |
| PRIORITY | ✅ | ❌ (FNC group) | ✅ |
| SEVERITY | ✅ | ❌ (FNC group) | ✅ |
| STATUS | ❌ (chỉ qua popup 0370) | ❌ (chỉ qua popup 0370) | ❌ (chỉ qua popup 0370) |
| TESTER_ID | ✅ | ❌ (TST group) | ❌ (auto) |
| DEV_ID | ✅ | ❌ | ❌ |
| VERIFY_TESTER_ID | ✅ | ❌ | ❌ |

### 4.4. Screen Group ↔ Role mapping

| Screen Group | Fields | Manager | Developer | Tester |
|-------------|--------|:-------:|:---------:|:------:|
| `EDT` | All editable fields | ✅ Edit | ✅ Edit | ✅ Edit |
| `BID` | BUG_ID | ❌ Always locked | ❌ | ❌ |
| `PRJ` | PROJECT_ID | ❌ Locked from project context | ❌ | ❌ |
| `PID` | PROJECT_ID (on Screen 0500) | ❌ Always locked | ❌ | ❌ |
| `FNC` | BUG_TYPE, PRIORITY, SEVERITY | ✅ Edit | ❌ Locked | ✅ Edit |
| `TST` | Tester-specific fields | ✅ Edit | ❌ Locked | ✅ Edit |
| `DEV` | Developer-specific fields | ✅ Edit | ✅ Edit | ❌ Locked |
| `STS` | STATUS field | ❌ Always locked (use popup) | ❌ | ❌ |

---

## 5. EVIDENCE / BẰNG CHỨNG

### 5.1. Loại file theo giai đoạn

| Template SMW0 | Tên download | Giai đoạn | Ai upload |
|--------------|-------------|-----------|-----------|
| `ZBT_TMPL_01` | Bug_report.xlsx | Tạo bug / Báo cáo lỗi | Tester |
| `ZBT_TMPL_02` | fix_report.xlsx | Dev xác nhận đã fix | Developer |
| `ZBT_TMPL_03` | confirm_report.xlsx | Final Tester xác nhận | Final Tester |

### 5.2. Kiểm tra Evidence trước khi chuyển trạng thái

| Chuyển sang | Điều kiện |
|-------------|----------|
| 5 (Fixed) | Evidence file bất kỳ (COUNT > 0 từ ZBUG_EVIDENCE) |
| 6 (Final Testing) | Tự động (auto-assign Tester) |
| V (Resolved) | `TRANS_NOTE` bắt buộc |
| R (Rejected) | `TRANS_NOTE` bắt buộc (lý do từ chối) |

---

## 6. ABAP CONSTANTS

```abap
CONSTANTS:
  gc_st_new          TYPE zde_bug_status VALUE '1',       " New
  gc_st_assigned     TYPE zde_bug_status VALUE '2',       " Assigned
  gc_st_inprogress   TYPE zde_bug_status VALUE '3',       " In Progress
  gc_st_pending      TYPE zde_bug_status VALUE '4',       " Pending
  gc_st_fixed        TYPE zde_bug_status VALUE '5',       " Fixed
  gc_st_finaltesting TYPE zde_bug_status VALUE '6',       " Final Testing
  gc_st_closed       TYPE zde_bug_status VALUE '7',       " Closed (legacy)
  gc_st_waiting      TYPE zde_bug_status VALUE 'W',       " Waiting
  gc_st_rejected     TYPE zde_bug_status VALUE 'R',       " Rejected
  gc_st_resolved     TYPE zde_bug_status VALUE 'V'.       " Resolved (terminal state)
```

### Status text mapping:

```abap
SWITCH #( <status>
  WHEN gc_st_new          THEN 'New'
  WHEN gc_st_assigned     THEN 'Assigned'
  WHEN gc_st_inprogress   THEN 'In Progress'
  WHEN gc_st_pending      THEN 'Pending'
  WHEN gc_st_fixed        THEN 'Fixed'
  WHEN gc_st_finaltesting THEN 'Final Testing'
  WHEN gc_st_closed       THEN 'Closed'
  WHEN gc_st_waiting      THEN 'Waiting'
  WHEN gc_st_rejected     THEN 'Rejected'
  WHEN gc_st_resolved     THEN 'Resolved'
  ELSE <status> ).
```

---

## 7. MAPPING VỚI MÀN HÌNH (SCREEN ↔ STATUS INTERACTION)

### Tạo Bug (Screen 0300, mode = Create):
- STATUS = `1` (New) — **bắt buộc, không cho user chọn**
- CREATED_AT = `sy-datum` — **auto-fill, không cho nhập**
- PROJECT_ID = pre-filled từ context — **locked**
- BUG_ID = `(Auto)` — **auto-generate khi save**
- TESTER_ID = `sy-uname` — **auto-fill**
- Sau khi save → trigger **Auto-Assign Giai đoạn A**

### Change Bug (Screen 0300, mode = Change):
- STATUS field **LOCKED** (input = 0, screen group `STS`)
- Nút "Change Status" → mở **Popup Screen 0370** (status transition)
- Các field khác: editable theo vai trò (FNC, TST, DEV groups)

### Display Bug (Screen 0300, mode = Display):
- **TẤT CẢ fields** locked (input = 0)
- Không có nút Save, Upload, Email, Delete Evidence

---

*File này là source of truth cho status lifecycle. Mọi thay đổi logic chuyển trạng thái PHẢI update file này trước.*
*Cập nhật: 13/04/2026 (v5.0)*
