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

" === BUG STATUS CONSTANTS (10-state lifecycle) ===
" BREAKING CHANGE: '6' WAS Resolved in v4.x → NOW Final Testing
"                  'V' is the NEW Resolved (terminal state)
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

" === GLOBAL VARIABLES ===
DATA: gv_ok_code   TYPE sy-ucomm,
      gv_save_ok   TYPE sy-ucomm,
      gv_mode      TYPE char1,           " D/C/X (Display/Change/Create)
      gv_role      TYPE zde_bug_role,    " T/D/M (Tester/Dev/Manager)
      gv_uname     TYPE sy-uname,
      gv_current_bug_id     TYPE zde_bug_id,
      gv_current_project_id TYPE zde_project_id.

" === PBO DATA-LOADING FLAGS (prevent reload on tab switch) ===
DATA: gv_detail_loaded     TYPE abap_bool,   " Bug Detail (Screen 0300)
      gv_prj_detail_loaded TYPE abap_bool.   " Project Detail (Screen 0500)

" === BUG LIST FILTER MODE ===
" 'P' = Project mode (all bugs of a project, no role filter)
" 'M' = My Bugs mode (cross-project, filtered by role)
DATA: gv_bug_filter_mode TYPE char1.

" === NAVIGATION FLAGS ===
" gv_from_search: tells PBO init_project_list to skip select_project_data
"   (data already loaded by search_projects). Cleared when BACK from 0400.
DATA: gv_from_search     TYPE abap_bool.
" gv_search_executed: set in user_command_0210 when EXECUTE pressed;
"   checked in user_command_0200 to navigate to 0220 after modal closes.
DATA: gv_search_executed TYPE abap_bool.

" === DISPLAY TEXT VARIABLES (mapped from raw codes for Screen fields) ===
DATA: gv_status_disp     TYPE char20,
      gv_priority_disp   TYPE char10,
      gv_severity_disp   TYPE char20,
      gv_bug_type_disp   TYPE char20,
      gv_prj_status_disp TYPE char20.

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

" === EVIDENCE ALV (Subscreen 0350, container CC_EVIDENCE) ===
DATA: go_cont_evidence TYPE REF TO cl_gui_custom_container,
      go_alv_evidence  TYPE REF TO cl_gui_alv_grid.

" === SEARCH RESULTS ALV (Screen 0220, container CC_SEARCH_RESULTS) ===
DATA: go_cont_search TYPE REF TO cl_gui_custom_container,
      go_search_alv  TYPE REF TO cl_gui_alv_grid.

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

" === TRANSITION NOTE EDITOR (Screen 0370 popup) ===
DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
      go_edit_trans_note TYPE REF TO cl_gui_textedit.

" === FIELD CATALOGS ===
DATA: gt_fcat_bug      TYPE lvc_t_fcat,
      gt_fcat_project  TYPE lvc_t_fcat,
      gt_fcat_history  TYPE lvc_t_fcat,
      gt_fcat_evidence TYPE lvc_t_fcat,
      gt_fcat_search   TYPE lvc_t_fcat.    " Bug Search Results

" === INTERNAL TABLES & WORK AREAS ===
" Bug ALV — matches ZBUG_TRACKER fields + display text columns
TYPES: BEGIN OF ty_bug_alv,
         bug_id           TYPE zde_bug_id,
         title            TYPE zde_bug_title,
         project_id       TYPE zde_project_id,
         status           TYPE zde_bug_status,     " CHAR 20
         status_text      TYPE char20,
         priority         TYPE zde_priority,
         priority_text    TYPE char10,
         severity         TYPE zde_severity,
         severity_text    TYPE char20,
         bug_type         TYPE zde_bug_type,
         bug_type_text    TYPE char20,
         tester_id        TYPE zde_username,
         verify_tester_id TYPE zde_username,
         dev_id           TYPE zde_username,
         sap_module       TYPE zde_sap_module,
         created_at       TYPE zde_bug_cr_date,
         t_color          TYPE lvc_t_scol,
       END OF ty_bug_alv.

DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
      gs_bug_detail TYPE zbug_tracker.

" Snapshot for unsaved changes detection
DATA: gs_bug_snapshot TYPE zbug_tracker.

" Search Results (reuses ty_bug_alv for consistent ALV columns)
DATA: gt_search_results TYPE TABLE OF ty_bug_alv.

