# Analysis v1

### CODE_F00.md — added

`+163 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes
+*&---------------------------------------------------------------------*
+
+CLASS lcl_event_handler DEFINITION.
+  PUBLIC SECTION.
+    METHODS:
+      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
+        IMPORTING e_row_id e_column_id,
+      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
+        IMPORTING e_object e_interactive,
+      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
+        IMPORTING e_ucomm.
+ENDCLASS.
+
+CLASS lcl_event_handler IMPLEMENTATION.
+  METHOD handle_hotspot_click.
+    " Bug List: click Bug ID → mở Bug Detail (Display mode)
+    IF e_column_id-fieldname = 'BUG_ID'.
+      READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
+      IF sy-subrc = 0.
+        gv_current_bug_id   = ls_bug-bug_id.
+        gv_mode             = gc_mode_display.
+        gv_active_subscreen = '0310'.
+        CALL SCREEN 0300.
+      ENDIF.
+    ENDIF.
+
+    " ----- PROJECT LIST: click Project ID → Bug List (project context) -----
+    " NEW FLOW: Hotspot trên Project ALV → mở Bug List filtered by project
+    "           (thay vì mở Project Detail như trước)
+    IF e_column_id-fieldname = 'PROJECT_ID'.
+      " Check if we are on Project List (ALV source = go_alv_project)
+      " vs Bug List (ALV source = go_alv_bug)
+      " Distinguish by checking which table the row belongs to
+      READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
+      IF sy-subrc = 0.
+        " From Project List → open Bug List with project filter
+        gv_current_project_id = ls_prj-project_id.
+        gv_bug_filter_mode    = 'P'.  " Project mode — show ALL bugs of this project
+        CALL SCREEN 0200.
+      ELSE.
+        " From Bug List → open Project Detail (display mode)
+        " (PROJECT_ID hotspot on Bug ALV still opens Project Detail)
+        READ TABLE gt_bugs INTO DATA(ls_bug2) INDEX e_row_id-index.
+        IF sy-subrc = 0 AND ls_bug2-project_id IS NOT INITIAL.
+          gv_current_project_id = ls_bug2-project_id.
+          gv_mode               = gc_mode_display.
+          CALL SCREEN 0500.
+        ENDIF.
+      ENDIF.
+    ENDIF.
+  ENDMETHOD.
+
+  METHOD handle_toolbar.
+  ENDMETHOD.
+
+  METHOD handle_user_command.
+  ENDMETHOD.
+ENDCLASS.
+
+*&--- BUG LIST FIELD CATALOG ---*
+FORM build_bug_fieldcat.
+  DATA: ls_fcat TYPE lvc_s_fcat.
+  CLEAR gt_fcat_bug.
+
+  DEFINE add_fcat.
+    CLEAR ls_fcat.
+    ls_fcat-tabname   = 'GT_BUGS'.
+    ls_fcat-fieldname = &1.
+    ls_fcat-coltext   = &2.
+    ls_fcat-outputlen = &3.
+    APPEND ls_fcat TO gt_fcat_bug.
+  END-OF-DEFINITION.
+
+  add_fcat 'BUG_ID'           'Bug ID'          12.
+  add_fcat 'TITLE'            'Title'           40.
+  add_fcat 'PROJECT_ID'       'Project'         15.
+  add_fcat 'STATUS_TEXT'      'Status'          15.
+  add_fcat 'PRIORITY_TEXT'    'Priority'        10.
+  add_fcat 'SEVERITY_TEXT'    'Severity'        15.   " NEW — text instead of raw code
+  add_fcat 'BUG_TYPE_TEXT'    'Type'            18.   " NEW — text instead of raw code
+  add_fcat 'SAP_MODULE'       'Module'          12.
+  add_fcat 'TESTER_ID'        'Tester'          12.
+  add_fcat 'VERIFY_TESTER_ID' 'Verify Tester'   12.
+  add_fcat 'DEV_ID'           'Developer'       12.
+  add_fcat 'CREATED_AT'       'Created'         10.
+
+  " Hotspot trên BUG_ID
+  READ TABLE gt_fcat_bug ASSIGNING FIELD-SYMBOL(<fc>)
+    WITH KEY fieldname = 'BUG_ID'.
+  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
+
+  " Hotspot trên PROJECT_ID (click → Project Detail from Bug List)
+  READ TABLE gt_fcat_bug ASSIGNING <fc>
+    WITH KEY fieldname = 'PROJECT_ID'.
+  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
+
+  " Ẩn raw code columns (hiển thị _TEXT thay thế)
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
+  ls_fcat-fieldname = 'STATUS'.   ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
+  ls_fcat-fieldname = 'PRIORITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
+  ls_fcat-fieldname = 'SEVERITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
+  ls_fcat-fieldname = 'BUG_TYPE'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
+ENDFORM.
+
+*&--- PROJECT LIST FIELD CATALOG ---*
+FORM build_pro_fieldcat.
+  DATA: ls_fcat TYPE lvc_s_fcat.
+  CLEAR gt_fcat_project.
+
+  DEFINE add_fcat_p.
+    CLEAR ls_fcat.
+    ls_fcat-tabname   = 'GT_PROJECTS'.
+    ls_fcat-fieldname = &1.
+    ls_fcat-coltext   = &2.
+    ls_fcat-outputlen = &3.
+    APPEND ls_fcat TO gt_fcat_project.
+  END-OF-DEFINITION.
+
+  add_fcat_p 'PROJECT_ID'      'Project ID'     20.
+  add_fcat_p 'PROJECT_NAME'    'Project Name'   40.
+  add_fcat_p 'STATUS_TEXT'     'Status'         12.
+  add_fcat_p 'START_DATE'      'Start Date'     10.
+  add_fcat_p 'END_DATE'        'End Date'       10.
+  add_fcat_p 'PROJECT_MANAGER' 'Manager'        12.
+  add_fcat_p 'NOTE'            'Note'           30.
+
+  " Hotspot trên PROJECT_ID — click → Bug List (project filter)
+  READ TABLE gt_fcat_project ASSIGNING FIELD-SYMBOL(<fc>)
+    WITH KEY fieldname = 'PROJECT_ID'.
+  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
+
+  " Ẩn raw status code
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_PROJECTS'.
+  ls_fcat-fieldname = 'PROJECT_STATUS'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_project.
+ENDFORM.
+
+*&--- HISTORY FIELD CATALOG ---*
+FORM build_history_fieldcat CHANGING pt_fcat TYPE lvc_t_fcat.
+  DATA: ls_fcat TYPE lvc_s_fcat.
+  CLEAR pt_fcat.
+
+  DEFINE add_hfcat.
+    CLEAR ls_fcat.
+    ls_fcat-tabname   = 'GT_HISTORY'.
+    ls_fcat-fieldname = &1.
+    ls_fcat-coltext   = &2.
+    ls_fcat-outputlen = &3.
+    APPEND ls_fcat TO pt_fcat.
+  END-OF-DEFINITION.
+
+  add_hfcat 'CHANGED_AT'   'Date'        10.
+  add_hfcat 'CHANGED_TIME' 'Time'         8.
+  add_hfcat 'CHANGED_BY'   'Changed By'  12.
+  add_hfcat 'ACTION_TEXT'  'Action'      15.
+  add_hfcat 'OLD_VALUE'    'Old Value'   30.
+  add_hfcat 'NEW_VALUE'    'New Value'   30.
+  add_hfcat 'REASON'       'Reason'      40.
+ENDFORM.
```

### CODE_F01.md — added

