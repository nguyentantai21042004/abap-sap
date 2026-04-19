*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F01 — Main Business Logic (SQL & Processing)
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
      WHEN 'T'. " Tester: chỉ thấy bugs mình tạo hoặc được assign verify
        SELECT * FROM zbug_tracker
          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
          WHERE ( tester_id = @gv_uname OR verify_tester_id = @gv_uname )
            AND is_del <> 'X'.
      WHEN 'D'. " Developer: chỉ thấy bugs được assign cho mình
        SELECT * FROM zbug_tracker
          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
          WHERE dev_id = @gv_uname AND is_del <> 'X'.
      WHEN 'M'. " Manager: thấy tất cả bugs
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

    " NEW: Severity text
    <bug>-severity_text = SWITCH #( <bug>-severity
      WHEN '1' THEN 'Dump/Critical'
      WHEN '2' THEN 'Very High'
      WHEN '3' THEN 'High'
      WHEN '4' THEN 'Normal'
      WHEN '5' THEN 'Minor' ).

    " NEW: Bug Type text
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
    " Manager thấy tất cả projects
    SELECT * FROM zbug_project
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE is_del <> 'X'.
  ELSE.
    " Tester/Dev chỉ thấy projects được assign
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
    " Set current bug id BEFORE saving long texts (save_long_text checks this)
    gv_current_bug_id = gs_bug_detail-bug_id.
    " Save long text tabs (SAVE_TEXT performs its own COMMIT internally)
    PERFORM save_long_text USING 'Z001'.  " Description
    PERFORM save_long_text USING 'Z002'.  " Dev Note
    PERFORM save_long_text USING 'Z003'.  " Tester Note
    MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
    gv_mode = gc_mode_change.
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
  go_desc_mini_edit->get_text_as_r3table( IMPORTING table = lt_mini ).
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

  " Validate required fields
  IF gs_project-project_id IS INITIAL.
    MESSAGE 'Project ID is required.' TYPE 'E'. RETURN.
  ENDIF.
  IF gs_project-project_name IS INITIAL.
    MESSAGE 'Project Name is required.' TYPE 'E'. RETURN.
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
      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue — New
      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow — Waiting
      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange — Assigned
      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple — In Progress
      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow — Pending
      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green — Fixed
      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green — Resolved
      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey — Closed
      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red — Rejected
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
  " Note: intentionally no COMMIT here — caller handles commit
ENDFORM.

*&=== PROJECT USER MANAGEMENT: ADD ===*
FORM add_user_to_project.
  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval.

  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
  ls_field-fieldname = 'USER_ID'.
  ls_field-fieldtext = 'SAP Username (USER_ID)'.
  APPEND ls_field TO lt_fields.

  CLEAR ls_field.
  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
  ls_field-fieldname = 'ROLE'.
  ls_field-fieldtext = 'Role: M=Manager D=Dev T=Tester'.
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
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ROLE'.
  lv_role = ls_field-value.

  IF lv_uid IS INITIAL.
    MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
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
  " Xóa user đang được highlight trong table control
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

*&=== LOAD HISTORY TAB ===*
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

*&=== STUBS (Phase D) ===*
FORM upload_evidence_file.
  " TODO Phase D: GOS attachment upload
  MESSAGE 'File upload not yet implemented (Phase D).' TYPE 'I'.
ENDFORM.

FORM download_project_template.
  " TODO Phase D: Download Excel template from SMW0
  MESSAGE 'Template download not yet implemented (Phase D).' TYPE 'I'.
ENDFORM.

FORM upload_project_excel.
  " TODO Phase D: Upload Excel via TEXT_CONVERT_XLS_TO_SAP
  MESSAGE 'Excel upload not yet implemented (Phase D).' TYPE 'I'.
ENDFORM.
