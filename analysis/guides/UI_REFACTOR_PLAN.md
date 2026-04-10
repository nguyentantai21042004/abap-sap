# UI Refactor Plan — Z_BUG_WORKSPACE_MP

> **Cập nhật:** 09/04/2026 (session 4)
> **Tổng:** 16 items, 5 phases
> **Tham khảo:** `UI_STATUS.md` (trạng thái trước refactor), `UI_SCREEN_FLOW.md` (flow mới)

---

## FLOW CHANGES (Prerequisite — trước tất cả 16 items)

### F1. Screen 0400 thành Initial Screen
- **SE93**: Đổi `ZBUG_HOME` initial screen từ `0100` → `0400`
- **CODE_PBO**: Module `init_user_role` gắn vào Screen 0400 PBO (thay vì 0100)
- **CODE_PAI**: Screen 0400 `BACK/CANC` → `LEAVE PROGRAM` (thay vì `LEAVE TO SCREEN 0100`)

### F2. Project Hotspot → Bug List (thay vì Project Detail)
- **CODE_F00**: `handle_hotspot_click` khi click `PROJECT_ID` trên Project ALV → set `gv_bug_filter_mode = 'P'`, set `gv_current_project_id`, `CALL SCREEN 0200`
- **Giữ lại**: Hotspot `PROJECT_ID` trên **Bug List ALV** vẫn mở Project Detail (0500)

### F3. My Bugs button trên Screen 0400
- **SE41**: Thêm fcode `MY_BUGS` vào `STATUS_0400`
- **CODE_PAI**: Handle `MY_BUGS` → set `gv_bug_filter_mode = 'M'`, clear `gv_current_project_id`, `CALL SCREEN 0200`

### F4. Bug List dual mode (Project vs My Bugs)
- **CODE_TOP**: Thêm `gv_bug_filter_mode TYPE char1`
- **CODE_F01**: `select_bug_data` check `gv_bug_filter_mode`:
  - `'P'` → `WHERE project_id = gv_current_project_id AND is_del <> 'X'` (no role filter)
  - `'M'` → giữ logic cũ (filter by role)
- **CODE_PBO**: Title khác nhau cho 2 modes
- **CODE_PAI**: Hide CREATE khi mode M (no project context)

### F5. Create Bug pre-fill PROJECT_ID
- **CODE_PBO**: `load_bug_detail` — khi create mode, pre-fill `gs_bug_detail-project_id` from `gv_current_project_id`
- **Screen 0310**: PROJECT_ID field có screen group `PRJ` — disable khi create mode (đã pre-fill)

### F6. Bug List Back → Screen 0400
- **CODE_PAI**: `user_command_0200` BACK/CANC → `LEAVE TO SCREEN 0400` (thay vì 0100)

---

## PHASE 1 — CRITICAL FIXES (Must-have)

### Item 1: Fix Save button missing in Change mode
- **Vấn đề:** Nút Save bị ẩn khi ở Change mode trên Screen 0300
- **Root cause:** `status_0300` chỉ ẩn SAVE khi Display mode, nhưng GUI Status có thể chưa include fcode `SAVE`
- **Fix:** Verify `STATUS_0300` trong SE41 có fcode `SAVE`. Code PBO đã đúng (chỉ exclude khi `gc_mode_display`)
- **Files:** SE41 `STATUS_0300` verification
- **Priority:** CRITICAL

### Item 2: BUG_ID display-only after Create
- **Vấn đề:** User có thể sửa BUG_ID sau khi tạo bug — gây data corruption
- **Fix:** Thêm screen group `BID` cho BUG_ID field trên Screen 0310. Trong `modify_screen_0300`:
  ```abap
  IF screen-group1 = 'BID'.
    IF gv_mode <> gc_mode_create.
      screen-input = 0.  " Lock BUG_ID after creation
    ENDIF.
    MODIFY SCREEN.
  ENDIF.
  ```
- **Files:** CODE_PBO (modify_screen_0300), Screen 0310 layout
- **Priority:** CRITICAL

---

## PHASE 2 — LABEL IMPROVEMENTS

### Item 3: STATUS raw code → text on Screen 0310
- **Vấn đề:** Screen 0310 hiển thị raw status code (1,2,3...) thay vì text
- **Fix:** Thêm field `GV_STATUS_DISP` (CHAR 20) trên screen, populate trong PBO:
  ```abap
  gv_status_disp = SWITCH #( gs_bug_detail-status
    WHEN '1' THEN 'New' WHEN '2' THEN 'Assigned' ... ).
  ```
  Field này display-only, nằm cạnh STATUS field (hoặc thay thế)
- **Files:** CODE_TOP (new var), CODE_PBO (populate), Screen 0310 layout
- **Priority:** HIGH

