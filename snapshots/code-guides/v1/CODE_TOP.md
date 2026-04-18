*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_TOP — Global Declarations
*&---------------------------------------------------------------------*
" === FORWARD DECLARATION ===
CLASS lcl_event_handler DEFINITION DEFERRED.

" === CONSTANTS ===
CONSTANTS:
  gc_mode_display TYPE char1 VALUE 'D',
  gc_mode_change  TYPE char1 VALUE 'C',
  gc_mode_create  TYPE char1 VALUE 'X'.

" === BUG STATUS CONSTANTS (9-state lifecycle) ===
CONSTANTS:
  gc_st_new        TYPE zde_bug_status VALUE '1',
  gc_st_assigned   TYPE zde_bug_status VALUE '2',
  gc_st_inprogress TYPE zde_bug_status VALUE '3',
  gc_st_pending    TYPE zde_bug_status VALUE '4',
  gc_st_fixed      TYPE zde_bug_status VALUE '5',
  gc_st_resolved   TYPE zde_bug_status VALUE '6',
  gc_st_closed     TYPE zde_bug_status VALUE '7',
  gc_st_waiting    TYPE zde_bug_status VALUE 'W',
  gc_st_rejected   TYPE zde_bug_status VALUE 'R'.

" === GLOBAL VARIABLES ===
DATA: gv_ok_code   TYPE sy-ucomm,
      gv_save_ok   TYPE sy-ucomm,
      gv_mode      TYPE char1,           " D/C/X (Display/Change/Create)
      gv_role      TYPE zde_bug_role,    " T/D/M (Tester/Dev/Manager)
      gv_uname     TYPE sy-uname,
      gv_current_bug_id     TYPE zde_bug_id,
      gv_current_project_id TYPE zde_project_id.

" === BUG LIST FILTER MODE (NEW — Project-first flow) ===
" 'P' = Project mode (all bugs of a project, no role filter)
" 'M' = My Bugs mode (cross-project, filtered by role)
DATA: gv_bug_filter_mode TYPE char1.

" === DISPLAY TEXT VARIABLES (for Screen fields — mapped from raw codes) ===
DATA: gv_status_disp     TYPE char20,    " Status text for Screen 0310
      gv_priority_disp   TYPE char10,    " Priority text for Screen 0310
      gv_severity_disp   TYPE char20,    " Severity text for Screen 0310
      gv_bug_type_disp   TYPE char20,    " Bug Type text for Screen 0310
      gv_prj_status_disp TYPE char20.    " Project Status text for Screen 0500

" === TAB STRIP (Screen 0300) ===
DATA: gv_active_tab       TYPE char20 VALUE 'TAB_INFO',
      gv_active_subscreen TYPE sy-dynnr VALUE '0310'.

" === ALV OBJECTS (Containers & Grids) ===
DATA: go_cont_bug     TYPE REF TO cl_gui_custom_container,
      go_alv_bug      TYPE REF TO cl_gui_alv_grid,
      go_cont_project TYPE REF TO cl_gui_custom_container,
      go_alv_project  TYPE REF TO cl_gui_alv_grid,
      go_cont_history TYPE REF TO cl_gui_custom_container,
      go_alv_history  TYPE REF TO cl_gui_alv_grid.

" === TEXT EDIT OBJECTS (subscreens 0320/0330/0340) ===
DATA: go_cont_desc      TYPE REF TO cl_gui_custom_container,
      go_edit_desc      TYPE REF TO cl_gui_textedit,
      go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
      go_edit_dev_note  TYPE REF TO cl_gui_textedit,
      go_cont_tstr_note TYPE REF TO cl_gui_custom_container,
      go_edit_tstr_note TYPE REF TO cl_gui_textedit.

" === DESCRIPTION MINI EDITOR (on Subscreen 0310 — Bug Info tab) ===
DATA: go_desc_mini_cont TYPE REF TO cl_gui_custom_container,
      go_desc_mini_edit TYPE REF TO cl_gui_textedit.

" === FIELD CATALOGS (Column Definitions) ===
DATA: gt_fcat_bug     TYPE lvc_t_fcat,
      gt_fcat_project TYPE lvc_t_fcat,
      gt_fcat_history TYPE lvc_t_fcat.

