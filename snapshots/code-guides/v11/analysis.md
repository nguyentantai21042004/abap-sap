# Analysis v11

### CODE_F01.md — modified

`+63 / -86 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -194,6 +194,9 @@
             gs_bug_detail-desc_text = lv_sync_line.
           ENDIF.
         ENDLOOP.
+        " Persist synced desc_text to DB (Bug #2 fix — desc_text was only updated in memory)
+        UPDATE zbug_tracker SET desc_text = @gs_bug_detail-desc_text
+          WHERE bug_id = @gs_bug_detail-bug_id.
       ENDIF.
     ENDIF.
 
@@ -247,13 +250,66 @@
   gs_bug_detail-desc_text = lv_text.
 ENDFORM.
 
+*&=====================================================================*
+*& CAPTURE NOTE EDITORS TO BUFFERS
+*& Called: (a) on each tab switch (while source tab is still active),
+*&         (b) before SAVE (in case user presses SAVE while on note tab).
+*& Ensures save_long_text can use buffer as fallback on SAP GUI for Java
+*& where get_text_as_r3table may fail on inactive subscreens (Bug A fix).
+*&=====================================================================*
+FORM capture_note_editors.
+  DATA: lt_lines TYPE TABLE OF char255,
+        lv_text  TYPE string.
+
+  " --- Capture Dev Note editor (Subscreen 0330) ---
+  IF go_edit_dev_note IS NOT INITIAL.
+    CLEAR: lt_lines, lv_text.
+    cl_gui_cfw=>flush( ).
+    go_edit_dev_note->get_text_as_r3table(
+      IMPORTING table = lt_lines
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+    IF sy-subrc = 0.
+      LOOP AT lt_lines INTO DATA(lv_dl).
+        IF sy-tabix = 1.
+          lv_text = lv_dl.
+        ELSE.
+          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_dl.
+        ENDIF.
+      ENDLOOP.
+      gv_buf_devnote     = lv_text.
+      gv_buf_devnote_set = abap_true.
+    ENDIF.
+  ENDIF.
+
+  " --- Capture Tester Note editor (Subscreen 0340) ---
+  IF go_edit_tstr_note IS NOT INITIAL.
+    CLEAR: lt_lines, lv_text.
+    cl_gui_cfw=>flush( ).
+    go_edit_tstr_note->get_text_as_r3table(
+      IMPORTING table = lt_lines
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+    IF sy-subrc = 0.
+      LOOP AT lt_lines INTO DATA(lv_tl).
+        IF sy-tabix = 1.
+          lv_text = lv_tl.
+        ELSE.
+          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_tl.
+        ENDIF.
+      ENDLOOP.
+      gv_buf_tstnote     = lv_text.
+      gv_buf_tstnote_set = abap_true.
+    ENDIF.
+  ENDIF.
+ENDFORM.
+
 *&=== SAVE PROJECT DETAIL ===*
 FORM save_project_detail.
   DATA: lv_un TYPE sy-uname.
   lv_un = sy-uname.
-
-  " Read Description from CL_GUI_TEXTEDIT editor → gs_project-description
-  PERFORM read_prj_editor_to_field.
 
   " Auto-generate PROJECT_ID in Create mode
   " (user sees "(Auto)" placeholder — real ID generated here before validation)
@@ -785,6 +841,8 @@
   ENDIF.
 
   " --- Clear data-loaded flag so next bug triggers fresh DB load ---
+  " --- Clear note editor buffers (reset for next bug) ---
+  CLEAR: gv_buf_devnote, gv_buf_devnote_set, gv_buf_tstnote, gv_buf_tstnote_set.
   CLEAR gv_detail_loaded.
 ENDFORM.
 
@@ -1212,9 +1270,6 @@
 FORM check_unsaved_prj CHANGING pv_continue TYPE abap_bool.
   pv_continue = abap_true.
 
-  " Sync editor text to work area for accurate comparison
-  PERFORM read_prj_editor_to_field.
-
   " Compare current state with snapshot
   IF gs_project = gs_prj_snapshot.
     RETURN.  " No changes — continue silently
@@ -1245,88 +1300,10 @@
 ENDFORM.
 
 *&=====================================================================*
-*& READ PROJECT EDITORS → WORK AREA
-*& Reads CL_GUI_TEXTEDIT content back into gs_project-description
-*& and gs_project-note (CHAR 255 — auto-truncated).
-*& Called before save_project_detail and check_unsaved_prj.
-*&=====================================================================*
-FORM read_prj_editor_to_field.
-  DATA: lt_lines TYPE TABLE OF char255,
-        lv_text  TYPE string.
-
-  " --- Description Editor ---
-  IF go_edit_prj_desc IS NOT INITIAL.
-    CLEAR: lt_lines, lv_text.
-    cl_gui_cfw=>flush( ).
-    go_edit_prj_desc->get_text_as_r3table(
-      IMPORTING table = lt_lines
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-    IF sy-subrc = 0.
-      LOOP AT lt_lines INTO DATA(lv_line_d).
-        IF sy-tabix = 1.
-          lv_text = lv_line_d.
-        ELSE.
-          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line_d.
-        ENDIF.
-      ENDLOOP.
-      gs_project-description = lv_text.  " Auto-truncated to CHAR 255
-    ENDIF.
-  ENDIF.
-
-  " --- Note Editor ---
-  IF go_edit_prj_note IS NOT INITIAL.
-    CLEAR: lt_lines, lv_text.
-    cl_gui_cfw=>flush( ).
-    go_edit_prj_note->get_text_as_r3table(
-      IMPORTING table = lt_lines
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-    IF sy-subrc = 0.
-      LOOP AT lt_lines INTO DATA(lv_line_n).
-        IF sy-tabix = 1.
-          lv_text = lv_line_n.
-        ELSE.
-          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line_n.
-        ENDIF.
-      ENDLOOP.
-      gs_project-note = lv_text.  " Auto-truncated to CHAR 255
-    ENDIF.
-  ENDIF.
-ENDFORM.
-
-*&=====================================================================*
-*& CLEANUP: Free Screen 0500 GUI controls (Project Desc/Note editors)
-*& Called on BACK/CANC from Project Detail — ensures clean state
-*& for the next project opened.
+*& CLEANUP: Reset Screen 0500 state when leaving Project Detail
+*& Clears data-loaded flag so next project triggers a fresh DB load.
 *&=====================================================================*
 FORM cleanup_prj_editors.
-  " --- Project Description Editor ---
-  IF go_edit_prj_desc IS NOT INITIAL.
-    go_edit_prj_desc->free( ).
-    FREE go_edit_prj_desc.
-    CLEAR go_edit_prj_desc.
-  ENDIF.
-  IF go_cont_prj_desc IS NOT INITIAL.
-    go_cont_prj_desc->free( ).
-    FREE go_cont_prj_desc.
-    CLEAR go_cont_prj_desc.
-  ENDIF.
-
-  " --- Project Note Editor ---
-  IF go_edit_prj_note IS NOT INITIAL.
-    go_edit_prj_note->free( ).
-    FREE go_edit_prj_note.
-    CLEAR go_edit_prj_note.
-  ENDIF.
-  IF go_cont_prj_note IS NOT INITIAL.
-    go_cont_prj_note->free( ).
-    FREE go_cont_prj_note.
-    CLEAR go_cont_prj_note.
-  ENDIF.
-
   " Clear data-loaded flag so next project triggers fresh DB load
   CLEAR gv_prj_detail_loaded.
 ENDFORM.
```

