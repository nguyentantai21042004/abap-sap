# 🚀 IMPLEMENTATION PHASES — Kế hoạch thực hiện

> **Deadline:** 03/04/2026 (Demo Day) — 10 ngày làm việc  
> **Nguyên tắc:** Giữ nguyên FM backend mạnh + Thêm Module Pool frontend đẹp  
> **Ưu tiên:** Database → Logic → Module Pool → Features → Testing

---

## Phase A: Database Hardening ⏱ 1 ngày (24-25/03)

**Mục tiêu:** Chuẩn hóa database layer, bổ sung Project entity, Severity field

### A1. Thêm Audit Fields & Soft Delete vào ZBUG_TRACKER, ZBUG_USERS

```
SE11 → ZBUG_TRACKER → Thêm: AENAM, AEDAT, AEZET, IS_DEL, SEVERITY
SE11 → ZBUG_USERS → Thêm: AENAM, AEDAT, AEZET, IS_DEL
→ Adjust Database (SE14)
```

### A2. Tạo bảng ZBUG_PROJECT (Project Management)

| Field | Type | Length | Key | Mô tả |
|-------|------|--------|-----|--------|
| MANDT | CLNT | 3 | ✓ | Client |
| PROJECT_ID | CHAR | 20 | ✓ | Project ID |
| PROJECT_NAME | CHAR | 100 | | Tên project |
| DESCRIPTION | CHAR | 255 | | Mô tả |
| START_DATE | DATS | 8 | | Ngày bắt đầu |
| END_DATE | DATS | 8 | | Ngày kết thúc |
| PROJECT_MANAGER | CHAR | 12 | | PM (user_id) |
| PROJECT_STATUS | CHAR | 1 | | 1=Opening, 2=InProcess, 3=Done, 4=Cancel |
| NOTE | CHAR | 255 | | Ghi chú |
| ERNAM/ERDAT/ERZET | — | — | | Created by/date/time |
| AENAM/AEDAT/AEZET | — | — | | Changed by/date/time |
| IS_DEL | CHAR | 1 | | Soft delete |

### A3. Tạo bảng ZBUG_USER_PROJECT (M:N)

| Field | Type | Length | Key | Mô tả |
|-------|------|--------|-----|--------|
| MANDT | CLNT | 3 | ✓ | Client |
| USER_ID | CHAR | 12 | ✓ | FK → ZBUG_USERS |
| PROJECT_ID | CHAR | 20 | ✓ | FK → ZBUG_PROJECT |
| ERNAM/ERDAT/ERZET | — | — | | Created audit |
| AENAM/AEDAT/AEZET | — | — | | Changed audit |

### A4. Thêm PROJECT_ID + SEVERITY vào ZBUG_TRACKER

```
SE11 → ZBUG_TRACKER:
  → Thêm PROJECT_ID (CHAR 20)
  → Thêm SEVERITY (CHAR 1) — Domain: 1=Dump, 2=VeryHigh, 3=High, 4=Normal, 5=Minor
```

### A5. Cập nhật Email field thành Mandatory

```
SE11 → ZBUG_USERS → Field EMAIL → Tích OBLIGATORY
```

### A6. Tạo Message Class ZBUG_MSG

```
SE91 → Create Message Class: ZBUG_MSG
→ Maintain messages EN + VI
→ Liệt kê tất cả hardcoded messages hiện tại
→ Migrate từng message vào ZBUG_MSG
```

---

## Phase B: Business Logic Update ⏱ 2 ngày (25-27/03)

### B1. Mở rộng Z_BUG_CHECK_PERMISSION

Thêm các actions mới:

- `CREATE_PROJECT` — Chỉ PM (M)
- `CHANGE_PROJECT` — PM của project đó
- `DELETE_PROJECT` — PM, project phải Done/Cancel
- `VIEW_PROJECT` — User thuộc project
- `ADD_USER_PROJECT` — PM only
- Bổ sung check user thuộc project cho mọi bug action

### B2. Cập nhật Z_BUG_CREATE

- Thêm `IV_PROJECT_ID` parameter
- Thêm `IV_SEVERITY` parameter
- Validate project exists + status = '2' (InProcess)
- Validate user thuộc project
- Validate user tồn tại trong `ZBUG_USERS` + `IS_ACTIVE = 'X'`
- Store PROJECT_ID + SEVERITY trong ZBUG_TRACKER

### B3. Chuẩn hóa Status States

Clear lại status codes:

| Code | Status | Transition hợp lệ |
|------|--------|--------------------|
| 1 | New | → 2 (assign), → W (no dev) |
| W | Waiting | → 2 (manager assign) |
| 2 | Assigned | → 3 (dev start), → R (reject) |
| 3 | In Progress | → 5 (fixed), → 4 (pending) |
| 4 | Pending | → 3 (resume) |
| 5 | Fixed | → 6 (verify pass), → 3 (verify fail) |
| 6 | Resolved | → 7 (close) |
| 7 | Closed | Terminal state |
| R | Rejected | → 2 (reassign) |

Cập nhật `Z_BUG_UPDATE_STATUS` validation + `Z_BUG_LOG_HISTORY`.

