# Analysis v5

### CODE_F00.md — modified

`+88 / -33 lines`

```diff
--- previous/CODE_F00.md
+++ current/CODE_F00.md
@@ -1,9 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes (v4.0)
-*&---------------------------------------------------------------------*
-*& v4.0 changes (over v3.0):
-*&  - handle_double_click: NEW method for evidence ALV download on dblclick
-*&  - build_evidence_fieldcat: NEW FORM for evidence ALV columns
+*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes
 *&---------------------------------------------------------------------*
 
 CLASS lcl_event_handler DEFINITION.
@@ -16,40 +12,56 @@
       handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
         IMPORTING e_ucomm,
       handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
-        IMPORTING e_row e_column es_row_no.            " v4.0: evidence download
+        IMPORTING e_row e_column es_row_no.
 ENDCLASS.
 
 CLASS lcl_event_handler IMPLEMENTATION.
   METHOD handle_hotspot_click.
-    " Bug List: click Bug ID → mở Bug Detail (Display mode)
+
+    " ===== BUG_ID hotspot — open Bug Detail =====
     IF e_column_id-fieldname = 'BUG_ID'.
-      READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
-      IF sy-subrc = 0.
-        gv_current_bug_id   = ls_bug-bug_id.
-        gv_mode             = gc_mode_display.
-        gv_active_subscreen = '0310'.
-        gv_active_tab       = 'TAB_INFO'.      " v3.0: sync tab highlight
-        CLEAR gv_detail_loaded.                 " v3.0: force fresh load
-        CALL SCREEN 0300.
+      " Search Results screen (0220) reads from gt_search_results
+      IF sy-dynnr = '0220'.
+        READ TABLE gt_search_results INTO DATA(ls_search) INDEX e_row_id-index.
+        IF sy-subrc = 0.
+          gv_current_bug_id   = ls_search-bug_id.
+          gv_mode             = gc_mode_display.
+          gv_active_subscreen = '0310'.
+          gv_active_tab       = 'TAB_INFO'.
+          CLEAR gv_detail_loaded.
+          CALL SCREEN 0300.
+        ENDIF.
+      ELSE.
+        " Standard Bug List (Screen 0200)
+        READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
+        IF sy-subrc = 0.
+          gv_current_bug_id   = ls_bug-bug_id.
+          gv_mode             = gc_mode_display.
+          gv_active_subscreen = '0310'.
+          gv_active_tab       = 'TAB_INFO'.
+          CLEAR gv_detail_loaded.
+          CALL SCREEN 0300.
+        ENDIF.
       ENDIF.
     ENDIF.
 
-    " ----- PROJECT LIST: click Project ID → Bug List (project context) -----
-    " NEW FLOW: Hotspot trên Project ALV → mở Bug List filtered by project
+    " ===== PROJECT_ID hotspot — context depends on which screen =====
     IF e_column_id-fieldname = 'PROJECT_ID'.
-      READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
-      IF sy-subrc = 0.
+      IF sy-dynnr = '0400'.
         " From Project List → open Bug List with project filter
-        gv_current_project_id = ls_prj-project_id.
-        gv_bug_filter_mode    = 'P'.  " Project mode — show ALL bugs of this project
-        CALL SCREEN 0200.
+        READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
+        IF sy-subrc = 0.
+          gv_current_project_id = ls_prj-project_id.
+          gv_bug_filter_mode    = 'P'.  " Project mode — show ALL bugs of this project
+          CALL SCREEN 0200.
+        ENDIF.
       ELSE.
-        " From Bug List → open Project Detail (display mode)
+        " From Bug List (0200/0220) → open Project Detail (display mode)
         READ TABLE gt_bugs INTO DATA(ls_bug2) INDEX e_row_id-index.
         IF sy-subrc = 0 AND ls_bug2-project_id IS NOT INITIAL.
           gv_current_project_id = ls_bug2-project_id.
           gv_mode               = gc_mode_display.
-          CLEAR gv_prj_detail_loaded.            " v3.0: force fresh load
+          CLEAR gv_prj_detail_loaded.
           CALL SCREEN 0500.
         ENDIF.
       ENDIF.
@@ -62,9 +74,8 @@
   METHOD handle_user_command.
   ENDMETHOD.
 
-  " v4.0: Double-click on Evidence ALV → download selected file
+  " Double-click on Evidence ALV → download selected file
   METHOD handle_double_click.
-    " Only fires for go_alv_evidence (registered below in PBO)
     DATA: ls_evidence TYPE ty_evidence_alv.
     READ TABLE gt_evidence INTO ls_evidence INDEX es_row_no-row_id.
     IF sy-subrc = 0.
@@ -100,17 +111,17 @@
   add_fcat 'DEV_ID'           'Developer'       12.
   add_fcat 'CREATED_AT'       'Created'         10.
 
-  " Hotspot trên BUG_ID
+  " Hotspot on BUG_ID
   READ TABLE gt_fcat_bug ASSIGNING FIELD-SYMBOL(<fc>)
     WITH KEY fieldname = 'BUG_ID'.
   IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
 
-  " Hotspot trên PROJECT_ID (click → Project Detail from Bug List)
+  " Hotspot on PROJECT_ID (click → Project Detail from Bug List)
   READ TABLE gt_fcat_bug ASSIGNING <fc>
     WITH KEY fieldname = 'PROJECT_ID'.
   IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
 
-  " Ẩn raw code columns (hiển thị _TEXT thay thế)
+  " Hide raw code columns (display _TEXT instead)
   CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
   ls_fcat-fieldname = 'STATUS'.   ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
   CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
@@ -119,6 +130,50 @@
   ls_fcat-fieldname = 'SEVERITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
   CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
   ls_fcat-fieldname = 'BUG_TYPE'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
+ENDFORM.
+
+*&--- SEARCH RESULTS FIELD CATALOG ---*
+*& Same columns as build_bug_fieldcat but tabname GT_SEARCH_RESULTS
+FORM build_search_fieldcat.
+  DATA: ls_fcat TYPE lvc_s_fcat.
+  CLEAR gt_fcat_search.
+
+  DEFINE add_sfcat.
+    CLEAR ls_fcat.
+    ls_fcat-tabname   = 'GT_SEARCH_RESULTS'.
+    ls_fcat-fieldname = &1.
+    ls_fcat-coltext   = &2.
+    ls_fcat-outputlen = &3.
+    APPEND ls_fcat TO gt_fcat_search.
+  END-OF-DEFINITION.
+
+  add_sfcat 'BUG_ID'           'Bug ID'          12.
+  add_sfcat 'TITLE'            'Title'           40.
+  add_sfcat 'PROJECT_ID'       'Project'         15.
+  add_sfcat 'STATUS_TEXT'      'Status'          15.
+  add_sfcat 'PRIORITY_TEXT'    'Priority'        10.
+  add_sfcat 'SEVERITY_TEXT'    'Severity'        15.
+  add_sfcat 'BUG_TYPE_TEXT'    'Type'            18.
+  add_sfcat 'SAP_MODULE'       'Module'          12.
+  add_sfcat 'TESTER_ID'        'Tester'          12.
+  add_sfcat 'VERIFY_TESTER_ID' 'Verify Tester'   12.
+  add_sfcat 'DEV_ID'           'Developer'       12.
+  add_sfcat 'CREATED_AT'       'Created'         10.
+
+  " Hotspot on BUG_ID (click → Bug Detail from search results)
+  READ TABLE gt_fcat_search ASSIGNING FIELD-SYMBOL(<fc>)
+    WITH KEY fieldname = 'BUG_ID'.
+  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
+
+  " Hide raw code columns
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
+  ls_fcat-fieldname = 'STATUS'.   ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
+  ls_fcat-fieldname = 'PRIORITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
+  ls_fcat-fieldname = 'SEVERITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
+  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
+  ls_fcat-fieldname = 'BUG_TYPE'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
 ENDFORM.
 
 *&--- PROJECT LIST FIELD CATALOG ---*
@@ -143,12 +198,12 @@
   add_fcat_p 'PROJECT_MANAGER' 'Manager'        12.
   add_fcat_p 'NOTE'            'Note'           30.
 
-  " Hotspot trên PROJECT_ID — click → Bug List (project filter)
+  " Hotspot on PROJECT_ID — click → Bug List (project filter)
   READ TABLE gt_fcat_project ASSIGNING FIELD-SYMBOL(<fc>)
     WITH KEY fieldname = 'PROJECT_ID'.
   IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.
 
-  " Ẩn raw status code
+  " Hide raw status code
   CLEAR ls_fcat. ls_fcat-tabname = 'GT_PROJECTS'.
   ls_fcat-fieldname = 'PROJECT_STATUS'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_project.
 ENDFORM.
@@ -176,7 +231,7 @@
   add_hfcat 'REASON'       'Reason'      40.
 ENDFORM.
 
-*&--- v4.0: EVIDENCE FIELD CATALOG ---*
+*&--- EVIDENCE FIELD CATALOG ---*
 FORM build_evidence_fieldcat.
   DATA: ls_fcat TYPE lvc_s_fcat.
   CLEAR gt_fcat_evidence.
@@ -196,4 +251,4 @@
   add_efcat 'FILE_SIZE' 'Size (B)'   12.
   add_efcat 'ERNAM'     'Uploaded By' 12.
   add_efcat 'ERDAT'     'Date'       10.
-ENDFORM.
+ENDFORM.
```

### CODE_F01.md — modified

