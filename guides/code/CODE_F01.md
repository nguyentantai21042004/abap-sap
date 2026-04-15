*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F01 — Main Business Logic (forms/subroutines)
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

  " Status text mapping (10 states — 6=FinalTesting, V=Resolved)
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    <bug>-status_text = SWITCH #( <bug>-status
      WHEN gc_st_new          THEN 'New'
      WHEN gc_st_assigned     THEN 'Assigned'
      WHEN gc_st_inprogress   THEN 'In Progress'
      WHEN gc_st_pending      THEN 'Pending'
      WHEN gc_st_fixed        THEN 'Fixed'
      WHEN gc_st_finaltesting THEN 'Final Testing'
      WHEN gc_st_closed       THEN 'Closed'
      WHEN gc_st_waiting      THEN 'Waiting'
      WHEN gc_st_rejected     THEN 'Rejected'
      WHEN gc_st_resolved     THEN 'Resolved'
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

  " Calculate dashboard metrics after loading bugs
  PERFORM calculate_dashboard.
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
      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.
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
    MESSAGE 'Project ID is required. Bug must belong to a project.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Validate TITLE is set
  IF gs_bug_detail-title IS INITIAL.
    MESSAGE 'Title is required.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " Severity vs Priority cross-validation
  " Dump/Critical(1), VeryHigh(2), High(3) → must have Priority = High
  IF gs_bug_detail-severity IS NOT INITIAL
     AND ( gs_bug_detail-severity = '1' OR gs_bug_detail-severity = '2'
           OR gs_bug_detail-severity = '3' ).
    IF gs_bug_detail-priority <> 'H'.
      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'S' DISPLAY LIKE 'E'.
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

    " FORCE status = New (always), pre-fill created_at + tester_id
    gs_bug_detail-status     = gc_st_new.
    gs_bug_detail-created_at = sy-datum.
    gs_bug_detail-tester_id  = lv_un.

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

    " Sync desc_text from editor after save_long_text
    IF go_edit_desc IS NOT INITIAL.
      DATA: lt_desc_sync TYPE TABLE OF char255.
      cl_gui_cfw=>flush( ).
      go_edit_desc->get_text_as_r3table(
        IMPORTING table = lt_desc_sync
        EXCEPTIONS OTHERS = 3 ).
      IF sy-subrc = 0.
        CLEAR gs_bug_detail-desc_text.
        LOOP AT lt_desc_sync INTO DATA(lv_sync_line).
          IF gs_bug_detail-desc_text IS NOT INITIAL.
            gs_bug_detail-desc_text = gs_bug_detail-desc_text
              && cl_abap_char_utilities=>cr_lf && lv_sync_line.
          ELSE.
            gs_bug_detail-desc_text = lv_sync_line.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.

    " Trigger auto-assign developer after creating new bug
    IF gv_mode = gc_mode_create.
      PERFORM auto_assign_developer.
    ENDIF.

    gv_mode = gc_mode_change.
    " Update snapshot after successful save
    gs_bug_snapshot = gs_bug_detail.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Save failed. Please check required fields.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=== SAVE DESCRIPTION MINI EDITOR → WORK AREA ===*
" Called before save_bug_detail — reads mini editor text into gs_bug_detail-desc_text
FORM save_desc_mini_to_workarea.
  CHECK go_desc_mini_edit IS NOT INITIAL.
  DATA: lt_mini TYPE TABLE OF char255,
        lv_text TYPE string.

  " Flush GUI control data before reading
  " Without flush, CL_GUI_TEXTEDIT raises POTENTIAL_DATA_LOSS
  cl_gui_cfw=>flush( ).

  go_desc_mini_edit->get_text_as_r3table(
    IMPORTING table = lt_mini
    EXCEPTIONS error_dp        = 1
               error_dp_create = 2
               OTHERS          = 3 ).
  IF sy-subrc <> 0.
    " Silently return — control may not be ready yet (no user-facing warning)
    RETURN.
  ENDIF.

  " Concatenate lines without inserting extra line breaks
  " get_text_as_r3table splits at 255 chars — join with space to preserve long text
  CLEAR lv_text.
  LOOP AT lt_mini INTO DATA(lv_line).
    IF sy-tabix = 1.
      lv_text = lv_line.
    ELSE.
      lv_text = lv_text && lv_line.
    ENDIF.
  ENDLOOP.
  gs_bug_detail-desc_text = lv_text.
ENDFORM.

