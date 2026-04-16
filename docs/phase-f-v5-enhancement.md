# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE F: v5.0 ENHANCEMENT

**Dự án:** SAP Bug Tracking Management System
**Ngày:** 13/04/2026 | **Phiên bản:** v5.0
**Thời gian ước tính:** 5-7 ngày
**Yêu cầu:** Hoàn thành Phase A + C+D v4.2 + deploy vào SAP trước
**ABAP Version:** 7.70 (SAP_BASIS 770 — inline declarations, SWITCH, CONV, string templates, @ host vars)
**Tài liệu tham chiếu:**
- `docs/status-lifecycle.md` — Source of truth cho lifecycle v5.0
- `docs/v5-bug-analysis.md` — 11 bugs cần fix
- `docs/requirements.md` — 8 phần yêu cầu mới (New_Requirements đã merge vào đây)
- `database/table-fields.md` — Source of truth cho DB fields

---

## MỤC LỤC

0. [Bước F0: Bug Fixes từ UAT (11 bugs)](#bước-f0-bug-fixes-từ-uat-11-bugs)
1. [Bước F1: Status Lifecycle v5.0 (Breaking Change)](#bước-f1-status-lifecycle-v50-breaking-change)
2. [Bước F2: Screen 0410 — Project Search](#bước-f2-screen-0410--project-search)
3. [Bước F3: Dashboard Header trên Screen 0200](#bước-f3-dashboard-header-trên-screen-0200)
4. [Bước F4: Template Rename (SMW0)](#bước-f4-template-rename-smw0)
5. [Bước F5: Status Transition Popup (Screen 0370)](#bước-f5-status-transition-popup-screen-0370)
6. [Bước F6: Matrix Logic — Transition Rules](#bước-f6-matrix-logic--transition-rules)
7. [Bước F7: Auto-Assign System](#bước-f7-auto-assign-system)
8. [Bước F8: Test Data Population](#bước-f8-test-data-population)
9. [Bước F9: Bug Search Engine (Screen 0210/0220)](#bước-f9-bug-search-engine-screen-02100220)
10. [Tổng kết Phase F](#tổng-kết-phase-f)

---

## Bước F0: Bug Fixes từ UAT (11 bugs)

**Mục tiêu:** Fix 11 bugs tìm được trong UAT round 1. Chi tiết phân tích: `docs/v5-bug-analysis.md`.

> **Nguyên tắc:** Tất cả các fix dưới đây sẽ được incorporate vào CODE v5.0 (không patch riêng v4.x).

### F0.1. Bug 1+9: Short dump CALL_FUNCTION_CONFLICT_TYPE

**Root cause:** Custom Control chưa tạo đúng trên SE51 HOẶC STRING field trên screen layout HOẶC READ_TEXT type mismatch.

**Fix trong CODE_PBO — TRY-CATCH container creation:**

```abap
" Áp dụng cho init_long_text_desc, init_long_text_devnote, init_long_text_tstnote
MODULE init_long_text_desc OUTPUT.
  IF go_cont_desc IS INITIAL.
    TRY.
        CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
        CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
      CATCH cx_root.
        MESSAGE 'Cannot create Description editor. Check Custom Control CC_DESC on screen 0320.' TYPE 'S' DISPLAY LIKE 'W'.
        RETURN.
    ENDTRY.
  ENDIF.
  " ... load text nếu có bug_id ...
ENDMODULE.
```

**Fix trong CODE_F02 — Explicit type cast trong READ_TEXT/SAVE_TEXT:**

```abap
" Trong load_long_text / save_long_text:
DATA: lv_tdname TYPE tdobname.
lv_tdname = gv_current_bug_id.    " Explicit CHAR 10 → CHAR 70
CALL FUNCTION 'READ_TEXT'
  EXPORTING
    id       = pv_text_id
    language = sy-langu
    name     = lv_tdname           " Dùng biến đã ép kiểu
    object   = 'ZBUG'
  ...
```

**Verify trên SE51:**
- Screen 0310: **XÓA** `GS_BUG_DETAIL-DESC_TEXT` và `GS_BUG_DETAIL-REASONS` khỏi layout (STRING fields KHÔNG hỗ trợ trên screen)
- Screen 0320: Custom Control `CC_DESC` phải tồn tại
- Screen 0330: Custom Control `CC_DEVNOTE` phải tồn tại
- Screen 0340: Custom Control `CC_TSTRNOTE` phải tồn tại

### F0.2. Bug 3: Description bị giới hạn ký tự

**Fix:** Xóa `GS_BUG_DETAIL-DESC_TEXT` khỏi screen 0310 layout (nếu có). Description chỉ nằm trong `cl_gui_textedit` (Custom Control `CC_DESC_MINI`).

### F0.3. Bug 4: Hiển thị trường bị thiếu

**Fix:** Verify trên SE51 Screen 0310 — mỗi field phải reference đúng tên biến global:
- SAP Module → `GS_BUG_DETAIL-SAP_MODULE`
- Severity display → `GV_SEVERITY_DISP`
- Created Date → `GS_BUG_DETAIL-CREATED_AT`

### F0.4. Bug 5: Remove User không chọn vẫn xóa

**Fix trong CODE_F01 — `remove_user_from_project`:**

```abap
FORM remove_user_from_project.
  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.
  " Fix: Validate phạm vi dữ liệu
  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
    MESSAGE 'Please select a user row to remove.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.
  " ... existing code ...
ENDFORM.
```

### F0.5. Bug 6: Create Bug — 4 vấn đề

**6a. STATUS bắt buộc = 1 (New) — CODE_F01 `save_bug_detail`:**

```abap
" Create mode: FORCE status = New, bỏ IF check
IF gv_mode = gc_mode_create.
  gs_bug_detail-status = gc_st_new.  " Luôn = 1
  gs_bug_detail-created_at = sy-datum.
  gs_bug_detail-created_time = sy-uzeit.
  gs_bug_detail-tester_id = sy-uname.
ENDIF.
```

**6b. SAP Module F4 Help — CODE_F02 + CODE_PAI:**

```abap
" CODE_F02:
FORM f4_sap_module USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mod_f4,
           sap_module TYPE zde_sap_module,
         END OF ty_mod_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mod_f4.
  lt_val = VALUE #(
    ( sap_module = 'FI' )    ( sap_module = 'MM' )
    ( sap_module = 'SD' )    ( sap_module = 'ABAP' )
    ( sap_module = 'BASIS' ) ( sap_module = 'PP' )
    ( sap_module = 'HR' )    ( sap_module = 'QM' ) ).
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'SAP_MODULE' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = pv_fn value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.

" CODE_PAI:
MODULE f4_bug_sapmodule INPUT.
  PERFORM f4_sap_module USING 'GS_BUG_DETAIL-SAP_MODULE'.
ENDMODULE.
```

**Screen 0310 Flow Logic thêm POV:**
```
PROCESS ON VALUE-REQUEST.
  FIELD gs_bug_detail-sap_module MODULE f4_bug_sapmodule.
```

**6c. Upload Evidence khi Create:** Bỏ `UP_FILE` khỏi Create mode exclusion list. Form `upload_evidence` đã check `gv_current_bug_id IS INITIAL` → message 'Save the bug first'.

**6d. Created Date auto-fill — CODE_PBO `modify_screen_0300`:** Đã xử lý ở 6a (pre-fill trong save logic) + screen group `CRD` hoặc `BID` cho CREATED_AT field luôn locked.

### F0.6. Bug 7: Fields bị khóa sau validation error

**Fix:** Đổi TẤT CẢ `MESSAGE ... TYPE 'E'` sang `MESSAGE ... TYPE 'S' DISPLAY LIKE 'E'` + `RETURN`.

**Áp dụng trong:**
- `save_bug_detail` (5 messages)
- `save_project_detail` (3 messages)
- Bất kỳ FORM nào gọi từ PAI

```abap
" TRƯỚC (gây lock screen):
MESSAGE 'Title is required.' TYPE 'E'.

" SAU:
MESSAGE 'Title is required.' TYPE 'S' DISPLAY LIKE 'E'.
gv_save_ok = abap_false.
RETURN.
```

### F0.7. Bug 8: Description biến mất khi xem detail

**Fix trong CODE_F01 — sync desc_text sau save long text:**

```abap
" Sau PERFORM save_long_text, sync lại gs_bug_detail-desc_text:
IF go_edit_desc IS NOT INITIAL.
  DATA: lt_desc_sync TYPE TABLE OF char255.
  go_edit_desc->get_text_as_r3table( IMPORTING table = lt_desc_sync ).
  CLEAR gs_bug_detail-desc_text.
  LOOP AT lt_desc_sync INTO DATA(lv_sync_line).
    IF gs_bug_detail-desc_text IS NOT INITIAL.
      gs_bug_detail-desc_text = gs_bug_detail-desc_text && cl_abap_char_utilities=>cr_lf && lv_sync_line.
    ELSE.
      gs_bug_detail-desc_text = lv_sync_line.
    ENDIF.
  ENDLOOP.
ENDIF.
```

### F0.8. Bug 10+11: Status chuyển ngược + Manager bypass

**Fix:** Xóa Manager bypass trong `change_bug_status`. Tất cả roles tuân theo transition matrix. Xem [Bước F6: Matrix Logic](#bước-f6-matrix-logic--transition-rules).

---

## Bước F1: Status Lifecycle v5.0 (Breaking Change)

**Mục tiêu:** Cập nhật hệ thống 9-state → 10-state lifecycle. Chi tiết: `docs/status-lifecycle.md`.

### F1.1. Update ABAP Constants (CODE_TOP)

```abap
" === BUG STATUS CONSTANTS (v5.0 — 10-state lifecycle) ===
CONSTANTS:
  gc_st_new          TYPE zde_bug_status VALUE '1',       " New
  gc_st_assigned     TYPE zde_bug_status VALUE '2',       " Assigned
  gc_st_inprogress   TYPE zde_bug_status VALUE '3',       " In Progress
  gc_st_pending      TYPE zde_bug_status VALUE '4',       " Pending
  gc_st_fixed        TYPE zde_bug_status VALUE '5',       " Fixed
  gc_st_finaltesting TYPE zde_bug_status VALUE '6',       " Final Testing (WAS Resolved in v4.x!)
  gc_st_closed       TYPE zde_bug_status VALUE '7',       " Closed (legacy)
  gc_st_waiting      TYPE zde_bug_status VALUE 'W',       " Waiting
  gc_st_rejected     TYPE zde_bug_status VALUE 'R',       " Rejected
  gc_st_resolved     TYPE zde_bug_status VALUE 'V'.       " Resolved (NEW! terminal state)
```

### F1.2. Update Status Text Mapping (CODE_F01 hoặc CODE_PBO)

```abap
<bug>-status_text = SWITCH #( <bug>-status
  WHEN gc_st_new          THEN 'New'
  WHEN gc_st_assigned     THEN 'Assigned'
  WHEN gc_st_inprogress   THEN 'In Progress'
  WHEN gc_st_pending      THEN 'Pending'
  WHEN gc_st_fixed        THEN 'Fixed'
  WHEN gc_st_finaltesting THEN 'Final Testing'     " CHANGED from 'Resolved'
  WHEN gc_st_closed       THEN 'Closed'
  WHEN gc_st_waiting      THEN 'Waiting'
  WHEN gc_st_rejected     THEN 'Rejected'
  WHEN gc_st_resolved     THEN 'Resolved'           " NEW
  ELSE <bug>-status ).
```

### F1.3. Migration Script

Bugs hiện có `status = '6'` (Resolved cũ) cần review:

```abap
" Kiểm tra trước:
SELECT bug_id, title, status FROM zbug_tracker
  WHERE status = '6' INTO TABLE @DATA(lt_old_resolved).

" Nếu chúng thực sự đã xong → đổi sang 'V' (Resolved mới)
UPDATE zbug_tracker SET status = 'V'
  WHERE status = '6' AND is_del <> 'X'.
COMMIT WORK.
```

### F1.4. Update Evidence Prefix Logic

| Chuyển sang | Evidence rule cũ (v4.x) | Evidence rule mới (v5.0) |
|-------------|------------------------|--------------------------|
| Fixed (5) | `BUGPROOF_` prefix | File evidence bất kỳ (COUNT > 0) |
| Final Testing (6) | `TESTCASE_` prefix | Tự động (auto-assign Tester) |
| Resolved (V) | — | `TRANS_NOTE` bắt buộc |
| Closed (7) | `CONFIRM_` prefix | Legacy — không còn trong flow chính |

---

## Bước F2: Screen 0410 — Project Search

**Mục tiêu:** Thêm màn hình lọc trước khi vào danh sách dự án (Screen 0400).

**Nguồn:** `docs/requirements.md` Phần 1.

### F2.1. Screen Architecture

```
ZBUG_WS → Screen 0410 (NEW — Project Search, initial)
  ├── Execute → Screen 0400 (Project List, filtered)
  └── Back → LEAVE PROGRAM
```

**Thay đổi flow:** T-code `ZBUG_WS` → initial screen đổi từ **0400** sang **0410**.

### F2.2. Screen 0410 Design

**Loại:** Normal Screen (full screen)
**Kích thước:** Mặc định SAP (không cần set)

**Fields trên Screen Layout:**

| Field name | Type | Label | Screen Group | F4 Help |
|-----------|------|-------|-------------|---------|
| `S_PRJ_ID` | `ZDE_PROJECT_ID` (CHAR 20) | Mã Dự án | — | F4 từ ZBUG_PROJECT |
| `S_PRJ_MN` | `UNAME` (CHAR 12) | Người Quản lý | — | F4 từ ZBUG_USERS WHERE ROLE='M' |
| `S_PRJ_ST` | `CHAR 1` | Trạng thái Dự án | — | F4 list: 1=Opening, 2=In Process, 3=Done, 4=Cancel |

**Global Variables (CODE_TOP):**

```abap
" === Screen 0410: Project Search Fields ===
DATA: s_prj_id TYPE zde_project_id,
      s_prj_mn TYPE uname,
      s_prj_st TYPE char1.
```

### F2.3. Flow Logic (Screen 0410)

```
PROCESS BEFORE OUTPUT.
  MODULE status_0410.

PROCESS AFTER INPUT.
  MODULE user_command_0410.

PROCESS ON VALUE-REQUEST.
  FIELD s_prj_id   MODULE f4_project_id.
  FIELD s_prj_mn   MODULE f4_manager.
  FIELD s_prj_st   MODULE f4_project_status.
```

### F2.4. PBO Module (CODE_PBO)

```abap
MODULE status_0410 OUTPUT.
  SET PF-STATUS 'STATUS_0410'.
  SET TITLEBAR 'T_0410'.
ENDMODULE.
```

### F2.5. PAI Module (CODE_PAI)

```abap
MODULE user_command_0410 INPUT.
  DATA: lv_ok TYPE sy-ucomm.
  lv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_ok.
    WHEN 'EXECUTE' OR 'ONLI'.   " F8 = Execute
      PERFORM search_projects.
      CALL SCREEN 0400.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.
```

### F2.6. Search Logic (CODE_F01)

```abap
FORM search_projects.
  " Build dynamic WHERE with security check
  DATA: lv_where TYPE string.

  " Security: Non-Manager chỉ thấy project mình tham gia
  IF gv_role <> 'M'.
    SELECT project_id FROM zbug_user_projec
      INTO TABLE @DATA(lt_my_projects)
      WHERE user_id = @sy-uname.
    IF lt_my_projects IS INITIAL.
      CLEAR gt_project_list.
      RETURN.
    ENDIF.
  ENDIF.

  " Build SELECT
  SELECT p~project_id, p~project_name, p~description,
         p~project_status, p~project_manager,
         p~start_date, p~end_date, p~note,
         p~ernam, p~erdat, p~erzet
    FROM zbug_project AS p
    INNER JOIN zbug_user_projec AS u
      ON p~project_id = u~project_id
    WHERE p~is_del <> 'X'
      AND ( @s_prj_id IS INITIAL OR p~project_id = @s_prj_id )
      AND ( @s_prj_mn IS INITIAL OR p~project_manager = @s_prj_mn )
      AND ( @s_prj_st IS INITIAL OR p~project_status = @s_prj_st )
      AND u~user_id = @sy-uname
    INTO CORRESPONDING FIELDS OF TABLE @gt_project_list.

  " Manager: nếu không dùng INNER JOIN thì dùng riêng
  IF gv_role = 'M'.
    SELECT p~project_id, p~project_name, p~description,
           p~project_status, p~project_manager,
           p~start_date, p~end_date, p~note,
           p~ernam, p~erdat, p~erzet
      FROM zbug_project AS p
      WHERE p~is_del <> 'X'
        AND ( @s_prj_id IS INITIAL OR p~project_id = @s_prj_id )
        AND ( @s_prj_mn IS INITIAL OR p~project_manager = @s_prj_mn )
        AND ( @s_prj_st IS INITIAL OR p~project_status = @s_prj_st )
      INTO CORRESPONDING FIELDS OF TABLE @gt_project_list.
  ENDIF.

  SORT gt_project_list BY project_id.
  DELETE ADJACENT DUPLICATES FROM gt_project_list COMPARING project_id.
ENDFORM.
```

### F2.7. F4 Help Modules (CODE_PAI + CODE_F02)

```abap
" CODE_PAI:
MODULE f4_project_id INPUT.
  PERFORM f4_project_id_help USING 'S_PRJ_ID'.
ENDMODULE.

MODULE f4_manager INPUT.
  PERFORM f4_manager_help USING 'S_PRJ_MN'.
ENDMODULE.

MODULE f4_project_status INPUT.
  PERFORM f4_project_status_help USING 'S_PRJ_ST'.
ENDMODULE.
```

```abap
" CODE_F02:
FORM f4_project_id_help USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_prj_f4,
           project_id TYPE zde_project_id,
           project_name TYPE zbug_project-project_name,
         END OF ty_prj_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_prj_f4.
  SELECT project_id, project_name FROM zbug_project
    WHERE is_del <> 'X'
    INTO CORRESPONDING FIELDS OF TABLE @lt_val.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'PROJECT_ID' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = pv_fn value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.

FORM f4_manager_help USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mgr_f4,
           user_id TYPE zbug_users-user_id,
           full_name TYPE zbug_users-full_name,
         END OF ty_mgr_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mgr_f4.
  SELECT user_id, full_name FROM zbug_users
    WHERE role = 'M' AND is_del <> 'X'
    INTO CORRESPONDING FIELDS OF TABLE @lt_val.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'USER_ID' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = pv_fn value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.

FORM f4_project_status_help USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_st_f4,
           status TYPE char1,
           text   TYPE char20,
         END OF ty_st_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_st_f4.
  lt_val = VALUE #(
    ( status = '1' text = 'Opening' )
    ( status = '2' text = 'In Process' )
    ( status = '3' text = 'Done' )
    ( status = '4' text = 'Cancelled' ) ).
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'STATUS' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = pv_fn value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.
```

### F2.8. GUI Status `STATUS_0410` (SE41)

| Button | Fcode | Icon | Type |
|--------|-------|------|------|
| Execute | `EXECUTE` | ICON_EXECUTE_OBJECT | Normal |
| Back | `BACK` | ICON_BACK | Normal |
| Exit | `EXIT` | ICON_EXIT | Normal |
| Cancel | `CANCEL` | ICON_CANCEL | Normal |

**Title Bar `T_0410`:** "Project Search"

### F2.9. SE93 Update

T-code `ZBUG_WS` → initial screen đổi từ `0400` sang `0410`.

> **Checkpoint:** Chạy ZBUG_WS → Screen 0410 hiện ra → nhập filter → Execute → Screen 0400 chỉ hiển thị projects đã lọc.

---

## Bước F3: Dashboard Header trên Screen 0200

**Mục tiêu:** Thêm phần thống kê (Dashboard) phía trên ALV Bug List.

**Nguồn:** `docs/requirements.md` Phần 2.

### F3.1. Screen Layout Design

Screen 0200 chia 2 phần:
- **Phần trên (Dashboard):** ~6-8 dòng output fields hiển thị metrics
- **Phần dưới (ALV):** Custom Control `CC_BUG_LIST` (giữ nguyên)

**Dashboard Fields (output-only, NO input):**

```
┌────────────────────────────────────────────────────────────────┐
│  Bug Tracking Dashboard                                        │
│                                                                │
│  Total Bugs: [gv_dash_total]                                   │
│                                                                │
│  By Status:  New:[gv_d_new]  Assigned:[gv_d_assigned]          │
│              InProgress:[gv_d_inprog]  Fixed:[gv_d_fixed]      │
│              FinalTest:[gv_d_finaltest]  Resolved:[gv_d_resolvd]│
│              Rejected:[gv_d_rejected]  Waiting:[gv_d_waiting]  │
│                                                                │
│  By Priority: High:[gv_d_p_high]  Medium:[gv_d_p_med]         │
│               Low:[gv_d_p_low]                                 │
│                                                                │
│  By Module:  FI:[gv_d_m_fi]  MM:[gv_d_m_mm]  SD:[gv_d_m_sd]  │
│              ABAP:[gv_d_m_abap]  BASIS:[gv_d_m_basis]         │
├────────────────────────────────────────────────────────────────┤
│  [CC_BUG_LIST — ALV Grid]                                      │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

### F3.2. Global Variables (CODE_TOP)

```abap
" === Dashboard metrics (Screen 0200) ===
DATA: gv_dash_total    TYPE i,
      " By Status
      gv_d_new         TYPE i,
      gv_d_assigned    TYPE i,
      gv_d_inprog      TYPE i,
      gv_d_fixed       TYPE i,
      gv_d_finaltest   TYPE i,
      gv_d_resolved    TYPE i,
      gv_d_rejected    TYPE i,
      gv_d_waiting     TYPE i,
      gv_d_closed      TYPE i,
      " By Priority
      gv_d_p_high      TYPE i,
      gv_d_p_med       TYPE i,
      gv_d_p_low       TYPE i,
      " By Module
      gv_d_m_fi        TYPE i,
      gv_d_m_mm        TYPE i,
      gv_d_m_sd        TYPE i,
      gv_d_m_abap      TYPE i,
      gv_d_m_basis     TYPE i.
```

### F3.3. Dashboard Calculation (CODE_F01)

```abap
FORM calculate_dashboard.
  " Reset all counters
  CLEAR: gv_dash_total, gv_d_new, gv_d_assigned, gv_d_inprog,
         gv_d_fixed, gv_d_finaltest, gv_d_resolved, gv_d_rejected,
         gv_d_waiting, gv_d_closed,
         gv_d_p_high, gv_d_p_med, gv_d_p_low,
         gv_d_m_fi, gv_d_m_mm, gv_d_m_sd, gv_d_m_abap, gv_d_m_basis.

  gv_dash_total = lines( gt_bug_list ).

  LOOP AT gt_bug_list ASSIGNING FIELD-SYMBOL(<bug>).
    " By Status
    CASE <bug>-status.
      WHEN gc_st_new.          ADD 1 TO gv_d_new.
      WHEN gc_st_assigned.     ADD 1 TO gv_d_assigned.
      WHEN gc_st_inprogress.   ADD 1 TO gv_d_inprog.
      WHEN gc_st_fixed.        ADD 1 TO gv_d_fixed.
      WHEN gc_st_finaltesting. ADD 1 TO gv_d_finaltest.
      WHEN gc_st_resolved.     ADD 1 TO gv_d_resolved.
      WHEN gc_st_rejected.     ADD 1 TO gv_d_rejected.
      WHEN gc_st_waiting.      ADD 1 TO gv_d_waiting.
      WHEN gc_st_closed.       ADD 1 TO gv_d_closed.
    ENDCASE.

    " By Priority
    CASE <bug>-priority.
      WHEN 'H' OR 'HIGH'.   ADD 1 TO gv_d_p_high.
      WHEN 'M' OR 'MEDIUM'. ADD 1 TO gv_d_p_med.
      WHEN 'L' OR 'LOW'.    ADD 1 TO gv_d_p_low.
    ENDCASE.

    " By Module
    CASE <bug>-sap_module.
      WHEN 'FI'.    ADD 1 TO gv_d_m_fi.
      WHEN 'MM'.    ADD 1 TO gv_d_m_mm.
      WHEN 'SD'.    ADD 1 TO gv_d_m_sd.
      WHEN 'ABAP'.  ADD 1 TO gv_d_m_abap.
      WHEN 'BASIS'. ADD 1 TO gv_d_m_basis.
    ENDCASE.
  ENDLOOP.
ENDFORM.
```

### F3.4. Gọi calculate_dashboard

Gọi sau mỗi lần load/filter bug list:
- Trong `select_bug_data` (sau SELECT)
- Trong `display_bug_alv` (khi refresh)
- Khi ALV filter thay đổi (via event handler)

```abap
" Trong PBO module status_0200:
PERFORM calculate_dashboard.
```

### F3.5. Screen 0200 Layout Update (SE51)

Thêm output fields phía trên Custom Control `CC_BUG_LIST`:
- Tất cả fields: `INPUT = 0` (output only), **KHÔNG** thuộc screen group
- Di chuyển `CC_BUG_LIST` xuống dưới để có chỗ cho dashboard (~8 dòng)

> **Checkpoint:** Screen 0200 → phần trên hiển thị metrics → ALV bên dưới → filter ALV → metrics update tương ứng.

---

## Bước F4: Template Rename (SMW0)

**Mục tiêu:** Đổi tên 3 templates cho phù hợp quy trình nghiệp vụ.

**Nguồn:** `docs/requirements.md` Phần 3.

### F4.1. Mapping cũ → mới

| Object SMW0 | Tên download cũ | Tên download mới | Mục đích |
|-------------|----------------|------------------|----------|
| `ZBT_TMPL_01` | `ZTEMPLATE_PROJECT.xlsx` | `Bug_report.xlsx` | Tester báo cáo lỗi |
| `ZBT_TMPL_02` | (chưa có) | `fix_report.xlsx` | Developer upload bằng chứng fix |
| `ZBT_TMPL_03` | (chưa có) | `confirm_report.xlsx` | Final Tester xác nhận |

### F4.2. Code Changes (CODE_F02)

Update `download_smw0_template` wrapper forms:

```abap
FORM download_bug_report_template.
  PERFORM download_smw0_template USING 'ZBT_TMPL_01' 'Bug_report.xlsx'.
ENDFORM.

FORM download_fix_report_template.
  PERFORM download_smw0_template USING 'ZBT_TMPL_02' 'fix_report.xlsx'.
ENDFORM.

FORM download_confirm_report_template.
  PERFORM download_smw0_template USING 'ZBT_TMPL_03' 'confirm_report.xlsx'.
ENDFORM.
```

### F4.3. SMW0 Actions

1. T-code **SMW0** → Binary data for WebRFC Applications
2. Tạo (hoặc rename) 3 objects: `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03`
3. Upload file Excel tương ứng cho mỗi template
4. Save + Activate

> **Checkpoint:** Nhấn nút DN_TC/DN_CONF/DN_PROOF → file tải về đúng tên mới.

---

## Bước F5: Status Transition Popup (Screen 0370)

**Mục tiêu:** Popup chuyển trạng thái thay thế `POPUP_GET_VALUES` hiện tại.

**Nguồn:** `docs/requirements.md` Phần 4.

### ⚠️ DESIGN DECISION: Screen Number

**Vấn đề:** Yêu cầu gốc nói Screen 0350, nhưng **0350 hiện là Evidence ALV subscreen** (tab trong Bug Detail). Không thể dùng cùng screen number.

**Giải pháp:** Dùng **Screen 0370** cho Status Transition Popup.

### F5.1. Screen 0370 Design

**Loại:** Modal Dialog Box (popup)
**Kích thước:** ~80 columns x 20 rows

**Read-only Fields:**

| Field | Variable | Label |
|-------|---------|-------|
| BUG_ID | `gv_trans_bug_id` | Mã lỗi |
| TITLE | `gv_trans_title` | Tiêu đề |
| REPORTER | `gv_trans_reporter` | Người báo |
| CURRENT_STATUS | `gv_trans_cur_status` | Trạng thái hiện tại |

**Input Fields:**

| Field | Variable | Type | Label |
|-------|---------|------|-------|
| NEW_STATUS | `gv_trans_new_status` | CHAR 20 | Trạng thái mới |
| DEVELOPER_ID | `gv_trans_dev_id` | CHAR 12 | Developer |
| FINAL_TESTER_ID | `gv_trans_ftester_id` | CHAR 12 | Final Tester |

**Custom Control:**

| Container | Variable | Purpose |
|-----------|---------|---------|
| `CC_TRANS_NOTE` | `go_cont_trans_note` / `go_edit_trans_note` | Text Edit cho TRANS_NOTE |
| (nút) | — | BTN_UPLOAD (upload evidence) |

### F5.2. Global Variables (CODE_TOP)

```abap
" === Screen 0370: Status Transition Popup ===
DATA: gv_trans_bug_id      TYPE zde_bug_id,
      gv_trans_title       TYPE zbug_tracker-title,
      gv_trans_reporter    TYPE zbug_tracker-tester_id,
      gv_trans_cur_status  TYPE zde_bug_status,
      gv_trans_cur_st_text TYPE char20,
      gv_trans_new_status  TYPE zde_bug_status,
      gv_trans_dev_id      TYPE zbug_tracker-dev_id,
      gv_trans_ftester_id  TYPE zbug_tracker-verify_tester_id,
      gv_trans_confirmed   TYPE abap_bool.

" Container objects for trans_note
DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
      go_edit_trans_note TYPE REF TO cl_gui_textedit.
```

### F5.3. Flow Logic (Screen 0370)

```
PROCESS BEFORE OUTPUT.
  MODULE status_0370.
  MODULE init_trans_popup.

PROCESS AFTER INPUT.
  MODULE user_command_0370.

PROCESS ON VALUE-REQUEST.
  FIELD gv_trans_new_status  MODULE f4_trans_status.
  FIELD gv_trans_dev_id      MODULE f4_trans_developer.
  FIELD gv_trans_ftester_id  MODULE f4_trans_ftester.
```

### F5.4. PBO Modules (CODE_PBO)

```abap
MODULE status_0370 OUTPUT.
  SET PF-STATUS 'STATUS_0370'.
  SET TITLEBAR 'T_0370'.
ENDMODULE.

MODULE init_trans_popup OUTPUT.
  " Pre-fill read-only fields
  gv_trans_bug_id     = gs_bug_detail-bug_id.
  gv_trans_title      = gs_bug_detail-title.
  gv_trans_reporter   = gs_bug_detail-tester_id.
  gv_trans_cur_status = gs_bug_detail-status.
  gv_trans_cur_st_text = SWITCH #( gs_bug_detail-status
    WHEN gc_st_new          THEN 'New'
    WHEN gc_st_assigned     THEN 'Assigned'
    WHEN gc_st_inprogress   THEN 'In Progress'
    WHEN gc_st_pending      THEN 'Pending'
    WHEN gc_st_fixed        THEN 'Fixed'
    WHEN gc_st_finaltesting THEN 'Final Testing'
    WHEN gc_st_waiting      THEN 'Waiting'
    WHEN gc_st_rejected     THEN 'Rejected'
    WHEN gc_st_resolved     THEN 'Resolved'
    WHEN gc_st_closed       THEN 'Closed'
    ELSE gs_bug_detail-status ).

  " Pre-fill existing developer/tester
  gv_trans_dev_id     = gs_bug_detail-dev_id.
  gv_trans_ftester_id = gs_bug_detail-verify_tester_id.

  " Init text editor for TRANS_NOTE
  IF go_cont_trans_note IS INITIAL.
    TRY.
        CREATE OBJECT go_cont_trans_note EXPORTING container_name = 'CC_TRANS_NOTE'.
        CREATE OBJECT go_edit_trans_note EXPORTING parent = go_cont_trans_note.
        go_edit_trans_note->set_toolbar_mode( cl_gui_textedit=>false ).
      CATCH cx_root.
        MESSAGE 'Cannot create Transition Note editor.' TYPE 'S' DISPLAY LIKE 'W'.
    ENDTRY.
  ENDIF.

  " Enable/Disable fields based on current status (see Matrix Logic F6)
  PERFORM modify_screen_0370.
ENDMODULE.
```

### F5.5. PAI Module (CODE_PAI)

```abap
MODULE user_command_0370 INPUT.
  DATA: lv_ok TYPE sy-ucomm.
  lv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_ok.
    WHEN 'CONFIRM'.
      " Validate transition
      PERFORM validate_status_transition.
      IF gv_trans_confirmed = abap_true.
        " Apply transition
        PERFORM apply_status_transition.
        " Free container trước khi leave
        IF go_cont_trans_note IS NOT INITIAL.
          go_cont_trans_note->free( ).
          CLEAR: go_cont_trans_note, go_edit_trans_note.
        ENDIF.
        LEAVE TO SCREEN 0.  " Close popup
      ENDIF.

    WHEN 'CANCEL' OR 'BACK'.
      CLEAR gv_trans_confirmed.
      IF go_cont_trans_note IS NOT INITIAL.
        go_cont_trans_note->free( ).
        CLEAR: go_cont_trans_note, go_edit_trans_note.
      ENDIF.
      LEAVE TO SCREEN 0.

    WHEN 'UP_TRANS'.
      " Upload evidence from popup
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Bug not saved yet. Cannot upload evidence.' TYPE 'S' DISPLAY LIKE 'W'.
      ELSE.
        PERFORM upload_evidence_file.
      ENDIF.
  ENDCASE.
ENDMODULE.
```

### F5.6. Gọi Popup từ Screen 0300

Thay thế `POPUP_GET_VALUES` hiện tại:

```abap
" Trong user_command_0300 (CODE_PAI), case 'STATUS_CHG':
WHEN 'STATUS_CHG'.
  CLEAR gv_trans_confirmed.
  CALL SCREEN 0370 STARTING AT 5 3 ENDING AT 85 22.
  IF gv_trans_confirmed = abap_true.
    " Refresh bug detail + ALV
    gv_detail_loaded = abap_false.
    PERFORM load_bug_detail.
  ENDIF.
```

### F5.7. GUI Status `STATUS_0370` (SE41)

| Button | Fcode | Icon | Label |
|--------|-------|------|-------|
| Confirm | `CONFIRM` | ICON_OKAY | Xác nhận |
| Cancel | `CANCEL` | ICON_CANCEL | Hủy |
| Upload Evidence | `UP_TRANS` | ICON_IMPORT | Upload |

**Title Bar `T_0370`:** "Change Bug Status"

> **Checkpoint:** Bug Detail → nút "Change Status" → popup 0370 mở ra → chọn status mới → Confirm → status updated.

---

## Bước F6: Matrix Logic — Transition Rules

**Mục tiêu:** Implement bảng chuyển trạng thái chi tiết cho popup Screen 0370.

**Nguồn:** `docs/requirements.md` Phần 5 + `docs/status-lifecycle.md` Section 2.3/2.4.

### F6.1. modify_screen_0370 — Enable/Disable fields theo current status

```abap
FORM modify_screen_0370.
  LOOP AT SCREEN.
    " Read-only fields: luôn locked
    IF screen-name CS 'GV_TRANS_BUG_ID' OR screen-name CS 'GV_TRANS_TITLE'
       OR screen-name CS 'GV_TRANS_REPORTER' OR screen-name CS 'GV_TRANS_CUR_'.
      screen-input = 0.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " NEW_STATUS: luôn mở (F4 sẽ filter theo allowed transitions)
    IF screen-name CS 'GV_TRANS_NEW_STATUS'.
      screen-input = 1.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " DEVELOPER_ID enable/disable
    IF screen-name CS 'GV_TRANS_DEV_ID'.
      CASE gv_trans_cur_status.
        WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
          screen-input = 1.   " MỞ
        WHEN OTHERS.
          screen-input = 0.   " KHÓA
      ENDCASE.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " FINAL_TESTER_ID enable/disable
    IF screen-name CS 'GV_TRANS_FTESTER_ID'.
      CASE gv_trans_cur_status.
        WHEN gc_st_waiting.
          screen-input = 1.   " MỞ (cho phép chọn khi Manager gán manual)
        WHEN OTHERS.
          screen-input = 0.   " KHÓA
      ENDCASE.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.
  ENDLOOP.

  " Enable/disable TRANS_NOTE text editor
  IF go_edit_trans_note IS NOT INITIAL.
    CASE gv_trans_cur_status.
      WHEN gc_st_assigned OR gc_st_inprogress OR gc_st_finaltesting.
        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>false ). " Mở
      WHEN OTHERS.
        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>true ).  " Khóa
    ENDCASE.
  ENDIF.
ENDFORM.
```

### F6.2. f4_trans_status — F4 chỉ hiện trạng thái hợp lệ

```abap
FORM f4_trans_status.
  TYPES: BEGIN OF ty_st_f4,
           status TYPE zde_bug_status,
           text   TYPE char20,
         END OF ty_st_f4.
  DATA: lt_val TYPE TABLE OF ty_st_f4,
        lt_ret TYPE TABLE OF ddshretval.

  " Build allowed list based on current status + role
  CASE gv_trans_cur_status.
    WHEN gc_st_new.        " Manager only
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned text = 'Assigned' )
          ( status = gc_st_waiting  text = 'Waiting' ) ).
      ENDIF.

    WHEN gc_st_waiting.    " Manager only
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned     text = 'Assigned' )
          ( status = gc_st_finaltesting text = 'Final Testing' ) ).
      ENDIF.

    WHEN gc_st_assigned.   " Dev (assigned) or Manager
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lt_val = VALUE #(
          ( status = gc_st_inprogress text = 'In Progress' )
          ( status = gc_st_rejected   text = 'Rejected' ) ).
      ENDIF.

    WHEN gc_st_inprogress. " Dev (assigned) or Manager
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lt_val = VALUE #(
          ( status = gc_st_fixed    text = 'Fixed' )
          ( status = gc_st_pending  text = 'Pending' )
          ( status = gc_st_rejected text = 'Rejected' ) ).
      ENDIF.

    WHEN gc_st_pending.    " Manager only
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned text = 'Assigned' ) ).
      ENDIF.

    WHEN gc_st_finaltesting. " Final Tester (assigned) only
      IF gs_bug_detail-verify_tester_id = sy-uname OR gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_resolved   text = 'Resolved' )
          ( status = gc_st_inprogress text = 'In Progress' ) ).
      ENDIF.
  ENDCASE.

  IF lt_val IS INITIAL.
    MESSAGE 'No valid transitions available for your role.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'STATUS' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = 'GV_TRANS_NEW_STATUS'
              value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.
