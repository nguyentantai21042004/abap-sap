*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F01 — Main Business Logic (v4.0 → v4.1 BUGFIX)
*&---------------------------------------------------------------------*
*& v4.0 changes (over v3.0):
*&  - upload_evidence_file/report/fix: REAL implementation (binary → ZBUG_EVIDENCE)
*&  - load_evidence_data: NEW — SELECT without CONTENT for ALV
*&  - download_evidence_file: NEW — binary download from ZBUG_EVIDENCE
*&  - delete_evidence: NEW — popup confirm → DELETE
*&  - check_evidence_for_status: NEW — file prefix enforcement before transition
*&  - check_unsaved_bug / check_unsaved_prj: NEW — snapshot comparison
*&  - send_mail_notification: NEW — real BCS API email
*&  - save_bug_detail: ENHANCED — severity/priority cross-validation
*&  - save_project_detail: ENHANCED — completion validation
*&  - cleanup_detail_editors: ENHANCED — evidence ALV cleanup
*&
*& v4.1 BUGFIX changes:
*&  - save_project_detail: auto-generate PROJECT_ID (PRJ + 7 digits) (Bug #1)
*&  - add_user_to_project: fix ROLE field (no DDIC ref), validate M/D/T, check project saved (Bug #2)
*&  - upload_project_excel: move i_tab_raw_data to CHANGING block (Bug #4)
*&  - save_desc_mini_to_workarea: add cl_gui_cfw=>flush() + EXCEPTIONS (Bug #6)
*&---------------------------------------------------------------------*

*&=== SELECT BUG DATA (dual mode: Project / My Bugs) ===*
FORM select_bug_data.
  CLEAR gt_bugs.
  gv_uname = sy-uname.

  IF gv_bug_filter_mode = 'P' AND gv_current_project_id IS NOT INITIAL.
    " ---- PROJECT MODE: ALL bugs of project (no role filter) ----
    SELECT * FROM zbug_tracker
      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
      WHERE project_id = @gv_current_project_id
        AND is_del <> 'X'.
  ELSE.
    " ---- MY BUGS MODE: filter by role (cross-project) ----
    CASE gv_role.
      WHEN 'T'. " Tester: bugs mình tạo hoặc được assign verify
        SELECT * FROM zbug_tracker
          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
          WHERE ( tester_id = @gv_uname OR verify_tester_id = @gv_uname )
            AND is_del <> 'X'.
      WHEN 'D'. " Developer: bugs được assign cho mình
        SELECT * FROM zbug_tracker
          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
          WHERE dev_id = @gv_uname AND is_del <> 'X'.
      WHEN 'M'. " Manager: tất cả bugs
        SELECT * FROM zbug_tracker
          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
          WHERE is_del <> 'X'.
    ENDCASE.
  ENDIF.

  " Status text mapping (9 states)
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    <bug>-status_text = SWITCH #( <bug>-status
      WHEN gc_st_new        THEN 'New'
      WHEN gc_st_assigned   THEN 'Assigned'
      WHEN gc_st_inprogress THEN 'In Progress'
      WHEN gc_st_pending    THEN 'Pending'
      WHEN gc_st_fixed      THEN 'Fixed'
      WHEN gc_st_resolved   THEN 'Resolved'
      WHEN gc_st_closed     THEN 'Closed'
      WHEN gc_st_waiting    THEN 'Waiting'
      WHEN gc_st_rejected   THEN 'Rejected'
      ELSE <bug>-status ).

    <bug>-priority_text = SWITCH #( <bug>-priority
      WHEN 'H' THEN 'High'
      WHEN 'M' THEN 'Medium'
      WHEN 'L' THEN 'Low' ).

    <bug>-severity_text = SWITCH #( <bug>-severity
      WHEN '1' THEN 'Dump/Critical'
      WHEN '2' THEN 'Very High'
      WHEN '3' THEN 'High'
      WHEN '4' THEN 'Normal'
      WHEN '5' THEN 'Minor' ).

    <bug>-bug_type_text = SWITCH #( <bug>-bug_type
      WHEN '1' THEN 'Functional'
      WHEN '2' THEN 'Performance'
      WHEN '3' THEN 'UI/UX'
      WHEN '4' THEN 'Integration'
      WHEN '5' THEN 'Security' ).
  ENDLOOP.

  PERFORM set_bug_colors.
ENDFORM.

*&=== SELECT PROJECT DATA ===*
FORM select_project_data.
  CLEAR gt_projects.
  gv_uname = sy-uname.

  IF gv_role = 'M'.
    " Manager sees all projects
    SELECT * FROM zbug_project
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE is_del <> 'X'.
  ELSE.
    " Tester/Dev: only assigned projects
    SELECT p~project_id,
           p~project_name,
           p~project_status,
           p~start_date,
           p~end_date,
           p~project_manager,
           p~note
      FROM zbug_project AS p
      INNER JOIN zbug_user_projec AS up ON p~project_id = up~project_id
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'.
  ENDIF.

  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
    <prj>-status_text = SWITCH #( <prj>-project_status
      WHEN '1' THEN 'Opening'
      WHEN '2' THEN 'In Process'
      WHEN '3' THEN 'Done'
      WHEN '4' THEN 'Cancelled' ).
  ENDLOOP.
ENDFORM.

