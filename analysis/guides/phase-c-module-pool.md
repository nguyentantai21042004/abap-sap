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
7. [Bước C7: Screen 0500 — Project Detail](#bước-c7-screen-0500--project-detail)
8. [Bước C8: GUI Status Creation (SE41)](#bước-c8-gui-status-creation)
9. [Bước C9: F4 Search Help + History Tab](#bước-c9-f4-search-help--history-tab)
10. [Bước C10: POPUP_TO_CONFIRM + ALV Color-Coding](#bước-c10-popup_to_confirm--alv-color-coding)
11. [Bước C11: Deprecate Old SE38 Programs](#bước-c11-deprecate-old-se38-programs)

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
INCLUDE z_bug_ws_f00.    " ALV setup + Event handler class (BEFORE PBO/PAI vì class cần define trước)
INCLUDE z_bug_ws_pbo.    " Process Before Output modules
INCLUDE z_bug_ws_pai.    " Process After Input modules
INCLUDE z_bug_ws_f01.    " Business logic FORM routines
INCLUDE z_bug_ws_f02.    " Helper: F4, Long Text, Popup, GOS
```

> ⚠️ **Lưu ý thứ tự include:** `Z_BUG_WS_F00` phải nằm TRƯỚC `PBO`/`PAI` vì class `LCL_EVENT_HANDLER` cần được define trước khi tham chiếu trong PBO modules.

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

" === TAB STRIP ===
DATA: gv_active_tab       TYPE char20 VALUE 'TAB_INFO',
      gv_active_subscreen TYPE sy-dynnr.

" === ALV OBJECTS — Bug List ===
DATA: go_cont_bug    TYPE REF TO cl_gui_custom_container,
      go_alv_bug     TYPE REF TO cl_gui_alv_grid.

" === ALV OBJECTS — Project List ===
DATA: go_cont_project TYPE REF TO cl_gui_custom_container,
      go_alv_project  TYPE REF TO cl_gui_alv_grid.

" === ALV OBJECTS — History ===
DATA: go_cont_history TYPE REF TO cl_gui_custom_container,
      go_alv_history  TYPE REF TO cl_gui_alv_grid.

" === TEXT EDIT OBJECTS ===
DATA: go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
      go_edit_dev_note  TYPE REF TO cl_gui_textedit,
      go_cont_func_note TYPE REF TO cl_gui_custom_container,
      go_edit_func_note TYPE REF TO cl_gui_textedit,
      go_cont_rootcause TYPE REF TO cl_gui_custom_container,
      go_edit_rootcause TYPE REF TO cl_gui_textedit.

" === FIELD CATALOGS ===
DATA: gt_fcat_bug     TYPE lvc_t_fcat,
      gt_fcat_project TYPE lvc_t_fcat,
      gt_fcat_history TYPE lvc_t_fcat.

" === ALV DATA TYPES — Bug ===
TYPES: BEGIN OF ty_bug_alv,
         bug_id        TYPE zde_bug_id,
         title         TYPE zde_bug_title,
         project_id    TYPE zde_project_id,
         status        TYPE char1,
         status_text   TYPE char20,
         priority      TYPE char1,
         priority_text TYPE char10,
         severity      TYPE char1,
         bug_type      TYPE char1,
         tester_id     TYPE zde_username,
         dev_id        TYPE zde_username,
         created_at    TYPE sydatum,
         sap_module    TYPE char10,
         t_color       TYPE lvc_t_scol,  " ALV row color
       END OF ty_bug_alv.

DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
      gs_bug_detail TYPE zbug_tracker.

" === ALV DATA TYPES — Project ===
TYPES: BEGIN OF ty_project_alv,
         project_id      TYPE zde_project_id,
         project_name    TYPE char100,
         description     TYPE char255,
         start_date      TYPE sydatum,
         end_date        TYPE sydatum,
         project_manager TYPE zde_username,
         project_status  TYPE char1,
         status_text     TYPE char20,
         t_color         TYPE lvc_t_scol,
       END OF ty_project_alv.

DATA: gt_projects TYPE TABLE OF ty_project_alv,
      gs_project  TYPE zbug_project.

" === ALV DATA TYPES — History ===
TYPES: BEGIN OF ty_history_alv,
         changed_at   TYPE sydatum,
         changed_time TYPE syuzeit,
         changed_by   TYPE char12,
         action_type  TYPE char2,
         action_text  TYPE char30,
         old_value    TYPE char50,
         new_value    TYPE char50,
         reason       TYPE char255,
       END OF ty_history_alv.

DATA: gt_history TYPE TABLE OF ty_history_alv.

" === EVENT HANDLER (forward declaration — class defined in F00) ===
DATA: go_event_handler TYPE REF TO lcl_event_handler.
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
    WHEN 'BUG_LIST'.     CALL SCREEN 0200.
    WHEN 'PROJECT_LIST'. CALL SCREEN 0400.
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
MODULE status_0200 OUTPUT.
  DATA: lt_excl TYPE TABLE OF sy-ucomm.
  IF gv_role <> 'M'.
    APPEND 'DELETE' TO lt_excl.
  ENDIF.
  IF gv_role = 'D'.
    APPEND 'CREATE' TO lt_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0200' EXCLUDING lt_excl.
  SET TITLEBAR 'TITLE_BUGLIST' WITH 'Bug List'.
ENDMODULE.

MODULE init_bug_list OUTPUT.
  PERFORM select_bug_data.
  IF go_alv_bug IS INITIAL.
    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
    CREATE OBJECT go_alv_bug EXPORTING i_parent = go_cont_bug.

    PERFORM build_bug_fieldcat.

    DATA: ls_layout TYPE lvc_s_layo.
    ls_layout-zebra      = 'X'.
    ls_layout-cwidth_opt = 'X'.
    ls_layout-ctab_fname = 'T_COLOR'.  " Color column

    go_alv_bug->set_table_for_first_display(
      EXPORTING is_layout       = ls_layout
      CHANGING  it_outtab       = gt_bugs
                it_fieldcatalog = gt_fcat_bug ).

    " Register event handler
    CREATE OBJECT go_event_handler.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_bug.
  ELSE.
    go_alv_bug->refresh_table_display( ).
  ENDIF.
ENDMODULE.
```

**FORM `select_bug_data` (trong `Z_BUG_WS_F01`):**

```abap
FORM select_bug_data.
  CLEAR gt_bugs.

  CASE gv_role.
    WHEN 'T'.  " Tester: own bugs only
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE tester_id = @sy-uname AND is_del <> 'X'.
    WHEN 'D'.  " Developer: assigned bugs
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE dev_id = @sy-uname AND is_del <> 'X'.
    WHEN 'M'.  " Manager: all bugs
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE is_del <> 'X'.
  ENDCASE.

  " Map status code → text + priority → text
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    <bug>-status_text = SWITCH #( <bug>-status
      WHEN '1' THEN 'New'        WHEN 'W' THEN 'Waiting'
      WHEN '2' THEN 'Assigned'   WHEN '3' THEN 'InProgress'
      WHEN '4' THEN 'Pending'    WHEN '5' THEN 'Fixed'
      WHEN '6' THEN 'Resolved'   WHEN '7' THEN 'Closed'
      WHEN 'R' THEN 'Rejected' ).

    <bug>-priority_text = SWITCH #( <bug>-priority
      WHEN 'H' THEN 'High' WHEN 'M' THEN 'Medium' WHEN 'L' THEN 'Low' ).
  ENDLOOP.

  " Apply color-coding
  PERFORM set_bug_colors.
ENDFORM.
```

**FORM `build_bug_fieldcat` (trong `Z_BUG_WS_F00`):**

```abap
FORM build_bug_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_bug.

  DEFINE add_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1. ls_fcat-coltext = &2. ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_bug.
  END-OF-DEFINITION.

  add_fcat 'BUG_ID'        'Bug ID'     12.
  add_fcat 'TITLE'         'Title'      40.
  add_fcat 'PROJECT_ID'    'Project'    15.
  add_fcat 'STATUS_TEXT'   'Status'     15.
  add_fcat 'PRIORITY_TEXT' 'Priority'   10.
  add_fcat 'SEVERITY'      'Severity'   10.
  add_fcat 'BUG_TYPE'      'Type'        8.
  add_fcat 'TESTER_ID'     'Tester'     12.
  add_fcat 'DEV_ID'        'Developer'  12.
  add_fcat 'CREATED_AT'    'Created'    10.

  " Set BUG_ID as hotspot (clickable → opens Bug Detail)
  READ TABLE gt_fcat_bug ASSIGNING FIELD-SYMBOL(<fc>)
    WITH KEY fieldname = 'BUG_ID'.
  IF sy-subrc = 0.
    <fc>-hotspot = 'X'.
  ENDIF.

  " Hide raw status code column (we show STATUS_TEXT instead)
  ls_fcat-fieldname = 'STATUS'. ls_fcat-no_out = 'X'.
  APPEND ls_fcat TO gt_fcat_bug.
  ls_fcat-fieldname = 'PRIORITY'. ls_fcat-no_out = 'X'.
  APPEND ls_fcat TO gt_fcat_bug.
ENDFORM.
```

---

## Bước C5: Screen 0300 — Bug Detail (Tab Strip)

**Mục tiêu:** Màn hình chi tiết bug với Tab Strip cho notes, evidence, history.

Tạo Screen **0300**.

**Phần dưới: Tab Strip control (`TS_DETAIL`) — 6 Tabs tương ứng 6 Subscreens:**

| Tab | Subscreen | Nội dung | Container |
| :--- | :--- | :--- | :--- |
| Bug Info | `0310` | Fields: Title, Status, Priority, Severity, etc. | (input fields) |
| Dev Note | `0320` | Long Text editor (Text ID Z001) | `CC_DEV_NOTE` |
| Func Note | `0330` | Long Text editor (Text ID Z002) | `CC_FUNC_NOTE` |
| Root Cause | `0340` | Long Text editor (Text ID Z003) | `CC_ROOTCAUSE` |
| Evidence | `0350` | GOS file list (BDS) | `CC_EVIDENCE` |
| History | `0360` | ALV readonly (ZBUG_HISTORY) | `CC_HISTORY` |

**Flow Logic 0300:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0300.
  MODULE load_bug_detail.
  MODULE modify_screen_0300.
  CALL SUBSCREEN ss_tab INCLUDING sy-repid gv_active_subscreen.

PROCESS AFTER INPUT.
  CALL SUBSCREEN ss_tab.
  MODULE user_command_0300.
```

**Trong `Z_BUG_WS_PBO`:**

```abap
MODULE status_0300 OUTPUT.
  DATA: lt_excl TYPE TABLE OF sy-ucomm.
  " Display mode → hide SAVE, STATUS_CHG
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE' TO lt_excl.
  ENDIF.
  " Tester: hide UPLOAD_FIX (trừ Config bug)
  IF gv_role = 'T' AND gs_bug_detail-bug_type <> 'F'.
    APPEND 'UPLOAD_FIX' TO lt_excl.
  ENDIF.
  " Developer: hide UPLOAD_REPORT
  IF gv_role = 'D'.
    APPEND 'UPLOAD_REPORT' TO lt_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0300' EXCLUDING lt_excl.
  SET TITLEBAR 'TITLE_BUGDETAIL' WITH gs_bug_detail-bug_id.
ENDMODULE.

MODULE load_bug_detail OUTPUT.
  CHECK gv_current_bug_id IS NOT INITIAL.
  SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
    WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.

  " Default active subscreen
  IF gv_active_subscreen IS INITIAL.
    gv_active_subscreen = '0310'.
  ENDIF.
ENDMODULE.

MODULE modify_screen_0300 OUTPUT.
  " Dynamic control: readonly khi Display mode hoặc Bug đã Closed
  LOOP AT SCREEN.
    IF gv_mode = gc_mode_display OR gs_bug_detail-status = '7'.
      IF screen-group1 = 'EDT'.  " Group EDT = editable fields
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.
```

**Trong `Z_BUG_WS_PAI`:**

```abap
MODULE user_command_0300 INPUT.
  gv_save_ok = gv_ok_code.
  CLEAR gv_ok_code.

  CASE gv_save_ok.
    WHEN 'BACK'.
      LEAVE TO SCREEN 0200.

    WHEN 'SAVE'.
      PERFORM save_bug_detail.

    WHEN 'STATUS_CHG'.
      PERFORM change_bug_status.

    WHEN 'UPLOAD_FILE'.
      PERFORM upload_evidence_file.

    " Tab switching
    WHEN 'TAB_INFO'.     gv_active_subscreen = '0310'.
    WHEN 'TAB_DEVNOTE'.  gv_active_subscreen = '0320'.
    WHEN 'TAB_FUNCNOTE'. gv_active_subscreen = '0330'.
    WHEN 'TAB_ROOTCAUSE'.gv_active_subscreen = '0340'.
    WHEN 'TAB_EVIDENCE'. gv_active_subscreen = '0350'.
    WHEN 'TAB_HISTORY'.  gv_active_subscreen = '0360'.
  ENDCASE.
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
  CLEAR gt_projects.

  IF gv_role = 'M'.
    " Manager thấy tất cả projects
    SELECT * FROM zbug_project
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE is_del <> 'X'.
  ELSE.
    " Tester/Dev chỉ thấy projects mình thuộc
    SELECT p~project_id p~project_name p~description
           p~start_date p~end_date p~project_manager p~project_status
      FROM zbug_project AS p
      INNER JOIN zbug_user_project AS up
        ON p~project_id = up~project_id
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE up~user_id = @sy-uname
        AND p~is_del <> 'X'.
  ENDIF.

  " Map status code → text
  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
    <prj>-status_text = SWITCH #( <prj>-project_status
      WHEN '1' THEN 'Opening'   WHEN '2' THEN 'InProcess'
      WHEN '3' THEN 'Done'      WHEN '4' THEN 'Cancel' ).
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
| `STATUS_0300` | 0300 (Bug Detail) | SAVE, STATUS_CHG, UPLOAD_FILE, UPLOAD_REPORT, UPLOAD_FIX, BACK |
| `STATUS_0400` | 0400 (Project List) | CREATE_PRO, CHANGE_PRO, DELETE_PRO, DISPLAY_PRO, UPLOAD, DOWNLOAD_TMPL, REFRESH, BACK |
| `STATUS_0500` | 0500 (Project Detail) | SAVE, ADD_USER, REMOVE_USER, BACK |

**Role-based excluding (trong PBO):**

```abap
" Ẩn nút theo role — ví dụ cho Screen 0200
DATA: lt_excl TYPE TABLE OF sy-ucomm.
IF gv_role <> 'M'.
  APPEND 'DELETE' TO lt_excl.
ENDIF.
IF gv_role = 'D'.
  APPEND 'CREATE' TO lt_excl.
ENDIF.
SET PF-STATUS 'STATUS_0200' EXCLUDING lt_excl.
```

> ✅ **Checkpoint:** Mỗi screen có GUI Status riêng, role-based buttons ẩn/hiện đúng.

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
      retfield    = 'PROJECT_ID'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = pv_field
      value_org   = 'S'
    TABLES
      value_tab   = lt_values
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.
ENDFORM.
```

### History Tab (SubScreen 0360)

**FORM `load_history_data` (trong `Z_BUG_WS_F01`):**

```abap
FORM load_history_data.
  CLEAR gt_history.

  SELECT * FROM zbug_history
    INTO CORRESPONDING FIELDS OF TABLE @gt_history
    WHERE bug_id = @gv_current_bug_id
    ORDER BY changed_at DESCENDING, changed_time DESCENDING.

  " Map action_type → text
  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<h>).
    <h>-action_text = SWITCH #( <h>-action_type
      WHEN 'CR' THEN 'Created'       WHEN 'AS' THEN 'Assigned'
      WHEN 'RS' THEN 'Reassigned'    WHEN 'ST' THEN 'Status Change'
      WHEN 'UP' THEN 'Updated'       WHEN 'DL' THEN 'Deleted'
      WHEN 'AT' THEN 'Attachment'    WHEN 'RJ' THEN 'Rejected' ).
  ENDLOOP.

  " Hiển thị bằng ALV readonly
  IF go_alv_history IS INITIAL.
    CREATE OBJECT go_cont_history EXPORTING container_name = 'CC_HISTORY'.
    CREATE OBJECT go_alv_history EXPORTING i_parent = go_cont_history.

    DATA: lt_fcat TYPE lvc_t_fcat, ls_fcat TYPE lvc_s_fcat.
    DEFINE add_hfcat.
      CLEAR ls_fcat.
      ls_fcat-fieldname = &1. ls_fcat-coltext = &2. ls_fcat-outputlen = &3.
      APPEND ls_fcat TO lt_fcat.
    END-OF-DEFINITION.

    add_hfcat 'CHANGED_AT'   'Date'      10.
    add_hfcat 'CHANGED_TIME' 'Time'       8.
    add_hfcat 'CHANGED_BY'   'Changed By' 12.
    add_hfcat 'ACTION_TEXT'  'Action'     15.
    add_hfcat 'OLD_VALUE'    'Old Value'  20.
    add_hfcat 'NEW_VALUE'    'New Value'  20.
    add_hfcat 'REASON'       'Reason'     40.

    DATA: ls_layout TYPE lvc_s_layo.
    ls_layout-zebra = 'X'.
    ls_layout-cwidth_opt = 'X'.

    go_alv_history->set_table_for_first_display(
      EXPORTING is_layout       = ls_layout
      CHANGING  it_outtab       = gt_history
                it_fieldcatalog = lt_fcat ).
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
      WHEN '4'. ls_color-color-col = 3. ls_color-color-int = 0. " Light Yellow — Pending
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

## Bước C11: Deprecate Old SE38 Programs

**Mục tiêu:** Sau khi Module Pool hoạt động, đánh dấu các SE38 programs cũ là deprecated.

> ⚠️ **KHÔNG XÓA** — chỉ deprecate. Xóa sau khi Phase E testing xác nhận Module Pool ổn định.

### Danh sách programs bị thay thế

| Old Program | Old T-Code | Thay thế bởi | Screen |
| :--- | :--- | :--- | :--- |
| `Z_BUG_CREATE_SCREEN` | `ZBUG_CREATE` | Screen 0200 → nút CREATE | 0300 (Create mode) |
| `Z_BUG_UPDATE_SCREEN` | `ZBUG_UPDATE` | Screen 0300 → nút STATUS_CHG | 0300 (Change mode) |
| `Z_BUG_REPORT_ALV` | `ZBUG_REPORT` | Screen 0200 (Bug List ALV) | 0200 |
| `Z_BUG_MANAGER_DASHBOARD` | `ZBUG_MANAGER` | Screen 0100 (Main Hub) | 0100 |
| `Z_BUG_PRINT` | `ZBUG_PRINT` | Screen 0200 → nút PRINT | 0200 |
| `Z_BUG_USER_MANAGEMENT` | `ZBUG_USERS` | Screen 0500 (Project Detail + TC_USERS) | 0500 |

### Cách deprecate

1. Mở từng program trong **SE38** → **Attributes** → sửa Title thêm `[DEPRECATED]`
2. Thêm comment ở đầu mỗi program:

```abap
* ============================================
* [DEPRECATED] — Replaced by Z_BUG_WORKSPACE_MP
* Use T-code ZBUG_HOME instead.
* This program will be deleted after go-live.
* ============================================
```

3. Cũng sửa cũ SE38 program `Z_BUG_WORKSPACE` (Phase 2 hub) → `[DEPRECATED]`

### Kế hoạch xóa

- **Phase E testing pass** → xóa T-codes cũ ở SE93 (xem Phase E, Bước E1.2)
- **Go-live ổn định 1 tuần** → xóa programs cũ và SE93 entries hoàn toàn

> ✅ **Checkpoint:** SE80 → mỗi program cũ có `[DEPRECATED]` trong title.

---

## Include F00: Event Handler Class

**Mục tiêu:** Define class xử lý ALV events.

**Trong `Z_BUG_WS_F00`:**

```abap
*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F00 — ALV Event Handler Class
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_hotspot_click
        FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id,

      handle_toolbar
        FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_user_command
        FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD handle_hotspot_click.
    " Bug List: click Bug ID → open Bug Detail
    IF e_column_id-fieldname = 'BUG_ID'.
      READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
      IF sy-subrc = 0.
        gv_current_bug_id = ls_bug-bug_id.
        gv_mode = gc_mode_display.
        gv_active_subscreen = '0310'.  " Reset to Info tab
        CALL SCREEN 0300.
      ENDIF.
    ENDIF.

    " Project List: click Project ID → open Project Detail
    IF e_column_id-fieldname = 'PROJECT_ID'.
      READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
      IF sy-subrc = 0.
        gv_current_project_id = ls_prj-project_id.
        gv_mode = gc_mode_display.
        CALL SCREEN 0500.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD handle_toolbar.
    " Custom toolbar buttons nếu cần thêm
  ENDMETHOD.

  METHOD handle_user_command.
    " Custom ALV toolbar command handling
  ENDMETHOD.

ENDCLASS.
```

---

## TỔNG KẾT PHASE C

Sau khi hoàn thành Phase C, bạn phải có:

- [x] Module Pool `Z_BUG_WORKSPACE_MP` (Type M) + 6 includes
- [x] Screen `0100` → Router / Main Hub
- [x] Screen `0200` → Bug List ALV (role-based filter, color-coded status)
- [x] Screen `0300` → Bug Detail (Tab Strip **6 tabs**: Info, Dev Note, Func Note, Root Cause, Evidence, History)
- [x] Screen `0400` → Project List ALV (CRUD + Excel buttons)
- [x] Screen `0500` → Project Detail (form + user table control)
- [x] 5 GUI Statuses (SE41) với role-based excluding
- [x] F4 Search Help cho Project, Developer, Module
- [x] History Tab subscreen `0360` (ALV readonly + action text mapping)
- [x] `POPUP_TO_CONFIRM` cho delete/close/reject actions
- [x] ALV color-coding (9 status → 9 colors)
- [x] Event handler class `LCL_EVENT_HANDLER` (Hotspot click → navigate)
- [x] Dynamic screen control (`LOOP AT SCREEN` / `MODIFY SCREEN`)
- [x] Complete `select_bug_data`, `build_bug_fieldcat` FORMs
- [x] Old SE38 programs deprecated (chưa xóa)

👉 **Chuyển sang Phase D: Advanced Features (Excel Upload, Message Class Migration)**
