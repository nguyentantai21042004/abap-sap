# Analysis v13

### CODE_F01.md — modified

`+0 / -90 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -169,35 +169,7 @@
 
   IF sy-subrc = 0.
     COMMIT WORK.
-    " Set current bug id BEFORE saving long texts
     gv_current_bug_id = gs_bug_detail-bug_id.
-    " Save Description long text (SAVE_TEXT buffers changes — needs explicit COMMIT)
-    PERFORM save_long_text USING 'Z001'.  " Description
-    COMMIT WORK.                          " Flush SAVE_TEXT buffer to DB
-
-    " Sync desc_text from editor after save_long_text
-    IF go_edit_desc IS NOT INITIAL.
-      DATA: lt_desc_sync TYPE TABLE OF char255.
-      cl_gui_cfw=>flush( ).
-      go_edit_desc->get_text_as_r3table(
-        IMPORTING table = lt_desc_sync
-        EXCEPTIONS OTHERS = 3 ).
-      IF sy-subrc = 0.
-        CLEAR gs_bug_detail-desc_text.
-        LOOP AT lt_desc_sync INTO DATA(lv_sync_line).
-          IF gs_bug_detail-desc_text IS NOT INITIAL.
-            gs_bug_detail-desc_text = gs_bug_detail-desc_text
-              && cl_abap_char_utilities=>cr_lf && lv_sync_line.
-          ELSE.
-            gs_bug_detail-desc_text = lv_sync_line.
-          ENDIF.
-        ENDLOOP.
-        " Persist synced desc_text to DB (Bug #2 fix — desc_text was only updated in memory)
-        UPDATE zbug_tracker SET desc_text = @gs_bug_detail-desc_text
-          WHERE bug_id = @gs_bug_detail-bug_id.
-      ENDIF.
-    ENDIF.
-
     MESSAGE |Bug { gs_bug_detail-bug_id } saved successfully.| TYPE 'S'.
 
     " Trigger auto-assign developer after creating new bug
@@ -212,40 +184,6 @@
     ROLLBACK WORK.
     MESSAGE 'Save failed. Please check required fields.' TYPE 'S' DISPLAY LIKE 'E'.
   ENDIF.
-ENDFORM.
-
-*&=== SAVE DESCRIPTION MINI EDITOR → WORK AREA ===*
-" Called before save_bug_detail — reads mini editor text into gs_bug_detail-desc_text
-FORM save_desc_mini_to_workarea.
-  CHECK go_desc_mini_edit IS NOT INITIAL.
-  DATA: lt_mini TYPE TABLE OF char255,
-        lv_text TYPE string.
-
-  " Flush GUI control data before reading
-  " Without flush, CL_GUI_TEXTEDIT raises POTENTIAL_DATA_LOSS
-  cl_gui_cfw=>flush( ).
-
-  go_desc_mini_edit->get_text_as_r3table(
-    IMPORTING table = lt_mini
-    EXCEPTIONS error_dp        = 1
-               error_dp_create = 2
-               OTHERS          = 3 ).
-  IF sy-subrc <> 0.
-    " Silently return — control may not be ready yet (no user-facing warning)
-    RETURN.
-  ENDIF.
-
-  " Concatenate lines without inserting extra line breaks
-  " get_text_as_r3table splits at 255 chars — join with space to preserve long text
-  CLEAR lv_text.
-  LOOP AT lt_mini INTO DATA(lv_line).
-    IF sy-tabix = 1.
-      lv_text = lv_line.
-    ELSE.
-      lv_text = lv_text && lv_line.
-    ENDIF.
-  ENDLOOP.
-  gs_bug_detail-desc_text = lv_text.
 ENDFORM.
 
 *&=== SAVE PROJECT DETAIL ===*
@@ -686,30 +624,6 @@
 *& Also cleans up Screen 0370 (trans_note) + Screen 0220 (search ALV)
 *&=====================================================================*
 FORM cleanup_detail_editors.
-  " --- Mini description editor (Subscreen 0310) ---
-  IF go_desc_mini_edit IS NOT INITIAL.
-    go_desc_mini_edit->free( ).
-    FREE go_desc_mini_edit.
-    CLEAR go_desc_mini_edit.
-  ENDIF.
-  IF go_desc_mini_cont IS NOT INITIAL.
-    go_desc_mini_cont->free( ).
-    FREE go_desc_mini_cont.
-    CLEAR go_desc_mini_cont.
-  ENDIF.
-
-  " --- Long Text: Description (Subscreen 0320) ---
-  IF go_edit_desc IS NOT INITIAL.
-    go_edit_desc->free( ).
-    FREE go_edit_desc.
-    CLEAR go_edit_desc.
-  ENDIF.
-  IF go_cont_desc IS NOT INITIAL.
-    go_cont_desc->free( ).
-    FREE go_cont_desc.
-    CLEAR go_cont_desc.
-  ENDIF.
-
   " --- Evidence ALV (Subscreen 0350) ---
   IF go_alv_evidence IS NOT INITIAL.
     go_alv_evidence->free( ).
@@ -800,7 +714,6 @@
   IF gv_current_bug_id IS INITIAL.
     IF gv_mode = gc_mode_create.
       " Auto-validate and save the bug (generates bug_id, switches to Change mode)
-      PERFORM save_desc_mini_to_workarea.
       PERFORM save_bug_detail.
       IF gv_current_bug_id IS INITIAL.
         " Save failed — validation errors already shown via TYPE 'S' DISPLAY LIKE 'E'
@@ -1147,9 +1060,6 @@
 *&=====================================================================*
 FORM check_unsaved_bug CHANGING pv_continue TYPE abap_bool.
   pv_continue = abap_true.
-
-  " Sync mini editor text to work area for accurate comparison
-  PERFORM save_desc_mini_to_workarea.
 
   " Compare current state with snapshot
   IF gs_bug_detail = gs_bug_snapshot.
```