*&=== SAVE PROJECT DETAIL ===*
FORM save_project_detail.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.

  " Auto-generate PROJECT_ID in Create mode
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
    MESSAGE 'Project ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF gs_project-project_name IS INITIAL.
    MESSAGE 'Project Name is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  " Project completion validation — block Done if unresolved bugs
  " gc_st_rejected counts as terminal state (resolved OR closed OR rejected = done)
  IF gs_project-project_status = '3'. " Done
    DATA: lv_open_bugs TYPE i.
    SELECT COUNT(*) FROM zbug_tracker INTO @lv_open_bugs
      WHERE project_id = @gs_project-project_id
        AND is_del <> 'X'
        AND status <> @gc_st_resolved
        AND status <> @gc_st_closed
        AND status <> @gc_st_rejected.
    IF lv_open_bugs > 0.
      DATA: lv_block_msg TYPE string.
      lv_block_msg = |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed/Rejected.|.
      MESSAGE lv_block_msg TYPE 'S' DISPLAY LIKE 'E'.
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
    " Update snapshot after successful save
    gs_prj_snapshot = gs_project.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=== ALV ROW COLORING ===*
FORM set_bug_colors.
  DATA: ls_color TYPE lvc_s_scol.
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    CLEAR <bug>-t_color.
    ls_color-fname = 'STATUS_TEXT'.
    CASE <bug>-status.
      WHEN gc_st_new.          ls_color-color-col = 1. ls_color-color-int = 0.  " Blue
      WHEN gc_st_waiting.      ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow
      WHEN gc_st_assigned.     ls_color-color-col = 7. ls_color-color-int = 0.  " Orange
      WHEN gc_st_inprogress.   ls_color-color-col = 6. ls_color-color-int = 0.  " Purple
      WHEN gc_st_pending.      ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow
      WHEN gc_st_fixed.        ls_color-color-col = 5. ls_color-color-int = 0.  " Green
      WHEN gc_st_finaltesting. ls_color-color-col = 2. ls_color-color-int = 0.  " Cyan
      WHEN gc_st_resolved.     ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green
      WHEN gc_st_closed.       ls_color-color-col = 1. ls_color-color-int = 1.  " Grey
      WHEN gc_st_rejected.     ls_color-color-col = 6. ls_color-color-int = 1.  " Red
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

*&=== GET SELECTED BUG FROM SEARCH RESULTS ALV ===*
FORM get_selected_search_bug CHANGING pv_bug_id TYPE zde_bug_id.
  CLEAR pv_bug_id.
  CHECK go_search_alv IS NOT INITIAL.
  DATA: lt_rows TYPE lvc_t_roid.
  go_search_alv->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL. RETURN. ENDIF.
  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_search_results INTO DATA(ls_bug) INDEX ls_row-row_id.
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
    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
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
    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
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
  " Check project is saved before adding users
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

  " Use SVAL-VALUE (generic CHAR 40, no search help) to avoid DDIC crash
  CLEAR ls_field.
  ls_field-tabname   = 'SVAL'.
  ls_field-fieldname = 'VALUE'.
  ls_field-fieldtext = 'Role (M=Manager / D=Developer / T=Tester)'.
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
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'VALUE'.
  lv_role = ls_field-value.

  IF lv_uid IS INITIAL.
    MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
  ENDIF.

  " Validate ROLE is M, D, or T
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
*& Guard: tc_users-current_line defaults to 1 even without a click.
*& Uses gv_tc_user_selected flag (set in tc_users_modify) to confirm
*& the user actually interacted with the table control.
FORM remove_user_from_project.
  " Require explicit user interaction before allowing remove
  IF gv_tc_user_selected = abap_false.
    MESSAGE 'Please click on a user row to select it first.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.

  " Validate range — prevent deleting wrong row
  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
    MESSAGE 'Invalid row selection.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
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
    " Reset flag after successful remove
    CLEAR gv_tc_user_selected.
    MESSAGE |User { gs_user_project-user_id } removed.| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Remove failed.' TYPE 'S' DISPLAY LIKE 'E'.
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
      WHEN 'RJ' THEN 'Rejected'
      WHEN 'AA' THEN 'Auto-Assigned' ).
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
*& CLEANUP: Free all Screen 0300 GUI controls
*& Called on BACK/CANC/EXIT from Bug Detail — ensures clean state
*& for the next bug opened.
*& Also cleans up Screen 0370 (trans_note) + Screen 0220 (search ALV)
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

  " --- Evidence ALV (Subscreen 0350) ---
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

  " --- Transition Note Editor (Screen 0370) ---
  IF go_edit_trans_note IS NOT INITIAL.
    go_edit_trans_note->free( ).
    FREE go_edit_trans_note.
    CLEAR go_edit_trans_note.
  ENDIF.
  IF go_cont_trans_note IS NOT INITIAL.
    go_cont_trans_note->free( ).
    FREE go_cont_trans_note.
    CLEAR go_cont_trans_note.
  ENDIF.

  " --- Search Results ALV (Screen 0220) ---
  IF go_search_alv IS NOT INITIAL.
    go_search_alv->free( ).
    FREE go_search_alv.
    CLEAR go_search_alv.
  ENDIF.
  IF go_cont_search IS NOT INITIAL.
    go_cont_search->free( ).
    FREE go_cont_search.
    CLEAR go_cont_search.
  ENDIF.

  " --- Clear data-loaded flag so next bug triggers fresh DB load ---
  CLEAR gv_detail_loaded.
