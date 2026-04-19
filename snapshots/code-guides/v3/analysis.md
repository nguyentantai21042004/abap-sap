# Analysis v3

### CODE_F01.md — modified

`+68 / -12 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -1,5 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F01 — Main Business Logic (v4.0)
+*& Include Z_BUG_WS_F01 — Main Business Logic (v4.0 → v4.1 BUGFIX)
 *&---------------------------------------------------------------------*
 *& v4.0 changes (over v3.0):
 *&  - upload_evidence_file/report/fix: REAL implementation (binary → ZBUG_EVIDENCE)
@@ -12,6 +12,12 @@
 *&  - save_bug_detail: ENHANCED — severity/priority cross-validation
 *&  - save_project_detail: ENHANCED — completion validation
 *&  - cleanup_detail_editors: ENHANCED — evidence ALV cleanup
+*&
+*& v4.1 BUGFIX changes:
+*&  - save_project_detail: auto-generate PROJECT_ID (PRJ + 7 digits) (Bug #1)
+*&  - add_user_to_project: fix ROLE field (no DDIC ref), validate M/D/T, check project saved (Bug #2)
+*&  - upload_project_excel: move i_tab_raw_data to CHANGING block (Bug #4)
+*&  - save_desc_mini_to_workarea: add cl_gui_cfw=>flush() + EXCEPTIONS (Bug #6)
 *&---------------------------------------------------------------------*
 
 *&=== SELECT BUG DATA (dual mode: Project / My Bugs) ===*
@@ -205,7 +211,21 @@
   CHECK go_desc_mini_edit IS NOT INITIAL.
   DATA: lt_mini TYPE TABLE OF char255,
         lv_text TYPE string.
-  go_desc_mini_edit->get_text_as_r3table( IMPORTING table = lt_mini ).
+
+  " v4.1 BUGFIX #6: Flush GUI control data before reading
+  " Without flush, CL_GUI_TEXTEDIT raises POTENTIAL_DATA_LOSS
+  cl_gui_cfw=>flush( ).
+
+  go_desc_mini_edit->get_text_as_r3table(
+    IMPORTING table = lt_mini
+    EXCEPTIONS error_dp        = 1
+               error_dp_create = 2
+               OTHERS          = 3 ).
+  IF sy-subrc <> 0.
+    MESSAGE 'Warning: Could not read description text.' TYPE 'S' DISPLAY LIKE 'W'.
+    RETURN.
+  ENDIF.
+
   CLEAR lv_text.
   LOOP AT lt_mini INTO DATA(lv_line).
     IF lv_text IS NOT INITIAL.
@@ -221,6 +241,23 @@
 FORM save_project_detail.
   DATA: lv_un TYPE sy-uname.
   lv_un = sy-uname.
+
+  " v4.1 BUGFIX #1: Auto-generate PROJECT_ID in Create mode
+  " (user sees "(Auto)" placeholder — real ID generated here before validation)
+  IF gv_mode = gc_mode_create.
+    DATA: lv_max_prj TYPE zde_project_id,
+          lv_prj_num TYPE i.
+    SELECT MAX( project_id ) FROM zbug_project INTO @lv_max_prj.
+    IF lv_max_prj IS INITIAL OR lv_max_prj = '(Auto)'.
+      lv_prj_num = 1.
+    ELSE.
+      " PROJECT_ID format: PRJ0000001 (3 prefix + 7 digits)
+      DATA: lv_prj_num_str TYPE char7.
+      lv_prj_num_str = lv_max_prj+3(7).
+      lv_prj_num = CONV i( lv_prj_num_str ) + 1.
+    ENDIF.
+    gs_project-project_id = |PRJ{ lv_prj_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
+  ENDIF.
 
   " Validate required fields
   IF gs_project-project_id IS INITIAL.
@@ -534,6 +571,12 @@
 
 *&=== PROJECT USER MANAGEMENT: ADD ===*
 FORM add_user_to_project.
+  " v4.1 BUGFIX #1: Check project is saved before adding users
+  IF gv_current_project_id IS INITIAL.
+    MESSAGE 'Save the project first before adding users.' TYPE 'W'.
+    RETURN.
+  ENDIF.
+
   DATA: lt_fields TYPE TABLE OF sval,
         ls_field  TYPE sval.
 
@@ -542,10 +585,13 @@
   ls_field-fieldtext = 'SAP Username (USER_ID)'.
   APPEND ls_field TO lt_fields.
 
+  " v4.1 BUGFIX #2: Use empty tabname to avoid DDIC search help crash
+  " (ZBUG_USER_PROJEC-ROLE triggers internal error on F4 → use plain field)
   CLEAR ls_field.
-  ls_field-tabname   = 'ZBUG_USER_PROJEC'.
-  ls_field-fieldname = 'ROLE'.
-  ls_field-fieldtext = 'Role: M=Manager D=Dev T=Tester'.
+  ls_field-tabname   = space.
+  ls_field-fieldname = 'P_ROLE'.
+  ls_field-fieldtext = 'Role (M/D/T)'.
+  ls_field-value     = 'D'.   " Default = Developer
   APPEND ls_field TO lt_fields.
 
   DATA: lv_rc TYPE char1.
@@ -560,11 +606,18 @@
         lv_role  TYPE zde_bug_role.
   READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'USER_ID'.
   lv_uid  = ls_field-value.
-  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'ROLE'.
+  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'P_ROLE'.
   lv_role = ls_field-value.
 
   IF lv_uid IS INITIAL.
     MESSAGE 'User ID is required.' TYPE 'W'. RETURN.
+  ENDIF.
+
+  " v4.1 BUGFIX #2: Validate ROLE is M, D, or T
+  TRANSLATE lv_role TO UPPER CASE.
+  IF lv_role <> 'M' AND lv_role <> 'D' AND lv_role <> 'T'.
+    MESSAGE 'Role must be M (Manager), D (Developer), or T (Tester).' TYPE 'W'.
+    RETURN.
   ENDIF.
 
   " Validate user exists in ZBUG_USERS
@@ -1304,17 +1357,20 @@
          END OF ty_upload.
   DATA: lt_upload TYPE TABLE OF ty_upload.
 
+  " v4.1 BUGFIX #4: i_tab_raw_data is a CHANGING parameter (not EXPORTING)
+  " Passing it in EXPORTING block caused CALL_FUNCTION_CONFLICT_TYPE runtime error
   CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
     EXPORTING
-      i_field_seperator = 'X'
-      i_line_header     = 'X'    " Skip header row
-      i_tab_raw_data    = lt_raw
-      i_filename        = lv_file
+      i_field_seperator    = 'X'
+      i_line_header        = 'X'    " Skip header row
+      i_filename           = lv_file
     TABLES
       i_tab_converted_data = lt_upload
+    CHANGING
+      i_tab_raw_data       = lt_raw
     EXCEPTIONS
-      conversion_failed   = 1
-      OTHERS              = 2.
+      conversion_failed    = 1
+      OTHERS               = 2.
 
   IF sy-subrc <> 0.
     MESSAGE 'Failed to read Excel file.' TYPE 'S' DISPLAY LIKE 'E'.
```