`+900 / -246 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -1,23 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F01 — Main Business Logic (v4.0 → v4.1 BUGFIX)
-*&---------------------------------------------------------------------*
-*& v4.0 changes (over v3.0):
-*&  - upload_evidence_file/report/fix: REAL implementation (binary → ZBUG_EVIDENCE)
-*&  - load_evidence_data: NEW — SELECT without CONTENT for ALV
-*&  - download_evidence_file: NEW — binary download from ZBUG_EVIDENCE
-*&  - delete_evidence: NEW — popup confirm → DELETE
-*&  - check_evidence_for_status: NEW — file prefix enforcement before transition
-*&  - check_unsaved_bug / check_unsaved_prj: NEW — snapshot comparison
-*&  - send_mail_notification: NEW — real BCS API email
-*&  - save_bug_detail: ENHANCED — severity/priority cross-validation
-*&  - save_project_detail: ENHANCED — completion validation
-*&  - cleanup_detail_editors: ENHANCED — evidence ALV cleanup
-*&
-*& v4.1 BUGFIX changes:
-*&  - save_project_detail: auto-generate PROJECT_ID (PRJ + 7 digits) (Bug #1)
-*&  - add_user_to_project: fix ROLE field (no DDIC ref), validate M/D/T, check project saved (Bug #2)
-*&  - upload_project_excel: move i_tab_raw_data to CHANGING block (Bug #4)
-*&  - save_desc_mini_to_workarea: add cl_gui_cfw=>flush() + EXCEPTIONS (Bug #6)
+*& Include Z_BUG_WS_F01 — Main Business Logic (forms/subroutines)
 *&---------------------------------------------------------------------*
 
 *&=== SELECT BUG DATA (dual mode: Project / My Bugs) ===*
@@ -50,18 +32,19 @@
     ENDCASE.
   ENDIF.
 
-  " Status text mapping (9 states)
+  " Status text mapping (10 states — 6=FinalTesting, V=Resolved)
   LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
     <bug>-status_text = SWITCH #( <bug>-status
-      WHEN gc_st_new        THEN 'New'
-      WHEN gc_st_assigned   THEN 'Assigned'
-      WHEN gc_st_inprogress THEN 'In Progress'
-      WHEN gc_st_pending    THEN 'Pending'
-      WHEN gc_st_fixed      THEN 'Fixed'
-      WHEN gc_st_resolved   THEN 'Resolved'
-      WHEN gc_st_closed     THEN 'Closed'
-      WHEN gc_st_waiting    THEN 'Waiting'
-      WHEN gc_st_rejected   THEN 'Rejected'
+      WHEN gc_st_new          THEN 'New'
+      WHEN gc_st_assigned     THEN 'Assigned'
+      WHEN gc_st_inprogress   THEN 'In Progress'
+      WHEN gc_st_pending      THEN 'Pending'
+      WHEN gc_st_fixed        THEN 'Fixed'
+      WHEN gc_st_finaltesting THEN 'Final Testing'
+      WHEN gc_st_closed       THEN 'Closed'
+      WHEN gc_st_waiting      THEN 'Waiting'
+      WHEN gc_st_rejected     THEN 'Rejected'
+      WHEN gc_st_resolved     THEN 'Resolved'
       ELSE <bug>-status ).
 
     <bug>-priority_text = SWITCH #( <bug>-priority
@@ -85,6 +68,9 @@
   ENDLOOP.
 
   PERFORM set_bug_colors.
+
+  " Calculate dashboard metrics after loading bugs
+  PERFORM calculate_dashboard.
 ENDFORM.
 
 *&=== SELECT PROJECT DATA ===*
@@ -108,8 +94,8 @@
            p~note
       FROM zbug_project AS p
       INNER JOIN zbug_user_projec AS up ON p~project_id = up~project_id
-      INTO CORRESPONDING FIELDS OF TABLE @gt_projects
-      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'.
+      WHERE up~user_id = @gv_uname AND p~is_del <> 'X'
+      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.
   ENDIF.
 
   LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
@@ -128,23 +114,23 @@
 
   " Validate PROJECT_ID is set
   IF gs_bug_detail-project_id IS INITIAL.
-    MESSAGE 'Project ID is required. Bug must belong to a project.' TYPE 'E'.
+    MESSAGE 'Project ID is required. Bug must belong to a project.' TYPE 'S' DISPLAY LIKE 'E'.
     RETURN.
   ENDIF.
 
   " Validate TITLE is set
   IF gs_bug_detail-title IS INITIAL.
-    MESSAGE 'Title is required.' TYPE 'E'.
+    MESSAGE 'Title is required.' TYPE 'S' DISPLAY LIKE 'E'.
     RETURN.
   ENDIF.
 
-  " v4.0: Severity vs Priority cross-validation
+  " Severity vs Priority cross-validation
   " Dump/Critical(1), VeryHigh(2), High(3) → must have Priority = High
   IF gs_bug_detail-severity IS NOT INITIAL
      AND ( gs_bug_detail-severity = '1' OR gs_bug_detail-severity = '2'
            OR gs_bug_detail-severity = '3' ).
     IF gs_bug_detail-priority <> 'H'.
-      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'E'.
+      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'S' DISPLAY LIKE 'E'.
       RETURN.
     ENDIF.
   ENDIF.
@@ -166,12 +152,12 @@
     gs_bug_detail-ernam   = lv_un.
     gs_bug_detail-erdat   = sy-datum.
     gs_bug_detail-erzet   = sy-uzeit.
-    IF gs_bug_detail-status IS INITIAL.
-      gs_bug_detail-status = gc_st_new.
-    ENDIF.
-    IF gs_bug_detail-tester_id IS INITIAL.
-      gs_bug_detail-tester_id = lv_un.
-    ENDIF.
+
+    " FORCE status = New (always), pre-fill created_at + tester_id
+    gs_bug_detail-status     = gc_st_new.
+    gs_bug_detail-created_at = sy-datum.
+    gs_bug_detail-tester_id  = lv_un.
+
     INSERT zbug_tracker FROM @gs_bug_detail.
     IF sy-subrc = 0.
       PERFORM add_history_entry USING gs_bug_detail-bug_id 'CR' '' 'New' 'Bug created'.
@@ -195,13 +181,40 @@
     PERFORM save_long_text USING 'Z001'.  " Description
     PERFORM save_long_text USING 'Z002'.  " Dev Note
     PERFORM save_long_text USING 'Z003'.  " Tester Note
+
+    " Sync desc_text from editor after save_long_text
+    IF go_edit_desc IS NOT INITIAL.
+      DATA: lt_desc_sync TYPE TABLE OF char255.
+      cl_gui_cfw=>flush( ).
+      go_edit_desc->get_text_as_r3table(
+        IMPORTING table = lt_desc_sync
+        EXCEPTIONS OTHERS = 3 ).
+      IF sy-subrc = 0.
+        CLEAR gs_bug_detail-desc_text.
+        LOOP AT lt_desc_sync INTO DATA(lv_sync_line).
+          IF gs_bug_detail-desc_text IS NOT INITIAL.
+            gs_bug_detail-desc_text = gs_bug_detail-desc_text
+              && cl_abap_char_utilities=>cr_lf && lv_sync_line.
+          ELSE.
+            gs_bug_detail-desc_text = lv_sync_line.
+          ENDIF.
+        ENDLOOP.
+      ENDIF.
+    ENDIF.
+
     MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
+
+    " Trigger auto-assign developer after creating new bug
+    IF gv_mode = gc_mode_create.
+      PERFORM auto_assign_developer.
+    ENDIF.
+
     gv_mode = gc_mode_change.
-    " v4.0: Update snapshot after successful save
+    " Update snapshot after successful save
     gs_bug_snapshot = gs_bug_detail.
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Save failed. Please check required fields.' TYPE 'E'.
+    MESSAGE 'Save failed. Please check required fields.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
 
@@ -212,7 +225,7 @@
   DATA: lt_mini TYPE TABLE OF char255,
         lv_text TYPE string.
 
-  " v4.1 BUGFIX #6: Flush GUI control data before reading
+  " Flush GUI control data before reading
   " Without flush, CL_GUI_TEXTEDIT raises POTENTIAL_DATA_LOSS
   cl_gui_cfw=>flush( ).
 
@@ -222,16 +235,18 @@
                error_dp_create = 2
                OTHERS          = 3 ).
   IF sy-subrc <> 0.
-    MESSAGE 'Warning: Could not read description text.' TYPE 'S' DISPLAY LIKE 'W'.
+    " Silently return — control may not be ready yet (no user-facing warning)
     RETURN.
   ENDIF.
 
+  " Concatenate lines without inserting extra line breaks
+  " get_text_as_r3table splits at 255 chars — join with space to preserve long text
   CLEAR lv_text.
   LOOP AT lt_mini INTO DATA(lv_line).
-    IF lv_text IS NOT INITIAL.
-      lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line.
+    IF sy-tabix = 1.
+      lv_text = lv_line.
     ELSE.
-      lv_text = lv_line.
+      lv_text = lv_text && lv_line.
     ENDIF.
   ENDLOOP.
   gs_bug_detail-desc_text = lv_text.
@@ -242,7 +257,7 @@
   DATA: lv_un TYPE sy-uname.
   lv_un = sy-uname.
 
-  " v4.1 BUGFIX #1: Auto-generate PROJECT_ID in Create mode
+  " Auto-generate PROJECT_ID in Create mode
   " (user sees "(Auto)" placeholder — real ID generated here before validation)
   IF gv_mode = gc_mode_create.
     DATA: lv_max_prj TYPE zde_project_id,
@@ -261,24 +276,26 @@
 
   " Validate required fields
   IF gs_project-project_id IS INITIAL.
-    MESSAGE 'Project ID is required.' TYPE 'E'. RETURN.
+    MESSAGE 'Project ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
   ENDIF.
   IF gs_project-project_name IS INITIAL.
-    MESSAGE 'Project Name is required.' TYPE 'E'. RETURN.
-  ENDIF.
-
-  " v4.0: Project completion validation — block Done if unresolved bugs
+    MESSAGE 'Project Name is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+  ENDIF.
+
+  " Project completion validation — block Done if unresolved bugs
+  " gc_st_rejected counts as terminal state (resolved OR closed OR rejected = done)
   IF gs_project-project_status = '3'. " Done
     DATA: lv_open_bugs TYPE i.
     SELECT COUNT(*) FROM zbug_tracker INTO @lv_open_bugs
       WHERE project_id = @gs_project-project_id
         AND is_del <> 'X'
         AND status <> @gc_st_resolved
-        AND status <> @gc_st_closed.
+        AND status <> @gc_st_closed
+        AND status <> @gc_st_rejected.
     IF lv_open_bugs > 0.
       DATA: lv_block_msg TYPE string.
-      lv_block_msg = |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed.|.
-      MESSAGE lv_block_msg TYPE 'E'.
+      lv_block_msg = |Cannot set project to Done. { lv_open_bugs } bug(s) not yet Resolved/Closed/Rejected.|.
+      MESSAGE lv_block_msg TYPE 'S' DISPLAY LIKE 'E'.
       RETURN.
     ENDIF.
   ENDIF.
@@ -303,11 +320,11 @@
     MESSAGE |Project { gs_project-project_id } saved successfully.| TYPE 'S'.
     gv_current_project_id = gs_project-project_id.
     gv_mode = gc_mode_change.
-    " v4.0: Update snapshot after successful save
+    " Update snapshot after successful save
     gs_prj_snapshot = gs_project.
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'E'.
+    MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
 
@@ -318,15 +335,16 @@
     CLEAR <bug>-t_color.
     ls_color-fname = 'STATUS_TEXT'.
     CASE <bug>-status.
-      WHEN gc_st_new.        ls_color-color-col = 1. ls_color-color-int = 0.  " Blue
-      WHEN gc_st_waiting.    ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow
-      WHEN gc_st_assigned.   ls_color-color-col = 7. ls_color-color-int = 0.  " Orange
-      WHEN gc_st_inprogress. ls_color-color-col = 6. ls_color-color-int = 0.  " Purple
-      WHEN gc_st_pending.    ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow
-      WHEN gc_st_fixed.      ls_color-color-col = 5. ls_color-color-int = 0.  " Green
-      WHEN gc_st_resolved.   ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green
-      WHEN gc_st_closed.     ls_color-color-col = 1. ls_color-color-int = 1.  " Grey
-      WHEN gc_st_rejected.   ls_color-color-col = 6. ls_color-color-int = 1.  " Red
+      WHEN gc_st_new.          ls_color-color-col = 1. ls_color-color-int = 0.  " Blue
+      WHEN gc_st_waiting.      ls_color-color-col = 3. ls_color-color-int = 1.  " Yellow
+      WHEN gc_st_assigned.     ls_color-color-col = 7. ls_color-color-int = 0.  " Orange
+      WHEN gc_st_inprogress.   ls_color-color-col = 6. ls_color-color-int = 0.  " Purple
+      WHEN gc_st_pending.      ls_color-color-col = 3. ls_color-color-int = 0.  " Light Yellow
+      WHEN gc_st_fixed.        ls_color-color-col = 5. ls_color-color-int = 0.  " Green
+      WHEN gc_st_finaltesting. ls_color-color-col = 2. ls_color-color-int = 0.  " Cyan
+      WHEN gc_st_resolved.     ls_color-color-col = 4. ls_color-color-int = 1.  " Light Green
+      WHEN gc_st_closed.       ls_color-color-col = 1. ls_color-color-int = 1.  " Grey
+      WHEN gc_st_rejected.     ls_color-color-col = 6. ls_color-color-int = 1.  " Red
     ENDCASE.
     APPEND ls_color TO <bug>-t_color.
   ENDLOOP.
@@ -341,6 +359,18 @@
   IF lt_rows IS INITIAL. RETURN. ENDIF.
   READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
   READ TABLE gt_bugs INTO DATA(ls_bug) INDEX ls_row-row_id.
+  IF sy-subrc = 0. pv_bug_id = ls_bug-bug_id. ENDIF.
+ENDFORM.
+
+*&=== GET SELECTED BUG FROM SEARCH RESULTS ALV ===*
+FORM get_selected_search_bug CHANGING pv_bug_id TYPE zde_bug_id.
+  CLEAR pv_bug_id.
+  CHECK go_search_alv IS NOT INITIAL.
+  DATA: lt_rows TYPE lvc_t_roid.
+  go_search_alv->get_selected_rows( IMPORTING et_row_no = lt_rows ).
+  IF lt_rows IS INITIAL. RETURN. ENDIF.
+  READ TABLE lt_rows INTO DATA(ls_row) INDEX 1.
+  READ TABLE gt_search_results INTO DATA(ls_bug) INDEX ls_row-row_id.
   IF sy-subrc = 0. pv_bug_id = ls_bug-bug_id. ENDIF.
 ENDFORM.
 
@@ -382,7 +412,7 @@
     ENDIF.
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Delete failed.' TYPE 'E'.
+    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
 
@@ -411,7 +441,7 @@
     ENDIF.
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Delete failed.' TYPE 'E'.
+    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
 
@@ -432,116 +462,6 @@
   pv_confirmed = COND #( WHEN lv_answer = '1' THEN abap_true ELSE abap_false ).
 ENDFORM.
 
-*&=== CHANGE BUG STATUS (with 9-state transition validation) ===*
-FORM change_bug_status.
-  " Build allowed transitions based on current status and role
-  DATA: lt_allowed TYPE TABLE OF zde_bug_status,
-        lv_current TYPE zde_bug_status.
-  lv_current = gs_bug_detail-status.
-
-  CASE gv_role.
-    WHEN 'T'. " Tester
-      CASE lv_current.
-        WHEN gc_st_new.      APPEND gc_st_assigned TO lt_allowed.
-                             APPEND gc_st_waiting  TO lt_allowed.
-        WHEN gc_st_fixed.    APPEND gc_st_resolved TO lt_allowed.
-                             APPEND gc_st_rejected TO lt_allowed.
-        WHEN gc_st_resolved. APPEND gc_st_closed   TO lt_allowed.
-      ENDCASE.
-    WHEN 'D'. " Developer
-      CASE lv_current.
-        WHEN gc_st_assigned.   APPEND gc_st_inprogress TO lt_allowed.
-        WHEN gc_st_inprogress. APPEND gc_st_pending    TO lt_allowed.
-                               APPEND gc_st_fixed      TO lt_allowed.
-                               APPEND gc_st_rejected   TO lt_allowed.
-        WHEN gc_st_pending.    APPEND gc_st_inprogress TO lt_allowed.
-      ENDCASE.
-    WHEN 'M'. " Manager: can set any status
-      APPEND gc_st_new        TO lt_allowed.
-      APPEND gc_st_assigned   TO lt_allowed.
-      APPEND gc_st_inprogress TO lt_allowed.
-      APPEND gc_st_pending    TO lt_allowed.
-      APPEND gc_st_fixed      TO lt_allowed.
-      APPEND gc_st_resolved   TO lt_allowed.
-      APPEND gc_st_closed     TO lt_allowed.
-      APPEND gc_st_waiting    TO lt_allowed.
-      APPEND gc_st_rejected   TO lt_allowed.
-  ENDCASE.
-
-  IF lt_allowed IS INITIAL.
-    MESSAGE |No valid transitions available from current status.| TYPE 'W'.
-    RETURN.
-  ENDIF.
-
-  " Use POPUP_GET_VALUES to get new status
-  DATA: lt_fields TYPE TABLE OF sval,
-        ls_field  TYPE sval.
-  ls_field-tabname   = 'ZBUG_TRACKER'.
-  ls_field-fieldname = 'STATUS'.
-  DATA: lv_hint TYPE string.
-  lv_hint = 'Allowed: '.
-  LOOP AT lt_allowed INTO DATA(lv_al).
-    lv_hint = lv_hint && lv_al && ' '.
-  ENDLOOP.
-  ls_field-fieldtext = lv_hint(40).
-  APPEND ls_field TO lt_fields.
-
-  DATA: lv_rc TYPE char1.
-  CALL FUNCTION 'POPUP_GET_VALUES'
-    EXPORTING
-      popup_title  = 'Change Bug Status'
-      start_column = 20
-      start_row    = 5
-    IMPORTING
-      returncode   = lv_rc
-    TABLES
-      fields       = lt_fields.
-  CHECK lv_rc <> 'A'.
-
-  READ TABLE lt_fields INTO ls_field INDEX 1.
-  CHECK ls_field-value IS NOT INITIAL.
-
-  " Validate transition
-  DATA: lv_new_status TYPE zde_bug_status.
-  lv_new_status = ls_field-value.
-  READ TABLE lt_allowed TRANSPORTING NO FIELDS WITH KEY table_line = lv_new_status.
-  IF sy-subrc <> 0 AND gv_role <> 'M'.
-    MESSAGE |Invalid transition: { lv_current } → { lv_new_status }| TYPE 'W'.
-    RETURN.
-  ENDIF.
-
-  " v4.0: Evidence file prefix enforcement before status transition
-  DATA: lv_evd_ok TYPE abap_bool.
-  PERFORM check_evidence_for_status USING lv_new_status CHANGING lv_evd_ok.
-  IF lv_evd_ok = abap_false.
-    RETURN.  " Message already shown by check_evidence_for_status
-  ENDIF.
-
-  DATA: lv_un TYPE sy-uname.
-  lv_un = sy-uname.
-  UPDATE zbug_tracker
-    SET status = @lv_new_status,
-        aenam  = @lv_un,
-        aedat  = @sy-datum,
-        aezet  = @sy-uzeit
-    WHERE bug_id = @gv_current_bug_id.
-  IF sy-subrc = 0.
-    COMMIT WORK.
-    DATA: lv_old_st TYPE string,
-          lv_new_st TYPE string.
-    lv_old_st = lv_current.
-    lv_new_st = lv_new_status.
-    PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
-    gs_bug_detail-status = lv_new_status.
-    " v4.0: Update snapshot to reflect new status
-    gs_bug_snapshot-status = lv_new_status.
-    MESSAGE |Status updated: { lv_current } → { lv_new_status }| TYPE 'S'.
-  ELSE.
-    ROLLBACK WORK.
-    MESSAGE 'Status update failed.' TYPE 'E'.
-  ENDIF.
-ENDFORM.
-
 *&=== ADD HISTORY ENTRY (auto-generate LOG_ID) ===*
 FORM add_history_entry USING pv_bug_id  TYPE zde_bug_id
                              pv_type    TYPE char2
@@ -571,7 +491,7 @@
 
 *&=== PROJECT USER MANAGEMENT: ADD ===*
 FORM add_user_to_project.
-  " v4.1 BUGFIX #1: Check project is saved before adding users
+  " Check project is saved before adding users
   IF gv_current_project_id IS INITIAL.
     MESSAGE 'Save the project first before adding users.' TYPE 'W'.
     RETURN.
@@ -585,9 +505,7 @@
   ls_field-fieldtext = 'SAP Username (USER_ID)'.
   APPEND ls_field TO lt_fields.
 
-  " v4.2 BUGFIX #2: Use SVAL-VALUE (generic CHAR 40, no search help)
-  " to avoid DDIC search help crash on ZBUG_USER_PROJEC-ROLE
-  " and avoid "Field P_ROLE does not belong to table" error
+  " Use SVAL-VALUE (generic CHAR 40, no search help) to avoid DDIC crash
   CLEAR ls_field.
   ls_field-tabname   = 'SVAL'.
   ls_field-fieldname = 'VALUE'.
@@ -614,7 +532,7 @@
     MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
   ENDIF.
 
-  " v4.1 BUGFIX #2: Validate ROLE is M, D, or T
+  " Validate ROLE is M, D, or T
   TRANSLATE lv_role TO UPPER CASE.
   IF lv_role <> 'M' AND lv_role <> 'D' AND lv_role <> 'T'.
     MESSAGE 'Role must be M (Manager), D (Developer), or T (Tester).' TYPE 'W'.
@@ -649,11 +567,23 @@
 ENDFORM.
 
 *&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
+*& Guard: tc_users-current_line defaults to 1 even without a click.
+*& Uses gv_tc_user_selected flag (set in tc_users_modify) to confirm
+*& the user actually interacted with the table control.
 FORM remove_user_from_project.
+  " Require explicit user interaction before allowing remove
+  IF gv_tc_user_selected = abap_false.
+    MESSAGE 'Please click on a user row to select it first.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
   DATA: lv_line TYPE i.
   lv_line = tc_users-current_line.
-  IF lv_line = 0.
-    MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
+
+  " Validate range — prevent deleting wrong row
+  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
+    MESSAGE 'Invalid row selection.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
   ENDIF.
 
   READ TABLE gt_user_project INTO gs_user_project INDEX lv_line.
@@ -671,10 +601,12 @@
   IF sy-subrc = 0.
     COMMIT WORK.
     DELETE gt_user_project INDEX lv_line.
+    " Reset flag after successful remove
+    CLEAR gv_tc_user_selected.
     MESSAGE |User { gs_user_project-user_id } removed.| TYPE 'S'.
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Remove failed.' TYPE 'E'.
+    MESSAGE 'Remove failed.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
 
@@ -695,7 +627,8 @@
       WHEN 'ST' THEN 'Status Change'
       WHEN 'AT' THEN 'Attachment'
       WHEN 'DL' THEN 'Deleted'
-      WHEN 'RJ' THEN 'Rejected' ).
+      WHEN 'RJ' THEN 'Rejected'
+      WHEN 'AA' THEN 'Auto-Assigned' ).
   ENDLOOP.
 
   IF go_alv_history IS INITIAL.
@@ -716,9 +649,10 @@
 ENDFORM.
 
 *&=====================================================================*
-*& CLEANUP: Free all Screen 0300 GUI controls (v4.0)
+*& CLEANUP: Free all Screen 0300 GUI controls
 *& Called on BACK/CANC/EXIT from Bug Detail — ensures clean state
 *& for the next bug opened.
+*& Also cleans up Screen 0370 (trans_note) + Screen 0220 (search ALV)
 *&=====================================================================*
 FORM cleanup_detail_editors.
   " --- Mini description editor (Subscreen 0310) ---
@@ -769,7 +703,7 @@
     CLEAR go_cont_tstr_note.
   ENDIF.
 
-  " --- v4.0: Evidence ALV (Subscreen 0350) ---
+  " --- Evidence ALV (Subscreen 0350) ---
   IF go_alv_evidence IS NOT INITIAL.
     go_alv_evidence->free( ).
     FREE go_alv_evidence.
@@ -793,12 +727,36 @@
     CLEAR go_cont_history.
   ENDIF.
 
+  " --- Transition Note Editor (Screen 0370) ---
+  IF go_edit_trans_note IS NOT INITIAL.
+    go_edit_trans_note->free( ).
+    FREE go_edit_trans_note.
+    CLEAR go_edit_trans_note.
+  ENDIF.
+  IF go_cont_trans_note IS NOT INITIAL.
+    go_cont_trans_note->free( ).
+    FREE go_cont_trans_note.
+    CLEAR go_cont_trans_note.
+  ENDIF.
+
+  " --- Search Results ALV (Screen 0220) ---
+  IF go_search_alv IS NOT INITIAL.
+    go_search_alv->free( ).
+    FREE go_search_alv.
+    CLEAR go_search_alv.
+  ENDIF.
+  IF go_cont_search IS NOT INITIAL.
+    go_cont_search->free( ).
+    FREE go_cont_search.
+    CLEAR go_cont_search.
+  ENDIF.
+
   " --- Clear data-loaded flag so next bug triggers fresh DB load ---
   CLEAR gv_detail_loaded.
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: LOAD EVIDENCE DATA (metadata only — no CONTENT for performance)
+*& LOAD EVIDENCE DATA (metadata only — no CONTENT for performance)
 *& Used by PBO init_evidence_alv module
 *&=====================================================================*
 FORM load_evidence_data.
@@ -813,7 +771,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: UPLOAD EVIDENCE — Common logic for UP_FILE / UP_REP / UP_FIX
+*& UPLOAD EVIDENCE — Common logic for UP_FILE / UP_REP / UP_FIX
 *& pv_att_field: 'EVD' = generic, 'REP' = report, 'FIX' = fix
 *&=====================================================================*
 FORM upload_evidence USING pv_att_field TYPE char3.
@@ -830,10 +788,22 @@
         lv_max_evd_id  TYPE numc10,
         lv_new_evd_id  TYPE numc10.
 
-  " Bug must be saved first (need bug_id for evidence)
+  " Auto-save in create mode before uploading evidence
+  " Evidence needs bug_id (FK). If bug not saved yet, save it first.
   IF gv_current_bug_id IS INITIAL.
-    MESSAGE 'Save the bug first before uploading evidence.' TYPE 'W'.
-    RETURN.
+    IF gv_mode = gc_mode_create.
+      " Auto-validate and save the bug (generates bug_id, switches to Change mode)
+      PERFORM save_desc_mini_to_workarea.
+      PERFORM save_bug_detail.
+      IF gv_current_bug_id IS INITIAL.
+        " Save failed — validation errors already shown via TYPE 'S' DISPLAY LIKE 'E'
+        RETURN.
+      ENDIF.
+      " save_bug_detail already set gv_mode = gc_mode_change
+    ELSE.
+      MESSAGE 'Bug ID not available. Cannot upload evidence.' TYPE 'S' DISPLAY LIKE 'E'.
+      RETURN.
+    ENDIF.
   ENDIF.
 
   " 1. File open dialog
@@ -970,7 +940,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: UPLOAD EVIDENCE FILE (generic — no prefix requirement)
+*& UPLOAD EVIDENCE FILE (generic — no prefix requirement)
 *& Fcode UP_FILE
 *&=====================================================================*
 FORM upload_evidence_file.
@@ -978,7 +948,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: UPLOAD REPORT FILE (Tester uploads test report / bug proof)
+*& UPLOAD REPORT FILE (Tester uploads test report / bug proof)
 *& Fcode UP_REP — also sets ATT_REPORT on ZBUG_TRACKER
 *&=====================================================================*
 FORM upload_report_file.
@@ -986,7 +956,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: UPLOAD FIX FILE (Developer uploads fix package / patch)
+*& UPLOAD FIX FILE (Developer uploads fix package / patch)
 *& Fcode UP_FIX — also sets ATT_FIX on ZBUG_TRACKER
 *&=====================================================================*
 FORM upload_fix_file.
@@ -994,7 +964,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: DOWNLOAD EVIDENCE FILE
+*& DOWNLOAD EVIDENCE FILE
 *& Called from evidence ALV double-click handler
 *&=====================================================================*
 FORM download_evidence_file USING pv_evd_id TYPE numc10.
@@ -1053,7 +1023,7 @@
     EXCEPTIONS OTHERS = 1 ).
   IF sy-subrc = 0.
     MESSAGE |File "{ lv_fname }" downloaded successfully.| TYPE 'S'.
-    " v4.0: Auto-open downloaded file
+    " Auto-open downloaded file
     cl_gui_frontend_services=>execute(
       EXPORTING document = lv_fullpath
       EXCEPTIONS OTHERS = 1 ).
@@ -1063,7 +1033,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: DELETE EVIDENCE (selected row from Evidence ALV)
+*& DELETE EVIDENCE (selected row from Evidence ALV)
 *& Fcode DL_EVD
 *&=====================================================================*
 FORM delete_evidence.
@@ -1104,52 +1074,44 @@
     go_alv_evidence->refresh_table_display( ).
   ELSE.
     ROLLBACK WORK.
-    MESSAGE 'Delete failed.' TYPE 'E'.
-  ENDIF.
-ENDFORM.
-
-*&=====================================================================*
-*& v4.0: CHECK EVIDENCE PREFIX BEFORE STATUS TRANSITION
-*& Enforces file naming convention per status:
-*&   → Fixed(5):    require BUGPROOF_ evidence exists
-*&   → Resolved(6): require TESTCASE_ evidence exists
-*&   → Closed(7):   require CONFIRM_ evidence exists
+    MESSAGE 'Delete failed.' TYPE 'S' DISPLAY LIKE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& CHECK EVIDENCE FOR STATUS TRANSITION
+*&
+*& Rules:
+*&   → Fixed(5): require any evidence file (COUNT > 0)
+*&   → Resolved(V): require any evidence file (COUNT > 0)
+*&   → Other statuses: no evidence check needed
+*&
+*& NOTE: ZBUG_EVIDENCE has NO is_del field — not in WHERE clause.
+*& File prefix enforcement (BUGPROOF_, TESTCASE_, CONFIRM_) not applied.
 *&=====================================================================*
 FORM check_evidence_for_status USING    pv_new_status TYPE zde_bug_status
                                CHANGING pv_ok         TYPE abap_bool.
   pv_ok = abap_true.
   CHECK gv_current_bug_id IS NOT INITIAL.
 
-  DATA: lv_prefix TYPE string,
-        lv_count  TYPE i,
-        lv_like   TYPE sdok_filnm.
-
-  CASE pv_new_status.
-    WHEN gc_st_fixed.     " To Fixed: need bug proof uploaded earlier
-      lv_prefix = 'BUGPROOF_'.
-    WHEN gc_st_resolved.  " To Resolved: need test case result
-      lv_prefix = 'TESTCASE_'.
-    WHEN gc_st_closed.    " To Closed: need confirmation
-      lv_prefix = 'CONFIRM_'.
-    WHEN OTHERS.
-      RETURN.  " No check needed for other transitions
-  ENDCASE.
-
-  " Build LIKE pattern: 'BUGPROOF_%'
-  CONCATENATE lv_prefix '%' INTO lv_like.
-
-  SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
-    WHERE bug_id    = @gv_current_bug_id
-      AND file_name LIKE @lv_like.
-
-  IF lv_count = 0.
-    MESSAGE |Evidence file with prefix "{ lv_prefix }" is required before this status change. Upload first.| TYPE 'W'.
-    pv_ok = abap_false.
-  ENDIF.
-ENDFORM.
-
-*&=====================================================================*
-*& v4.0: CHECK UNSAVED BUG CHANGES (snapshot comparison)
+  " Evidence required for Fixed and Resolved
+  IF pv_new_status = gc_st_fixed OR pv_new_status = gc_st_resolved.
+    DATA: lv_count TYPE i.
+    SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
+      WHERE bug_id = @gv_current_bug_id.
+    IF lv_count = 0.
+      IF pv_new_status = gc_st_fixed.
+        MESSAGE 'Evidence file is required before marking as Fixed. Upload first.' TYPE 'S' DISPLAY LIKE 'W'.
+      ELSE.
+        MESSAGE 'Evidence file is required before marking as Resolved. Upload first.' TYPE 'S' DISPLAY LIKE 'W'.
+      ENDIF.
+      pv_ok = abap_false.
+    ENDIF.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& CHECK UNSAVED BUG CHANGES (snapshot comparison)
 *& Pops up Save/Discard/Cancel if changes detected
 *&=====================================================================*
 FORM check_unsaved_bug CHANGING pv_continue TYPE abap_bool.
@@ -1188,7 +1150,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: CHECK UNSAVED PROJECT CHANGES (snapshot comparison)
+*& CHECK UNSAVED PROJECT CHANGES (snapshot comparison)
 *&=====================================================================*
 FORM check_unsaved_prj CHANGING pv_continue TYPE abap_bool.
   pv_continue = abap_true.
@@ -1223,7 +1185,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& v4.0: SEND EMAIL NOTIFICATION (BCS API — real implementation)
+*& SEND EMAIL NOTIFICATION (BCS API — real implementation)
 *& Sends email to Dev, Tester, Verify Tester with bug details
 *&=====================================================================*
 FORM send_mail_notification.
@@ -1358,8 +1320,8 @@
          END OF ty_upload.
   DATA: lt_upload TYPE TABLE OF ty_upload.
 
-  " v4.1 BUGFIX #4: i_tab_raw_data is a CHANGING parameter (not EXPORTING)
-  " Passing it in EXPORTING block caused CALL_FUNCTION_CONFLICT_TYPE runtime error
+  " i_tab_raw_data is a CHANGING parameter (not EXPORTING)
+  " Passing it in EXPORTING block causes CALL_FUNCTION_CONFLICT_TYPE runtime error
   CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
     EXPORTING
       i_field_seperator    = 'X'
@@ -1452,3 +1414,695 @@
     MESSAGE 'No valid data to upload.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
 ENDFORM.
+
+*&=====================================================================*
+*&=====================================================================*
+*& NEW FORMS
+*&=====================================================================*
+*&=====================================================================*
+
+*&=====================================================================*
+*& SEARCH PROJECTS (Screen 0410 → Screen 0400)
+*&
+*& Filters projects based on s_prj_id, s_prj_mn, s_prj_st.
+*& Security: Manager sees ALL projects (no INNER JOIN).
+*&           Non-Manager uses INNER JOIN with ZBUG_USER_PROJEC.
+*& Results stored in gt_projects.
+*& Sets gv_from_search = abap_true so PBO init_project_list skips
+*& select_project_data (data already loaded).
+*&=====================================================================*
+FORM search_projects.
+  CLEAR gt_projects.
+
+  IF gv_role = 'M'.
+    " Manager sees ALL projects — no security INNER JOIN
+    SELECT p~project_id, p~project_name, p~description,
+           p~project_status, p~project_manager,
+           p~start_date, p~end_date, p~note
+      FROM zbug_project AS p
+      WHERE p~is_del <> 'X'
+        AND ( @s_prj_id IS INITIAL OR p~project_id      = @s_prj_id )
+        AND ( @s_prj_mn IS INITIAL OR p~project_manager  = @s_prj_mn )
+        AND ( @s_prj_st IS INITIAL OR p~project_status   = @s_prj_st )
+      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.
+  ELSE.
+    " Non-Manager: INNER JOIN with ZBUG_USER_PROJEC for security
+    SELECT p~project_id, p~project_name, p~description,
+           p~project_status, p~project_manager,
+           p~start_date, p~end_date, p~note
+      FROM zbug_project AS p
+      INNER JOIN zbug_user_projec AS u ON p~project_id = u~project_id
+      WHERE p~is_del <> 'X'
+        AND u~user_id = @sy-uname
+        AND ( @s_prj_id IS INITIAL OR p~project_id      = @s_prj_id )
+        AND ( @s_prj_mn IS INITIAL OR p~project_manager  = @s_prj_mn )
+        AND ( @s_prj_st IS INITIAL OR p~project_status   = @s_prj_st )
+      INTO CORRESPONDING FIELDS OF TABLE @gt_projects.
+
+    " Remove duplicates (user may have multiple roles in same project)
+    SORT gt_projects BY project_id.
+    DELETE ADJACENT DUPLICATES FROM gt_projects COMPARING project_id.
+  ENDIF.
+
+  " Map status text
+  LOOP AT gt_projects ASSIGNING FIELD-SYMBOL(<prj>).
+    <prj>-status_text = SWITCH #( <prj>-project_status
+      WHEN '1' THEN 'Opening'
+      WHEN '2' THEN 'In Process'
+      WHEN '3' THEN 'Done'
+      WHEN '4' THEN 'Cancelled' ).
+  ENDLOOP.
+
+  " Flag: data already loaded — PBO should NOT call select_project_data
+  gv_from_search = abap_true.
+ENDFORM.
+
+*&=====================================================================*
+*& CALCULATE DASHBOARD (Screen 0200 header metrics)
+*&
+*& Counts gt_bugs by status, priority, and SAP module.
+*& Called from select_bug_data after loading bugs.
+*& Results are displayed on Screen 0200 dashboard header fields.
+*&=====================================================================*
+FORM calculate_dashboard.
+  " Reset all counters
+  CLEAR: gv_dash_total,
+         gv_d_new, gv_d_assigned, gv_d_inprog, gv_d_pending,
+         gv_d_fixed, gv_d_finaltest, gv_d_resolved,
+         gv_d_rejected, gv_d_waiting, gv_d_closed,
+         gv_d_p_high, gv_d_p_med, gv_d_p_low,
+         gv_d_m_fi, gv_d_m_mm, gv_d_m_sd, gv_d_m_abap, gv_d_m_basis.
+
+  gv_dash_total = lines( gt_bugs ).
+
+  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<bug>).
+    " By Status
+    CASE <bug>-status.
+      WHEN gc_st_new.          ADD 1 TO gv_d_new.
+      WHEN gc_st_assigned.     ADD 1 TO gv_d_assigned.
+      WHEN gc_st_inprogress.   ADD 1 TO gv_d_inprog.
+      WHEN gc_st_pending.      ADD 1 TO gv_d_pending.
+      WHEN gc_st_fixed.        ADD 1 TO gv_d_fixed.
+      WHEN gc_st_finaltesting. ADD 1 TO gv_d_finaltest.
+      WHEN gc_st_resolved.     ADD 1 TO gv_d_resolved.
+      WHEN gc_st_rejected.     ADD 1 TO gv_d_rejected.
+      WHEN gc_st_waiting.      ADD 1 TO gv_d_waiting.
+      WHEN gc_st_closed.       ADD 1 TO gv_d_closed.
+    ENDCASE.
+
+    " By Priority
+    CASE <bug>-priority.
+      WHEN 'H'. ADD 1 TO gv_d_p_high.
+      WHEN 'M'. ADD 1 TO gv_d_p_med.
+      WHEN 'L'. ADD 1 TO gv_d_p_low.
+    ENDCASE.
+
+    " By Module
+    CASE <bug>-sap_module.
+      WHEN 'FI'.    ADD 1 TO gv_d_m_fi.
+      WHEN 'MM'.    ADD 1 TO gv_d_m_mm.
+      WHEN 'SD'.    ADD 1 TO gv_d_m_sd.
+      WHEN 'ABAP'.  ADD 1 TO gv_d_m_abap.
+      WHEN 'BASIS'. ADD 1 TO gv_d_m_basis.
+    ENDCASE.
+  ENDLOOP.
+ENDFORM.
+
+*&=====================================================================*
+*& VALIDATE STATUS TRANSITION (Screen 0370 popup)
+*&
+*& Validates the transition matrix before applying:
+*& 1. New status must be selected
+*& 2. Transition must be in allowed list
+*& 3. Role must be authorized
+*& 4. Required fields must be filled (dev_id, trans_note, evidence)
+*&
+*& Sets gv_trans_confirmed = abap_true if all checks pass.
+*& Called from PAI user_command_0370 → CONFIRM fcode.
+*&=====================================================================*
+FORM validate_status_transition.
+  gv_trans_confirmed = abap_false.
+
+  " 1. New status must be selected
+  IF gv_trans_new_status IS INITIAL.
+    MESSAGE 'Please select a new status.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 2. Validate allowed transition (matrix check)
+  DATA: lt_allowed TYPE TABLE OF zde_bug_status.
+  CASE gv_trans_cur_status.
+    WHEN gc_st_new.
+      APPEND gc_st_assigned TO lt_allowed.
+      APPEND gc_st_waiting  TO lt_allowed.
+    WHEN gc_st_waiting.
+      APPEND gc_st_assigned     TO lt_allowed.
+      APPEND gc_st_finaltesting TO lt_allowed.
+    WHEN gc_st_assigned.
+      APPEND gc_st_inprogress TO lt_allowed.
+      APPEND gc_st_rejected   TO lt_allowed.
+    WHEN gc_st_inprogress.
+      APPEND gc_st_fixed      TO lt_allowed.
+      APPEND gc_st_pending    TO lt_allowed.
+      APPEND gc_st_rejected   TO lt_allowed.
+    WHEN gc_st_pending.
+      APPEND gc_st_assigned   TO lt_allowed.
+    WHEN gc_st_finaltesting.
+      APPEND gc_st_resolved   TO lt_allowed.
+      APPEND gc_st_inprogress TO lt_allowed.
+  ENDCASE.
+
+  READ TABLE lt_allowed TRANSPORTING NO FIELDS
+    WITH KEY table_line = gv_trans_new_status.
+  IF sy-subrc <> 0.
+    MESSAGE |Invalid status transition: { gv_trans_cur_status } -> { gv_trans_new_status }| TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 3. Role authorization check (Manager does NOT auto-bypass — role matters)
+  DATA: lv_role_ok TYPE abap_bool VALUE abap_false.
+  CASE gv_trans_cur_status.
+    WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
+      " Only Manager can transition from New/Waiting/Pending
+      IF gv_role = 'M'. lv_role_ok = abap_true. ENDIF.
+    WHEN gc_st_assigned OR gc_st_inprogress.
+      " Dev (assigned to this bug) or Manager
+      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
+        lv_role_ok = abap_true.
+      ENDIF.
+    WHEN gc_st_finaltesting.
+      " Final Tester (assigned verify_tester_id) or Manager
+      IF gs_bug_detail-verify_tester_id = sy-uname OR gv_role = 'M'.
+        lv_role_ok = abap_true.
+      ENDIF.
+  ENDCASE.
+  IF lv_role_ok = abap_false.
+    MESSAGE 'You do not have permission to perform this transition.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 4. Required fields check
+
+  " 4a. DEVELOPER_ID required for → Assigned
+  IF gv_trans_new_status = gc_st_assigned AND gv_trans_dev_id IS INITIAL.
+    MESSAGE 'Developer ID is required for Assigned status.' TYPE 'S' DISPLAY LIKE 'E'.
+    RETURN.
+  ENDIF.
+
+  " 4b. DEVELOPER_ID + FINAL_TESTER_ID required for Waiting → Final Testing
+  IF gv_trans_cur_status = gc_st_waiting AND gv_trans_new_status = gc_st_finaltesting.
+    IF gv_trans_dev_id IS INITIAL.
+      MESSAGE 'Developer ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+    ENDIF.
+    IF gv_trans_ftester_id IS INITIAL.
+      MESSAGE 'Final Tester ID is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+    ENDIF.
+  ENDIF.
+
+  " 4c. TRANS_NOTE required for → Rejected
+  IF gv_trans_new_status = gc_st_rejected.
+    DATA: lt_note_check TYPE TABLE OF char255.
+    IF go_edit_trans_note IS NOT INITIAL.
+      cl_gui_cfw=>flush( ).
+      go_edit_trans_note->get_text_as_r3table(
+        IMPORTING table = lt_note_check
+        EXCEPTIONS OTHERS = 3 ).
+    ENDIF.
+    IF lt_note_check IS INITIAL.
+      MESSAGE 'Rejection reason (note) is required.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+    ENDIF.
+  ENDIF.
+
+  " 4d. Evidence required for → Fixed and → Resolved
+  IF gv_trans_new_status = gc_st_fixed OR gv_trans_new_status = gc_st_resolved.
+    DATA: lv_evd_count TYPE i.
+    SELECT COUNT(*) FROM zbug_evidence INTO @lv_evd_count
+      WHERE bug_id = @gv_current_bug_id.
+    IF lv_evd_count = 0.
+      IF gv_trans_new_status = gc_st_fixed.
+        MESSAGE 'Evidence file is required before marking as Fixed.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+      ELSE.
+        MESSAGE 'Evidence file is required before marking as Resolved.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+      ENDIF.
+    ENDIF.
+  ENDIF.
+
+  " 4e. TRANS_NOTE required for → Resolved (test result note)
+  IF gv_trans_new_status = gc_st_resolved.
+    DATA: lt_note_res TYPE TABLE OF char255.
+    IF go_edit_trans_note IS NOT INITIAL.
+      cl_gui_cfw=>flush( ).
+      go_edit_trans_note->get_text_as_r3table(
+        IMPORTING table = lt_note_res
+        EXCEPTIONS OTHERS = 3 ).
+    ENDIF.
+    IF lt_note_res IS INITIAL.
+      MESSAGE 'Test result note is required for Resolved.' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
+    ENDIF.
+  ENDIF.
+
+  " All checks passed
+  gv_trans_confirmed = abap_true.
+ENDFORM.
+
+*&=====================================================================*
+*& APPLY STATUS TRANSITION (execute the actual change)
+*&
+*& Called from PAI user_command_0370 AFTER validate_status_transition
+*& passes (gv_trans_confirmed = abap_true).
+*&
+*& Actions:
+*& 1. Update gs_bug_detail fields (status, dev_id, verify_tester_id)
+*& 2. Save TRANS_NOTE to Dev Note (Z002) if → Rejected
+*& 3. Save TRANS_NOTE to Tester Note (Z003) if FinalTesting → Resolved/InProgress
+*& 4. UPDATE ZBUG_TRACKER
+*& 5. Log history via add_history_entry
+*& 6. Trigger auto_assign_tester if → Fixed
+*&
+*& NOTE: Uses save_long_text_direct (NOT save_long_text) because
+*& the text comes from go_edit_trans_note popup, not the main editors.
+*&=====================================================================*
+FORM apply_status_transition.
+  DATA: lv_old_status TYPE zde_bug_status.
+  lv_old_status = gs_bug_detail-status.
+
+  " Update bug detail in work area
+  gs_bug_detail-status = gv_trans_new_status.
+
+  " Update developer/tester if provided
+  IF gv_trans_dev_id IS NOT INITIAL.
+    gs_bug_detail-dev_id = gv_trans_dev_id.
+  ENDIF.
+  IF gv_trans_ftester_id IS NOT INITIAL.
+    gs_bug_detail-verify_tester_id = gv_trans_ftester_id.
+  ENDIF.
+
+  " Read transition note text ONCE (single flush + get_text call)
+  DATA: lt_trans_note TYPE gty_t_char255.
+  IF go_edit_trans_note IS NOT INITIAL.
+    cl_gui_cfw=>flush( ).
+    go_edit_trans_note->get_text_as_r3table(
+      IMPORTING table = lt_trans_note
+      EXCEPTIONS OTHERS = 3 ).
+  ENDIF.
+
+  " Save TRANS_NOTE → Dev Note (Z002) if → Rejected
+  IF gv_trans_new_status = gc_st_rejected AND lt_trans_note IS NOT INITIAL.
+    PERFORM save_long_text_direct USING 'Z002' lt_trans_note.
+  ENDIF.
+
+  " Save TRANS_NOTE → Tester Note (Z003) if FinalTesting → Resolved or → InProgress
+  IF gv_trans_cur_status = gc_st_finaltesting AND lt_trans_note IS NOT INITIAL.
+    PERFORM save_long_text_direct USING 'Z003' lt_trans_note.
+  ENDIF.
+
+  " Update timestamps
+  gs_bug_detail-aenam = sy-uname.
+  gs_bug_detail-aedat = sy-datum.
+  gs_bug_detail-aezet = sy-uzeit.
+
+  " Update database
+  UPDATE zbug_tracker FROM @gs_bug_detail.
+  IF sy-subrc = 0.
+    COMMIT WORK.
+
+    " Log history
+    DATA: lv_old_st TYPE string,
+          lv_new_st TYPE string.
+    lv_old_st = lv_old_status.
+    lv_new_st = gv_trans_new_status.
+    PERFORM add_history_entry USING gv_current_bug_id 'ST' lv_old_st lv_new_st 'Status changed'.
+    COMMIT WORK.
+
+    " Update snapshot to reflect new status
+    gs_bug_snapshot = gs_bug_detail.
+
+    " Trigger auto-assign tester if status → Fixed
+    IF gv_trans_new_status = gc_st_fixed.
+      PERFORM auto_assign_tester.
+    ENDIF.
+
+    MESSAGE |Status changed: { lv_old_status } -> { gv_trans_new_status }| TYPE 'S'.
+  ELSE.
+    ROLLBACK WORK.
+    " Revert work area on failure
+    gs_bug_detail-status = lv_old_status.
+    MESSAGE 'Failed to update bug status.' TYPE 'S' DISPLAY LIKE 'E'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& AUTO-ASSIGN DEVELOPER (New → Assigned/Waiting)
+*&
+*& Triggered after save_bug_detail in Create mode.
+*& Algorithm:
+*& 1. Find Developers in same project + same SAP module + active
+*& 2. Count active workload (status IN assigned/inprogress/pending/finaltesting)
+*& 3. Filter devs with workload < 5
+*& 4. Pick the one with least workload → Assigned
+*& 5. If no available dev → Waiting
+*&
+*& Uses add_history_entry. Uses comma-separated SET in UPDATE.
+*& Includes is_active check. Handles empty sap_module gracefully.
+*&=====================================================================*
+FORM auto_assign_developer.
+  " Only trigger for newly created bugs (status = New)
+  CHECK gs_bug_detail-status = gc_st_new.
+
+  TYPES: BEGIN OF ty_dev_workload,
+           user_id  TYPE zde_username,
+           workload TYPE i,
+         END OF ty_dev_workload.
+  DATA: lt_candidates TYPE TABLE OF ty_dev_workload,
+        ls_best       TYPE ty_dev_workload,
+        lv_assign_msg TYPE string.
+
+  " 1. Get Developers in same project + same module + active + not deleted
+  SELECT u~user_id
+    FROM zbug_user_projec AS u
+    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
+    WHERE u~project_id = @gs_bug_detail-project_id
+      AND u~role = 'D'
+      AND usr~is_del <> 'X'
+      AND usr~is_active = 'X'
+      AND ( @gs_bug_detail-sap_module IS INITIAL
+            OR usr~sap_module = @gs_bug_detail-sap_module )
+    INTO TABLE @DATA(lt_devs).
+
+  IF lt_devs IS INITIAL.
+    " No available Dev → set to Waiting
+    gs_bug_detail-status = gc_st_waiting.
+    UPDATE zbug_tracker SET status = @gc_st_waiting
+      WHERE bug_id = @gs_bug_detail-bug_id.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'No developer available'.
+    COMMIT WORK.
+    MESSAGE 'No available developer. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 2. Calculate workload for each Dev
+  LOOP AT lt_devs INTO DATA(ls_dev).
+    DATA: ls_cand TYPE ty_dev_workload.
+    ls_cand-user_id = ls_dev-user_id.
+    SELECT COUNT(*) FROM zbug_tracker
+      WHERE dev_id = @ls_dev-user_id
+        AND status IN (@gc_st_assigned, @gc_st_inprogress, @gc_st_pending, @gc_st_finaltesting)
+        AND is_del <> 'X'.
+    ls_cand-workload = sy-dbcnt.
+    IF ls_cand-workload < 5.
+      APPEND ls_cand TO lt_candidates.
+    ENDIF.
+  ENDLOOP.
+
+  IF lt_candidates IS INITIAL.
+    " All Devs overloaded (workload >= 5) → Waiting
+    gs_bug_detail-status = gc_st_waiting.
+    UPDATE zbug_tracker SET status = @gc_st_waiting
+      WHERE bug_id = @gs_bug_detail-bug_id.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'All developers overloaded'.
+    COMMIT WORK.
+    MESSAGE 'All developers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 3. Pick Dev with lowest workload
+  SORT lt_candidates BY workload ASCENDING.
+  READ TABLE lt_candidates INTO ls_best INDEX 1.
+
+  " 4. Assign developer + update status to Assigned
+  gs_bug_detail-dev_id = ls_best-user_id.
+  gs_bug_detail-status = gc_st_assigned.
+  UPDATE zbug_tracker
+    SET dev_id = @ls_best-user_id,
+        status = @gc_st_assigned
+    WHERE bug_id = @gs_bug_detail-bug_id.
+  COMMIT WORK.
+  lv_assign_msg = |Auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })|.
+  PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_assigned
+    lv_assign_msg.
+  COMMIT WORK.
+
+  " Update snapshot
+  gs_bug_snapshot = gs_bug_detail.
+
+  MESSAGE |Bug auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })| TYPE 'S'.
+ENDFORM.
+
+*&=====================================================================*
+*& AUTO-ASSIGN TESTER (Fixed → Final Testing/Waiting)
+*&
+*& Triggered from apply_status_transition when status → Fixed.
+*& Algorithm:
+*& 1. Find Testers in same project + same SAP module + active
+*& 2. Count active workload (verify_tester_id with status = FinalTesting)
+*& 3. Filter testers with workload < 5
+*& 4. Pick the one with least workload → Final Testing
+*& 5. If no available tester → Waiting
+*&
+*& Uses add_history_entry. Uses comma-separated SET in UPDATE.
+*&=====================================================================*
+FORM auto_assign_tester.
+  " Only trigger when status = Fixed
+  CHECK gs_bug_detail-status = gc_st_fixed.
+
+  TYPES: BEGIN OF ty_tst_workload,
+           user_id  TYPE zde_username,
+           workload TYPE i,
+         END OF ty_tst_workload.
+  DATA: lt_candidates TYPE TABLE OF ty_tst_workload,
+        ls_best       TYPE ty_tst_workload,
+        lv_assign_msg TYPE string.
+
+  " 1. Get Testers in same project + same module + active + not deleted
+  SELECT u~user_id
+    FROM zbug_user_projec AS u
+    INNER JOIN zbug_users AS usr ON u~user_id = usr~user_id
+    WHERE u~project_id = @gs_bug_detail-project_id
+      AND u~role = 'T'
+      AND usr~is_del <> 'X'
+      AND usr~is_active = 'X'
+      AND ( @gs_bug_detail-sap_module IS INITIAL
+            OR usr~sap_module = @gs_bug_detail-sap_module )
+    INTO TABLE @DATA(lt_testers).
+
+  IF lt_testers IS INITIAL.
+    " No available Tester → Waiting
+    gs_bug_detail-status = gc_st_waiting.
+    UPDATE zbug_tracker SET status = @gc_st_waiting
+      WHERE bug_id = @gs_bug_detail-bug_id.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_waiting 'No tester available'.
+    COMMIT WORK.
+    " Update snapshot
+    gs_bug_snapshot = gs_bug_detail.
+    MESSAGE 'No available tester. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 2. Calculate workload for each Tester
+  LOOP AT lt_testers INTO DATA(ls_tst).
+    DATA: ls_cand TYPE ty_tst_workload.
+    ls_cand-user_id = ls_tst-user_id.
+    SELECT COUNT(*) FROM zbug_tracker
+      WHERE verify_tester_id = @ls_tst-user_id
+        AND status = @gc_st_finaltesting
+        AND is_del <> 'X'.
+    ls_cand-workload = sy-dbcnt.
+    IF ls_cand-workload < 5.
+      APPEND ls_cand TO lt_candidates.
+    ENDIF.
+  ENDLOOP.
+
+  IF lt_candidates IS INITIAL.
+    " All Testers overloaded → Waiting
+    gs_bug_detail-status = gc_st_waiting.
+    UPDATE zbug_tracker SET status = @gc_st_waiting
+      WHERE bug_id = @gs_bug_detail-bug_id.
+    COMMIT WORK.
+    PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_waiting 'All testers overloaded'.
+    COMMIT WORK.
+    gs_bug_snapshot = gs_bug_detail.
+    MESSAGE 'All testers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
+  " 3. Pick Tester with lowest workload
+  SORT lt_candidates BY workload ASCENDING.
+  READ TABLE lt_candidates INTO ls_best INDEX 1.
+
+  " 4. Assign tester + update status to Final Testing
+  gs_bug_detail-verify_tester_id = ls_best-user_id.
+  gs_bug_detail-status = gc_st_finaltesting.
+  UPDATE zbug_tracker
+    SET verify_tester_id = @ls_best-user_id,
+        status = @gc_st_finaltesting
+    WHERE bug_id = @gs_bug_detail-bug_id.
+  COMMIT WORK.
+  lv_assign_msg = |Auto-assigned to tester { ls_best-user_id } (workload: { ls_best-workload })|.
+  PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_finaltesting
+    lv_assign_msg.
+  COMMIT WORK.
+
+  " Update snapshot
+  gs_bug_snapshot = gs_bug_detail.
+
+  MESSAGE |Bug auto-assigned to tester { ls_best-user_id } for Final Testing| TYPE 'S'.
+ENDFORM.
+
+*&=====================================================================*
+*& EXECUTE BUG SEARCH (Screen 0210 → results in gt_search_results)
+*&
+*& Search filters: s_bug_id, s_title, s_status, s_prio, s_mod,
+*&                 s_reporter, s_dev
+*& Security: scoped to current project (gv_current_project_id).
+*& Results in gt_search_results (ty_bug_alv) with text mapping.
+*&
+*& NOTE: Title wildcard uses CP operator in a LOOP (not in SQL —
+*& CP not valid in Open SQL). Pattern: *term* for CP matching.
+*& Sets gv_search_executed = abap_true so PAI navigates to 0220
+*& after the modal dialog closes.
+*&=====================================================================*
+FORM execute_bug_search.
+  CLEAR gt_search_results.
+
+  " Build title pattern for CP operator: surround with *
+  DATA: lv_title_pattern TYPE string.
+  IF s_title IS NOT INITIAL.
+    lv_title_pattern = '*' && s_title && '*'.
+    TRANSLATE lv_title_pattern TO UPPER CASE.
+  ENDIF.
+
+  " SELECT into gt_search_results (ty_bug_alv via CORRESPONDING FIELDS)
+  SELECT * FROM zbug_tracker
+    WHERE is_del <> 'X'
+      AND project_id = @gv_current_project_id
+      AND ( @s_bug_id   IS INITIAL OR bug_id    = @s_bug_id )
+      AND ( @s_status   IS INITIAL OR status    = @s_status )
+      AND ( @s_prio     IS INITIAL OR priority  = @s_prio )
+      AND ( @s_mod      IS INITIAL OR sap_module = @s_mod )
+      AND ( @s_reporter IS INITIAL OR tester_id = @s_reporter )
+      AND ( @s_dev      IS INITIAL OR dev_id    = @s_dev )
+    INTO CORRESPONDING FIELDS OF TABLE @gt_search_results.
+
+  " Title wildcard filter (post-SELECT — CP operator not valid in SQL)
+  IF lv_title_pattern IS NOT INITIAL.
+    DATA: lt_keep TYPE TABLE OF ty_bug_alv.
+    LOOP AT gt_search_results ASSIGNING FIELD-SYMBOL(<sr>).
+      DATA: lv_title_upper TYPE string.
+      lv_title_upper = <sr>-title.
+      TRANSLATE lv_title_upper TO UPPER CASE.
+      IF lv_title_upper CP lv_title_pattern.
+        APPEND <sr> TO lt_keep.
+      ENDIF.
+    ENDLOOP.
+    gt_search_results = lt_keep.
+  ENDIF.
+
+  " Text mapping loop (same as select_bug_data)
+  LOOP AT gt_search_results ASSIGNING FIELD-SYMBOL(<bug>).
+    <bug>-status_text = SWITCH #( <bug>-status
+      WHEN gc_st_new          THEN 'New'
+      WHEN gc_st_assigned     THEN 'Assigned'
+      WHEN gc_st_inprogress   THEN 'In Progress'
+      WHEN gc_st_pending      THEN 'Pending'
+      WHEN gc_st_fixed        THEN 'Fixed'
+      WHEN gc_st_finaltesting THEN 'Final Testing'
+      WHEN gc_st_closed       THEN 'Closed'
+      WHEN gc_st_waiting      THEN 'Waiting'
+      WHEN gc_st_rejected     THEN 'Rejected'
+      WHEN gc_st_resolved     THEN 'Resolved'
+      ELSE <bug>-status ).
+
+    <bug>-priority_text = SWITCH #( <bug>-priority
+      WHEN 'H' THEN 'High'
+      WHEN 'M' THEN 'Medium'
+      WHEN 'L' THEN 'Low' ).
+
+    <bug>-severity_text = SWITCH #( <bug>-severity
+      WHEN '1' THEN 'Dump/Critical'
+      WHEN '2' THEN 'Very High'
+      WHEN '3' THEN 'High'
+      WHEN '4' THEN 'Normal'
+      WHEN '5' THEN 'Minor' ).
+
+    <bug>-bug_type_text = SWITCH #( <bug>-bug_type
+      WHEN '1' THEN 'Functional'
+      WHEN '2' THEN 'Performance'
+      WHEN '3' THEN 'UI/UX'
+      WHEN '4' THEN 'Integration'
+      WHEN '5' THEN 'Security' ).
+  ENDLOOP.
+
+  IF gt_search_results IS INITIAL.
+    MESSAGE 'No bugs found matching criteria.' TYPE 'S' DISPLAY LIKE 'W'.
+  ELSE.
+    MESSAGE |Found { lines( gt_search_results ) } bug(s).| TYPE 'S'.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*&=====================================================================*
+*& MODIFY SCREEN 0370 — PBO helper for field enable/disable
+*&
+*& Read-only fields: BUG_ID, TITLE, REPORTER, CURRENT_STATUS — always locked
+*& NEW_STATUS: always open (F4 will filter by allowed transitions)
+*& DEVELOPER_ID: open when current status = New/Waiting/Pending
+*& FINAL_TESTER_ID: open when current status = Waiting
+*& TRANS_NOTE editor: enabled for Assigned/InProgress/FinalTesting
+*&
+*& Called from PBO MODULE init_trans_popup.
+*&=====================================================================*
+FORM modify_screen_0370.
+  LOOP AT SCREEN.
+    " Read-only fields: always locked
+    IF screen-name CS 'GV_TRANS_BUG_ID' OR screen-name CS 'GV_TRANS_TITLE'
+       OR screen-name CS 'GV_TRANS_REPORTER' OR screen-name CS 'GV_TRANS_CUR_'.
+      screen-input = 0.
+      MODIFY SCREEN.
+      CONTINUE.
+    ENDIF.
+
+    " NEW_STATUS: always open (F4 enforces transition matrix)
+    IF screen-name CS 'GV_TRANS_NEW_STATUS'.
+      screen-input = 1.
+      MODIFY SCREEN.
+      CONTINUE.
+    ENDIF.
+
+    " DEVELOPER_ID: enable when Manager needs to assign dev
+    IF screen-name CS 'GV_TRANS_DEV_ID'.
+      CASE gv_trans_cur_status.
+        WHEN gc_st_new OR gc_st_waiting OR gc_st_pending.
+          screen-input = 1.   " Open
+        WHEN OTHERS.
+          screen-input = 0.   " Locked
+      ENDCASE.
+      MODIFY SCREEN.
+      CONTINUE.
+    ENDIF.
+
+    " FINAL_TESTER_ID: enable only when current status = Waiting
+    IF screen-name CS 'GV_TRANS_FTESTER_ID'.
+      CASE gv_trans_cur_status.
+        WHEN gc_st_waiting.
+          screen-input = 1.   " Open (Manager can manually assign tester)
+        WHEN OTHERS.
+          screen-input = 0.   " Locked
+      ENDCASE.
+      MODIFY SCREEN.
+      CONTINUE.
+    ENDIF.
+  ENDLOOP.
+
+  " Enable/disable TRANS_NOTE text editor based on current status
+  IF go_edit_trans_note IS NOT INITIAL.
+    CASE gv_trans_cur_status.
+      WHEN gc_st_assigned OR gc_st_inprogress OR gc_st_finaltesting.
+        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>false ). " Editable
+      WHEN OTHERS.
+        go_edit_trans_note->set_readonly_mode( cl_gui_textedit=>true ).  " Read-only
+    ENDCASE.
+  ENDIF.
+ENDFORM.
```