### Item 4: PRIORITY raw code → text on Screen 0310
- **Vấn đề:** Priority hiển thị H/M/L thay vì High/Medium/Low
- **Fix:** Tương tự Item 3, thêm `GV_PRIORITY_DISP` (CHAR 10)
- **Files:** CODE_TOP, CODE_PBO, Screen 0310
- **Priority:** HIGH

### Item 5: PROJECT_STATUS text on Screen 0500
- **Vấn đề:** Project status hiển thị 1/2/3/4 thay vì Opening/In Process/Done/Cancelled
- **Fix:** Thêm `GV_PRJ_STATUS_DISP` (CHAR 20), populate trong `init_project_detail`
- **Files:** CODE_TOP, CODE_PBO, Screen 0500
- **Priority:** HIGH

---

## PHASE 3 — DESCRIPTION MINI EDITOR

### Item 6: Text editor mini on Bug Info tab (Subscreen 0310)
- **Vấn đề:** Description chỉ available trên tab riêng (0320) — user phải switch tab để xem/nhập mô tả
- **Fix:** Thêm `cl_gui_textedit` nhỏ (3-4 dòng) ngay trên Subscreen 0310:
  1. Screen 0310: Thêm Custom Control `CC_DESC_MINI` (size ~60x4 characters)
  2. CODE_TOP: Thêm `go_desc_mini_cont`, `go_desc_mini_edit`
  3. CODE_PBO: Module `init_desc_mini` — create container + editor, load text from `DESC_TEXT` field
  4. CODE_F01: `save_bug_detail` — save text from mini editor back to `gs_bug_detail-desc_text`
- **Quan hệ với Tab Description (0320):** Tab Description (Long Text Z001) là cho mô tả dài/chi tiết. Mini editor trên 0310 là cho quick description (field `DESC_TEXT` trên ZBUG_TRACKER). Hai cái khác nhau — không conflict
- **Files:** CODE_TOP, CODE_PBO, CODE_F01, Screen 0310 layout
- **Priority:** HIGH

---

## PHASE 4 — LAYOUT ENHANCEMENTS

### Item 7: Group boxes on Screen 0310
- **Vấn đề:** Fields nằm rời rạc, khó phân biệt nhóm
- **Fix:** Thêm Group Boxes trong SE51:
  - "Bug Information" (BUG_ID, TITLE, PROJECT_ID, STATUS, PRIORITY)
  - "Classification" (SEVERITY, BUG_TYPE, SAP_MODULE)
  - "Assignment" (TESTER_ID, DEV_ID, VERIFY_TESTER_ID)
  - "Description" (CC_DESC_MINI)
- **Files:** Screen 0310 layout only (no code change)
- **Priority:** MEDIUM

### Item 8: Required field indicators
- **Vấn đề:** User không biết field nào bắt buộc
- **Fix:** Thêm `(*)` hoặc `Required` text sau label của TITLE, PROJECT_ID trong SE51
- **Files:** Screen 0310 layout, Screen 0500 layout
- **Priority:** MEDIUM

### Item 9: Title shows mode (Create/Change/Display)
- **Vấn đề:** Title bar chỉ hiện Bug ID, không biết đang ở mode nào
- **Fix:** `status_0300`:
  ```abap
  DATA(lv_mode_text) = SWITCH string( gv_mode
    WHEN gc_mode_create  THEN 'Create Bug'
    WHEN gc_mode_change  THEN |Change Bug: { gs_bug_detail-bug_id }|
    WHEN gc_mode_display THEN |Display Bug: { gs_bug_detail-bug_id }| ).
  SET TITLEBAR 'TITLE_BUGDETAIL' WITH lv_mode_text.
  ```
  Tương tự cho Screen 0500 (Project Detail)
- **Files:** CODE_PBO
- **Priority:** MEDIUM

### Item 10: Homepage info — N/A
- **Vấn đề ban đầu:** Homepage (0100) trống rỗng, không có dashboard
- **Quyết định:** Screen 0100 deprecated — item này **cancelled**
- **Priority:** CANCELLED

### Item 11: Label consistency
- **Vấn đề:** Labels không thống nhất (vd: "Tester" vs "Tester ID" vs "Created By")
- **Fix:** Chuẩn hóa trong SE51:
  - `BUG_ID` → "Bug ID"
  - `TITLE` → "Title *"
  - `PROJECT_ID` → "Project *"
  - `STATUS` → "Status"
  - `PRIORITY` → "Priority"
  - `TESTER_ID` → "Tester"
  - `DEV_ID` → "Developer"
  - `VERIFY_TESTER_ID` → "Verify Tester"
  - `SAP_MODULE` → "SAP Module"
  - `CREATED_AT` → "Created Date"