ENDFORM.

*&=====================================================================*
*& LOAD EVIDENCE DATA (metadata only — no CONTENT for performance)
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
*& UPLOAD EVIDENCE — Common logic for UP_FILE / UP_REP / UP_FIX
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

  " Auto-save in create mode before uploading evidence
  " Evidence needs bug_id (FK). If bug not saved yet, save it first.
  IF gv_current_bug_id IS INITIAL.
    IF gv_mode = gc_mode_create.
      " Auto-validate and save the bug (generates bug_id, switches to Change mode)
      PERFORM save_desc_mini_to_workarea.
      PERFORM save_bug_detail.
      IF gv_current_bug_id IS INITIAL.
        " Save failed — validation errors already shown via TYPE 'S' DISPLAY LIKE 'E'
        RETURN.
      ENDIF.
      " save_bug_detail already set gv_mode = gc_mode_change
    ELSE.
      MESSAGE 'Bug ID not available. Cannot upload evidence.' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
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
*& UPLOAD EVIDENCE FILE (generic — no prefix requirement)
*& Fcode UP_FILE
*&=====================================================================*
FORM upload_evidence_file.
  PERFORM upload_evidence USING 'EVD'.
ENDFORM.

*&=====================================================================*
*& UPLOAD REPORT FILE (Tester uploads test report / bug proof)
*& Fcode UP_REP — also sets ATT_REPORT on ZBUG_TRACKER
*&=====================================================================*
FORM upload_report_file.
  PERFORM upload_evidence USING 'REP'.
ENDFORM.

*&=====================================================================*
*& UPLOAD FIX FILE (Developer uploads fix package / patch)
*& Fcode UP_FIX — also sets ATT_FIX on ZBUG_TRACKER
*&=====================================================================*
FORM upload_fix_file.
  PERFORM upload_evidence USING 'FIX'.
ENDFORM.

*&=====================================================================*
*& DOWNLOAD EVIDENCE FILE
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
    " Auto-open downloaded file
    cl_gui_frontend_services=>execute(
      EXPORTING document = lv_fullpath
      EXCEPTIONS OTHERS = 1 ).
  ELSE.
    MESSAGE 'Download failed.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& DELETE EVIDENCE (selected row from Evidence ALV)
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
    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& CHECK EVIDENCE FOR STATUS TRANSITION
*&
*& Rules:
*&   → Fixed(5): require any evidence file (COUNT > 0)
*&   → Resolved(V): require any evidence file (COUNT > 0)
*&   → Other statuses: no evidence check needed
*&
*& NOTE: ZBUG_EVIDENCE has NO is_del field — not in WHERE clause.
*& File prefix enforcement (BUGPROOF_, TESTCASE_, CONFIRM_) not applied.
*&=====================================================================*
FORM check_evidence_for_status USING    pv_new_status TYPE zde_bug_status
                               CHANGING pv_ok         TYPE abap_bool.
  pv_ok = abap_true.
  CHECK gv_current_bug_id IS NOT INITIAL.

  " Evidence required for Fixed and Resolved
  IF pv_new_status = gc_st_fixed OR pv_new_status = gc_st_resolved.
    DATA: lv_count TYPE i.
    SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
      WHERE bug_id = @gv_current_bug_id.
    IF lv_count = 0.
      IF pv_new_status = gc_st_fixed.
        MESSAGE 'Evidence file is required before marking as Fixed. Upload first.' TYPE 'S' DISPLAY LIKE 'W'.
      ELSE.
        MESSAGE 'Evidence file is required before marking as Resolved. Upload first.' TYPE 'S' DISPLAY LIKE 'W'.
      ENDIF.
      pv_ok = abap_false.
    ENDIF.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& CHECK UNSAVED BUG CHANGES (snapshot comparison)
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
*& CHECK UNSAVED PROJECT CHANGES (snapshot comparison)
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
*& SEND EMAIL NOTIFICATION (BCS API — real implementation)
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

  " i_tab_raw_data is a CHANGING parameter (not EXPORTING)
  " Passing it in EXPORTING block causes CALL_FUNCTION_CONFLICT_TYPE runtime error
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