`+629 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_F01 — Main Business Logic (SQL & Processing)
+*&---------------------------------------------------------------------*
+
+*&=== SELECT BUG DATA (dual mode: Project / My Bugs) ===*
+FORM select_bug_data.
+  CLEAR gt_bugs.
+  gv_uname = sy-uname.
+
+  IF gv_bug_filter_mode = 'P' AND gv_current_project_id IS NOT INITIAL.
+    " ---- PROJECT MODE: ALL bugs of project (no role filter) ----
+    SELECT * FROM zbug_tracker
+      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
+      WHERE project_id = @gv_current_project_id
+        AND is_del <> 'X'.
+  ELSE.
+    " ---- MY BUGS MODE: filter by role (cross-project) ----
+    CASE gv_role.
+      WHEN 'T'. " Tester: chỉ thấy bugs mình tạo hoặc được assign verify
+        SELECT * FROM zbug_tracker
+          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
+          WHERE ( tester_id = @gv_uname OR verify_tester_id = @gv_uname )
+            AND is_del <> 'X'.
+      WHEN 'D'. " Developer: chỉ thấy bugs được assign cho mình
+        SELECT * FROM zbug_tracker
+          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
+          WHERE dev_id = @gv_uname AND is_del <> 'X'.
+      WHEN 'M'. " Manager: thấy tất cả bugs
+        SELECT * FROM zbug_tracker
+          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
+          WHERE is_del <> 'X'.
+    ENDCASE.
+  ENDIF.
+
+  " Status text mapping (9 states)
+  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
+    <bug>-status_text = SWITCH #( <bug>-status
+      WHEN gc_st_new        THEN 'New'
+      WHEN gc_st_assigned   THEN 'Assigned'
+      WHEN gc_st_inprogress THEN 'In Progress'
+      WHEN gc_st_pending    THEN 'Pending'
+      WHEN gc_st_fixed      THEN 'Fixed'
+      WHEN gc_st_resolved   THEN 'Resolved'
+      WHEN gc_st_closed     THEN 'Closed'
+      WHEN gc_st_waiting    THEN 'Waiting'
+      WHEN gc_st_rejected   THEN 'Rejected'
+      ELSE <bug>-status ).
+
+    <bug>-priority_text = SWITCH #( <bug>-priority
+      WHEN 'H' THEN 'High'
+      WHEN 'M' THEN 'Medium'
+      WHEN 'L' THEN 'Low' ).
+
+    " NEW: Severity text
+    <bug>-severity_text = SWITCH #( <bug>-severity
+      WHEN '1' THEN 'Dump/Critical'
+      WHEN '2' THEN 'Very High'
+      WHEN '3' THEN 'High'
+      WHEN '4' THEN 'Normal'
+      WHEN '5' THEN 'Minor' ).
+
+    " NEW: Bug Type text
+    <bug>-bug_type_text = SWITCH #( <bug>-bug_type
+      WHEN '1' THEN 'Functional'
+      WHEN '2' THEN 'Performance'
+      WHEN '3' THEN 'UI/UX'
+      WHEN '4' THEN 'Integration'
+      WHEN '5' THEN 'Security' ).
+  ENDLOOP.
+
+  PERFORM set_bug_colors.
+ENDFORM.
+
+*&=== SELECT PROJECT DATA ===*
+FORM select_project_data.
+  CLEAR gt_projects.
+  gv_uname = sy-uname.
+
+  IF gv_role = 'M'.
+    " Manager thấy tất cả projects
+    SELECT * FROM zbug_project
+      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
+      WHERE is_del <> 'X'.
+  ELSE.
+    " Tester/Dev chỉ thấy projects được assign
+    SELECT p~project_id,
+           p~project_name,
+           p~project_status,
+           p~start_date,
+           p~end_date,
+           p~project_manager,
+           p~note
+      FROM zbug_project AS p
+      INNER JOIN zbug_user_projec AS up ON p~project_id = up~project_id
+      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
+      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'.
+  ENDIF.
+
+  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
+    <prj>-status_text = SWITCH #( <prj>-project_status
+      WHEN '1' THEN 'Opening'
+      WHEN '2' THEN 'In Process'
+      WHEN '3' THEN 'Done'
+      WHEN '4' THEN 'Cancelled' ).
+  ENDLOOP.
+ENDFORM.
+
+*&=== SAVE BUG DETAIL ===*
+FORM save_bug_detail.
+  DATA: lv_un TYPE sy-uname.
+  lv_un = sy-uname.
+
+  " Validate PROJECT_ID is set
+  IF gs_bug_detail-project_id IS INITIAL.
+    MESSAGE 'Project ID is required. Bug must belong to a project.' TYPE 'E'.
+    RETURN.
+  ENDIF.
+
+  " Validate TITLE is set
+  IF gs_bug_detail-title IS INITIAL.
+    MESSAGE 'Title is required.' TYPE 'E'.
+    RETURN.
+  ENDIF.
+
+  IF gv_mode = gc_mode_create.
+    " Auto-generate Bug ID: BUG + 7-digit number
+    DATA: lv_max_id TYPE zde_bug_id,
+          lv_num    TYPE i.
+    SELECT MAX( bug_id ) FROM zbug_tracker INTO @lv_max_id.
+    IF lv_max_id IS INITIAL.
+      lv_num = 1.
+    ELSE.
+      " BUG_ID format: BUG0000001 (3 prefix + 7 digits)
+      DATA: lv_num_str TYPE char7.
+      lv_num_str = lv_max_id+3(7).
+      lv_num = CONV i( lv_num_str ) + 1.
+    ENDIF.
+    gs_bug_detail-bug_id  = |BUG{ lv_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
+    gs_bug_detail-ernam   = lv_un.
+    gs_bug_detail-erdat   = sy-datum.
+    gs_bug_detail-erzet   = sy-uzeit.
+    IF gs_bug_detail-status IS INITIAL.
+      gs_bug_detail-status = gc_st_new.
+    ENDIF.
+    IF gs_bug_detail-tester_id IS INITIAL.
+      gs_bug_detail-tester_id = lv_un.
+    ENDIF.
+    INSERT zbug_tracker FROM @gs_bug_detail.
+    IF sy-subrc = 0.
+      PERFORM add_history_entry USING gs_bug_detail-bug_id 'CR' '' 'New' 'Bug created'.
+    ENDIF.
+  ELSE.
+    " Update existing bug
+    gs_bug_detail-aenam = lv_un.
+    gs_bug_detail-aedat = sy-datum.
+    gs_bug_detail-aezet = sy-uzeit.
+    UPDATE zbug_tracker FROM @gs_bug_detail.
+    IF sy-subrc = 0.
+      PERFORM add_history_entry USING gs_bug_detail-bug_id 'UP' '' '' 'Bug updated'.
+    ENDIF.
+  ENDIF.
+
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    " Set current bug id BEFORE saving long texts (save_long_text checks this)
+    gv_current_bug_id = gs_bug_detail-bug_id.
+    " Save long text tabs (SAVE_TEXT performs its own COMMIT internally)
+    PERFORM save_long_text USING 'Z001'.  " Description
+    PERFORM save_long_text USING 'Z002'.  " Dev Note
+    PERFORM save_long_text USING 'Z003'.  " Tester Note
+    MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
+    gv_mode = gc_mode_change.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Save failed. Please check required fields.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== SAVE DESCRIPTION MINI EDITOR → WORK AREA ===*
+" Called before save_bug_detail — reads mini editor text into gs_bug_detail-desc_text
+FORM save_desc_mini_to_workarea.
+  CHECK go_desc_mini_edit IS NOT INITIAL.
+  DATA: lt_mini TYPE TABLE OF char255,
+        lv_text TYPE string.
+  go_desc_mini_edit->get_text_as_r3table( IMPORTING table = lt_mini ).
+  CLEAR lv_text.
+  LOOP AT lt_mini INTO DATA(lv_line).
+    IF lv_text IS NOT INITIAL.
+      lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line.
+    ELSE.
+      lv_text = lv_line.
+    ENDIF.
+  ENDLOOP.
+  gs_bug_detail-desc_text = lv_text.
+ENDFORM.
+
+*&=== SAVE PROJECT DETAIL ===*
+FORM save_project_detail.
+  DATA: lv_un TYPE sy-uname.
+  lv_un = sy-uname.
+
+  " Validate required fields
+  IF gs_project-project_id IS INITIAL.
+    MESSAGE 'Project ID is required.' TYPE 'E'. RETURN.
+  ENDIF.
+  IF gs_project-project_name IS INITIAL.
+    MESSAGE 'Project Name is required.' TYPE 'E'. RETURN.
+  ENDIF.
+
+  IF gv_mode = gc_mode_create.
+    gs_project-ernam          = lv_un.
+    gs_project-erdat          = sy-datum.
+    gs_project-erzet          = sy-uzeit.
+    IF gs_project-project_status IS INITIAL.
+      gs_project-project_status = '1'.
+    ENDIF.
+    INSERT zbug_project FROM @gs_project.
+  ELSE.
+    gs_project-aenam = lv_un.
+    gs_project-aedat = sy-datum.
+    gs_project-aezet = sy-uzeit.
+    UPDATE zbug_project FROM @gs_project.
+  ENDIF.
+
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    MESSAGE |Project { gs_project-project_id } saved successfully.| TYPE 'S'.
+    gv_current_project_id = gs_project-project_id.
+    gv_mode = gc_mode_change.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== ALV ROW COLORING ===*
+FORM set_bug_colors.
+  DATA: ls_color TYPE lvc_s_scol.
+  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
+    CLEAR <bug>-t_color.
+    ls_color-fname = 'STATUS_TEXT'.
+    CASE <bug>-status.
+      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue — New
+      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow — Waiting
+      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange — Assigned
+      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple — In Progress
+      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow — Pending
+      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green — Fixed
+      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green — Resolved
+      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey — Closed
+      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red — Rejected
+    ENDCASE.
+    APPEND ls_color TO <bug>-t_color.
+  ENDLOOP.
+ENDFORM.
+
+*&=== GET SELECTED BUG FROM ALV ===*
+FORM get_selected_bug CHANGING pv_bug_id TYPE zde_bug_id.
+  CLEAR pv_bug_id.
+  CHECK go_alv_bug IS NOT INITIAL.
+  DATA: lt_rows TYPE lvc_t_roid.
+  go_alv_bug->get_selected_rows( IMPORTING et_row_no = lt_rows ).
+  IF lt_rows IS INITIAL. RETURN. ENDIF.
+  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
+  READ TABLE gt_bugs INTO DATA(ls_bug) INDEX ls_row-row_id.
+  IF sy-subrc = 0. pv_bug_id = ls_bug-bug_id. ENDIF.
+ENDFORM.
+
+*&=== GET SELECTED PROJECT FROM ALV ===*
+FORM get_selected_project CHANGING pv_proj_id TYPE zde_project_id.
+  CLEAR pv_proj_id.
+  CHECK go_alv_project IS NOT INITIAL.
+  DATA: lt_rows TYPE lvc_t_roid.
+  go_alv_project->get_selected_rows( IMPORTING et_row_no = lt_rows ).
+  IF lt_rows IS INITIAL. RETURN. ENDIF.
+  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
+  READ TABLE gt_projects INTO DATA(ls_prj) INDEX ls_row-row_id.
+  IF sy-subrc = 0. pv_proj_id = ls_prj-project_id. ENDIF.
+ENDFORM.
+
+*&=== DELETE BUG (Soft Delete) ===*
+FORM delete_bug.
+  DATA: lv_confirmed TYPE abap_bool,
+        lv_msg       TYPE string.
+  lv_msg = |Delete Bug { gv_current_bug_id }?|.
+  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
+  CHECK lv_confirmed = abap_true.
+
+  DATA: lv_un TYPE sy-uname.
+  lv_un = sy-uname.
+  UPDATE zbug_tracker
+    SET is_del = 'X',
+        aenam  = @lv_un,
+        aedat  = @sy-datum,
+        aezet  = @sy-uzeit
+    WHERE bug_id = @gv_current_bug_id.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gv_current_bug_id 'DL' '' '' 'Bug soft-deleted'.
+    MESSAGE |Bug { gv_current_bug_id } deleted.| TYPE 'S'.
+    PERFORM select_bug_data.
+    IF go_alv_bug IS NOT INITIAL.
+      go_alv_bug->refresh_table_display( ).
+    ENDIF.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Delete failed.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== DELETE PROJECT (Soft Delete) ===*
+FORM delete_project.
+  DATA: lv_confirmed TYPE abap_bool,
+        lv_msg       TYPE string.
+  lv_msg = |Delete Project { gv_current_project_id }?|.
+  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
+  CHECK lv_confirmed = abap_true.
+
+  DATA: lv_un TYPE sy-uname.
+  lv_un = sy-uname.
+  UPDATE zbug_project
+    SET is_del = 'X',
+        aenam  = @lv_un,
+        aedat  = @sy-datum,
+        aezet  = @sy-uzeit
+    WHERE project_id = @gv_current_project_id.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    MESSAGE |Project { gv_current_project_id } deleted.| TYPE 'S'.
+    PERFORM select_project_data.
+    IF go_alv_project IS NOT INITIAL.
+      go_alv_project->refresh_table_display( ).
+    ENDIF.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Delete failed.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== POPUP CONFIRM ===*
+FORM confirm_action USING    pv_text      TYPE string
+                   CHANGING  pv_confirmed TYPE abap_bool.
+  DATA: lv_answer TYPE char1.
+  CALL FUNCTION 'POPUP_TO_CONFIRM'
+    EXPORTING
+      titlebar              = 'Confirm Action'
+      text_question         = pv_text
+      text_button_1         = 'Yes'
+      text_button_2         = 'No'
+      default_button        = '2'
+      display_cancel_button = ' '
+    IMPORTING
+      answer                = lv_answer.
+  pv_confirmed = COND #( WHEN lv_answer = '1' THEN abap_true ELSE abap_false ).
+ENDFORM.
+
+*&=== CHANGE BUG STATUS (with 9-state transition validation) ===*
+FORM change_bug_status.
+  " Build allowed transitions based on current status and role
+  DATA: lt_allowed TYPE TABLE OF zde_bug_status,
+        lv_current TYPE zde_bug_status.
+  lv_current = gs_bug_detail-status.
+
+  CASE gv_role.
+    WHEN 'T'. " Tester
+      CASE lv_current.
+        WHEN gc_st_new.      APPEND gc_st_assigned TO lt_allowed.
+                             APPEND gc_st_waiting  TO lt_allowed.
+        WHEN gc_st_fixed.    APPEND gc_st_resolved TO lt_allowed.
+                             APPEND gc_st_rejected TO lt_allowed.
+        WHEN gc_st_resolved. APPEND gc_st_closed   TO lt_allowed.
+      ENDCASE.
+    WHEN 'D'. " Developer
+      CASE lv_current.
+        WHEN gc_st_assigned.   APPEND gc_st_inprogress TO lt_allowed.
+        WHEN gc_st_inprogress. APPEND gc_st_pending    TO lt_allowed.
+                               APPEND gc_st_fixed      TO lt_allowed.
+                               APPEND gc_st_rejected   TO lt_allowed.
+        WHEN gc_st_pending.    APPEND gc_st_inprogress TO lt_allowed.
+      ENDCASE.
+    WHEN 'M'. " Manager: can set any status
+      APPEND gc_st_new        TO lt_allowed.
+      APPEND gc_st_assigned   TO lt_allowed.
+      APPEND gc_st_inprogress TO lt_allowed.
+      APPEND gc_st_pending    TO lt_allowed.
+      APPEND gc_st_fixed      TO lt_allowed.
+      APPEND gc_st_resolved   TO lt_allowed.
+      APPEND gc_st_closed     TO lt_allowed.
+      APPEND gc_st_waiting    TO lt_allowed.
+      APPEND gc_st_rejected   TO lt_allowed.
+  ENDCASE.
+
+  IF lt_allowed IS INITIAL.
+    MESSAGE |No valid transitions available from current status.| TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  " Use POPUP_GET_VALUES to get new status
+  DATA: lt_fields TYPE TABLE OF sval,
+        ls_field  TYPE sval.
+  ls_field-tabname   = 'ZBUG_TRACKER'.
+  ls_field-fieldname = 'STATUS'.
+  DATA: lv_hint TYPE string.
+  lv_hint = 'Allowed: '.
+  LOOP AT lt_allowed INTO DATA(lv_al).
+    lv_hint = lv_hint && lv_al && ' '.
+  ENDLOOP.
+  ls_field-fieldtext = lv_hint(40).
+  APPEND ls_field TO lt_fields.
+
+  DATA: lv_rc TYPE char1.
+  CALL FUNCTION 'POPUP_GET_VALUES'
+    EXPORTING
+      popup_title  = 'Change Bug Status'
+      start_column = 20
+      start_row    = 5
+    IMPORTING
+      returncode   = lv_rc
+    TABLES
+      fields       = lt_fields.
+  CHECK lv_rc <> 'A'.
+
+  READ TABLE lt_fields INTO ls_field INDEX 1.
+  CHECK ls_field-value IS NOT INITIAL.
+
+  " Validate transition
+  DATA: lv_new_status TYPE zde_bug_status.
+  lv_new_status = ls_field-value.
+  READ TABLE lt_allowed TRANSPORTING NO FIELDS WITH KEY table_line = lv_new_status.
+  IF sy-subrc <> 0 AND gv_role <> 'M'.
+    MESSAGE |Invalid transition: { lv_current } → { lv_new_status }| TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  DATA: lv_un TYPE sy-uname.
+  lv_un = sy-uname.
+  UPDATE zbug_tracker
+    SET status = @lv_new_status,
+        aenam  = @lv_un,
+        aedat  = @sy-datum,
+        aezet  = @sy-uzeit
+    WHERE bug_id = @gv_current_bug_id.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    DATA: lv_old_st TYPE string,
+          lv_new_st TYPE string.
+    lv_old_st = lv_current.
+    lv_new_st = lv_new_status.
+    PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
+    gs_bug_detail-status = lv_new_status.
+    MESSAGE |Status updated: { lv_current } → { lv_new_status }| TYPE 'S'.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Status update failed.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== ADD HISTORY ENTRY (auto-generate LOG_ID) ===*
+FORM add_history_entry USING pv_bug_id  TYPE zde_bug_id
+                             pv_type    TYPE char2
+                             pv_old
+                             pv_new
+                             pv_reason.
+  DATA: ls_hist    TYPE zbug_history,
+        lv_max_id  TYPE numc10,
+        lv_new_id  TYPE numc10.
+
+  " Auto-generate LOG_ID (MAX + 1)
+  SELECT MAX( log_id ) FROM zbug_history INTO @lv_max_id.
+  lv_new_id = lv_max_id + 1.
+
+  ls_hist-log_id       = lv_new_id.
+  ls_hist-bug_id       = pv_bug_id.
+  ls_hist-changed_at   = sy-datum.
+  ls_hist-changed_time = sy-uzeit.
+  ls_hist-changed_by   = sy-uname.
+  ls_hist-action_type  = pv_type.
+  ls_hist-old_value    = pv_old.
+  ls_hist-new_value    = pv_new.
+  ls_hist-reason       = pv_reason.
+  INSERT zbug_history FROM @ls_hist.
+  " Note: intentionally no COMMIT here — caller handles commit
+ENDFORM.
+
+*&=== PROJECT USER MANAGEMENT: ADD ===*
+FORM add_user_to_project.
+  DATA: lt_fields TYPE TABLE OF sval,
+        ls_field  TYPE sval.
+
+  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
+  ls_field-fieldname = 'USER_ID'.
+  ls_field-fieldtext = 'SAP Username (USER_ID)'.
+  APPEND ls_field TO lt_fields.
+
+  CLEAR ls_field.
+  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
+  ls_field-fieldname = 'ROLE'.
+  ls_field-fieldtext = 'Role: M=Manager D=Dev T=Tester'.
+  APPEND ls_field TO lt_fields.
+
+  DATA: lv_rc TYPE char1.
+  CALL FUNCTION 'POPUP_GET_VALUES'
+    EXPORTING popup_title = 'Assign User to Project'
+    IMPORTING returncode  = lv_rc
+    TABLES    fields       = lt_fields.
+  CHECK lv_rc <> 'A'.
+
+  DATA: ls_up    TYPE zbug_user_projec,
+        lv_uid   TYPE zde_username,
+        lv_role  TYPE zde_bug_role.
+  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'USER_ID'.
+  lv_uid  = ls_field-value.
+  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ROLE'.
+  lv_role = ls_field-value.
+
+  IF lv_uid IS INITIAL.
+    MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
+  ENDIF.
+
+  " Validate user exists in ZBUG_USERS
+  SELECT SINGLE user_id FROM zbug_users INTO @DATA(lv_check)
+    WHERE user_id = @lv_uid AND is_del <> 'X'.
+  IF sy-subrc <> 0.
+    MESSAGE |User { lv_uid } not found in system.| TYPE 'W'. RETURN.
+  ENDIF.
+
+  ls_up-project_id = gv_current_project_id.
+  ls_up-user_id    = lv_uid.
+  ls_up-role       = lv_role.
+  ls_up-ernam      = sy-uname.
+  ls_up-erdat      = sy-datum.
+  ls_up-erzet      = sy-uzeit.
+
+  INSERT zbug_user_projec FROM @ls_up.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    MESSAGE |User { lv_uid } added to project { gv_current_project_id }.| TYPE 'S'.
+    " Reload user list
+    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
+      WHERE project_id = @gv_current_project_id.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE |User { lv_uid } is already assigned to this project.| TYPE 'W'.
+  ENDIF.
+ENDFORM.
+
+*&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
+FORM remove_user_from_project.
+  " Xóa user đang được highlight trong table control
+  DATA: lv_line TYPE i.
+  lv_line = tc_users-current_line.
+  IF lv_line = 0.
+    MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
+  ENDIF.
+
+  READ TABLE gt_user_project INTO gs_user_project INDEX lv_line.
+  IF sy-subrc <> 0. RETURN. ENDIF.
+
+  DATA: lv_confirmed TYPE abap_bool,
+        lv_msg       TYPE string.
+  lv_msg = |Remove user { gs_user_project-user_id } from project?|.
+  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
+  CHECK lv_confirmed = abap_true.
+
+  DELETE FROM zbug_user_projec
+    WHERE project_id = @gv_current_project_id
+      AND user_id    = @gs_user_project-user_id.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    DELETE gt_user_project INDEX lv_line.
+    MESSAGE |User { gs_user_project-user_id } removed.| TYPE 'S'.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Remove failed.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=== LOAD HISTORY TAB ===*
+FORM load_history_data.
+  CLEAR gt_history.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+
+  SELECT * FROM zbug_history
+    INTO CORRESPONDING FIELDS OF TABLE @gt_history
+    WHERE bug_id = @gv_current_bug_id
+    ORDER BY changed_at DESCENDING, changed_time DESCENDING.
+
+  LOOP AT gt_history ASSIGNING FIELD-SYMBOL(<h>).
+    <h>-action_text = SWITCH #( <h>-action_type
+      WHEN 'CR' THEN 'Created'
+      WHEN 'UP' THEN 'Updated'
+      WHEN 'ST' THEN 'Status Change'
+      WHEN 'AT' THEN 'Attachment'
+      WHEN 'DL' THEN 'Deleted'
+      WHEN 'RJ' THEN 'Rejected' ).
+  ENDLOOP.
+
+  IF go_alv_history IS INITIAL.
+    CREATE OBJECT go_cont_history EXPORTING container_name = 'CC_HISTORY'.
+    CREATE OBJECT go_alv_history  EXPORTING i_parent = go_cont_history.
+    PERFORM build_history_fieldcat CHANGING gt_fcat_history.
+    DATA: ls_layo TYPE lvc_s_layo.
+    ls_layo-zebra      = 'X'.
+    ls_layo-cwidth_opt = 'X'.
+    ls_layo-no_toolbar = 'X'.  " History is readonly — no toolbar
+    go_alv_history->set_table_for_first_display(
+      EXPORTING is_layout      = ls_layo
+      CHANGING  it_outtab      = gt_history
+                it_fieldcatalog = gt_fcat_history ).
+  ELSE.
+    go_alv_history->refresh_table_display( ).
+  ENDIF.
+ENDFORM.
+
+*&=== STUBS (Phase D) ===*
+FORM upload_evidence_file.
+  " TODO Phase D: GOS attachment upload
+  MESSAGE 'File upload not yet implemented (Phase D).' TYPE 'I'.
+ENDFORM.
+
+FORM download_project_template.
+  " TODO Phase D: Download Excel template from SMW0
+  MESSAGE 'Template download not yet implemented (Phase D).' TYPE 'I'.
+ENDFORM.
+
+FORM upload_project_excel.
+  " TODO Phase D: Upload Excel via TEXT_CONVERT_XLS_TO_SAP
+  MESSAGE 'Excel upload not yet implemented (Phase D).' TYPE 'I'.
+ENDFORM.
```

