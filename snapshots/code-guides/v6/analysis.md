# Analysis v6

### CODE_F01.md — modified

`+80 / -20 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -14,22 +14,16 @@
       WHERE project_id = @gv_current_project_id
         AND is_del <> 'X'.
   ELSE.
-    " ---- MY BUGS MODE: filter by role (cross-project) ----
-    CASE gv_role.
-      WHEN 'T'. " Tester: bugs mình tạo hoặc được assign verify
-        SELECT * FROM zbug_tracker
-          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
-          WHERE ( tester_id = @gv_uname OR verify_tester_id = @gv_uname )
-            AND is_del <> 'X'.
-      WHEN 'D'. " Developer: bugs được assign cho mình
-        SELECT * FROM zbug_tracker
-          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
-          WHERE dev_id = @gv_uname AND is_del <> 'X'.
-      WHEN 'M'. " Manager: tất cả bugs
-        SELECT * FROM zbug_tracker
-          INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
-          WHERE is_del <> 'X'.
-    ENDCASE.
+    " ---- MY BUGS MODE: all bugs where current user is involved (role-agnostic) ----
+    " Shows bugs where user is tester, developer, verify tester, or creator.
+    " This replaces the old role-based CASE block that missed cross-role bugs.
+    SELECT * FROM zbug_tracker
+      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs
+      WHERE ( tester_id = @gv_uname
+              OR dev_id = @gv_uname
+              OR verify_tester_id = @gv_uname
+              OR ernam = @gv_uname )
+        AND is_del <> 'X'.
   ENDIF.
 
   " Status text mapping (10 states — 6=FinalTesting, V=Resolved)
@@ -557,9 +551,10 @@
   IF sy-subrc = 0.
     COMMIT WORK.
     MESSAGE |User { lv_uid } added to project { gv_current_project_id }.| TYPE 'S'.
-    " Reload user list
+    " Reload user list + update table control scrollbar
     SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
       WHERE project_id = @gv_current_project_id.
+    tc_users-lines = lines( gt_user_project ).
   ELSE.
     ROLLBACK WORK.
     MESSAGE |User { lv_uid } is already assigned to this project.| TYPE 'W'.
@@ -1079,7 +1074,31 @@
 ENDFORM.
 
 *&=====================================================================*
-*& CHECK EVIDENCE FOR STATUS TRANSITION
+*& DOWNLOAD EVIDENCE (selected row from Evidence ALV via button)
+*& Fcode DW_EVD — explicit download button (supplement to double-click)
+*&=====================================================================*
+FORM download_evidence_selected.
+  CHECK go_alv_evidence IS NOT INITIAL.
+
+  DATA: lt_rows TYPE lvc_t_roid.
+  go_alv_evidence->get_selected_rows( IMPORTING et_row_no = lt_rows ).
+  IF lt_rows IS INITIAL.
+    MESSAGE 'Please select an evidence file to download.' TYPE 'W'.
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
+  PERFORM download_evidence_file USING ls_evd-evd_id.
+ENDFORM.
+
+*&=====================================================================*
 *&
 *& Rules:
 *&   → Fixed(5): require any evidence file (COUNT > 0)
@@ -1198,6 +1217,21 @@
         lv_subject      TYPE so_obj_des,
         lv_email        TYPE adr6-smtp_addr,
         lv_has_rcpt     TYPE abap_bool.
+
+  " Refresh status display text (may be called from PAI before PBO runs)
+  CASE gs_bug_detail-status.
+    WHEN gc_st_new.          gv_status_disp = 'New'.
+    WHEN gc_st_assigned.     gv_status_disp = 'Assigned'.
+    WHEN gc_st_inprogress.   gv_status_disp = 'In Progress'.
+    WHEN gc_st_pending.      gv_status_disp = 'Pending'.
+    WHEN gc_st_fixed.        gv_status_disp = 'Fixed'.
+    WHEN gc_st_finaltesting. gv_status_disp = 'Final Testing'.
+    WHEN gc_st_resolved.     gv_status_disp = 'Resolved'.
+    WHEN gc_st_closed.       gv_status_disp = 'Closed'.
+    WHEN gc_st_rejected.     gv_status_disp = 'Rejected'.
+    WHEN gc_st_waiting.      gv_status_disp = 'Waiting'.
+    WHEN OTHERS.             gv_status_disp = gs_bug_detail-status.
+  ENDCASE.
 
   " Build email subject
   lv_subject = |Bug { gs_bug_detail-bug_id } - { gs_bug_detail-title }|.
@@ -1237,7 +1271,7 @@
       lo_sender = cl_sapuser_bcs=>create( sy-uname ).
       lo_send_request->set_sender( lo_sender ).
 
-      " Collect unique recipients: dev, tester, verify tester
+      " Collect unique recipients: dev, tester, verify tester, project manager
       DATA: lt_recipients TYPE TABLE OF zde_username.
       IF gs_bug_detail-dev_id IS NOT INITIAL.
         APPEND gs_bug_detail-dev_id TO lt_recipients.
@@ -1248,6 +1282,19 @@
       IF gs_bug_detail-verify_tester_id IS NOT INITIAL.
         APPEND gs_bug_detail-verify_tester_id TO lt_recipients.
       ENDIF.
+
+      " Add project manager to recipients (ensures email in Waiting path)
+      DATA: lv_pm_user TYPE zde_username.
+      IF gs_bug_detail-project_id IS NOT INITIAL.
+        SELECT SINGLE project_manager FROM zbug_project
+          INTO @lv_pm_user
+          WHERE project_id = @gs_bug_detail-project_id
+            AND is_del <> 'X'.
+        IF sy-subrc = 0 AND lv_pm_user IS NOT INITIAL.
+          APPEND lv_pm_user TO lt_recipients.
+        ENDIF.
+      ENDIF.
+
       SORT lt_recipients.
       DELETE ADJACENT DUPLICATES FROM lt_recipients.
 
@@ -1289,7 +1336,7 @@
 *& Fcode UPLOAD on Screen 0400: Manager uploads Excel → validate → insert
 *&=====================================================================*
 FORM upload_project_excel.
-  DATA: lv_file     TYPE string,
+  DATA: lv_file     TYPE rlgrap-filename,
         lt_raw      TYPE truxs_t_text_data,
         lt_projects TYPE TABLE OF zbug_project,
         ls_project  TYPE zbug_project,
@@ -1737,6 +1784,9 @@
     " Update snapshot to reflect new status
     gs_bug_snapshot = gs_bug_detail.
 
+    " Send email notification for status change
+    PERFORM send_mail_notification.
+
     " Trigger auto-assign tester if status → Fixed
     IF gv_trans_new_status = gc_st_fixed.
       PERFORM auto_assign_tester.
@@ -1797,6 +1847,8 @@
     COMMIT WORK.
     PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'No developer available'.
     COMMIT WORK.
+    gs_bug_snapshot = gs_bug_detail.
+    PERFORM send_mail_notification.
     MESSAGE 'No available developer. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
     RETURN.
   ENDIF.
@@ -1823,6 +1875,8 @@
     COMMIT WORK.
     PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_new gc_st_waiting 'All developers overloaded'.
     COMMIT WORK.
+    gs_bug_snapshot = gs_bug_detail.
+    PERFORM send_mail_notification.
     MESSAGE 'All developers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
     RETURN.
   ENDIF.
@@ -1847,6 +1901,8 @@
   " Update snapshot
   gs_bug_snapshot = gs_bug_detail.
 
+  PERFORM send_mail_notification.
+
   MESSAGE |Bug auto-assigned to { ls_best-user_id } (workload: { ls_best-workload })| TYPE 'S'.
 ENDFORM.
 
@@ -1897,6 +1953,7 @@
     COMMIT WORK.
     " Update snapshot
     gs_bug_snapshot = gs_bug_detail.
+    PERFORM send_mail_notification.
     MESSAGE 'No available tester. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
     RETURN.
   ENDIF.
@@ -1924,6 +1981,7 @@
     PERFORM add_history_entry USING gs_bug_detail-bug_id 'AA' gc_st_fixed gc_st_waiting 'All testers overloaded'.
     COMMIT WORK.
     gs_bug_snapshot = gs_bug_detail.
+    PERFORM send_mail_notification.
     MESSAGE 'All testers overloaded. Bug set to Waiting.' TYPE 'S' DISPLAY LIKE 'W'.
     RETURN.
   ENDIF.
@@ -1947,6 +2005,8 @@
 
   " Update snapshot
   gs_bug_snapshot = gs_bug_detail.
+
+  PERFORM send_mail_notification.
 
   MESSAGE |Bug auto-assigned to tester { ls_best-user_id } for Final Testing| TYPE 'S'.
 ENDFORM.
```