### CODE_F02.md — modified

`+355 / -96 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -1,21 +1,12 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads (v4.0 → v4.1 BUGFIX)
+*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads
 *&---------------------------------------------------------------------*
-*& v4.0 changes:
-*&  - NEW: f4_date — Calendar popup for date fields (Feature #4)
-*&  - NEW: download_smw0_template — Generic SMW0 download + auto-open (Feature #10)
-*&  - NEW: download_testcase_template  (ZTEMPLATE_TESTCASE)  (Feature #7)
-*&  - NEW: download_confirm_template   (ZTEMPLATE_CONFIRM)   (Feature #7)
-*&  - NEW: download_bugproof_template  (ZTEMPLATE_BUGPROOF)  (Feature #7)
-*&  - ENHANCED: download_project_template — refactored to use generic helper
-*&
-*& v4.1 BUGFIX changes:
-*&  - NEW: f4_project_status — F4 help for project status dropdown (Bug #1)
-*&  - load_long_text: added EXCEPTIONS to set_text_as_r3table (Bug #6)
-*&  - save_long_text: added cl_gui_cfw=>flush() + EXCEPTIONS to get_text_as_r3table (Bug #6)
-*&---------------------------------------------------------------------*
-
-*&=== F4: PROJECT ID ===*
+
+*&=====================================================================*
+*& F4 VALUE HELPS — Existing
+*&=====================================================================*
+
+*&=== F4: PROJECT ID (for Screen 0300/0500) ===*
 FORM f4_project_id USING pv_fn TYPE dynfnam.
   TYPES: BEGIN OF ty_prj_f4,
            project_id   TYPE zde_project_id,
@@ -72,7 +63,7 @@
       OTHERS          = 1.
 ENDFORM.
 
-*&=== F4: BUG STATUS ===*
+*&=== F4: BUG STATUS (10 states — 6=FinalTesting, V=Resolved) ===*
 FORM f4_status USING pv_fn TYPE dynfnam.
   TYPES: BEGIN OF ty_st_f4,
            code TYPE char2,
@@ -81,15 +72,16 @@
   DATA: lt_ret TYPE TABLE OF ddshretval,
         lt_val TYPE TABLE OF ty_st_f4.
 
-  APPEND VALUE ty_st_f4( code = '1' text = 'New' )        TO lt_val.
-  APPEND VALUE ty_st_f4( code = '2' text = 'Assigned' )   TO lt_val.
-  APPEND VALUE ty_st_f4( code = '3' text = 'In Progress' ) TO lt_val.
-  APPEND VALUE ty_st_f4( code = '4' text = 'Pending' )    TO lt_val.
-  APPEND VALUE ty_st_f4( code = '5' text = 'Fixed' )      TO lt_val.
-  APPEND VALUE ty_st_f4( code = '6' text = 'Resolved' )   TO lt_val.
-  APPEND VALUE ty_st_f4( code = '7' text = 'Closed' )     TO lt_val.
-  APPEND VALUE ty_st_f4( code = 'W' text = 'Waiting' )    TO lt_val.
-  APPEND VALUE ty_st_f4( code = 'R' text = 'Rejected' )   TO lt_val.
+  APPEND VALUE ty_st_f4( code = '1' text = 'New' )            TO lt_val.
+  APPEND VALUE ty_st_f4( code = '2' text = 'Assigned' )       TO lt_val.
+  APPEND VALUE ty_st_f4( code = '3' text = 'In Progress' )    TO lt_val.
+  APPEND VALUE ty_st_f4( code = '4' text = 'Pending' )        TO lt_val.
+  APPEND VALUE ty_st_f4( code = '5' text = 'Fixed' )          TO lt_val.
+  APPEND VALUE ty_st_f4( code = '6' text = 'Final Testing' )  TO lt_val.
+  APPEND VALUE ty_st_f4( code = '7' text = 'Closed' )         TO lt_val.
+  APPEND VALUE ty_st_f4( code = 'W' text = 'Waiting' )        TO lt_val.
+  APPEND VALUE ty_st_f4( code = 'R' text = 'Rejected' )       TO lt_val.
+  APPEND VALUE ty_st_f4( code = 'V' text = 'Resolved' )       TO lt_val.
 
   CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
     EXPORTING
@@ -190,11 +182,7 @@
       OTHERS          = 1.
 ENDFORM.
 
-*&=====================================================================*
-*& v4.1 BUGFIX #1: F4 PROJECT STATUS
-*& Dropdown for project status field on Screen 0500
-*& Called from POV module f4_prj_status → CODE_PAI.md
-*&=====================================================================*
+*&=== F4: PROJECT STATUS (for Screen 0500) ===*
 FORM f4_project_status USING pv_fn TYPE dynfnam.
   TYPES: BEGIN OF ty_pst_f4,
            code TYPE char1,
@@ -223,7 +211,7 @@
 ENDFORM.
 
 *&=====================================================================*
-*& F4 DATE CALENDAR POPUP (v4.0 — Feature #4)
+*& F4 DATE CALENDAR POPUP
 *&
 *& Shows SAP calendar popup and assigns selected date to the
 *& appropriate global structure field based on pv_field_name.
@@ -234,9 +222,6 @@
 *&
 *& NOTE: Bug date fields (DEADLINE, START_DATE) do NOT exist in
 *&       ZBUG_TRACKER per SE11. Only project dates are supported.
-*&
-*& Pattern from ZPG_BUGTRACKING_DETAIL (MODULE f4_date / f4_startdate):
-*& Assigns directly to structure field — screen picks up new value on PBO.
 *&=====================================================================*
 FORM f4_date USING pv_field_name TYPE char20.
   DATA: lv_selected_date TYPE dats.
@@ -264,9 +249,233 @@
   ENDCASE.
 ENDFORM.
 
+*&=====================================================================*
+*& NEW F4 VALUE HELPS
+*&=====================================================================*
+
+*&=== F4: SAP MODULE (for Screen 0310) ===*
+*& Static list of SAP modules.
+*& Called from PAI MODULE f4_bug_sapmodule → PERFORM f4_sap_module USING ...
+FORM f4_sap_module USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_mod_f4,
+           sap_module TYPE zde_sap_module,
+         END OF ty_mod_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_mod_f4.
+
+  lt_val = VALUE #(
+    ( sap_module = 'FI' )
+    ( sap_module = 'MM' )
+    ( sap_module = 'SD' )
+    ( sap_module = 'ABAP' )
+    ( sap_module = 'BASIS' )
+    ( sap_module = 'PP' )
+    ( sap_module = 'HR' )
+    ( sap_module = 'QM' )
+    ( sap_module = 'CO' )
+    ( sap_module = 'PM' )
+    ( sap_module = 'WM' )
+    ( sap_module = 'PS' ) ).
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'SAP_MODULE'
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
+*&=== F4: PROJECT ID HELP (for Screen 0410 search) ===*
+*& Same logic as f4_project_id but separate form name for PAI module clarity.
+*& Called from PAI MODULE f4_project_id → PERFORM f4_project_id_help USING 'S_PRJ_ID'
+FORM f4_project_id_help USING pv_fn TYPE dynfnam.
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
+*&=== F4: MANAGER HELP (for Screen 0410 search) ===*
+*& Filters ZBUG_USERS by role = 'M' (Manager).
+*& Called from PAI MODULE f4_manager → PERFORM f4_manager_help USING 'S_PRJ_MN'
+FORM f4_manager_help USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_mgr_f4,
+           user_id   TYPE zde_username,
+           full_name TYPE zde_bug_full_name,
+         END OF ty_mgr_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_mgr_f4.
+
+  SELECT user_id, full_name FROM zbug_users
+    INTO CORRESPONDING FIELDS OF TABLE @lt_val
+    WHERE role = 'M' AND is_del <> 'X'
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
+*&=== F4: PROJECT STATUS HELP (for Screen 0410 search) ===*
+*& Same logic as f4_project_status but separate form name for PAI module clarity.
+*& Called from PAI MODULE f4_project_status → PERFORM f4_project_status_help USING 'S_PRJ_ST'
+FORM f4_project_status_help USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_st_f4,
+           status TYPE char1,
+           text   TYPE char20,
+         END OF ty_st_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_st_f4.
+
+  lt_val = VALUE #(
+    ( status = '1' text = 'Opening' )
+    ( status = '2' text = 'In Process' )
+    ( status = '3' text = 'Done' )
+    ( status = '4' text = 'Cancelled' ) ).
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'STATUS'
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
+*&=====================================================================*
+*& F4: TRANSITION STATUS (for Screen 0370 popup)
+*&
+*& Shows ONLY valid target statuses based on current status
+*& (gv_trans_cur_status) + user role (gv_role).
+*& Enforces the transition matrix at the UI level.
+*&
+*& Called from PAI MODULE f4_trans_status_mod → PERFORM f4_trans_status
+*& Note: hardcoded dynprofield = 'GV_TRANS_NEW_STATUS' (Screen 0370)
+*&=====================================================================*
+FORM f4_trans_status.
+  TYPES: BEGIN OF ty_st_f4,
+           status TYPE zde_bug_status,
+           text   TYPE char20,
+         END OF ty_st_f4.
+  DATA: lt_val TYPE TABLE OF ty_st_f4,
+        lt_ret TYPE TABLE OF ddshretval.
+
+  " Build allowed list based on current status + role
+  CASE gv_trans_cur_status.
+    WHEN gc_st_new.        " New → Assigned, Waiting (Manager only)
+      IF gv_role = 'M'.
+        lt_val = VALUE #(
+          ( status = gc_st_assigned text = 'Assigned' )
+          ( status = gc_st_waiting  text = 'Waiting' ) ).
+      ENDIF.
+
+    WHEN gc_st_waiting.    " Waiting → Assigned, FinalTesting (Manager only)
+      IF gv_role = 'M'.
+        lt_val = VALUE #(
+          ( status = gc_st_assigned     text = 'Assigned' )
+          ( status = gc_st_finaltesting text = 'Final Testing' ) ).
+      ENDIF.
+
+    WHEN gc_st_assigned.   " Assigned → InProgress, Rejected (Dev assigned or Manager)
+      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
+        lt_val = VALUE #(
+          ( status = gc_st_inprogress text = 'In Progress' )
+          ( status = gc_st_rejected   text = 'Rejected' ) ).
+      ENDIF.
+
+    WHEN gc_st_inprogress. " InProgress → Fixed, Pending, Rejected (Dev assigned or Manager)
+      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
+        lt_val = VALUE #(
+          ( status = gc_st_fixed    text = 'Fixed' )
+          ( status = gc_st_pending  text = 'Pending' )
+          ( status = gc_st_rejected text = 'Rejected' ) ).
+      ENDIF.
+
+    WHEN gc_st_pending.    " Pending → Assigned (Manager only)
+      IF gv_role = 'M'.
+        lt_val = VALUE #(
+          ( status = gc_st_assigned text = 'Assigned' ) ).
+      ENDIF.
+
+    WHEN gc_st_finaltesting. " FinalTesting → Resolved, InProgress (FinalTester or Manager)
+      IF gs_bug_detail-verify_tester_id = sy-uname OR gv_role = 'M'.
+        lt_val = VALUE #(
+          ( status = gc_st_resolved   text = 'Resolved' )
+          ( status = gc_st_inprogress text = 'In Progress' ) ).
+      ENDIF.
+
+    " Fixed(5), Resolved(V), Closed(7), Rejected(R) → terminal/automatic, no manual transitions
+  ENDCASE.
+
+  IF lt_val IS INITIAL.
+    MESSAGE 'No valid transitions available for your role.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield        = 'STATUS'
+      dynpprog        = sy-repid
+      dynpnr          = sy-dynnr
+      dynprofield     = 'GV_TRANS_NEW_STATUS'
+      value_org       = 'S'
+    TABLES
+      value_tab       = lt_val
+      return_tab      = lt_ret
+    EXCEPTIONS
+      OTHERS          = 1.
+ENDFORM.
+
+*&=====================================================================*
+*& LONG TEXT OPERATIONS
+*&=====================================================================*
+
 *&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
-" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
-" Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
+*& pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
+*& Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
+*&
+*& Explicit lv_tdname TYPE tdobname cast to prevent CALL_FUNCTION_CONFLICT_TYPE:
+*& gv_current_bug_id is CHAR 10, but READ_TEXT NAME expects TDOBNAME = CHAR 70.
 FORM load_long_text USING pv_text_id TYPE thead-tdid.
   CHECK gv_current_bug_id IS NOT INITIAL.
 
@@ -282,11 +491,15 @@
   DATA: lt_lines TYPE TABLE OF tline,
         ls_line  TYPE tline.
 
+  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
+  DATA: lv_tdname TYPE tdobname.
+  lv_tdname = gv_current_bug_id.
+
   CALL FUNCTION 'READ_TEXT'
     EXPORTING
       id       = pv_text_id
       language = sy-langu
-      name     = gv_current_bug_id
+      name     = lv_tdname
       object   = 'ZBUG'
     TABLES
       lines    = lt_lines
@@ -307,8 +520,10 @@
 ENDFORM.
 
 *&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
-" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
-" Editor is resolved internally. Caller must set gv_current_bug_id before calling.
+*& pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
+*& Editor is resolved internally. Caller must set gv_current_bug_id before calling.
+*&
+*& Explicit lv_tdname TYPE tdobname cast for SAVE_TEXT (same reason as load_long_text).
 FORM save_long_text USING pv_text_id TYPE thead-tdid.
   CHECK gv_current_bug_id IS NOT INITIAL.
 
@@ -325,7 +540,7 @@
         lt_lines TYPE TABLE OF tline,
         ls_line  TYPE tline.
 
-  " v4.1 BUGFIX #6: Flush GUI before reading text to prevent POTENTIAL_DATA_LOSS
+  " Flush GUI before reading text to prevent POTENTIAL_DATA_LOSS
   cl_gui_cfw=>flush( ).
 
   lr_editor->get_text_as_r3table(
@@ -344,9 +559,13 @@
     APPEND ls_line TO lt_lines.
   ENDLOOP.
 
+  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
+  DATA: lv_tdname TYPE tdobname.
+  lv_tdname = gv_current_bug_id.
+
   DATA: ls_header TYPE thead.
   ls_header-tdobject = 'ZBUG'.
-  ls_header-tdname   = gv_current_bug_id.
+  ls_header-tdname   = lv_tdname.
   ls_header-tdid     = pv_text_id.
   ls_header-tdspras  = sy-langu.
 
@@ -361,26 +580,70 @@
 ENDFORM.
 
 *&=====================================================================*
-*& GENERIC SMW0 TEMPLATE DOWNLOAD + AUTO-OPEN (v4.0 — Features #7, #10)
+*& LONG TEXT: SAVE DIRECT (from table param, no editor)
+*&
+*& Used by apply_status_transition to save transition note text directly
+*& from a char255 table (e.g., text read from go_edit_trans_note popup).
+*& The existing save_long_text reads from go_edit_desc/dev_note/tstr_note
+*& which may not exist when the popup is active.
+*&
+*& Parameters:
+*&   pv_text_id — Text ID (Z001/Z002/Z003)
+*&   pt_text    — Text content as table of char255
+*&=====================================================================*
+FORM save_long_text_direct USING pv_text_id TYPE thead-tdid
+                                 pt_text    TYPE gty_t_char255.
+  CHECK gv_current_bug_id IS NOT INITIAL.
+  CHECK pt_text IS NOT INITIAL.
+
+  DATA: lt_lines TYPE TABLE OF tline,
+        ls_line  TYPE tline.
+
+  LOOP AT pt_text INTO DATA(lv_line).
+    CLEAR ls_line.
+    ls_line-tdformat = '*'.
+    ls_line-tdline   = lv_line.
+    APPEND ls_line TO lt_lines.
+  ENDLOOP.
+
+  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
+  DATA: lv_tdname TYPE tdobname.
+  lv_tdname = gv_current_bug_id.
+
+  DATA: ls_header TYPE thead.
+  ls_header-tdobject = 'ZBUG'.
+  ls_header-tdname   = lv_tdname.
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
+ENDFORM.
+
+*&=====================================================================*
+*& GENERIC SMW0 TEMPLATE DOWNLOAD + AUTO-OPEN
 *&
 *& Downloads a binary template from SMW0 (MIME Repository) to local PC
 *& and auto-opens it in the default application (e.g., Excel).
 *&
-*& Pattern from reference program ZPG_BUGTRACKING_MAIN (FORM excute_download):
-*& 1. Check template exists in WWWDATA table
-*& 2. Read file extension + size from WWWPARAMS table
-*& 3. WWWDATA_IMPORT to load binary content into memory
-*& 4. file_save_dialog for user to pick save location
-*& 5. GUI_DOWNLOAD in BIN mode with exact bin_filesize
-*& 6. cl_gui_frontend_services=>execute to auto-open
-*&
-*& SMW0 Object IDs used:
-*&   ZTEMPLATE_PROJECT  — Project upload template
-*&   ZTEMPLATE_TESTCASE — Test case template (required before Resolved)
-*&   ZTEMPLATE_CONFIRM  — Confirm template (required before Closed)
-*&   ZTEMPLATE_BUGPROOF — Bug proof template (required before Fixed)
-*&=====================================================================*
-FORM download_smw0_template USING pv_objid TYPE wwwdatatab-objid.
+*& 2nd parameter pv_default_name — if provided, overrides the display
+*& name from WWWDATA as the default download filename.
+*& This allows custom filenames like 'Bug_report.xlsx' regardless of
+*& what the SMW0 object's text field contains.
+*&
+*& SMW0 Object IDs:
+*&   ZTEMPLATE_PROJECT — Project upload template
+*&   ZBT_TMPL_01      — Bug report template (Bug_report.xlsx)
+*&   ZBT_TMPL_02      — Fix report template (fix_report.xlsx)
+*&   ZBT_TMPL_03      — Confirm report template (confirm_report.xlsx)
+*&=====================================================================*
+FORM download_smw0_template USING pv_objid        TYPE wwwdatatab-objid
+                                  pv_default_name TYPE string.
   DATA: ls_wdata    TYPE wwwdatatab,
         lv_filename TYPE string,
         lv_ext      TYPE string,
@@ -403,13 +666,14 @@
     RETURN.
   ENDIF.
 
-  " 2. Get file metadata from WWWPARAMS
-  "    - text field from WWWDATA = display name (used as default filename)
-  "    - 'fileextension' param  = original file extension
-  "    - 'filesize' param       = exact byte size (critical for BIN download)
-  lv_filename = ls_wdata-text.
-  IF lv_filename IS INITIAL.
-    lv_filename = pv_objid.
+  " 2. Get file metadata — use pv_default_name if provided, else fall back to WWWDATA text
+  IF pv_default_name IS NOT INITIAL.
+    lv_filename = pv_default_name.
+  ELSE.
+    lv_filename = ls_wdata-text.
+    IF lv_filename IS INITIAL.
+      lv_filename = pv_objid.
+    ENDIF.
   ENDIF.
 
   SELECT SINGLE value INTO lv_ext
@@ -480,7 +744,7 @@
     RETURN.
   ENDIF.
 
-  " 6. Auto-open the downloaded file in default app (Feature #10)
+  " 6. Auto-open the downloaded file in default app
   cl_gui_frontend_services=>execute(
     EXPORTING
       document               = lv_fullpath
@@ -500,39 +764,34 @@
   MESSAGE 'Template downloaded successfully.' TYPE 'S'.
 ENDFORM.
 
+*&=====================================================================*
+*& TEMPLATE DOWNLOAD WRAPPERS
+*&=====================================================================*
+
 *&=== DOWNLOAD PROJECT TEMPLATE ===*
 *& Wrapper: downloads ZTEMPLATE_PROJECT from SMW0
 *& Called from PAI fcode DN_TMPL on Screen 0400
 FORM download_project_template.
-  PERFORM download_smw0_template USING 'ZTEMPLATE_PROJECT'.
-ENDFORM.
-
-*&=====================================================================*
-*& DOWNLOAD TESTCASE TEMPLATE (v4.0 — Feature #7)
-*& Wrapper: downloads ZTEMPLATE_TESTCASE from SMW0
+  PERFORM download_smw0_template USING 'ZTEMPLATE_PROJECT' 'Project_template.xlsx'.
+ENDFORM.
+
+*&=== DOWNLOAD BUG REPORT TEMPLATE ===*
+*& Wrapper: downloads ZBT_TMPL_01 from SMW0 as 'Bug_report.xlsx'
 *& Called from PAI fcode DN_TC on Screen 0200
-*& User must upload this template to SMW0 (Binary, relid = MI)
-*&=====================================================================*
-FORM download_testcase_template.
-  PERFORM download_smw0_template USING 'ZTEMPLATE_TESTCASE'.
-ENDFORM.
-
-*&=====================================================================*
-*& DOWNLOAD CONFIRM TEMPLATE (v4.0 — Feature #7)
-*& Wrapper: downloads ZTEMPLATE_CONFIRM from SMW0
+FORM download_bug_report_template.
+  PERFORM download_smw0_template USING 'ZBT_TMPL_01' 'Bug_report.xlsx'.
+ENDFORM.
+
+*&=== DOWNLOAD FIX REPORT TEMPLATE ===*
+*& Wrapper: downloads ZBT_TMPL_02 from SMW0 as 'fix_report.xlsx'
+*& Called from PAI fcode DN_PROOF on Screen 0200
+FORM download_fix_report_template.
+  PERFORM download_smw0_template USING 'ZBT_TMPL_02' 'fix_report.xlsx'.
+ENDFORM.
+
+*&=== DOWNLOAD CONFIRM REPORT TEMPLATE ===*
+*& Wrapper: downloads ZBT_TMPL_03 from SMW0 as 'confirm_report.xlsx'
 *& Called from PAI fcode DN_CONF on Screen 0200
-*& User must upload this template to SMW0 (Binary, relid = MI)
-*&=====================================================================*
-FORM download_confirm_template.
-  PERFORM download_smw0_template USING 'ZTEMPLATE_CONFIRM'.
-ENDFORM.
-
-*&=====================================================================*
-*& DOWNLOAD BUGPROOF TEMPLATE (v4.0 — Feature #7)
-*& Wrapper: downloads ZTEMPLATE_BUGPROOF from SMW0
-*& Called from PAI fcode DN_PROOF on Screen 0200
-*& User must upload this template to SMW0 (Binary, relid = MI)
-*&=====================================================================*
-FORM download_bugproof_template.
-  PERFORM download_smw0_template USING 'ZTEMPLATE_BUGPROOF'.
-ENDFORM.
+FORM dl_confirm_report_tmpl.
+  PERFORM download_smw0_template USING 'ZBT_TMPL_03' 'confirm_report.xlsx'.
+ENDFORM.
```