### CODE_F02.md — modified

`+0 / -126 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -467,136 +467,10 @@
 ENDFORM.
 
 *&=====================================================================*
-*& LONG TEXT OPERATIONS
-*&=====================================================================*
-
-*&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
-*& pv_text_id: 'Z001' = Description (only)
-*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — no textedit needed.
-*& Editor is resolved internally from global object go_edit_desc.
-*&
-*& Explicit lv_tdname TYPE tdobname cast to prevent CALL_FUNCTION_CONFLICT_TYPE:
-*& gv_current_bug_id is CHAR 10, but READ_TEXT NAME expects TDOBNAME = CHAR 70.
-FORM load_long_text USING pv_text_id TYPE thead-tdid.
-  CHECK gv_current_bug_id IS NOT INITIAL.
-
-  " Resolve editor reference from text_id
-  DATA: lr_editor TYPE REF TO cl_gui_textedit.
-  CASE pv_text_id.
-    WHEN 'Z001'. lr_editor = go_edit_desc.
-  ENDCASE.
-  CHECK lr_editor IS NOT INITIAL.
-
-  DATA: lt_lines TYPE TABLE OF tline,
-        ls_line  TYPE tline.
-
-  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
-  DATA: lv_tdname TYPE tdobname.
-  lv_tdname = gv_current_bug_id.
-
-  CALL FUNCTION 'READ_TEXT'
-    EXPORTING
-      id       = pv_text_id
-      language = sy-langu
-      name     = lv_tdname
-      object   = 'ZBUG'
-    TABLES
-      lines    = lt_lines
-    EXCEPTIONS
-      OTHERS   = 4.  " subrc 4 = text not found (OK for new bugs)
-
-  IF sy-subrc = 0.
-    DATA: lt_text TYPE TABLE OF char255.
-    LOOP AT lt_lines INTO ls_line.
-      APPEND CONV char255( ls_line-tdline ) TO lt_text.
-    ENDLOOP.
-    lr_editor->set_text_as_r3table(
-      EXPORTING table = lt_text
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-  ENDIF.
-ENDFORM.
-
-*&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
-*& pv_text_id: 'Z001' = Description (only)
-*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — saved via UPDATE.
-*& Caller must set gv_current_bug_id before calling.
-*&
-*& Explicit lv_tdname TYPE tdobname cast for SAVE_TEXT (same reason as load_long_text).
-FORM save_long_text USING pv_text_id TYPE thead-tdid.
-  CHECK gv_current_bug_id IS NOT INITIAL.
-
-  " Resolve editor reference from text_id
-  DATA: lr_editor TYPE REF TO cl_gui_textedit.
-  CASE pv_text_id.
-    WHEN 'Z001'.
-      " Prefer full editor (tab 0320). If user never opened Description tab,
-      " fall back to mini editor (tab 0310) to avoid losing desc_text.
-      IF go_edit_desc IS NOT INITIAL.
-        lr_editor = go_edit_desc.
-      ELSE.
-        lr_editor = go_desc_mini_edit.
-      ENDIF.
-  ENDCASE.
-
-  DATA: lt_text  TYPE TABLE OF char255,
-        lt_lines TYPE TABLE OF tline,
-        ls_line  TYPE tline.
-
-  " Try to read text from editor
-  IF lr_editor IS NOT INITIAL.
-    cl_gui_cfw=>flush( ).
-    lr_editor->get_text_as_r3table(
-      IMPORTING table = lt_text
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-  ENDIF.
-
-  IF lr_editor IS INITIAL OR sy-subrc <> 0.
-    RETURN.
-  ENDIF.
-
-  LOOP AT lt_text INTO DATA(lv_line).
-    CLEAR ls_line.
-    ls_line-tdformat = '*'.
-    ls_line-tdline   = lv_line.
-    APPEND ls_line TO lt_lines.
-  ENDLOOP.
-
-  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
-  DATA: lv_tdname TYPE tdobname.
-  lv_tdname = gv_current_bug_id.
-
-  DATA: ls_header TYPE thead.
-  ls_header-tdobject = 'ZBUG'.
-  ls_header-tdname   = lv_tdname.
-  ls_header-tdid     = pv_text_id.
-  ls_header-tdspras  = sy-langu.
-
-  CALL FUNCTION 'SAVE_TEXT'
-    EXPORTING
-      header          = ls_header
-      savemode_direct = 'X'
-    TABLES
-      lines           = lt_lines
-    EXCEPTIONS
-      OTHERS          = 4.
-  IF sy-subrc <> 0.
-    DATA: lv_save_msg TYPE string.
-    lv_save_msg = |Long text { pv_text_id } save failed (RC={ sy-subrc }). Check text object ZBUG in SE75.|.
-    MESSAGE lv_save_msg TYPE 'S' DISPLAY LIKE 'W'.
-  ENDIF.
-ENDFORM.
-
-*&=====================================================================*
 *& LONG TEXT: SAVE DIRECT (from table param, no editor)
 *&
 *& Used by apply_status_transition to save transition note text directly
 *& from a char255 table (e.g., text read from go_edit_trans_note popup).
-*& The existing save_long_text reads from go_edit_desc/dev_note/tstr_note
-*& which may not exist when the popup is active.
 *&
 *& Parameters:
 *&   pv_text_id — Text ID (Z001/Z002/Z003)
```

