# Analysis v12

### CODE_F01.md — modified

`+23 / -91 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -171,10 +171,8 @@
     COMMIT WORK.
     " Set current bug id BEFORE saving long texts
     gv_current_bug_id = gs_bug_detail-bug_id.
-    " Save long text tabs (SAVE_TEXT buffers changes — needs explicit COMMIT)
+    " Save Description long text (SAVE_TEXT buffers changes — needs explicit COMMIT)
     PERFORM save_long_text USING 'Z001'.  " Description
-    PERFORM save_long_text USING 'Z002'.  " Dev Note
-    PERFORM save_long_text USING 'Z003'.  " Tester Note
     COMMIT WORK.                          " Flush SAVE_TEXT buffer to DB
 
     " Sync desc_text from editor after save_long_text
@@ -250,62 +248,6 @@
   gs_bug_detail-desc_text = lv_text.
 ENDFORM.
 
-*&=====================================================================*
-*& CAPTURE NOTE EDITORS TO BUFFERS
-*& Called: (a) on each tab switch (while source tab is still active),
-*&         (b) before SAVE (in case user presses SAVE while on note tab).
-*& Ensures save_long_text can use buffer as fallback on SAP GUI for Java
-*& where get_text_as_r3table may fail on inactive subscreens (Bug A fix).
-*&=====================================================================*
-FORM capture_note_editors.
-  DATA: lt_lines TYPE TABLE OF char255,
-        lv_text  TYPE string.
-
-  " --- Capture Dev Note editor (Subscreen 0330) ---
-  IF go_edit_dev_note IS NOT INITIAL.
-    CLEAR: lt_lines, lv_text.
-    cl_gui_cfw=>flush( ).
-    go_edit_dev_note->get_text_as_r3table(
-      IMPORTING table = lt_lines
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-    IF sy-subrc = 0.
-      LOOP AT lt_lines INTO DATA(lv_dl).
-        IF sy-tabix = 1.
-          lv_text = lv_dl.
-        ELSE.
-          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_dl.
-        ENDIF.
-      ENDLOOP.
-      gv_buf_devnote     = lv_text.
-      gv_buf_devnote_set = abap_true.
-    ENDIF.
-  ENDIF.
-
-  " --- Capture Tester Note editor (Subscreen 0340) ---
-  IF go_edit_tstr_note IS NOT INITIAL.
-    CLEAR: lt_lines, lv_text.
-    cl_gui_cfw=>flush( ).
-    go_edit_tstr_note->get_text_as_r3table(
-      IMPORTING table = lt_lines
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-    IF sy-subrc = 0.
-      LOOP AT lt_lines INTO DATA(lv_tl).
-        IF sy-tabix = 1.
-          lv_text = lv_tl.
-        ELSE.
-          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_tl.
-        ENDIF.
-      ENDLOOP.
-      gv_buf_tstnote     = lv_text.
-      gv_buf_tstnote_set = abap_true.
-    ENDIF.
-  ENDIF.
-ENDFORM.
-
 *&=== SAVE PROJECT DETAIL ===*
 FORM save_project_detail.
   DATA: lv_un TYPE sy-uname.
@@ -768,30 +710,6 @@
     CLEAR go_cont_desc.
   ENDIF.
 
-  " --- Long Text: Dev Note (Subscreen 0330) ---
-  IF go_edit_dev_note IS NOT INITIAL.
-    go_edit_dev_note->free( ).
-    FREE go_edit_dev_note.
-    CLEAR go_edit_dev_note.
-  ENDIF.
-  IF go_cont_dev_note IS NOT INITIAL.
-    go_cont_dev_note->free( ).
-    FREE go_cont_dev_note.
-    CLEAR go_cont_dev_note.
-  ENDIF.
-
-  " --- Long Text: Tester Note (Subscreen 0340) ---
-  IF go_edit_tstr_note IS NOT INITIAL.
-    go_edit_tstr_note->free( ).
-    FREE go_edit_tstr_note.
-    CLEAR go_edit_tstr_note.
-  ENDIF.
-  IF go_cont_tstr_note IS NOT INITIAL.
-    go_cont_tstr_note->free( ).
-    FREE go_cont_tstr_note.
-    CLEAR go_cont_tstr_note.
-  ENDIF.
-
   " --- Evidence ALV (Subscreen 0350) ---
   IF go_alv_evidence IS NOT INITIAL.
     go_alv_evidence->free( ).
@@ -841,8 +759,6 @@
   ENDIF.
 
   " --- Clear data-loaded flag so next bug triggers fresh DB load ---
-  " --- Clear note editor buffers (reset for next bug) ---
-  CLEAR: gv_buf_devnote, gv_buf_devnote_set, gv_buf_tstnote, gv_buf_tstnote_set.
   CLEAR gv_detail_loaded.
 ENDFORM.
 
@@ -1858,14 +1774,30 @@
       EXCEPTIONS OTHERS = 3 ).
   ENDIF.
 
-  " Save TRANS_NOTE → Dev Note (Z002) if → Rejected
+  " Copy TRANS_NOTE → Dev Note (DB field) if → Rejected
   IF gv_trans_new_status = gc_st_rejected AND lt_trans_note IS NOT INITIAL.
-    PERFORM save_long_text_direct USING 'Z002' lt_trans_note.
-  ENDIF.
-
-  " Save TRANS_NOTE → Tester Note (Z003) if FinalTesting → Resolved or → InProgress
+    DATA: lv_dn_text TYPE string.
+    LOOP AT lt_trans_note INTO DATA(lv_dn_line).
+      IF lv_dn_text IS INITIAL.
+        lv_dn_text = lv_dn_line.
+      ELSE.
+        lv_dn_text = lv_dn_text && cl_abap_char_utilities=>cr_lf && lv_dn_line.
+      ENDIF.
+    ENDLOOP.
+    gs_bug_detail-dev_note = lv_dn_text.
+  ENDIF.
+
+  " Copy TRANS_NOTE → Tester Note (DB field) if FinalTesting → Resolved or → InProgress
   IF gv_trans_cur_status = gc_st_finaltesting AND lt_trans_note IS NOT INITIAL.
-    PERFORM save_long_text_direct USING 'Z003' lt_trans_note.
+    DATA: lv_tn_text TYPE string.
+    LOOP AT lt_trans_note INTO DATA(lv_tn_line).
+      IF lv_tn_text IS INITIAL.
+        lv_tn_text = lv_tn_line.
+      ELSE.
+        lv_tn_text = lv_tn_text && cl_abap_char_utilities=>cr_lf && lv_tn_line.
+      ENDIF.
+    ENDLOOP.
+    gs_bug_detail-tester_note = lv_tn_text.
   ENDIF.
 
   " Update timestamps
```