### CODE_PAI.md — modified

`+267 / -53 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -1,15 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_PAI — User Action Logic (v4.0 → v4.1 BUGFIX)
-*&---------------------------------------------------------------------*
-*& v4.0 changes (over v3.0):
-*&  - user_command_0300: added DL_EVD (delete evidence), SENDMAIL handlers
-*&  - user_command_0300: added unsaved changes check before BACK/CANC
-*&  - user_command_0500: added unsaved changes check before BACK/CANC
-*&  - user_command_0200: added DN_TC, DN_CONF, DN_PROOF (template downloads)
-*&
-*& v4.1 BUGFIX changes:
-*&  - Added 8 POV modules for Screen 0310 F4 help (Bug #5)
-*&  - Added 2 POV modules for Screen 0500: project_status, project_manager (Bug #1)
+*& Include Z_BUG_WS_PAI — User Action Logic (PAI modules for all screens)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety) ---*
@@ -27,14 +17,37 @@
 ENDMODULE.
 
 *&=====================================================================*
+*& SCREEN 0410 — PROJECT SEARCH (initial screen)
+*&=====================================================================*
+MODULE user_command_0410 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'EXECUTE' OR 'ONLI'.   " F8 = Execute
+      PERFORM search_projects.
+      CALL SCREEN 0400.
+
+    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
+      LEAVE PROGRAM.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
 *& BUG LIST SCREEN 0200
 *&=====================================================================*
 MODULE user_command_0200 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
-      " Always go back to Project List (initial screen)
-      LEAVE TO SCREEN 0400.
+      " LEAVE TO SCREEN 0 → returns to caller (Screen 0400 via CALL SCREEN)
+      " Destroy Bug ALV to force rebuild on re-entry
+      IF go_alv_bug IS NOT INITIAL.
+        go_alv_bug->free( ).
+        FREE go_alv_bug.
+        go_cont_bug->free( ).
+        FREE go_cont_bug.
+        CLEAR: go_alv_bug, go_cont_bug.
+      ENDIF.
+      LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
       LEAVE PROGRAM.
     WHEN 'CREATE'.
@@ -51,8 +64,8 @@
       CLEAR: gv_current_bug_id, gs_bug_detail.
       gv_mode             = gc_mode_create.
       gv_active_subscreen = '0310'.
-      gv_active_tab       = 'TAB_INFO'.      " v3.0: sync tab highlight
-      CLEAR gv_detail_loaded.                 " v3.0: force fresh load
+      gv_active_tab       = 'TAB_INFO'.
+      CLEAR gv_detail_loaded.
       " gv_current_project_id already set from project context
       CALL SCREEN 0300.
     WHEN 'CHANGE'.
@@ -62,8 +75,8 @@
       ELSE.
         gv_mode             = gc_mode_change.
         gv_active_subscreen = '0310'.
-        gv_active_tab       = 'TAB_INFO'.    " v3.0
-        CLEAR gv_detail_loaded.               " v3.0
+        gv_active_tab       = 'TAB_INFO'.
+        CLEAR gv_detail_loaded.
         CALL SCREEN 0300.
       ENDIF.
     WHEN 'DISPLAY'.
@@ -73,8 +86,8 @@
       ELSE.
         gv_mode             = gc_mode_display.
         gv_active_subscreen = '0310'.
-        gv_active_tab       = 'TAB_INFO'.    " v3.0
-        CLEAR gv_detail_loaded.               " v3.0
+        gv_active_tab       = 'TAB_INFO'.
+        CLEAR gv_detail_loaded.
         CALL SCREEN 0300.
       ENDIF.
     WHEN 'DELETE'.
@@ -93,13 +106,28 @@
       IF go_alv_bug IS NOT INITIAL.
         go_alv_bug->refresh_table_display( ).
       ENDIF.
-    " v4.0: Template download buttons
+
+    " Bug Search Engine
+    WHEN 'SEARCH'.
+      " Clear previous search fields + results
+      CLEAR: s_bug_id, s_title, s_status, s_prio, s_mod, s_reporter, s_dev.
+      CLEAR gv_search_executed.
+      " Open search popup (modal dialog)
+      CALL SCREEN 0210 STARTING AT 5 3 ENDING AT 75 18.
+      " After popup closes, check if search was executed
+      " (Cannot CALL SCREEN 0220 from inside modal dialog — use flag pattern)
+      IF gv_search_executed = abap_true.
+        CLEAR gv_search_executed.
+        CALL SCREEN 0220.
+      ENDIF.
+
+    " Template download buttons
     WHEN 'DN_TC'.
-      PERFORM download_testcase_template.
+      PERFORM download_bug_report_template.
     WHEN 'DN_CONF'.
-      PERFORM download_confirm_template.
+      PERFORM dl_confirm_report_tmpl.
     WHEN 'DN_PROOF'.
-      PERFORM download_bugproof_template.
+      PERFORM download_fix_report_template.
   ENDCASE.
 ENDMODULE.
 
@@ -110,7 +138,7 @@
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
-      " v4.0: Check unsaved changes before leaving
+      " Check unsaved changes before leaving
       IF gv_mode <> gc_mode_display.
         DATA: lv_continue TYPE abap_bool.
         PERFORM check_unsaved_bug CHANGING lv_continue.
@@ -118,10 +146,11 @@
           RETURN.  " User cancelled — stay on screen
         ENDIF.
       ENDIF.
-      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
-      LEAVE TO SCREEN 0200.
+      PERFORM cleanup_detail_editors.
+      " LEAVE TO SCREEN 0 → returns to caller (Screen 0200)
+      LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
-      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
+      PERFORM cleanup_detail_editors.
       LEAVE PROGRAM.
     WHEN 'SAVE'.
       IF gv_mode = gc_mode_display.
@@ -131,25 +160,41 @@
       " Save description mini editor content to gs_bug_detail-desc_text
       PERFORM save_desc_mini_to_workarea.
       PERFORM save_bug_detail.
+
+    " STATUS_CHG opens popup Screen 0370 (replaces old change_bug_status)
     WHEN 'STATUS_CHG'.
       IF gv_mode = gc_mode_create.
         MESSAGE 'Save the bug first before changing status.' TYPE 'W'.
         RETURN.
       ENDIF.
-      PERFORM change_bug_status.
+      IF gv_mode = gc_mode_display.
+        MESSAGE 'Switch to Change mode before changing status.' TYPE 'W'.
+        RETURN.
+      ENDIF.
+      " Clear previous transition state
+      CLEAR: gv_trans_new_status, gv_trans_confirmed.
+      " Open Status Transition Popup
+      CALL SCREEN 0370 STARTING AT 5 3 ENDING AT 85 22.
+      " After popup returns, check if transition was confirmed
+      IF gv_trans_confirmed = abap_true.
+        " Refresh bug detail (status may have changed + auto-assign may have fired)
+        gv_detail_loaded = abap_false.
+        CLEAR gv_trans_confirmed.
+      ENDIF.
+
     WHEN 'UP_FILE'.
       PERFORM upload_evidence_file.
     WHEN 'UP_REP'.
       PERFORM upload_report_file.
     WHEN 'UP_FIX'.
       PERFORM upload_fix_file.
-    " v4.0: Delete evidence
+    " Delete evidence
     WHEN 'DL_EVD'.
       PERFORM delete_evidence.
-    " v4.0: Send email notification
+    " Send email notification
     WHEN 'SENDMAIL'.
       PERFORM send_mail_notification.
-    " ---- Tab switching (v3.0: sync gv_active_tab, no PERFORM load calls) ----
+    " ---- Tab switching ----
     WHEN 'TAB_INFO'.
       gv_active_subscreen = '0310'.
       gv_active_tab       = 'TAB_INFO'.
@@ -172,14 +217,121 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& PROJECT LIST SCREEN 0400 (INITIAL SCREEN)
+*& SCREEN 0370 — STATUS TRANSITION POPUP
+*&=====================================================================*
+MODULE user_command_0370 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'CONFIRM'.
+      " Validate transition (matrix + role + required fields)
+      PERFORM validate_status_transition.
+      IF gv_trans_confirmed = abap_true.
+        " Apply transition (update DB + log history + auto-assign)
+        PERFORM apply_status_transition.
+        " Free container before leaving popup
+        IF go_cont_trans_note IS NOT INITIAL.
+          go_cont_trans_note->free( ).
+          CLEAR: go_cont_trans_note, go_edit_trans_note.
+        ENDIF.
+        LEAVE TO SCREEN 0.  " Close popup → return to Screen 0300
+      ENDIF.
+
+    WHEN 'CANCEL' OR 'BACK'.
+      CLEAR gv_trans_confirmed.
+      IF go_cont_trans_note IS NOT INITIAL.
+        go_cont_trans_note->free( ).
+        CLEAR: go_cont_trans_note, go_edit_trans_note.
+      ENDIF.
+      LEAVE TO SCREEN 0.
+
+    WHEN 'UP_TRANS'.
+      " Upload evidence from within popup
+      IF gv_current_bug_id IS INITIAL.
+        MESSAGE 'Bug not saved yet. Cannot upload evidence.' TYPE 'S' DISPLAY LIKE 'W'.
+      ELSE.
+        PERFORM upload_evidence_file.
+      ENDIF.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0210 — BUG SEARCH INPUT (Modal Dialog popup)
+*&=====================================================================*
+MODULE user_command_0210 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'EXECUTE' OR 'ONLI'.    " F8 = Execute
+      PERFORM execute_bug_search.
+      " Set flag — caller (user_command_0200) will navigate to Screen 0220
+      " (Cannot CALL SCREEN 0220 from inside modal dialog)
+      IF gt_search_results IS NOT INITIAL.
+        gv_search_executed = abap_true.
+      ENDIF.
+      LEAVE TO SCREEN 0.  " Close popup
+
+    WHEN 'CANCEL' OR 'BACK'.
+      LEAVE TO SCREEN 0.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0220 — BUG SEARCH RESULTS (Full screen ALV)
+*&=====================================================================*
+MODULE user_command_0220 INPUT.
+  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
+  CASE gv_save_ok.
+    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
+      " Free search results ALV to force rebuild on next search
+      IF go_cont_search IS NOT INITIAL.
+        go_cont_search->free( ).
+        CLEAR: go_cont_search, go_search_alv.
+      ENDIF.
+      LEAVE TO SCREEN 0.   " Return to Screen 0200
+
+    WHEN 'CHANGE'.
+      PERFORM get_selected_search_bug CHANGING gv_current_bug_id.
+      IF gv_current_bug_id IS INITIAL.
+        MESSAGE 'Please select a bug first.' TYPE 'W'.
+      ELSE.
+        gv_mode             = gc_mode_change.
+        gv_active_subscreen = '0310'.
+        gv_active_tab       = 'TAB_INFO'.
+        CLEAR gv_detail_loaded.
+        CALL SCREEN 0300.
+      ENDIF.
+
+    WHEN 'DISPLAY'.
+      PERFORM get_selected_search_bug CHANGING gv_current_bug_id.
+      IF gv_current_bug_id IS INITIAL.
+        MESSAGE 'Please select a bug first.' TYPE 'W'.
+      ELSE.
+        gv_mode             = gc_mode_display.
+        gv_active_subscreen = '0310'.
+        gv_active_tab       = 'TAB_INFO'.
+        CLEAR gv_detail_loaded.
+        CALL SCREEN 0300.
+      ENDIF.
+  ENDCASE.
+ENDMODULE.
+
+*&=====================================================================*
+*& PROJECT LIST SCREEN 0400
+*& No longer initial screen — called from 0410 via CALL SCREEN
 *&=====================================================================*
 MODULE user_command_0400 INPUT.
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
-      " This is the initial screen — Back = exit program
-      LEAVE PROGRAM.
+      " LEAVE TO SCREEN 0 → returns to caller (Screen 0410)
+      " Destroy Project ALV to force rebuild on re-entry (filtered data may differ)
+      IF go_alv_project IS NOT INITIAL.
+        go_alv_project->free( ).
+        FREE go_alv_project.
+        go_cont_project->free( ).
+        FREE go_cont_project.
+        CLEAR: go_alv_project, go_cont_project.
+      ENDIF.
+      LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
       LEAVE PROGRAM.
     WHEN 'MY_BUGS'.
@@ -202,7 +354,7 @@
       ENDIF.
       CLEAR: gv_current_project_id, gs_project, gt_user_project.
       gv_mode = gc_mode_create.
-      CLEAR gv_prj_detail_loaded.            " v3.0: force fresh load
+      CLEAR gv_prj_detail_loaded.
       CALL SCREEN 0500.
     WHEN 'CHNG_PRJ'.
       PERFORM get_selected_project CHANGING gv_current_project_id.
@@ -210,7 +362,7 @@
         MESSAGE 'Please select a project first.' TYPE 'W'.
       ELSE.
         gv_mode = gc_mode_change.
-        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
+        CLEAR gv_prj_detail_loaded.
         CALL SCREEN 0500.
       ENDIF.
     WHEN 'DISP_PRJ'.
@@ -219,7 +371,7 @@
         MESSAGE 'Please select a project first.' TYPE 'W'.
       ELSE.
         gv_mode = gc_mode_display.
-        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
+        CLEAR gv_prj_detail_loaded.
         CALL SCREEN 0500.
       ENDIF.
     WHEN 'DEL_PRJ'.
@@ -252,7 +404,7 @@
   gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
   CASE gv_save_ok.
     WHEN 'BACK' OR 'CANC'.
-      " v4.0: Check unsaved changes before leaving
+      " Check unsaved changes before leaving
       IF gv_mode <> gc_mode_display.
         DATA: lv_prj_continue TYPE abap_bool.
         PERFORM check_unsaved_prj CHANGING lv_prj_continue.
@@ -260,7 +412,8 @@
           RETURN.  " User cancelled — stay on screen
         ENDIF.
       ENDIF.
-      LEAVE TO SCREEN 0400.
+      " LEAVE TO SCREEN 0 → returns to caller (Screen 0400)
+      LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
       LEAVE PROGRAM.
     WHEN 'SAVE'.
@@ -279,12 +432,12 @@
 *&--- TABLE CONTROL SYNC (Screen 0500) ---*
 MODULE tc_users_modify INPUT.
   MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
-ENDMODULE.
-
-*&=====================================================================*
-*& v4.0: POV MODULES — F4 Calendar Popup (Screen 0500)
-*& Called from PROCESS ON VALUE-REQUEST in Screen 0500 flow logic.
-*& These modules delegate to FORM f4_date in CODE_F02.md.
+  " Track that user actually interacted with the table control row
+  gv_tc_user_selected = abap_true.
+ENDMODULE.
+
+*&=====================================================================*
+*& POV MODULES — F4 Help (Screen 0500 — Project Detail)
 *&=====================================================================*
 MODULE f4_prj_startdate INPUT.
   PERFORM f4_date USING 'PRJ_START_DATE'.
@@ -294,10 +447,6 @@
   PERFORM f4_date USING 'PRJ_END_DATE'.
 ENDMODULE.
 
-*&=====================================================================*
-*& v4.1 BUGFIX #1: POV MODULES — Screen 0500 (Project Detail)
-*& F4 help for PROJECT_STATUS and PROJECT_MANAGER fields
-*&=====================================================================*
 MODULE f4_prj_status INPUT.
   PERFORM f4_project_status USING 'GS_PROJECT-PROJECT_STATUS'.
 ENDMODULE.
@@ -307,10 +456,7 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& v4.1 BUGFIX #5: POV MODULES — Screen 0310 (Bug Info)
-*& F4 help for STATUS, PRIORITY, SEVERITY, BUG_TYPE, PROJECT_ID,
-*& TESTER_ID, DEV_ID, VERIFY_TESTER_ID fields
-*& Called from PROCESS ON VALUE-REQUEST in Screen 0310 flow logic.
+*& POV MODULES — F4 Help (Screen 0310 — Bug Info)
 *&=====================================================================*
 MODULE f4_bug_status INPUT.
   PERFORM f4_status USING 'GS_BUG_DETAIL-STATUS'.
@@ -343,3 +489,71 @@
 MODULE f4_bug_verify INPUT.
   PERFORM f4_user_id USING 'GS_BUG_DETAIL-VERIFY_TESTER_ID'.
 ENDMODULE.
+
+" SAP Module F4 (Screen 0310)
+MODULE f4_bug_sapmodule INPUT.
+  PERFORM f4_sap_module USING 'GS_BUG_DETAIL-SAP_MODULE'.
+ENDMODULE.
+
+*&=====================================================================*
+*& POV MODULES — F4 Help (Screen 0410 — Project Search)
+*&=====================================================================*
+MODULE f4_project_id INPUT.
+  PERFORM f4_project_id_help USING 'S_PRJ_ID'.
+ENDMODULE.
+
+MODULE f4_manager INPUT.
+  PERFORM f4_manager_help USING 'S_PRJ_MN'.
+ENDMODULE.
+
+MODULE f4_project_status INPUT.
+  PERFORM f4_project_status_help USING 'S_PRJ_ST'.
+ENDMODULE.
+
+*&=====================================================================*
+*& POV MODULES — F4 Help (Screen 0370 — Status Transition)
+*&=====================================================================*
+
+" F4 for New Status — shows only valid transitions based on current status + role
+MODULE f4_trans_status_mod INPUT.
+  PERFORM f4_trans_status.
+ENDMODULE.
+
+" F4 for Developer (assign)
+MODULE f4_trans_developer INPUT.
+  PERFORM f4_user_id USING 'GV_TRANS_DEV_ID'.
+ENDMODULE.
+
+" F4 for Final Tester (assign)
+MODULE f4_trans_ftester INPUT.
+  PERFORM f4_user_id USING 'GV_TRANS_FTESTER_ID'.
+ENDMODULE.
+
+*&=====================================================================*
+*& POV MODULES — F4 Help (Screen 0210 — Bug Search)
+*&=====================================================================*
+
+" Status F4 for search — shows all 10 statuses
+MODULE f4_bug_search_status INPUT.
+  PERFORM f4_status USING 'S_STATUS'.
+ENDMODULE.
+
+" Priority F4 for search
+MODULE f4_bug_search_priority INPUT.
+  PERFORM f4_priority USING 'S_PRIO'.
+ENDMODULE.
+
+" SAP Module F4 for search
+MODULE f4_bug_search_module INPUT.
+  PERFORM f4_sap_module USING 'S_MOD'.
+ENDMODULE.
+
+" Reporter F4 for search (all users)
+MODULE f4_bug_search_reporter INPUT.
+  PERFORM f4_user_id USING 'S_REPORTER'.
+ENDMODULE.
+
+" Developer F4 for search (all users — filter by Dev role is optional)
+MODULE f4_bug_search_developer INPUT.
+  PERFORM f4_user_id USING 'S_DEV'.
+ENDMODULE.
```

