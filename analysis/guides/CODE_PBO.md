*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PBO — Presentation Logic (v4.0)
*&---------------------------------------------------------------------*
*& v4.0 changes (over v3.0):
*&  - load_bug_detail: saves snapshot (gs_bug_snapshot) after first load
*&  - init_project_detail: saves snapshot (gs_prj_snapshot) after first load
*&  - status_0300: added SENDMAIL, DL_EVD exclusion logic
*&  - status_0200: added template download button exclusions (DN_TC/DN_CONF/DN_PROOF)
*&  - init_evidence_alv: NEW module for subscreen 0350
*&  - modify_screen_0300: added FNC screen group (Tester/Manager-only fields)
*&
*& v4.1 BUGFIX changes:
*&  - load_bug_detail: Create mode sets BUG_ID = '(Auto)' placeholder (Bug #5)
*&  - modify_screen_0300: BID group → ALWAYS display-only (Bug #5)
*&  - init_desc_mini: added EXCEPTIONS to set_text_as_r3table (Bug #6)
*&  - status_0500: exclude ADD_USER/REMO_USR in Create mode (Bug #1)
*&  - init_project_detail: Create mode sets PROJECT_ID = '(Auto)' (Bug #1)
*&  - modify_screen_0500: added PID group → always display-only (Bug #1/#3)
*&---------------------------------------------------------------------*

*&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Hub'.
ENDMODULE.

*&--- INIT USER ROLE (runs on initial screen 0400, loaded once) ---*
MODULE init_user_role OUTPUT.
  " Load role once at startup
  CHECK gv_role IS INITIAL.
  gv_uname = sy-uname.
  SELECT SINGLE role FROM zbug_users INTO @gv_role
    WHERE user_id = @gv_uname AND is_del <> 'X'.
  IF sy-subrc <> 0.
    MESSAGE 'User not registered in Bug Tracking system.' TYPE 'E' DISPLAY LIKE 'I'.
    LEAVE PROGRAM.
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0200: BUG LIST (dual mode: Project / My Bugs)
*&=====================================================================*
MODULE status_0200 OUTPUT.
  CLEAR gm_excl.

  " Developer cannot create/delete bugs
  IF gv_role = 'D'.
    APPEND 'CREATE' TO gm_excl.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.
  " Tester cannot delete
  IF gv_role = 'T'.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.

  " My Bugs mode: hide CREATE + DELETE (no project context)
  IF gv_bug_filter_mode = 'M'.
    APPEND 'CREATE' TO gm_excl.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.

  " v4.0: Template downloads only for Testers/Managers
  IF gv_role = 'D'.
    APPEND 'DN_TC'    TO gm_excl.    " Download Testcase template
    APPEND 'DN_CONF'  TO gm_excl.    " Download Confirm template
    APPEND 'DN_PROOF' TO gm_excl.    " Download BugProof template
  ENDIF.

  SET PF-STATUS 'STATUS_0200' EXCLUDING gm_excl.

  " Dynamic title based on filter mode
  DATA: lv_title TYPE string.
  IF gv_bug_filter_mode = 'P' AND gv_current_project_id IS NOT INITIAL.
    " Project mode: show project name in title
    DATA: lv_prj_name TYPE zde_prj_name.
    SELECT SINGLE project_name FROM zbug_project INTO @lv_prj_name
      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
    IF sy-subrc = 0.
      lv_title = |Bugs — { lv_prj_name }|.
    ELSE.
      lv_title = |Bugs — { gv_current_project_id }|.
    ENDIF.
  ELSE.
    " My Bugs mode
    lv_title = |My Bugs — { gv_uname }|.
  ENDIF.
  SET TITLEBAR 'TITLE_BUGLIST' WITH lv_title.
ENDMODULE.

MODULE init_bug_list OUTPUT.
  PERFORM select_bug_data.
  IF go_alv_bug IS INITIAL.
    " First-time ALV creation
    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
    CREATE OBJECT go_alv_bug  EXPORTING i_parent = go_cont_bug.
    PERFORM build_bug_fieldcat.
    CLEAR gm_layo_bug.
    gm_layo_bug-zebra      = 'X'.
    gm_layo_bug-cwidth_opt = 'X'.
    gm_layo_bug-sel_mode   = 'D'.  " Single-row selection
    gm_layo_bug-ctab_fname = 'T_COLOR'.
    go_alv_bug->set_table_for_first_display(
      EXPORTING is_layout      = gm_layo_bug
      CHANGING  it_outtab      = gt_bugs
                it_fieldcatalog = gt_fcat_bug ).
    " Register event handler
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_bug.
  ELSE.
    go_alv_bug->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0300: BUG DETAIL (Tab Strip)
*&=====================================================================*
MODULE status_0300 OUTPUT.
  CLEAR gm_excl.
  " Display mode: hide SAVE + upload buttons + email + delete evidence
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE'     TO gm_excl.
    APPEND 'SENDMAIL' TO gm_excl.    " v4.0
  ENDIF.
  " Tester cannot upload fix
  IF gv_role = 'T'.
    APPEND 'UP_FIX' TO gm_excl.
  ENDIF.
  " Developer cannot upload report
  IF gv_role = 'D'.
    APPEND 'UP_REP' TO gm_excl.
  ENDIF.
  " Create mode: hide status change + file uploads + email + delete evidence
  IF gv_mode = gc_mode_create.
    APPEND 'STATUS_CHG' TO gm_excl.
    APPEND 'UP_FILE'    TO gm_excl.
    APPEND 'UP_REP'     TO gm_excl.
    APPEND 'UP_FIX'     TO gm_excl.
    APPEND 'SENDMAIL'   TO gm_excl.    " v4.0: no email for unsaved bug
    APPEND 'DL_EVD'     TO gm_excl.    " v4.0: no delete evidence before save
  ENDIF.
  " Display mode: hide upload + delete evidence
  IF gv_mode = gc_mode_display.
    APPEND 'UP_FILE' TO gm_excl.
    APPEND 'UP_REP'  TO gm_excl.
    APPEND 'UP_FIX'  TO gm_excl.
    APPEND 'DL_EVD'  TO gm_excl.       " v4.0
  ENDIF.
  SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.

  " Title shows mode (Create/Change/Display)
  DATA(lv_mode_text) = SWITCH string( gv_mode
    WHEN gc_mode_create  THEN 'Create Bug'
    WHEN gc_mode_change  THEN |Change Bug: { gs_bug_detail-bug_id }|
    WHEN gc_mode_display THEN |Display Bug: { gs_bug_detail-bug_id }| ).
  SET TITLEBAR 'TITLE_BUGDETAIL' WITH lv_mode_text.
ENDMODULE.

*&--- LOAD BUG DETAIL (with flag — prevents DB overwrite on tab switch) ---*
MODULE load_bug_detail OUTPUT.
  " 1. Ensure subscreen + tab have valid defaults
  IF gv_active_subscreen IS INITIAL OR gv_active_subscreen = '0000'.
    gv_active_subscreen = '0310'.
    gv_active_tab       = 'TAB_INFO'.
  ENDIF.

  " 2. Sync tab strip highlight with active tab (every PBO)
  ts_detail-activetab = gv_active_tab.

  " 3. Skip DB reload if already loaded (preserves user edits during tab switch)
  IF gv_detail_loaded = abap_true.
    RETURN.
  ENDIF.

  " 4. Change/Display: load data from DB (first time only)
  IF gv_mode <> gc_mode_create AND gv_current_bug_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
      WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
    IF sy-subrc <> 0.
      MESSAGE |Bug { gv_current_bug_id } not found| TYPE 'W'.
    ENDIF.
  ENDIF.

  " 5. Create mode: reset work area with defaults
  IF gv_mode = gc_mode_create.
    CLEAR gs_bug_detail.
    " v4.1 BUGFIX #5: Show placeholder — BUG_ID will be auto-generated on save
    gs_bug_detail-bug_id = '(Auto)'.
    " Pre-fill PROJECT_ID from project context (locked on screen)
    IF gv_current_project_id IS NOT INITIAL.
      gs_bug_detail-project_id = gv_current_project_id.
    ENDIF.
    gs_bug_detail-tester_id = gv_uname.  " Default tester = current user
    gs_bug_detail-priority  = 'M'.       " Default priority = Medium
  ENDIF.

  " 6. v4.0: Save snapshot for unsaved changes detection
  gs_bug_snapshot = gs_bug_detail.

  " 7. Mark as loaded — subsequent PBO calls skip DB read
  gv_detail_loaded = abap_true.
ENDMODULE.

*&--- COMPUTE BUG DISPLAY TEXTS (always runs — no DB, in-memory only) ---*
*& Separated from load_bug_detail so display texts update after
*& status change without requiring a DB reload.
MODULE compute_bug_display_texts OUTPUT.
  gv_status_disp = SWITCH #( gs_bug_detail-status
    WHEN gc_st_new        THEN 'New'
    WHEN gc_st_assigned   THEN 'Assigned'
    WHEN gc_st_inprogress THEN 'In Progress'
    WHEN gc_st_pending    THEN 'Pending'
    WHEN gc_st_fixed      THEN 'Fixed'
    WHEN gc_st_resolved   THEN 'Resolved'
    WHEN gc_st_closed     THEN 'Closed'
    WHEN gc_st_waiting    THEN 'Waiting'
    WHEN gc_st_rejected   THEN 'Rejected'
    ELSE gs_bug_detail-status ).

  gv_priority_disp = SWITCH #( gs_bug_detail-priority
    WHEN 'H' THEN 'High'
    WHEN 'M' THEN 'Medium'
    WHEN 'L' THEN 'Low'
    ELSE gs_bug_detail-priority ).

  gv_severity_disp = SWITCH #( gs_bug_detail-severity
    WHEN '1' THEN 'Dump/Critical'
    WHEN '2' THEN 'Very High'
    WHEN '3' THEN 'High'
    WHEN '4' THEN 'Normal'
    WHEN '5' THEN 'Minor'
    ELSE gs_bug_detail-severity ).

  gv_bug_type_disp = SWITCH #( gs_bug_detail-bug_type
    WHEN '1' THEN 'Functional'
    WHEN '2' THEN 'Performance'
    WHEN '3' THEN 'UI/UX'
    WHEN '4' THEN 'Integration'
    WHEN '5' THEN 'Security'
    ELSE gs_bug_detail-bug_type ).
ENDMODULE.

*&--- MODIFY SCREEN 0300 (field enable/disable by mode + role) ---*
MODULE modify_screen_0300 OUTPUT.
  LOOP AT SCREEN.
    " Readonly mode: disable all fields with group EDT
    IF screen-group1 = 'EDT'.
      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " BUG_ID: ALWAYS display-only (auto-generated on save) — v4.1 BUGFIX #5
    " Previously was editable in Create mode which confused users
    IF screen-group1 = 'BID'.
      screen-input = 0.  " Always locked — shows "(Auto)" in Create, real ID after save
      MODIFY SCREEN.
    ENDIF.

    " PROJECT_ID: locked when creating from project context (group PRJ)
    IF screen-group1 = 'PRJ'.
      IF gv_mode = gc_mode_create AND gv_current_project_id IS NOT INITIAL.
        screen-input = 0.  " Pre-filled + locked
      ENDIF.
      IF gv_mode = gc_mode_display.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " Role-based field restrictions (group TST / DEV)
    IF screen-group1 = 'TST' AND gv_role = 'D'.
      " Dev cannot edit Tester fields
      screen-input = 0. MODIFY SCREEN.
    ENDIF.
    IF screen-group1 = 'DEV' AND gv_role = 'T'.
      " Tester cannot edit Dev fields
      screen-input = 0. MODIFY SCREEN.
    ENDIF.

    " v4.0: FNC group — fields only Tester/Manager can edit
    " (BUG_TYPE, PRIORITY, SEVERITY, DEADLINE)
    " Developer cannot edit these fields even in Change mode
    IF screen-group1 = 'FNC'.
      IF gv_role = 'D'.
        screen-input = 0. MODIFY SCREEN.
      ENDIF.
      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
        screen-input = 0. MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.

*&=====================================================================*
*& SUBSCREEN 0310: Bug Info — Description Mini Editor
*&=====================================================================*
MODULE init_desc_mini OUTPUT.
  " Create mini text editor (3-4 lines) for quick description on Bug Info tab
  IF go_desc_mini_cont IS INITIAL.
    CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
    CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
    go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
    go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).

    " Load DESC_TEXT into mini editor — ONLY on first creation
    " (subsequent PBO calls skip this, preserving user edits during tab switch)
    DATA: lt_mini_text TYPE TABLE OF char255.
    IF gs_bug_detail-desc_text IS NOT INITIAL.
      SPLIT gs_bug_detail-desc_text AT cl_abap_char_utilities=>cr_lf
        INTO TABLE lt_mini_text.
    ENDIF.
    go_desc_mini_edit->set_text_as_r3table(
      EXPORTING table = lt_mini_text
      EXCEPTIONS error_dp        = 1
                 error_dp_create = 2
                 OTHERS          = 3 ).
  ENDIF.

  " Readonly mode: set every PBO (may differ between bugs)
  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
  ELSE.
    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SUBSCREEN 0320: Description Long Text (Text ID Z001)
*&=====================================================================*
MODULE init_long_text_desc OUTPUT.
  IF go_cont_desc IS INITIAL.
    CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
    CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
    go_edit_desc->set_toolbar_mode( cl_gui_textedit=>false ).
    go_edit_desc->set_statusbar_mode( cl_gui_textedit=>false ).
    " Load text from DB on first creation only
    PERFORM load_long_text USING 'Z001'.
  ENDIF.
  " Readonly: set every PBO
  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
    go_edit_desc->set_readonly_mode( cl_gui_textedit=>true ).
  ELSE.
    go_edit_desc->set_readonly_mode( cl_gui_textedit=>false ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SUBSCREEN 0330: Dev Note Long Text (Text ID Z002)
*&=====================================================================*
MODULE init_long_text_devnote OUTPUT.
  IF go_cont_dev_note IS INITIAL.
    CREATE OBJECT go_cont_dev_note EXPORTING container_name = 'CC_DEVNOTE'.
    CREATE OBJECT go_edit_dev_note EXPORTING parent = go_cont_dev_note.
    go_edit_dev_note->set_toolbar_mode( cl_gui_textedit=>false ).
    go_edit_dev_note->set_statusbar_mode( cl_gui_textedit=>false ).
    " Load text from DB on first creation only
    PERFORM load_long_text USING 'Z002'.
  ENDIF.
  " Readonly: Testers cannot edit Dev Notes; also readonly in display/closed
  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
     OR gv_role = 'T'.
    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>true ).
  ELSE.
    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>false ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SUBSCREEN 0340: Tester Note Long Text (Text ID Z003)
*&=====================================================================*
MODULE init_long_text_tstrnote OUTPUT.
  IF go_cont_tstr_note IS INITIAL.
    CREATE OBJECT go_cont_tstr_note EXPORTING container_name = 'CC_TSTRNOTE'.
    CREATE OBJECT go_edit_tstr_note EXPORTING parent = go_cont_tstr_note.
    go_edit_tstr_note->set_toolbar_mode( cl_gui_textedit=>false ).
    go_edit_tstr_note->set_statusbar_mode( cl_gui_textedit=>false ).
    " Load text from DB on first creation only
    PERFORM load_long_text USING 'Z003'.
  ENDIF.
  " Readonly: Devs cannot edit Tester Notes; also readonly in display/closed
  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
     OR gv_role = 'D'.
    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>true ).
  ELSE.
    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>false ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& v4.0: SUBSCREEN 0350: Evidence ALV (attachment list)