### CODE_F02.md — modified

`+38 / -11 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -522,6 +522,8 @@
 *&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
 *& pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
 *& Editor is resolved internally. Caller must set gv_current_bug_id before calling.
+*& For Z002/Z003: falls back to gv_buf_devnote/gv_buf_tstnote when editor is on
+*& an inactive subscreen (SAP GUI for Java — get_text_as_r3table fails there).
 *&
 *& Explicit lv_tdname TYPE tdobname cast for SAVE_TEXT (same reason as load_long_text).
 FORM save_long_text USING pv_text_id TYPE thead-tdid.
@@ -541,22 +543,47 @@
     WHEN 'Z002'. lr_editor = go_edit_dev_note.
     WHEN 'Z003'. lr_editor = go_edit_tstr_note.
   ENDCASE.
-  CHECK lr_editor IS NOT INITIAL.
 
   DATA: lt_text  TYPE TABLE OF char255,
         lt_lines TYPE TABLE OF tline,
         ls_line  TYPE tline.
 
-  " Flush GUI before reading text to prevent POTENTIAL_DATA_LOSS
-  cl_gui_cfw=>flush( ).
-
-  lr_editor->get_text_as_r3table(
-    IMPORTING table = lt_text
-    EXCEPTIONS error_dp        = 1
-               error_dp_create = 2
-               OTHERS          = 3 ).
-  IF sy-subrc <> 0.
-    RETURN.  " Cannot read text — skip save for this text ID
+  " Try to read text from editor (may fail on SAP GUI for Java if subscreen inactive)
+  IF lr_editor IS NOT INITIAL.
+    cl_gui_cfw=>flush( ).
+    lr_editor->get_text_as_r3table(
+      IMPORTING table = lt_text
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+  ENDIF.
+
+  " Fallback for Dev/Tester Note: use captured buffer when editor is unavailable
+  " or get_text_as_r3table failed (inactive subscreen on SAP GUI for Java).
+  IF lr_editor IS INITIAL OR sy-subrc <> 0.
+    CASE pv_text_id.
+      WHEN 'Z002'.
+        IF gv_buf_devnote_set = abap_true.
+          CLEAR lt_text.
+          IF gv_buf_devnote IS NOT INITIAL.
+            SPLIT gv_buf_devnote AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_text.
+          ENDIF.
+          " lt_text empty → SAVE_TEXT clears DB text (correct when user cleared note)
+        ELSE.
+          RETURN.  " User never visited Dev Note tab — preserve existing DB text
+        ENDIF.
+      WHEN 'Z003'.
+        IF gv_buf_tstnote_set = abap_true.
+          CLEAR lt_text.
+          IF gv_buf_tstnote IS NOT INITIAL.
+            SPLIT gv_buf_tstnote AT cl_abap_char_utilities=>cr_lf INTO TABLE lt_text.
+          ENDIF.
+        ELSE.
+          RETURN.  " User never visited Tester Note tab — preserve existing DB text
+        ENDIF.
+      WHEN OTHERS.
+        RETURN.  " Z001 with no editor — skip
+    ENDCASE.
   ENDIF.
 
   LOOP AT lt_text INTO DATA(lv_line).
```

