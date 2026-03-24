# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE C: MODULE POOL UI

**Dự án:** SAP Bug Tracking Management System  
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)  
**Thời gian ước tính:** 4 ngày (27-31/03)  
**Yêu cầu:** Hoàn thành Phase A + B trước khi bắt đầu Phase C  

---

## MỤC LỤC

1. [Bước C1: Tạo Module Pool Program + Includes](#bước-c1-tạo-module-pool-program--includes)
2. [Bước C2: Include TOP — Global Declarations](#bước-c2-include-top--global-declarations)
3. [Bước C3: Screen 0100 — Main Hub (Router)](#bước-c3-screen-0100--main-hub-router)
4. [Bước C4: Screen 0200 — Bug List (ALV Grid)](#bước-c4-screen-0200--bug-list-alv-grid)
5. [Bước C5: Screen 0300 — Bug Detail (Tab Strip)](#bước-c5-screen-0300--bug-detail-tab-strip)
6. [Bước C6: Screen 0400 — Project List (ALV Grid)](#bước-c6-screen-0400--project-list-alv-grid)
7. [Bước C7-C10: GUI Statuses, F4, Dynamic Screen](#bước-c7-c10-còn-lại)

---

## Bước C1: Tạo Module Pool Program + Includes

**Mục tiêu:** Tạo program Type M với 6 includes.

Vào **SE80** → chọn "Program" → nhập `Z_BUG_WORKSPACE_MP` → **Enter**.

- **Chọn:** "With TOP INCL."
- **Type:** Module Pool (M)
- **Status:** Test Program (T)
- **Package:** `ZBUGTRACK`

SAP tự tạo include `Z_BUG_WS_TOP` (TOP include).

Tạo thêm 5 includes:

1. Chuột phải vào program → **Create** → Include → `Z_BUG_WS_PBO`
2. Chuột phải vào program → **Create** → Include → `Z_BUG_WS_PAI`
3. Chuột phải vào program → **Create** → Include → `Z_BUG_WS_F00`
4. Chuột phải vào program → **Create** → Include → `Z_BUG_WS_F01`
5. Chuột phải vào program → **Create** → Include → `Z_BUG_WS_F02`

**Trong main program `Z_BUG_WORKSPACE_MP`, thêm:**

```abap
PROGRAM z_bug_workspace_mp.

INCLUDE z_bug_ws_top.    " Global data declarations
INCLUDE z_bug_ws_pbo.    " Process Before Output modules
INCLUDE z_bug_ws_pai.    " Process After Input modules
INCLUDE z_bug_ws_f00.    " ALV setup + Event handler class
INCLUDE z_bug_ws_f01.    " Business logic FORM routines
INCLUDE z_bug_ws_f02.    " Helper: F4, Long Text, Popup, GOS
```

Nhấn **Save** + **Activate**.

> ✅ **Checkpoint:** **SE80** → `Z_BUG_WORKSPACE_MP` → thấy 6 includes trong navigation tree.

---

## Bước C2: Include TOP — Global Declarations

**Mục tiêu:** Khai báo tất cả biến global, types, constants.

**Mở include `Z_BUG_WS_TOP`:**

```abap
*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_TOP — Global Declarations
*&---------------------------------------------------------------------*

" === CONSTANTS ===
CONSTANTS:
  gc_mode_display TYPE char1 VALUE 'D',
  gc_mode_change  TYPE char1 VALUE 'C',
  gc_mode_create  TYPE char1 VALUE 'X'.

" === GLOBAL VARIABLES ===
DATA: gv_ok_code   TYPE sy-ucomm,
      gv_save_ok   TYPE sy-ucomm,
      gv_mode      TYPE char1,           " D/C/X
      gv_role      TYPE zbug_users-role,  " T/D/M
      gv_current_bug_id     TYPE zde_bug_id,
      gv_current_project_id TYPE zde_project_id.

" === ALV OBJECTS ===
DATA: go_cont_bug    TYPE REF TO cl_gui_custom_container,
      go_alv_bug     TYPE REF TO cl_gui_alv_grid.

" === TEXT EDIT OBJECTS ===
DATA: go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
      go_edit_dev_note  TYPE REF TO cl_gui_textedit.

" === ALV DATA TYPES ===
TYPES: BEGIN OF ty_bug_alv,
         bug_id        TYPE zde_bug_id,
         title         TYPE zde_bug_title,
         project_id    TYPE zde_project_id,
         status_text   TYPE char20,
         " ... [other columns] ...
         t_color       TYPE lvc_t_scol,  " ALV row color
       END OF ty_bug_alv.

DATA: gt_bugs     TYPE TABLE OF ty_bug_alv,
      gs_bug_detail TYPE zbug_tracker.

" === TAB STRIP ===
DATA: gv_active_tab TYPE char20 VALUE 'TAB_INFO'.
```

Nhấn **Save** + **Activate**.

---

## Bước C3: Screen 0100 — Main Hub (Router)

**Mục tiêu:** Screen đầu tiên, đọc role user và điều hướng.

Vào **SE80** → `Z_BUG_WORKSPACE_MP` → chuột phải → **Create** → **Screen** → `0100`.

**Flow Logic:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE init_user_role.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

**Trong `Z_BUG_WS_PBO`:**

```abap
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Workspace'.
ENDMODULE.

MODULE init_user_role OUTPUT.
  SELECT SINGLE role FROM zbug_users INTO @gv_role
    WHERE user_id = @sy-uname AND is_del <> 'X'.
  IF sy-subrc <> 0.
    MESSAGE s003(zbug_msg) DISPLAY LIKE 'E'.
    LEAVE PROGRAM.
  ENDIF.
ENDMODULE.
```

**Trong `Z_BUG_WS_PAI`:**

```abap
MODULE user_command_0100 INPUT.
  gv_save_ok = gv_ok_code.
  CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'. LEAVE PROGRAM.
    WHEN 'BUG_LIST'. CALL SCREEN 0200.
  ENDCASE.
ENDMODULE.
```

> ✅ **Checkpoint:** Chạy thử Main Hub hiển thị chuẩn bị chuyển màn hình.

---

## Bước C4: Screen 0200 — Bug List (ALV Grid)

**Mục tiêu:** ALV Grid hiển thị danh sách bug với toolbar buttons.

Tạo Screen **0200**.

**Screen Layout:** Tạo 1 Custom Container `CC_BUG_LIST`.

**Flow Logic:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  MODULE init_bug_list.

PROCESS AFTER INPUT.
  MODULE user_command_0200.
```

**Trong `Z_BUG_WS_PBO`:**

```abap
MODULE init_bug_list OUTPUT.
  PERFORM select_bug_data.
  IF go_alv_bug IS INITIAL.
    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
    CREATE OBJECT go_alv_bug EXPORTING i_parent = go_cont_bug.
    PERFORM build_bug_fieldcat.
    " setup Layout...
    go_alv_bug->set_table_for_first_display( ... ).
  ELSE.
    go_alv_bug->refresh_table_display( ).
  ENDIF.
ENDMODULE.
```

---

## Bước C5: Screen 0300 — Bug Detail (Tab Strip)

**Mục tiêu:** Màn hình chi tiết bug với Tab Strip cho notes, evidence, history.

Tạo Screen **0300**.

**Phần dưới: Tab Strip control (`TS_DETAIL`)**

- 5 Tabs tương ứng Subscreens:
  - `0310`: Bug Info Fields
  - `0320`: Container `CC_DEV_NOTE`
  - `0330`: Container `CC_FUNC_NOTE`
  - `0340`: Container `CC_ROOTCAUSE`
  - `0350`: Container `CC_EVIDENCE`
  - `0360`: Container `CC_HISTORY`

**Flow Logic 0300:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE load_bug_detail.
  MODULE modify_screen_0300.
  CALL SUBSCREEN ss_tab INCLUDING sy-repid gv_active_subscreen.

PROCESS AFTER INPUT.
  CALL SUBSCREEN ss_tab.
  MODULE user_command_0300.
```

**`modify_screen_0300` logic:** (Dynamic Control)

```abap
MODULE modify_screen_0300 OUTPUT.
  LOOP AT SCREEN.
    IF gv_mode = gc_mode_display OR gs_bug_detail-status = '7'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
```

---

## Bước C6: Screen 0400 — Project List (ALV Grid)

**Mục tiêu:** ALV Grid hiển thị danh sách Project + toolbar CRUD + Excel Upload.

Tạo Screen **0400**, Custom Container `CC_PROJECT_LIST`.

**Flow Logic:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0400.
  MODULE init_project_list.

PROCESS AFTER INPUT.
  MODULE user_command_0400.
```

**FORM `select_project_data` (trong `Z_BUG_WS_F01`):**

```abap
FORM select_project_data.
  DATA: lv_count TYPE i.

  IF gv_role = 'M'.
    " Manager thấy tất cả projects
    SELECT * FROM zbug_project INTO TABLE @gt_projects
      WHERE is_del <> 'X'.
  ELSE.
    " Tester/Dev chỉ thấy projects mình thuộc
    SELECT p.* FROM zbug_project AS p
      INNER JOIN zbug_user_project AS up
        ON p~project_id = up~project_id
      INTO TABLE @gt_projects
      WHERE up~user_id = @sy-uname
        AND p~is_del <> 'X'.
  ENDIF.

  " Map status code → text
  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
    CASE <prj>-project_status.
      WHEN '1'. <prj>-status_text = 'Opening'.
      WHEN '2'. <prj>-status_text = 'InProcess'.
      WHEN '3'. <prj>-status_text = 'Done'.
      WHEN '4'. <prj>-status_text = 'Cancel'.
    ENDCASE.
  ENDLOOP.
ENDFORM.
```

**GUI Status `STATUS_0400`:**

| Button | FCode | Icon | Role |
| :--- | :--- | :--- | :--- |
| Create | `CREATE_PRO` | `ICON_CREATE` | M |
| Change | `CHANGE_PRO` | `ICON_CHANGE` | M |
| Display | `DISPLAY_PRO` | `ICON_DISPLAY` | All |
| Delete | `DELETE_PRO` | `ICON_DELETE` | M |
| Upload | `UPLOAD` | `ICON_IMPORT` | M |
| Download Template | `DOWNLOAD_TMPL` | `ICON_EXPORT` | M |
| Refresh | `REFRESH` | `ICON_REFRESH` | All |
| Back | `BACK` | `ICON_BACK` | All |

---

## Bước C7: Screen 0500 — Project Detail

**Mục tiêu:** Form nhập/sửa thông tin Project + bảng user-project.

Tạo Screen **0500**, chứa các fields:

| Screen Element | Field | Type |
| :--- | :--- | :--- |
| Input Field | `GS_PROJECT-PROJECT_ID` | CHAR 20 |
| Input Field | `GS_PROJECT-PROJECT_NAME` | CHAR 100 |
| Input Field | `GS_PROJECT-DESCRIPTION` | CHAR 255 |
| Input Field | `GS_PROJECT-START_DATE` | DATS |
| Input Field | `GS_PROJECT-END_DATE` | DATS |
| Input Field | `GS_PROJECT-PROJECT_MANAGER` | CHAR 12 |
| Dropdown | `GS_PROJECT-PROJECT_STATUS` | CHAR 1 |
| Table Control | `TC_USERS` | User-Project list |

**FORM `save_project_detail` (trong `Z_BUG_WS_F01`):**

```abap
FORM save_project_detail.
  IF gv_mode = gc_mode_create.
    gs_project-ernam = sy-uname.
    gs_project-erdat = sy-datum.
    gs_project-erzet = sy-uzeit.
    gs_project-project_status = '1'. " Opening
    INSERT zbug_project FROM gs_project.
  ELSE.
    gs_project-aenam = sy-uname.
    gs_project-aedat = sy-datum.
    gs_project-aezet = sy-uzeit.
    UPDATE zbug_project FROM gs_project.
  ENDIF.

  IF sy-subrc = 0.
    MESSAGE s012(zbug_msg) WITH gs_project-project_id.
    COMMIT WORK.
  ELSE.
    MESSAGE s010(zbug_msg) DISPLAY LIKE 'E'.
    ROLLBACK WORK.
  ENDIF.
ENDFORM.
```

---

## Bước C8: GUI Status Creation (SE41)

**Mục tiêu:** Tạo 5 GUI Statuses cho 5 screens.

Vào **SE41** → nhập program `Z_BUG_WORKSPACE_MP` → **Create**.

| Status Name | Screen | Buttons |
| :--- | :--- | :--- |
| `STATUS_0100` | 0100 (Hub) | BUG_LIST, PROJECT_LIST, BACK/EXIT/CANC |
| `STATUS_0200` | 0200 (Bug List) | CREATE, CHANGE, DISPLAY, DELETE, REFRESH, PRINT, BACK |
| `STATUS_0300` | 0300 (Bug Detail) | SAVE, STATUS_CHG, UPLOAD_FILE, BACK |
| `STATUS_0400` | 0400 (Project List) | CREATE_PRO, CHANGE_PRO, DELETE_PRO, UPLOAD, DOWNLOAD_TMPL, REFRESH, BACK |
| `STATUS_0500` | 0500 (Project Detail) | SAVE, ADD_USER, REMOVE_USER, BACK |

**Role-based excluding (trong PBO):**

```abap
" Ẩn nút theo role
DATA: lt_excl TYPE TABLE OF sy-ucomm.
IF gv_role <> 'M'.
  APPEND 'DELETE' TO lt_excl.
  APPEND 'CREATE_PRO' TO lt_excl.
  APPEND 'DELETE_PRO' TO lt_excl.
  APPEND 'UPLOAD' TO lt_excl.
ENDIF.
IF gv_role = 'D'.
  APPEND 'CREATE' TO lt_excl.
ENDIF.
SET PF-STATUS 'STATUS_0200' EXCLUDING lt_excl.
```

---

## Bước C9: F4 Search Help + History Tab

### F4 Search Help

**FORM `f4_project_id` (trong `Z_BUG_WS_F02`):**

```abap
FORM f4_project_id USING pv_field TYPE dynfnam.
  DATA: lt_return TYPE TABLE OF ddshretval,
        lt_values TYPE TABLE OF zbug_project.

  SELECT project_id project_name project_status
    FROM zbug_project INTO CORRESPONDING FIELDS OF TABLE @lt_values
    WHERE is_del <> 'X'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield   = 'PROJECT_ID'
      dynpprog   = sy-repid
      dynpnr     = sy-dynnr
      dynprofield = pv_field
      value_org  = 'S'
    TABLES
      value_tab  = lt_values
      return_tab = lt_return
    EXCEPTIONS
      OTHERS     = 1.
ENDFORM.
```

### History Tab (SubScreen 0360)

**FORM `load_history_data` (trong `Z_BUG_WS_F01`):**

```abap
FORM load_history_data.
  SELECT * FROM zbug_history INTO TABLE @gt_history
    WHERE bug_id = @gv_current_bug_id
    ORDER BY changed_at DESCENDING, changed_time DESCENDING.

  " Map action_type → text
  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<h>).
    CASE <h>-action_type.
      WHEN 'CR'. <h>-action_text = 'Created'.
      WHEN 'AS'. <h>-action_text = 'Assigned'.
      WHEN 'RS'. <h>-action_text = 'Reassigned'.
      WHEN 'ST'. <h>-action_text = 'Status Change'.
      WHEN 'UP'. <h>-action_text = 'Updated'.
      WHEN 'DL'. <h>-action_text = 'Deleted'.
      WHEN 'AT'. <h>-action_text = 'Attachment'.
    ENDCASE.
  ENDLOOP.

  " Hiển thị bằng ALV readonly
  IF go_alv_history IS INITIAL.
    CREATE OBJECT go_cont_history EXPORTING container_name = 'CC_HISTORY'.
    CREATE OBJECT go_alv_history EXPORTING i_parent = go_cont_history.
    " Field catalog: CHANGED_AT, CHANGED_TIME, CHANGED_BY, ACTION_TEXT, OLD_VALUE, NEW_VALUE, REASON
    go_alv_history->set_table_for_first_display( ... ).
  ELSE.
    go_alv_history->refresh_table_display( ).
  ENDIF.
ENDFORM.
```

---

## Bước C10: POPUP_TO_CONFIRM + ALV Color-Coding

### POPUP_TO_CONFIRM

```abap
FORM confirm_action USING pv_text TYPE string
                    CHANGING pv_confirmed TYPE abap_bool.
  DATA: lv_answer TYPE char1.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirm'
      text_question         = pv_text
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.

  pv_confirmed = COND #( WHEN lv_answer = '1' THEN abap_true ELSE abap_false ).
ENDFORM.
```

### ALV Color-Coding (Status → Row Color)

```abap
FORM set_bug_colors.
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    DATA: ls_color TYPE lvc_s_scol.
    CLEAR <bug>-t_color.

    ls_color-fname = 'STATUS_TEXT'.
    CASE <bug>-status.
      WHEN '1'. ls_color-color-col = 1. ls_color-color-int = 0. " Blue — New
      WHEN 'W'. ls_color-color-col = 3. ls_color-color-int = 1. " Yellow — Waiting
      WHEN '2'. ls_color-color-col = 7. ls_color-color-int = 0. " Orange — Assigned
      WHEN '3'. ls_color-color-col = 6. ls_color-color-int = 0. " Purple — InProgress
      WHEN '4'. ls_color-color-col = 3. ls_color-color-int = 0. " Light Orange — Pending
      WHEN '5'. ls_color-color-col = 5. ls_color-color-int = 0. " Green — Fixed
      WHEN '6'. ls_color-color-col = 4. ls_color-color-int = 1. " Light Green — Resolved
      WHEN '7'. ls_color-color-col = 1. ls_color-color-int = 1. " Grey — Closed
      WHEN 'R'. ls_color-color-col = 6. ls_color-color-int = 1. " Red — Rejected
    ENDCASE.
    APPEND ls_color TO <bug>-t_color.
  ENDLOOP.
ENDFORM.
```

---

## TỔNG KẾT PHASE C

Sau khi hoàn thành Phase C, bạn phải có:

- [x] Module Pool `Z_BUG_WORKSPACE_MP` (Type M) + 6 includes
- [x] Screen `0100` → Router / Main Hub
- [x] Screen `0200` → Bug List ALV (role-based filter, color-coded status)
- [x] Screen `0300` → Bug Detail (Tab Strip 5 tabs: Notes ×3, Evidence, History)
- [x] Screen `0400` → Project List ALV (CRUD + Excel buttons)
- [x] Screen `0500` → Project Detail (form + user table control)
- [x] 5 GUI Statuses (SE41) với role-based excluding
- [x] F4 Search Help cho Project, Developer, Module
- [x] History Tab (ALV readonly + action text mapping)
- [x] `POPUP_TO_CONFIRM` cho delete/close/reject actions
- [x] ALV color-coding (9 status → 9 colors)
- [x] Event handler class `LCL_EVENT_HANDLER` (Hotspot/Double Click)
- [x] Dynamic screen control (`LOOP AT SCREEN` / `MODIFY SCREEN`)

👉 **Chuyển sang Phase D: Advanced Features (Excel Upload, Message Class Migration)**
