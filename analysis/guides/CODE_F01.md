*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F01 — Main Logic (SQL & Processing)
*&---------------------------------------------------------------------*

*&--- FETCH BUG DATA ---*
FORM select_bug_data.
  CLEAR gt_bugs.
  gv_uname = sy-uname.

  CASE gv_role.
    WHEN 'T'. " Own bugs
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE tester_id = @gv_uname AND is_del <> 'X'.
    WHEN 'D'. " Assigned bugs
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE dev_id = @gv_uname AND is_del <> 'X'.
    WHEN 'M'. " All bugs
      SELECT * FROM zbug_tracker
        INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
        WHERE is_del <> 'X'.
  ENDCASE.

  " Status mapping logic
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    <bug>-status_text = SWITCH #( <bug>-status
      WHEN '1' THEN 'New'        WHEN '5' THEN 'Fixed'
      WHEN '7' THEN 'Closed'     ELSE 'Active' ).
    <bug>-priority_text = SWITCH #( <bug>-priority
      WHEN 'H' THEN 'High' WHEN 'M' THEN 'Medium' WHEN 'L' THEN 'Low' ).
  ENDLOOP.

  PERFORM set_bug_colors.
ENDFORM.

*&--- FETCH PROJECT DATA ---*
FORM select_project_data.
  CLEAR gt_projects.
  gv_uname = sy-uname.

  IF gv_role = 'M'.
    SELECT * FROM zbug_project
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE is_del <> 'X'.
  ELSE.
    " FIX: Thêm dấu phẩy giữa các trường trong SELECT list
    SELECT p~project_id,
           p~project_name,
           p~description,
           p~start_date,
           p~end_date,
           p~project_manager,
           p~project_status
      FROM zbug_project AS p
      INNER JOIN zbug_user_projec AS up ON p~project_id = up~project_id
      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'.
  ENDIF.

  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
    <prj>-status_text = SWITCH #( <prj>-project_status
      WHEN '1' THEN 'Opening'   WHEN '3' THEN 'Done'     ELSE 'Active' ).
  ENDLOOP.
ENDFORM.

*&--- SAVE PROJECT DETAIL (Strict Mode) ---*
FORM save_project_detail.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.

  IF gv_mode = gc_mode_create.
    gs_project-ernam = lv_un.
    gs_project-erdat = sy-datum.
    gs_project-erzet = sy-uzeit.
    gs_project-project_status = '1'.
    INSERT zbug_project FROM @gs_project.
  ELSE.
    gs_project-aenam = lv_un.
    gs_project-aedat = sy-datum.
    gs_project-aezet = sy-uzeit.
    UPDATE zbug_project FROM @gs_project.
  ENDIF.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'Saved successfully' TYPE 'S'.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Save failed' TYPE 'E'.
  ENDIF.
ENDFORM.

*&--- ALV COLORING (Full 9 Status Colors) ---*
FORM set_bug_colors.
  DATA: ls_color TYPE lvc_s_scol.
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
    CLEAR <bug>-t_color.
    ls_color-fname = 'STATUS_TEXT'.
    CASE <bug>-status.
      WHEN '1'. ls_color-color-col = 1. ls_color-color-int = 0.  " Blue — New
      WHEN 'W'. ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow — Waiting
      WHEN '2'. ls_color-color-col = 7. ls_color-color-int = 0.  " Orange — Assigned
      WHEN '3'. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple — InProgress
      WHEN '4'. ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow — Pending
      WHEN '5'. ls_color-color-col = 5. ls_color-color-int = 0.  " Green — Fixed
      WHEN '6'. ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green — Resolved
      WHEN '7'. ls_color-color-col = 1. ls_color-color-int = 1.  " Grey — Closed
      WHEN 'R'. ls_color-color-col = 6. ls_color-color-int = 1.  " Red — Rejected
    ENDCASE.
    APPEND ls_color TO <bug>-t_color.
  ENDLOOP.
ENDFORM.

*&=== C9: BUG SELECTION ===*
FORM get_selected_bug CHANGING pv_bug_id TYPE zde_bug_id.
  CLEAR pv_bug_id.
  DATA: lt_rows TYPE lvc_t_roid.
  go_alv_bug->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL. RETURN. ENDIF.
  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_bugs INTO DATA(ls_bug) INDEX ls_row-row_id.
  IF sy-subrc = 0. pv_bug_id = ls_bug-bug_id. ENDIF.
ENDFORM.