*&=====================================================================*
*&=====================================================================*
*& NEW FORMS
*&=====================================================================*
*&=====================================================================*

*&=====================================================================*
*& SEARCH PROJECTS (Screen 0410 → Screen 0400)
*&
*& Filters projects based on s_prj_id, s_prj_mn, s_prj_st.
*& Security: Manager sees ALL projects (no INNER JOIN).
*&           Non-Manager uses INNER JOIN with ZBUG_USER_PROJEC.
*& Results stored in gt_projects.
*& Sets gv_from_search = abap_true so PBO init_project_list skips
*& select_project_data (data already loaded).
*&=====================================================================*
FORM search_projects.
  CLEAR gt_projects.

  IF gv_role = 'M'.
    " Manager sees ALL projects — no security INNER JOIN
    SELECT p~project_id, p~project_name, p~description,
           p~project_status, p~project_manager,
           p~start_date, p~end_date, p~note
      FROM zbug_project AS p
      WHERE p~is_del <> 'X'
        AND ( @s_prj_id IS INITIAL OR p~project_id      = @s_prj_id )
        AND ( @s_prj_mn IS INITIAL OR p~project_manager  = @s_prj_mn )
        AND ( @s_prj_st IS INITIAL OR p~project_status   = @s_prj_st )
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.
  ELSE.
    " Non-Manager: INNER JOIN with ZBUG_USER_PROJEC for security
    SELECT p~project_id, p~project_name, p~description,
           p~project_status, p~project_manager,
           p~start_date, p~end_date, p~note
      FROM zbug_project AS p
      INNER JOIN zbug_user_projec AS u ON p~project_id = u~project_id
      WHERE p~is_del <> 'X'
        AND u~user_id = @sy-uname
        AND ( @s_prj_id IS INITIAL OR p~project_id      = @s_prj_id )
        AND ( @s_prj_mn IS INITIAL OR p~project_manager  = @s_prj_mn )
        AND ( @s_prj_st IS INITIAL OR p~project_status   = @s_prj_st )
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.

    " Remove duplicates (user may have multiple roles in same project)
    SORT gt_projects BY project_id.
    DELETE ADJACENT DUPLICATES FROM gt_projects COMPARING project_id.
  ENDIF.

  " Map status text
  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
    <prj>-status_text = SWITCH #( <prj>-project_status
      WHEN '1' THEN 'Opening'
      WHEN '2' THEN 'In Process'
      WHEN '3' THEN 'Done'
      WHEN '4' THEN 'Cancelled' ).
  ENDLOOP.

  " Flag: data already loaded — PBO should NOT call select_project_data
  gv_from_search = abap_true.
ENDFORM.

*&=====================================================================*
*& CALCULATE DASHBOARD (Screen 0200 header metrics)
*&
*& Counts gt_bugs by status, priority, and SAP module.
*& Called from select_bug_data after loading bugs.
*& Results are displayed on Screen 0200 dashboard header fields.
*&=====================================================================*
FORM calculate_dashboard.
  " Reset all counters
  CLEAR: gv_dash_total,
         gv_d_new, gv_d_assigned, gv_d_inprog, gv_d_pending,
         gv_d_fixed, gv_d_finaltest, gv_d_resolved,
         gv_d_rejected, gv_d_waiting, gv_d_closed,
         gv_d_p_high, gv_d_p_med, gv_d_p_low,
         gv_d_m_fi, gv_d_m_mm, gv_d_m_sd, gv_d_m_abap, gv_d_m_basis.

  gv_dash_total = lines( gt_bugs ).

  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    " By Status
    CASE <bug>-status.
      WHEN gc_st_new.          ADD 1 TO gv_d_new.
      WHEN gc_st_assigned.     ADD 1 TO gv_d_assigned.
      WHEN gc_st_inprogress.   ADD 1 TO gv_d_inprog.
      WHEN gc_st_pending.      ADD 1 TO gv_d_pending.
      WHEN gc_st_fixed.        ADD 1 TO gv_d_fixed.
      WHEN gc_st_finaltesting. ADD 1 TO gv_d_finaltest.
      WHEN gc_st_resolved.     ADD 1 TO gv_d_resolved.
      WHEN gc_st_rejected.     ADD 1 TO gv_d_rejected.
      WHEN gc_st_waiting.      ADD 1 TO gv_d_waiting.
      WHEN gc_st_closed.       ADD 1 TO gv_d_closed.
    ENDCASE.

    " By Priority
    CASE <bug>-priority.
      WHEN 'H'. ADD 1 TO gv_d_p_high.
      WHEN 'M'. ADD 1 TO gv_d_p_med.
      WHEN 'L'. ADD 1 TO gv_d_p_low.
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