### CODE_PAI.md — modified

`+0 / -1 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -159,7 +159,6 @@
         MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
         RETURN.
       ENDIF.
-      PERFORM save_desc_mini_to_workarea.
       PERFORM save_bug_detail.
 
     " STATUS_CHG opens popup Screen 0370 (replaces old change_bug_status)
```

### CODE_PBO.md — modified

`+0 / -72 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -304,78 +304,6 @@
 ENDMODULE.
 
 *&=====================================================================*
-*& SUBSCREEN 0310: Bug Info — Description Mini Editor
-*&=====================================================================*
-MODULE init_desc_mini OUTPUT.
-  " Create mini text editor (3-4 lines) for quick description on Bug Info tab
-  IF go_desc_mini_cont IS INITIAL.
-    TRY.
-        CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
-        CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
-        go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Mini Description editor. Check Custom Control CC_DESC_MINI on screen 0310.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-
-    " Load DESC_TEXT into mini editor — ONLY on first creation
-    " (subsequent PBO calls skip this, preserving user edits during tab switch)
-    DATA: lt_mini_text TYPE TABLE OF char255.
-    IF gs_bug_detail-desc_text IS NOT INITIAL.
-      SPLIT gs_bug_detail-desc_text AT cl_abap_char_utilities=>cr_lf
-        INTO TABLE lt_mini_text.
-    ENDIF.
-    go_desc_mini_edit->set_text_as_r3table(
-      EXPORTING table = lt_mini_text
-      EXCEPTIONS error_dp        = 1
-                 error_dp_create = 2
-                 OTHERS          = 3 ).
-  ENDIF.
-
-  " Readonly mode: set every PBO (may differ between bugs)
-  IF go_desc_mini_edit IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-       OR gs_bug_detail-status = gc_st_resolved.
-      go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
-    ENDIF.
-  ENDIF.
-ENDMODULE.
-
-*&=====================================================================*
-*& SUBSCREEN 0320: Description Long Text (Text ID Z001)
-*& TRY-CATCH for container creation (prevents dump if CC missing)
-*&=====================================================================*
-MODULE init_long_text_desc OUTPUT.
-  IF go_cont_desc IS INITIAL.
-    TRY.
-        CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
-        CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
-        go_edit_desc->set_toolbar_mode( cl_gui_textedit=>false ).
-        go_edit_desc->set_statusbar_mode( cl_gui_textedit=>false ).
-      CATCH cx_root.
-        MESSAGE 'Cannot create Description editor. Check Custom Control CC_DESC on screen 0320.'
-          TYPE 'S' DISPLAY LIKE 'W'.
-        RETURN.
-    ENDTRY.
-    " Load text from DB on first creation only
-    PERFORM load_long_text USING 'Z001'.
-  ENDIF.
-  " Readonly: set every PBO
-  IF go_edit_desc IS NOT INITIAL.
-    IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed
-       OR gs_bug_detail-status = gc_st_resolved.
-      go_edit_desc->set_readonly_mode( cl_gui_textedit=>true ).
-    ELSE.
-      go_edit_desc->set_readonly_mode( cl_gui_textedit=>false ).
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

`+1 / -7 lines`

```diff
--- previous/CODE_TOP.md
+++ current/CODE_TOP.md
@@ -82,13 +82,7 @@
 DATA: go_cont_search TYPE REF TO cl_gui_custom_container,
       go_search_alv  TYPE REF TO cl_gui_alv_grid.
 
-" === TEXT EDIT OBJECTS (subscreen 0320 only — Dev/Tester Note use DB CHAR fields) ===
-DATA: go_cont_desc TYPE REF TO cl_gui_custom_container,
-      go_edit_desc TYPE REF TO cl_gui_textedit.
-
-" === DESCRIPTION MINI EDITOR (on Subscreen 0310 — Bug Info tab) ===
-DATA: go_desc_mini_cont TYPE REF TO cl_gui_custom_container,
-      go_desc_mini_edit TYPE REF TO cl_gui_textedit.
+" === TEXT EDIT OBJECTS (Screen 0370 trans_note only — Description/Dev/Tester Note use DB CHAR fields) ===
 
 " === TRANSITION NOTE EDITOR (Screen 0370 popup) ===
 DATA: go_cont_trans_note TYPE REF TO cl_gui_custom_container,
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