" Project ALV — matches ZBUG_PROJECT fields
TYPES: BEGIN OF ty_project_alv,
         project_id      TYPE zde_project_id,
         project_name    TYPE zde_prj_name,
         description     TYPE zde_prj_desc,
         project_status  TYPE zde_prj_status,
         status_text     TYPE char20,
         start_date      TYPE sydatum,
         end_date        TYPE sydatum,
         project_manager TYPE zde_username,
         note            TYPE char255,
         t_color         TYPE lvc_t_scol,
       END OF ty_project_alv.

DATA: gt_projects TYPE TABLE OF ty_project_alv,
      gs_project  TYPE zbug_project.

" Snapshot for unsaved changes detection
DATA: gs_prj_snapshot TYPE zbug_project.

" History ALV — matches ZBUG_HISTORY fields
TYPES: BEGIN OF ty_history_alv,
         changed_at   TYPE zde_bug_cr_date,
         changed_time TYPE zde_bug_cr_time,
         changed_by   TYPE zde_username,
         action_type  TYPE zde_bug_act_type,
         action_text  TYPE char30,
         old_value    TYPE zde_bug_title,
         new_value    TYPE zde_bug_title,
         reason       TYPE string,
       END OF ty_history_alv.

DATA: gt_history TYPE TABLE OF ty_history_alv.

" Evidence ALV — metadata only (no CONTENT for performance)
TYPES: BEGIN OF ty_evidence_alv,
         evd_id    TYPE numc10,
         file_name TYPE sdok_filnm,
         mime_type TYPE w3conttype,
         file_size TYPE int4,
         ernam     TYPE ernam,
         erdat     TYPE erdat,
       END OF ty_evidence_alv.

DATA: gt_evidence TYPE TABLE OF ty_evidence_alv.

" === TABLE CONTROL SCREEN 0500 ===
DATA: gt_user_project TYPE TABLE OF zbug_user_projec,
      gs_user_project TYPE zbug_user_projec.

CONTROLS: tc_users  TYPE TABLEVIEW USING SCREEN 0500,
          ts_detail TYPE TABSTRIP.

" === EVENT HANDLER OBJECT ===
DATA: go_event_handler TYPE REF TO lcl_event_handler.

" === Screen 0410 — Project Search Fields ===
DATA: s_prj_id TYPE zde_project_id,
      s_prj_mn TYPE uname,
      s_prj_st TYPE char1.

" === Screen 0370 — Status Transition Popup Variables ===
DATA: gv_trans_bug_id      TYPE zde_bug_id,
      gv_trans_title       TYPE zde_bug_title,
      gv_trans_reporter    TYPE zde_username,
      gv_trans_cur_status  TYPE zde_bug_status,
      gv_trans_cur_st_text TYPE char20,
      gv_trans_new_status  TYPE zde_bug_status,
      gv_trans_dev_id      TYPE zde_username,
      gv_trans_ftester_id  TYPE zde_username,
      gv_trans_confirmed   TYPE abap_bool.

" === Screen 0210 — Bug Search Fields ===
DATA: s_bug_id   TYPE zde_bug_id,
      s_title    TYPE char40,          " Wildcard search
      s_status   TYPE zde_bug_status,
      s_prio     TYPE char10,
      s_mod      TYPE zde_sap_module,
      s_reporter TYPE char12,
      s_dev      TYPE char12.

" === Dashboard Metrics (Screen 0200) ===
DATA: gv_dash_total    TYPE i,
      " By Status
      gv_d_new         TYPE i,
      gv_d_assigned    TYPE i,
      gv_d_inprog      TYPE i,
      gv_d_pending     TYPE i,
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

" === Custom TYPE for save_long_text_direct table parameter ===
TYPES: gty_t_char255 TYPE TABLE OF char255.

" === TABLE CONTROL SELECTION FLAG (Screen 0500) ===
" tc_users-current_line defaults to 1 when table has data,
" even if user never clicked a row. This flag tracks actual clicks.
DATA: gv_tc_user_selected TYPE abap_bool.

" === MODULE-LEVEL WORK VARIABLES ===
DATA: gm_excl     TYPE TABLE OF sy-ucomm,  " Reused by all status_XXXX modules
      gm_layo_bug TYPE lvc_s_layo,
      gm_layo_prj TYPE lvc_s_layo,
      gm_title    TYPE string.