*&=====================================================================*
*& VALIDATE STATUS TRANSITION (Screen 0370 popup)
*&
*& Validates the transition matrix before applying:
*& 1. New status must be selected
*& 2. Transition must be in allowed list
*& 3. Role must be authorized
*& 4. Required fields must be filled (dev_id, trans_note, evidence)
*&
*& Sets gv_trans_confirmed = abap_true if all checks pass.
*& Called from PAI user_command_0370 → CONFIRM fcode.
*&=====================================================================*
FORM validate_status_transition.
  gv_trans_confirmed = abap_false.

  " 1. New status must be selected
  IF gv_trans_new_status IS INITIAL.
    MESSAGE 'Please select a new status.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 2. Validate allowed transition (matrix check)
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

  " 3. Role authorization check (Manager does NOT auto-bypass — role matters)
  DATA: lv_role_ok TYPE abap_bool VALUE abap_false.
  CASE gv_trans_cur_status.
    WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
      " Only Manager can transition from New/Waiting/Pending
      IF gv_role = 'M'. lv_role_ok = abap_true. ENDIF.
    WHEN gc_st_assigned OR gc_st_inprogress.
      " Dev (assigned to this bug) or Manager
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lv_role_ok = abap_true.
      ENDIF.
    WHEN gc_st_finaltesting.
      " Final Tester (assigned verify_tester_id) or Manager
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
      cl_gui_cfw=>flush( ).
      go_edit_trans_note->get_text_as_r3table(
        IMPORTING table = lt_note_check
        EXCEPTIONS OTHERS = 3 ).
    ENDIF.
    IF lt_note_check IS INITIAL.
      MESSAGE 'Rejection reason (note) is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " 4d. Evidence required for → Fixed and → Resolved
  IF gv_trans_new_status = gc_st_fixed OR gv_trans_new_status = gc_st_resolved.
    DATA: lv_evd_count TYPE i.
    SELECT COUNT(*) FROM zbug_evidence INTO @lv_evd_count
      WHERE bug_id = @gv_current_bug_id.
    IF lv_evd_count = 0.
      IF gv_trans_new_status = gc_st_fixed.
        MESSAGE 'Evidence file is required before marking as Fixed.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
      ELSE.
        MESSAGE 'Evidence file is required before marking as Resolved.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
      ENDIF.
    ENDIF.
  ENDIF.

  " 4e. TRANS_NOTE required for → Resolved (test result note)
  IF gv_trans_new_status = gc_st_resolved.
    DATA: lt_note_res TYPE TABLE OF char255.
    IF go_edit_trans_note IS NOT INITIAL.
      cl_gui_cfw=>flush( ).
      go_edit_trans_note->get_text_as_r3table(
        IMPORTING table = lt_note_res
        EXCEPTIONS OTHERS = 3 ).
    ENDIF.
    IF lt_note_res IS INITIAL.
      MESSAGE 'Test result note is required for Resolved.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " All checks passed
  gv_trans_confirmed = abap_true.
ENDFORM.