### CODE_F02.md — modified

`+8 / -1 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -530,7 +530,14 @@
   " Resolve editor reference from text_id
   DATA: lr_editor TYPE REF TO cl_gui_textedit.
   CASE pv_text_id.
-    WHEN 'Z001'. lr_editor = go_edit_desc.
+    WHEN 'Z001'.
+      " Prefer full editor (tab 0320). If user never opened Description tab,
+      " fall back to mini editor (tab 0310) to avoid losing desc_text.
+      IF go_edit_desc IS NOT INITIAL.
+        lr_editor = go_edit_desc.
+      ELSE.
+        lr_editor = go_desc_mini_edit.
+      ENDIF.
     WHEN 'Z002'. lr_editor = go_edit_dev_note.
     WHEN 'Z003'. lr_editor = go_edit_tstr_note.
   ENDCASE.
```

### CODE_PAI.md — modified

`+3 / -0 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -191,6 +191,9 @@
     " Delete evidence
     WHEN 'DL_EVD'.
       PERFORM delete_evidence.
+    " Download evidence (selected row via button)
+    WHEN 'DW_EVD'.
+      PERFORM download_evidence_selected.
     " Send email notification
     WHEN 'SENDMAIL'.
       PERFORM send_mail_notification.
```

### CODE_PBO.md — modified

`+5 / -3 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -112,10 +112,11 @@
 *&=====================================================================*
 MODULE status_0300 OUTPUT.
   CLEAR gm_excl.
-  " Display mode: hide SAVE + upload buttons + email + delete evidence
+  " Display mode: hide SAVE + upload buttons + email + delete evidence + status change
   IF gv_mode = gc_mode_display.
-    APPEND 'SAVE'     TO gm_excl.
-    APPEND 'SENDMAIL' TO gm_excl.
+    APPEND 'SAVE'       TO gm_excl.
+    APPEND 'SENDMAIL'   TO gm_excl.
+    APPEND 'STATUS_CHG' TO gm_excl.
   ENDIF.
   " Tester cannot upload fix
   IF gv_role = 'T'.
@@ -133,6 +134,7 @@
     APPEND 'UP_FIX'     TO gm_excl.
     APPEND 'SENDMAIL'   TO gm_excl.    " No email for unsaved bug
     APPEND 'DL_EVD'     TO gm_excl.    " No delete evidence before save
+    APPEND 'DW_EVD'     TO gm_excl.    " No download evidence before save
   ENDIF.
   " Display mode: hide upload + delete evidence
   IF gv_mode = gc_mode_display.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