*&=== C9: PROJECT SELECTION ===*
FORM get_selected_project CHANGING pv_proj_id TYPE zde_project_id.
  CLEAR pv_proj_id.
  DATA: lt_rows TYPE lvc_t_roid.
  go_alv_project->get_selected_rows( IMPORTING et_row_no = lt_rows ).
  IF lt_rows IS INITIAL. RETURN. ENDIF.
  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
  READ TABLE gt_projects INTO DATA(ls_prj) INDEX ls_row-row_id.
  IF sy-subrc = 0. pv_proj_id = ls_prj-project_id. ENDIF.
ENDFORM.

*&=== C9: SAVE BUG DETAIL ===*
FORM save_bug_detail.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.

  IF gv_mode = gc_mode_create.
    " Auto-generate Bug ID: tìm MAX rồi +1
    SELECT MAX( bug_id ) FROM zbug_tracker INTO @DATA(lv_max_id).
    DATA(lv_num) = COND i( WHEN lv_max_id IS INITIAL THEN 1
                           ELSE CONV i( lv_max_id+3 ) + 1 ).
    gs_bug_detail-bug_id = |BUG{ lv_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
    gs_bug_detail-ernam  = lv_un.
    gs_bug_detail-erdat  = sy-datum.
    gs_bug_detail-erzet  = sy-uzeit.
    IF gs_bug_detail-status IS INITIAL. gs_bug_detail-status = '1'. ENDIF.
    INSERT zbug_tracker FROM @gs_bug_detail.
    " Add history for creation
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'CR' '' 'New' 'Created'.
  ELSE.
    gs_bug_detail-aenam = lv_un.
    gs_bug_detail-aedat = sy-datum.
    gs_bug_detail-aezet = sy-uzeit.
    UPDATE zbug_tracker FROM @gs_bug_detail.
    " Simple history for update
    PERFORM add_history_entry USING gs_bug_detail-bug_id 'UP' '' '' 'Updated'.
  ENDIF.

  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE |Bug { gs_bug_detail-bug_id } saved| TYPE 'S'.
    gv_current_bug_id = gs_bug_detail-bug_id.
    gv_mode = gc_mode_change.
  ELSE.
    ROLLBACK WORK.
    MESSAGE 'Save failed' TYPE 'E'.
  ENDIF.
ENDFORM.

*&=== C9: DELETE BUG (Soft Delete) ===*
FORM delete_bug.
  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = 'Delete Bug ' && gv_current_bug_id && '?'.
  PERFORM confirm_action USING lv_msg
                         CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_tracker SET is_del = 'X',
                          aenam  = @lv_un,
                          aedat  = @sy-datum,
                          aezet  = @sy-uzeit
    WHERE bug_id = @gv_current_bug_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'Bug deleted successfully' TYPE 'S'.
    PERFORM select_bug_data.
  ENDIF.
ENDFORM.

*&=== C9: DELETE PROJECT (Soft Delete) ===*
FORM delete_project.
  DATA: lv_confirmed TYPE abap_bool,
        lv_msg       TYPE string.
  lv_msg = 'Delete Project ' && gv_current_project_id && '?'.
  PERFORM confirm_action USING lv_msg
                         CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_project SET is_del = 'X',
                          aenam  = @lv_un,
                          aedat  = @sy-datum,
                          aezet  = @sy-uzeit
    WHERE project_id = @gv_current_project_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'Project deleted successfully' TYPE 'S'.
    PERFORM select_project_data.
  ENDIF.
ENDFORM.

*&=== C9: POPUP CONFIRM ===*
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

*&=== C9: CHANGE STATUS ===*
FORM change_bug_status.
  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval.
  ls_field-tabname   = 'ZBUG_TRACKER'.
  ls_field-fieldname = 'STATUS'.
  ls_field-fieldtext = 'Status (1=New 5=Fixed 7=Closed)'.
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
  DATA: lv_un TYPE sy-uname.
  lv_un = sy-uname.
  UPDATE zbug_tracker SET status = @ls_field-value,
                          aenam  = @lv_un,
                          aedat  = @sy-datum,
                          aezet  = @sy-uzeit
    WHERE bug_id = @gv_current_bug_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    " Add history for status change
    PERFORM add_history_entry USING gv_current_bug_id 'ST' gs_bug_detail-status ls_field-value 'Status updated via popup'.
    gs_bug_detail-status = ls_field-value.
    MESSAGE 'Status updated' TYPE 'S'.
  ENDIF.
ENDFORM.

*&=== C9: UNIVERSAL HISTORY LOG ===*
FORM add_history_entry USING pv_bug_id TYPE zde_bug_id
                           pv_type   TYPE char2
                           pv_old
                           pv_new
                           pv_reason.
  DATA: ls_hist TYPE zbug_history.
  ls_hist-bug_id      = pv_bug_id.
  ls_hist-changed_at  = sy-datum.
  ls_hist-changed_time = sy-uzeit.
  ls_hist-changed_by  = sy-uname.
  ls_hist-action_type = pv_type.
  ls_hist-old_value   = pv_old.
  ls_hist-new_value   = pv_new.
  ls_hist-reason      = pv_reason.
  INSERT zbug_history FROM @ls_hist.
ENDFORM.

*&=== C9: PROJECT USER MANAGEMENT ===*
FORM add_user_to_project.
  DATA: lt_fields TYPE TABLE OF sval,
        ls_field  TYPE sval.
  
  ls_field-tabname = 'ZBUG_USER_PROJEC'. ls_field-fieldname = 'USER_ID'.
  APPEND ls_field TO lt_fields.
  ls_field-fieldname = 'ROLE'. ls_field-fieldtext = 'Role (M=Mgr, D=Dev, T=Tst)'.
  APPEND ls_field TO lt_fields.

  DATA: lv_rc TYPE char1.
  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING popup_title = 'Assign User to Project'
    IMPORTING returncode = lv_rc
    TABLES fields = lt_fields.
  CHECK lv_rc <> 'A'.

  DATA: ls_up TYPE zbug_user_projec.
  ls_up-project_id = gv_current_project_id.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'USER_ID'.
  ls_up-user_id = ls_field-value.
  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ROLE'.
  ls_up-role = ls_field-value.

  INSERT zbug_user_projec FROM @ls_up.
  IF sy-subrc = 0.
    COMMIT WORK.
    MESSAGE 'User added to project' TYPE 'S'.
    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
      WHERE project_id = @gv_current_project_id.
  ENDIF.
ENDFORM.

FORM remove_user_from_project.
  " Hardcoded for now: delete all users from project if confirmed
  " In real world, would use ALV selection
  DATA: lv_confirmed TYPE abap_bool.
  PERFORM confirm_action USING 'Remove all users from this project?' CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.

  DELETE FROM zbug_user_projec WHERE project_id = @gv_current_project_id.
  IF sy-subrc = 0.
    COMMIT WORK.
    CLEAR gt_user_project.
    MESSAGE 'All users removed' TYPE 'S'.
  ENDIF.
ENDFORM.

*&=== C9: HISTORY TAB ===*
FORM load_history_data.
  CLEAR gt_history.
  CHECK gv_current_bug_id IS NOT INITIAL.
  SELECT * FROM zbug_history
    INTO CORRESPONDING FIELDS OF TABLE @gt_history
    WHERE bug_id = @gv_current_bug_id
    ORDER BY changed_at DESCENDING, changed_time DESCENDING.

  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<h>).
    <h>-action_text = SWITCH #( <h>-action_type
      WHEN 'CR' THEN 'Created'     WHEN 'ST' THEN 'Status Change'
      WHEN 'UP' THEN 'Updated'     WHEN 'AT' THEN 'Attachment'
      WHEN 'DL' THEN 'Deleted'     WHEN 'RJ' THEN 'Rejected' ).
  ENDLOOP.

  IF go_alv_history IS INITIAL.
    CREATE OBJECT go_cont_history EXPORTING container_name = 'CC_HISTORY'.
    CREATE OBJECT go_alv_history  EXPORTING i_parent = go_cont_history.
    DATA: lt_fcat TYPE lvc_t_fcat, ls_fcat TYPE lvc_s_fcat.
    DEFINE add_hfcat.
      CLEAR ls_fcat.
      ls_fcat-fieldname = &1. ls_fcat-coltext = &2. ls_fcat-outputlen = &3.
      APPEND ls_fcat TO lt_fcat.
    END-OF-DEFINITION.
    add_hfcat 'CHANGED_AT'   'Date'       10.
    add_hfcat 'CHANGED_TIME' 'Time'        8.
    add_hfcat 'CHANGED_BY'   'Changed By' 12.
    add_hfcat 'ACTION_TEXT'  'Action'     15.
    add_hfcat 'OLD_VALUE'    'Old Value'  20.
    add_hfcat 'NEW_VALUE'    'New Value'  20.
    add_hfcat 'REASON'       'Reason'     40.
    DATA: ls_layo TYPE lvc_s_layo.
    ls_layo-zebra = 'X'. ls_layo-cwidth_opt = 'X'.
    go_alv_history->set_table_for_first_display(
      EXPORTING is_layout = ls_layo
      CHANGING it_outtab = gt_history it_fieldcatalog = lt_fcat ).
  ELSE.
    go_alv_history->refresh_table_display( ).
  ENDIF.
ENDFORM.

*&=== STUB: Upload (Phase D) ===*
FORM upload_evidence_file. ENDFORM.