### CODE_F02.md — modified

`+8 / -36 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -471,8 +471,9 @@
 *&=====================================================================*
 
 *&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
-*& pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
-*& Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
+*& pv_text_id: 'Z001' = Description (only)
+*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — no textedit needed.
+*& Editor is resolved internally from global object go_edit_desc.
 *&
 *& Explicit lv_tdname TYPE tdobname cast to prevent CALL_FUNCTION_CONFLICT_TYPE:
 *& gv_current_bug_id is CHAR 10, but READ_TEXT NAME expects TDOBNAME = CHAR 70.
@@ -483,8 +484,6 @@
   DATA: lr_editor TYPE REF TO cl_gui_textedit.
   CASE pv_text_id.
     WHEN 'Z001'. lr_editor = go_edit_desc.
-    WHEN 'Z002'. lr_editor = go_edit_dev_note.
-    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
   ENDCASE.
   CHECK lr_editor IS NOT INITIAL.
 
@@ -520,10 +519,9 @@
 ENDFORM.
 
 *&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
-*& pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
-*& Editor is resolved internally. Caller must set gv_current_bug_id before calling.
-*& For Z002/Z003: falls back to gv_buf_devnote/gv_buf_tstnote when editor is on
-*& an inactive subscreen (SAP GUI for Java — get_text_as_r3table fails there).
+*& pv_text_id: 'Z001' = Description (only)
+*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — saved via UPDATE.
+*& Caller must set gv_current_bug_id before calling.
 *&
 *& Explicit lv_tdname TYPE tdobname cast for SAVE_TEXT (same reason as load_long_text).
 FORM save_long_text USING pv_text_id TYPE thead-tdid.
@@ -540,15 +538,13 @@
       ELSE.
         lr_editor = go_desc_mini_edit.
       ENDIF.
-    WHEN 'Z002'. lr_editor = go_edit_dev_note.
-    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
   ENDCASE.
 
   DATA: lt_text  TYPE TABLE OF char255,
         lt_lines TYPE TABLE OF tline,
         ls_line  TYPE tline.
 
-  " Try to read text from editor (may fail on SAP GUI for Java if subscreen inactive)
+  " Try to read text from editor
   IF lr_editor IS NOT INITIAL.
     cl_gui_cfw=>flush( ).
     lr_editor->get_text_as_r3table(
@@ -558,32 +554,8 @@
                  OTHERS          = 3 ).
   ENDIF.
 
-  " Fallback for Dev/Tester Note: use captured buffer when editor is unavailable
-  " or get_text_as_r3table failed (inactive subscreen on SAP GUI for Java).
   IF lr_editor IS INITIAL OR sy-subrc <> 0.
-    CASE pv_text_id.
-      WHEN 'Z002'.
-        IF gv_buf_devnote_set = abap_true.
-          CLEAR lt_text.
-          IF gv_buf_devnote IS NOT INITIAL.
-            SPLIT gv_buf_devnote AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_text.
-          ENDIF.
-          " lt_text empty → SAVE_TEXT clears DB text (correct when user cleared note)
-        ELSE.
-          RETURN.  " User never visited Dev Note tab — preserve existing DB text
-        ENDIF.
-      WHEN 'Z003'.
-        IF gv_buf_tstnote_set = abap_true.
-          CLEAR lt_text.
-          IF gv_buf_tstnote IS NOT INITIAL.
-            SPLIT gv_buf_tstnote AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_text.
-          ENDIF.
-        ELSE.
-          RETURN.  " User never visited Tester Note tab — preserve existing DB text
-        ENDIF.
-      WHEN OTHERS.
-        RETURN.  " Z001 with no editor — skip
-    ENDCASE.
+    RETURN.
   ENDIF.
 
   LOOP AT lt_text INTO DATA(lv_line).
```