*&=== SAVE BUG DETAIL ===*
FORM save_bug_detail.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.

  " Validate PROJECT_ID is set
  IF gs_bug_detail-project_id IS INITIAL.
    MESSAGE 'Project ID is required. Bug must belong to a project.' TYPE 'E'.
    RETURN.
  ENDIF.

  " Validate TITLE is set
  IF gs_bug_detail-title IS INITIAL.
    MESSAGE 'Title is required.' TYPE 'E'.
    RETURN.
  ENDIF.

  " v4.0: Severity vs Priority cross-validation
  " Dump/Critical(1), VeryHigh(2), High(3) → must have Priority = High
  IF gs_bug_detail-severity IS NOT INITIAL
     AND ( gs_bug_detail-severity = '1' OR gs_bug_detail-severity = '2'
           OR gs_bug_detail-severity = '3' ).
    IF gs_bug_detail-priority <> 'H'.
      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

  IF gv_mode = gc_mode_create.
    " Auto-generate Bug ID: BUG + 7-digit number
    DATA: lv_max_id TYPE zde_bug_id,
          lv_num    TYPE i.
    SELECT MAX( bug_id ) FROM zbug_tracker INTO @lv_max_id.
    IF lv_max_id IS INITIAL.
      lv_num = 1.
    ELSE.
      " BUG_ID format: BUG0000001 (3 prefix + 7 digits)
      DATA: lv_num_str TYPE char7.
      lv_num_str = lv_max_id+3(7).
      lv_num = CONV i( lv_num_str ) + 1.
    ENDIF.
    gs_bug_detail-bug_id  = |BUG{ lv_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
    gs_bug_detail-ernam   = lv_un.
    gs_bug_detail-erdat   = sy-datum.
    gs_bug_detail-erzet   = sy-uzeit.
    IF gs_bug_detail-status IS INITIAL.
      gs_bug_detail-status = gc_st_new.
    ENDIF.
    IF gs_bug_detail-tester_id IS INITIAL.
      gs_bug_detail-tester_id = lv_un.
    ENDIF.
    INSERT zbug_tracker FROM @gs_bug_detail.
    IF sy-subrc = 0.
      PERFORM add_history_entry USING gs_bug_detail-bug_id 'CR' '' 'New' 'Bug created'.
    ENDIF.
  ELSE.
    " Update existing bug
    gs_bug_detail-aenam = lv_un.
    gs_bug_detail-aedat = sy-datum.
    gs_bug_detail-aezet = sy-uzeit.
    UPDATE zbug_tracker FROM @gs_bug_detail.
    IF sy-subrc = 0.
      PERFORM add_history_entry USING gs_bug_detail-bug_id 'UP' '' '' 'Bug updated'.
    ENDIF.
  ENDIF.

  IF sy-subrc = 0.
    COMMIT WORK.
    " Set current bug id BEFORE saving long texts
    gv_current_bug_id = gs_bug_detail-bug_id.
    " Save long text tabs (SAVE_TEXT performs its own COMMIT internally)
    PERFORM save_long_text USING 'Z001'.  " Description
    PERFORM save_long_text USING 'Z002'.  " Dev Note
    PERFORM save_long_text USING 'Z003'.  " Tester Note
    MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
    gv_mode = gc_mode_change.
    " v4.0: Update snapshot after successful save
    gs_bug_snapshot = gs_bug_detail.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Save failed. Please check required fields.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== SAVE DESCRIPTION MINI EDITOR → WORK AREA ===*
" Called before save_bug_detail — reads mini editor text into gs_bug_detail-desc_text
FORM save_desc_mini_to_workarea.
  CHECK go_desc_mini_edit IS NOT INITIAL.
  DATA: lt_mini TYPE TABLE OF char255,
        lv_text TYPE string.

  " v4.1 BUGFIX #6: Flush GUI control data before reading
  " Without flush, CL_GUI_TEXTEDIT raises POTENTIAL_DATA_LOSS
  cl_gui_cfw=>flush( ).

  go_desc_mini_edit->get_text_as_r3table(
    IMPORTING table = lt_mini
    EXCEPTIONS error_dp        = 1
               error_dp_create = 2
               OTHERS          = 3 ).
  IF sy-subrc <> 0.
    MESSAGE 'Warning: Could not read description text.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  CLEAR lv_text.
  LOOP AT lt_mini INTO DATA(lv_line).
    IF lv_text IS NOT INITIAL.
      lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line.
    ELSE.
      lv_text = lv_line.
    ENDIF.
  ENDLOOP.
  gs_bug_detail-desc_text = lv_text.
ENDFORM.

*&=== SAVE PROJECT DETAIL ===*
FORM save_project_detail.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.

  " v4.1 BUGFIX #1: Auto-generate PROJECT_ID in Create mode
  " (user sees "(Auto)" placeholder — real ID generated here before validation)
  IF gv_mode = gc_mode_create.
    DATA: lv_max_prj TYPE zde_project_id,
          lv_prj_num TYPE i.
    SELECT MAX( project_id ) FROM zbug_project INTO @lv_max_prj.
    IF lv_max_prj IS INITIAL OR lv_max_prj = '(Auto)'.
      lv_prj_num = 1.
    ELSE.
      " PROJECT_ID format: PRJ0000001 (3 prefix + 7 digits)
      DATA: lv_prj_num_str TYPE char7.
      lv_prj_num_str = lv_max_prj+3(7).
      lv_prj_num = CONV i( lv_prj_num_str ) + 1.
    ENDIF.
    gs_project-project_id = |PRJ{ lv_prj_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
  ENDIF.

  " Validate required fields
  IF gs_project-project_id IS INITIAL.
    MESSAGE 'Project ID is required.' TYPE 'E'. RETURN.
  ENDIF.
  IF gs_project-project_name IS INITIAL.
    MESSAGE 'Project Name is required.' TYPE 'E'. RETURN.
  ENDIF.

  " v4.0: Project completion validation — block Done if unresolved bugs
  IF gs_project-project_status = '3'. " Done
    DATA: lv_open_bugs TYPE i.
    SELECT COUNT(*) FROM zbug_tracker INTO @lv_open_bugs
      WHERE project_id = @gs_project-project_id
        AND is_del <> 'X'
        AND status <> @gc_st_resolved
        AND status <> @gc_st_closed.
    IF lv_open_bugs > 0.
      DATA: lv_block_msg TYPE string.
      lv_block_msg = |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed.|.
      MESSAGE lv_block_msg TYPE 'E'.
      RETURN.
    ENDIF.
  ENDIF.

  IF gv_mode = gc_mode_create.
    gs_project-ernam          = lv_un.
    gs_project-erdat          = sy-datum.
    gs_project-erzet          = sy-uzeit.
    IF gs_project-project_status IS INITIAL.
      gs_project-project_status = '1'.
    ENDIF.
    INSERT zbug_project FROM @gs_project.
  ELSE.
    gs_project-aenam = lv_un.
    gs_project-aedat = sy-datum.
    gs_project-aezet = sy-uzeit.
    UPDATE zbug_project FROM @gs_project.
  ENDIF.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Project { gs_project-project_id } saved successfully.| TYPE 'S'.
    gv_current_project_id = gs_project-project_id.
    gv_mode = gc_mode_change.
    " v4.0: Update snapshot after successful save
    gs_prj_snapshot = gs_project.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== ALV ROW COLORING ===*
FORM set_bug_colors.
  DATA: ls_color TYPE lvc_s_scol.
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    CLEAR <bug>-t_color.
    ls_color-fname = 'STATUS_TEXT'.
    CASE <bug>-status.
      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue
      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow
      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange
      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple
      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow
      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green
      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green
      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey
      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red
    ENDCASE.
    APPEND ls_color TO <bug>-t_color.
  ENDLOOP.
ENDFORM.

*&=== GET SELECTED BUG FROM ALV ===*
FORM get_selected_bug CHANGING pv_bug_id TYPE zde_bug_id.
  CLEAR pv_bug_id.
  CHECK go_alv_bug IS NOT INITIAL.
  DATA: lt_rows TYPE lvc_t_roid.
  go_alv_bug->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL. RETURN. ENDIF.
  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_bugs INTO DATA(ls_bug) INDEX ls_row-row_id.
  IF sy-subrc = 0. pv_bug_id = ls_bug-bug_id. ENDIF.
ENDFORM.

*&=== GET SELECTED PROJECT FROM ALV ===*
FORM get_selected_project CHANGING pv_proj_id TYPE zde_project_id.
  CLEAR pv_proj_id.
  CHECK go_alv_project IS NOT INITIAL.
  DATA: lt_rows TYPE lvc_t_roid.
  go_alv_project->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL. RETURN. ENDIF.
  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_projects INTO DATA(ls_prj) INDEX ls_row-row_id.
  IF sy-subrc = 0. pv_proj_id = ls_prj-project_id. ENDIF.
ENDFORM.

*&=== DELETE BUG (Soft Delete) ===*
FORM delete_bug.
  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = |Delete Bug { gv_current_bug_id }?|.
  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.

  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_tracker
    SET is_del = 'X',
        aenam  = @lv_un,
        aedat  = @sy-datum,
        aezet  = @sy-uzeit
    WHERE bug_id = @gv_current_bug_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM add_history_entry USING gv_current_bug_id 'DL' '' '' 'Bug soft-deleted'.
    MESSAGE |Bug { gv_current_bug_id } deleted.| TYPE 'S'.
    PERFORM select_bug_data.
    IF go_alv_bug IS NOT INITIAL.
      go_alv_bug->refresh_table_display( ).
    ENDIF.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Delete failed.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== DELETE PROJECT (Soft Delete) ===*
FORM delete_project.
  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = |Delete Project { gv_current_project_id }?|.
  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.

  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_project
    SET is_del = 'X',
        aenam  = @lv_un,
        aedat  = @sy-datum,
        aezet  = @sy-uzeit
    WHERE project_id = @gv_current_project_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Project { gv_current_project_id } deleted.| TYPE 'S'.
    PERFORM select_project_data.
    IF go_alv_project IS NOT INITIAL.
      go_alv_project->refresh_table_display( ).
    ENDIF.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Delete failed.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== POPUP CONFIRM ===*
FORM confirm_action USING    pv_text      TYPE string
                   CHANGING  pv_confirmed TYPE abap_bool.
  DATA: lv_answer TYPE char1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Confirm Action'
      text_question         = pv_text
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = ' '
    IMPORTING
      answer                = lv_answer.
  pv_confirmed = COND #( WHEN lv_answer = '1' THEN abap_true ELSE abap_false ).
ENDFORM.

*&=== CHANGE BUG STATUS (with 9-state transition validation) ===*
FORM change_bug_status.
  " Build allowed transitions based on current status and role
  DATA: lt_allowed TYPE TABLE OF zde_bug_status,
        lv_current TYPE zde_bug_status.
  lv_current = gs_bug_detail-status.

  CASE gv_role.
    WHEN 'T'. " Tester
      CASE lv_current.
        WHEN gc_st_new.      APPEND gc_st_assigned TO lt_allowed.
                             APPEND gc_st_waiting  TO lt_allowed.
        WHEN gc_st_fixed.    APPEND gc_st_resolved TO lt_allowed.
                             APPEND gc_st_rejected TO lt_allowed.
        WHEN gc_st_resolved. APPEND gc_st_closed   TO lt_allowed.
      ENDCASE.
    WHEN 'D'. " Developer
      CASE lv_current.
        WHEN gc_st_assigned.   APPEND gc_st_inprogress TO lt_allowed.
        WHEN gc_st_inprogress. APPEND gc_st_pending    TO lt_allowed.
                               APPEND gc_st_fixed      TO lt_allowed.
                               APPEND gc_st_rejected   TO lt_allowed.
        WHEN gc_st_pending.    APPEND gc_st_inprogress TO lt_allowed.
      ENDCASE.
    WHEN 'M'. " Manager: can set any status
      APPEND gc_st_new        TO lt_allowed.
      APPEND gc_st_assigned   TO lt_allowed.
      APPEND gc_st_inprogress TO lt_allowed.
      APPEND gc_st_pending    TO lt_allowed.
      APPEND gc_st_fixed      TO lt_allowed.
      APPEND gc_st_resolved   TO lt_allowed.
      APPEND gc_st_closed     TO lt_allowed.
      APPEND gc_st_waiting    TO lt_allowed.
      APPEND gc_st_rejected   TO lt_allowed.
  ENDCASE.

  IF lt_allowed IS INITIAL.
    MESSAGE |No valid transitions available from current status.| TYPE 'W'.
    RETURN.
  ENDIF.

  " Use POPUP_GET_VALUES to get new status
  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval.
  ls_field-tabname   = 'ZBUG_TRACKER'.
  ls_field-fieldname = 'STATUS'.
  DATA: lv_hint TYPE string.
  lv_hint = 'Allowed: '.
  LOOP AT lt_allowed INTO DATA(lv_al).
    lv_hint = lv_hint && lv_al && ' '.
  ENDLOOP.
  ls_field-fieldtext = lv_hint(40).
  APPEND ls_field TO lt_fields.

  DATA: lv_rc TYPE char1.
  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title  = 'Change Bug Status'
      start_column = 20
      start_row    = 5
    IMPORTING
      returncode   = lv_rc
    TABLES
      fields       = lt_fields.
  CHECK lv_rc <> 'A'.

  READ TABLE lt_fields INTO ls_field INDEX 1.
  CHECK ls_field-value IS NOT INITIAL.

  " Validate transition
  DATA: lv_new_status TYPE zde_bug_status.
  lv_new_status = ls_field-value.
  READ TABLE lt_allowed TRANSPORTING NO FIELDS WITH KEY table_line = lv_new_status.
  IF sy-subrc <> 0 AND gv_role <> 'M'.
    MESSAGE |Invalid transition: { lv_current } → { lv_new_status }| TYPE 'W'.
    RETURN.
  ENDIF.

  " v4.0: Evidence file prefix enforcement before status transition
  DATA: lv_evd_ok TYPE abap_bool.
  PERFORM check_evidence_for_status USING lv_new_status CHANGING lv_evd_ok.
  IF lv_evd_ok = abap_false.
    RETURN.  " Message already shown by check_evidence_for_status
  ENDIF.

  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_tracker
    SET status = @lv_new_status,
        aenam  = @lv_un,
        aedat  = @sy-datum,
        aezet  = @sy-uzeit
    WHERE bug_id = @gv_current_bug_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    DATA: lv_old_st TYPE string,
          lv_new_st TYPE string.
    lv_old_st = lv_current.
    lv_new_st = lv_new_status.
    PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
    gs_bug_detail-status = lv_new_status.
    " v4.0: Update snapshot to reflect new status
    gs_bug_snapshot-status = lv_new_status.
    MESSAGE |Status updated: { lv_current } → { lv_new_status }| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Status update failed.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== ADD HISTORY ENTRY (auto-generate LOG_ID) ===*
FORM add_history_entry USING pv_bug_id  TYPE zde_bug_id
                             pv_type    TYPE char2
                             pv_old
                             pv_new
                             pv_reason.
  DATA: ls_hist    TYPE zbug_history,
        lv_max_id  TYPE numc10,
        lv_new_id  TYPE numc10.

  " Auto-generate LOG_ID (MAX + 1)
  SELECT MAX( log_id ) FROM zbug_history INTO @lv_max_id.
  lv_new_id = lv_max_id + 1.

  ls_hist-log_id       = lv_new_id.
  ls_hist-bug_id       = pv_bug_id.
  ls_hist-changed_at   = sy-datum.
  ls_hist-changed_time = sy-uzeit.
  ls_hist-changed_by   = sy-uname.
  ls_hist-action_type  = pv_type.
  ls_hist-old_value    = pv_old.
  ls_hist-new_value    = pv_new.
  ls_hist-reason       = pv_reason.
  INSERT zbug_history FROM @ls_hist.
  " Note: no COMMIT here — caller handles commit
ENDFORM.

*&=== PROJECT USER MANAGEMENT: ADD ===*
FORM add_user_to_project.
  " v4.1 BUGFIX #1: Check project is saved before adding users
  IF gv_current_project_id IS INITIAL.
    MESSAGE 'Save the project first before adding users.' TYPE 'W'.
    RETURN.
  ENDIF.

  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval.

  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
  ls_field-fieldname = 'USER_ID'.
  ls_field-fieldtext = 'SAP Username (USER_ID)'.
  APPEND ls_field TO lt_fields.

  " v4.1 BUGFIX #2: Use empty tabname to avoid DDIC search help crash
  " (ZBUG_USER_PROJEC-ROLE triggers internal error on F4 → use plain field)
  CLEAR ls_field.
  ls_field-tabname   = space.
  ls_field-fieldname = 'P_ROLE'.
  ls_field-fieldtext = 'Role (M/D/T)'.
  ls_field-value     = 'D'.   " Default = Developer
  APPEND ls_field TO lt_fields.

  DATA: lv_rc TYPE char1.
  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING popup_title = 'Assign User to Project'
    IMPORTING returncode  = lv_rc
    TABLES    fields       = lt_fields.
  CHECK lv_rc <> 'A'.

  DATA: ls_up    TYPE zbug_user_projec,
        lv_uid   TYPE zde_username,
        lv_role  TYPE zde_bug_role.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'USER_ID'.
  lv_uid  = ls_field-value.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'P_ROLE'.
  lv_role = ls_field-value.

  IF lv_uid IS INITIAL.
    MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
  ENDIF.

  " v4.1 BUGFIX #2: Validate ROLE is M, D, or T
  TRANSLATE lv_role TO UPPER CASE.
  IF lv_role <> 'M' AND lv_role <> 'D' AND lv_role <> 'T'.
    MESSAGE 'Role must be M (Manager), D (Developer), or T (Tester).' TYPE 'W'.
    RETURN.
  ENDIF.

  " Validate user exists in ZBUG_USERS
  SELECT SINGLE user_id FROM zbug_users INTO @DATA(lv_check)
    WHERE user_id = @lv_uid AND is_del <> 'X'.
  IF sy-subrc <> 0.
    MESSAGE |User { lv_uid } not found in system.| TYPE 'W'. RETURN.
  ENDIF.

  ls_up-project_id = gv_current_project_id.
  ls_up-user_id    = lv_uid.
  ls_up-role       = lv_role.
  ls_up-ernam      = sy-uname.
  ls_up-erdat      = sy-datum.
  ls_up-erzet      = sy-uzeit.

  INSERT zbug_user_projec FROM @ls_up.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |User { lv_uid } added to project { gv_current_project_id }.| TYPE 'S'.
    " Reload user list
    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
      WHERE project_id = @gv_current_project_id.
  ELSE.
    ROLLBACK WORK.
    MESSAGE |User { lv_uid } is already assigned to this project.| TYPE 'W'.
  ENDIF.
ENDFORM.

*&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
FORM remove_user_from_project.
  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.
  IF lv_line = 0.
    MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
  ENDIF.

  READ TABLE gt_user_project INTO gs_user_project INDEX lv_line.
  IF sy-subrc <> 0. RETURN. ENDIF.

  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = |Remove user { gs_user_project-user_id } from project?|.
  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.

  DELETE FROM zbug_user_projec
    WHERE project_id = @gv_current_project_id
      AND user_id    = @gs_user_project-user_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    DELETE gt_user_project INDEX lv_line.
    MESSAGE |User { gs_user_project-user_id } removed.| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Remove failed.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== LOAD HISTORY TAB (creates ALV if needed, refreshes if exists) ===*
FORM load_history_data.
  CLEAR gt_history.
  CHECK gv_current_bug_id IS NOT INITIAL.

  SELECT * FROM zbug_history
    INTO CORRESPONDING FIELDS OF TABLE @gt_history
    WHERE bug_id = @gv_current_bug_id
    ORDER BY changed_at DESCENDING, changed_time DESCENDING.

  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<h>).
    <h>-action_text = SWITCH #( <h>-action_type
      WHEN 'CR' THEN 'Created'
      WHEN 'UP' THEN 'Updated'
      WHEN 'ST' THEN 'Status Change'
      WHEN 'AT' THEN 'Attachment'
      WHEN 'DL' THEN 'Deleted'
      WHEN 'RJ' THEN 'Rejected' ).
  ENDLOOP.

  IF go_alv_history IS INITIAL.
    CREATE OBJECT go_cont_history EXPORTING container_name = 'CC_HISTORY'.
    CREATE OBJECT go_alv_history  EXPORTING i_parent = go_cont_history.
    PERFORM build_history_fieldcat CHANGING gt_fcat_history.
    DATA: ls_layo TYPE lvc_s_layo.
    ls_layo-zebra      = 'X'.
    ls_layo-cwidth_opt = 'X'.
    ls_layo-no_toolbar = 'X'.  " History is readonly — no toolbar
    go_alv_history->set_table_for_first_display(
      EXPORTING is_layout      = ls_layo
      CHANGING  it_outtab      = gt_history
                it_fieldcatalog = gt_fcat_history ).
  ELSE.
    go_alv_history->refresh_table_display( ).
  ENDIF.