*&=====================================================================*
*& APPLY STATUS TRANSITION (execute the actual change)
*&
*& Called from PAI user_command_0370 AFTER validate_status_transition
*& passes (gv_trans_confirmed = abap_true).
*&
*& Actions:
*& 1. Update gs_bug_detail fields (status, dev_id, verify_tester_id)
*& 2. Save TRANS_NOTE to Dev Note (Z002) if → Rejected
*& 3. Save TRANS_NOTE to Tester Note (Z003) if FinalTesting → Resolved/InProgress
*& 4. UPDATE ZBUG_TRACKER
*& 5. Log history via add_history_entry
*& 6. Trigger auto_assign_tester if → Fixed
*&
*& NOTE: Uses save_long_text_direct (NOT save_long_text) because
*& the text comes from go_edit_trans_note popup, not the main editors.
*&=====================================================================*
FORM apply_status_transition.
  DATA: lv_old_status TYPE zde_bug_status.
  lv_old_status = gs_bug_detail-status.

  " Update bug detail in work area
  gs_bug_detail-status = gv_trans_new_status.

  " Update developer/tester if provided
  IF gv_trans_dev_id IS NOT INITIAL.
    gs_bug_detail-dev_id = gv_trans_dev_id.
  ENDIF.
  IF gv_trans_ftester_id IS NOT INITIAL.
    gs_bug_detail-verify_tester_id = gv_trans_ftester_id.
  ENDIF.

  " Read transition note text ONCE (single flush + get_text call)
  DATA: lt_trans_note TYPE gty_t_char255.
  IF go_edit_trans_note IS NOT INITIAL.
    cl_gui_cfw=>flush( ).
    go_edit_trans_note->get_text_as_r3table(
      IMPORTING table = lt_trans_note
      EXCEPTIONS OTHERS = 3 ).
  ENDIF.

  " Save TRANS_NOTE → Dev Note (Z002) if → Rejected
  IF gv_trans_new_status = gc_st_rejected AND lt_trans_note IS NOT INITIAL.
    PERFORM save_long_text_direct USING 'Z002' lt_trans_note.
  ENDIF.

  " Save TRANS_NOTE → Tester Note (Z003) if FinalTesting → Resolved or → InProgress
  IF gv_trans_cur_status = gc_st_finaltesting AND lt_trans_note IS NOT INITIAL.
    PERFORM save_long_text_direct USING 'Z003' lt_trans_note.
  ENDIF.

  " Update timestamps
  gs_bug_detail-aenam = sy-uname.
  gs_bug_detail-aedat = sy-datum.
  gs_bug_detail-aezet = sy-uzeit.

  " Update database
  UPDATE zbug_tracker FROM @gs_bug_detail.
  IF sy-subrc = 0.
    COMMIT WORK.

    " Log history
    DATA: lv_old_st TYPE string,
          lv_new_st TYPE string.
    lv_old_st = lv_old_status.
    lv_new_st = gv_trans_new_status.
    PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
    COMMIT WORK.

    " Update snapshot to reflect new status
    gs_bug_snapshot = gs_bug_detail.

    " Trigger auto-assign tester if status → Fixed
    IF gv_trans_new_status = gc_st_fixed.
      PERFORM auto_assign_tester.
    ENDIF.

    MESSAGE |Status changed: { lv_old_status } -> { gv_trans_new_status }| TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    " Revert work area on failure
    gs_bug_detail-status = lv_old_status.
    MESSAGE 'Failed to update bug status.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& AUTO-ASSIGN DEVELOPER (New → Assigned/Waiting)
*&
*& Triggered after save_bug_detail in Create mode.
*& Algorithm:
*& 1. Find Developers in same project + same SAP module + active
*& 2. Count active workload (status IN assigned/inprogress/pending/finaltesting)
*& 3. Filter devs with workload < 5
*& 4. Pick the one with least workload → Assigned
*& 5. If no available dev → Waiting
*&
*& Uses add_history_entry. Uses comma-separated SET in UPDATE.
*& Includes is_active check. Handles empty sap_module gracefully.
*&=====================================================================*
FORM auto_assign_developer.
  " Only trigger for newly created bugs (status = New)
  CHECK gs_bug_detail-status = gc_st_new.

  TYPES: BEGIN OF ty_dev_workload,
           user_id  TYPE zde_username,
           workload TYPE i,
         END OF ty_dev_workload.
  DATA: lt_candidates TYPE TABLE OF ty_dev_workload,
        ls_best       TYPE ty_dev_workload,
        lv_assign_msg TYPE string.

  " 1. Get Developers in same project + same module + active + not deleted
  SELECT u~user_id
    FROM zbug_user_projec AS u
    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
    WHERE u~project_id = @gs_bug_detail-project_id
      AND u~role = 'D'
      AND usr~is_del <> 'X'
      AND usr~is_active = 'X'
      AND ( @gs_bug_detail-sap_module IS INITIAL
            OR usr~sap_module = @gs_bug_detail-sap_module )
    INTO TABLE @DATA(lt_devs).

  IF lt_devs IS INITIAL.
    " No available Dev → set to Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'No developer available'.
    COMMIT WORK.
    MESSAGE 'No available developer. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 2. Calculate workload for each Dev
  LOOP AT lt_devs INTO DATA(ls_dev).
    DATA: ls_cand TYPE ty_dev_workload.
    ls_cand-user_id = ls_dev-user_id.
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
    " All Devs overloaded (workload >= 5) → Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'All developers overloaded'.
    COMMIT WORK.
    MESSAGE 'All developers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 3. Pick Dev with lowest workload
  SORT lt_candidates BY workload ASCENDING.
  READ TABLE lt_candidates INTO ls_best INDEX 1.

  " 4. Assign developer + update status to Assigned
  gs_bug_detail-dev_id = ls_best-user_id.
  gs_bug_detail-status = gc_st_assigned.
  UPDATE zbug_tracker
    SET dev_id = @ls_best-user_id,
        status = @gc_st_assigned
    WHERE bug_id = @gs_bug_detail-bug_id.
  COMMIT WORK.
  lv_assign_msg = |Auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })|.
  PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_assigned
    lv_assign_msg.
  COMMIT WORK.

  " Update snapshot
  gs_bug_snapshot = gs_bug_detail.

  MESSAGE |Bug auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })| TYPE 'S'.