### CODE_PAI.md — modified

`+0 / -11 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -159,10 +159,6 @@
         MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
         RETURN.
       ENDIF.
-      " Capture note editors to buffers before save
-      " (fallback for SAP GUI for Java where inactive subscreen editors may fail)
-      PERFORM capture_note_editors.
-      " Save description mini editor content to gs_bug_detail-desc_text
       PERFORM save_desc_mini_to_workarea.
       PERFORM save_bug_detail.
 
@@ -203,29 +199,22 @@
     WHEN 'SENDMAIL'.
       PERFORM send_mail_notification.
     " ---- Tab switching ----
-    " Capture note editors before each switch (source tab still active in PAI)
     WHEN 'TAB_INFO'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0310'.
       gv_active_tab       = 'TAB_INFO'.
     WHEN 'TAB_DESC'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0320'.
       gv_active_tab       = 'TAB_DESC'.
     WHEN 'TAB_DEVNOTE'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0330'.
       gv_active_tab       = 'TAB_DEVNOTE'.
     WHEN 'TAB_TSTR_NOTE'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0340'.
       gv_active_tab       = 'TAB_TSTR_NOTE'.
     WHEN 'TAB_EVIDENCE'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0350'.
       gv_active_tab       = 'TAB_EVIDENCE'.
     WHEN 'TAB_HISTORY'.
-      PERFORM capture_note_editors.
       gv_active_subscreen = '0360'.
       gv_active_tab       = 'TAB_HISTORY'.
   ENDCASE.
```

### CODE_PBO.md — modified