### CODE_F02.md — added

`+262 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Popup
+*&---------------------------------------------------------------------*
+
+*&=== F4: PROJECT ID ===*
+FORM f4_project_id USING pv_fn TYPE dynfnam.
+  " Hiển thị danh sách projects để chọn
+  TYPES: BEGIN OF ty_prj_f4,
+           project_id   TYPE zde_project_id,
+           project_name TYPE zde_prj_name,
+         END OF ty_prj_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_prj_f4.
+
+  SELECT project_id, project_name FROM zbug_project
+    INTO CORRESPONDING FIELDS OF TABLE @lt_val
+    WHERE is_del <> 'X'
+    ORDER BY project_id.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'PROJECT_ID'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== F4: USER ID ===*
+FORM f4_user_id USING pv_fn TYPE dynfnam.
+  " Hiển thị danh sách users để chọn
+  TYPES: BEGIN OF ty_usr_f4,
+           user_id   TYPE zde_username,
+           full_name TYPE zde_bug_full_name,
+           role      TYPE zde_bug_role,
+         END OF ty_usr_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_usr_f4.
+
+  SELECT user_id, full_name, role FROM zbug_users
+    INTO CORRESPONDING FIELDS OF TABLE @lt_val
+    WHERE is_del <> 'X' AND is_active = 'X'
+    ORDER BY user_id.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'USER_ID'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== F4: BUG STATUS ===*
+FORM f4_status USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_st_f4,
+           code TYPE char2,
+           text TYPE char20,
+         END OF ty_st_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_st_f4.
+
+  APPEND VALUE ty_st_f4( code = '1' text = 'New' )        TO lt_val.
+  APPEND VALUE ty_st_f4( code = '2' text = 'Assigned' )   TO lt_val.
+  APPEND VALUE ty_st_f4( code = '3' text = 'In Progress' ) TO lt_val.
+  APPEND VALUE ty_st_f4( code = '4' text = 'Pending' )    TO lt_val.
+  APPEND VALUE ty_st_f4( code = '5' text = 'Fixed' )      TO lt_val.
+  APPEND VALUE ty_st_f4( code = '6' text = 'Resolved' )   TO lt_val.
+  APPEND VALUE ty_st_f4( code = '7' text = 'Closed' )     TO lt_val.
+  APPEND VALUE ty_st_f4( code = 'W' text = 'Waiting' )    TO lt_val.
+  APPEND VALUE ty_st_f4( code = 'R' text = 'Rejected' )   TO lt_val.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'CODE'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== F4: PRIORITY ===*
+FORM f4_priority USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_prio_f4,
+           code TYPE char1,
+           text TYPE char10,
+         END OF ty_prio_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_prio_f4.
+
+  APPEND VALUE ty_prio_f4( code = 'H' text = 'High' )   TO lt_val.
+  APPEND VALUE ty_prio_f4( code = 'M' text = 'Medium' ) TO lt_val.
+  APPEND VALUE ty_prio_f4( code = 'L' text = 'Low' )    TO lt_val.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'CODE'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== F4: BUG TYPE ===*
+FORM f4_bug_type USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_type_f4,
+           code TYPE char1,
+           text TYPE char20,
+         END OF ty_type_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_type_f4.
+
+  APPEND VALUE ty_type_f4( code = '1' text = 'Functional Bug' )  TO lt_val.
+  APPEND VALUE ty_type_f4( code = '2' text = 'Performance Bug' ) TO lt_val.
+  APPEND VALUE ty_type_f4( code = '3' text = 'UI/UX Bug' )       TO lt_val.
+  APPEND VALUE ty_type_f4( code = '4' text = 'Integration Bug' ) TO lt_val.
+  APPEND VALUE ty_type_f4( code = '5' text = 'Security Bug' )    TO lt_val.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'CODE'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== F4: SEVERITY ===*
+FORM f4_severity USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_sev_f4,
+           code TYPE char1,
+           text TYPE char20,
+         END OF ty_sev_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_sev_f4.
+
+  APPEND VALUE ty_sev_f4( code = '1' text = 'Dump / Critical' ) TO lt_val.
+  APPEND VALUE ty_sev_f4( code = '2' text = 'Very High' )       TO lt_val.
+  APPEND VALUE ty_sev_f4( code = '3' text = 'High' )            TO lt_val.
+  APPEND VALUE ty_sev_f4( code = '4' text = 'Normal' )          TO lt_val.
+  APPEND VALUE ty_sev_f4( code = '5' text = 'Minor' )           TO lt_val.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'CODE'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = pv_fn
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
+" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
+" Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
+FORM load_long_text USING pv_text_id TYPE thead-tdid.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+
+  " Resolve editor reference from text_id
+  DATA: lr_editor TYPE REF TO cl_gui_textedit.
+  CASE pv_text_id.
+    WHEN 'Z001'. lr_editor = go_edit_desc.
+    WHEN 'Z002'. lr_editor = go_edit_dev_note.
+    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
+  ENDCASE.
+  CHECK lr_editor IS NOT INITIAL.
+
+  DATA: lt_lines TYPE TABLE OF tline,
+        ls_line  TYPE tline.
+
+  CALL FUNCTION 'READ_TEXT'
+    EXPORTING
+      id       = pv_text_id
+      language = sy-langu
+      name     = gv_current_bug_id
+      object   = 'ZBUG'
+    TABLES
+      lines    = lt_lines
+    EXCEPTIONS
+      OTHERS   = 4.  " subrc 4 = text not found (OK for new bugs)
+
+  IF sy-subrc = 0.
+    DATA: lt_text TYPE TABLE OF char255.
+    LOOP AT lt_lines INTO ls_line.
+      APPEND CONV char255( ls_line-tdline ) TO lt_text.
+    ENDLOOP.
+    lr_editor->set_text_as_r3table( table = lt_text ).
+  ENDIF.
+ENDFORM.
+
+*&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
+" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
+" Editor is resolved internally. Caller must set gv_current_bug_id before calling.
+FORM save_long_text USING pv_text_id TYPE thead-tdid.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+
+  " Resolve editor reference from text_id
+  DATA: lr_editor TYPE REF TO cl_gui_textedit.
+  CASE pv_text_id.
+    WHEN 'Z001'. lr_editor = go_edit_desc.
+    WHEN 'Z002'. lr_editor = go_edit_dev_note.
+    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
+  ENDCASE.
+  CHECK lr_editor IS NOT INITIAL.
+
+  DATA: lt_text  TYPE TABLE OF char255,
+        lt_lines TYPE TABLE OF tline,
+        ls_line  TYPE tline.
+
+  lr_editor->get_text_as_r3table( IMPORTING table = lt_text ).
+
+  LOOP AT lt_text INTO DATA(lv_line).
+    CLEAR ls_line.
+    ls_line-tdformat = '*'.
+    ls_line-tdline   = lv_line.
+    APPEND ls_line TO lt_lines.
+  ENDLOOP.
+
+  DATA: ls_header TYPE thead.
+  ls_header-tdobject = 'ZBUG'.
+  ls_header-tdname   = gv_current_bug_id.
+  ls_header-tdid     = pv_text_id.
+  ls_header-tdspras  = sy-langu.
+
+  CALL FUNCTION 'SAVE_TEXT'
+    EXPORTING
+      header          = ls_header
+    TABLES
+      lines           = lt_lines
+    EXCEPTIONS
+      OTHERS          = 4.
+  " Note: SAVE_TEXT performs its own internal COMMIT
+ENDFORM.
```