### CODE_F02.md — modified

`+54 / -3 lines`

```diff
--- previous/CODE_F02.md
+++ current/CODE_F02.md
@@ -1,5 +1,5 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads (v4.0)
+*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads (v4.0 → v4.1 BUGFIX)
 *&---------------------------------------------------------------------*
 *& v4.0 changes:
 *&  - NEW: f4_date — Calendar popup for date fields (Feature #4)
@@ -8,6 +8,11 @@
 *&  - NEW: download_confirm_template   (ZTEMPLATE_CONFIRM)   (Feature #7)
 *&  - NEW: download_bugproof_template  (ZTEMPLATE_BUGPROOF)  (Feature #7)
 *&  - ENHANCED: download_project_template — refactored to use generic helper
+*&
+*& v4.1 BUGFIX changes:
+*&  - NEW: f4_project_status — F4 help for project status dropdown (Bug #1)
+*&  - load_long_text: added EXCEPTIONS to set_text_as_r3table (Bug #6)
+*&  - save_long_text: added cl_gui_cfw=>flush() + EXCEPTIONS to get_text_as_r3table (Bug #6)
 *&---------------------------------------------------------------------*
 
 *&=== F4: PROJECT ID ===*
@@ -186,6 +191,38 @@
 ENDFORM.
 
 *&=====================================================================*
+*& v4.1 BUGFIX #1: F4 PROJECT STATUS
+*& Dropdown for project status field on Screen 0500
+*& Called from POV module f4_prj_status → CODE_PAI.md
+*&=====================================================================*
+FORM f4_project_status USING pv_fn TYPE dynfnam.
+  TYPES: BEGIN OF ty_pst_f4,
+           code TYPE char1,
+           text TYPE char20,
+         END OF ty_pst_f4.
+  DATA: lt_ret TYPE TABLE OF ddshretval,
+        lt_val TYPE TABLE OF ty_pst_f4.
+
+  APPEND VALUE ty_pst_f4( code = '1' text = 'Opening' )   TO lt_val.
+  APPEND VALUE ty_pst_f4( code = '2' text = 'In Process' ) TO lt_val.
+  APPEND VALUE ty_pst_f4( code = '3' text = 'Done' )       TO lt_val.
+  APPEND VALUE ty_pst_f4( code = '4' text = 'Cancelled' )  TO lt_val.
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
+*&=====================================================================*
 *& F4 DATE CALENDAR POPUP (v4.0 — Feature #4)
 *&
 *& Shows SAP calendar popup and assigns selected date to the
@@ -261,7 +298,11 @@
     LOOP AT lt_lines INTO ls_line.
       APPEND CONV char255( ls_line-tdline ) TO lt_text.
     ENDLOOP.
-    lr_editor->set_text_as_r3table( table = lt_text ).
+    lr_editor->set_text_as_r3table(
+      EXPORTING table = lt_text
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
   ENDIF.
 ENDFORM.
 
@@ -284,7 +325,17 @@
         lt_lines TYPE TABLE OF tline,
         ls_line  TYPE tline.
 
-  lr_editor->get_text_as_r3table( IMPORTING table = lt_text ).
+  " v4.1 BUGFIX #6: Flush GUI before reading text to prevent POTENTIAL_DATA_LOSS
+  cl_gui_cfw=>flush( ).
+
+  lr_editor->get_text_as_r3table(
+    IMPORTING table = lt_text
+    EXCEPTIONS error_dp        = 1
+               error_dp_create = 2
+               OTHERS          = 3 ).
+  IF sy-subrc <> 0.
+    RETURN.  " Cannot read text — skip save for this text ID
+  ENDIF.
 
   LOOP AT lt_text INTO DATA(lv_line).
     CLEAR ls_line.
```