```

### F6.3. validate_status_transition — Validation trước khi confirm

```abap
FORM validate_status_transition.
  gv_trans_confirmed = abap_false.

  " 1. New status phải được chọn
  IF gv_trans_new_status IS INITIAL.
    MESSAGE 'Please select a new status.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 2. Validate allowed transition (dùng lại logic từ f4_trans_status)
  DATA: lt_allowed TYPE TABLE OF zde_bug_status.
  CASE gv_trans_cur_status.
    WHEN gc_st_new.
      APPEND gc_st_assigned TO lt_allowed.
      APPEND gc_st_waiting  TO lt_allowed.
    WHEN gc_st_waiting.
      APPEND gc_st_assigned     TO lt_allowed.
      APPEND gc_st_finaltesting TO lt_allowed.
    WHEN gc_st_assigned.
      APPEND gc_st_inprogress TO lt_allowed.
      APPEND gc_st_rejected   TO lt_allowed.
    WHEN gc_st_inprogress.
      APPEND gc_st_fixed      TO lt_allowed.
      APPEND gc_st_pending    TO lt_allowed.
      APPEND gc_st_rejected   TO lt_allowed.
    WHEN gc_st_pending.
      APPEND gc_st_assigned   TO lt_allowed.
    WHEN gc_st_finaltesting.
      APPEND gc_st_resolved   TO lt_allowed.
      APPEND gc_st_inprogress TO lt_allowed.
  ENDCASE.

  READ TABLE lt_allowed TRANSPORTING NO FIELDS
    WITH KEY table_line = gv_trans_new_status.
  IF sy-subrc <> 0.
    MESSAGE |Invalid status transition: { gv_trans_cur_status } -> { gv_trans_new_status }| TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 3. Role check
  DATA: lv_role_ok TYPE abap_bool VALUE abap_false.
  CASE gv_trans_cur_status.
    WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
      IF gv_role = 'M'. lv_role_ok = abap_true. ENDIF.
    WHEN gc_st_assigned OR gc_st_inprogress.
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lv_role_ok = abap_true.
      ENDIF.
    WHEN gc_st_finaltesting.
      IF gs_bug_detail-verify_tester_id = sy-uname OR gv_role = 'M'.
        lv_role_ok = abap_true.
      ENDIF.
  ENDCASE.
  IF lv_role_ok = abap_false.
    MESSAGE 'You do not have permission to perform this transition.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 4. Required fields check
  " 4a. DEVELOPER_ID required for → Assigned
  IF gv_trans_new_status = gc_st_assigned AND gv_trans_dev_id IS INITIAL.
    MESSAGE 'Developer ID is required for Assigned status.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 4b. DEVELOPER_ID + FINAL_TESTER_ID required for Waiting → Final Testing
  IF gv_trans_cur_status = gc_st_waiting AND gv_trans_new_status = gc_st_finaltesting.
    IF gv_trans_dev_id IS INITIAL.
      MESSAGE 'Developer ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
    IF gv_trans_ftester_id IS INITIAL.
      MESSAGE 'Final Tester ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " 4c. TRANS_NOTE required for → Rejected
  IF gv_trans_new_status = gc_st_rejected.
    DATA: lt_note_check TYPE TABLE OF char255.
    IF go_edit_trans_note IS NOT INITIAL.
      go_edit_trans_note->get_text_as_r3table( IMPORTING table = lt_note_check ).
    ENDIF.
    IF lt_note_check IS INITIAL.
      MESSAGE 'Rejection reason (note) is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " 4d. Evidence required for → Fixed
  IF gv_trans_new_status = gc_st_fixed.
    SELECT COUNT(*) FROM zbug_evidence
      WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
    IF sy-dbcnt = 0.
      MESSAGE 'Evidence file is required before marking as Fixed.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " 4e. TRANS_NOTE for → Resolved (test result)
  IF gv_trans_new_status = gc_st_resolved.
    DATA: lt_note_res TYPE TABLE OF char255.
    IF go_edit_trans_note IS NOT INITIAL.
      go_edit_trans_note->get_text_as_r3table( IMPORTING table = lt_note_res ).
    ENDIF.
    IF lt_note_res IS INITIAL.
      MESSAGE 'Test result note is required for Resolved.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  gv_trans_confirmed = abap_true.
