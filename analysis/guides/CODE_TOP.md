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

" === GLOBAL VARIABLES ===
DATA: gv_ok_code   TYPE sy-ucomm,
      gv_save_ok   TYPE sy-ucomm,
      gv_mode      TYPE char1,           " D/C/X (Display/Change/Create)
      gv_role      TYPE zbug_users-role, " T/D/M (Tester/Dev/Manager)
      gv_uname     TYPE sy-uname,        " Strict Mode helper
      gv_current_bug_id     TYPE zde_bug_id,
      gv_current_project_id TYPE zde_project_id.

" === TAB STRIP (Screen 0300) ===
DATA: gv_active_tab       TYPE char20 VALUE 'TAB_INFO',
      gv_active_subscreen TYPE sy-dynnr.

" === ALV OBJECTS (Containers & Grids) ===
DATA: go_cont_bug     TYPE REF TO cl_gui_custom_container,
      go_alv_bug      TYPE REF TO cl_gui_alv_grid,
      go_cont_project TYPE REF TO cl_gui_custom_container,
      go_alv_project  TYPE REF TO cl_gui_alv_grid,
      go_cont_history TYPE REF TO cl_gui_custom_container,
      go_alv_history  TYPE REF TO cl_gui_alv_grid.

" === TEXT EDIT OBJECTS ===
DATA: go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
      go_edit_dev_note  TYPE REF TO cl_gui_textedit,
      go_cont_func_note TYPE REF TO cl_gui_custom_container,
      go_edit_func_note TYPE REF TO cl_gui_textedit,
      go_cont_rootcause TYPE REF TO cl_gui_custom_container,
      go_edit_rootcause TYPE REF TO cl_gui_textedit.

" === FIELD CATALOGS (Column Definitions) ===
DATA: gt_fcat_bug     TYPE lvc_t_fcat,
      gt_fcat_project TYPE lvc_t_fcat,
      gt_fcat_history TYPE lvc_t_fcat.

" === INTERNAL TABLES & WORK AREAS ===
" ALV Bug Data
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
         t_color       TYPE lvc_t_scol,  " Row color
       END OF ty_bug_alv.

DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
      gs_bug_detail TYPE zbug_tracker.

" ALV Project Data
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

" ALV History Data
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

" === TABLE CONTROL SCREEN 0500 ===
DATA: gt_user_project TYPE TABLE OF zbug_user_projec,
      gs_user_project TYPE zbug_user_projec.

CONTROLS: tc_users  TYPE TABLEVIEW USING SCREEN 0500,
          ts_detail TYPE TABSTRIP.

" === EVENT HANDLER OBJECT ===
DATA: go_event_handler TYPE REF TO lcl_event_handler.
