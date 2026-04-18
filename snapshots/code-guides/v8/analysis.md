# Analysis v8

### CODE_F01.md — modified

`+93 / -0 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -250,6 +250,9 @@
 FORM save_project_detail.
   DATA: lv_un TYPE sy-uname.
   lv_un = sy-uname.
+
+  " Read Description from CL_GUI_TEXTEDIT editor → gs_project-description
+  PERFORM read_prj_editor_to_field.
 
   " Auto-generate PROJECT_ID in Create mode
   " (user sees "(Auto)" placeholder — real ID generated here before validation)
@@ -1167,6 +1170,9 @@
 FORM check_unsaved_prj CHANGING pv_continue TYPE abap_bool.
   pv_continue = abap_true.
 
+  " Sync editor text to work area for accurate comparison
+  PERFORM read_prj_editor_to_field.
+
   " Compare current state with snapshot
   IF gs_project = gs_prj_snapshot.
     RETURN.  " No changes — continue silently
@@ -1194,6 +1200,93 @@
     WHEN 'A'. " Cancel — stay on screen
       pv_continue = abap_false.
   ENDCASE.
+ENDFORM.
+
+*&=====================================================================*
+*& READ PROJECT EDITORS → WORK AREA
+*& Reads CL_GUI_TEXTEDIT content back into gs_project-description
+*& and gs_project-note (CHAR 255 — auto-truncated).
+*& Called before save_project_detail and check_unsaved_prj.
+*&=====================================================================*
+FORM read_prj_editor_to_field.
+  DATA: lt_lines TYPE TABLE OF char255,
+        lv_text  TYPE string.
+
+  " --- Description Editor ---
+  IF go_edit_prj_desc IS NOT INITIAL.
+    CLEAR: lt_lines, lv_text.
+    cl_gui_cfw=>flush( ).
+    go_edit_prj_desc->get_text_as_r3table(
+      IMPORTING table = lt_lines
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+    IF sy-subrc = 0.
+      LOOP AT lt_lines INTO DATA(lv_line_d).
+        IF sy-tabix = 1.
+          lv_text = lv_line_d.
+        ELSE.
+          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line_d.
+        ENDIF.
+      ENDLOOP.
+      gs_project-description = lv_text.  " Auto-truncated to CHAR 255
+    ENDIF.
+  ENDIF.
+
+  " --- Note Editor ---
+  IF go_edit_prj_note IS NOT INITIAL.
+    CLEAR: lt_lines, lv_text.
+    cl_gui_cfw=>flush( ).
+    go_edit_prj_note->get_text_as_r3table(
+      IMPORTING table = lt_lines
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+    IF sy-subrc = 0.
+      LOOP AT lt_lines INTO DATA(lv_line_n).
+        IF sy-tabix = 1.
+          lv_text = lv_line_n.
+        ELSE.
+          lv_text = lv_text && cl_abap_char_utilities=>cr_lf && lv_line_n.
+        ENDIF.
+      ENDLOOP.
+      gs_project-note = lv_text.  " Auto-truncated to CHAR 255
+    ENDIF.
+  ENDIF.
+ENDFORM.
+
+*&=====================================================================*
+*& CLEANUP: Free Screen 0500 GUI controls (Project Desc/Note editors)
+*& Called on BACK/CANC from Project Detail — ensures clean state
+*& for the next project opened.
+*&=====================================================================*
+FORM cleanup_prj_editors.
+  " --- Project Description Editor ---
+  IF go_edit_prj_desc IS NOT INITIAL.
+    go_edit_prj_desc->free( ).
+    FREE go_edit_prj_desc.
+    CLEAR go_edit_prj_desc.
+  ENDIF.
+  IF go_cont_prj_desc IS NOT INITIAL.
+    go_cont_prj_desc->free( ).
+    FREE go_cont_prj_desc.
+    CLEAR go_cont_prj_desc.
+  ENDIF.
+
+  " --- Project Note Editor ---
+  IF go_edit_prj_note IS NOT INITIAL.
+    go_edit_prj_note->free( ).
+    FREE go_edit_prj_note.
+    CLEAR go_edit_prj_note.
+  ENDIF.
+  IF go_cont_prj_note IS NOT INITIAL.
+    go_cont_prj_note->free( ).
+    FREE go_cont_prj_note.
+    CLEAR go_cont_prj_note.
+  ENDIF.
+
+  " Clear data-loaded flag so next project triggers fresh DB load
+  CLEAR gv_prj_detail_loaded.
 ENDFORM.
 
 *&=====================================================================*
```

### CODE_PAI.md — modified