ENDFORM.
```

### F6.4. apply_status_transition — Thực hiện chuyển trạng thái

```abap
FORM apply_status_transition.
  DATA: lv_old_status TYPE zde_bug_status.
  lv_old_status = gs_bug_detail-status.

  " Update bug detail
  gs_bug_detail-status = gv_trans_new_status.

  " Update developer/tester nếu có
  IF gv_trans_dev_id IS NOT INITIAL.
    gs_bug_detail-dev_id = gv_trans_dev_id.
  ENDIF.
  IF gv_trans_ftester_id IS NOT INITIAL.
    gs_bug_detail-verify_tester_id = gv_trans_ftester_id.
  ENDIF.

  " Save TRANS_NOTE vào Dev Note (Z002) nếu → Rejected
  IF gv_trans_new_status = gc_st_rejected AND go_edit_trans_note IS NOT INITIAL.
    DATA: lt_trans_note TYPE TABLE OF char255.
    go_edit_trans_note->get_text_as_r3table( IMPORTING table = lt_trans_note ).
    IF lt_trans_note IS NOT INITIAL.
      PERFORM save_long_text USING 'Z002' lt_trans_note.
    ENDIF.
  ENDIF.

  " Save TRANS_NOTE vào Tester Note (Z003) nếu Final Testing → Resolved hoặc → In Progress
  IF gv_trans_cur_status = gc_st_finaltesting AND go_edit_trans_note IS NOT INITIAL.
    DATA: lt_tstr_note TYPE TABLE OF char255.
    go_edit_trans_note->get_text_as_r3table( IMPORTING table = lt_tstr_note ).
    IF lt_tstr_note IS NOT INITIAL.
      PERFORM save_long_text USING 'Z003' lt_tstr_note.
    ENDIF.
  ENDIF.

  " Update timestamps
  gs_bug_detail-aenam = sy-uname.
  gs_bug_detail-aedat = sy-datum.
  gs_bug_detail-aezet = sy-uzeit.

  " Update DB
  UPDATE zbug_tracker FROM gs_bug_detail.
  IF sy-subrc = 0.
    COMMIT WORK.
    " Log history
    PERFORM log_history USING lv_old_status gv_trans_new_status.
    " Trigger auto-assign nếu status = Fixed
    IF gv_trans_new_status = gc_st_fixed.
      PERFORM auto_assign_tester.
    ENDIF.
    MESSAGE |Status changed: { lv_old_status } -> { gv_trans_new_status }| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Failed to update bug status.' TYPE 'S' DISPLAY LIKE 'E'.
    gs_bug_detail-status = lv_old_status.
  ENDIF.