`+0 / -62 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -376,68 +376,6 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& SUBSCREEN 0330: Dev Note Long Text (Text ID Z002)
-*& TRY-CATCH for container creation (prevents dump if CC missing)
-*&=====================================================================*
-MODULE init_long_text_devnote OUTPUT.
-  IF go_cont_dev_note IS INITIAL.
-    TRY.
-        CREATE OBJECT go_cont_dev_note EXPORTING container_name = 'CC_DEVNOTE'.
-        CREATE OBJECT go_edit_dev_note EXPORTING parent = go_cont_dev_note.
-        go_edit_dev_note->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_edit_dev_note->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Dev Note editor. Check Custom Control CC_DEVNOTE on screen 0330.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-    " Load text from DB on first creation only
-    PERFORM load_long_text USING 'Z002'.
-  ENDIF.
-  " Readonly: Testers cannot edit Dev Notes; also readonly in display/closed/resolved
-  IF go_edit_dev_note IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-       OR gs_bug_detail-status = gc_st_resolved
-       OR gv_role = 'T'.
-      go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_edit_dev_note->set_readonly_mode( cl_gui_textedit=>false ).
-    ENDIF.
-  ENDIF.
-ENDMODULE.
-
-*&=====================================================================*
-*& SUBSCREEN 0340: Tester Note Long Text (Text ID Z003)
-*& TRY-CATCH for container creation (prevents dump if CC missing)
-*&=====================================================================*
-MODULE init_long_text_tstrnote OUTPUT.
-  IF go_cont_tstr_note IS INITIAL.
-    TRY.
-        CREATE OBJECT go_cont_tstr_note EXPORTING container_name = 'CC_TSTRNOTE'.
-        CREATE OBJECT go_edit_tstr_note EXPORTING parent = go_cont_tstr_note.
-        go_edit_tstr_note->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_edit_tstr_note->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Tester Note editor. Check Custom Control CC_TSTRNOTE on screen 0340.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-    " Load text from DB on first creation only
-    PERFORM load_long_text USING 'Z003'.
-  ENDIF.
-  " Readonly: Devs cannot edit Tester Notes; also readonly in display/closed/resolved
-  IF go_edit_tstr_note IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-       OR gs_bug_detail-status = gc_st_resolved
-       OR gv_role = 'D'.
-      go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_edit_tstr_note->set_readonly_mode( cl_gui_textedit=>false ).
-    ENDIF.
-  ENDIF.
-ENDMODULE.
-
-*&=====================================================================*
 *& SUBSCREEN 0350: Evidence ALV (attachment list)
 *&=====================================================================*
 MODULE init_evidence_alv OUTPUT.
```

### CODE_TOP.md — modified

`+3 / -15 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -82,13 +82,9 @@
 DATA: go_cont_search TYPE REF TO cl_gui_custom_container,
       go_search_alv  TYPE REF TO cl_gui_alv_grid.
 
-" === TEXT EDIT OBJECTS (subscreens 0320/0330/0340) ===
-DATA: go_cont_desc      TYPE REF TO cl_gui_custom_container,
-      go_edit_desc      TYPE REF TO cl_gui_textedit,
-      go_cont_dev_note  TYPE REF TO cl_gui_custom_container,
-      go_edit_dev_note  TYPE REF TO cl_gui_textedit,
-      go_cont_tstr_note TYPE REF TO cl_gui_custom_container,
-      go_edit_tstr_note TYPE REF TO cl_gui_textedit.
+" === TEXT EDIT OBJECTS (subscreen 0320 only — Dev/Tester Note use DB CHAR fields) ===
+DATA: go_cont_desc TYPE REF TO cl_gui_custom_container,
+      go_edit_desc TYPE REF TO cl_gui_textedit.
 
 " === DESCRIPTION MINI EDITOR (on Subscreen 0310 — Bug Info tab) ===
 DATA: go_desc_mini_cont TYPE REF TO cl_gui_custom_container,
@@ -256,11 +252,3 @@
       gm_layo_prj TYPE lvc_s_layo,
       gm_title    TYPE string.
 
-" === NOTE EDITOR BUFFERS (Screen 0300 subscreens 0330/0340) ===
-" Captures editor text on each tab switch so save_long_text can use it as
-" fallback on SAP GUI for Java where get_text_as_r3table may fail on inactive subscreens.
-" gv_buf_*_set = abap_true means the buffer was explicitly captured (even if empty).
-DATA: gv_buf_devnote     TYPE string,
-      gv_buf_devnote_set TYPE abap_bool,
-      gv_buf_tstnote     TYPE string,
-      gv_buf_tstnote_set TYPE abap_bool.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