`+3 / -0 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -415,9 +415,12 @@
           RETURN.  " User cancelled — stay on screen
         ENDIF.
       ENDIF.
+      " Free project editors before leaving
+      PERFORM cleanup_prj_editors.
       " LEAVE TO SCREEN 0 → returns to caller (Screen 0400)
       LEAVE TO SCREEN 0.
     WHEN 'EXIT'.
+      PERFORM cleanup_prj_editors.
       LEAVE PROGRAM.
     WHEN 'SAVE'.
       IF gv_mode = gc_mode_display.
```

### CODE_PBO.md — modified

`+82 / -0 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -710,5 +710,87 @@
       screen-input = 0.
       MODIFY SCREEN.
     ENDIF.
+
+    " Hide old Description/Note I/O fields (replaced by CL_GUI_TEXTEDIT editors)
+    IF screen-name = 'GS_PROJECT-DESCRIPTION' OR screen-name = 'GS_PROJECT-NOTE'.
+      screen-active = 0.
+      MODIFY SCREEN.
+    ENDIF.
   ENDLOOP.
 ENDMODULE.
+
+*&--- PROJECT DESCRIPTION + NOTE EDITORS (Screen 0500) ---*
+*& Creates CL_GUI_TEXTEDIT controls in CC_PRJ_DESC and CC_PRJ_NOTE.
+*& Loads text from gs_project-description / gs_project-note on first creation.
+*& Readonly when mode=Display or role<>Manager.
+MODULE init_prj_editors OUTPUT.
+  " --- Description Editor ---
+  IF go_cont_prj_desc IS INITIAL.
+    TRY.
+        CREATE OBJECT go_cont_prj_desc EXPORTING container_name = 'CC_PRJ_DESC'.
+        CREATE OBJECT go_edit_prj_desc EXPORTING parent = go_cont_prj_desc.
+        go_edit_prj_desc->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_prj_desc->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Project Description editor. Check Custom Control CC_PRJ_DESC on screen 0500.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
+
+    " Load description text on first creation only
+    DATA: lt_desc_text TYPE TABLE OF char255.
+    IF gs_project-description IS NOT INITIAL.
+      SPLIT gs_project-description AT cl_abap_char_utilities=>cr_lf
+        INTO TABLE lt_desc_text.
+    ENDIF.
+    go_edit_prj_desc->set_text_as_r3table(
+      EXPORTING table = lt_desc_text
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+  ENDIF.
+
+  " Readonly control for Description
+  IF go_edit_prj_desc IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gv_role <> 'M'.
+      go_edit_prj_desc->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_edit_prj_desc->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
+  ENDIF.
+
+  " --- Note Editor ---
+  IF go_cont_prj_note IS INITIAL.
+    TRY.
+        CREATE OBJECT go_cont_prj_note EXPORTING container_name = 'CC_PRJ_NOTE'.
+        CREATE OBJECT go_edit_prj_note EXPORTING parent = go_cont_prj_note.
+        go_edit_prj_note->set_toolbar_mode( cl_gui_textedit=>false ).
+        go_edit_prj_note->set_statusbar_mode( cl_gui_textedit=>false ).
+      CATCH cx_root.
+        MESSAGE 'Cannot create Project Note editor. Check Custom Control CC_PRJ_NOTE on screen 0500.'
+          TYPE 'S' DISPLAY LIKE 'W'.
+        RETURN.
+    ENDTRY.
+
+    " Load note text on first creation only
+    DATA: lt_note_text TYPE TABLE OF char255.
+    IF gs_project-note IS NOT INITIAL.
+      SPLIT gs_project-note AT cl_abap_char_utilities=>cr_lf
+        INTO TABLE lt_note_text.
+    ENDIF.
+    go_edit_prj_note->set_text_as_r3table(
+      EXPORTING table = lt_note_text
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
+  ENDIF.
+
+  " Readonly control for Note
+  IF go_edit_prj_note IS NOT INITIAL.
+    IF gv_mode = gc_mode_display OR gv_role <> 'M'.
+      go_edit_prj_note->set_readonly_mode( cl_gui_textedit=>true ).
+    ELSE.
+      go_edit_prj_note->set_readonly_mode( cl_gui_textedit=>false ).
+    ENDIF.
+  ENDIF.
+ENDMODULE.
```

### CODE_TOP.md — modified

`+6 / -0 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -94,6 +94,12 @@
 " === TRANSITION NOTE EDITOR (Screen 0370 popup) ===
 DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
       go_edit_trans_note TYPE REF TO cl_gui_textedit.
+
+" === PROJECT DETAIL EDITORS (Screen 0500 — Description + Note) ===
+DATA: go_cont_prj_desc TYPE REF TO cl_gui_custom_container,
+      go_edit_prj_desc TYPE REF TO cl_gui_textedit,
+      go_cont_prj_note TYPE REF TO cl_gui_custom_container,
+      go_edit_prj_note TYPE REF TO cl_gui_textedit.
 
 " === FIELD CATALOGS ===
 DATA: gt_fcat_bug      TYPE lvc_t_fcat,
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