ENDFORM.
```

---

## Bước F7: Auto-Assign System

**Mục tiêu:** Tự động gán Developer/Tester khi chuyển trạng thái.

**Nguồn:** `docs/requirements.md` Phần 6 + `docs/status-lifecycle.md` Section 2.5.

### F7.1. Phase A: Auto-Assign Developer (New → Assigned/Waiting)

**Trigger:** Sau khi tạo bug mới thành công (status = 1).

```abap
FORM auto_assign_developer.
  " Chỉ trigger khi bug mới tạo (status = New)
  CHECK gs_bug_detail-status = gc_st_new.

  TYPES: BEGIN OF ty_dev_workload,
           user_id   TYPE zbug_users-user_id,
           workload  TYPE i,
         END OF ty_dev_workload.
  DATA: lt_candidates TYPE TABLE OF ty_dev_workload,
        ls_best       TYPE ty_dev_workload.

  " 1. Lấy danh sách Developer cùng project + cùng module
  SELECT u~user_id
    FROM zbug_user_projec AS u
    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
    WHERE u~project_id = @gs_bug_detail-project_id
      AND u~role = 'D'
      AND usr~sap_module = @gs_bug_detail-sap_module
      AND usr~is_del <> 'X'
    INTO TABLE @DATA(lt_devs).

  IF lt_devs IS INITIAL.
    " Không có Dev → Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM log_history USING gc_st_new gc_st_waiting.
    " Email cho Manager
    " PERFORM send_email_bcs USING 'WAITING' ...
    MESSAGE 'No available developer. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 2. Tính workload cho mỗi Dev
  LOOP AT lt_devs INTO DATA(ls_dev).
    DATA(ls_cand) = VALUE ty_dev_workload( user_id = ls_dev-user_id ).
    SELECT COUNT(*) FROM zbug_tracker
      WHERE dev_id = @ls_dev-user_id
        AND status IN (@gc_st_assigned, @gc_st_inprogress, @gc_st_pending, @gc_st_finaltesting)
        AND is_del <> 'X'.
    ls_cand-workload = sy-dbcnt.
    IF ls_cand-workload < 5.
      APPEND ls_cand TO lt_candidates.
    ENDIF.
  ENDLOOP.

  IF lt_candidates IS INITIAL.
    " Tất cả Dev quá tải → Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM log_history USING gc_st_new gc_st_waiting.
    MESSAGE 'All developers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 3. Chọn Dev ít việc nhất
  SORT lt_candidates BY workload ASCENDING.
  READ TABLE lt_candidates INTO ls_best INDEX 1.

  " 4. Gán
  gs_bug_detail-dev_id = ls_best-user_id.
  gs_bug_detail-status = gc_st_assigned.
  UPDATE zbug_tracker
    SET dev_id = @ls_best-user_id
        status = @gc_st_assigned
    WHERE bug_id = @gs_bug_detail-bug_id.
  COMMIT WORK.
  PERFORM log_history USING gc_st_new gc_st_assigned.
  MESSAGE |Bug auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })| TYPE 'S'.