ENDFORM.

*&=====================================================================*
*& AUTO-ASSIGN TESTER (Fixed → Final Testing/Waiting)
*&
*& Triggered from apply_status_transition when status → Fixed.
*& Algorithm:
*& 1. Find Testers in same project + same SAP module + active
*& 2. Count active workload (verify_tester_id with status = FinalTesting)
*& 3. Filter testers with workload < 5
*& 4. Pick the one with least workload → Final Testing
*& 5. If no available tester → Waiting
*&
*& Uses add_history_entry. Uses comma-separated SET in UPDATE.
*&=====================================================================*
FORM auto_assign_tester.
  " Only trigger when status = Fixed
  CHECK gs_bug_detail-status = gc_st_fixed.

  TYPES: BEGIN OF ty_tst_workload,
           user_id  TYPE zde_username,
           workload TYPE i,
         END OF ty_tst_workload.
  DATA: lt_candidates TYPE TABLE OF ty_tst_workload,
        ls_best       TYPE ty_tst_workload,
        lv_assign_msg TYPE string.

  " 1. Get Testers in same project + same module + active + not deleted
  SELECT u~user_id
    FROM zbug_user_projec AS u
    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
    WHERE u~project_id = @gs_bug_detail-project_id
      AND u~role = 'T'
      AND usr~is_del <> 'X'
      AND usr~is_active = 'X'
      AND ( @gs_bug_detail-sap_module IS INITIAL
            OR usr~sap_module = @gs_bug_detail-sap_module )
    INTO TABLE @DATA(lt_testers).

  IF lt_testers IS INITIAL.
    " No available Tester → Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_waiting 'No tester available'.
    COMMIT WORK.
    " Update snapshot
    gs_bug_snapshot = gs_bug_detail.
    MESSAGE 'No available tester. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 2. Calculate workload for each Tester
  LOOP AT lt_testers INTO DATA(ls_tst).
    DATA: ls_cand TYPE ty_tst_workload.
    ls_cand-user_id = ls_tst-user_id.
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
    " All Testers overloaded → Waiting
    gs_bug_detail-status = gc_st_waiting.
    UPDATE zbug_tracker SET status = @gc_st_waiting
      WHERE bug_id = @gs_bug_detail-bug_id.
    COMMIT WORK.
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_waiting 'All testers overloaded'.
    COMMIT WORK.
    gs_bug_snapshot = gs_bug_detail.
    MESSAGE 'All testers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  " 3. Pick Tester with lowest workload
  SORT lt_candidates BY workload ASCENDING.
  READ TABLE lt_candidates INTO ls_best INDEX 1.

  " 4. Assign tester + update status to Final Testing
  gs_bug_detail-verify_tester_id = ls_best-user_id.
  gs_bug_detail-status = gc_st_finaltesting.
  UPDATE zbug_tracker
    SET verify_tester_id = @ls_best-user_id,
        status = @gc_st_finaltesting
    WHERE bug_id = @gs_bug_detail-bug_id.
  COMMIT WORK.
  lv_assign_msg = |Auto-assigned to tester { ls_best-user_id } (workload: { ls_best-workload })|.
  PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_finaltesting
    lv_assign_msg.
  COMMIT WORK.

  " Update snapshot
  gs_bug_snapshot = gs_bug_detail.

  MESSAGE |Bug auto-assigned to tester { ls_best-user_id } for Final Testing| TYPE 'S'.
ENDFORM.

