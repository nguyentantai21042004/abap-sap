# Analysis v2

### CODE_F00.md — modified

`+45 / -9 lines`

```diff
--- previous/CODE_F00.md
+++ current/CODE_F00.md
@@ -1,5 +1,9 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes
+*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes (over v3.0):
+*&  - handle_double_click: NEW method for evidence ALV download on dblclick
+*&  - build_evidence_fieldcat: NEW FORM for evidence ALV columns
 *&---------------------------------------------------------------------*
 
 CLASS lcl_event_handler DEFINITION.
@@ -10,7 +14,9 @@
       handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
         IMPORTING e_object e_interactive,
       handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
-        IMPORTING e_ucomm.
+        IMPORTING e_ucomm,
+      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
+        IMPORTING e_row e_column es_row_no.            " v4.0: evidence download
 ENDCLASS.
 
 CLASS lcl_event_handler IMPLEMENTATION.
@@ -22,17 +28,15 @@
         gv_current_bug_id   = ls_bug-bug_id.
         gv_mode             = gc_mode_display.
         gv_active_subscreen = '0310'.
+        gv_active_tab       = 'TAB_INFO'.      " v3.0: sync tab highlight
+        CLEAR gv_detail_loaded.                 " v3.0: force fresh load
         CALL SCREEN 0300.
       ENDIF.
     ENDIF.
 
     " ----- PROJECT LIST: click Project ID → Bug List (project context) -----
     " NEW FLOW: Hotspot trên Project ALV → mở Bug List filtered by project
-    "           (thay vì mở Project Detail như trước)
     IF e_column_id-fieldname = 'PROJECT_ID'.
-      " Check if we are on Project List (ALV source = go_alv_project)
-      " vs Bug List (ALV source = go_alv_bug)
-      " Distinguish by checking which table the row belongs to
       READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
       IF sy-subrc = 0.
         " From Project List → open Bug List with project filter
@@ -41,11 +45,11 @@
         CALL SCREEN 0200.
       ELSE.
         " From Bug List → open Project Detail (display mode)
-        " (PROJECT_ID hotspot on Bug ALV still opens Project Detail)
         READ TABLE gt_bugs INTO DATA(ls_bug2) INDEX e_row_id-index.
         IF sy-subrc = 0 AND ls_bug2-project_id IS NOT INITIAL.
           gv_current_project_id = ls_bug2-project_id.
           gv_mode               = gc_mode_display.
+          CLEAR gv_prj_detail_loaded.            " v3.0: force fresh load
           CALL SCREEN 0500.
         ENDIF.
       ENDIF.
@@ -56,6 +60,16 @@
   ENDMETHOD.
 
   METHOD handle_user_command.
+  ENDMETHOD.
+
+  " v4.0: Double-click on Evidence ALV → download selected file
+  METHOD handle_double_click.
+    " Only fires for go_alv_evidence (registered below in PBO)
+    DATA: ls_evidence TYPE ty_evidence_alv.
+    READ TABLE gt_evidence INTO ls_evidence INDEX es_row_no-row_id.
+    IF sy-subrc = 0.
+      PERFORM download_evidence_file USING ls_evidence-evd_id.
+    ENDIF.
   ENDMETHOD.
 ENDCLASS.
 
@@ -78,8 +92,8 @@
   add_fcat 'PROJECT_ID'       'Project'         15.
   add_fcat 'STATUS_TEXT'      'Status'          15.
   add_fcat 'PRIORITY_TEXT'    'Priority'        10.
-  add_fcat 'SEVERITY_TEXT'    'Severity'        15.   " NEW — text instead of raw code
-  add_fcat 'BUG_TYPE_TEXT'    'Type'            18.   " NEW — text instead of raw code
+  add_fcat 'SEVERITY_TEXT'    'Severity'        15.
+  add_fcat 'BUG_TYPE_TEXT'    'Type'            18.
   add_fcat 'SAP_MODULE'       'Module'          12.
   add_fcat 'TESTER_ID'        'Tester'          12.
   add_fcat 'VERIFY_TESTER_ID' 'Verify Tester'   12.
@@ -161,3 +175,25 @@
   add_hfcat 'NEW_VALUE'    'New Value'   30.
   add_hfcat 'REASON'       'Reason'      40.
 ENDFORM.
+
+*&--- v4.0: EVIDENCE FIELD CATALOG ---*
+FORM build_evidence_fieldcat.
+  DATA: ls_fcat TYPE lvc_s_fcat.
+  CLEAR gt_fcat_evidence.
+
+  DEFINE add_efcat.
+    CLEAR ls_fcat.
+    ls_fcat-tabname   = 'GT_EVIDENCE'.
+    ls_fcat-fieldname = &1.
+    ls_fcat-coltext   = &2.
+    ls_fcat-outputlen = &3.
+    APPEND ls_fcat TO gt_fcat_evidence.
+  END-OF-DEFINITION.
+
+  add_efcat 'EVD_ID'    'ID'         10.
+  add_efcat 'FILE_NAME' 'File Name'  50.
+  add_efcat 'MIME_TYPE' 'Type'       25.
+  add_efcat 'FILE_SIZE' 'Size (B)'   12.
+  add_efcat 'ERNAM'     'Uploaded By' 12.
+  add_efcat 'ERDAT'     'Date'       10.
+ENDFORM.
```

### CODE_F01.md — modified