### CODE_PBO.md — modified

`+254 / -95 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -1,21 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_PBO — Presentation Logic (v4.0)
-*&---------------------------------------------------------------------*
-*& v4.0 changes (over v3.0):
-*&  - load_bug_detail: saves snapshot (gs_bug_snapshot) after first load
-*&  - init_project_detail: saves snapshot (gs_prj_snapshot) after first load
-*&  - status_0300: added SENDMAIL, DL_EVD exclusion logic
-*&  - status_0200: added template download button exclusions (DN_TC/DN_CONF/DN_PROOF)
-*&  - init_evidence_alv: NEW module for subscreen 0350
-*&  - modify_screen_0300: added FNC screen group (Tester/Manager-only fields)
-*&
-*& v4.1 BUGFIX changes:
-*&  - load_bug_detail: Create mode sets BUG_ID = '(Auto)' placeholder (Bug #5)
-*&  - modify_screen_0300: BID group → ALWAYS display-only (Bug #5)
-*&  - init_desc_mini: added EXCEPTIONS to set_text_as_r3table (Bug #6)
-*&  - status_0500: exclude ADD_USER/REMO_USR in Create mode (Bug #1)
-*&  - init_project_detail: Create mode sets PROJECT_ID = '(Auto)' (Bug #1)
-*&  - modify_screen_0500: added PID group → always display-only (Bug #1/#3)
+*& Include Z_BUG_WS_PBO — Presentation Logic (PBO modules for all screens)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
@@ -24,13 +8,15 @@
   SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Hub'.
 ENDMODULE.
 
-*&--- INIT USER ROLE (runs on initial screen 0400, loaded once) ---*
+*&--- INIT USER ROLE (runs on initial screen 0410, loaded once) ---*
 MODULE init_user_role OUTPUT.
   " Load role once at startup
   CHECK gv_role IS INITIAL.
   gv_uname = sy-uname.
   SELECT SINGLE role FROM zbug_users INTO @gv_role
-    WHERE user_id = @gv_uname AND is_del <> 'X'.
+    WHERE user_id = @gv_uname
+      AND is_del <> 'X'
+      AND is_active = 'X'.
   IF sy-subrc <> 0.
     MESSAGE 'User not registered in Bug Tracking system.' TYPE 'E' DISPLAY LIKE 'I'.
     LEAVE PROGRAM.
@@ -38,7 +24,15 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& SCREEN 0200: BUG LIST (dual mode: Project / My Bugs)
+*& SCREEN 0410 — PROJECT SEARCH (initial screen)
+*&=====================================================================*
+MODULE status_0410 OUTPUT.
+  SET PF-STATUS 'STATUS_0410'.
+  SET TITLEBAR 'T_0410'.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0200: BUG LIST (dual mode: Project / My Bugs) + Dashboard
 *&=====================================================================*
 MODULE status_0200 OUTPUT.
   CLEAR gm_excl.
@@ -59,7 +53,7 @@
     APPEND 'DELETE' TO gm_excl.
   ENDIF.
 
-  " v4.0: Template downloads only for Testers/Managers
+  " Template downloads only for Testers/Managers
   IF gv_role = 'D'.
     APPEND 'DN_TC'    TO gm_excl.    " Download Testcase template
     APPEND 'DN_CONF'  TO gm_excl.    " Download Confirm template
@@ -121,7 +115,7 @@
   " Display mode: hide SAVE + upload buttons + email + delete evidence
   IF gv_mode = gc_mode_display.
     APPEND 'SAVE'     TO gm_excl.
-    APPEND 'SENDMAIL' TO gm_excl.    " v4.0
+    APPEND 'SENDMAIL' TO gm_excl.
   ENDIF.
   " Tester cannot upload fix
   IF gv_role = 'T'.
@@ -131,21 +125,21 @@
   IF gv_role = 'D'.
     APPEND 'UP_REP' TO gm_excl.
   ENDIF.
-  " Create mode: hide status change + file uploads + email + delete evidence
+  " Create mode: hide status change + some uploads + email + delete evidence
+  " UP_FILE is allowed in create mode (auto-save before upload)
   IF gv_mode = gc_mode_create.
     APPEND 'STATUS_CHG' TO gm_excl.
-    APPEND 'UP_FILE'    TO gm_excl.
     APPEND 'UP_REP'     TO gm_excl.
     APPEND 'UP_FIX'     TO gm_excl.
-    APPEND 'SENDMAIL'   TO gm_excl.    " v4.0: no email for unsaved bug
-    APPEND 'DL_EVD'     TO gm_excl.    " v4.0: no delete evidence before save
+    APPEND 'SENDMAIL'   TO gm_excl.    " No email for unsaved bug
+    APPEND 'DL_EVD'     TO gm_excl.    " No delete evidence before save
   ENDIF.
   " Display mode: hide upload + delete evidence
   IF gv_mode = gc_mode_display.
     APPEND 'UP_FILE' TO gm_excl.
     APPEND 'UP_REP'  TO gm_excl.
     APPEND 'UP_FIX'  TO gm_excl.
-    APPEND 'DL_EVD'  TO gm_excl.       " v4.0
+    APPEND 'DL_EVD'  TO gm_excl.
   ENDIF.
   SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.
 
@@ -185,17 +179,20 @@
   " 5. Create mode: reset work area with defaults
   IF gv_mode = gc_mode_create.
     CLEAR gs_bug_detail.
-    " v4.1 BUGFIX #5: Show placeholder — BUG_ID will be auto-generated on save
+    " Show placeholder — BUG_ID will be auto-generated on save
     gs_bug_detail-bug_id = '(Auto)'.
     " Pre-fill PROJECT_ID from project context (locked on screen)
     IF gv_current_project_id IS NOT INITIAL.
       gs_bug_detail-project_id = gv_current_project_id.
     ENDIF.
-    gs_bug_detail-tester_id = gv_uname.  " Default tester = current user
-    gs_bug_detail-priority  = 'M'.       " Default priority = Medium
-  ENDIF.
-
-  " 6. v4.0: Save snapshot for unsaved changes detection
+    " Force status=New, pre-fill created_at + tester_id
+    gs_bug_detail-status     = gc_st_new.       " Always '1'
+    gs_bug_detail-tester_id  = gv_uname.        " Default tester = current user
+    gs_bug_detail-created_at = sy-datum.         " Pre-fill created date
+    gs_bug_detail-priority   = 'M'.             " Default priority = Medium
+  ENDIF.
+
+  " 6. Save snapshot for unsaved changes detection
   gs_bug_snapshot = gs_bug_detail.
 
   " 7. Mark as loaded — subsequent PBO calls skip DB read
@@ -206,16 +203,18 @@
 *& Separated from load_bug_detail so display texts update after
 *& status change without requiring a DB reload.
 MODULE compute_bug_display_texts OUTPUT.
+  " 10-state status mapping (6=FinalTesting, V=Resolved)
   gv_status_disp = SWITCH #( gs_bug_detail-status
-    WHEN gc_st_new        THEN 'New'
-    WHEN gc_st_assigned   THEN 'Assigned'
-    WHEN gc_st_inprogress THEN 'In Progress'
-    WHEN gc_st_pending    THEN 'Pending'
-    WHEN gc_st_fixed      THEN 'Fixed'
-    WHEN gc_st_resolved   THEN 'Resolved'
-    WHEN gc_st_closed     THEN 'Closed'
-    WHEN gc_st_waiting    THEN 'Waiting'
-    WHEN gc_st_rejected   THEN 'Rejected'
+    WHEN gc_st_new          THEN 'New'
+    WHEN gc_st_assigned     THEN 'Assigned'
+    WHEN gc_st_inprogress   THEN 'In Progress'
+    WHEN gc_st_pending      THEN 'Pending'
+    WHEN gc_st_fixed        THEN 'Fixed'
+    WHEN gc_st_finaltesting THEN 'Final Testing'
+    WHEN gc_st_closed       THEN 'Closed'
+    WHEN gc_st_waiting      THEN 'Waiting'
+    WHEN gc_st_rejected     THEN 'Rejected'
+    WHEN gc_st_resolved     THEN 'Resolved'
     ELSE gs_bug_detail-status ).
 
   gv_priority_disp = SWITCH #( gs_bug_detail-priority
@@ -246,7 +245,8 @@
   LOOP AT SCREEN.
     " Readonly mode: disable all fields with group EDT
     IF screen-group1 = 'EDT'.
-      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+         OR gs_bug_detail-status = gc_st_resolved.
         screen-input = 0.
       ELSE.
         screen-input = 1.
@@ -254,10 +254,23 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " BUG_ID: ALWAYS display-only (auto-generated on save) — v4.1 BUGFIX #5
-    " Previously was editable in Create mode which confused users
+    " BUG_ID: ALWAYS display-only (auto-generated on save)
     IF screen-group1 = 'BID'.
       screen-input = 0.  " Always locked — shows "(Auto)" in Create, real ID after save
+      MODIFY SCREEN.
+    ENDIF.
+
+    " STATUS field — ALWAYS locked (change only via popup Screen 0370)
+    " Screen group STS assigned to STATUS field on Screen 0310
+    IF screen-group1 = 'STS'.
+      screen-input = 0.  " Never editable — use STATUS_CHG button → popup 0370
+      MODIFY SCREEN.
+    ENDIF.
+
+    " CREATED fields — ALWAYS read-only (system-generated)
+    " Assign group CRD in SE51 to: GS_BUG_DETAIL-ERDAT, ERNAM, ERZET
+    IF screen-group1 = 'CRD'.
+      screen-input = 0.
       MODIFY SCREEN.
     ENDIF.
 
@@ -282,14 +295,15 @@
       screen-input = 0. MODIFY SCREEN.
     ENDIF.
 
-    " v4.0: FNC group — fields only Tester/Manager can edit
-    " (BUG_TYPE, PRIORITY, SEVERITY, DEADLINE)
+    " FNC group — fields only Tester/Manager can edit
+    " (BUG_TYPE, PRIORITY, SEVERITY)
     " Developer cannot edit these fields even in Change mode
     IF screen-group1 = 'FNC'.
       IF gv_role = 'D'.
         screen-input = 0. MODIFY SCREEN.
       ENDIF.
-      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
+      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+         OR gs_bug_detail-status = gc_st_resolved.
         screen-input = 0. MODIFY SCREEN.
       ENDIF.
     ENDIF.
@@ -302,10 +316,16 @@
 MODULE init_desc_mini OUTPUT.
   " Create mini text editor (3-4 lines) for quick description on Bug Info tab
   IF go_desc_mini_cont IS INITIAL.
-    CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
-    CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
-    go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
-    go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
+    TRY.
+        CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
+        CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
+        go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Mini Description editor. Check Custom Control CC_DESC_MINI on screen 0310.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
 
     " Load DESC_TEXT into mini editor — ONLY on first creation
     " (subsequent PBO calls skip this, preserving user edits during tab switch)
@@ -322,77 +342,110 @@
   ENDIF.
 
   " Readonly mode: set every PBO (may differ between bugs)
-  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
-    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
-  ELSE.
-    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
+  IF go_desc_mini_edit IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+       OR gs_bug_detail-status = gc_st_resolved.
+      go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
   ENDIF.
 ENDMODULE.
 
 *&=====================================================================*
 *& SUBSCREEN 0320: Description Long Text (Text ID Z001)
+*& TRY-CATCH for container creation (prevents dump if CC missing)
 *&=====================================================================*
 MODULE init_long_text_desc OUTPUT.
   IF go_cont_desc IS INITIAL.
-    CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
-    CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
-    go_edit_desc->set_toolbar_mode( cl_gui_textedit=>false ).
-    go_edit_desc->set_statusbar_mode( cl_gui_textedit=>false ).
+    TRY.
+        CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
+        CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
+        go_edit_desc->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_desc->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Description editor. Check Custom Control CC_DESC on screen 0320.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
     " Load text from DB on first creation only
     PERFORM load_long_text USING 'Z001'.
   ENDIF.
   " Readonly: set every PBO
-  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
-    go_edit_desc->set_readonly_mode( cl_gui_textedit=>true ).
-  ELSE.
-    go_edit_desc->set_readonly_mode( cl_gui_textedit=>false ).
+  IF go_edit_desc IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+       OR gs_bug_detail-status = gc_st_resolved.
+      go_edit_desc->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_edit_desc->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
   ENDIF.
 ENDMODULE.
 
 *&=====================================================================*
 *& SUBSCREEN 0330: Dev Note Long Text (Text ID Z002)
+*& TRY-CATCH for container creation (prevents dump if CC missing)
 *&=====================================================================*
 MODULE init_long_text_devnote OUTPUT.
   IF go_cont_dev_note IS INITIAL.
-    CREATE OBJECT go_cont_dev_note EXPORTING container_name = 'CC_DEVNOTE'.
-    CREATE OBJECT go_edit_dev_note EXPORTING parent = go_cont_dev_note.
-    go_edit_dev_note->set_toolbar_mode( cl_gui_textedit=>false ).
-    go_edit_dev_note->set_statusbar_mode( cl_gui_textedit=>false ).
+    TRY.
+        CREATE OBJECT go_cont_dev_note EXPORTING container_name = 'CC_DEVNOTE'.
+        CREATE OBJECT go_edit_dev_note EXPORTING parent = go_cont_dev_note.
+        go_edit_dev_note->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_dev_note->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Dev Note editor. Check Custom Control CC_DEVNOTE on screen 0330.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
     " Load text from DB on first creation only
     PERFORM load_long_text USING 'Z002'.
   ENDIF.
-  " Readonly: Testers cannot edit Dev Notes; also readonly in display/closed
-  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-     OR gv_role = 'T'.
-    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>true ).
-  ELSE.
-    go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>false ).
+  " Readonly: Testers cannot edit Dev Notes; also readonly in display/closed/resolved
+  IF go_edit_dev_note IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+       OR gs_bug_detail-status = gc_st_resolved
+       OR gv_role = 'T'.
+      go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
   ENDIF.
 ENDMODULE.
 
 *&=====================================================================*
 *& SUBSCREEN 0340: Tester Note Long Text (Text ID Z003)
+*& TRY-CATCH for container creation (prevents dump if CC missing)
 *&=====================================================================*
 MODULE init_long_text_tstrnote OUTPUT.
   IF go_cont_tstr_note IS INITIAL.
-    CREATE OBJECT go_cont_tstr_note EXPORTING container_name = 'CC_TSTRNOTE'.
-    CREATE OBJECT go_edit_tstr_note EXPORTING parent = go_cont_tstr_note.
-    go_edit_tstr_note->set_toolbar_mode( cl_gui_textedit=>false ).
-    go_edit_tstr_note->set_statusbar_mode( cl_gui_textedit=>false ).
+    TRY.
+        CREATE OBJECT go_cont_tstr_note EXPORTING container_name = 'CC_TSTRNOTE'.
+        CREATE OBJECT go_edit_tstr_note EXPORTING parent = go_cont_tstr_note.
+        go_edit_tstr_note->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_tstr_note->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Tester Note editor. Check Custom Control CC_TSTRNOTE on screen 0340.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
     " Load text from DB on first creation only
     PERFORM load_long_text USING 'Z003'.
   ENDIF.
-  " Readonly: Devs cannot edit Tester Notes; also readonly in display/closed
-  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-     OR gv_role = 'D'.
-    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>true ).
-  ELSE.
-    go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>false ).
-  ENDIF.
-ENDMODULE.
-
-*&=====================================================================*
-*& v4.0: SUBSCREEN 0350: Evidence ALV (attachment list)
+  " Readonly: Devs cannot edit Tester Notes; also readonly in display/closed/resolved
+  IF go_edit_tstr_note IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
+       OR gs_bug_detail-status = gc_st_resolved
+       OR gv_role = 'D'.
+      go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& SUBSCREEN 0350: Evidence ALV (attachment list)
 *&=====================================================================*
 MODULE init_evidence_alv OUTPUT.
   " Always reload evidence data (files may have been added/deleted)
@@ -430,7 +483,101 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& SCREEN 0400: PROJECT LIST (INITIAL SCREEN)
+*& SCREEN 0370 — STATUS TRANSITION POPUP
+*&=====================================================================*
+MODULE status_0370 OUTPUT.
+  SET PF-STATUS 'STATUS_0370'.
+  SET TITLEBAR 'T_0370'.
+ENDMODULE.
+
+MODULE init_trans_popup OUTPUT.
+  " 1. Pre-fill read-only fields from current bug detail
+  gv_trans_bug_id     = gs_bug_detail-bug_id.
+  gv_trans_title      = gs_bug_detail-title.
+  gv_trans_reporter   = gs_bug_detail-tester_id.
+  gv_trans_cur_status = gs_bug_detail-status.
+
+  " 2. Compute current status display text
+  gv_trans_cur_st_text = SWITCH #( gs_bug_detail-status
+    WHEN gc_st_new          THEN 'New'
+    WHEN gc_st_assigned     THEN 'Assigned'
+    WHEN gc_st_inprogress   THEN 'In Progress'
+    WHEN gc_st_pending      THEN 'Pending'
+    WHEN gc_st_fixed        THEN 'Fixed'
+    WHEN gc_st_finaltesting THEN 'Final Testing'
+    WHEN gc_st_waiting      THEN 'Waiting'
+    WHEN gc_st_rejected     THEN 'Rejected'
+    WHEN gc_st_resolved     THEN 'Resolved'
+    WHEN gc_st_closed       THEN 'Closed'
+    ELSE gs_bug_detail-status ).
+
+  " 3. Pre-fill existing developer/tester (user may override via F4)
+  gv_trans_dev_id     = gs_bug_detail-dev_id.
+  gv_trans_ftester_id = gs_bug_detail-verify_tester_id.
+
+  " 4. Init text editor for TRANS_NOTE (transition justification / test results)
+  IF go_cont_trans_note IS INITIAL.
+    TRY.
+        CREATE OBJECT go_cont_trans_note EXPORTING container_name = 'CC_TRANS_NOTE'.
+        CREATE OBJECT go_edit_trans_note EXPORTING parent = go_cont_trans_note.
+        go_edit_trans_note->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_trans_note->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Transition Note editor. Check Custom Control CC_TRANS_NOTE on screen 0370.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+    ENDTRY.
+  ENDIF.
+
+  " 5. Enable/Disable fields based on current status + role
+  "    (calls modify_screen_0370 FORM in CODE_F01)
+  PERFORM modify_screen_0370.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0210 — BUG SEARCH INPUT (Modal Dialog popup)
+*&=====================================================================*
+MODULE status_0210 OUTPUT.
+  SET PF-STATUS 'STATUS_0210'.
+  SET TITLEBAR 'T_0210'.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0220 — BUG SEARCH RESULTS (Full screen ALV)
+*&=====================================================================*
+MODULE status_0220 OUTPUT.
+  SET PF-STATUS 'STATUS_0220'.
+  SET TITLEBAR 'T_0220'.
+ENDMODULE.
+
+MODULE init_search_results OUTPUT.
+  IF go_cont_search IS INITIAL.
+    CREATE OBJECT go_cont_search EXPORTING container_name = 'CC_SEARCH_RESULTS'.
+    CREATE OBJECT go_search_alv  EXPORTING i_parent = go_cont_search.
+    " Use dedicated build_search_fieldcat (tabname GT_SEARCH_RESULTS)
+    PERFORM build_search_fieldcat.
+    DATA: ls_slayo TYPE lvc_s_layo.
+    ls_slayo-zebra      = 'X'.
+    ls_slayo-cwidth_opt = 'X'.
+    ls_slayo-sel_mode   = 'A'.   " Multiple-row selection
+    ls_slayo-ctab_fname = 'T_COLOR'.
+    go_search_alv->set_table_for_first_display(
+      EXPORTING is_layout      = ls_slayo
+      CHANGING  it_outtab      = gt_search_results
+                it_fieldcatalog = gt_fcat_search ).
+    " Register hotspot handler (click BUG_ID → open Bug Detail)
+    IF go_event_handler IS INITIAL.
+      CREATE OBJECT go_event_handler.
+    ENDIF.
+    SET HANDLER go_event_handler->handle_hotspot_click FOR go_search_alv.
+  ELSE.
+    go_search_alv->refresh_table_display( ).
+  ENDIF.
+ENDMODULE.
+
+*&=====================================================================*
+*& SCREEN 0400: PROJECT LIST
+*& No longer initial screen — 0410 is the new initial screen.
+*& Called via CALL SCREEN 0400 from Screen 0410.
 *&=====================================================================*
 MODULE status_0400 OUTPUT.
   CLEAR gm_excl.
@@ -447,7 +594,16 @@
 ENDMODULE.
 
 MODULE init_project_list OUTPUT.
-  PERFORM select_project_data.
+  " If coming from Screen 0410 search, data already loaded
+  " (gv_from_search flag set by search_projects FORM in CODE_F01)
+  IF gv_from_search = abap_true.
+    " Skip select_project_data — gt_projects already populated by search_projects
+    CLEAR gv_from_search.
+  ELSE.
+    " Normal reload (BACK from 0200, REFRESH button, etc.)
+    PERFORM select_project_data.
+  ENDIF.
+
   IF go_alv_project IS INITIAL.
     CREATE OBJECT go_cont_project EXPORTING container_name = 'CC_PROJECT_LIST'.
     CREATE OBJECT go_alv_project  EXPORTING i_parent = go_cont_project.
@@ -484,7 +640,7 @@
     APPEND 'ADD_USER' TO gm_excl.
     APPEND 'REMO_USR' TO gm_excl.
   ENDIF.
-  " v4.1 BUGFIX #1: Create mode → hide ADD_USER/REMO_USR
+  " Create mode → hide ADD_USER/REMO_USR
   " Project not yet saved → gv_current_project_id is empty → add user would fail
   IF gv_mode = gc_mode_create.
     APPEND 'ADD_USER' TO gm_excl.
@@ -510,6 +666,9 @@
     RETURN.
   ENDIF.
 
+  " Reset table control selection flag on fresh load
+  CLEAR gv_tc_user_selected.
+
   IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
     SELECT SINGLE * FROM zbug_project INTO @gs_project
       WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
@@ -519,13 +678,13 @@
 
   IF gv_mode = gc_mode_create.
     CLEAR: gs_project, gt_user_project.
-    " v4.1 BUGFIX #1: Show placeholder — PROJECT_ID will be auto-generated on save
+    " Show placeholder — PROJECT_ID will be auto-generated on save
     gs_project-project_id      = '(Auto)'.
     gs_project-project_manager = gv_uname.  " Default manager = current user
     gs_project-project_status  = '1'.       " Opening
   ENDIF.
 
-  " v4.0: Save snapshot for unsaved changes detection
+  " Save snapshot for unsaved changes detection
   gs_prj_snapshot = gs_project.
 
   gv_prj_detail_loaded = abap_true.
@@ -553,7 +712,7 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " v4.1 BUGFIX #1/#3: PROJECT_ID ALWAYS display-only (primary key, auto-generated)
+    " PROJECT_ID ALWAYS display-only (primary key, auto-generated)
     IF screen-group1 = 'PID'.
       screen-input = 0.
       MODIFY SCREEN.
```