*&=====================================================================*
MODULE init_evidence_alv OUTPUT.
  " Always reload evidence data (files may have been added/deleted)
  PERFORM load_evidence_data.

  IF go_alv_evidence IS INITIAL.
    CREATE OBJECT go_cont_evidence EXPORTING container_name = 'CC_EVIDENCE'.
    CREATE OBJECT go_alv_evidence  EXPORTING i_parent = go_cont_evidence.
    PERFORM build_evidence_fieldcat.
    DATA: ls_elayo TYPE lvc_s_layo.
    ls_elayo-zebra      = 'X'.
    ls_elayo-cwidth_opt = 'X'.
    ls_elayo-sel_mode   = 'D'.   " Single-row selection
    ls_elayo-no_toolbar = ' '.   " Keep toolbar for selection
    go_alv_evidence->set_table_for_first_display(
      EXPORTING is_layout      = ls_elayo
      CHANGING  it_outtab      = gt_evidence
                it_fieldcatalog = gt_fcat_evidence ).
    " Register double-click for download
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_double_click FOR go_alv_evidence.
  ELSE.
    go_alv_evidence->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SUBSCREEN 0360: History ALV (readonly)
*&=====================================================================*
MODULE init_history_alv OUTPUT.
  " Delegates to load_history_data which handles both creation and refresh
  PERFORM load_history_data.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0400: PROJECT LIST (INITIAL SCREEN)