### B4. GOS File Storage Integration

```abap
" Upload file qua GOS:
DATA: lo_gos TYPE REF TO cl_gos_document_service,
      ls_object TYPE borident.

ls_object-objtype = 'ZBUG'.       " Business Object Type
ls_object-objkey  = lv_bug_id.    " Object Key

" Hoặc dùng BDS API:
CALL FUNCTION 'BDS_BUSINESSDOCUMENT_CREA_TAB'
  EXPORTING objecttype = 'ZBUG'
            objectkey  = lv_bug_id
  TABLES    ...
```

> **Lưu ý:** Cần tạo Business Object Type `ZBUG` trong SWO1 hoặc dùng generic object.

### B5. User Validation Enhancement

```abap
" Trong Z_BUG_CREATE, trước khi INSERT:
SELECT SINGLE user_id FROM zbug_users
  WHERE user_id = sy-uname AND is_del <> 'X' AND is_active = 'X'.
IF sy-subrc <> 0.
  ev_message = TEXT-e01. " Message Class: 'User does not exist or is inactive'
  RETURN.
ENDIF.

" Check user thuộc project:
SELECT SINGLE * FROM zbug_user_project
  WHERE user_id = sy-uname AND project_id = iv_project_id.
IF sy-subrc <> 0.
  ev_message = TEXT-e02. " 'User is not a member of this project'
  RETURN.
ENDIF.
```

### B6. SmartForm Email Template

```
SMARTFORMS → Create: ZBUG_EMAIL_FORM
→ Interface: IV_BUG_ID, IV_EVENT, IV_RECIPIENT
→ Layout: Bug ID, Title, Status, Priority, Module, Assigned Dev, Tester
→ Subject: "[ZBUG] {EVENT}: {BUG_ID} - {TITLE}"
→ Generate HTML → pass to CL_BCS

" Gọi SmartForm:
CALL FUNCTION lv_fm_name
  EXPORTING control_parameters = ls_ctrl
            output_options     = ls_output
            iv_bug_id          = lv_bug_id
  IMPORTING document           = lo_document.
```

### B7. Severity + Bug Type Dual Validation

```abap
" Validation: Severity cao (Dump/VeryHigh/High) + Bug Type = Code → Priority tự set High
IF iv_severity IN ('1', '2', '3') AND iv_bug_type = 'C'.
  ev_priority = 'H'.  " Force High priority
ENDIF.
```

---

## Phase C: Module Pool UI ⏱ 4 ngày (27-31/03)

**Đây là phase lớn nhất — xây dựng toàn bộ Module Pool mới.**

### C1. Tạo Module Pool Program (27/03)

```
SE80 → Create Program → Type M (Module Pool)
Program: Z_BUG_WORKSPACE_MP
Includes:
  Z_BUG_WS_TOP    → Global data declarations
  Z_BUG_WS_PBO    → Process Before Output
  Z_BUG_WS_PAI    → Process After Input
  Z_BUG_WS_F00    → ALV setup + Event handler class
  Z_BUG_WS_F01    → Business logic FORM routines
  Z_BUG_WS_F02    → Helper: F4, Long Text, Popup, GOS
```

### C2. Screen Design (27-28/03)

```
Screen 0100: Main Hub (Router → đọc parameter, điều hướng)
Screen 0200: Bug List (ALV Grid + toolbar buttons)
  → SubScreen 0210: Selection criteria (optional filter bar)
Screen 0300: Bug Detail (Tab Strip: Info/Notes/Evidence/History)
  → SubScreen 0310: Bug Info fields
  → SubScreen 0320: Tester Note (cl_gui_textedit)
  → SubScreen 0330: Developer Note (cl_gui_textedit)
  → SubScreen 0340: Root Cause (cl_gui_textedit)
  → SubScreen 0350: Evidence (GOS integration)
  → SubScreen 0360: History Log (ALV readonly + filter)
Screen 0400: Project List (ALV Grid)
Screen 0500: Project Detail (fields + user list table control)
Screen 1000: Selection Screen (Upload Excel mode)
```

### C3. GUI Statuses (28/03)

| Status | Screen | Buttons |
|--------|--------|---------|
| STATUS_0200 | Bug List | CREATE, CHANGE, DISPLAY, DELETE, REFRESH, PRINT, BACK |
| STATUS_0300 | Bug Detail | SAVE, BACK, SENDMAIL |
| STATUS_0400 | Project List | CREATE_PRO, CHANGE_PRO, DISPLAY_PRO, DELETE_PRO, REFRESH, DOWNLOAD_TMPL, UPLOAD, BACK |
| STATUS_0500 | Project Detail | SAVE, BACK |

### C4. Dynamic Screen Control (28-29/03)

```abap
MODULE modify_screen OUTPUT.
  " Role-based field control (T/D/M)
  " Mode-based (D/C/X) field control
  " Status-based field locking (Closed → all readonly)
  " Severity-Bug Type cross validation UI hints
  LOOP AT SCREEN.
    " ... logic from ZPG patterns ...
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
```

### C5. Tab Strip + Long Text (29-30/03)