### CODE_TOP.md — modified

`+152 / -79 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -1,13 +1,7 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_TOP — Global Declarations (v4.0)
+*& Include Z_BUG_WS_TOP — Global Declarations
 *&---------------------------------------------------------------------*
-*& v4.0 changes (over v3.0):
-*&  - Evidence ALV objects (go_cont_evidence, go_alv_evidence)
-*&  - Evidence field catalog (gt_fcat_evidence)
-*&  - Evidence ALV type (ty_evidence_alv — metadata only, no CONTENT)
-*&  - Evidence internal table (gt_evidence)
-*&  - Snapshot variables (gs_bug_snapshot, gs_prj_snapshot) for unsaved detection
-*&---------------------------------------------------------------------*
+
 " === FORWARD DECLARATION ===
 CLASS lcl_event_handler DEFINITION DEFERRED.
 
@@ -17,17 +11,20 @@
   gc_mode_change  TYPE char1 VALUE 'C',
   gc_mode_create  TYPE char1 VALUE 'X'.
 
-" === BUG STATUS CONSTANTS (9-state lifecycle) ===
+" === BUG STATUS CONSTANTS (10-state lifecycle) ===
+" BREAKING CHANGE: '6' WAS Resolved in v4.x → NOW Final Testing
+"                  'V' is the NEW Resolved (terminal state)
 CONSTANTS:
-  gc_st_new        TYPE zde_bug_status VALUE '1',
-  gc_st_assigned   TYPE zde_bug_status VALUE '2',
-  gc_st_inprogress TYPE zde_bug_status VALUE '3',
-  gc_st_pending    TYPE zde_bug_status VALUE '4',
-  gc_st_fixed      TYPE zde_bug_status VALUE '5',
-  gc_st_resolved   TYPE zde_bug_status VALUE '6',
-  gc_st_closed     TYPE zde_bug_status VALUE '7',
-  gc_st_waiting    TYPE zde_bug_status VALUE 'W',
-  gc_st_rejected   TYPE zde_bug_status VALUE 'R'.
+  gc_st_new          TYPE zde_bug_status VALUE '1',       " New
+  gc_st_assigned     TYPE zde_bug_status VALUE '2',       " Assigned
+  gc_st_inprogress   TYPE zde_bug_status VALUE '3',       " In Progress
+  gc_st_pending      TYPE zde_bug_status VALUE '4',       " Pending
+  gc_st_fixed        TYPE zde_bug_status VALUE '5',       " Fixed
+  gc_st_finaltesting TYPE zde_bug_status VALUE '6',       " Final Testing
+  gc_st_closed       TYPE zde_bug_status VALUE '7',       " Closed (legacy)
+  gc_st_waiting      TYPE zde_bug_status VALUE 'W',       " Waiting
+  gc_st_rejected     TYPE zde_bug_status VALUE 'R',       " Rejected
+  gc_st_resolved     TYPE zde_bug_status VALUE 'V'.       " Resolved (terminal state)
 
 " === GLOBAL VARIABLES ===
 DATA: gv_ok_code   TYPE sy-ucomm,
@@ -38,22 +35,29 @@
       gv_current_bug_id     TYPE zde_bug_id,
       gv_current_project_id TYPE zde_project_id.
 
-" === PBO DATA-LOADING FLAGS (v3.0 — prevent reload on tab switch) ===
-" Set to abap_true after first DB load; cleared before each CALL SCREEN
+" === PBO DATA-LOADING FLAGS (prevent reload on tab switch) ===
 DATA: gv_detail_loaded     TYPE abap_bool,   " Bug Detail (Screen 0300)
       gv_prj_detail_loaded TYPE abap_bool.   " Project Detail (Screen 0500)
 
-" === BUG LIST FILTER MODE (Project-first flow) ===
+" === BUG LIST FILTER MODE ===
 " 'P' = Project mode (all bugs of a project, no role filter)
 " 'M' = My Bugs mode (cross-project, filtered by role)
 DATA: gv_bug_filter_mode TYPE char1.
 
-" === DISPLAY TEXT VARIABLES (for Screen fields — mapped from raw codes) ===
-DATA: gv_status_disp     TYPE char20,    " Status text for Screen 0310
-      gv_priority_disp   TYPE char10,    " Priority text for Screen 0310
-      gv_severity_disp   TYPE char20,    " Severity text for Screen 0310
-      gv_bug_type_disp   TYPE char20,    " Bug Type text for Screen 0310
-      gv_prj_status_disp TYPE char20.    " Project Status text for Screen 0500
+" === NAVIGATION FLAGS ===
+" gv_from_search: tells PBO init_project_list to skip select_project_data
+"   (data already loaded by search_projects). Cleared when BACK from 0400.
+DATA: gv_from_search     TYPE abap_bool.
+" gv_search_executed: set in user_command_0210 when EXECUTE pressed;
+"   checked in user_command_0200 to navigate to 0220 after modal closes.
+DATA: gv_search_executed TYPE abap_bool.
+
+" === DISPLAY TEXT VARIABLES (mapped from raw codes for Screen fields) ===
+DATA: gv_status_disp     TYPE char20,
+      gv_priority_disp   TYPE char10,
+      gv_severity_disp   TYPE char20,
+      gv_bug_type_disp   TYPE char20,
+      gv_prj_status_disp TYPE char20.
 
 " === TAB STRIP (Screen 0300) ===
 DATA: gv_active_tab       TYPE char20 VALUE 'TAB_INFO',
@@ -67,9 +71,13 @@
       go_cont_history TYPE REF TO cl_gui_custom_container,
       go_alv_history  TYPE REF TO cl_gui_alv_grid.
 
-" === v4.0: EVIDENCE ALV (Subscreen 0350, container CC_EVIDENCE) ===
+" === EVIDENCE ALV (Subscreen 0350, container CC_EVIDENCE) ===
 DATA: go_cont_evidence TYPE REF TO cl_gui_custom_container,
       go_alv_evidence  TYPE REF TO cl_gui_alv_grid.
+
+" === SEARCH RESULTS ALV (Screen 0220, container CC_SEARCH_RESULTS) ===
+DATA: go_cont_search TYPE REF TO cl_gui_custom_container,
+      go_search_alv  TYPE REF TO cl_gui_alv_grid.
 
 " === TEXT EDIT OBJECTS (subscreens 0320/0330/0340) ===
 DATA: go_cont_desc      TYPE REF TO cl_gui_custom_container,
@@ -83,82 +91,90 @@
 DATA: go_desc_mini_cont TYPE REF TO cl_gui_custom_container,
       go_desc_mini_edit TYPE REF TO cl_gui_textedit.
 
-" === FIELD CATALOGS (Column Definitions) ===
+" === TRANSITION NOTE EDITOR (Screen 0370 popup) ===
+DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
+      go_edit_trans_note TYPE REF TO cl_gui_textedit.
+
+" === FIELD CATALOGS ===
 DATA: gt_fcat_bug      TYPE lvc_t_fcat,
       gt_fcat_project  TYPE lvc_t_fcat,
       gt_fcat_history  TYPE lvc_t_fcat,
-      gt_fcat_evidence TYPE lvc_t_fcat.    " v4.0
+      gt_fcat_evidence TYPE lvc_t_fcat,
+      gt_fcat_search   TYPE lvc_t_fcat.    " Bug Search Results
 
 " === INTERNAL TABLES & WORK AREAS ===
-" ALV Bug Data — khớp chính xác với ZBUG_TRACKER fields + display text columns
+" Bug ALV — matches ZBUG_TRACKER fields + display text columns
 TYPES: BEGIN OF ty_bug_alv,
-         bug_id           TYPE zde_bug_id,        " CHAR 10
-         title            TYPE zde_bug_title,      " CHAR 100
-         project_id       TYPE zde_project_id,     " CHAR 20
-         status           TYPE zde_bug_status,     " CHAR 20 — đúng theo SE11
-         status_text      TYPE char20,             " Display: New/Assigned/...
-         priority         TYPE zde_priority,       " CHAR 1
-         priority_text    TYPE char10,             " Display: High/Medium/Low
-         severity         TYPE zde_severity,       " CHAR 1
-         severity_text    TYPE char20,             " Display: Dump/VeryHigh/...
-         bug_type         TYPE zde_bug_type,       " CHAR 1
-         bug_type_text    TYPE char20,             " Display: Functional/Performance/...
-         tester_id        TYPE zde_username,        " CHAR 12
-         verify_tester_id TYPE zde_username,        " CHAR 12
-         dev_id           TYPE zde_username,        " CHAR 12
-         sap_module       TYPE zde_sap_module,      " CHAR 20 — đúng theo SE11
-         created_at       TYPE zde_bug_cr_date,     " DATS 8
-         t_color          TYPE lvc_t_scol,          " Row color
+         bug_id           TYPE zde_bug_id,
+         title            TYPE zde_bug_title,
+         project_id       TYPE zde_project_id,
+         status           TYPE zde_bug_status,     " CHAR 20
+         status_text      TYPE char20,
+         priority         TYPE zde_priority,
+         priority_text    TYPE char10,
+         severity         TYPE zde_severity,
+         severity_text    TYPE char20,
+         bug_type         TYPE zde_bug_type,
+         bug_type_text    TYPE char20,
+         tester_id        TYPE zde_username,
+         verify_tester_id TYPE zde_username,
+         dev_id           TYPE zde_username,
+         sap_module       TYPE zde_sap_module,
+         created_at       TYPE zde_bug_cr_date,
+         t_color          TYPE lvc_t_scol,
        END OF ty_bug_alv.
 
 DATA: gt_bugs       TYPE TABLE OF ty_bug_alv,
       gs_bug_detail TYPE zbug_tracker.
 
-" v4.0: Snapshot of bug detail for unsaved changes detection
+" Snapshot for unsaved changes detection
 DATA: gs_bug_snapshot TYPE zbug_tracker.
 
-" ALV Project Data — khớp với ZBUG_PROJECT fields
+" Search Results (reuses ty_bug_alv for consistent ALV columns)
+DATA: gt_search_results TYPE TABLE OF ty_bug_alv.
+
+" Project ALV — matches ZBUG_PROJECT fields
 TYPES: BEGIN OF ty_project_alv,
-         project_id      TYPE zde_project_id,      " CHAR 20
-         project_name    TYPE zde_prj_name,         " CHAR 100
-         description     TYPE zde_prj_desc,         " CHAR 255
-         project_status  TYPE zde_prj_status,       " CHAR 1
-         status_text     TYPE char20,               " Display: Opening/In Process/...
-         start_date      TYPE sydatum,              " DATS 8
-         end_date        TYPE sydatum,              " DATS 8
-         project_manager TYPE zde_username,          " CHAR 12
-         note            TYPE char255,              " CHAR 255
+         project_id      TYPE zde_project_id,
+         project_name    TYPE zde_prj_name,
+         description     TYPE zde_prj_desc,
+         project_status  TYPE zde_prj_status,
+         status_text     TYPE char20,
+         start_date      TYPE sydatum,
+         end_date        TYPE sydatum,
+         project_manager TYPE zde_username,
+         note            TYPE char255,
          t_color         TYPE lvc_t_scol,
        END OF ty_project_alv.
 
 DATA: gt_projects TYPE TABLE OF ty_project_alv,
       gs_project  TYPE zbug_project.
 
-" v4.0: Snapshot of project for unsaved changes detection
+" Snapshot for unsaved changes detection
 DATA: gs_prj_snapshot TYPE zbug_project.
 
-" ALV History Data — khớp với ZBUG_HISTORY fields
+" History ALV — matches ZBUG_HISTORY fields
 TYPES: BEGIN OF ty_history_alv,
-         changed_at   TYPE zde_bug_cr_date,    " DATS 8
-         changed_time TYPE zde_bug_cr_time,    " TIMS 6
-         changed_by   TYPE zde_username,       " CHAR 12
-         action_type  TYPE zde_bug_act_type,   " CHAR 2
+         changed_at   TYPE zde_bug_cr_date,
+         changed_time TYPE zde_bug_cr_time,
+         changed_by   TYPE zde_username,
+         action_type  TYPE zde_bug_act_type,
          action_text  TYPE char30,
-         old_value    TYPE zde_bug_title,      " CHAR 100 — matches OLD_VALUE data element
-         new_value    TYPE zde_bug_title,      " CHAR 100 — matches NEW_VALUE data element
-         reason       TYPE string,             " STRING — matches ZBUG_HISTORY-REASON
+         old_value    TYPE zde_bug_title,
+         new_value    TYPE zde_bug_title,
+         reason       TYPE string,
        END OF ty_history_alv.
 
 DATA: gt_history TYPE TABLE OF ty_history_alv.
 
-" v4.0: Evidence ALV Data — metadata only (no CONTENT for performance)
+" Evidence ALV — metadata only (no CONTENT for performance)
 TYPES: BEGIN OF ty_evidence_alv,
-         evd_id    TYPE numc10,          " Evidence ID
-         file_name TYPE sdok_filnm,      " File name (CHAR 255)
-         mime_type TYPE w3conttype,       " MIME type (CHAR 128)
-         file_size TYPE int4,            " File size in bytes
-         ernam     TYPE ernam,           " Created by
-         erdat     TYPE erdat,           " Created date
+         evd_id    TYPE numc10,
+         file_name TYPE sdok_filnm,
+         mime_type TYPE w3conttype,
+         file_size TYPE int4,
+         ernam     TYPE ernam,
+         erdat     TYPE erdat,
        END OF ty_evidence_alv.
 
 DATA: gt_evidence TYPE TABLE OF ty_evidence_alv.
@@ -173,8 +189,65 @@
 " === EVENT HANDLER OBJECT ===
 DATA: go_event_handler TYPE REF TO lcl_event_handler.
 
-" === MODULE-LEVEL WORK VARIABLES (global — Module Pool DATA in MODULE has no local scope) ===
+" === Screen 0410 — Project Search Fields ===
+DATA: s_prj_id TYPE zde_project_id,
+      s_prj_mn TYPE uname,
+      s_prj_st TYPE char1.
+
+" === Screen 0370 — Status Transition Popup Variables ===
+DATA: gv_trans_bug_id      TYPE zde_bug_id,
+      gv_trans_title       TYPE zde_bug_title,
+      gv_trans_reporter    TYPE zde_username,
+      gv_trans_cur_status  TYPE zde_bug_status,
+      gv_trans_cur_st_text TYPE char20,
+      gv_trans_new_status  TYPE zde_bug_status,
+      gv_trans_dev_id      TYPE zde_username,
+      gv_trans_ftester_id  TYPE zde_username,
+      gv_trans_confirmed   TYPE abap_bool.
+
+" === Screen 0210 — Bug Search Fields ===
+DATA: s_bug_id   TYPE zde_bug_id,
+      s_title    TYPE char40,          " Wildcard search
+      s_status   TYPE zde_bug_status,
+      s_prio     TYPE char10,
+      s_mod      TYPE zde_sap_module,
+      s_reporter TYPE char12,
+      s_dev      TYPE char12.
+
+" === Dashboard Metrics (Screen 0200) ===
+DATA: gv_dash_total    TYPE i,
+      " By Status
+      gv_d_new         TYPE i,
+      gv_d_assigned    TYPE i,
+      gv_d_inprog      TYPE i,
+      gv_d_pending     TYPE i,
+      gv_d_fixed       TYPE i,
+      gv_d_finaltest   TYPE i,
+      gv_d_resolved    TYPE i,
+      gv_d_rejected    TYPE i,
+      gv_d_waiting     TYPE i,
+      gv_d_closed      TYPE i,
+      " By Priority
+      gv_d_p_high      TYPE i,
+      gv_d_p_med       TYPE i,
+      gv_d_p_low       TYPE i,
+      " By Module
+      gv_d_m_fi        TYPE i,
+      gv_d_m_mm        TYPE i,
+      gv_d_m_sd        TYPE i,
+      gv_d_m_abap      TYPE i,
+      gv_d_m_basis     TYPE i.
+
+" === Custom TYPE for save_long_text_direct table parameter ===
+TYPES: gty_t_char255 TYPE TABLE OF char255.
+
+" === TABLE CONTROL SELECTION FLAG (Screen 0500) ===
+" tc_users-current_line defaults to 1 when table has data,
+" even if user never clicked a row. This flag tracks actual clicks.
+DATA: gv_tc_user_selected TYPE abap_bool.
+
+" === MODULE-LEVEL WORK VARIABLES ===
 DATA: gm_excl     TYPE TABLE OF sy-ucomm,  " Reused by all status_XXXX modules
-      gm_layo_bug TYPE lvc_s_layo,          " Layout for Bug ALV
-      gm_layo_prj TYPE lvc_s_layo,          " Layout for Project ALV
-      gm_title    TYPE string.              " Title buffer for SET TITLEBAR
+      gm_layo_bug TYPE lvc_s_layo,
+      gm_layo_prj TYPE lvc_s_layo,
+      gm_title    TYPE string.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