ENDFORM.

*&=====================================================================*
*& CLEANUP: Free all Screen 0300 GUI controls (v4.0)
*& Called on BACK/CANC/EXIT from Bug Detail — ensures clean state
*& for the next bug opened.
*&=====================================================================*
FORM cleanup_detail_editors.
  " --- Mini description editor (Subscreen 0310) ---
  IF go_desc_mini_edit IS NOT INITIAL.
    go_desc_mini_edit->free( ).
    FREE go_desc_mini_edit.
    CLEAR go_desc_mini_edit.
  ENDIF.
  IF go_desc_mini_cont IS NOT INITIAL.
    go_desc_mini_cont->free( ).
    FREE go_desc_mini_cont.
    CLEAR go_desc_mini_cont.
  ENDIF.

  " --- Long Text: Description (Subscreen 0320) ---
  IF go_edit_desc IS NOT INITIAL.
    go_edit_desc->free( ).
    FREE go_edit_desc.
    CLEAR go_edit_desc.
  ENDIF.
  IF go_cont_desc IS NOT INITIAL.
    go_cont_desc->free( ).
    FREE go_cont_desc.
    CLEAR go_cont_desc.
  ENDIF.

  " --- Long Text: Dev Note (Subscreen 0330) ---
  IF go_edit_dev_note IS NOT INITIAL.
    go_edit_dev_note->free( ).
    FREE go_edit_dev_note.
    CLEAR go_edit_dev_note.
  ENDIF.
  IF go_cont_dev_note IS NOT INITIAL.
    go_cont_dev_note->free( ).
    FREE go_cont_dev_note.
    CLEAR go_cont_dev_note.
  ENDIF.

  " --- Long Text: Tester Note (Subscreen 0340) ---
  IF go_edit_tstr_note IS NOT INITIAL.
    go_edit_tstr_note->free( ).
    FREE go_edit_tstr_note.
    CLEAR go_edit_tstr_note.
  ENDIF.
  IF go_cont_tstr_note IS NOT INITIAL.
    go_cont_tstr_note->free( ).
    FREE go_cont_tstr_note.
    CLEAR go_cont_tstr_note.
  ENDIF.

  " --- v4.0: Evidence ALV (Subscreen 0350) ---
  IF go_alv_evidence IS NOT INITIAL.
    go_alv_evidence->free( ).
    FREE go_alv_evidence.
    CLEAR go_alv_evidence.
  ENDIF.
  IF go_cont_evidence IS NOT INITIAL.
    go_cont_evidence->free( ).
    FREE go_cont_evidence.
    CLEAR go_cont_evidence.
  ENDIF.

  " --- History ALV (Subscreen 0360) ---
  IF go_alv_history IS NOT INITIAL.
    go_alv_history->free( ).
    FREE go_alv_history.
    CLEAR go_alv_history.
  ENDIF.
  IF go_cont_history IS NOT INITIAL.
    go_cont_history->free( ).
    FREE go_cont_history.
    CLEAR go_cont_history.
  ENDIF.

  " --- Clear data-loaded flag so next bug triggers fresh DB load ---
  CLEAR gv_detail_loaded.