" === INTERNAL TABLES & WORK AREAS ===
" ALV Bug Data — khớp chính xác với ZBUG_TRACKER fields + display text columns
TYPES: BEGIN OF ty_bug_alv,
         bug_id           TYPE zde_bug_id,        " CHAR 10
         title            TYPE zde_bug_title,      " CHAR 100
         project_id       TYPE zde_project_id,     " CHAR 20
         status           TYPE zde_bug_status,     " CHAR 20 — đúng theo SE11
         status_text      TYPE char20,             " Display: New/Assigned/...
         priority         TYPE zde_priority,       " CHAR 1
         priority_text    TYPE char10,             " Display: High/Medium/Low
         severity         TYPE zde_severity,       " CHAR 1
         severity_text    TYPE char20,             " Display: Dump/VeryHigh/... (NEW)
         bug_type         TYPE zde_bug_type,       " CHAR 1
         bug_type_text    TYPE char20,             " Display: Functional/Performance/... (NEW)
         tester_id        TYPE zde_username,        " CHAR 12
         verify_tester_id TYPE zde_username,        " CHAR 12
         dev_id           TYPE zde_username,        " CHAR 12
         sap_module       TYPE zde_sap_module,      " CHAR 20 — đúng theo SE11
         created_at       TYPE zde_bug_cr_date,     " DATS 8
         t_color          TYPE lvc_t_scol,          " Row color
       END OF ty_bug_alv.

DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
      gs_bug_detail TYPE zbug_tracker.

" ALV Project Data — khớp với ZBUG_PROJECT fields
TYPES: BEGIN OF ty_project_alv,
         project_id      TYPE zde_project_id,      " CHAR 20
         project_name    TYPE zde_prj_name,         " CHAR 100
         description     TYPE zde_prj_desc,         " CHAR 255
         project_status  TYPE zde_prj_status,       " CHAR 1
         status_text     TYPE char20,               " Display: Opening/In Process/...
         start_date      TYPE sydatum,              " DATS 8
         end_date        TYPE sydatum,              " DATS 8
         project_manager TYPE zde_username,          " CHAR 12
         note            TYPE char255,              " CHAR 255
         t_color         TYPE lvc_t_scol,
       END OF ty_project_alv.

DATA: gt_projects TYPE TABLE OF ty_project_alv,
      gs_project  TYPE zbug_project.

" ALV History Data — khớp với ZBUG_HISTORY fields
TYPES: BEGIN OF ty_history_alv,
         changed_at   TYPE zde_bug_cr_date,    " DATS 8
         changed_time TYPE zde_bug_cr_time,    " TIMS 6
         changed_by   TYPE zde_username,       " CHAR 12
         action_type  TYPE zde_bug_act_type,   " CHAR 2
         action_text  TYPE char30,
         old_value    TYPE zde_bug_title,      " CHAR 100 — matches OLD_VALUE data element
         new_value    TYPE zde_bug_title,      " CHAR 100 — matches NEW_VALUE data element
         reason       TYPE string,             " STRING — matches ZBUG_HISTORY-REASON
       END OF ty_history_alv.

DATA: gt_history TYPE TABLE OF ty_history_alv.

" === TABLE CONTROL SCREEN 0500 ===
DATA: gt_user_project TYPE TABLE OF zbug_user_projec,
      gs_user_project TYPE zbug_user_projec.

CONTROLS: tc_users  TYPE TABLEVIEW USING SCREEN 0500,
          ts_detail TYPE TABSTRIP.

" === EVENT HANDLER OBJECT ===
DATA: go_event_handler TYPE REF TO lcl_event_handler.

" === MODULE-LEVEL WORK VARIABLES (global — Module Pool DATA in MODULE has no local scope) ===
DATA: gm_excl     TYPE TABLE OF sy-ucomm,  " Reused by all status_XXXX modules
      gm_layo_bug TYPE lvc_s_layo,          " Layout for Bug ALV
      gm_layo_prj TYPE lvc_s_layo,          " Layout for Project ALV
      gm_title    TYPE string.              " Title buffer for SET TITLEBAR