*&=====================================================================*
MODULE status_0400 OUTPUT.
  CLEAR gm_excl.
  " Only Manager can create/change/delete projects + upload/download
  IF gv_role <> 'M'.
    APPEND 'CREA_PRJ' TO gm_excl.
    APPEND 'CHNG_PRJ' TO gm_excl.
    APPEND 'DEL_PRJ'  TO gm_excl.
    APPEND 'UPLOAD'   TO gm_excl.
    APPEND 'DN_TMPL'  TO gm_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0400' EXCLUDING gm_excl.
  SET TITLEBAR 'TITLE_PROJLIST' WITH 'Project List'.
ENDMODULE.

MODULE init_project_list OUTPUT.
  PERFORM select_project_data.
  IF go_alv_project IS INITIAL.
    CREATE OBJECT go_cont_project EXPORTING container_name = 'CC_PROJECT_LIST'.
    CREATE OBJECT go_alv_project  EXPORTING i_parent = go_cont_project.
    PERFORM build_pro_fieldcat.
    CLEAR gm_layo_prj.
    gm_layo_prj-zebra      = 'X'.
    gm_layo_prj-cwidth_opt = 'X'.
    gm_layo_prj-sel_mode   = 'D'.
    go_alv_project->set_table_for_first_display(
      EXPORTING is_layout      = gm_layo_prj
      CHANGING  it_outtab      = gt_projects
                it_fieldcatalog = gt_fcat_project ).
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_project.
  ELSE.
    go_alv_project->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0500: PROJECT DETAIL + TABLE CONTROL