- **Files:** Screen 0310, 0500 layouts
- **Priority:** LOW

### Item 12: Date picker
- **Vấn đề:** Date fields không có date picker
- **Fix:** Trong SE51, set field type = DATS cho START_DATE, END_DATE, CREATED_AT → SAP tự hiện calendar icon
- **Files:** Screen 0310, 0500 layouts
- **Priority:** LOW

---

## PHASE 5 — ALV ENHANCEMENTS

### Item 13: Severity text column in Bug ALV
- **Vấn đề:** ALV hiện raw severity code (1-5) thay vì text
- **Fix:**
  1. CODE_TOP: Thêm `severity_text TYPE char20` vào `ty_bug_alv`
  2. CODE_F01: Populate trong `select_bug_data`:
     ```abap
     <bug>-severity_text = SWITCH #( <bug>-severity
       WHEN '1' THEN 'Dump/Critical' WHEN '2' THEN 'Very High'
       WHEN '3' THEN 'High' WHEN '4' THEN 'Normal' WHEN '5' THEN 'Minor' ).
     ```
  3. CODE_F00: Thêm `SEVERITY_TEXT` column, ẩn raw `SEVERITY`
- **Files:** CODE_TOP, CODE_F00, CODE_F01
- **Priority:** MEDIUM

### Item 14: Bug Type text column in Bug ALV
- **Vấn đề:** ALV hiện raw bug_type code (1-5) thay vì text
- **Fix:** Tương tự Item 13
  1. CODE_TOP: Thêm `bug_type_text TYPE char20` vào `ty_bug_alv`
  2. CODE_F01: Populate mapping
  3. CODE_F00: Thêm `BUG_TYPE_TEXT` column, ẩn raw `BUG_TYPE`
- **Files:** CODE_TOP, CODE_F00, CODE_F01
- **Priority:** MEDIUM

### Item 15: Project ALV column widths
- **Vấn đề:** Column widths mặc định không optimal
- **Fix:** Đã set `cwidth_opt = 'X'` (auto-optimize). Có thể fine-tune `outputlen` trong `build_pro_fieldcat`
- **Files:** CODE_F00
- **Priority:** LOW

### Item 16: ROLE column in team table (Screen 0500)
- **Vấn đề:** Table Control trên Screen 0500 không hiện Role column
- **Fix:** Thêm ROLE column trong Table Control layout (SE51)
- **Files:** Screen 0500 layout
- **Priority:** LOW

---

## IMPLEMENTATION MATRIX — Files Affected

| File | Flow | Ph1 | Ph2 | Ph3 | Ph4 | Ph5 | Total Changes |
|------|------|-----|-----|-----|-----|-----|---------------|
| CODE_TOP.md | F4 | — | 3,4,5 | 6 | — | 13,14 | 6 items |
| CODE_F00.md | F2 | — | — | — | — | 13,14,15 | 4 items |
| CODE_PBO.md | F1,F4,F5 | 1,2 | 3,4,5 | 6 | 9 | — | 10 items |
| CODE_PAI.md | F3,F4,F6 | — | — | — | — | — | 3 items |
| CODE_F01.md | F4 | — | — | 6 | — | 13,14 | 3 items |
| CODE_F02.md | — | — | — | 6 | — | — | 1 item |
| SE41 (GUI Status) | F3 | 1 | — | — | — | — | 2 items |
| SE51 (Screens) | F5 | 2 | — | 6 | 7,8,11,12 | 16 | 6 items |
| SE93 (T-code) | F1 | — | — | — | — | — | 1 item |

---

## ESTIMATED EFFORT

| Phase | Items | ABAP Lines | SE51 Work | SE41 Work |
|-------|-------|-----------|-----------|-----------|
| Flow Changes | F1-F6 | ~40 lines | Screen 0310 (PRJ group), 0400 (MY_BUGS) | STATUS_0400 (+MY_BUGS), STATUS_0200 (+exclusion) |
| Phase 1 | 1-2 | ~10 lines | Screen 0310 (BID group) | STATUS_0300 verify |
| Phase 2 | 3-5 | ~15 lines | Screen 0310 (+disp fields), 0500 (+disp field) | — |
| Phase 3 | 6 | ~30 lines | Screen 0310 (+CC_DESC_MINI) | — |
| Phase 4 | 7-12 | ~10 lines | Screen 0310 (group boxes, labels), 0500 | — |
| Phase 5 | 13-16 | ~20 lines | Screen 0500 (ROLE col) | — |
| **Total** | **16** | **~125 lines** | **4 screens** | **2 statuses** |

---

*Refer to CODE_*.md files for exact ABAP code. Refer to phase-c-module-pool.md for SE51/SE41 step-by-step.*