ENDFORM.
```

### F7.2. Phase B: Auto-Assign Tester (Fixed → Final Testing/Waiting)

**Trigger:** Sau khi Developer chuyển status sang Fixed (5).

```abap
FORM auto_assign_tester.
  CHECK gs_bug_detail-status = gc_st_fixed.

  TYPES: BEGIN OF ty_tst_workload,
           user_id   TYPE zbug_users-user_id,
           workload  TYPE i,
         END OF ty_tst_workload.
  DATA: lt_candidates TYPE TABLE OF ty_tst_workload,
        ls_best       TYPE ty_tst_workload.

  " 1. Lấy danh sách Tester cùng project + cùng module
  SELECT u~user_id
    FROM zbug_user_projec AS u
    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
    WHERE u~project_id = @gs_bug_detail-project_id
      AND u~role = 'T'
      AND usr~sap_module = @gs_bug_detail-sap_module
      AND usr~is_del <> 'X'
    INTO TABLE @DATA(lt_testers).

  IF lt_testers IS INITIAL.
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM log_history USING gc_st_fixed gc_st_waiting.
    MESSAGE 'No available tester. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 2. Tính workload
  LOOP AT lt_testers INTO DATA(ls_tst).
    DATA(ls_cand) = VALUE ty_tst_workload( user_id = ls_tst-user_id ).
    SELECT COUNT(*) FROM zbug_tracker
      WHERE verify_tester_id = @ls_tst-user_id
        AND status = @gc_st_finaltesting
        AND is_del <> 'X'.
    ls_cand-workload = sy-dbcnt.
    IF ls_cand-workload < 5.
      APPEND ls_cand TO lt_candidates.
    ENDIF.
  ENDLOOP.

  IF lt_candidates IS INITIAL.
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM log_history USING gc_st_fixed gc_st_waiting.
    MESSAGE 'All testers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 3. Chọn Tester ít việc nhất
  SORT lt_candidates BY workload ASCENDING.
  READ TABLE lt_candidates INTO ls_best INDEX 1.

  " 4. Gán + chuyển sang Final Testing
  gs_bug_detail-verify_tester_id = ls_best-user_id.
  gs_bug_detail-status = gc_st_finaltesting.
  UPDATE zbug_tracker
    SET verify_tester_id = @ls_best-user_id
        status = @gc_st_finaltesting
    WHERE bug_id = @gs_bug_detail-bug_id.
  COMMIT WORK.
  PERFORM log_history USING gc_st_fixed gc_st_finaltesting.
  MESSAGE |Bug auto-assigned to tester { ls_best-user_id } for Final Testing| TYPE 'S'.