*&=====================================================================*
MODULE status_0500 OUTPUT.
  CLEAR gm_excl.
  IF gv_role <> 'M'.
    APPEND 'SAVE'     TO gm_excl.
    APPEND 'ADD_USER' TO gm_excl.
    APPEND 'REMO_USR' TO gm_excl.
  ENDIF.
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE'     TO gm_excl.
    APPEND 'ADD_USER' TO gm_excl.
    APPEND 'REMO_USR' TO gm_excl.
  ENDIF.
  " v4.1 BUGFIX #1: Create mode → hide ADD_USER/REMO_USR
  " Project not yet saved → gv_current_project_id is empty → add user would fail
  IF gv_mode = gc_mode_create.
    APPEND 'ADD_USER' TO gm_excl.
    APPEND 'REMO_USR' TO gm_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0500' EXCLUDING gm_excl.

  " Title shows mode
  DATA(lv_prj_title) = SWITCH string( gv_mode
    WHEN gc_mode_create  THEN 'Create Project'
    WHEN gc_mode_change  THEN |Change Project: { gs_project-project_name }|
    WHEN gc_mode_display THEN |Display Project: { gs_project-project_name }| ).
  IF lv_prj_title IS INITIAL.
    lv_prj_title = 'Project Detail'.
  ENDIF.
  SET TITLEBAR 'TITLE_PRJDET' WITH lv_prj_title.
