# Analysis v9

### CODE_F01.md — modified

`+60 / -18 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -171,10 +171,11 @@
     COMMIT WORK.
     " Set current bug id BEFORE saving long texts
     gv_current_bug_id = gs_bug_detail-bug_id.
-    " Save long text tabs (SAVE_TEXT performs its own COMMIT internally)
+    " Save long text tabs (SAVE_TEXT buffers changes — needs explicit COMMIT)
     PERFORM save_long_text USING 'Z001'.  " Description
     PERFORM save_long_text USING 'Z002'.  " Dev Note
     PERFORM save_long_text USING 'Z003'.  " Tester Note
+    COMMIT WORK.                          " Flush SAVE_TEXT buffer to DB
 
     " Sync desc_text from editor after save_long_text
     IF go_edit_desc IS NOT INITIAL.
@@ -319,6 +320,8 @@
     gv_mode = gc_mode_change.
     " Update snapshot after successful save
     gs_prj_snapshot = gs_project.
+    " Signal project list to reload on next PBO (Bug 2 fix)
+    gv_prj_list_dirty = abap_true.
   ELSE.
     ROLLBACK WORK.
     MESSAGE 'Project save failed. Project ID may already exist.' TYPE 'S' DISPLAY LIKE 'E'.
@@ -432,6 +435,8 @@
   IF sy-subrc = 0.
     COMMIT WORK.
     MESSAGE |Project { gv_current_project_id } deleted.| TYPE 'S'.
+    " Signal project list to reload on next PBO (Bug 2 fix)
+    gv_prj_list_dirty = abap_true.
     PERFORM select_project_data.
     IF go_alv_project IS NOT INITIAL.
       go_alv_project->refresh_table_display( ).
@@ -564,37 +569,74 @@
   ENDIF.
 ENDFORM.
 
-*&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
-*& Uses tc_users-current_line to determine which row to delete.
-*& Range check guards against invalid row index.
+*&=== PROJECT USER MANAGEMENT: REMOVE (F4 popup selection) ===*
+*& Uses F4IF_INT_TABLE_VALUE_REQUEST popup to let user pick which user
+*& to remove — avoids tc_users-current_line unreliability (Bug 4 fix).
 FORM remove_user_from_project.
-  DATA: lv_line TYPE i.
-  lv_line = tc_users-current_line.
-
-  " Validate range — prevent deleting wrong row
-  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
-    MESSAGE 'Invalid row selection.' TYPE 'S' DISPLAY LIKE 'W'.
+  " Build value table from current project users
+  TYPES: BEGIN OF ty_up_f4,
+           user_id TYPE zde_username,
+           role    TYPE zde_bug_role,
+         END OF ty_up_f4.
+  DATA: lt_val TYPE TABLE OF ty_up_f4,
+        lt_ret TYPE TABLE OF ddshretval,
+        ls_val TYPE ty_up_f4.
+
+  IF gt_user_project IS INITIAL.
+    MESSAGE 'No users assigned to this project.' TYPE 'S' DISPLAY LIKE 'W'.
     RETURN.
   ENDIF.
 
-  READ TABLE gt_user_project INTO gs_user_project INDEX lv_line.
-  IF sy-subrc <> 0. RETURN. ENDIF.
-
+  " Populate F4 value table from gt_user_project
+  LOOP AT gt_user_project INTO gs_user_project.
+    ls_val-user_id = gs_user_project-user_id.
+    ls_val-role    = gs_user_project-role.
+    APPEND ls_val TO lt_val.
+  ENDLOOP.
+
+  " Show F4 popup — user picks which user to remove
+  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
+    EXPORTING
+      retfield    = 'USER_ID'
+      value_org   = 'S'
+      window_title = 'Select User to Remove'
+    TABLES
+      value_tab   = lt_val
+      return_tab  = lt_ret
+    EXCEPTIONS
+      OTHERS      = 1.
+
+  " Check if user made a selection
+  IF lt_ret IS INITIAL.
+    RETURN.  " User cancelled
+  ENDIF.
+
+  DATA: lv_sel_user TYPE zde_username.
+  READ TABLE lt_ret INTO DATA(ls_ret) INDEX 1.
+  lv_sel_user = ls_ret-fieldval.
+
+  IF lv_sel_user IS INITIAL.
+    RETURN.  " Empty selection
+  ENDIF.
+
+  " Confirm deletion
   DATA: lv_confirmed TYPE abap_bool,
         lv_msg       TYPE string.
-  lv_msg = |Remove user { gs_user_project-user_id } from project?|.
+  lv_msg = |Remove user { lv_sel_user } from project?|.
   PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
   CHECK lv_confirmed = abap_true.
 
+  " Delete from DB
   DELETE FROM zbug_user_projec
     WHERE project_id = @gv_current_project_id
-      AND user_id    = @gs_user_project-user_id.
+      AND user_id    = @lv_sel_user.
   IF sy-subrc = 0.
     COMMIT WORK.
-    DELETE gt_user_project INDEX lv_line.
-    " Reset flag after successful remove
+    " Remove from internal table
+    DELETE gt_user_project WHERE user_id = lv_sel_user.
+    tc_users-lines = lines( gt_user_project ).
     CLEAR gv_tc_user_selected.
-    MESSAGE |User { gs_user_project-user_id } removed.| TYPE 'S'.
+    MESSAGE |User { lv_sel_user } removed.| TYPE 'S'.
   ELSE.
     ROLLBACK WORK.
     MESSAGE 'Remove failed.' TYPE 'S' DISPLAY LIKE 'E'.
```