ENDFORM.
```

### F7.3. Integration Points

Gọi `auto_assign_developer`:
- Sau `save_bug_detail` khi Create mode thành công

Gọi `auto_assign_tester`:
- Trong `apply_status_transition` khi `gv_trans_new_status = gc_st_fixed`

---

## Bước F8: Test Data Population

**Mục tiêu:** Tạo dữ liệu test cho auto-assign algorithm.

**Nguồn:** `docs/requirements.md` Phần 7.

### F8.1. Report tạo test data (SE38)

Tạo report `Z_BUG_POPULATE_TESTDATA` (Type 1, Executable):

```abap
REPORT z_bug_populate_testdata.

" ── 20 Developers ──
DATA: lt_devs TYPE TABLE OF zbug_users.
DO 5 TIMES.
  DATA(lv_idx) = sy-index.
  APPEND VALUE zbug_users( user_id = |DEV_FI_0{ lv_idx }|   full_name = |Dev FI { lv_idx }|
    role = 'D' sap_module = 'FI'   email = |dev_fi_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_devs.
  APPEND VALUE zbug_users( user_id = |DEV_MM_0{ lv_idx }|   full_name = |Dev MM { lv_idx }|
    role = 'D' sap_module = 'MM'   email = |dev_mm_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_devs.
  APPEND VALUE zbug_users( user_id = |DEV_SD_0{ lv_idx }|   full_name = |Dev SD { lv_idx }|
    role = 'D' sap_module = 'SD'   email = |dev_sd_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_devs.
  APPEND VALUE zbug_users( user_id = |DEV_ABAP_0{ lv_idx }| full_name = |Dev ABAP { lv_idx }|
    role = 'D' sap_module = 'ABAP' email = |dev_abap_0{ lv_idx }@test.com| erdat = sy-datum ernam = sy-uname ) TO lt_devs.
ENDDO.

" ── 10 Testers ──
DATA: lt_testers TYPE TABLE OF zbug_users.
DO 2 TIMES.
  lv_idx = sy-index.
  APPEND VALUE zbug_users( user_id = |TST_FI_0{ lv_idx }|   full_name = |Tester FI { lv_idx }|
    role = 'T' sap_module = 'FI'   email = |tst_fi_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_testers.
  APPEND VALUE zbug_users( user_id = |TST_MM_0{ lv_idx }|   full_name = |Tester MM { lv_idx }|
    role = 'T' sap_module = 'MM'   email = |tst_mm_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_testers.
  APPEND VALUE zbug_users( user_id = |TST_SD_0{ lv_idx }|   full_name = |Tester SD { lv_idx }|
    role = 'T' sap_module = 'SD'   email = |tst_sd_0{ lv_idx }@test.com|   erdat = sy-datum ernam = sy-uname ) TO lt_testers.
  APPEND VALUE zbug_users( user_id = |TST_ABAP_0{ lv_idx }| full_name = |Tester ABAP { lv_idx }|
    role = 'T' sap_module = 'ABAP' email = |tst_abap_0{ lv_idx }@test.com| erdat = sy-datum ernam = sy-uname ) TO lt_testers.
ENDDO.
" 2 dự phòng
APPEND VALUE zbug_users( user_id = 'TST_GEN_01' full_name = 'Tester General 1'
  role = 'T' sap_module = 'BASIS' email = 'tst_gen_01@test.com' erdat = sy-datum ernam = sy-uname ) TO lt_testers.
APPEND VALUE zbug_users( user_id = 'TST_GEN_02' full_name = 'Tester General 2'
  role = 'T' sap_module = 'PP'    email = 'tst_gen_02@test.com' erdat = sy-datum ernam = sy-uname ) TO lt_testers.

" ── Insert ──
INSERT zbug_users FROM TABLE lt_devs ACCEPTING DUPLICATE KEYS.
INSERT zbug_users FROM TABLE lt_testers ACCEPTING DUPLICATE KEYS.
COMMIT WORK.

WRITE: / 'Inserted', lines( lt_devs ), 'developers.'.
WRITE: / 'Inserted', lines( lt_testers ), 'testers.'.
```

### F8.2. Workload Test Scenario

Sau khi tạo users, gán thủ công bugs để test workload:
- `DEV_FI_01`: 6 bugs (status 2,3,4) → sẽ bị bỏ qua (> 5)
- `DEV_FI_02`: 2 bugs → sẽ được chọn
- `DEV_FI_03`: 4 bugs
- `DEV_FI_04`: 0 bugs → sẽ được chọn (ít nhất)
- `DEV_FI_05`: 3 bugs

### F8.3. Gán users vào project test

Cần INSERT vào `ZBUG_USER_PROJEC` để gán users vào project:

```abap
" Ví dụ: gán vào project 'TESTPRJ01'
DATA: lt_assign TYPE TABLE OF zbug_user_projec.
LOOP AT lt_devs ASSIGNING FIELD-SYMBOL(<dev>).
  APPEND VALUE zbug_user_projec(
    user_id    = <dev>-user_id
    project_id = 'TESTPRJ01'
    role       = 'D'
    ernam      = sy-uname
    erdat      = sy-datum ) TO lt_assign.
ENDLOOP.
LOOP AT lt_testers ASSIGNING FIELD-SYMBOL(<tst>).
  APPEND VALUE zbug_user_projec(
    user_id    = <tst>-user_id
    project_id = 'TESTPRJ01'
    role       = 'T'
    ernam      = sy-uname
    erdat      = sy-datum ) TO lt_assign.
ENDLOOP.
INSERT zbug_user_projec FROM TABLE lt_assign ACCEPTING DUPLICATE KEYS.
COMMIT WORK.
```

> **Checkpoint:** Chạy `Z_BUG_POPULATE_TESTDATA` → SE16 `ZBUG_USERS` → 30 users mới. Tạo bug FI module → auto-assign chọn `DEV_FI_04` (workload thấp nhất).

---

## Bước F9: Bug Search Engine (Screen 0210/0220)

**Mục tiêu:** Tìm kiếm bug nâng cao với popup nhập điều kiện + full screen kết quả.

**Nguồn:** `docs/requirements.md` Phần 8.

### F9.1. Flow

```
Screen 0200 (Bug List + Dashboard)
  └── [SEARCH] → Screen 0210 (Popup — nhập điều kiện)
       └── [EXECUTE] → Screen 0220 (Full screen — kết quả, KHÔNG dashboard)
            └── [BACK] → Screen 0200
```

### F9.2. Global Variables (CODE_TOP)

```abap
" === Bug Search Fields (Screen 0210) ===
DATA: s_bug_id  TYPE zde_bug_id,
      s_title   TYPE char40,          " Wildcard search
      s_status  TYPE zde_bug_status,
      s_prio    TYPE char10,
      s_mod     TYPE zde_sap_module,
      s_reporter TYPE char12,
      s_dev     TYPE char12.

" === Search Results (Screen 0220) ===
DATA: gt_search_results TYPE TABLE OF zbug_tracker,
      go_search_alv     TYPE REF TO cl_gui_alv_grid,
      go_cont_search    TYPE REF TO cl_gui_custom_container.
```

### F9.3. Screen 0210 (Popup — Search Input)

**Loại:** Modal Dialog Box
**Kích thước:** ~70 columns x 15 rows

**Fields:**

| Field | Variable | Label | F4 Help |
|-------|---------|-------|---------|
| Bug ID | `S_BUG_ID` | Mã lỗi | — |
| Title | `S_TITLE` | Tiêu đề (*keyword*) | — |
| Status | `S_STATUS` | Trạng thái | F4 (10 statuses) |
| Priority | `S_PRIO` | Độ ưu tiên | F4 (H/M/L) |
| Module | `S_MOD` | Module SAP | F4 (từ f4_sap_module) |
| Reporter | `S_REPORTER` | Người báo | F4 (từ ZBUG_USERS) |
| Developer | `S_DEV` | Người xử lý | F4 (từ ZBUG_USERS WHERE role='D') |

**Flow Logic:**

```
PROCESS BEFORE OUTPUT.
  MODULE status_0210.

PROCESS AFTER INPUT.
  MODULE user_command_0210.

PROCESS ON VALUE-REQUEST.
  FIELD s_status  MODULE f4_bug_search_status.
  FIELD s_prio    MODULE f4_bug_search_priority.
  FIELD s_mod     MODULE f4_bug_search_module.
  FIELD s_reporter MODULE f4_bug_search_reporter.
  FIELD s_dev     MODULE f4_bug_search_developer.
```

### F9.4. Screen 0220 (Full screen — Search Results)

**Loại:** Normal Screen (full screen)

**Layout:** Custom Control `CC_SEARCH_RESULTS` chiếm toàn bộ diện tích. **KHÔNG** có Dashboard.

**Flow Logic:**

```
PROCESS BEFORE OUTPUT.
  MODULE status_0220.
  MODULE init_search_results.

PROCESS AFTER INPUT.
  MODULE user_command_0220.
```

### F9.5. PBO/PAI Modules

```abap
" === Screen 0210 (Popup) ===
MODULE status_0210 OUTPUT.
  SET PF-STATUS 'STATUS_0210'.
  SET TITLEBAR 'T_0210'.
ENDMODULE.

MODULE user_command_0210 INPUT.
  DATA: lv_ok TYPE sy-ucomm.
  lv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_ok.
    WHEN 'EXECUTE' OR 'ONLI'.
      PERFORM execute_bug_search.
      LEAVE TO SCREEN 0.      " Close popup
      CALL SCREEN 0220.       " Open full screen results

    WHEN 'CANCEL' OR 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

" === Screen 0220 (Full screen results) ===
MODULE status_0220 OUTPUT.
  SET PF-STATUS 'STATUS_0220'.
  SET TITLEBAR 'T_0220'.
ENDMODULE.

MODULE init_search_results OUTPUT.
  IF go_cont_search IS INITIAL.
    CREATE OBJECT go_cont_search EXPORTING container_name = 'CC_SEARCH_RESULTS'.
    CREATE OBJECT go_search_alv EXPORTING i_parent = go_cont_search.
    " Build field catalog (reuse from build_bug_fieldcat)
    DATA: lt_fcat TYPE lvc_t_fcat.
    PERFORM build_bug_fieldcat CHANGING lt_fcat.
    go_search_alv->set_table_for_first_display(
      EXPORTING is_layout = VALUE lvc_s_layo( zebra = 'X' sel_mode = 'A' )
      CHANGING  it_fieldcatalog = lt_fcat
                it_outtab = gt_search_results ).
  ELSE.
    go_search_alv->refresh_table_display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0220 INPUT.
  DATA: lv_ok TYPE sy-ucomm.
  lv_ok = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      IF go_cont_search IS NOT INITIAL.
        go_cont_search->free( ).
        CLEAR: go_cont_search, go_search_alv.
      ENDIF.
      LEAVE TO SCREEN 0.   " Quay về Screen 0200
  ENDCASE.
ENDMODULE.
```

### F9.6. Search Logic (CODE_F01)

```abap
FORM execute_bug_search.
  DATA: lv_title_pattern TYPE string.

  " Wildcard support: *keyword* → %keyword%
  IF s_title IS NOT INITIAL.
    lv_title_pattern = s_title.
    REPLACE ALL OCCURRENCES OF '*' IN lv_title_pattern WITH '%'.
    IF lv_title_pattern(1) <> '%'.
      lv_title_pattern = '%' && lv_title_pattern.
    ENDIF.
    IF lv_title_pattern+( strlen( lv_title_pattern ) - 1 ) <> '%'.
      lv_title_pattern = lv_title_pattern && '%'.
    ENDIF.
  ENDIF.

  " Security: scope to current project context
  SELECT * FROM zbug_tracker
    WHERE is_del <> 'X'
      AND project_id = @gv_current_project_id
      AND ( @s_bug_id IS INITIAL OR bug_id = @s_bug_id )
      AND ( @s_status IS INITIAL OR status = @s_status )
      AND ( @s_prio IS INITIAL   OR priority = @s_prio )
      AND ( @s_mod IS INITIAL    OR sap_module = @s_mod )
      AND ( @s_reporter IS INITIAL OR tester_id = @s_reporter )
      AND ( @s_dev IS INITIAL    OR dev_id = @s_dev )
    INTO TABLE @gt_search_results.

  " Title wildcard filter (post-SELECT vì STRING field)
  IF s_title IS NOT INITIAL.
    DELETE gt_search_results WHERE NOT title CP s_title.
  ENDIF.

  IF gt_search_results IS INITIAL.
    MESSAGE 'No bugs found matching criteria.' TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    MESSAGE |Found { lines( gt_search_results ) } bug(s).| TYPE 'S'.
  ENDIF.
ENDFORM.
```

### F9.7. Nút SEARCH trên Screen 0200

Thêm Fcode `SEARCH` vào GUI Status `STATUS_0200`:

| Button | Fcode | Icon | Label |
|--------|-------|------|-------|
| Search Bug | `SEARCH` | ICON_SEARCH | Search Bug |

Trong `user_command_0200`:
```abap
WHEN 'SEARCH'.
  " Clear previous search
  CLEAR: s_bug_id, s_title, s_status, s_prio, s_mod, s_reporter, s_dev.
  CALL SCREEN 0210 STARTING AT 5 3 ENDING AT 75 18.
```

### F9.8. GUI Statuses

**`STATUS_0210`** (Popup):

| Button | Fcode | Icon |
|--------|-------|------|
| Execute | `EXECUTE` | ICON_EXECUTE_OBJECT |
| Cancel | `CANCEL` | ICON_CANCEL |

**`STATUS_0220`** (Full screen):

| Button | Fcode | Icon |
|--------|-------|------|
| Back | `BACK` | ICON_BACK |
| Exit | `EXIT` | ICON_EXIT |
| Cancel | `CANCEL` | ICON_CANCEL |

**Title Bars:**
- `T_0210`: "Bug Search"
- `T_0220`: "Search Results"

### F9.9. Container Names

| Screen | Container | Variable |
|--------|-----------|---------|
| 0220 | `CC_SEARCH_RESULTS` | `go_cont_search` / `go_search_alv` |

> **Checkpoint:** Screen 0200 → nút SEARCH → popup 0210 → nhập filter → Execute → Screen 0220 (full screen ALV, không dashboard) → Back → quay về 0200.

---

## Tổng kết Phase F

### New Screens

| Screen | Type | Purpose | Container(s) |
|--------|------|---------|-------------|
| **0410** | Normal | Project Search (new initial screen) | — |
| **0370** | Modal Dialog | Status Transition Popup | `CC_TRANS_NOTE` |
| **0210** | Modal Dialog | Bug Search Input | — |
| **0220** | Normal | Bug Search Results | `CC_SEARCH_RESULTS` |

### New GUI Statuses (SE41)

| Status | Screen | Buttons |
|--------|--------|---------|
| `STATUS_0410` | 0410 | EXECUTE, BACK, EXIT, CANCEL |
| `STATUS_0370` | 0370 | CONFIRM, CANCEL, UP_TRANS |
| `STATUS_0210` | 0210 | EXECUTE, CANCEL |
| `STATUS_0220` | 0220 | BACK, EXIT, CANCEL |

### Updated GUI Statuses

| Status | Changes |
|--------|---------|
| `STATUS_0200` | +SEARCH button |

### New Title Bars (SE41)

| Title | Text |
|-------|------|
| `T_0410` | Project Search |
| `T_0370` | Change Bug Status |
| `T_0210` | Bug Search |
| `T_0220` | Search Results |

### Updated Code Files

| File | Version | Key Changes |
|------|---------|-------------|
| `CODE_TOP.md` | v5.0 | +10 status constants, +dashboard vars, +search vars, +transition vars |
| `CODE_F00.md` | v5.0 | +build_search_fieldcat (optional, reuse bug fieldcat) |
| `CODE_PBO.md` | v5.0 | +status_0410, +init_trans_popup, +status_0210, +init_search_results, +modify_screen_0370, +TRY-CATCH for containers, +dashboard calc |
| `CODE_PAI.md` | v5.0 | +user_command_0410, +user_command_0370, +user_command_0210, +user_command_0220, +f4 modules (trans, search), +f4_bug_sapmodule |
| `CODE_F01.md` | v5.0 | +search_projects, +calculate_dashboard, +auto_assign_developer, +auto_assign_tester, +validate_status_transition, +apply_status_transition, +execute_bug_search, fix MESSAGE types, fix Manager transition |
| `CODE_F02.md` | v5.0 | +f4_sap_module, +f4_project_id_help, +f4_manager_help, +f4_project_status_help, +f4_trans_status, fix READ_TEXT type cast, update template names |

### SE93 Change

T-code `ZBUG_WS` initial screen: **0400 → 0410**

### Checklist trước khi code

- [ ] Fix 11 bugs (F0)
- [ ] Update status constants v5.0 (F1)
- [ ] Migration script cho status '6' (F1.3)
- [ ] Screen 0410 layout + flow logic (F2)
- [ ] Screen 0200 dashboard fields (F3)
- [ ] SMW0 templates rename (F4)
- [ ] Screen 0370 layout + flow logic (F5)
- [ ] Matrix logic implement (F6)
- [ ] Auto-assign forms (F7)
- [ ] Test data population report (F8)
- [ ] Screen 0210/0220 layout + flow logic (F9)
- [ ] New GUI Statuses + Title Bars (SE41)
- [ ] Update SE93 initial screen
- [ ] Full regression test

---

*File này mô tả toàn bộ Phase F — v5.0 Enhancement. Tất cả code snippets sẽ được consolidate vào CODE v5.0 files.*
*Tạo bởi OpenCode agent — 13/04/2026*