`+802 / -34 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -1,5 +1,17 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F01 — Main Business Logic (SQL & Processing)
+*& Include Z_BUG_WS_F01 — Main Business Logic (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes (over v3.0):
+*&  - upload_evidence_file/report/fix: REAL implementation (binary → ZBUG_EVIDENCE)
+*&  - load_evidence_data: NEW — SELECT without CONTENT for ALV
+*&  - download_evidence_file: NEW — binary download from ZBUG_EVIDENCE
+*&  - delete_evidence: NEW — popup confirm → DELETE
+*&  - check_evidence_for_status: NEW — file prefix enforcement before transition
+*&  - check_unsaved_bug / check_unsaved_prj: NEW — snapshot comparison
+*&  - send_mail_notification: NEW — real BCS API email
+*&  - save_bug_detail: ENHANCED — severity/priority cross-validation
+*&  - save_project_detail: ENHANCED — completion validation
+*&  - cleanup_detail_editors: ENHANCED — evidence ALV cleanup
 *&---------------------------------------------------------------------*
 
 *&=== SELECT BUG DATA (dual mode: Project / My Bugs) ===*
@@ -16,16 +28,16 @@
   ELSE.
     " ---- MY BUGS MODE: filter by role (cross-project) ----
     CASE gv_role.
-      WHEN 'T'. " Tester: chỉ thấy bugs mình tạo hoặc được assign verify
+      WHEN 'T'. " Tester: bugs mình tạo hoặc được assign verify
         SELECT * FROM zbug_tracker
           INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
           WHERE ( tester_id = @gv_uname OR verify_tester_id = @gv_uname )
             AND is_del <> 'X'.
-      WHEN 'D'. " Developer: chỉ thấy bugs được assign cho mình
+      WHEN 'D'. " Developer: bugs được assign cho mình
         SELECT * FROM zbug_tracker
           INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
           WHERE dev_id = @gv_uname AND is_del <> 'X'.
-      WHEN 'M'. " Manager: thấy tất cả bugs
+      WHEN 'M'. " Manager: tất cả bugs
         SELECT * FROM zbug_tracker
           INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
           WHERE is_del <> 'X'.
@@ -51,7 +63,6 @@
       WHEN 'M' THEN 'Medium'
       WHEN 'L' THEN 'Low' ).
 
-    " NEW: Severity text
     <bug>-severity_text = SWITCH #( <bug>-severity
       WHEN '1' THEN 'Dump/Critical'
       WHEN '2' THEN 'Very High'
@@ -59,7 +70,6 @@
       WHEN '4' THEN 'Normal'
       WHEN '5' THEN 'Minor' ).
 
-    " NEW: Bug Type text
     <bug>-bug_type_text = SWITCH #( <bug>-bug_type
       WHEN '1' THEN 'Functional'
       WHEN '2' THEN 'Performance'
@@ -77,12 +87,12 @@
   gv_uname = sy-uname.
 
   IF gv_role = 'M'.
-    " Manager thấy tất cả projects
+    " Manager sees all projects
     SELECT * FROM zbug_project
       INTO CORRESPONDING FIELDS OF TABLE @gt_projects
       WHERE is_del <> 'X'.
   ELSE.
-    " Tester/Dev chỉ thấy projects được assign
+    " Tester/Dev: only assigned projects
     SELECT p~project_id,
            p~project_name,
            p~project_status,
@@ -120,6 +130,17 @@
   IF gs_bug_detail-title IS INITIAL.
     MESSAGE 'Title is required.' TYPE 'E'.
     RETURN.
+  ENDIF.
+
+  " v4.0: Severity vs Priority cross-validation
+  " Dump/Critical(1), VeryHigh(2), High(3) → must have Priority = High
+  IF gs_bug_detail-severity IS NOT INITIAL
+     AND ( gs_bug_detail-severity = '1' OR gs_bug_detail-severity = '2'
+           OR gs_bug_detail-severity = '3' ).
+    IF gs_bug_detail-priority <> 'H'.
+      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'E'.
+      RETURN.
+    ENDIF.
   ENDIF.
 
   IF gv_mode = gc_mode_create.
@@ -162,7 +183,7 @@
 
   IF sy-subrc = 0.
     COMMIT WORK.
-    " Set current bug id BEFORE saving long texts (save_long_text checks this)
+    " Set current bug id BEFORE saving long texts
     gv_current_bug_id = gs_bug_detail-bug_id.
     " Save long text tabs (SAVE_TEXT performs its own COMMIT internally)
     PERFORM save_long_text USING 'Z001'.  " Description
@@ -170,6 +191,8 @@
     PERFORM save_long_text USING 'Z003'.  " Tester Note
     MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
     gv_mode = gc_mode_change.
+    " v4.0: Update snapshot after successful save
+    gs_bug_snapshot = gs_bug_detail.
   ELSE.
     ROLLBACK WORK.
     MESSAGE 'Save failed. Please check required fields.' TYPE 'E'.
@@ -207,6 +230,22 @@
     MESSAGE 'Project Name is required.' TYPE 'E'. RETURN.
   ENDIF.
 
+  " v4.0: Project completion validation — block Done if unresolved bugs
+  IF gs_project-project_status = '3'. " Done
+    DATA: lv_open_bugs TYPE i.
+    SELECT COUNT(*) FROM zbug_tracker INTO @lv_open_bugs
+      WHERE project_id = @gs_project-project_id
+        AND is_del <> 'X'
+        AND status <> @gc_st_resolved
+        AND status <> @gc_st_closed.
+    IF lv_open_bugs > 0.
+      DATA: lv_block_msg TYPE string.
+      lv_block_msg = |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed.|.
+      MESSAGE lv_block_msg TYPE 'E'.
+      RETURN.
+    ENDIF.
+  ENDIF.
+
   IF gv_mode = gc_mode_create.
     gs_project-ernam          = lv_un.
     gs_project-erdat          = sy-datum.
@@ -227,6 +266,8 @@
     MESSAGE |Project { gs_project-project_id } saved successfully.| TYPE 'S'.
     gv_current_project_id = gs_project-project_id.
     gv_mode = gc_mode_change.
+    " v4.0: Update snapshot after successful save
+    gs_prj_snapshot = gs_project.
   ELSE.
     ROLLBACK WORK.
     MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'E'.
@@ -240,15 +281,15 @@
     CLEAR <bug>-t_color.
     ls_color-fname = 'STATUS_TEXT'.
     CASE <bug>-status.
-      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue — New
-      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow — Waiting
-      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange — Assigned
-      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple — In Progress
-      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow — Pending
-      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green — Fixed
-      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green — Resolved
-      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey — Closed
-      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red — Rejected
+      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue
+      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow
+      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange
+      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple
+      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow
+      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green
+      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green
+      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey
+      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red
     ENDCASE.
     APPEND ls_color TO <bug>-t_color.
   ENDLOOP.
@@ -432,6 +473,13 @@
     RETURN.
   ENDIF.
 
+  " v4.0: Evidence file prefix enforcement before status transition
+  DATA: lv_evd_ok TYPE abap_bool.
+  PERFORM check_evidence_for_status USING lv_new_status CHANGING lv_evd_ok.
+  IF lv_evd_ok = abap_false.
+    RETURN.  " Message already shown by check_evidence_for_status
+  ENDIF.
+
   DATA: lv_un TYPE sy-uname.
   lv_un = sy-uname.
   UPDATE zbug_tracker
@@ -448,6 +496,8 @@
     lv_new_st = lv_new_status.
     PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
     gs_bug_detail-status = lv_new_status.
+    " v4.0: Update snapshot to reflect new status
+    gs_bug_snapshot-status = lv_new_status.
     MESSAGE |Status updated: { lv_current } → { lv_new_status }| TYPE 'S'.
   ELSE.
     ROLLBACK WORK.
@@ -479,7 +529,7 @@
   ls_hist-new_value    = pv_new.
   ls_hist-reason       = pv_reason.
   INSERT zbug_history FROM @ls_hist.
-  " Note: intentionally no COMMIT here — caller handles commit
+  " Note: no COMMIT here — caller handles commit
 ENDFORM.
 
 *&=== PROJECT USER MANAGEMENT: ADD ===*
@@ -546,7 +596,6 @@
 
 *&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
 FORM remove_user_from_project.
-  " Xóa user đang được highlight trong table control
   DATA: lv_line TYPE i.
   lv_line = tc_users-current_line.
   IF lv_line = 0.
@@ -575,7 +624,7 @@
   ENDIF.
 ENDFORM.
 
-*&=== LOAD HISTORY TAB ===*
+*&=== LOAD HISTORY TAB (creates ALV if needed, refreshes if exists) ===*
 FORM load_history_data.
   CLEAR gt_history.
   CHECK gv_current_bug_id IS NOT INITIAL.
@@ -612,18 +661,737 @@
   ENDIF.
 ENDFORM.
 
-*&=== STUBS (Phase D) ===*
+*&=====================================================================*
+*& CLEANUP: Free all Screen 0300 GUI controls (v4.0)
+*& Called on BACK/CANC/EXIT from Bug Detail — ensures clean state
+*& for the next bug opened.
+*&=====================================================================*
+FORM cleanup_detail_editors.
+  " --- Mini description editor (Subscreen 0310) ---
+  IF go_desc_mini_edit IS NOT INITIAL.
+    go_desc_mini_edit->free( ).
+    FREE go_desc_mini_edit.
+    CLEAR go_desc_mini_edit.
+  ENDIF.
+  IF go_desc_mini_cont IS NOT INITIAL.
+    go_desc_mini_cont->free( ).
+    FREE go_desc_mini_cont.
+    CLEAR go_desc_mini_cont.
+  ENDIF.
+
+  " --- Long Text: Description (Subscreen 0320) ---
+  IF go_edit_desc IS NOT INITIAL.
+    go_edit_desc->free( ).
+    FREE go_edit_desc.
+    CLEAR go_edit_desc.
+  ENDIF.
+  IF go_cont_desc IS NOT INITIAL.
+    go_cont_desc->free( ).
+    FREE go_cont_desc.
+    CLEAR go_cont_desc.
+  ENDIF.
+
+  " --- Long Text: Dev Note (Subscreen 0330) ---
+  IF go_edit_dev_note IS NOT INITIAL.
+    go_edit_dev_note->free( ).
+    FREE go_edit_dev_note.
+    CLEAR go_edit_dev_note.
+  ENDIF.
+  IF go_cont_dev_note IS NOT INITIAL.
+    go_cont_dev_note->free( ).
+    FREE go_cont_dev_note.
+    CLEAR go_cont_dev_note.
+  ENDIF.
+
+  " --- Long Text: Tester Note (Subscreen 0340) ---
+  IF go_edit_tstr_note IS NOT INITIAL.
+    go_edit_tstr_note->free( ).
+    FREE go_edit_tstr_note.
+    CLEAR go_edit_tstr_note.
+  ENDIF.
+  IF go_cont_tstr_note IS NOT INITIAL.
+    go_cont_tstr_note->free( ).
+    FREE go_cont_tstr_note.
+    CLEAR go_cont_tstr_note.
+  ENDIF.
+
+  " --- v4.0: Evidence ALV (Subscreen 0350) ---
+  IF go_alv_evidence IS NOT INITIAL.
+    go_alv_evidence->free( ).
+    FREE go_alv_evidence.
+    CLEAR go_alv_evidence.
+  ENDIF.
+  IF go_cont_evidence IS NOT INITIAL.
+    go_cont_evidence->free( ).
+    FREE go_cont_evidence.
+    CLEAR go_cont_evidence.
+  ENDIF.
+
+  " --- History ALV (Subscreen 0360) ---
+  IF go_alv_history IS NOT INITIAL.
+    go_alv_history->free( ).
+    FREE go_alv_history.
+    CLEAR go_alv_history.
+  ENDIF.
+  IF go_cont_history IS NOT INITIAL.
+    go_cont_history->free( ).
+    FREE go_cont_history.
+    CLEAR go_cont_history.
+  ENDIF.
+
+  " --- Clear data-loaded flag so next bug triggers fresh DB load ---
+  CLEAR gv_detail_loaded.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: LOAD EVIDENCE DATA (metadata only — no CONTENT for performance)
+*& Used by PBO init_evidence_alv module
+*&=====================================================================*
+FORM load_evidence_data.
+  CLEAR gt_evidence.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+
+  SELECT evd_id, file_name, mime_type, file_size, ernam, erdat
+    FROM zbug_evidence
+    INTO CORRESPONDING FIELDS OF TABLE @gt_evidence
+    WHERE bug_id = @gv_current_bug_id
+    ORDER BY evd_id DESCENDING.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: UPLOAD EVIDENCE — Common logic for UP_FILE / UP_REP / UP_FIX
+*& pv_att_field: 'EVD' = generic, 'REP' = report, 'FIX' = fix
+*&=====================================================================*
+FORM upload_evidence USING pv_att_field TYPE char3.
+  DATA: lt_file_table  TYPE filetable,
+        lv_rc          TYPE i,
+        lv_fullpath    TYPE string,
+        lt_binary      TYPE solix_tab,
+        lv_filelength  TYPE i,
+        lv_xstring     TYPE xstring,
+        lv_fname_only  TYPE string,
+        lv_ext         TYPE string,
+        lv_mime        TYPE w3conttype,
+        ls_evd         TYPE zbug_evidence,
+        lv_max_evd_id  TYPE numc10,
+        lv_new_evd_id  TYPE numc10.
+
+  " Bug must be saved first (need bug_id for evidence)
+  IF gv_current_bug_id IS INITIAL.
+    MESSAGE 'Save the bug first before uploading evidence.' TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 1. File open dialog
+  cl_gui_frontend_services=>file_open_dialog(
+    EXPORTING
+      file_filter = 'All Files (*.*)|*.*|Images (*.png;*.jpg)|*.png;*.jpg|Documents (*.pdf;*.docx)|*.pdf;*.docx|Excel (*.xlsx)|*.xlsx'
+    CHANGING
+      file_table  = lt_file_table
+      rc          = lv_rc
+    EXCEPTIONS OTHERS = 1 ).
+  IF lv_rc <= 0. RETURN. ENDIF.
+  READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
+  lv_fullpath = ls_file-filename.
+
+  " 2. Extract filename from full path (after last \ or /)
+  DATA: lv_idx TYPE i.
+  lv_fname_only = lv_fullpath.
+  FIND ALL OCCURRENCES OF '\' IN lv_fullpath MATCH OFFSET lv_idx.
+  IF sy-subrc = 0.
+    lv_fname_only = lv_fullpath+lv_idx.
+    " Skip the backslash itself
+    IF strlen( lv_fname_only ) > 0 AND lv_fname_only(1) = '\'.
+      SHIFT lv_fname_only LEFT BY 1 PLACES.
+    ENDIF.
+  ELSE.
+    FIND ALL OCCURRENCES OF '/' IN lv_fullpath MATCH OFFSET lv_idx.
+    IF sy-subrc = 0.
+      lv_fname_only = lv_fullpath+lv_idx.
+      IF strlen( lv_fname_only ) > 0 AND lv_fname_only(1) = '/'.
+        SHIFT lv_fname_only LEFT BY 1 PLACES.
+      ENDIF.
+    ENDIF.
+  ENDIF.
+
+  " 3. Detect MIME type from file extension
+  DATA: lv_fname_upper TYPE string.
+  lv_fname_upper = lv_fname_only.
+  TRANSLATE lv_fname_upper TO UPPER CASE.
+  IF lv_fname_upper CS '.XLSX'.  lv_mime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'.
+  ELSEIF lv_fname_upper CS '.XLS'.   lv_mime = 'application/vnd.ms-excel'.
+  ELSEIF lv_fname_upper CS '.PDF'.   lv_mime = 'application/pdf'.
+  ELSEIF lv_fname_upper CS '.DOCX'.  lv_mime = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'.
+  ELSEIF lv_fname_upper CS '.DOC'.   lv_mime = 'application/msword'.
+  ELSEIF lv_fname_upper CS '.PNG'.   lv_mime = 'image/png'.
+  ELSEIF lv_fname_upper CS '.JPG' OR lv_fname_upper CS '.JPEG'. lv_mime = 'image/jpeg'.
+  ELSEIF lv_fname_upper CS '.TXT'.   lv_mime = 'text/plain'.
+  ELSEIF lv_fname_upper CS '.ZIP'.   lv_mime = 'application/zip'.
+  ELSE.                               lv_mime = 'application/octet-stream'.
+  ENDIF.
+
+  " 4. Upload binary file from frontend
+  cl_gui_frontend_services=>gui_upload(
+    EXPORTING
+      filename   = lv_fullpath
+      filetype   = 'BIN'
+    IMPORTING
+      filelength = lv_filelength
+    CHANGING
+      data_tab   = lt_binary
+    EXCEPTIONS
+      file_open_error  = 1
+      file_read_error  = 2
+      OTHERS           = 3 ).
+  IF sy-subrc <> 0.
+    MESSAGE 'Failed to read file from frontend.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 5. Convert binary table to XSTRING
+  CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
+    EXPORTING
+      input_length = lv_filelength
+    IMPORTING
+      buffer       = lv_xstring
+    TABLES
+      binary_tab   = lt_binary
+    EXCEPTIONS
+      failed       = 1
+      OTHERS       = 2.
+  IF sy-subrc <> 0.
+    MESSAGE 'Failed to convert file to binary.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 6. Auto-generate EVD_ID (MAX + 1)
+  SELECT MAX( evd_id ) FROM zbug_evidence INTO @lv_max_evd_id.
+  lv_new_evd_id = lv_max_evd_id + 1.
+
+  " 7. Build evidence record
+  ls_evd-evd_id     = lv_new_evd_id.
+  ls_evd-bug_id     = gv_current_bug_id.
+  ls_evd-project_id = gs_bug_detail-project_id.
+  ls_evd-file_name  = lv_fname_only.
+  ls_evd-mime_type  = lv_mime.
+  ls_evd-file_size  = lv_filelength.
+  ls_evd-content    = lv_xstring.
+  ls_evd-ernam      = sy-uname.
+  ls_evd-erdat      = sy-datum.
+  ls_evd-erzet      = sy-uzeit.
+
+  " 8. Insert into database
+  INSERT zbug_evidence FROM @ls_evd.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    " Log history
+    PERFORM add_history_entry USING gv_current_bug_id 'AT' '' lv_fname_only 'Evidence uploaded'.
+    COMMIT WORK.
+
+    " 9. Set ATT_ field if applicable
+    CASE pv_att_field.
+      WHEN 'REP'.
+        gs_bug_detail-att_report = lv_fname_only(100).  " Truncate to CHAR 100
+        UPDATE zbug_tracker SET att_report = @gs_bug_detail-att_report
+          WHERE bug_id = @gv_current_bug_id.
+        COMMIT WORK.
+      WHEN 'FIX'.
+        gs_bug_detail-att_fix = lv_fname_only(100).     " Truncate to CHAR 100
+        UPDATE zbug_tracker SET att_fix = @gs_bug_detail-att_fix
+          WHERE bug_id = @gv_current_bug_id.
+        COMMIT WORK.
+    ENDCASE.
+
+    MESSAGE |File "{ lv_fname_only }" uploaded successfully (ID: { lv_new_evd_id }).| TYPE 'S'.
+
+    " 10. Refresh evidence ALV if visible
+    IF go_alv_evidence IS NOT INITIAL.
+      PERFORM load_evidence_data.
+      go_alv_evidence->refresh_table_display( ).
+    ENDIF.
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Failed to save evidence to database.' TYPE 'S' DISPLAY LIKE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: UPLOAD EVIDENCE FILE (generic — no prefix requirement)
+*& Fcode UP_FILE
+*&=====================================================================*
 FORM upload_evidence_file.
-  " TODO Phase D: GOS attachment upload
-  MESSAGE 'File upload not yet implemented (Phase D).' TYPE 'I'.
-ENDFORM.
-
-FORM download_project_template.
-  " TODO Phase D: Download Excel template from SMW0
-  MESSAGE 'Template download not yet implemented (Phase D).' TYPE 'I'.
-ENDFORM.
-
+  PERFORM upload_evidence USING 'EVD'.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: UPLOAD REPORT FILE (Tester uploads test report / bug proof)
+*& Fcode UP_REP — also sets ATT_REPORT on ZBUG_TRACKER
+*&=====================================================================*
+FORM upload_report_file.
+  PERFORM upload_evidence USING 'REP'.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: UPLOAD FIX FILE (Developer uploads fix package / patch)
+*& Fcode UP_FIX — also sets ATT_FIX on ZBUG_TRACKER
+*&=====================================================================*
+FORM upload_fix_file.
+  PERFORM upload_evidence USING 'FIX'.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: DOWNLOAD EVIDENCE FILE
+*& Called from evidence ALV double-click handler
+*&=====================================================================*
+FORM download_evidence_file USING pv_evd_id TYPE numc10.
+  DATA: lv_xstring  TYPE xstring,
+        lv_fname    TYPE sdok_filnm,
+        lt_binary   TYPE solix_tab,
+        lv_size     TYPE i,
+        lv_filename TYPE string,
+        lv_path     TYPE string,
+        lv_fullpath TYPE string,
+        lv_uaction  TYPE i.
+
+  " 1. Read evidence content from DB
+  SELECT SINGLE content, file_name FROM zbug_evidence
+    INTO (@lv_xstring, @lv_fname)
+    WHERE evd_id = @pv_evd_id.
+  IF sy-subrc <> 0.
+    MESSAGE 'Evidence file not found.' TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 2. Convert XSTRING to binary table
+  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
+    EXPORTING
+      buffer        = lv_xstring
+    IMPORTING
+      output_length = lv_size
+    TABLES
+      binary_tab    = lt_binary.
+
+  " 3. File save dialog
+  DATA: lv_default_name TYPE string.
+  lv_default_name = lv_fname.
+  cl_gui_frontend_services=>file_save_dialog(
+    EXPORTING
+      default_file_name = lv_default_name
+    CHANGING
+      filename    = lv_filename
+      path        = lv_path
+      fullpath    = lv_fullpath
+      user_action = lv_uaction
+    EXCEPTIONS OTHERS = 1 ).
+  IF lv_uaction <> 0.
+    MESSAGE 'Download cancelled.' TYPE 'S'.
+    RETURN.
+  ENDIF.
+
+  " 4. Download binary to frontend
+  cl_gui_frontend_services=>gui_download(
+    EXPORTING
+      filename     = lv_fullpath
+      filetype     = 'BIN'
+      bin_filesize = lv_size
+    CHANGING
+      data_tab     = lt_binary
+    EXCEPTIONS OTHERS = 1 ).
+  IF sy-subrc = 0.
+    MESSAGE |File "{ lv_fname }" downloaded successfully.| TYPE 'S'.
+    " v4.0: Auto-open downloaded file
+    cl_gui_frontend_services=>execute(
+      EXPORTING document = lv_fullpath
+      EXCEPTIONS OTHERS = 1 ).
+  ELSE.
+    MESSAGE 'Download failed.' TYPE 'S' DISPLAY LIKE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: DELETE EVIDENCE (selected row from Evidence ALV)
+*& Fcode DL_EVD
+*&=====================================================================*
+FORM delete_evidence.
+  " Get selected row from evidence ALV
+  CHECK go_alv_evidence IS NOT INITIAL.
+
+  DATA: lt_rows TYPE lvc_t_roid.
+  go_alv_evidence->get_selected_rows( IMPORTING et_row_no = lt_rows ).
+  IF lt_rows IS INITIAL.
+    MESSAGE 'Please select an evidence file to delete.' TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
+  DATA: ls_evd TYPE ty_evidence_alv.
+  READ TABLE gt_evidence INTO ls_evd INDEX ls_row-row_id.
+  IF sy-subrc <> 0.
+    MESSAGE 'Could not read selected evidence row.' TYPE 'W'.
+    RETURN.
+  ENDIF.
+
+  " Popup confirm
+  DATA: lv_confirmed TYPE abap_bool,
+        lv_msg       TYPE string.
+  lv_msg = |Delete evidence file "{ ls_evd-file_name }" (ID: { ls_evd-evd_id })?|.
+  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
+  CHECK lv_confirmed = abap_true.
+
+  " Delete from DB
+  DELETE FROM zbug_evidence WHERE evd_id = @ls_evd-evd_id.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gv_current_bug_id 'AT' ls_evd-file_name '' 'Evidence deleted'.
+    COMMIT WORK.
+    MESSAGE |Evidence "{ ls_evd-file_name }" deleted.| TYPE 'S'.
+    " Refresh ALV
+    PERFORM load_evidence_data.
+    go_alv_evidence->refresh_table_display( ).
+  ELSE.
+    ROLLBACK WORK.
+    MESSAGE 'Delete failed.' TYPE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: CHECK EVIDENCE PREFIX BEFORE STATUS TRANSITION
+*& Enforces file naming convention per status:
+*&   → Fixed(5):    require BUGPROOF_ evidence exists
+*&   → Resolved(6): require TESTCASE_ evidence exists
+*&   → Closed(7):   require CONFIRM_ evidence exists
+*&=====================================================================*
+FORM check_evidence_for_status USING    pv_new_status TYPE zde_bug_status
+                               CHANGING pv_ok         TYPE abap_bool.
+  pv_ok = abap_true.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+
+  DATA: lv_prefix TYPE string,
+        lv_count  TYPE i,
+        lv_like   TYPE sdok_filnm.
+
+  CASE pv_new_status.
+    WHEN gc_st_fixed.     " To Fixed: need bug proof uploaded earlier
+      lv_prefix = 'BUGPROOF_'.
+    WHEN gc_st_resolved.  " To Resolved: need test case result
+      lv_prefix = 'TESTCASE_'.
+    WHEN gc_st_closed.    " To Closed: need confirmation
+      lv_prefix = 'CONFIRM_'.
+    WHEN OTHERS.
+      RETURN.  " No check needed for other transitions
+  ENDCASE.
+
+  " Build LIKE pattern: 'BUGPROOF_%'
+  CONCATENATE lv_prefix '%' INTO lv_like.
+
+  SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
+    WHERE bug_id    = @gv_current_bug_id
+      AND file_name LIKE @lv_like.
+
+  IF lv_count = 0.
+    MESSAGE |Evidence file with prefix "{ lv_prefix }" is required before this status change. Upload first.| TYPE 'W'.
+    pv_ok = abap_false.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: CHECK UNSAVED BUG CHANGES (snapshot comparison)
+*& Pops up Save/Discard/Cancel if changes detected
+*&=====================================================================*
+FORM check_unsaved_bug CHANGING pv_continue TYPE abap_bool.
+  pv_continue = abap_true.
+
+  " Sync mini editor text to work area for accurate comparison
+  PERFORM save_desc_mini_to_workarea.
+
+  " Compare current state with snapshot
+  IF gs_bug_detail = gs_bug_snapshot.
+    RETURN.  " No changes — continue silently
+  ENDIF.
+
+  " Changes detected — popup
+  DATA: lv_answer TYPE char1.
+  CALL FUNCTION 'POPUP_TO_CONFIRM'
+    EXPORTING
+      titlebar              = 'Unsaved Changes'
+      text_question         = 'You have unsaved changes. Save before leaving?'
+      text_button_1         = 'Save'
+      text_button_2         = 'Discard'
+      default_button        = '1'
+      display_cancel_button = 'X'
+    IMPORTING
+      answer                = lv_answer.
+
+  CASE lv_answer.
+    WHEN '1'. " Save
+      PERFORM save_bug_detail.
+      pv_continue = abap_true.
+    WHEN '2'. " Discard
+      pv_continue = abap_true.
+    WHEN 'A'. " Cancel — stay on screen
+      pv_continue = abap_false.
+  ENDCASE.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: CHECK UNSAVED PROJECT CHANGES (snapshot comparison)
+*&=====================================================================*
+FORM check_unsaved_prj CHANGING pv_continue TYPE abap_bool.
+  pv_continue = abap_true.
+
+  " Compare current state with snapshot
+  IF gs_project = gs_prj_snapshot.
+    RETURN.  " No changes — continue silently
+  ENDIF.
+
+  " Changes detected — popup
+  DATA: lv_answer TYPE char1.
+  CALL FUNCTION 'POPUP_TO_CONFIRM'
+    EXPORTING
+      titlebar              = 'Unsaved Changes'
+      text_question         = 'You have unsaved project changes. Save before leaving?'
+      text_button_1         = 'Save'
+      text_button_2         = 'Discard'
+      default_button        = '1'
+      display_cancel_button = 'X'
+    IMPORTING
+      answer                = lv_answer.
+
+  CASE lv_answer.
+    WHEN '1'. " Save
+      PERFORM save_project_detail.
+      pv_continue = abap_true.
+    WHEN '2'. " Discard
+      pv_continue = abap_true.
+    WHEN 'A'. " Cancel — stay on screen
+      pv_continue = abap_false.
+  ENDCASE.
+ENDFORM.
+
+*&=====================================================================*
+*& v4.0: SEND EMAIL NOTIFICATION (BCS API — real implementation)
+*& Sends email to Dev, Tester, Verify Tester with bug details
+*&=====================================================================*
+FORM send_mail_notification.
+  DATA: lo_send_request TYPE REF TO cl_bcs,
+        lo_document     TYPE REF TO cl_document_bcs,
+        lo_sender       TYPE REF TO cl_sapuser_bcs,
+        lo_recipient    TYPE REF TO if_recipient_bcs,
+        lt_text         TYPE bcsy_text,
+        ls_text         TYPE soli,
+        lv_subject      TYPE so_obj_des,
+        lv_email        TYPE adr6-smtp_addr,
+        lv_has_rcpt     TYPE abap_bool.
+
+  " Build email subject
+  lv_subject = |Bug { gs_bug_detail-bug_id } - { gs_bug_detail-title }|.
+
+  " Build email body
+  CLEAR lt_text.
+  ls_text-line = |Bug Tracking Notification|.      APPEND ls_text TO lt_text.
+  ls_text-line = |============================|.   APPEND ls_text TO lt_text.
+  ls_text-line = | |.                               APPEND ls_text TO lt_text.
+  ls_text-line = |Bug ID:    { gs_bug_detail-bug_id }|. APPEND ls_text TO lt_text.
+  ls_text-line = |Title:     { gs_bug_detail-title }|.   APPEND ls_text TO lt_text.
+  ls_text-line = |Status:    { gv_status_disp }|.        APPEND ls_text TO lt_text.
+  ls_text-line = |Priority:  { gv_priority_disp }|.      APPEND ls_text TO lt_text.
+  ls_text-line = |Severity:  { gv_severity_disp }|.      APPEND ls_text TO lt_text.
+  ls_text-line = |Project:   { gs_bug_detail-project_id }|. APPEND ls_text TO lt_text.
+  ls_text-line = |Module:    { gs_bug_detail-sap_module }|.  APPEND ls_text TO lt_text.
+  ls_text-line = | |.                               APPEND ls_text TO lt_text.
+  ls_text-line = |Tester:    { gs_bug_detail-tester_id }|.   APPEND ls_text TO lt_text.
+  ls_text-line = |Developer: { gs_bug_detail-dev_id }|.      APPEND ls_text TO lt_text.
+  ls_text-line = |Verify:    { gs_bug_detail-verify_tester_id }|. APPEND ls_text TO lt_text.
+  ls_text-line = | |.                               APPEND ls_text TO lt_text.
+  ls_text-line = |Sent by:   { sy-uname } at { sy-datum DATE = USER } { sy-uzeit TIME = USER }|.
+  APPEND ls_text TO lt_text.
+
+  TRY.
+      " Create persistent send request
+      lo_send_request = cl_bcs=>create_persistent( ).
+
+      " Create document
+      lo_document = cl_document_bcs=>create_document(
+        i_type    = 'RAW'
+        i_text    = lt_text
+        i_subject = lv_subject ).
+      lo_send_request->set_document( lo_document ).
+
+      " Set sender (current user)
+      lo_sender = cl_sapuser_bcs=>create( sy-uname ).
+      lo_send_request->set_sender( lo_sender ).
+
+      " Collect unique recipients: dev, tester, verify tester
+      DATA: lt_recipients TYPE TABLE OF zde_username.
+      IF gs_bug_detail-dev_id IS NOT INITIAL.
+        APPEND gs_bug_detail-dev_id TO lt_recipients.
+      ENDIF.
+      IF gs_bug_detail-tester_id IS NOT INITIAL.
+        APPEND gs_bug_detail-tester_id TO lt_recipients.
+      ENDIF.
+      IF gs_bug_detail-verify_tester_id IS NOT INITIAL.
+        APPEND gs_bug_detail-verify_tester_id TO lt_recipients.
+      ENDIF.
+      SORT lt_recipients.
+      DELETE ADJACENT DUPLICATES FROM lt_recipients.
+
+      " Remove current user from recipients (don't email yourself)
+      DELETE lt_recipients WHERE table_line = sy-uname.
+
+      lv_has_rcpt = abap_false.
+      LOOP AT lt_recipients INTO DATA(lv_user).
+        CLEAR lv_email.
+        SELECT SINGLE email FROM zbug_users INTO @lv_email
+          WHERE user_id = @lv_user AND is_del <> 'X'.
+        IF sy-subrc = 0 AND lv_email IS NOT INITIAL.
+          lo_recipient = cl_cam_address_bcs=>create_internet_address( lv_email ).
+          lo_send_request->add_recipient( lo_recipient ).
+          lv_has_rcpt = abap_true.
+        ENDIF.
+      ENDLOOP.
+
+      IF lv_has_rcpt = abap_false.
+        MESSAGE 'No recipients with valid email addresses found.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+
+      " Send immediately
+      lo_send_request->set_send_immediately( abap_true ).
+      lo_send_request->send( ).
+      COMMIT WORK.
+      MESSAGE 'Email notification sent successfully.' TYPE 'S'.
+
+    CATCH cx_bcs INTO DATA(lx_bcs).
+      DATA: lv_err_text TYPE string.
+      lv_err_text = lx_bcs->get_text( ).
+      MESSAGE lv_err_text TYPE 'S' DISPLAY LIKE 'E'.
+  ENDTRY.
+ENDFORM.
+
+*&=====================================================================*
+*& UPLOAD PROJECT EXCEL (Phase D — real implementation)
+*& Fcode UPLOAD on Screen 0400: Manager uploads Excel → validate → insert
+*&=====================================================================*
 FORM upload_project_excel.
-  " TODO Phase D: Upload Excel via TEXT_CONVERT_XLS_TO_SAP
-  MESSAGE 'Excel upload not yet implemented (Phase D).' TYPE 'I'.
-ENDFORM.
+  DATA: lv_file     TYPE string,
+        lt_raw      TYPE truxs_t_text_data,
+        lt_projects TYPE TABLE OF zbug_project,
+        ls_project  TYPE zbug_project,
+        lv_errors   TYPE i,
+        lv_success  TYPE i.
+
+  " 1. File open dialog
+  DATA: lt_file_table TYPE filetable, lv_rc TYPE i.
+  cl_gui_frontend_services=>file_open_dialog(
+    EXPORTING file_filter = 'Excel Files (*.xlsx)|*.xlsx'
+    CHANGING  file_table  = lt_file_table
+              rc          = lv_rc
+    EXCEPTIONS OTHERS = 1 ).
+
+  IF lv_rc <= 0. RETURN. ENDIF.
+  READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
+  lv_file = ls_file-filename.
+
+  " 2. Read Excel into internal table
+  TYPES: BEGIN OF ty_upload,
+           project_id      TYPE char20,
+           project_name    TYPE char100,
+           description     TYPE char255,
+           start_date      TYPE char10,
+           end_date        TYPE char10,
+           project_manager TYPE char12,
+           note            TYPE char255,
+         END OF ty_upload.
+  DATA: lt_upload TYPE TABLE OF ty_upload.
+
+  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
+    EXPORTING
+      i_field_seperator = 'X'
+      i_line_header     = 'X'    " Skip header row
+      i_tab_raw_data    = lt_raw
+      i_filename        = lv_file
+    TABLES
+      i_tab_converted_data = lt_upload
+    EXCEPTIONS
+      conversion_failed   = 1
+      OTHERS              = 2.
+
+  IF sy-subrc <> 0.
+    MESSAGE 'Failed to read Excel file.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 3. Validate + Insert
+  LOOP AT lt_upload ASSIGNING FIELD-SYMBOL(<fs>).
+    CLEAR ls_project.
+
+    " Skip header/format hint rows
+    IF <fs>-project_id CS 'PROJECT_ID' OR <fs>-project_id CS '(Char'.
+      CONTINUE.
+    ENDIF.
+
+    " Validate PROJECT_ID not empty
+    IF <fs>-project_id IS INITIAL.
+      ADD 1 TO lv_errors.
+      CONTINUE.
+    ENDIF.
+
+    " Validate PROJECT_ID not duplicate
+    SELECT COUNT(*) FROM zbug_project
+      WHERE project_id = @<fs>-project_id.
+    IF sy-dbcnt > 0.
+      ADD 1 TO lv_errors.
+      CONTINUE.
+    ENDIF.
+
+    " Validate Project Manager exists + is Manager role + active
+    SELECT COUNT(*) FROM zbug_users
+      WHERE user_id = @<fs>-project_manager AND role = 'M' AND is_del <> 'X'.
+    IF sy-dbcnt = 0.
+      ADD 1 TO lv_errors.
+      CONTINUE.
+    ENDIF.
+
+    " Map data to structure
+    ls_project-project_id      = <fs>-project_id.
+    ls_project-project_name    = <fs>-project_name.
+    ls_project-description     = <fs>-description.
+    ls_project-project_manager = <fs>-project_manager.
+    ls_project-note            = <fs>-note.
+
+    " Parse dates (DD.MM.YYYY → YYYYMMDD)
+    IF <fs>-start_date IS NOT INITIAL AND strlen( <fs>-start_date ) = 10.
+      CONCATENATE <fs>-start_date+6(4) <fs>-start_date+3(2) <fs>-start_date(2)
+        INTO ls_project-start_date.
+    ENDIF.
+    IF <fs>-end_date IS NOT INITIAL AND strlen( <fs>-end_date ) = 10.
+      CONCATENATE <fs>-end_date+6(4) <fs>-end_date+3(2) <fs>-end_date(2)
+        INTO ls_project-end_date.
+    ENDIF.
+
+    " Default values
+    ls_project-project_status = '1'.  " Opening
+    ls_project-ernam          = sy-uname.
+    ls_project-erdat          = sy-datum.
+    ls_project-erzet          = sy-uzeit.
+
+    APPEND ls_project TO lt_projects.
+    ADD 1 TO lv_success.
+  ENDLOOP.
+
+  " 4. Batch insert + refresh ALV
+  IF lt_projects IS NOT INITIAL.
+    INSERT zbug_project FROM TABLE lt_projects.
+    COMMIT WORK.
+    DATA: lv_msg TYPE string.
+    lv_msg = |Uploaded { lv_success } project(s). Errors: { lv_errors }|.
+    MESSAGE lv_msg TYPE 'S'.
+    " Refresh project ALV after upload
+    PERFORM select_project_data.
+    IF go_alv_project IS NOT INITIAL.
+      go_alv_project->refresh_table_display( ).
+    ENDIF.
+  ELSE.
+    MESSAGE 'No valid data to upload.' TYPE 'S' DISPLAY LIKE 'E'.
+  ENDIF.
+ENDFORM.
```