*&=====================================================================*
*& EXECUTE BUG SEARCH (Screen 0210 → results in gt_search_results)
*&
*& Search filters: s_bug_id, s_title, s_status, s_prio, s_mod,
*&                 s_reporter, s_dev
*& Security: scoped to current project (gv_current_project_id).
*& Results in gt_search_results (ty_bug_alv) with text mapping.
*&
*& NOTE: Title wildcard uses CP operator in a LOOP (not in SQL —
*& CP not valid in Open SQL). Pattern: *term* for CP matching.
*& Sets gv_search_executed = abap_true so PAI navigates to 0220
*& after the modal dialog closes.
*&=====================================================================*
FORM execute_bug_search.
  CLEAR gt_search_results.

  " Build title pattern for CP operator: surround with *
  DATA: lv_title_pattern TYPE string.
  IF s_title IS NOT INITIAL.
    lv_title_pattern = '*' && s_title && '*'.
    TRANSLATE lv_title_pattern TO UPPER CASE.
  ENDIF.

  " SELECT into gt_search_results (ty_bug_alv via CORRESPONDING FIELDS)
  SELECT * FROM zbug_tracker
    WHERE is_del <> 'X'
      AND project_id = @gv_current_project_id
      AND ( @s_bug_id   IS INITIAL OR bug_id    = @s_bug_id )
      AND ( @s_status   IS INITIAL OR status    = @s_status )
      AND ( @s_prio     IS INITIAL OR priority  = @s_prio )
      AND ( @s_mod      IS INITIAL OR sap_module = @s_mod )
      AND ( @s_reporter IS INITIAL OR tester_id = @s_reporter )
      AND ( @s_dev      IS INITIAL OR dev_id    = @s_dev )
    INTO CORRESPONDING FIELDS OF TABLE @gt_search_results.

  " Title wildcard filter (post-SELECT — CP operator not valid in SQL)
  IF lv_title_pattern IS NOT INITIAL.
    DATA: lt_keep TYPE TABLE OF ty_bug_alv.
    LOOP AT gt_search_results ASSIGNING FIELD-SYMBOL(<sr>).
      DATA: lv_title_upper TYPE string.
      lv_title_upper = <sr>-title.
      TRANSLATE lv_title_upper TO UPPER CASE.
      IF lv_title_upper CP lv_title_pattern.
        APPEND <sr> TO lt_keep.
      ENDIF.
    ENDLOOP.
    gt_search_results = lt_keep.
  ENDIF.

  " Text mapping loop (same as select_bug_data)
  LOOP AT gt_search_results ASSIGNING FIELD-SYMBOL(<bug>).
    <bug>-status_text = SWITCH #( <bug>-status
      WHEN gc_st_new          THEN 'New'
      WHEN gc_st_assigned     THEN 'Assigned'
      WHEN gc_st_inprogress   THEN 'In Progress'
      WHEN gc_st_pending      THEN 'Pending'
      WHEN gc_st_fixed        THEN 'Fixed'
      WHEN gc_st_finaltesting THEN 'Final Testing'
      WHEN gc_st_closed       THEN 'Closed'
      WHEN gc_st_waiting      THEN 'Waiting'
      WHEN gc_st_rejected     THEN 'Rejected'
      WHEN gc_st_resolved     THEN 'Resolved'
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

  IF gt_search_results IS INITIAL.
    MESSAGE 'No bugs found matching criteria.' TYPE 'S' DISPLAY LIKE 'W'.
  ELSE.
    MESSAGE |Found { lines( gt_search_results ) } bug(s).| TYPE 'S'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*&=====================================================================*
*& MODIFY SCREEN 0370 — PBO helper for field enable/disable
*&
*& Read-only fields: BUG_ID, TITLE, REPORTER, CURRENT_STATUS — always locked
*& NEW_STATUS: always open (F4 will filter by allowed transitions)
*& DEVELOPER_ID: open when current status = New/Waiting/Pending
*& FINAL_TESTER_ID: open when current status = Waiting
*& TRANS_NOTE editor: enabled for Assigned/InProgress/FinalTesting
*&
*& Called from PBO MODULE init_trans_popup.
*&=====================================================================*
FORM modify_screen_0370.
  LOOP AT SCREEN.
    " Read-only fields: always locked
    IF screen-name CS 'GV_TRANS_BUG_ID' OR screen-name CS 'GV_TRANS_TITLE'
       OR screen-name CS 'GV_TRANS_REPORTER' OR screen-name CS 'GV_TRANS_CUR_'.
      screen-input = 0.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " NEW_STATUS: always open (F4 enforces transition matrix)
    IF screen-name CS 'GV_TRANS_NEW_STATUS'.
      screen-input = 1.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " DEVELOPER_ID: enable when Manager needs to assign dev
    IF screen-name CS 'GV_TRANS_DEV_ID'.
      CASE gv_trans_cur_status.
        WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
          screen-input = 1.   " Open
        WHEN OTHERS.
          screen-input = 0.   " Locked
      ENDCASE.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.

    " FINAL_TESTER_ID: enable only when current status = Waiting
    IF screen-name CS 'GV_TRANS_FTESTER_ID'.
      CASE gv_trans_cur_status.
        WHEN gc_st_waiting.
          screen-input = 1.   " Open (Manager can manually assign tester)
        WHEN OTHERS.
          screen-input = 0.   " Locked
      ENDCASE.
      MODIFY SCREEN.
      CONTINUE.
    ENDIF.
  ENDLOOP.

  " Enable/disable TRANS_NOTE text editor based on current status
  IF go_edit_trans_note IS NOT INITIAL.
    CASE gv_trans_cur_status.
      WHEN gc_st_assigned OR gc_st_inprogress OR gc_st_finaltesting.
        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>false ). " Editable
      WHEN OTHERS.
        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>true ).  " Read-only
    ENDCASE.
  ENDIF.
ENDFORM.