### CODE_PAI.md — added

`+218 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_PAI — User Action Logic
+*&---------------------------------------------------------------------*
+
+*&--- HUB SCREEN 0100 (DEPRECATED — kept for safety) ---*
+MODULE user_command_0100 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
+      LEAVE PROGRAM.
+    WHEN 'BUG_LIST'.
+      gv_bug_filter_mode = 'M'.  " Legacy: My Bugs mode
+      CALL SCREEN 0200.
+    WHEN 'PROJ_LIST'.
+      CALL SCREEN 0400.
+  ENDCASE.
+ENDMODULE.
+
+*&--- BUG LIST SCREEN 0200 ---*
+MODULE user_command_0200 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'CANC'.
+      " Always go back to Project List (initial screen)
+      LEAVE TO SCREEN 0400.
+    WHEN 'EXIT'.
+      LEAVE PROGRAM.
+    WHEN 'CREATE'.
+      " Only available in Project mode (gv_bug_filter_mode = 'P')
+      " Button is hidden in My Bugs mode via PBO, but double-check here
+      IF gv_bug_filter_mode = 'M'.
+        MESSAGE 'Cannot create bug without project context. Go to a project first.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      IF gv_role = 'D'.
+        MESSAGE 'Developers cannot create bugs.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      CLEAR: gv_current_bug_id, gs_bug_detail.
+      gv_mode = gc_mode_create.
+      gv_active_subscreen = '0310'.
+      " gv_current_project_id is already set from project context
+      CALL SCREEN 0300.
+    WHEN 'CHANGE'.
+      PERFORM get_selected_bug CHANGING gv_current_bug_id.
+      IF gv_current_bug_id IS INITIAL.
+        MESSAGE 'Please select a bug first.' TYPE 'W'.
+      ELSE.
+        gv_mode = gc_mode_change.
+        gv_active_subscreen = '0310'.
+        CALL SCREEN 0300.
+      ENDIF.
+    WHEN 'DISPLAY'.
+      PERFORM get_selected_bug CHANGING gv_current_bug_id.
+      IF gv_current_bug_id IS INITIAL.
+        MESSAGE 'Please select a bug first.' TYPE 'W'.
+      ELSE.
+        gv_mode = gc_mode_display.
+        gv_active_subscreen = '0310'.
+        CALL SCREEN 0300.
+      ENDIF.
+    WHEN 'DELETE'.
+      IF gv_role = 'D'.
+        MESSAGE 'Developers cannot delete bugs.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      PERFORM get_selected_bug CHANGING gv_current_bug_id.
+      IF gv_current_bug_id IS NOT INITIAL.
+        PERFORM delete_bug.
+      ELSE.
+        MESSAGE 'Please select a bug to delete.' TYPE 'W'.
+      ENDIF.
+    WHEN 'REFRESH'.
+      PERFORM select_bug_data.
+      IF go_alv_bug IS NOT INITIAL.
+        go_alv_bug->refresh_table_display( ).
+      ENDIF.
+  ENDCASE.
+ENDMODULE.
+
+*&--- BUG DETAIL SCREEN 0300 ---*
+MODULE user_command_0300 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'CANC'.
+      LEAVE TO SCREEN 0200.
+    WHEN 'EXIT'.
+      LEAVE PROGRAM.
+    WHEN 'SAVE'.
+      IF gv_mode = gc_mode_display.
+        MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      " Save description mini editor content to gs_bug_detail-desc_text
+      PERFORM save_desc_mini_to_workarea.
+      PERFORM save_bug_detail.
+    WHEN 'STATUS_CHG'.
+      IF gv_mode = gc_mode_create.
+        MESSAGE 'Save the bug first before changing status.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      PERFORM change_bug_status.
+    WHEN 'UP_FILE'.
+      PERFORM upload_evidence_file.
+    " ---- Tab switching ----
+    WHEN 'TAB_INFO'.
+      gv_active_subscreen = '0310'.
+    WHEN 'TAB_DESC'.
+      gv_active_subscreen = '0320'.
+      PERFORM load_long_text USING 'Z001'.
+    WHEN 'TAB_DEVNOTE'.
+      gv_active_subscreen = '0330'.
+      PERFORM load_long_text USING 'Z002'.
+    WHEN 'TAB_TSTR_NOTE'.
+      gv_active_subscreen = '0340'.
+      PERFORM load_long_text USING 'Z003'.
+    WHEN 'TAB_EVIDENCE'.
+      gv_active_subscreen = '0350'.
+    WHEN 'TAB_HISTORY'.
+      gv_active_subscreen = '0360'.
+      PERFORM load_history_data.
+  ENDCASE.
+ENDMODULE.
+
+*&--- PROJECT LIST SCREEN 0400 (INITIAL SCREEN) ---*
+MODULE user_command_0400 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'CANC'.
+      " This is the initial screen — Back = exit program
+      LEAVE PROGRAM.
+    WHEN 'EXIT'.
+      LEAVE PROGRAM.
+    WHEN 'MY_BUGS'.
+      " NEW: My Bugs — show cross-project bugs filtered by role
+      CLEAR gv_current_project_id.
+      gv_bug_filter_mode = 'M'.
+      " Destroy existing Bug ALV to force rebuild with new data
+      IF go_alv_bug IS NOT INITIAL.
+        go_alv_bug->free( ).
+        FREE go_alv_bug.
+        go_cont_bug->free( ).
+        FREE go_cont_bug.
+        CLEAR: go_alv_bug, go_cont_bug.
+      ENDIF.
+      CALL SCREEN 0200.
+    WHEN 'CREA_PRJ'.
+      IF gv_role <> 'M'.
+        MESSAGE 'Only managers can create projects.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      CLEAR: gv_current_project_id, gs_project, gt_user_project.
+      gv_mode = gc_mode_create.
+      CALL SCREEN 0500.
+    WHEN 'CHNG_PRJ'.
+      PERFORM get_selected_project CHANGING gv_current_project_id.
+      IF gv_current_project_id IS INITIAL.
+        MESSAGE 'Please select a project first.' TYPE 'W'.
+      ELSE.
+        gv_mode = gc_mode_change.
+        CALL SCREEN 0500.
+      ENDIF.
+    WHEN 'DISP_PRJ'.
+      PERFORM get_selected_project CHANGING gv_current_project_id.
+      IF gv_current_project_id IS INITIAL.
+        MESSAGE 'Please select a project first.' TYPE 'W'.
+      ELSE.
+        gv_mode = gc_mode_display.
+        CALL SCREEN 0500.
+      ENDIF.
+    WHEN 'DEL_PRJ'.
+      IF gv_role <> 'M'.
+        MESSAGE 'Only managers can delete projects.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      PERFORM get_selected_project CHANGING gv_current_project_id.
+      IF gv_current_project_id IS NOT INITIAL.
+        PERFORM delete_project.
+      ELSE.
+        MESSAGE 'Please select a project to delete.' TYPE 'W'.
+      ENDIF.
+    WHEN 'REFRESH'.
+      PERFORM select_project_data.
+      IF go_alv_project IS NOT INITIAL.
+        go_alv_project->refresh_table_display( ).
+      ENDIF.
+    WHEN 'DN_TMPL'.
+      PERFORM download_project_template.
+    WHEN 'UPLOAD'.
+      PERFORM upload_project_excel.
+  ENDCASE.
+ENDMODULE.
+
+*&--- PROJECT DETAIL SCREEN 0500 ---*
+MODULE user_command_0500 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'CANC'.
+      LEAVE TO SCREEN 0400.
+    WHEN 'EXIT'.
+      LEAVE PROGRAM.
+    WHEN 'SAVE'.
+      IF gv_mode = gc_mode_display.
+        MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      PERFORM save_project_detail.
+    WHEN 'ADD_USER'.
+      PERFORM add_user_to_project.
+    WHEN 'REMO_USR'.
+      PERFORM remove_user_from_project.
+  ENDCASE.
+ENDMODULE.
+
+*&--- TABLE CONTROL SYNC (Screen 0500) ---*
+MODULE tc_users_modify INPUT.
+  MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
+ENDMODULE.
```