### CODE_F02.md — modified

`+228 / -3 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -1,10 +1,17 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Popup
+*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes:
+*&  - NEW: f4_date — Calendar popup for date fields (Feature #4)
+*&  - NEW: download_smw0_template — Generic SMW0 download + auto-open (Feature #10)
+*&  - NEW: download_testcase_template  (ZTEMPLATE_TESTCASE)  (Feature #7)
+*&  - NEW: download_confirm_template   (ZTEMPLATE_CONFIRM)   (Feature #7)
+*&  - NEW: download_bugproof_template  (ZTEMPLATE_BUGPROOF)  (Feature #7)
+*&  - ENHANCED: download_project_template — refactored to use generic helper
 *&---------------------------------------------------------------------*
 
 *&=== F4: PROJECT ID ===*
 FORM f4_project_id USING pv_fn TYPE dynfnam.
-  " Hiển thị danh sách projects để chọn
   TYPES: BEGIN OF ty_prj_f4,
            project_id   TYPE zde_project_id,
            project_name TYPE zde_prj_name,
@@ -33,7 +40,6 @@
 
 *&=== F4: USER ID ===*
 FORM f4_user_id USING pv_fn TYPE dynfnam.
-  " Hiển thị danh sách users để chọn
   TYPES: BEGIN OF ty_usr_f4,
            user_id   TYPE zde_username,
            full_name TYPE zde_bug_full_name,
@@ -179,6 +185,48 @@
       OTHERS          = 1.
 ENDFORM.
 
+*&=====================================================================*
+*& F4 DATE CALENDAR POPUP (v4.0 — Feature #4)
+*&
+*& Shows SAP calendar popup and assigns selected date to the
+*& appropriate global structure field based on pv_field_name.
+*&
+*& Called from POV modules in PAI:
+*&   MODULE f4_prj_startdate  → PERFORM f4_date USING 'PRJ_START_DATE'
+*&   MODULE f4_prj_enddate    → PERFORM f4_date USING 'PRJ_END_DATE'
+*&
+*& NOTE: Bug date fields (DEADLINE, START_DATE) do NOT exist in
+*&       ZBUG_TRACKER per SE11. Only project dates are supported.
+*&
+*& Pattern from ZPG_BUGTRACKING_DETAIL (MODULE f4_date / f4_startdate):
+*& Assigns directly to structure field — screen picks up new value on PBO.
+*&=====================================================================*
+FORM f4_date USING pv_field_name TYPE char20.
+  DATA: lv_selected_date TYPE dats.
+
+  CALL FUNCTION 'F4_DATE'
+    EXPORTING
+      date_for_first_month         = sy-datum
+      display                      = ' '
+    IMPORTING
+      select_date                  = lv_selected_date
+    EXCEPTIONS
+      calendar_buffer_not_loadable = 1
+      date_after_range             = 2
+      date_before_range            = 3
+      date_invalid                 = 4
+      OTHERS                       = 8.
+
+  CHECK sy-subrc = 0.
+
+  CASE pv_field_name.
+    WHEN 'PRJ_START_DATE'.
+      gs_project-start_date = lv_selected_date.
+    WHEN 'PRJ_END_DATE'.
+      gs_project-end_date = lv_selected_date.
+  ENDCASE.
+ENDFORM.
+
 *&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
 " pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
 " Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
@@ -260,3 +308,180 @@
       OTHERS          = 4.
   " Note: SAVE_TEXT performs its own internal COMMIT
 ENDFORM.
+
+*&=====================================================================*
+*& GENERIC SMW0 TEMPLATE DOWNLOAD + AUTO-OPEN (v4.0 — Features #7, #10)
+*&
+*& Downloads a binary template from SMW0 (MIME Repository) to local PC
+*& and auto-opens it in the default application (e.g., Excel).
+*&
+*& Pattern from reference program ZPG_BUGTRACKING_MAIN (FORM excute_download):
+*& 1. Check template exists in WWWDATA table
+*& 2. Read file extension + size from WWWPARAMS table
+*& 3. WWWDATA_IMPORT to load binary content into memory
+*& 4. file_save_dialog for user to pick save location
+*& 5. GUI_DOWNLOAD in BIN mode with exact bin_filesize
+*& 6. cl_gui_frontend_services=>execute to auto-open
+*&
+*& SMW0 Object IDs used:
+*&   ZTEMPLATE_PROJECT  — Project upload template
+*&   ZTEMPLATE_TESTCASE — Test case template (required before Resolved)
+*&   ZTEMPLATE_CONFIRM  — Confirm template (required before Closed)
+*&   ZTEMPLATE_BUGPROOF — Bug proof template (required before Fixed)
+*&=====================================================================*
+FORM download_smw0_template USING pv_objid TYPE wwwdatatab-objid.
+  DATA: ls_wdata    TYPE wwwdatatab,
+        lv_filename TYPE string,
+        lv_ext      TYPE string,
+        lv_size     TYPE string,
+        lv_filesize TYPE i,
+        lt_wmime    TYPE TABLE OF w3mime,
+        lv_path     TYPE string,
+        lv_fullpath TYPE string,
+        lv_msg      TYPE string.
+
+  " 1. Check if template exists in SMW0
+  SELECT SINGLE * FROM wwwdata                              "#EC WARNOK
+    INTO CORRESPONDING FIELDS OF ls_wdata
+    WHERE relid = 'MI'
+      AND objid = pv_objid.
+
+  IF sy-subrc <> 0.
+    lv_msg = |Template { pv_objid } not found in SMW0. Upload it first.|.
+    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 2. Get file metadata from WWWPARAMS
+  "    - text field from WWWDATA = display name (used as default filename)
+  "    - 'fileextension' param  = original file extension
+  "    - 'filesize' param       = exact byte size (critical for BIN download)
+  lv_filename = ls_wdata-text.
+  IF lv_filename IS INITIAL.
+    lv_filename = pv_objid.
+  ENDIF.
+
+  SELECT SINGLE value INTO lv_ext
+    FROM wwwparams
+    WHERE relid = ls_wdata-relid
+      AND objid = ls_wdata-objid
+      AND name  = 'fileextension'.
+  REPLACE ALL OCCURRENCES OF '.' IN lv_ext WITH ''.
+  IF lv_ext IS INITIAL.
+    lv_ext = 'xlsx'.
+  ENDIF.
+
+  SELECT SINGLE value INTO lv_size
+    FROM wwwparams
+    WHERE relid = ls_wdata-relid
+      AND objid = ls_wdata-objid
+      AND name  = 'filesize'.
+  lv_filesize = lv_size.
+
+  " 3. Load binary content from WWWDATA into memory
+  CALL FUNCTION 'WWWDATA_IMPORT'
+    EXPORTING
+      key               = ls_wdata
+    TABLES
+      mime              = lt_wmime
+    EXCEPTIONS
+      wrong_object_type = 1
+      import_error      = 2
+      OTHERS            = 3.
+
+  IF sy-subrc <> 0.
+    lv_msg = |Failed to load template { pv_objid } from SMW0.|.
+    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 4. File save dialog — let user choose destination
+  cl_gui_frontend_services=>file_save_dialog(
+    EXPORTING
+      default_extension = lv_ext
+      default_file_name = lv_filename
+    CHANGING
+      filename    = lv_filename
+      path        = lv_path
+      fullpath    = lv_fullpath
+    EXCEPTIONS OTHERS = 1 ).
+
+  IF lv_fullpath IS INITIAL.
+    MESSAGE 'Download cancelled.' TYPE 'S'.
+    RETURN.
+  ENDIF.
+
+  " 5. Download binary to local file
+  "    bin_filesize is critical — without it the last MIME block
+  "    may be padded with nulls, corrupting the file.
+  CALL FUNCTION 'GUI_DOWNLOAD'
+    EXPORTING
+      filename     = lv_fullpath
+      filetype     = 'BIN'
+      bin_filesize = lv_filesize
+    TABLES
+      data_tab     = lt_wmime
+    EXCEPTIONS
+      OTHERS       = 1.
+
+  IF sy-subrc <> 0.
+    MESSAGE 'Failed to save template file.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 6. Auto-open the downloaded file in default app (Feature #10)
+  cl_gui_frontend_services=>execute(
+    EXPORTING
+      document               = lv_fullpath
+    EXCEPTIONS
+      cntl_error             = 1
+      error_no_gui           = 2
+      bad_parameter          = 3
+      file_not_found         = 4
+      path_not_found         = 5
+      file_extension_unknown = 6
+      error_execute_failed   = 7
+      synchronous_failed     = 8
+      not_supported_by_gui   = 9
+      OTHERS                 = 10 ).
+  " Ignore execute errors — file is already saved successfully
+
+  MESSAGE 'Template downloaded successfully.' TYPE 'S'.
+ENDFORM.
+
+*&=== DOWNLOAD PROJECT TEMPLATE ===*
+*& Wrapper: downloads ZTEMPLATE_PROJECT from SMW0
+*& Called from PAI fcode DN_TMPL on Screen 0400
+FORM download_project_template.
+  PERFORM download_smw0_template USING 'ZTEMPLATE_PROJECT'.
+ENDFORM.
+
+*&=====================================================================*
+*& DOWNLOAD TESTCASE TEMPLATE (v4.0 — Feature #7)
+*& Wrapper: downloads ZTEMPLATE_TESTCASE from SMW0
+*& Called from PAI fcode DN_TC on Screen 0200
+*& User must upload this template to SMW0 (Binary, relid = MI)
+*&=====================================================================*
+FORM download_testcase_template.
+  PERFORM download_smw0_template USING 'ZTEMPLATE_TESTCASE'.
+ENDFORM.
+
+*&=====================================================================*
+*& DOWNLOAD CONFIRM TEMPLATE (v4.0 — Feature #7)
+*& Wrapper: downloads ZTEMPLATE_CONFIRM from SMW0
+*& Called from PAI fcode DN_CONF on Screen 0200
+*& User must upload this template to SMW0 (Binary, relid = MI)
+*&=====================================================================*
+FORM download_confirm_template.
+  PERFORM download_smw0_template USING 'ZTEMPLATE_CONFIRM'.
+ENDFORM.
+
+*&=====================================================================*
+*& DOWNLOAD BUGPROOF TEMPLATE (v4.0 — Feature #7)
+*& Wrapper: downloads ZTEMPLATE_BUGPROOF from SMW0
+*& Called from PAI fcode DN_PROOF on Screen 0200
+*& User must upload this template to SMW0 (Binary, relid = MI)
+*&=====================================================================*
+FORM download_bugproof_template.
+  PERFORM download_smw0_template USING 'ZTEMPLATE_BUGPROOF'.
+ENDFORM.
```