ENDMODULE.

*&--- LOAD PROJECT DETAIL (with flag — prevents DB reload) ---*
MODULE init_project_detail OUTPUT.
  " Skip DB reload if already loaded
  IF gv_prj_detail_loaded = abap_true.
    RETURN.
  ENDIF.

  IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_project INTO @gs_project
      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
      WHERE project_id = @gv_current_project_id.
  ENDIF.

  IF gv_mode = gc_mode_create.
    CLEAR: gs_project, gt_user_project.
    " v4.1 BUGFIX #1: Show placeholder — PROJECT_ID will be auto-generated on save
    gs_project-project_id      = '(Auto)'.
    gs_project-project_manager = gv_uname.  " Default manager = current user
    gs_project-project_status  = '1'.       " Opening
  ENDIF.

  " v4.0: Save snapshot for unsaved changes detection
  gs_prj_snapshot = gs_project.

  gv_prj_detail_loaded = abap_true.
ENDMODULE.

*&--- COMPUTE PROJECT DISPLAY TEXTS (always runs — no DB) ---*
MODULE compute_prj_display_texts OUTPUT.
  gv_prj_status_disp = SWITCH #( gs_project-project_status
    WHEN '1' THEN 'Opening'
    WHEN '2' THEN 'In Process'
    WHEN '3' THEN 'Done'
    WHEN '4' THEN 'Cancelled'
    ELSE gs_project-project_status ).
ENDMODULE.

*&--- MODIFY SCREEN 0500 (field enable/disable) ---*
MODULE modify_screen_0500 OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'EDT'.
      IF gv_mode = gc_mode_display OR gv_role <> 'M'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " v4.1 BUGFIX #1/#3: PROJECT_ID ALWAYS display-only (primary key, auto-generated)
    IF screen-group1 = 'PID'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