ENDFORM.

*&=====================================================================*
*& v4.0: LOAD EVIDENCE DATA (metadata only — no CONTENT for performance)
*& Used by PBO init_evidence_alv module
*&=====================================================================*
FORM load_evidence_data.
  CLEAR gt_evidence.
  CHECK gv_current_bug_id IS NOT INITIAL.

  SELECT evd_id, file_name, mime_type, file_size, ernam, erdat
    FROM zbug_evidence
    INTO CORRESPONDING FIELDS OF TABLE @gt_evidence
    WHERE bug_id = @gv_current_bug_id
    ORDER BY evd_id DESCENDING.
ENDFORM.

*&=====================================================================*
*& v4.0: UPLOAD EVIDENCE — Common logic for UP_FILE / UP_REP / UP_FIX
*& pv_att_field: 'EVD' = generic, 'REP' = report, 'FIX' = fix
*&=====================================================================*
FORM upload_evidence USING pv_att_field TYPE char3.
  DATA: lt_file_table  TYPE filetable,
        lv_rc          TYPE i,
        lv_fullpath    TYPE string,
        lt_binary      TYPE solix_tab,
        lv_filelength  TYPE i,
        lv_xstring     TYPE xstring,
        lv_fname_only  TYPE string,
        lv_ext         TYPE string,
        lv_mime        TYPE w3conttype,
        ls_evd         TYPE zbug_evidence,
        lv_max_evd_id  TYPE numc10,
        lv_new_evd_id  TYPE numc10.

  " Bug must be saved first (need bug_id for evidence)
  IF gv_current_bug_id IS INITIAL.
    MESSAGE 'Save the bug first before uploading evidence.' TYPE 'W'.
    RETURN.
  ENDIF.

  " 1. File open dialog
  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      file_filter = 'All Files (*.*)|*.*|Images (*.png;*.jpg)|*.png;*.jpg|Documents (*.pdf;*.docx)|*.pdf;*.docx|Excel (*.xlsx)|*.xlsx'
    CHANGING
      file_table  = lt_file_table
      rc          = lv_rc
    EXCEPTIONS OTHERS = 1 ).
  IF lv_rc <= 0. RETURN. ENDIF.
  READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
  lv_fullpath = ls_file-filename.

  " 2. Extract filename from full path (after last \ or /)
  DATA: lv_idx TYPE i.
  lv_fname_only = lv_fullpath.
  FIND ALL OCCURRENCES OF '\' IN lv_fullpath MATCH OFFSET lv_idx.
  IF sy-subrc = 0.
    lv_fname_only = lv_fullpath+lv_idx.
    " Skip the backslash itself
    IF strlen( lv_fname_only ) > 0 AND lv_fname_only(1) = '\'.
      SHIFT lv_fname_only LEFT BY 1 PLACES.
    ENDIF.
  ELSE.
    FIND ALL OCCURRENCES OF '/' IN lv_fullpath MATCH OFFSET lv_idx.
    IF sy-subrc = 0.
      lv_fname_only = lv_fullpath+lv_idx.
      IF strlen( lv_fname_only ) > 0 AND lv_fname_only(1) = '/'.
        SHIFT lv_fname_only LEFT BY 1 PLACES.
      ENDIF.
    ENDIF.
  ENDIF.

  " 3. Detect MIME type from file extension
  DATA: lv_fname_upper TYPE string.
  lv_fname_upper = lv_fname_only.
  TRANSLATE lv_fname_upper TO UPPER CASE.
  IF lv_fname_upper CS '.XLSX'.  lv_mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
  ELSEIF lv_fname_upper CS '.XLS'.   lv_mime = 'application/vnd.ms-excel'.
  ELSEIF lv_fname_upper CS '.PDF'.   lv_mime = 'application/pdf'.
  ELSEIF lv_fname_upper CS '.DOCX'.  lv_mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.
  ELSEIF lv_fname_upper CS '.DOC'.   lv_mime = 'application/msword'.
  ELSEIF lv_fname_upper CS '.PNG'.   lv_mime = 'image/png'.
  ELSEIF lv_fname_upper CS '.JPG' OR lv_fname_upper CS '.JPEG'. lv_mime = 'image/jpeg'.
  ELSEIF lv_fname_upper CS '.TXT'.   lv_mime = 'text/plain'.
  ELSEIF lv_fname_upper CS '.ZIP'.   lv_mime = 'application/zip'.
  ELSE.                               lv_mime = 'application/octet-stream'.
  ENDIF.

  " 4. Upload binary file from frontend
  cl_gui_frontend_services=>gui_upload(
    EXPORTING
      filename   = lv_fullpath
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_filelength
    CHANGING
      data_tab   = lt_binary
    EXCEPTIONS
      file_open_error  = 1
      file_read_error  = 2
      OTHERS           = 3 ).
  IF sy-subrc <> 0.
    MESSAGE 'Failed to read file from frontend.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 5. Convert binary table to XSTRING
  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
    EXPORTING
      input_length = lv_filelength
    IMPORTING
      buffer       = lv_xstring
    TABLES
      binary_tab   = lt_binary
    EXCEPTIONS
      failed       = 1
      OTHERS       = 2.
  IF sy-subrc <> 0.
    MESSAGE 'Failed to convert file to binary.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 6. Auto-generate EVD_ID (MAX + 1)
  SELECT MAX( evd_id ) FROM zbug_evidence INTO @lv_max_evd_id.
  lv_new_evd_id = lv_max_evd_id + 1.

  " 7. Build evidence record
  ls_evd-evd_id     = lv_new_evd_id.
  ls_evd-bug_id     = gv_current_bug_id.
  ls_evd-project_id = gs_bug_detail-project_id.
  ls_evd-file_name  = lv_fname_only.
  ls_evd-mime_type  = lv_mime.
  ls_evd-file_size  = lv_filelength.
  ls_evd-content    = lv_xstring.
  ls_evd-ernam      = sy-uname.
  ls_evd-erdat      = sy-datum.
  ls_evd-erzet      = sy-uzeit.

  " 8. Insert into database
  INSERT zbug_evidence FROM @ls_evd.
  IF sy-subrc = 0.
    COMMIT WORK.
    " Log history
    PERFORM add_history_entry USING gv_current_bug_id 'AT' '' lv_fname_only 'Evidence uploaded'.
    COMMIT WORK.

    " 9. Set ATT_ field if applicable
    CASE pv_att_field.
      WHEN 'REP'.
        gs_bug_detail-att_report = lv_fname_only(100).  " Truncate to CHAR 100
        UPDATE zbug_tracker SET att_report = @gs_bug_detail-att_report
          WHERE bug_id = @gv_current_bug_id.
        COMMIT WORK.
      WHEN 'FIX'.
        gs_bug_detail-att_fix = lv_fname_only(100).     " Truncate to CHAR 100
        UPDATE zbug_tracker SET att_fix = @gs_bug_detail-att_fix
          WHERE bug_id = @gv_current_bug_id.
        COMMIT WORK.
    ENDCASE.

    MESSAGE |File "{ lv_fname_only }" uploaded successfully (ID: { lv_new_evd_id }).| TYPE 'S'.

    " 10. Refresh evidence ALV if visible
    IF go_alv_evidence IS NOT INITIAL.
      PERFORM load_evidence_data.
      go_alv_evidence->refresh_table_display( ).
    ENDIF.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Failed to save evidence to database.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& v4.0: UPLOAD EVIDENCE FILE (generic — no prefix requirement)