### CODE_PAI.md — modified

`+95 / -22 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -1,5 +1,11 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_PAI — User Action Logic
+*& Include Z_BUG_WS_PAI — User Action Logic (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes (over v3.0):
+*&  - user_command_0300: added DL_EVD (delete evidence), SENDMAIL handlers
+*&  - user_command_0300: added unsaved changes check before BACK/CANC
+*&  - user_command_0500: added unsaved changes check before BACK/CANC
+*&  - user_command_0200: added DN_TC, DN_CONF, DN_PROOF (template downloads)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety) ---*
@@ -16,7 +22,9 @@
   ENDCASE.
 ENDMODULE.
 
-*&--- BUG LIST SCREEN 0200 ---*
+*&=====================================================================*
+*& BUG LIST SCREEN 0200
+*&=====================================================================*
 MODULE user_command_0200 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
@@ -27,7 +35,7 @@
       LEAVE PROGRAM.
     WHEN 'CREATE'.
       " Only available in Project mode (gv_bug_filter_mode = 'P')
-      " Button is hidden in My Bugs mode via PBO, but double-check here
+      " Button is hidden in My Bugs mode via PBO, but double-check
       IF gv_bug_filter_mode = 'M'.
         MESSAGE 'Cannot create bug without project context. Go to a project first.' TYPE 'W'.
         RETURN.
@@ -37,17 +45,21 @@
         RETURN.
       ENDIF.
       CLEAR: gv_current_bug_id, gs_bug_detail.
-      gv_mode = gc_mode_create.
+      gv_mode             = gc_mode_create.
       gv_active_subscreen = '0310'.
-      " gv_current_project_id is already set from project context
+      gv_active_tab       = 'TAB_INFO'.      " v3.0: sync tab highlight
+      CLEAR gv_detail_loaded.                 " v3.0: force fresh load
+      " gv_current_project_id already set from project context
       CALL SCREEN 0300.
     WHEN 'CHANGE'.
       PERFORM get_selected_bug CHANGING gv_current_bug_id.
       IF gv_current_bug_id IS INITIAL.
         MESSAGE 'Please select a bug first.' TYPE 'W'.
       ELSE.
-        gv_mode = gc_mode_change.
+        gv_mode             = gc_mode_change.
         gv_active_subscreen = '0310'.
+        gv_active_tab       = 'TAB_INFO'.    " v3.0
+        CLEAR gv_detail_loaded.               " v3.0
         CALL SCREEN 0300.
       ENDIF.
     WHEN 'DISPLAY'.
@@ -55,8 +67,10 @@
       IF gv_current_bug_id IS INITIAL.
         MESSAGE 'Please select a bug first.' TYPE 'W'.
       ELSE.
-        gv_mode = gc_mode_display.
+        gv_mode             = gc_mode_display.
         gv_active_subscreen = '0310'.
+        gv_active_tab       = 'TAB_INFO'.    " v3.0
+        CLEAR gv_detail_loaded.               " v3.0
         CALL SCREEN 0300.
       ENDIF.
     WHEN 'DELETE'.
@@ -75,16 +89,35 @@
       IF go_alv_bug IS NOT INITIAL.
         go_alv_bug->refresh_table_display( ).
       ENDIF.
-  ENDCASE.
-ENDMODULE.
-
-*&--- BUG DETAIL SCREEN 0300 ---*
+    " v4.0: Template download buttons
+    WHEN 'DN_TC'.
+      PERFORM download_testcase_template.
+    WHEN 'DN_CONF'.
+      PERFORM download_confirm_template.
+    WHEN 'DN_PROOF'.
+      PERFORM download_bugproof_template.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
+*& BUG DETAIL SCREEN 0300
+*&=====================================================================*
 MODULE user_command_0300 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
+      " v4.0: Check unsaved changes before leaving
+      IF gv_mode <> gc_mode_display.
+        DATA: lv_continue TYPE abap_bool.
+        PERFORM check_unsaved_bug CHANGING lv_continue.
+        IF lv_continue = abap_false.
+          RETURN.  " User cancelled — stay on screen
+        ENDIF.
+      ENDIF.
+      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
       LEAVE TO SCREEN 0200.
     WHEN 'EXIT'.
+      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
       LEAVE PROGRAM.
     WHEN 'SAVE'.
       IF gv_mode = gc_mode_display.
@@ -102,27 +135,41 @@
       PERFORM change_bug_status.
     WHEN 'UP_FILE'.
       PERFORM upload_evidence_file.
-    " ---- Tab switching ----
+    WHEN 'UP_REP'.
+      PERFORM upload_report_file.
+    WHEN 'UP_FIX'.
+      PERFORM upload_fix_file.
+    " v4.0: Delete evidence
+    WHEN 'DL_EVD'.
+      PERFORM delete_evidence.
+    " v4.0: Send email notification
+    WHEN 'SENDMAIL'.
+      PERFORM send_mail_notification.
+    " ---- Tab switching (v3.0: sync gv_active_tab, no PERFORM load calls) ----
     WHEN 'TAB_INFO'.
       gv_active_subscreen = '0310'.
+      gv_active_tab       = 'TAB_INFO'.
     WHEN 'TAB_DESC'.
       gv_active_subscreen = '0320'.
-      PERFORM load_long_text USING 'Z001'.
+      gv_active_tab       = 'TAB_DESC'.
     WHEN 'TAB_DEVNOTE'.
       gv_active_subscreen = '0330'.
-      PERFORM load_long_text USING 'Z002'.
+      gv_active_tab       = 'TAB_DEVNOTE'.
     WHEN 'TAB_TSTR_NOTE'.
       gv_active_subscreen = '0340'.
-      PERFORM load_long_text USING 'Z003'.
+      gv_active_tab       = 'TAB_TSTR_NOTE'.
     WHEN 'TAB_EVIDENCE'.
       gv_active_subscreen = '0350'.
+      gv_active_tab       = 'TAB_EVIDENCE'.
     WHEN 'TAB_HISTORY'.
       gv_active_subscreen = '0360'.
-      PERFORM load_history_data.
-  ENDCASE.
-ENDMODULE.
-
-*&--- PROJECT LIST SCREEN 0400 (INITIAL SCREEN) ---*
+      gv_active_tab       = 'TAB_HISTORY'.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
+*& PROJECT LIST SCREEN 0400 (INITIAL SCREEN)
+*&=====================================================================*
 MODULE user_command_0400 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
@@ -132,7 +179,7 @@
     WHEN 'EXIT'.
       LEAVE PROGRAM.
     WHEN 'MY_BUGS'.
-      " NEW: My Bugs — show cross-project bugs filtered by role
+      " My Bugs — show cross-project bugs filtered by role
       CLEAR gv_current_project_id.
       gv_bug_filter_mode = 'M'.
       " Destroy existing Bug ALV to force rebuild with new data
@@ -151,6 +198,7 @@
       ENDIF.
       CLEAR: gv_current_project_id, gs_project, gt_user_project.
       gv_mode = gc_mode_create.
+      CLEAR gv_prj_detail_loaded.            " v3.0: force fresh load
       CALL SCREEN 0500.
     WHEN 'CHNG_PRJ'.
       PERFORM get_selected_project CHANGING gv_current_project_id.
@@ -158,6 +206,7 @@
         MESSAGE 'Please select a project first.' TYPE 'W'.
       ELSE.
         gv_mode = gc_mode_change.
+        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
         CALL SCREEN 0500.
       ENDIF.
     WHEN 'DISP_PRJ'.
@@ -166,6 +215,7 @@
         MESSAGE 'Please select a project first.' TYPE 'W'.
       ELSE.
         gv_mode = gc_mode_display.
+        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
         CALL SCREEN 0500.
       ENDIF.
     WHEN 'DEL_PRJ'.
@@ -191,11 +241,21 @@
   ENDCASE.
 ENDMODULE.
 
-*&--- PROJECT DETAIL SCREEN 0500 ---*
+*&=====================================================================*
+*& PROJECT DETAIL SCREEN 0500
+*&=====================================================================*
 MODULE user_command_0500 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
+      " v4.0: Check unsaved changes before leaving
+      IF gv_mode <> gc_mode_display.
+        DATA: lv_prj_continue TYPE abap_bool.
+        PERFORM check_unsaved_prj CHANGING lv_prj_continue.
+        IF lv_prj_continue = abap_false.
+          RETURN.  " User cancelled — stay on screen
+        ENDIF.
+      ENDIF.
       LEAVE TO SCREEN 0400.
     WHEN 'EXIT'.
       LEAVE PROGRAM.
@@ -216,3 +276,16 @@
 MODULE tc_users_modify INPUT.
   MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
 ENDMODULE.
+
+*&=====================================================================*
+*& v4.0: POV MODULES — F4 Calendar Popup (Screen 0500)
+*& Called from PROCESS ON VALUE-REQUEST in Screen 0500 flow logic.
+*& These modules delegate to FORM f4_date in CODE_F02.md.
+*&=====================================================================*
+MODULE f4_prj_startdate INPUT.
+  PERFORM f4_date USING 'PRJ_START_DATE'.
+ENDMODULE.
+
+MODULE f4_prj_enddate INPUT.
+  PERFORM f4_date USING 'PRJ_END_DATE'.
+ENDMODULE.
```