### CODE_PBO.md — added

`+351 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_PBO — Presentation Logic (Display)
+*&---------------------------------------------------------------------*
+
+*&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
+MODULE status_0100 OUTPUT.
+  SET PF-STATUS 'STATUS_0100'.
+  SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Hub'.
+ENDMODULE.
+
+*&--- INIT USER ROLE (runs on initial screen 0400, loaded once) ---*
+MODULE init_user_role OUTPUT.
+  " Chỉ load role 1 lần khi khởi động
+  CHECK gv_role IS INITIAL.
+  gv_uname = sy-uname.
+  SELECT SINGLE role FROM zbug_users INTO @gv_role
+    WHERE user_id = @gv_uname AND is_del <> 'X'.
+  IF sy-subrc <> 0.
+    MESSAGE 'User not registered in Bug Tracking system.' TYPE 'E' DISPLAY LIKE 'I'.
+    LEAVE PROGRAM.
+  ENDIF.
+ENDMODULE.
+
+*&--- SCREEN 0200: BUG LIST (dual mode: Project / My Bugs) ---*
+MODULE status_0200 OUTPUT.
+  CLEAR gm_excl.
+
+  " Developer cannot create/delete bugs
+  IF gv_role = 'D'.
+    APPEND 'CREATE' TO gm_excl.
+    APPEND 'DELETE' TO gm_excl.
+  ENDIF.
+  " Tester cannot delete
+  IF gv_role = 'T'.
+    APPEND 'DELETE' TO gm_excl.
+  ENDIF.
+
+  " My Bugs mode: hide CREATE (no project context to assign bug to)
+  IF gv_bug_filter_mode = 'M'.
+    APPEND 'CREATE' TO gm_excl.
+    APPEND 'DELETE' TO gm_excl.
+  ENDIF.
+
+  SET PF-STATUS 'STATUS_0200' EXCLUDING gm_excl.
+
+  " Dynamic title based on filter mode
+  DATA: lv_title TYPE string.
+  IF gv_bug_filter_mode = 'P' AND gv_current_project_id IS NOT INITIAL.
+    " Project mode: show project name in title
+    DATA: lv_prj_name TYPE zde_prj_name.
+    SELECT SINGLE project_name FROM zbug_project INTO @lv_prj_name
+      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
+    IF sy-subrc = 0.
+      lv_title = |Bugs — { lv_prj_name }|.
+    ELSE.
+      lv_title = |Bugs — { gv_current_project_id }|.
+    ENDIF.
+  ELSE.
+    " My Bugs mode
+    lv_title = |My Bugs — { gv_uname }|.
+  ENDIF.
+  SET TITLEBAR 'TITLE_BUGLIST' WITH lv_title.
+ENDMODULE.
+
+MODULE init_bug_list OUTPUT.
+  PERFORM select_bug_data.
+  IF go_alv_bug IS INITIAL.
+    " Khởi tạo ALV lần đầu
+    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
+    CREATE OBJECT go_alv_bug  EXPORTING i_parent = go_cont_bug.
+    PERFORM build_bug_fieldcat.
+    CLEAR gm_layo_bug.
+    gm_layo_bug-zebra      = 'X'.
+    gm_layo_bug-cwidth_opt = 'X'.
+    gm_layo_bug-sel_mode   = 'D'.  " Single-row selection
+    gm_layo_bug-ctab_fname = 'T_COLOR'.
+    go_alv_bug->set_table_for_first_display(
+      EXPORTING is_layout      = gm_layo_bug
+      CHANGING  it_outtab      = gt_bugs
+                it_fieldcatalog = gt_fcat_bug ).
+    " Register event handler
+    IF go_event_handler IS INITIAL.
+      CREATE OBJECT go_event_handler.
+    ENDIF.
+    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_bug.
+  ELSE.
+    go_alv_bug->refresh_table_display( ).
+  ENDIF.
+ENDMODULE.
+
+*&--- SCREEN 0300: BUG DETAIL (Tab Strip) ---*
+MODULE status_0300 OUTPUT.
+  CLEAR gm_excl.
+  " Display mode: ẩn SAVE
+  IF gv_mode = gc_mode_display.
+    APPEND 'SAVE' TO gm_excl.
+  ENDIF.
+  " Tester không upload fix
+  IF gv_role = 'T'.
+    APPEND 'UP_FIX' TO gm_excl.
+  ENDIF.
+  " Developer không upload report
+  IF gv_role = 'D'.
+    APPEND 'UP_REP' TO gm_excl.
+  ENDIF.
+  " Create mode: ẩn status change (chưa có bug_id)
+  IF gv_mode = gc_mode_create.
+    APPEND 'STATUS_CHG' TO gm_excl.
+    APPEND 'UP_FILE'    TO gm_excl.
+  ENDIF.
+  SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.
+
+  " Title shows mode (Create/Change/Display)
+  DATA(lv_mode_text) = SWITCH string( gv_mode
+    WHEN gc_mode_create  THEN 'Create Bug'
+    WHEN gc_mode_change  THEN |Change Bug: { gs_bug_detail-bug_id }|
+    WHEN gc_mode_display THEN |Display Bug: { gs_bug_detail-bug_id }| ).
+  SET TITLEBAR 'TITLE_BUGDETAIL' WITH lv_mode_text.
+ENDMODULE.
+
+MODULE load_bug_detail OUTPUT.
+  " 1. Đảm bảo subscreen luôn có giá trị hợp lệ
+  IF gv_active_subscreen IS INITIAL OR gv_active_subscreen = '0000'.
+    gv_active_subscreen = '0310'.
+  ENDIF.
+
+  " 2. Change/Display: load dữ liệu từ DB
+  IF gv_mode <> gc_mode_create AND gv_current_bug_id IS NOT INITIAL.
+    SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
+      WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
+    IF sy-subrc <> 0.
+      MESSAGE |Bug { gv_current_bug_id } not found| TYPE 'W'.
+    ENDIF.
+  ENDIF.
+
+  " 3. Create mode: reset work area
+  IF gv_mode = gc_mode_create.
+    CLEAR gs_bug_detail.
+    " Pre-fill PROJECT_ID from project context (locked on screen)
+    IF gv_current_project_id IS NOT INITIAL.
+      gs_bug_detail-project_id = gv_current_project_id.
+    ENDIF.
+    gs_bug_detail-tester_id = gv_uname.  " Default tester = current user
+    gs_bug_detail-priority  = 'M'.       " Default priority = Medium
+  ENDIF.
+
+  " 4. Populate display text variables for Screen 0310
+  gv_status_disp = SWITCH #( gs_bug_detail-status
+    WHEN gc_st_new        THEN 'New'
+    WHEN gc_st_assigned   THEN 'Assigned'
+    WHEN gc_st_inprogress THEN 'In Progress'
+    WHEN gc_st_pending    THEN 'Pending'
+    WHEN gc_st_fixed      THEN 'Fixed'
+    WHEN gc_st_resolved   THEN 'Resolved'
+    WHEN gc_st_closed     THEN 'Closed'
+    WHEN gc_st_waiting    THEN 'Waiting'
+    WHEN gc_st_rejected   THEN 'Rejected'
+    ELSE gs_bug_detail-status ).
+
+  gv_priority_disp = SWITCH #( gs_bug_detail-priority
+    WHEN 'H' THEN 'High'
+    WHEN 'M' THEN 'Medium'
+    WHEN 'L' THEN 'Low'
+    ELSE gs_bug_detail-priority ).
+
+  gv_severity_disp = SWITCH #( gs_bug_detail-severity
+    WHEN '1' THEN 'Dump/Critical'
+    WHEN '2' THEN 'Very High'
+    WHEN '3' THEN 'High'
+    WHEN '4' THEN 'Normal'
+    WHEN '5' THEN 'Minor'
+    ELSE gs_bug_detail-severity ).
+
+  gv_bug_type_disp = SWITCH #( gs_bug_detail-bug_type
+    WHEN '1' THEN 'Functional'
+    WHEN '2' THEN 'Performance'
+    WHEN '3' THEN 'UI/UX'
+    WHEN '4' THEN 'Integration'
+    WHEN '5' THEN 'Security'
+    ELSE gs_bug_detail-bug_type ).
+ENDMODULE.
+
+MODULE modify_screen_0300 OUTPUT.
+  LOOP AT SCREEN.
+    " Readonly mode: disable tất cả fields có group EDT
+    IF screen-group1 = 'EDT'.
+      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+        screen-input = 0.
+      ELSE.
+        screen-input = 1.
+      ENDIF.
+      MODIFY SCREEN.
+    ENDIF.
+
+    " BUG_ID: display-only after creation (group BID)
+    IF screen-group1 = 'BID'.
+      IF gv_mode <> gc_mode_create.
+        screen-input = 0.  " Lock BUG_ID after creation
+      ENDIF.
+      MODIFY SCREEN.
+    ENDIF.
+
+    " PROJECT_ID: locked when creating from project context (group PRJ)
+    IF screen-group1 = 'PRJ'.
+      IF gv_mode = gc_mode_create AND gv_current_project_id IS NOT INITIAL.
+        screen-input = 0.  " Pre-filled + locked
+      ENDIF.
+      IF gv_mode = gc_mode_display.
+        screen-input = 0.
+      ENDIF.
+      MODIFY SCREEN.
+    ENDIF.
+
+    " Role-based field restrictions
+    IF screen-group1 = 'TST' AND gv_role = 'D'.
+      " Dev không sửa Tester fields
+      screen-input = 0. MODIFY SCREEN.
+    ENDIF.
+    IF screen-group1 = 'DEV' AND gv_role = 'T'.
+      " Tester không sửa Dev fields
+      screen-input = 0. MODIFY SCREEN.
+    ENDIF.
+  ENDLOOP.
+ENDMODULE.
+
+*&--- SUBSCREEN 0310: DESCRIPTION MINI EDITOR ---*
+MODULE init_desc_mini OUTPUT.
+  " Create mini text editor (3-4 lines) for quick description on Bug Info tab
+  IF go_desc_mini_cont IS INITIAL.
+    CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
+    CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
+    go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
+    go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
+  ENDIF.
+
+  " Load DESC_TEXT content into mini editor
+  IF gs_bug_detail-desc_text IS NOT INITIAL.
+    DATA: lt_mini_text TYPE TABLE OF char255.
+    APPEND CONV char255( gs_bug_detail-desc_text ) TO lt_mini_text.
+    go_desc_mini_edit->set_text_as_r3table( table = lt_mini_text ).
+  ELSE.
+    DATA: lt_empty TYPE TABLE OF char255.
+    go_desc_mini_edit->set_text_as_r3table( table = lt_empty ).
+  ENDIF.
+
+  " Disable editing in Display mode or Closed status
+  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
+  ELSE.
+    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
+  ENDIF.
+ENDMODULE.
+
+*&--- SCREEN 0400: PROJECT LIST (NEW INITIAL SCREEN) ---*
+MODULE status_0400 OUTPUT.
+  CLEAR gm_excl.
+  " Chỉ Manager được tạo/sửa/xóa Project
+  IF gv_role <> 'M'.
+    APPEND 'CREA_PRJ' TO gm_excl.
+    APPEND 'CHNG_PRJ' TO gm_excl.
+    APPEND 'DEL_PRJ'  TO gm_excl.
+    APPEND 'UPLOAD'   TO gm_excl.
+    APPEND 'DN_TMPL'  TO gm_excl.
+  ENDIF.
+  SET PF-STATUS 'STATUS_0400' EXCLUDING gm_excl.
+  SET TITLEBAR 'TITLE_PROJLIST' WITH 'Project List'.
+ENDMODULE.
+
+MODULE init_project_list OUTPUT.
+  PERFORM select_project_data.
+  IF go_alv_project IS INITIAL.
+    CREATE OBJECT go_cont_project EXPORTING container_name = 'CC_PROJECT_LIST'.
+    CREATE OBJECT go_alv_project  EXPORTING i_parent = go_cont_project.
+    PERFORM build_pro_fieldcat.
+    CLEAR gm_layo_prj.
+    gm_layo_prj-zebra      = 'X'.
+    gm_layo_prj-cwidth_opt = 'X'.
+    gm_layo_prj-sel_mode   = 'D'.
+    go_alv_project->set_table_for_first_display(
+      EXPORTING is_layout      = gm_layo_prj
+      CHANGING  it_outtab      = gt_projects
+                it_fieldcatalog = gt_fcat_project ).
+    IF go_event_handler IS INITIAL.
+      CREATE OBJECT go_event_handler.
+    ENDIF.
+    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_project.
+  ELSE.
+    go_alv_project->refresh_table_display( ).
+  ENDIF.
+ENDMODULE.
+
+*&--- SCREEN 0500: PROJECT DETAIL + TABLE CONTROL ---*
+MODULE status_0500 OUTPUT.
+  CLEAR gm_excl.
+  IF gv_role <> 'M'.
+    APPEND 'SAVE'     TO gm_excl.
+    APPEND 'ADD_USER' TO gm_excl.
+    APPEND 'REMO_USR' TO gm_excl.
+  ENDIF.
+  IF gv_mode = gc_mode_display.
+    APPEND 'SAVE'     TO gm_excl.
+    APPEND 'ADD_USER' TO gm_excl.
+    APPEND 'REMO_USR' TO gm_excl.
+  ENDIF.
+  SET PF-STATUS 'STATUS_0500' EXCLUDING gm_excl.
+
+  " Title shows mode (Create/Change/Display)
+  DATA(lv_prj_title) = SWITCH string( gv_mode
+    WHEN gc_mode_create  THEN 'Create Project'
+    WHEN gc_mode_change  THEN |Change Project: { gs_project-project_name }|
+    WHEN gc_mode_display THEN |Display Project: { gs_project-project_name }| ).
+  IF lv_prj_title IS INITIAL.
+    lv_prj_title = 'Project Detail'.
+  ENDIF.
+  SET TITLEBAR 'TITLE_PRJDET' WITH lv_prj_title.
+ENDMODULE.
+
+MODULE init_project_detail OUTPUT.
+  IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
+    SELECT SINGLE * FROM zbug_project INTO @gs_project
+      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
+    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
+      WHERE project_id = @gv_current_project_id.
+  ENDIF.
+  IF gv_mode = gc_mode_create.
+    CLEAR: gs_project, gt_user_project.
+    gs_project-project_manager = gv_uname.  " Default manager = current user
+    gs_project-project_status  = '1'.       " Opening
+  ENDIF.
+
+  " Populate display text for Project Status on Screen 0500
+  gv_prj_status_disp = SWITCH #( gs_project-project_status
+    WHEN '1' THEN 'Opening'
+    WHEN '2' THEN 'In Process'
+    WHEN '3' THEN 'Done'
+    WHEN '4' THEN 'Cancelled'
+    ELSE gs_project-project_status ).
+ENDMODULE.
+
+MODULE modify_screen_0500 OUTPUT.
+  LOOP AT SCREEN.
+    IF screen-group1 = 'EDT'.
+      IF gv_mode = gc_mode_display OR gv_role <> 'M'.
+        screen-input = 0.
+      ELSE.
+        screen-input = 1.
+      ENDIF.
+      MODIFY SCREEN.
+    ENDIF.
+  ENDLOOP.
+ENDMODULE.
```