*& Fcode UP_FILE
*&=====================================================================*
FORM upload_evidence_file.
  PERFORM upload_evidence USING 'EVD'.
ENDFORM.

*&=====================================================================*
*& v4.0: UPLOAD REPORT FILE (Tester uploads test report / bug proof)
*& Fcode UP_REP — also sets ATT_REPORT on ZBUG_TRACKER
*&=====================================================================*
FORM upload_report_file.
  PERFORM upload_evidence USING 'REP'.
ENDFORM.

*&=====================================================================*
*& v4.0: UPLOAD FIX FILE (Developer uploads fix package / patch)
*& Fcode UP_FIX — also sets ATT_FIX on ZBUG_TRACKER
*&=====================================================================*
FORM upload_fix_file.
  PERFORM upload_evidence USING 'FIX'.
ENDFORM.

*&=====================================================================*
*& v4.0: DOWNLOAD EVIDENCE FILE
*& Called from evidence ALV double-click handler
*&=====================================================================*
FORM download_evidence_file USING pv_evd_id TYPE numc10.
  DATA: lv_xstring  TYPE xstring,
        lv_fname    TYPE sdok_filnm,
        lt_binary   TYPE solix_tab,
        lv_size     TYPE i,
        lv_filename TYPE string,
        lv_path     TYPE string,
        lv_fullpath TYPE string,
        lv_uaction  TYPE i.

  " 1. Read evidence content from DB
  SELECT SINGLE content, file_name FROM zbug_evidence
    INTO (@lv_xstring, @lv_fname)
    WHERE evd_id = @pv_evd_id.
  IF sy-subrc <> 0.
    MESSAGE 'Evidence file not found.' TYPE 'W'.
    RETURN.
  ENDIF.

  " 2. Convert XSTRING to binary table
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lv_xstring
    IMPORTING
      output_length = lv_size
    TABLES
      binary_tab    = lt_binary.

  " 3. File save dialog
  DATA: lv_default_name TYPE string.
  lv_default_name = lv_fname.
  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_file_name = lv_default_name
    CHANGING
      filename    = lv_filename
      path        = lv_path
      fullpath    = lv_fullpath
      user_action = lv_uaction
    EXCEPTIONS OTHERS = 1 ).
  IF lv_uaction <> 0.
    MESSAGE 'Download cancelled.' TYPE 'S'.
    RETURN.
  ENDIF.

  " 4. Download binary to frontend
  cl_gui_frontend_services=>gui_download(
    EXPORTING
      filename     = lv_fullpath
      filetype     = 'BIN'
      bin_filesize = lv_size
    CHANGING
      data_tab     = lt_binary
    EXCEPTIONS OTHERS = 1 ).
  IF sy-subrc = 0.
    MESSAGE |File "{ lv_fname }" downloaded successfully.| TYPE 'S'.
    " v4.0: Auto-open downloaded file
    cl_gui_frontend_services=>execute(
      EXPORTING document = lv_fullpath
      EXCEPTIONS OTHERS = 1 ).
  ELSE.
    MESSAGE 'Download failed.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& v4.0: DELETE EVIDENCE (selected row from Evidence ALV)