### CODE_PAI.md — modified

`+12 / -0 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -47,6 +47,8 @@
         FREE go_cont_bug.
         CLEAR: go_alv_bug, go_cont_bug.
       ENDIF.
+      " Force project list reload on return so role-filter is always applied
+      gv_prj_list_dirty = abap_true.
       LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
       LEAVE PROGRAM.
@@ -157,6 +159,9 @@
         MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
         RETURN.
       ENDIF.
+      " Capture note editors to buffers before save
+      " (fallback for SAP GUI for Java where inactive subscreen editors may fail)
+      PERFORM capture_note_editors.
       " Save description mini editor content to gs_bug_detail-desc_text
       PERFORM save_desc_mini_to_workarea.
       PERFORM save_bug_detail.
@@ -198,22 +203,29 @@
     WHEN 'SENDMAIL'.
       PERFORM send_mail_notification.
     " ---- Tab switching ----
+    " Capture note editors before each switch (source tab still active in PAI)
     WHEN 'TAB_INFO'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0310'.
       gv_active_tab       = 'TAB_INFO'.
     WHEN 'TAB_DESC'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0320'.
       gv_active_tab       = 'TAB_DESC'.
     WHEN 'TAB_DEVNOTE'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0330'.
       gv_active_tab       = 'TAB_DEVNOTE'.
     WHEN 'TAB_TSTR_NOTE'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0340'.
       gv_active_tab       = 'TAB_TSTR_NOTE'.
     WHEN 'TAB_EVIDENCE'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0350'.
       gv_active_tab       = 'TAB_EVIDENCE'.
     WHEN 'TAB_HISTORY'.
+      PERFORM capture_note_editors.
       gv_active_subscreen = '0360'.
       gv_active_tab       = 'TAB_HISTORY'.
   ENDCASE.
```

### CODE_PBO.md — modified