### CODE_TOP.md — added

`+145 / -0 lines` (new file)

```diff
+*&---------------------------------------------------------------------*
+*& Include Z_BUG_WS_TOP — Global Declarations
+*&---------------------------------------------------------------------*
+" === FORWARD DECLARATION ===
+CLASS lcl_event_handler DEFINITION DEFERRED.
+
+" === CONSTANTS ===
+CONSTANTS:
+  gc_mode_display TYPE char1 VALUE 'D',
+  gc_mode_change  TYPE char1 VALUE 'C',
+  gc_mode_create  TYPE char1 VALUE 'X'.
+
+" === BUG STATUS CONSTANTS (9-state lifecycle) ===
+CONSTANTS:
+  gc_st_new        TYPE zde_bug_status VALUE '1',
+  gc_st_assigned   TYPE zde_bug_status VALUE '2',
+  gc_st_inprogress TYPE zde_bug_status VALUE '3',
+  gc_st_pending    TYPE zde_bug_status VALUE '4',
+  gc_st_fixed      TYPE zde_bug_status VALUE '5',
+  gc_st_resolved   TYPE zde_bug_status VALUE '6',
+  gc_st_closed     TYPE zde_bug_status VALUE '7',
+  gc_st_waiting    TYPE zde_bug_status VALUE 'W',
+  gc_st_rejected   TYPE zde_bug_status VALUE 'R'.
+
+" === GLOBAL VARIABLES ===
+DATA: gv_ok_code   TYPE sy-ucomm,
+      gv_save_ok   TYPE sy-ucomm,
+      gv_mode      TYPE char1,           " D/C/X (Display/Change/Create)
+      gv_role      TYPE zde_bug_role,    " T/D/M (Tester/Dev/Manager)
+      gv_uname     TYPE sy-uname,
+      gv_current_bug_id     TYPE zde_bug_id,
+      gv_current_project_id TYPE zde_project_id.
+
+" === BUG LIST FILTER MODE (NEW — Project-first flow) ===
+" 'P' = Project mode (all bugs of a project, no role filter)
+" 'M' = My Bugs mode (cross-project, filtered by role)
+DATA: gv_bug_filter_mode TYPE char1.
+
+" === DISPLAY TEXT VARIABLES (for Screen fields — mapped from raw codes) ===
+DATA: gv_status_disp     TYPE char20,    " Status text for Screen 0310
+      gv_priority_disp   TYPE char10,    " Priority text for Screen 0310
+      gv_severity_disp   TYPE char20,    " Severity text for Screen 0310
+      gv_bug_type_disp   TYPE char20,    " Bug Type text for Screen 0310
+      gv_prj_status_disp TYPE char20.    " Project Status text for Screen 0500
+
+" === TAB STRIP (Screen 0300) ===
+DATA: gv_active_tab       TYPE char20 VALUE 'TAB_INFO',
+      gv_active_subscreen TYPE sy-dynnr VALUE '0310'.
+
+" === ALV OBJECTS (Containers & Grids) ===
+DATA: go_cont_bug     TYPE REF TO cl_gui_custom_container,
+      go_alv_bug      TYPE REF TO cl_gui_alv_grid,
+      go_cont_project TYPE REF TO cl_gui_custom_container,
+      go_alv_project  TYPE REF TO cl_gui_alv_grid,
+      go_cont_history TYPE REF TO cl_gui_custom_container,
+      go_alv_history  TYPE REF TO cl_gui_alv_grid.
+
+" === TEXT EDIT OBJECTS (subscreens 0320/0330/0340) ===
+DATA: go_cont_desc      TYPE REF TO cl_gui_custom_container,
+      go_edit_desc      TYPE REF TO cl_gui_textedit,
+      go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
+      go_edit_dev_note  TYPE REF TO cl_gui_textedit,
+      go_cont_tstr_note TYPE REF TO cl_gui_custom_container,
+      go_edit_tstr_note TYPE REF TO cl_gui_textedit.
+
+" === DESCRIPTION MINI EDITOR (on Subscreen 0310 — Bug Info tab) ===
+DATA: go_desc_mini_cont TYPE REF TO cl_gui_custom_container,
+      go_desc_mini_edit TYPE REF TO cl_gui_textedit.
+
+" === FIELD CATALOGS (Column Definitions) ===
+DATA: gt_fcat_bug     TYPE lvc_t_fcat,
+      gt_fcat_project TYPE lvc_t_fcat,
+      gt_fcat_history TYPE lvc_t_fcat.
+
+" === INTERNAL TABLES & WORK AREAS ===
+" ALV Bug Data — khớp chính xác với ZBUG_TRACKER fields + display text columns
+TYPES: BEGIN OF ty_bug_alv,
+         bug_id           TYPE zde_bug_id,        " CHAR 10
+         title            TYPE zde_bug_title,      " CHAR 100
+         project_id       TYPE zde_project_id,     " CHAR 20
+         status           TYPE zde_bug_status,     " CHAR 20 — đúng theo SE11
+         status_text      TYPE char20,             " Display: New/Assigned/...
+         priority         TYPE zde_priority,       " CHAR 1
+         priority_text    TYPE char10,             " Display: High/Medium/Low
+         severity         TYPE zde_severity,       " CHAR 1
+         severity_text    TYPE char20,             " Display: Dump/VeryHigh/... (NEW)
+         bug_type         TYPE zde_bug_type,       " CHAR 1
+         bug_type_text    TYPE char20,             " Display: Functional/Performance/... (NEW)
+         tester_id        TYPE zde_username,        " CHAR 12
+         verify_tester_id TYPE zde_username,        " CHAR 12
+         dev_id           TYPE zde_username,        " CHAR 12
+         sap_module       TYPE zde_sap_module,      " CHAR 20 — đúng theo SE11
+         created_at       TYPE zde_bug_cr_date,     " DATS 8
+         t_color          TYPE lvc_t_scol,          " Row color
+       END OF ty_bug_alv.
+
+DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
+      gs_bug_detail TYPE zbug_tracker.
+
+" ALV Project Data — khớp với ZBUG_PROJECT fields
+TYPES: BEGIN OF ty_project_alv,
+         project_id      TYPE zde_project_id,      " CHAR 20
+         project_name    TYPE zde_prj_name,         " CHAR 100
+         description     TYPE zde_prj_desc,         " CHAR 255
+         project_status  TYPE zde_prj_status,       " CHAR 1
+         status_text     TYPE char20,               " Display: Opening/In Process/...
+         start_date      TYPE sydatum,              " DATS 8
+         end_date        TYPE sydatum,              " DATS 8
+         project_manager TYPE zde_username,          " CHAR 12
+         note            TYPE char255,              " CHAR 255
+         t_color         TYPE lvc_t_scol,
+       END OF ty_project_alv.
+
+DATA: gt_projects TYPE TABLE OF ty_project_alv,
+      gs_project  TYPE zbug_project.
+
+" ALV History Data — khớp với ZBUG_HISTORY fields
+TYPES: BEGIN OF ty_history_alv,
+         changed_at   TYPE zde_bug_cr_date,    " DATS 8
+         changed_time TYPE zde_bug_cr_time,    " TIMS 6
+         changed_by   TYPE zde_username,       " CHAR 12
+         action_type  TYPE zde_bug_act_type,   " CHAR 2
+         action_text  TYPE char30,
+         old_value    TYPE zde_bug_title,      " CHAR 100 — matches OLD_VALUE data element
+         new_value    TYPE zde_bug_title,      " CHAR 100 — matches NEW_VALUE data element
+         reason       TYPE string,             " STRING — matches ZBUG_HISTORY-REASON
+       END OF ty_history_alv.
+
+DATA: gt_history TYPE TABLE OF ty_history_alv.
+
+" === TABLE CONTROL SCREEN 0500 ===
+DATA: gt_user_project TYPE TABLE OF zbug_user_projec,
+      gs_user_project TYPE zbug_user_projec.
+
+CONTROLS: tc_users  TYPE TABLEVIEW USING SCREEN 0500,
+          ts_detail TYPE TABSTRIP.
+
+" === EVENT HANDLER OBJECT ===
+DATA: go_event_handler TYPE REF TO lcl_event_handler.
+
+" === MODULE-LEVEL WORK VARIABLES (global — Module Pool DATA in MODULE has no local scope) ===
+DATA: gm_excl     TYPE TABLE OF sy-ucomm,  " Reused by all status_XXXX modules
+      gm_layo_bug TYPE lvc_s_layo,          " Layout for Bug ALV
+      gm_layo_prj TYPE lvc_s_layo,          " Layout for Project ALV
+      gm_title    TYPE string.              " Title buffer for SET TITLEBAR
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