*& Fcode DL_EVD
*&=====================================================================*
FORM delete_evidence.
  " Get selected row from evidence ALV
  CHECK go_alv_evidence IS NOT INITIAL.

  DATA: lt_rows TYPE lvc_t_roid.
  go_alv_evidence->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL.
    MESSAGE 'Please select an evidence file to delete.' TYPE 'W'.
    RETURN.
  ENDIF.

  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  DATA: ls_evd TYPE ty_evidence_alv.
  READ TABLE gt_evidence INTO ls_evd INDEX ls_row-row_id.
  IF sy-subrc <> 0.
    MESSAGE 'Could not read selected evidence row.' TYPE 'W'.
    RETURN.
  ENDIF.

  " Popup confirm
  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = |Delete evidence file "{ ls_evd-file_name }" (ID: { ls_evd-evd_id })?|.
  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.

  " Delete from DB
  DELETE FROM zbug_evidence WHERE evd_id = @ls_evd-evd_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    PERFORM add_history_entry USING gv_current_bug_id 'AT' ls_evd-file_name '' 'Evidence deleted'.
    COMMIT WORK.
    MESSAGE |Evidence "{ ls_evd-file_name }" deleted.| TYPE 'S'.
    " Refresh ALV
    PERFORM load_evidence_data.
    go_alv_evidence->refresh_table_display( ).
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Delete failed.' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& v4.0: CHECK EVIDENCE PREFIX BEFORE STATUS TRANSITION
*& Enforces file naming convention per status:
*&   → Fixed(5):    require BUGPROOF_ evidence exists
*&   → Resolved(6): require TESTCASE_ evidence exists
*&   → Closed(7):   require CONFIRM_ evidence exists
*&=====================================================================*
FORM check_evidence_for_status USING    pv_new_status TYPE zde_bug_status
                               CHANGING pv_ok         TYPE abap_bool.
  pv_ok = abap_true.
  CHECK gv_current_bug_id IS NOT INITIAL.

  DATA: lv_prefix TYPE string,
        lv_count  TYPE i,
        lv_like   TYPE sdok_filnm.

  CASE pv_new_status.
    WHEN gc_st_fixed.     " To Fixed: need bug proof uploaded earlier
      lv_prefix = 'BUGPROOF_'.
    WHEN gc_st_resolved.  " To Resolved: need test case result
      lv_prefix = 'TESTCASE_'.
    WHEN gc_st_closed.    " To Closed: need confirmation
      lv_prefix = 'CONFIRM_'.
    WHEN OTHERS.
      RETURN.  " No check needed for other transitions
  ENDCASE.

  " Build LIKE pattern: 'BUGPROOF_%'
  CONCATENATE lv_prefix '%' INTO lv_like.

  SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
    WHERE bug_id    = @gv_current_bug_id
      AND file_name LIKE @lv_like.

  IF lv_count = 0.
    MESSAGE |Evidence file with prefix "{ lv_prefix }" is required before this status change. Upload first.| TYPE 'W'.
    pv_ok = abap_false.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& v4.0: CHECK UNSAVED BUG CHANGES (snapshot comparison)