`+0 / -87 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -715,92 +715,5 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " Hide old Description/Note I/O fields ONLY when editors were created successfully.
-    " Fallback: if Custom Controls missing (e.g., Mac alphanumeric Screen Painter),
-    " old I/O fields remain visible + editable so user can still enter text.
-    IF screen-name = 'GS_PROJECT-DESCRIPTION' AND go_edit_prj_desc IS NOT INITIAL.
-      screen-active = 0.
-      MODIFY SCREEN.
-    ENDIF.
-    IF screen-name = 'GS_PROJECT-NOTE' AND go_edit_prj_note IS NOT INITIAL.
-      screen-active = 0.
-      MODIFY SCREEN.
-    ENDIF.
   ENDLOOP.
 ENDMODULE.
-
-*&--- PROJECT DESCRIPTION + NOTE EDITORS (Screen 0500) ---*
-*& Creates CL_GUI_TEXTEDIT controls in CC_PRJ_DESC and CC_PRJ_NOTE.
-*& Loads text from gs_project-description / gs_project-note on first creation.
-*& Readonly when mode=Display or role<>Manager.
-MODULE init_prj_editors OUTPUT.
-  " --- Description Editor ---
-  IF go_cont_prj_desc IS INITIAL.
-    TRY.
-        CREATE OBJECT go_cont_prj_desc EXPORTING container_name = 'CC_PRJ_DESC'.
-        CREATE OBJECT go_edit_prj_desc EXPORTING parent = go_cont_prj_desc.
-        go_edit_prj_desc->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_edit_prj_desc->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Project Description editor. Check Custom Control CC_PRJ_DESC on screen 0500.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-
-    " Load description text on first creation only
-    DATA: lt_desc_text TYPE TABLE OF char255.
-    IF gs_project-description IS NOT INITIAL.
-      SPLIT gs_project-description AT cl_abap_char_utilities=>cr_lf
-        INTO TABLE lt_desc_text.
-    ENDIF.
-    go_edit_prj_desc->set_text_as_r3table(
-      EXPORTING table = lt_desc_text
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-  ENDIF.
-
-  " Readonly control for Description
-  IF go_edit_prj_desc IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gv_role <> 'M'.
-      go_edit_prj_desc->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_edit_prj_desc->set_readonly_mode( cl_gui_textedit=>false ).
-    ENDIF.
-  ENDIF.
-
-  " --- Note Editor ---
-  IF go_cont_prj_note IS INITIAL.
-    TRY.
-        CREATE OBJECT go_cont_prj_note EXPORTING container_name = 'CC_PRJ_NOTE'.
-        CREATE OBJECT go_edit_prj_note EXPORTING parent = go_cont_prj_note.
-        go_edit_prj_note->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_edit_prj_note->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Project Note editor. Check Custom Control CC_PRJ_NOTE on screen 0500.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-
-    " Load note text on first creation only
-    DATA: lt_note_text TYPE TABLE OF char255.
-    IF gs_project-note IS NOT INITIAL.
-      SPLIT gs_project-note AT cl_abap_char_utilities=>cr_lf
-        INTO TABLE lt_note_text.
-    ENDIF.
-    go_edit_prj_note->set_text_as_r3table(
-      EXPORTING table = lt_note_text
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-  ENDIF.
-
-  " Readonly control for Note
-  IF go_edit_prj_note IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gv_role <> 'M'.
-      go_edit_prj_note->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_edit_prj_note->set_readonly_mode( cl_gui_textedit=>false ).
-    ENDIF.
-  ENDIF.
-ENDMODULE.
```

### CODE_TOP.md — modified

`+10 / -6 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -98,11 +98,6 @@
 DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
       go_edit_trans_note TYPE REF TO cl_gui_textedit.
 
-" === PROJECT DETAIL EDITORS (Screen 0500 — Description + Note) ===
-DATA: go_cont_prj_desc TYPE REF TO cl_gui_custom_container,
-      go_edit_prj_desc TYPE REF TO cl_gui_textedit,
-      go_cont_prj_note TYPE REF TO cl_gui_custom_container,
-      go_edit_prj_note TYPE REF TO cl_gui_textedit.
 
 " === FIELD CATALOGS ===
 DATA: gt_fcat_bug      TYPE lvc_t_fcat,
@@ -259,4 +254,13 @@
 DATA: gm_excl     TYPE TABLE OF sy-ucomm,  " Reused by all status_XXXX modules
       gm_layo_bug TYPE lvc_s_layo,
       gm_layo_prj TYPE lvc_s_layo,
-      gm_title    TYPE string.
+      gm_title    TYPE string.
+
+" === NOTE EDITOR BUFFERS (Screen 0300 subscreens 0330/0340) ===
+" Captures editor text on each tab switch so save_long_text can use it as
+" fallback on SAP GUI for Java where get_text_as_r3table may fail on inactive subscreens.
+" gv_buf_*_set = abap_true means the buffer was explicitly captured (even if empty).
+DATA: gv_buf_devnote     TYPE string,
+      gv_buf_devnote_set TYPE abap_bool,
+      gv_buf_tstnote     TYPE string,
+      gv_buf_tstnote_set TYPE abap_bool.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