### CODE_PBO.md — modified

`+223 / -39 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -1,5 +1,13 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_PBO — Presentation Logic (Display)
+*& Include Z_BUG_WS_PBO — Presentation Logic (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes (over v3.0):
+*&  - load_bug_detail: saves snapshot (gs_bug_snapshot) after first load
+*&  - init_project_detail: saves snapshot (gs_prj_snapshot) after first load
+*&  - status_0300: added SENDMAIL, DL_EVD exclusion logic
+*&  - status_0200: added template download button exclusions (DN_TC/DN_CONF/DN_PROOF)
+*&  - init_evidence_alv: NEW module for subscreen 0350
+*&  - modify_screen_0300: added FNC screen group (Tester/Manager-only fields)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
@@ -10,7 +18,7 @@
 
 *&--- INIT USER ROLE (runs on initial screen 0400, loaded once) ---*
 MODULE init_user_role OUTPUT.
-  " Chỉ load role 1 lần khi khởi động
+  " Load role once at startup
   CHECK gv_role IS INITIAL.
   gv_uname = sy-uname.
   SELECT SINGLE role FROM zbug_users INTO @gv_role
@@ -21,7 +29,9 @@
   ENDIF.
 ENDMODULE.
 
-*&--- SCREEN 0200: BUG LIST (dual mode: Project / My Bugs) ---*
+*&=====================================================================*
+*& SCREEN 0200: BUG LIST (dual mode: Project / My Bugs)
+*&=====================================================================*
 MODULE status_0200 OUTPUT.
   CLEAR gm_excl.
 
@@ -35,10 +45,17 @@
     APPEND 'DELETE' TO gm_excl.
   ENDIF.
 
-  " My Bugs mode: hide CREATE (no project context to assign bug to)
+  " My Bugs mode: hide CREATE + DELETE (no project context)
   IF gv_bug_filter_mode = 'M'.
     APPEND 'CREATE' TO gm_excl.
     APPEND 'DELETE' TO gm_excl.
+  ENDIF.
+
+  " v4.0: Template downloads only for Testers/Managers
+  IF gv_role = 'D'.
+    APPEND 'DN_TC'    TO gm_excl.    " Download Testcase template
+    APPEND 'DN_CONF'  TO gm_excl.    " Download Confirm template
+    APPEND 'DN_PROOF' TO gm_excl.    " Download BugProof template
   ENDIF.
 
   SET PF-STATUS 'STATUS_0200' EXCLUDING gm_excl.
@@ -65,7 +82,7 @@
 MODULE init_bug_list OUTPUT.
   PERFORM select_bug_data.
   IF go_alv_bug IS INITIAL.
-    " Khởi tạo ALV lần đầu
+    " First-time ALV creation
     CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
     CREATE OBJECT go_alv_bug  EXPORTING i_parent = go_cont_bug.
     PERFORM build_bug_fieldcat.
@@ -88,25 +105,39 @@
   ENDIF.
 ENDMODULE.
 
-*&--- SCREEN 0300: BUG DETAIL (Tab Strip) ---*
+*&=====================================================================*
+*& SCREEN 0300: BUG DETAIL (Tab Strip)
+*&=====================================================================*
 MODULE status_0300 OUTPUT.
   CLEAR gm_excl.
-  " Display mode: ẩn SAVE
+  " Display mode: hide SAVE + upload buttons + email + delete evidence
   IF gv_mode = gc_mode_display.
-    APPEND 'SAVE' TO gm_excl.
-  ENDIF.
-  " Tester không upload fix
+    APPEND 'SAVE'     TO gm_excl.
+    APPEND 'SENDMAIL' TO gm_excl.    " v4.0
+  ENDIF.
+  " Tester cannot upload fix
   IF gv_role = 'T'.
     APPEND 'UP_FIX' TO gm_excl.
   ENDIF.
-  " Developer không upload report
+  " Developer cannot upload report
   IF gv_role = 'D'.
     APPEND 'UP_REP' TO gm_excl.
   ENDIF.
-  " Create mode: ẩn status change (chưa có bug_id)
+  " Create mode: hide status change + file uploads + email + delete evidence
   IF gv_mode = gc_mode_create.
     APPEND 'STATUS_CHG' TO gm_excl.
     APPEND 'UP_FILE'    TO gm_excl.
+    APPEND 'UP_REP'     TO gm_excl.
+    APPEND 'UP_FIX'     TO gm_excl.
+    APPEND 'SENDMAIL'   TO gm_excl.    " v4.0: no email for unsaved bug
+    APPEND 'DL_EVD'     TO gm_excl.    " v4.0: no delete evidence before save
+  ENDIF.
+  " Display mode: hide upload + delete evidence
+  IF gv_mode = gc_mode_display.
+    APPEND 'UP_FILE' TO gm_excl.
+    APPEND 'UP_REP'  TO gm_excl.
+    APPEND 'UP_FIX'  TO gm_excl.
+    APPEND 'DL_EVD'  TO gm_excl.       " v4.0
   ENDIF.
   SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.
 
@@ -118,13 +149,23 @@
   SET TITLEBAR 'TITLE_BUGDETAIL' WITH lv_mode_text.
 ENDMODULE.
 
+*&--- LOAD BUG DETAIL (with flag — prevents DB overwrite on tab switch) ---*
 MODULE load_bug_detail OUTPUT.
-  " 1. Đảm bảo subscreen luôn có giá trị hợp lệ
+  " 1. Ensure subscreen + tab have valid defaults
   IF gv_active_subscreen IS INITIAL OR gv_active_subscreen = '0000'.
     gv_active_subscreen = '0310'.
-  ENDIF.
-
-  " 2. Change/Display: load dữ liệu từ DB
+    gv_active_tab       = 'TAB_INFO'.
+  ENDIF.
+
+  " 2. Sync tab strip highlight with active tab (every PBO)
+  ts_detail-activetab = gv_active_tab.
+
+  " 3. Skip DB reload if already loaded (preserves user edits during tab switch)
+  IF gv_detail_loaded = abap_true.
+    RETURN.
+  ENDIF.
+
+  " 4. Change/Display: load data from DB (first time only)
   IF gv_mode <> gc_mode_create AND gv_current_bug_id IS NOT INITIAL.
     SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
       WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
@@ -133,7 +174,7 @@
     ENDIF.
   ENDIF.
 
-  " 3. Create mode: reset work area
+  " 5. Create mode: reset work area with defaults
   IF gv_mode = gc_mode_create.
     CLEAR gs_bug_detail.
     " Pre-fill PROJECT_ID from project context (locked on screen)
@@ -144,7 +185,17 @@
     gs_bug_detail-priority  = 'M'.       " Default priority = Medium
   ENDIF.
 
-  " 4. Populate display text variables for Screen 0310
+  " 6. v4.0: Save snapshot for unsaved changes detection
+  gs_bug_snapshot = gs_bug_detail.
+
+  " 7. Mark as loaded — subsequent PBO calls skip DB read
+  gv_detail_loaded = abap_true.
+ENDMODULE.
+
+*&--- COMPUTE BUG DISPLAY TEXTS (always runs — no DB, in-memory only) ---*
+*& Separated from load_bug_detail so display texts update after
+*& status change without requiring a DB reload.
+MODULE compute_bug_display_texts OUTPUT.
   gv_status_disp = SWITCH #( gs_bug_detail-status
     WHEN gc_st_new        THEN 'New'
     WHEN gc_st_assigned   THEN 'Assigned'
@@ -180,9 +231,10 @@
     ELSE gs_bug_detail-bug_type ).
 ENDMODULE.
 
+*&--- MODIFY SCREEN 0300 (field enable/disable by mode + role) ---*
 MODULE modify_screen_0300 OUTPUT.
   LOOP AT SCREEN.
-    " Readonly mode: disable tất cả fields có group EDT
+    " Readonly mode: disable all fields with group EDT
     IF screen-group1 = 'EDT'.
       IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
         screen-input = 0.
@@ -211,19 +263,33 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " Role-based field restrictions
+    " Role-based field restrictions (group TST / DEV)
     IF screen-group1 = 'TST' AND gv_role = 'D'.
-      " Dev không sửa Tester fields
+      " Dev cannot edit Tester fields
       screen-input = 0. MODIFY SCREEN.
     ENDIF.
     IF screen-group1 = 'DEV' AND gv_role = 'T'.
-      " Tester không sửa Dev fields
+      " Tester cannot edit Dev fields
       screen-input = 0. MODIFY SCREEN.
     ENDIF.
+
+    " v4.0: FNC group — fields only Tester/Manager can edit
+    " (BUG_TYPE, PRIORITY, SEVERITY, DEADLINE)
+    " Developer cannot edit these fields even in Change mode
+    IF screen-group1 = 'FNC'.
+      IF gv_role = 'D'.
+        screen-input = 0. MODIFY SCREEN.
+      ENDIF.
+      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+        screen-input = 0. MODIFY SCREEN.
+      ENDIF.
+    ENDIF.
   ENDLOOP.
 ENDMODULE.
 
-*&--- SUBSCREEN 0310: DESCRIPTION MINI EDITOR ---*
+*&=====================================================================*
+*& SUBSCREEN 0310: Bug Info — Description Mini Editor
+*&=====================================================================*
 MODULE init_desc_mini OUTPUT.
   " Create mini text editor (3-4 lines) for quick description on Bug Info tab
   IF go_desc_mini_cont IS INITIAL.
@@ -231,19 +297,18 @@
     CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
     go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
     go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
-  ENDIF.
-
-  " Load DESC_TEXT content into mini editor
-  IF gs_bug_detail-desc_text IS NOT INITIAL.
+
+    " Load DESC_TEXT into mini editor — ONLY on first creation
+    " (subsequent PBO calls skip this, preserving user edits during tab switch)
     DATA: lt_mini_text TYPE TABLE OF char255.
-    APPEND CONV char255( gs_bug_detail-desc_text ) TO lt_mini_text.
+    IF gs_bug_detail-desc_text IS NOT INITIAL.
+      SPLIT gs_bug_detail-desc_text AT cl_abap_char_utilities=>cr_lf
+        INTO TABLE lt_mini_text.
+    ENDIF.
     go_desc_mini_edit->set_text_as_r3table( table = lt_mini_text ).
-  ELSE.
-    DATA: lt_empty TYPE TABLE OF char255.
-    go_desc_mini_edit->set_text_as_r3table( table = lt_empty ).
-  ENDIF.
-
-  " Disable editing in Display mode or Closed status
+  ENDIF.
+
+  " Readonly mode: set every PBO (may differ between bugs)
   IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
     go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
   ELSE.
@@ -251,10 +316,112 @@
   ENDIF.
 ENDMODULE.
 
-*&--- SCREEN 0400: PROJECT LIST (NEW INITIAL SCREEN) ---*
+*&=====================================================================*
+*& SUBSCREEN 0320: Description Long Text (Text ID Z001)
+*&=====================================================================*
+MODULE init_long_text_desc OUTPUT.
+  IF go_cont_desc IS INITIAL.
+    CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
+    CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
+    go_edit_desc->set_toolbar_mode( cl_gui_textedit=>false ).
+    go_edit_desc->set_statusbar_mode( cl_gui_textedit=>false ).
+    " Load text from DB on first creation only
+    PERFORM load_long_text USING 'Z001'.
+  ENDIF.
+  " Readonly: set every PBO
+  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+    go_edit_desc->set_readonly_mode( cl_gui_textedit=>true ).
+  ELSE.
+    go_edit_desc->set_readonly_mode( cl_gui_textedit=>false ).
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& SUBSCREEN 0330: Dev Note Long Text (Text ID Z002)
+*&=====================================================================*
+MODULE init_long_text_devnote OUTPUT.
+  IF go_cont_dev_note IS INITIAL.
+    CREATE OBJECT go_cont_dev_note EXPORTING container_name = 'CC_DEVNOTE'.
+    CREATE OBJECT go_edit_dev_note EXPORTING parent = go_cont_dev_note.
+    go_edit_dev_note->set_toolbar_mode( cl_gui_textedit=>false ).
+    go_edit_dev_note->set_statusbar_mode( cl_gui_textedit=>false ).
+    " Load text from DB on first creation only
+    PERFORM load_long_text USING 'Z002'.
+  ENDIF.
+  " Readonly: Testers cannot edit Dev Notes; also readonly in display/closed
+  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+     OR gv_role = 'T'.
+    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>true ).
+  ELSE.
+    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>false ).
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& SUBSCREEN 0340: Tester Note Long Text (Text ID Z003)
+*&=====================================================================*
+MODULE init_long_text_tstrnote OUTPUT.
+  IF go_cont_tstr_note IS INITIAL.
+    CREATE OBJECT go_cont_tstr_note EXPORTING container_name = 'CC_TSTRNOTE'.
+    CREATE OBJECT go_edit_tstr_note EXPORTING parent = go_cont_tstr_note.
+    go_edit_tstr_note->set_toolbar_mode( cl_gui_textedit=>false ).
+    go_edit_tstr_note->set_statusbar_mode( cl_gui_textedit=>false ).
+    " Load text from DB on first creation only
+    PERFORM load_long_text USING 'Z003'.
+  ENDIF.
+  " Readonly: Devs cannot edit Tester Notes; also readonly in display/closed
+  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+     OR gv_role = 'D'.
+    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>true ).
+  ELSE.
+    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>false ).
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& v4.0: SUBSCREEN 0350: Evidence ALV (attachment list)
+*&=====================================================================*
+MODULE init_evidence_alv OUTPUT.
+  " Always reload evidence data (files may have been added/deleted)
+  PERFORM load_evidence_data.
+
+  IF go_alv_evidence IS INITIAL.
+    CREATE OBJECT go_cont_evidence EXPORTING container_name = 'CC_EVIDENCE'.
+    CREATE OBJECT go_alv_evidence  EXPORTING i_parent = go_cont_evidence.
+    PERFORM build_evidence_fieldcat.
+    DATA: ls_elayo TYPE lvc_s_layo.
+    ls_elayo-zebra      = 'X'.
+    ls_elayo-cwidth_opt = 'X'.
+    ls_elayo-sel_mode   = 'D'.   " Single-row selection
+    ls_elayo-no_toolbar = ' '.   " Keep toolbar for selection
+    go_alv_evidence->set_table_for_first_display(
+      EXPORTING is_layout      = ls_elayo
+      CHANGING  it_outtab      = gt_evidence
+                it_fieldcatalog = gt_fcat_evidence ).
+    " Register double-click for download
+    IF go_event_handler IS INITIAL.
+      CREATE OBJECT go_event_handler.
+    ENDIF.
+    SET HANDLER go_event_handler->handle_double_click FOR go_alv_evidence.
+  ELSE.
+    go_alv_evidence->refresh_table_display( ).
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& SUBSCREEN 0360: History ALV (readonly)
+*&=====================================================================*
+MODULE init_history_alv OUTPUT.
+  " Delegates to load_history_data which handles both creation and refresh
+  PERFORM load_history_data.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0400: PROJECT LIST (INITIAL SCREEN)
+*&=====================================================================*
 MODULE status_0400 OUTPUT.
   CLEAR gm_excl.
-  " Chỉ Manager được tạo/sửa/xóa Project
+  " Only Manager can create/change/delete projects + upload/download
   IF gv_role <> 'M'.
     APPEND 'CREA_PRJ' TO gm_excl.
     APPEND 'CHNG_PRJ' TO gm_excl.
@@ -289,7 +456,9 @@
   ENDIF.
 ENDMODULE.
 
-*&--- SCREEN 0500: PROJECT DETAIL + TABLE CONTROL ---*
+*&=====================================================================*
+*& SCREEN 0500: PROJECT DETAIL + TABLE CONTROL
+*&=====================================================================*
 MODULE status_0500 OUTPUT.
   CLEAR gm_excl.
   IF gv_role <> 'M'.
@@ -304,7 +473,7 @@
   ENDIF.
   SET PF-STATUS 'STATUS_0500' EXCLUDING gm_excl.
 
-  " Title shows mode (Create/Change/Display)
+  " Title shows mode
   DATA(lv_prj_title) = SWITCH string( gv_mode
     WHEN gc_mode_create  THEN 'Create Project'
     WHEN gc_mode_change  THEN |Change Project: { gs_project-project_name }|
@@ -315,20 +484,34 @@
   SET TITLEBAR 'TITLE_PRJDET' WITH lv_prj_title.
 ENDMODULE.
 
+*&--- LOAD PROJECT DETAIL (with flag — prevents DB reload) ---*
 MODULE init_project_detail OUTPUT.
+  " Skip DB reload if already loaded
+  IF gv_prj_detail_loaded = abap_true.
+    RETURN.
+  ENDIF.
+
   IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
     SELECT SINGLE * FROM zbug_project INTO @gs_project
       WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
     SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
       WHERE project_id = @gv_current_project_id.
   ENDIF.
+
   IF gv_mode = gc_mode_create.
     CLEAR: gs_project, gt_user_project.
     gs_project-project_manager = gv_uname.  " Default manager = current user
     gs_project-project_status  = '1'.       " Opening
   ENDIF.
 
-  " Populate display text for Project Status on Screen 0500
+  " v4.0: Save snapshot for unsaved changes detection
+  gs_prj_snapshot = gs_project.
+
+  gv_prj_detail_loaded = abap_true.
+ENDMODULE.
+
+*&--- COMPUTE PROJECT DISPLAY TEXTS (always runs — no DB) ---*
+MODULE compute_prj_display_texts OUTPUT.
   gv_prj_status_disp = SWITCH #( gs_project-project_status
     WHEN '1' THEN 'Opening'
     WHEN '2' THEN 'In Process'
@@ -337,6 +520,7 @@
     ELSE gs_project-project_status ).
 ENDMODULE.
 
+*&--- MODIFY SCREEN 0500 (field enable/disable) ---*
 MODULE modify_screen_0500 OUTPUT.
   LOOP AT SCREEN.
     IF screen-group1 = 'EDT'.
```