*& Pops up Save/Discard/Cancel if changes detected
*&=====================================================================*
FORM check_unsaved_bug CHANGING pv_continue TYPE abap_bool.
  pv_continue = abap_true.

  " Sync mini editor text to work area for accurate comparison
  PERFORM save_desc_mini_to_workarea.

  " Compare current state with snapshot
  IF gs_bug_detail = gs_bug_snapshot.
    RETURN.  " No changes — continue silently
  ENDIF.

  " Changes detected — popup
  DATA: lv_answer TYPE char1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Unsaved Changes'
      text_question         = 'You have unsaved changes. Save before leaving?'
      text_button_1         = 'Save'
      text_button_2         = 'Discard'
      default_button        = '1'
      display_cancel_button = 'X'
    IMPORTING
      answer                = lv_answer.

  CASE lv_answer.
    WHEN '1'. " Save
      PERFORM save_bug_detail.
      pv_continue = abap_true.
    WHEN '2'. " Discard
      pv_continue = abap_true.
    WHEN 'A'. " Cancel — stay on screen
      pv_continue = abap_false.
  ENDCASE.
ENDFORM.

*&=====================================================================*
*& v4.0: CHECK UNSAVED PROJECT CHANGES (snapshot comparison)
*&=====================================================================*
FORM check_unsaved_prj CHANGING pv_continue TYPE abap_bool.
  pv_continue = abap_true.

  " Compare current state with snapshot
  IF gs_project = gs_prj_snapshot.
    RETURN.  " No changes — continue silently
  ENDIF.

  " Changes detected — popup
  DATA: lv_answer TYPE char1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = 'Unsaved Changes'
      text_question         = 'You have unsaved project changes. Save before leaving?'
      text_button_1         = 'Save'
      text_button_2         = 'Discard'
      default_button        = '1'
      display_cancel_button = 'X'
    IMPORTING
      answer                = lv_answer.

  CASE lv_answer.
    WHEN '1'. " Save
      PERFORM save_project_detail.
      pv_continue = abap_true.
    WHEN '2'. " Discard
      pv_continue = abap_true.
    WHEN 'A'. " Cancel — stay on screen
      pv_continue = abap_false.
  ENDCASE.
ENDFORM.

*&=====================================================================*
*& v4.0: SEND EMAIL NOTIFICATION (BCS API — real implementation)
*& Sends email to Dev, Tester, Verify Tester with bug details
*&=====================================================================*
FORM send_mail_notification.
  DATA: lo_send_request TYPE REF TO cl_bcs,
        lo_document     TYPE REF TO cl_document_bcs,
        lo_sender       TYPE REF TO cl_sapuser_bcs,
        lo_recipient    TYPE REF TO if_recipient_bcs,
        lt_text         TYPE bcsy_text,
        ls_text         TYPE soli,
        lv_subject      TYPE so_obj_des,
        lv_email        TYPE adr6-smtp_addr,
        lv_has_rcpt     TYPE abap_bool.

  " Build email subject
  lv_subject = |Bug { gs_bug_detail-bug_id } - { gs_bug_detail-title }|.

  " Build email body
  CLEAR lt_text.
  ls_text-line = |Bug Tracking Notification|.      APPEND ls_text TO lt_text.
  ls_text-line = |============================|.   APPEND ls_text TO lt_text.
  ls_text-line = | |.                               APPEND ls_text TO lt_text.
  ls_text-line = |Bug ID:    { gs_bug_detail-bug_id }|. APPEND ls_text TO lt_text.
  ls_text-line = |Title:     { gs_bug_detail-title }|.   APPEND ls_text TO lt_text.
  ls_text-line = |Status:    { gv_status_disp }|.        APPEND ls_text TO lt_text.
  ls_text-line = |Priority:  { gv_priority_disp }|.      APPEND ls_text TO lt_text.
  ls_text-line = |Severity:  { gv_severity_disp }|.      APPEND ls_text TO lt_text.
  ls_text-line = |Project:   { gs_bug_detail-project_id }|. APPEND ls_text TO lt_text.
  ls_text-line = |Module:    { gs_bug_detail-sap_module }|.  APPEND ls_text TO lt_text.
  ls_text-line = | |.                               APPEND ls_text TO lt_text.
  ls_text-line = |Tester:    { gs_bug_detail-tester_id }|.   APPEND ls_text TO lt_text.
  ls_text-line = |Developer: { gs_bug_detail-dev_id }|.      APPEND ls_text TO lt_text.
  ls_text-line = |Verify:    { gs_bug_detail-verify_tester_id }|. APPEND ls_text TO lt_text.
  ls_text-line = | |.                               APPEND ls_text TO lt_text.
  ls_text-line = |Sent by:   { sy-uname } at { sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
  APPEND ls_text TO lt_text.

  TRY.
      " Create persistent send request
      lo_send_request = cl_bcs=>create_persistent( ).

      " Create document
      lo_document = cl_document_bcs=>create_document(
        i_type    = 'RAW'
        i_text    = lt_text
        i_subject = lv_subject ).
      lo_send_request->set_document( lo_document ).

      " Set sender (current user)
      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
      lo_send_request->set_sender( lo_sender ).

      " Collect unique recipients: dev, tester, verify tester
      DATA: lt_recipients TYPE TABLE OF zde_username.
      IF gs_bug_detail-dev_id IS NOT INITIAL.
        APPEND gs_bug_detail-dev_id TO lt_recipients.
      ENDIF.
      IF gs_bug_detail-tester_id IS NOT INITIAL.
        APPEND gs_bug_detail-tester_id TO lt_recipients.
      ENDIF.
      IF gs_bug_detail-verify_tester_id IS NOT INITIAL.
        APPEND gs_bug_detail-verify_tester_id TO lt_recipients.
      ENDIF.
      SORT lt_recipients.
      DELETE ADJACENT DUPLICATES FROM lt_recipients.

      " Remove current user from recipients (don't email yourself)
      DELETE lt_recipients WHERE table_line = sy-uname.

      lv_has_rcpt = abap_false.
      LOOP AT lt_recipients INTO DATA(lv_user).
        CLEAR lv_email.
        SELECT SINGLE email FROM zbug_users INTO @lv_email
          WHERE user_id = @lv_user AND is_del <> 'X'.
        IF sy-subrc = 0 AND lv_email IS NOT INITIAL.
          lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_email ).
          lo_send_request->add_recipient( lo_recipient ).
          lv_has_rcpt = abap_true.
        ENDIF.
      ENDLOOP.

      IF lv_has_rcpt = abap_false.
        MESSAGE 'No recipients with valid email addresses found.' TYPE 'W'.
        RETURN.
      ENDIF.

      " Send immediately
      lo_send_request->set_send_immediately( abap_true ).
      lo_send_request->send( ).
      COMMIT WORK.
      MESSAGE 'Email notification sent successfully.' TYPE 'S'.

    CATCH cx_bcs INTO DATA(lx_bcs).
      DATA: lv_err_text TYPE string.
      lv_err_text = lx_bcs->get_text( ).
      MESSAGE lv_err_text TYPE 'S' DISPLAY LIKE 'E'.
  ENDTRY.
