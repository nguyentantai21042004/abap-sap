# Analysis v7

### CODE_F01.md — modified

`+4 / -11 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -562,16 +562,9 @@
 ENDFORM.
 
 *&=== PROJECT USER MANAGEMENT: REMOVE (selected row from Table Control) ===*
-*& Guard: tc_users-current_line defaults to 1 even without a click.
-*& Uses gv_tc_user_selected flag (set in tc_users_modify) to confirm
-*& the user actually interacted with the table control.
+*& Uses tc_users-current_line to determine which row to delete.
+*& Range check guards against invalid row index.
 FORM remove_user_from_project.
-  " Require explicit user interaction before allowing remove
-  IF gv_tc_user_selected = abap_false.
-    MESSAGE 'Please click on a user row to select it first.' TYPE 'S' DISPLAY LIKE 'W'.
-    RETURN.
-  ENDIF.
-
   DATA: lv_line TYPE i.
   lv_line = tc_users-current_line.
 
@@ -910,12 +903,12 @@
     " 9. Set ATT_ field if applicable
     CASE pv_att_field.
       WHEN 'REP'.
-        gs_bug_detail-att_report = lv_fname_only(100).  " Truncate to CHAR 100
+        gs_bug_detail-att_report = lv_fname_only.  " Auto-truncated to CHAR 100
         UPDATE zbug_tracker SET att_report = @gs_bug_detail-att_report
           WHERE bug_id = @gv_current_bug_id.
         COMMIT WORK.
       WHEN 'FIX'.
-        gs_bug_detail-att_fix = lv_fname_only(100).     " Truncate to CHAR 100
+        gs_bug_detail-att_fix = lv_fname_only.     " Auto-truncated to CHAR 100
         UPDATE zbug_tracker SET att_fix = @gs_bug_detail-att_fix
           WHERE bug_id = @gv_current_bug_id.
         COMMIT WORK.
```

### CODE_F02.md — modified

`+10 / -1 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -583,7 +583,11 @@
       lines           = lt_lines
     EXCEPTIONS
       OTHERS          = 4.
-  " Note: SAVE_TEXT performs its own internal COMMIT
+  IF sy-subrc <> 0.
+    DATA: lv_save_msg TYPE string.
+    lv_save_msg = |Long text { pv_text_id } save failed (RC={ sy-subrc }). Check text object ZBUG in SE75.|.
+    MESSAGE lv_save_msg TYPE 'S' DISPLAY LIKE 'W'.
+  ENDIF.
 ENDFORM.
 
 *&=====================================================================*
@@ -630,6 +634,11 @@
       lines           = lt_lines
     EXCEPTIONS
       OTHERS          = 4.
+  IF sy-subrc <> 0.
+    DATA: lv_save_msg TYPE string.
+    lv_save_msg = |Long text { pv_text_id } save failed (RC={ sy-subrc }). Check text object ZBUG in SE75.|.
+    MESSAGE lv_save_msg TYPE 'S' DISPLAY LIKE 'W'.
+  ENDIF.
 ENDFORM.
 
 *&=====================================================================*
```

### CODE_PBO.md — modified

`+9 / -18 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -112,26 +112,19 @@
 *&=====================================================================*
 MODULE status_0300 OUTPUT.
   CLEAR gm_excl.
+  " UP_REP + UP_FIX hidden for ALL roles/modes (feature disabled — causes dump)
+  APPEND 'UP_REP' TO gm_excl.
+  APPEND 'UP_FIX' TO gm_excl.
   " Display mode: hide SAVE + upload buttons + email + delete evidence + status change
   IF gv_mode = gc_mode_display.
     APPEND 'SAVE'       TO gm_excl.
     APPEND 'SENDMAIL'   TO gm_excl.
     APPEND 'STATUS_CHG' TO gm_excl.
   ENDIF.
-  " Tester cannot upload fix
-  IF gv_role = 'T'.
-    APPEND 'UP_FIX' TO gm_excl.
-  ENDIF.
-  " Developer cannot upload report
-  IF gv_role = 'D'.
-    APPEND 'UP_REP' TO gm_excl.
-  ENDIF.
   " Create mode: hide status change + some uploads + email + delete evidence
   " UP_FILE is allowed in create mode (auto-save before upload)
   IF gv_mode = gc_mode_create.
     APPEND 'STATUS_CHG' TO gm_excl.
-    APPEND 'UP_REP'     TO gm_excl.
-    APPEND 'UP_FIX'     TO gm_excl.
     APPEND 'SENDMAIL'   TO gm_excl.    " No email for unsaved bug
     APPEND 'DL_EVD'     TO gm_excl.    " No delete evidence before save
     APPEND 'DW_EVD'     TO gm_excl.    " No download evidence before save
@@ -139,8 +132,6 @@
   " Display mode: hide upload + delete evidence
   IF gv_mode = gc_mode_display.
     APPEND 'UP_FILE' TO gm_excl.
-    APPEND 'UP_REP'  TO gm_excl.
-    APPEND 'UP_FIX'  TO gm_excl.
     APPEND 'DL_EVD'  TO gm_excl.
   ENDIF.
   SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.
@@ -583,13 +574,14 @@
 *&=====================================================================*
 MODULE status_0400 OUTPUT.
   CLEAR gm_excl.
-  " Only Manager can create/change/delete projects + upload/download
+  " Excel upload/download hidden for ALL roles (feature disabled)
+  APPEND 'UPLOAD'   TO gm_excl.
+  APPEND 'DN_TMPL'  TO gm_excl.
+  " Only Manager can create/change/delete projects
   IF gv_role <> 'M'.
     APPEND 'CREA_PRJ' TO gm_excl.
     APPEND 'CHNG_PRJ' TO gm_excl.
     APPEND 'DEL_PRJ'  TO gm_excl.
-    APPEND 'UPLOAD'   TO gm_excl.
-    APPEND 'DN_TMPL'  TO gm_excl.
   ENDIF.
   SET PF-STATUS 'STATUS_0400' EXCLUDING gm_excl.
   SET TITLEBAR 'TITLE_PROJLIST' WITH 'Project List'.
@@ -597,12 +589,11 @@
 
 MODULE init_project_list OUTPUT.
   " If coming from Screen 0410 search, data already loaded
-  " (gv_from_search flag set by search_projects FORM in CODE_F01)
   IF gv_from_search = abap_true.
     " Skip select_project_data — gt_projects already populated by search_projects
     CLEAR gv_from_search.
-  ELSE.
-    " Normal reload (BACK from 0200, REFRESH button, etc.)
+  ELSEIF go_alv_project IS INITIAL.
+    " First load only — subsequent returns from 0200/0500 keep existing data
     PERFORM select_project_data.
   ENDIF.
 
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