### CODE_TOP.md — modified

`+42 / -7 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -1,5 +1,12 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_TOP — Global Declarations
+*& Include Z_BUG_WS_TOP — Global Declarations (v4.0)
+*&---------------------------------------------------------------------*
+*& v4.0 changes (over v3.0):
+*&  - Evidence ALV objects (go_cont_evidence, go_alv_evidence)
+*&  - Evidence field catalog (gt_fcat_evidence)
+*&  - Evidence ALV type (ty_evidence_alv — metadata only, no CONTENT)
+*&  - Evidence internal table (gt_evidence)
+*&  - Snapshot variables (gs_bug_snapshot, gs_prj_snapshot) for unsaved detection
 *&---------------------------------------------------------------------*
 " === FORWARD DECLARATION ===
 CLASS lcl_event_handler DEFINITION DEFERRED.
@@ -31,7 +38,12 @@
       gv_current_bug_id     TYPE zde_bug_id,
       gv_current_project_id TYPE zde_project_id.
 
-" === BUG LIST FILTER MODE (NEW — Project-first flow) ===
+" === PBO DATA-LOADING FLAGS (v3.0 — prevent reload on tab switch) ===
+" Set to abap_true after first DB load; cleared before each CALL SCREEN
+DATA: gv_detail_loaded     TYPE abap_bool,   " Bug Detail (Screen 0300)
+      gv_prj_detail_loaded TYPE abap_bool.   " Project Detail (Screen 0500)
+
+" === BUG LIST FILTER MODE (Project-first flow) ===
 " 'P' = Project mode (all bugs of a project, no role filter)
 " 'M' = My Bugs mode (cross-project, filtered by role)
 DATA: gv_bug_filter_mode TYPE char1.
@@ -55,6 +67,10 @@
       go_cont_history TYPE REF TO cl_gui_custom_container,
       go_alv_history  TYPE REF TO cl_gui_alv_grid.
 
+" === v4.0: EVIDENCE ALV (Subscreen 0350, container CC_EVIDENCE) ===
+DATA: go_cont_evidence TYPE REF TO cl_gui_custom_container,
+      go_alv_evidence  TYPE REF TO cl_gui_alv_grid.
+
 " === TEXT EDIT OBJECTS (subscreens 0320/0330/0340) ===
 DATA: go_cont_desc      TYPE REF TO cl_gui_custom_container,
       go_edit_desc      TYPE REF TO cl_gui_textedit,
@@ -68,9 +84,10 @@
       go_desc_mini_edit TYPE REF TO cl_gui_textedit.
 
 " === FIELD CATALOGS (Column Definitions) ===
-DATA: gt_fcat_bug     TYPE lvc_t_fcat,
-      gt_fcat_project TYPE lvc_t_fcat,
-      gt_fcat_history TYPE lvc_t_fcat.
+DATA: gt_fcat_bug      TYPE lvc_t_fcat,
+      gt_fcat_project  TYPE lvc_t_fcat,
+      gt_fcat_history  TYPE lvc_t_fcat,
+      gt_fcat_evidence TYPE lvc_t_fcat.    " v4.0
 
 " === INTERNAL TABLES & WORK AREAS ===
 " ALV Bug Data — khớp chính xác với ZBUG_TRACKER fields + display text columns
@@ -83,9 +100,9 @@
          priority         TYPE zde_priority,       " CHAR 1
          priority_text    TYPE char10,             " Display: High/Medium/Low
          severity         TYPE zde_severity,       " CHAR 1
-         severity_text    TYPE char20,             " Display: Dump/VeryHigh/... (NEW)
+         severity_text    TYPE char20,             " Display: Dump/VeryHigh/...
          bug_type         TYPE zde_bug_type,       " CHAR 1
-         bug_type_text    TYPE char20,             " Display: Functional/Performance/... (NEW)
+         bug_type_text    TYPE char20,             " Display: Functional/Performance/...
          tester_id        TYPE zde_username,        " CHAR 12
          verify_tester_id TYPE zde_username,        " CHAR 12
          dev_id           TYPE zde_username,        " CHAR 12
@@ -96,6 +113,9 @@
 
 DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
       gs_bug_detail TYPE zbug_tracker.
+
+" v4.0: Snapshot of bug detail for unsaved changes detection
+DATA: gs_bug_snapshot TYPE zbug_tracker.
 
 " ALV Project Data — khớp với ZBUG_PROJECT fields
 TYPES: BEGIN OF ty_project_alv,
@@ -114,6 +134,9 @@
 DATA: gt_projects TYPE TABLE OF ty_project_alv,
       gs_project  TYPE zbug_project.
 
+" v4.0: Snapshot of project for unsaved changes detection
+DATA: gs_prj_snapshot TYPE zbug_project.
+
 " ALV History Data — khớp với ZBUG_HISTORY fields
 TYPES: BEGIN OF ty_history_alv,
          changed_at   TYPE zde_bug_cr_date,    " DATS 8
@@ -127,6 +150,18 @@
        END OF ty_history_alv.
 
 DATA: gt_history TYPE TABLE OF ty_history_alv.
+
+" v4.0: Evidence ALV Data — metadata only (no CONTENT for performance)
+TYPES: BEGIN OF ty_evidence_alv,
+         evd_id    TYPE numc10,          " Evidence ID
+         file_name TYPE sdok_filnm,      " File name (CHAR 255)
+         mime_type TYPE w3conttype,       " MIME type (CHAR 128)
+         file_size TYPE int4,            " File size in bytes
+         ernam     TYPE ernam,           " Created by
+         erdat     TYPE erdat,           " Created date
+       END OF ty_evidence_alv.
+
+DATA: gt_evidence TYPE TABLE OF ty_evidence_alv.
 
 " === TABLE CONTROL SCREEN 0500 ===
 DATA: gt_user_project TYPE TABLE OF zbug_user_projec,
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