ENDFORM.

*&=====================================================================*
*& UPLOAD PROJECT EXCEL (Phase D — real implementation)
*& Fcode UPLOAD on Screen 0400: Manager uploads Excel → validate → insert
*&=====================================================================*
FORM upload_project_excel.
  DATA: lv_file     TYPE string,
        lt_raw      TYPE truxs_t_text_data,
        lt_projects TYPE TABLE OF zbug_project,
        ls_project  TYPE zbug_project,
        lv_errors   TYPE i,
        lv_success  TYPE i.

  " 1. File open dialog
  DATA: lt_file_table TYPE filetable, lv_rc TYPE i.
  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING file_filter = 'Excel Files (*.xlsx)|*.xlsx'
    CHANGING  file_table  = lt_file_table
              rc          = lv_rc
    EXCEPTIONS OTHERS = 1 ).

  IF lv_rc <= 0. RETURN. ENDIF.
  READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
  lv_file = ls_file-filename.

  " 2. Read Excel into internal table
  TYPES: BEGIN OF ty_upload,
           project_id      TYPE char20,
           project_name    TYPE char100,
           description     TYPE char255,
           start_date      TYPE char10,
           end_date        TYPE char10,
           project_manager TYPE char12,
           note            TYPE char255,
         END OF ty_upload.
  DATA: lt_upload TYPE TABLE OF ty_upload.

  " v4.1 BUGFIX #4: i_tab_raw_data is a CHANGING parameter (not EXPORTING)
  " Passing it in EXPORTING block caused CALL_FUNCTION_CONFLICT_TYPE runtime error
  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_field_seperator    = 'X'
      i_line_header        = 'X'    " Skip header row
      i_filename           = lv_file
    TABLES
      i_tab_converted_data = lt_upload
    CHANGING
      i_tab_raw_data       = lt_raw
    EXCEPTIONS
      conversion_failed    = 1
      OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Failed to read Excel file.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 3. Validate + Insert
  LOOP AT lt_upload ASSIGNING FIELD-SYMBOL(<fs>).
    CLEAR ls_project.

    " Skip header/format hint rows
    IF <fs>-project_id CS 'PROJECT_ID' OR <fs>-project_id CS '(Char'.
      CONTINUE.
    ENDIF.

    " Validate PROJECT_ID not empty
    IF <fs>-project_id IS INITIAL.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " Validate PROJECT_ID not duplicate
    SELECT COUNT(*) FROM zbug_project
      WHERE project_id = @<fs>-project_id.
    IF sy-dbcnt > 0.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " Validate Project Manager exists + is Manager role + active
    SELECT COUNT(*) FROM zbug_users
      WHERE user_id = @<fs>-project_manager AND role = 'M' AND is_del <> 'X'.
    IF sy-dbcnt = 0.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " Map data to structure
    ls_project-project_id      = <fs>-project_id.
    ls_project-project_name    = <fs>-project_name.
    ls_project-description     = <fs>-description.
    ls_project-project_manager = <fs>-project_manager.
    ls_project-note            = <fs>-note.

    " Parse dates (DD.MM.YYYY → YYYYMMDD)
    IF <fs>-start_date IS NOT INITIAL AND strlen( <fs>-start_date ) = 10.
      CONCATENATE <fs>-start_date+6(4) <fs>-start_date+3(2) <fs>-start_date(2)
        INTO ls_project-start_date.
    ENDIF.
    IF <fs>-end_date IS NOT INITIAL AND strlen( <fs>-end_date ) = 10.
      CONCATENATE <fs>-end_date+6(4) <fs>-end_date+3(2) <fs>-end_date(2)
        INTO ls_project-end_date.
    ENDIF.

    " Default values
    ls_project-project_status = '1'.  " Opening
    ls_project-ernam          = sy-uname.
    ls_project-erdat          = sy-datum.
    ls_project-erzet          = sy-uzeit.

    APPEND ls_project TO lt_projects.
    ADD 1 TO lv_success.
  ENDLOOP.

  " 4. Batch insert + refresh ALV
  IF lt_projects IS NOT INITIAL.
    INSERT zbug_project FROM TABLE lt_projects.
    COMMIT WORK.
    DATA: lv_msg TYPE string.
    lv_msg = |Uploaded { lv_success } project(s). Errors: { lv_errors }|.
    MESSAGE lv_msg TYPE 'S'.
    " Refresh project ALV after upload
    PERFORM select_project_data.
    IF go_alv_project IS NOT INITIAL.
      go_alv_project->refresh_table_display( ).
    ENDIF.
  ELSE.
    MESSAGE 'No valid data to upload.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