### CODE_F02.md — modified

`+2 / -0 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -579,6 +579,7 @@
   CALL FUNCTION 'SAVE_TEXT'
     EXPORTING
       header          = ls_header
+      savemode_direct = 'X'
     TABLES
       lines           = lt_lines
     EXCEPTIONS
@@ -630,6 +631,7 @@
   CALL FUNCTION 'SAVE_TEXT'
     EXPORTING
       header          = ls_header
+      savemode_direct = 'X'
     TABLES
       lines           = lt_lines
     EXCEPTIONS
```

### CODE_PAI.md — modified

`+2 / -1 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -389,7 +389,8 @@
         MESSAGE 'Please select a project to delete.' TYPE 'W'.
       ENDIF.
     WHEN 'REFRESH'.
-      PERFORM select_project_data.
+      " Reload with search filters preserved (Bug 2 fix)
+      PERFORM search_projects.
       IF go_alv_project IS NOT INITIAL.
         go_alv_project->refresh_table_display( ).
       ENDIF.
```

### CODE_PBO.md — modified

`+12 / -2 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -592,6 +592,10 @@
   IF gv_from_search = abap_true.
     " Skip select_project_data — gt_projects already populated by search_projects
     CLEAR gv_from_search.
+  ELSEIF gv_prj_list_dirty = abap_true.
+    " Project was saved/deleted — reload with current search filters preserved
+    PERFORM search_projects.
+    CLEAR gv_prj_list_dirty.
   ELSEIF go_alv_project IS INITIAL.
     " First load only — subsequent returns from 0200/0500 keep existing data
     PERFORM select_project_data.
@@ -711,8 +715,14 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " Hide old Description/Note I/O fields (replaced by CL_GUI_TEXTEDIT editors)
-    IF screen-name = 'GS_PROJECT-DESCRIPTION' OR screen-name = 'GS_PROJECT-NOTE'.
+    " Hide old Description/Note I/O fields ONLY when editors were created successfully.
+    " Fallback: if Custom Controls missing (e.g., Mac alphanumeric Screen Painter),
+    " old I/O fields remain visible + editable so user can still enter text.
+    IF screen-name = 'GS_PROJECT-DESCRIPTION' AND go_edit_prj_desc IS NOT INITIAL.
+      screen-active = 0.
+      MODIFY SCREEN.
+    ENDIF.
+    IF screen-name = 'GS_PROJECT-NOTE' AND go_edit_prj_note IS NOT INITIAL.
       screen-active = 0.
       MODIFY SCREEN.
     ENDIF.
```

### CODE_TOP.md — modified

`+3 / -0 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -51,6 +51,9 @@
 " gv_search_executed: set in user_command_0210 when EXECUTE pressed;
 "   checked in user_command_0200 to navigate to 0220 after modal closes.
 DATA: gv_search_executed TYPE abap_bool.
+" gv_prj_list_dirty: set after save/delete project → tells PBO to reload
+"   project list via search_projects (preserving filters) on next 0400 PBO.
+DATA: gv_prj_list_dirty  TYPE abap_bool.
 
 " === DISPLAY TEXT VARIABLES (mapped from raw codes for Screen fields) ===
 DATA: gv_status_disp     TYPE char20,
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