### CODE_PAI.md — modified

`+55 / -1 lines`

```diff
--- previous/CODE_PAI.md
+++ current/CODE_PAI.md
@@ -1,11 +1,15 @@
 *&---------------------------------------------------------------------*
-*& Include Z_BUG_WS_PAI — User Action Logic (v4.0)
+*& Include Z_BUG_WS_PAI — User Action Logic (v4.0 → v4.1 BUGFIX)
 *&---------------------------------------------------------------------*
 *& v4.0 changes (over v3.0):
 *&  - user_command_0300: added DL_EVD (delete evidence), SENDMAIL handlers
 *&  - user_command_0300: added unsaved changes check before BACK/CANC
 *&  - user_command_0500: added unsaved changes check before BACK/CANC
 *&  - user_command_0200: added DN_TC, DN_CONF, DN_PROOF (template downloads)
+*&
+*& v4.1 BUGFIX changes:
+*&  - Added 8 POV modules for Screen 0310 F4 help (Bug #5)
+*&  - Added 2 POV modules for Screen 0500: project_status, project_manager (Bug #1)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety) ---*
@@ -289,3 +293,53 @@
 MODULE f4_prj_enddate INPUT.
   PERFORM f4_date USING 'PRJ_END_DATE'.
 ENDMODULE.
+
+*&=====================================================================*
+*& v4.1 BUGFIX #1: POV MODULES — Screen 0500 (Project Detail)
+*& F4 help for PROJECT_STATUS and PROJECT_MANAGER fields
+*&=====================================================================*
+MODULE f4_prj_status INPUT.
+  PERFORM f4_project_status USING 'GS_PROJECT-PROJECT_STATUS'.
+ENDMODULE.
+
+MODULE f4_prj_manager INPUT.
+  PERFORM f4_user_id USING 'GS_PROJECT-PROJECT_MANAGER'.
+ENDMODULE.
+
+*&=====================================================================*
+*& v4.1 BUGFIX #5: POV MODULES — Screen 0310 (Bug Info)
+*& F4 help for STATUS, PRIORITY, SEVERITY, BUG_TYPE, PROJECT_ID,
+*& TESTER_ID, DEV_ID, VERIFY_TESTER_ID fields
+*& Called from PROCESS ON VALUE-REQUEST in Screen 0310 flow logic.
+*&=====================================================================*
+MODULE f4_bug_status INPUT.
+  PERFORM f4_status USING 'GS_BUG_DETAIL-STATUS'.
+ENDMODULE.
+
+MODULE f4_bug_priority INPUT.
+  PERFORM f4_priority USING 'GS_BUG_DETAIL-PRIORITY'.
+ENDMODULE.
+
+MODULE f4_bug_severity INPUT.
+  PERFORM f4_severity USING 'GS_BUG_DETAIL-SEVERITY'.
+ENDMODULE.
+
+MODULE f4_bug_type INPUT.
+  PERFORM f4_bug_type USING 'GS_BUG_DETAIL-BUG_TYPE'.
+ENDMODULE.
+
+MODULE f4_bug_project INPUT.
+  PERFORM f4_project_id USING 'GS_BUG_DETAIL-PROJECT_ID'.
+ENDMODULE.
+
+MODULE f4_bug_tester INPUT.
+  PERFORM f4_user_id USING 'GS_BUG_DETAIL-TESTER_ID'.
+ENDMODULE.
+
+MODULE f4_bug_dev INPUT.
+  PERFORM f4_user_id USING 'GS_BUG_DETAIL-DEV_ID'.
+ENDMODULE.
+
+MODULE f4_bug_verify INPUT.
+  PERFORM f4_user_id USING 'GS_BUG_DETAIL-VERIFY_TESTER_ID'.
+ENDMODULE.
```