```abap
" Text Object: ZBUG_NOTE (SE75)
" Text IDs: Z001 (Dev Note), Z002 (Tester Note), Z003 (Root Cause)

" PBO: READ_TEXT → set_text_as_r3table
" PAI: get_text_as_r3table → SAVE_TEXT
" cl_gui_textedit per tab with wordwrap_at_windowborder
```

### C6. F4 Search Help (30/03)

- Project ID → `F4IF_INT_TABLE_VALUE_REQUEST` from `ZBUG_PROJECT WHERE IS_DEL <> 'X'`
- Developer → from `ZBUG_USERS WHERE ROLE = 'D' AND IS_ACTIVE = 'X'`
- Tester → from `ZBUG_USERS WHERE ROLE = 'T' AND IS_ACTIVE = 'X'`
- Module → hardcoded list hoặc custom table
- Severity → Domain fixed values

### C7. GOS Integration on Screen (30/03)

```abap
" Tích hợp GOS toolbar trên Bug Detail screen
" User click → GOS popup → upload/view/delete attachments
DATA: lo_gos_manager TYPE REF TO cl_gos_manager.
CREATE OBJECT lo_gos_manager
  EXPORTING is_object = ls_object
            ip_no_commit = 'X'.
```

### C8. History Tab with Filter (30-31/03)

```abap
" SubScreen 0360: readonly ALV
" Filter bar: Action Type dropdown + Date range
" Data: SELECT * FROM zbug_history WHERE bug_id = gv_current_bug_id
"       ORDER BY changed_at DESCENDING changed_time DESCENDING
```

### C9. Refresh Button (31/03)

```abap
WHEN 'REFRESH'.
  PERFORM select_bug_data.    " Re-select from DB
  CALL METHOD grid1->refresh_table_display.
```

### C10. Popup Confirm (31/03)

```abap
" Delete, Back when unsaved, Reject, Close bug
CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING titlebar       = 'Confirmation'
            text_question  = lv_question    " From Message Class
  IMPORTING answer         = lv_answer.
IF lv_answer = '1'. " Confirmed
  " proceed
ENDIF.
```

---

## Phase D: Excel & Advanced Features ⏱ 1.5 ngày (31/03-01/04)

### D1. Excel Template + Upload (31/03)

1. Tạo template Excel + upload SMW0 → `ZTEMPLATE_PROJECT`
2. Nút Download Template trên GUI Status
3. Upload logic: `TEXT_CONVERT_XLS_TO_SAP` + validation
4. Insert vào `ZBUG_PROJECT` + `ZBUG_USER_PROJECT`

### D2. Message Class Migration (01/04)

1. Liệt kê tất cả hardcoded messages trong code
2. Tạo entries trong `ZBUG_MSG` (SE91) — EN + VI
3. Replace hardcoded strings với `MESSAGE sNNN(zbug_msg)`
4. Test với logon language EN và VI

### D3. Dashboard Statistics (01/04, nếu đủ thời gian)

- Manager-only screen → Bug count by status/module/dev
- Dùng `Z_BUG_GET_STATISTICS` FM

---

## Phase E: Integration, Testing & Polish ⏱ 1.5 ngày (02-03/04)

### E1. Tạo T-code ZBUG_HOME (update)

```
SE93 → ZBUG_HOME → Delete old → Create new
Type: Program and screen (Dialog transaction)
Program: Z_BUG_WORKSPACE_MP, Screen: 0100
```

### E2. Kiểm thử chức năng

| Test Case | Mô tả | Expected |
|-----------|--------|----------|
| TC-01 | Tạo project, tạo bug trong project | Bug có PROJECT_ID |
| TC-02 | Create bug validation (user ko tồn tại) | Error message (ZBUG_MSG) |
| TC-03 | Permission check (Tester ko delete) | Nút hidden/disabled |
| TC-04 | Status transition (valid + invalid) | Chỉ valid transition accepted |
| TC-05 | File upload qua GOS | File lưu trên SAP, view từ GOS |
| TC-06 | Refresh button | ALV reload data |
| TC-07 | Email sent via SmartForm | Check SOST |
| TC-08 | F4 search help | Popup hiện, chọn → fill field |
| TC-09 | Bug Type C/F + Severity 1-5 | Workflow branch đúng, Priority enforce |
| TC-10 | Đa ngôn ngữ (EN/VI) | Messages hiển thị đúng language |
| TC-11 | Excel upload project | Template → fill → upload → success |
| TC-12 | History tab + filter | Log hiện, filter action type work |
| TC-13 | Soft delete bug/project | IS_DEL = 'X', record hidden nhưng ko mất |
| TC-14 | Close project check | Block nếu còn bug unresolved |

### E3. UAT Preparation

- Tạo test accounts (Tester, Developer, Manager)
- Tạo test project + test bugs
- Prepare demo script cho Demo Day
- Prepare fallback plan

### E4. Demo Day Preparation (03/04)

- Clean test data
- Rehearse demo flow: PM tạo project → Tester tạo bug → Auto-assign → Dev fix → Tester verify → Close
- Highlight: Auto-Assign, History, SmartForm Email, Đa ngôn ngữ, Module Pool UI