### CODE_PBO.md — modified

`+32 / -5 lines`

```diff
--- previous/CODE_PBO.md
+++ current/CODE_PBO.md
@@ -8,6 +8,14 @@
 *&  - status_0200: added template download button exclusions (DN_TC/DN_CONF/DN_PROOF)
 *&  - init_evidence_alv: NEW module for subscreen 0350
 *&  - modify_screen_0300: added FNC screen group (Tester/Manager-only fields)
+*&
+*& v4.1 BUGFIX changes:
+*&  - load_bug_detail: Create mode sets BUG_ID = '(Auto)' placeholder (Bug #5)
+*&  - modify_screen_0300: BID group → ALWAYS display-only (Bug #5)
+*&  - init_desc_mini: added EXCEPTIONS to set_text_as_r3table (Bug #6)
+*&  - status_0500: exclude ADD_USER/REMO_USR in Create mode (Bug #1)
+*&  - init_project_detail: Create mode sets PROJECT_ID = '(Auto)' (Bug #1)
+*&  - modify_screen_0500: added PID group → always display-only (Bug #1/#3)
 *&---------------------------------------------------------------------*
 
 *&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
@@ -177,6 +185,8 @@
   " 5. Create mode: reset work area with defaults
   IF gv_mode = gc_mode_create.
     CLEAR gs_bug_detail.
+    " v4.1 BUGFIX #5: Show placeholder — BUG_ID will be auto-generated on save
+    gs_bug_detail-bug_id = '(Auto)'.
     " Pre-fill PROJECT_ID from project context (locked on screen)
     IF gv_current_project_id IS NOT INITIAL.
       gs_bug_detail-project_id = gv_current_project_id.
@@ -244,11 +254,10 @@
       MODIFY SCREEN.
     ENDIF.
 
-    " BUG_ID: display-only after creation (group BID)
+    " BUG_ID: ALWAYS display-only (auto-generated on save) — v4.1 BUGFIX #5
+    " Previously was editable in Create mode which confused users
     IF screen-group1 = 'BID'.
-      IF gv_mode <> gc_mode_create.
-        screen-input = 0.  " Lock BUG_ID after creation
-      ENDIF.
+      screen-input = 0.  " Always locked — shows "(Auto)" in Create, real ID after save
       MODIFY SCREEN.
     ENDIF.
 
@@ -305,7 +314,11 @@
       SPLIT gs_bug_detail-desc_text AT cl_abap_char_utilities=>cr_lf
         INTO TABLE lt_mini_text.
     ENDIF.
-    go_desc_mini_edit->set_text_as_r3table( table = lt_mini_text ).
+    go_desc_mini_edit->set_text_as_r3table(
+      EXPORTING table = lt_mini_text
+      EXCEPTIONS error_dp        = 1
+                 error_dp_create = 2
+                 OTHERS          = 3 ).
   ENDIF.
 
   " Readonly mode: set every PBO (may differ between bugs)
@@ -471,6 +484,12 @@
     APPEND 'ADD_USER' TO gm_excl.
     APPEND 'REMO_USR' TO gm_excl.
   ENDIF.
+  " v4.1 BUGFIX #1: Create mode → hide ADD_USER/REMO_USR
+  " Project not yet saved → gv_current_project_id is empty → add user would fail
+  IF gv_mode = gc_mode_create.
+    APPEND 'ADD_USER' TO gm_excl.
+    APPEND 'REMO_USR' TO gm_excl.
+  ENDIF.
   SET PF-STATUS 'STATUS_0500' EXCLUDING gm_excl.
 
   " Title shows mode
@@ -500,6 +519,8 @@
 
   IF gv_mode = gc_mode_create.
     CLEAR: gs_project, gt_user_project.
+    " v4.1 BUGFIX #1: Show placeholder — PROJECT_ID will be auto-generated on save
+    gs_project-project_id      = '(Auto)'.
     gs_project-project_manager = gv_uname.  " Default manager = current user
     gs_project-project_status  = '1'.       " Opening
   ENDIF.
@@ -531,5 +552,11 @@
       ENDIF.
       MODIFY SCREEN.
     ENDIF.
+
+    " v4.1 BUGFIX #1/#3: PROJECT_ID ALWAYS display-only (primary key, auto-generated)
+    IF screen-group1 = 'PID'.
+      screen-input = 0.
+      MODIFY SCREEN.
+    ENDIF.
   ENDLOOP.
 ENDMODULE.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
