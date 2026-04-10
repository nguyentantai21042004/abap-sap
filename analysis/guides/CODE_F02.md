*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads (v4.0 → v4.1 BUGFIX)
*&---------------------------------------------------------------------*
*& v4.0 changes:
*&  - NEW: f4_date — Calendar popup for date fields (Feature #4)
*&  - NEW: download_smw0_template — Generic SMW0 download + auto-open (Feature #10)
*&  - NEW: download_testcase_template  (ZTEMPLATE_TESTCASE)  (Feature #7)
*&  - NEW: download_confirm_template   (ZTEMPLATE_CONFIRM)   (Feature #7)
*&  - NEW: download_bugproof_template  (ZTEMPLATE_BUGPROOF)  (Feature #7)
*&  - ENHANCED: download_project_template — refactored to use generic helper
*&
*& v4.1 BUGFIX changes:
*&  - NEW: f4_project_status — F4 help for project status dropdown (Bug #1)
*&  - load_long_text: added EXCEPTIONS to set_text_as_r3table (Bug #6)
*&  - save_long_text: added cl_gui_cfw=>flush() + EXCEPTIONS to get_text_as_r3table (Bug #6)
*&---------------------------------------------------------------------*

*&=== F4: PROJECT ID ===*
FORM f4_project_id USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_prj_f4,
           project_id   TYPE zde_project_id,
           project_name TYPE zde_prj_name,
         END OF ty_prj_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_prj_f4.

  SELECT project_id, project_name FROM zbug_project
    INTO CORRESPONDING FIELDS OF TABLE @lt_val
    WHERE is_del <> 'X'
    ORDER BY project_id.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PROJECT_ID'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=== F4: USER ID ===*
FORM f4_user_id USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_usr_f4,
           user_id   TYPE zde_username,
           full_name TYPE zde_bug_full_name,
           role      TYPE zde_bug_role,
         END OF ty_usr_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_usr_f4.

  SELECT user_id, full_name, role FROM zbug_users
    INTO CORRESPONDING FIELDS OF TABLE @lt_val
    WHERE is_del <> 'X' AND is_active = 'X'
    ORDER BY user_id.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'USER_ID'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=== F4: BUG STATUS ===*
FORM f4_status USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_st_f4,
           code TYPE char2,
           text TYPE char20,
         END OF ty_st_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_st_f4.

  APPEND VALUE ty_st_f4( code = '1' text = 'New' )        TO lt_val.
  APPEND VALUE ty_st_f4( code = '2' text = 'Assigned' )   TO lt_val.
  APPEND VALUE ty_st_f4( code = '3' text = 'In Progress' ) TO lt_val.
  APPEND VALUE ty_st_f4( code = '4' text = 'Pending' )    TO lt_val.
  APPEND VALUE ty_st_f4( code = '5' text = 'Fixed' )      TO lt_val.
  APPEND VALUE ty_st_f4( code = '6' text = 'Resolved' )   TO lt_val.
  APPEND VALUE ty_st_f4( code = '7' text = 'Closed' )     TO lt_val.
  APPEND VALUE ty_st_f4( code = 'W' text = 'Waiting' )    TO lt_val.
  APPEND VALUE ty_st_f4( code = 'R' text = 'Rejected' )   TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=== F4: PRIORITY ===*
FORM f4_priority USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_prio_f4,
           code TYPE char1,
           text TYPE char10,
         END OF ty_prio_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_prio_f4.

  APPEND VALUE ty_prio_f4( code = 'H' text = 'High' )   TO lt_val.
  APPEND VALUE ty_prio_f4( code = 'M' text = 'Medium' ) TO lt_val.
  APPEND VALUE ty_prio_f4( code = 'L' text = 'Low' )    TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=== F4: BUG TYPE ===*
FORM f4_bug_type USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_type_f4,
           code TYPE char1,
           text TYPE char20,
         END OF ty_type_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_type_f4.

  APPEND VALUE ty_type_f4( code = '1' text = 'Functional Bug' )  TO lt_val.
  APPEND VALUE ty_type_f4( code = '2' text = 'Performance Bug' ) TO lt_val.
  APPEND VALUE ty_type_f4( code = '3' text = 'UI/UX Bug' )       TO lt_val.
  APPEND VALUE ty_type_f4( code = '4' text = 'Integration Bug' ) TO lt_val.
  APPEND VALUE ty_type_f4( code = '5' text = 'Security Bug' )    TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=== F4: SEVERITY ===*
FORM f4_severity USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_sev_f4,
           code TYPE char1,
           text TYPE char20,
         END OF ty_sev_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_sev_f4.

  APPEND VALUE ty_sev_f4( code = '1' text = 'Dump / Critical' ) TO lt_val.
  APPEND VALUE ty_sev_f4( code = '2' text = 'Very High' )       TO lt_val.
  APPEND VALUE ty_sev_f4( code = '3' text = 'High' )            TO lt_val.
  APPEND VALUE ty_sev_f4( code = '4' text = 'Normal' )          TO lt_val.
  APPEND VALUE ty_sev_f4( code = '5' text = 'Minor' )           TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=====================================================================*
*& v4.1 BUGFIX #1: F4 PROJECT STATUS
*& Dropdown for project status field on Screen 0500
*& Called from POV module f4_prj_status → CODE_PAI.md
*&=====================================================================*
FORM f4_project_status USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_pst_f4,
           code TYPE char1,
           text TYPE char20,
         END OF ty_pst_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_pst_f4.

  APPEND VALUE ty_pst_f4( code = '1' text = 'Opening' )   TO lt_val.
  APPEND VALUE ty_pst_f4( code = '2' text = 'In Process' ) TO lt_val.
  APPEND VALUE ty_pst_f4( code = '3' text = 'Done' )       TO lt_val.
  APPEND VALUE ty_pst_f4( code = '4' text = 'Cancelled' )  TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=====================================================================*
*& F4 DATE CALENDAR POPUP (v4.0 — Feature #4)
*&
*& Shows SAP calendar popup and assigns selected date to the
*& appropriate global structure field based on pv_field_name.
*&
*& Called from POV modules in PAI:
*&   MODULE f4_prj_startdate  → PERFORM f4_date USING 'PRJ_START_DATE'
*&   MODULE f4_prj_enddate    → PERFORM f4_date USING 'PRJ_END_DATE'
*&
*& NOTE: Bug date fields (DEADLINE, START_DATE) do NOT exist in
*&       ZBUG_TRACKER per SE11. Only project dates are supported.
*&
*& Pattern from ZPG_BUGTRACKING_DETAIL (MODULE f4_date / f4_startdate):
*& Assigns directly to structure field — screen picks up new value on PBO.
*&=====================================================================*
FORM f4_date USING pv_field_name TYPE char20.
  DATA: lv_selected_date TYPE dats.

  CALL FUNCTION 'F4_DATE'
    EXPORTING
      date_for_first_month         = sy-datum
      display                      = ' '
    IMPORTING
      select_date                  = lv_selected_date
    EXCEPTIONS
      calendar_buffer_not_loadable = 1
      date_after_range             = 2
      date_before_range            = 3
      date_invalid                 = 4
      OTHERS                       = 8.

  CHECK sy-subrc = 0.

  CASE pv_field_name.
    WHEN 'PRJ_START_DATE'.
      gs_project-start_date = lv_selected_date.
    WHEN 'PRJ_END_DATE'.
      gs_project-end_date = lv_selected_date.
  ENDCASE.
ENDFORM.

*&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
" Editor is resolved internally from global objects (go_edit_desc/dev_note/tstr_note)
FORM load_long_text USING pv_text_id TYPE thead-tdid.
  CHECK gv_current_bug_id IS NOT INITIAL.

  " Resolve editor reference from text_id
  DATA: lr_editor TYPE REF TO cl_gui_textedit.
  CASE pv_text_id.
    WHEN 'Z001'. lr_editor = go_edit_desc.
    WHEN 'Z002'. lr_editor = go_edit_dev_note.
    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
  ENDCASE.
  CHECK lr_editor IS NOT INITIAL.

  DATA: lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id       = pv_text_id
      language = sy-langu
      name     = gv_current_bug_id
      object   = 'ZBUG'
    TABLES
      lines    = lt_lines
    EXCEPTIONS
      OTHERS   = 4.  " subrc 4 = text not found (OK for new bugs)

  IF sy-subrc = 0.
    DATA: lt_text TYPE TABLE OF char255.
    LOOP AT lt_lines INTO ls_line.
      APPEND CONV char255( ls_line-tdline ) TO lt_text.
    ENDLOOP.
    lr_editor->set_text_as_r3table(
      EXPORTING table = lt_text
      EXCEPTIONS error_dp        = 1
                 error_dp_create = 2
                 OTHERS          = 3 ).
  ENDIF.
ENDFORM.

*&=== LONG TEXT: SAVE (Text Object ZBUG) ===*
" pv_text_id: 'Z001' = Description, 'Z002' = Dev Note, 'Z003' = Tester Note
" Editor is resolved internally. Caller must set gv_current_bug_id before calling.
FORM save_long_text USING pv_text_id TYPE thead-tdid.
  CHECK gv_current_bug_id IS NOT INITIAL.

  " Resolve editor reference from text_id
  DATA: lr_editor TYPE REF TO cl_gui_textedit.
  CASE pv_text_id.
    WHEN 'Z001'. lr_editor = go_edit_desc.
    WHEN 'Z002'. lr_editor = go_edit_dev_note.
    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
  ENDCASE.
  CHECK lr_editor IS NOT INITIAL.

  DATA: lt_text  TYPE TABLE OF char255,
        lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline.

  " v4.1 BUGFIX #6: Flush GUI before reading text to prevent POTENTIAL_DATA_LOSS
  cl_gui_cfw=>flush( ).

  lr_editor->get_text_as_r3table(
    IMPORTING table = lt_text
    EXCEPTIONS error_dp        = 1
               error_dp_create = 2
               OTHERS          = 3 ).
  IF sy-subrc <> 0.
    RETURN.  " Cannot read text — skip save for this text ID
  ENDIF.

  LOOP AT lt_text INTO DATA(lv_line).
    CLEAR ls_line.
    ls_line-tdformat = '*'.
    ls_line-tdline   = lv_line.
    APPEND ls_line TO lt_lines.
  ENDLOOP.

  DATA: ls_header TYPE thead.
  ls_header-tdobject = 'ZBUG'.
  ls_header-tdname   = gv_current_bug_id.
  ls_header-tdid     = pv_text_id.
  ls_header-tdspras  = sy-langu.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = ls_header
    TABLES
      lines           = lt_lines
    EXCEPTIONS
      OTHERS          = 4.
  " Note: SAVE_TEXT performs its own internal COMMIT
ENDFORM.

*&=====================================================================*
*& GENERIC SMW0 TEMPLATE DOWNLOAD + AUTO-OPEN (v4.0 — Features #7, #10)
*&
*& Downloads a binary template from SMW0 (MIME Repository) to local PC
*& and auto-opens it in the default application (e.g., Excel).
*&
*& Pattern from reference program ZPG_BUGTRACKING_MAIN (FORM excute_download):
*& 1. Check template exists in WWWDATA table
*& 2. Read file extension + size from WWWPARAMS table
*& 3. WWWDATA_IMPORT to load binary content into memory
*& 4. file_save_dialog for user to pick save location
*& 5. GUI_DOWNLOAD in BIN mode with exact bin_filesize
*& 6. cl_gui_frontend_services=>execute to auto-open
*&
*& SMW0 Object IDs used:
*&   ZTEMPLATE_PROJECT  — Project upload template
*&   ZTEMPLATE_TESTCASE — Test case template (required before Resolved)
*&   ZTEMPLATE_CONFIRM  — Confirm template (required before Closed)
*&   ZTEMPLATE_BUGPROOF — Bug proof template (required before Fixed)
*&=====================================================================*
FORM download_smw0_template USING pv_objid TYPE wwwdatatab-objid.
  DATA: ls_wdata    TYPE wwwdatatab,
        lv_filename TYPE string,
        lv_ext      TYPE string,
        lv_size     TYPE string,
        lv_filesize TYPE i,
        lt_wmime    TYPE TABLE OF w3mime,
        lv_path     TYPE string,
        lv_fullpath TYPE string,
        lv_msg      TYPE string.

  " 1. Check if template exists in SMW0
  SELECT SINGLE * FROM wwwdata                              "#EC WARNOK
    INTO CORRESPONDING FIELDS OF ls_wdata
    WHERE relid = 'MI'
      AND objid = pv_objid.

  IF sy-subrc <> 0.
    lv_msg = |Template { pv_objid } not found in SMW0. Upload it first.|.
    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 2. Get file metadata from WWWPARAMS
  "    - text field from WWWDATA = display name (used as default filename)
  "    - 'fileextension' param  = original file extension
  "    - 'filesize' param       = exact byte size (critical for BIN download)
  lv_filename = ls_wdata-text.
  IF lv_filename IS INITIAL.
    lv_filename = pv_objid.
  ENDIF.

  SELECT SINGLE value INTO lv_ext
    FROM wwwparams
    WHERE relid = ls_wdata-relid
      AND objid = ls_wdata-objid
      AND name  = 'fileextension'.
  REPLACE ALL OCCURRENCES OF '.' IN lv_ext WITH ''.
  IF lv_ext IS INITIAL.
    lv_ext = 'xlsx'.
  ENDIF.

  SELECT SINGLE value INTO lv_size
    FROM wwwparams
    WHERE relid = ls_wdata-relid
      AND objid = ls_wdata-objid
      AND name  = 'filesize'.
  lv_filesize = lv_size.

  " 3. Load binary content from WWWDATA into memory
  CALL FUNCTION 'WWWDATA_IMPORT'
    EXPORTING
      key               = ls_wdata
    TABLES
      mime              = lt_wmime
    EXCEPTIONS
      wrong_object_type = 1
      import_error      = 2
      OTHERS            = 3.

  IF sy-subrc <> 0.
    lv_msg = |Failed to load template { pv_objid } from SMW0.|.
    MESSAGE lv_msg TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 4. File save dialog — let user choose destination
  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = lv_ext
      default_file_name = lv_filename
    CHANGING
      filename    = lv_filename
      path        = lv_path
      fullpath    = lv_fullpath
    EXCEPTIONS OTHERS = 1 ).

  IF lv_fullpath IS INITIAL.
    MESSAGE 'Download cancelled.' TYPE 'S'.
    RETURN.
  ENDIF.

  " 5. Download binary to local file
  "    bin_filesize is critical — without it the last MIME block
  "    may be padded with nulls, corrupting the file.
  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename     = lv_fullpath
      filetype     = 'BIN'
      bin_filesize = lv_filesize
    TABLES
      data_tab     = lt_wmime
    EXCEPTIONS
      OTHERS       = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Failed to save template file.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 6. Auto-open the downloaded file in default app (Feature #10)
  cl_gui_frontend_services=>execute(
    EXPORTING
      document               = lv_fullpath
    EXCEPTIONS
      cntl_error             = 1
      error_no_gui           = 2
      bad_parameter          = 3
      file_not_found         = 4
      path_not_found         = 5
      file_extension_unknown = 6
      error_execute_failed   = 7
      synchronous_failed     = 8
      not_supported_by_gui   = 9
      OTHERS                 = 10 ).
  " Ignore execute errors — file is already saved successfully

  MESSAGE 'Template downloaded successfully.' TYPE 'S'.
ENDFORM.

*&=== DOWNLOAD PROJECT TEMPLATE ===*
*& Wrapper: downloads ZTEMPLATE_PROJECT from SMW0
*& Called from PAI fcode DN_TMPL on Screen 0400
FORM download_project_template.
  PERFORM download_smw0_template USING 'ZTEMPLATE_PROJECT'.
ENDFORM.

*&=====================================================================*
*& DOWNLOAD TESTCASE TEMPLATE (v4.0 — Feature #7)
*& Wrapper: downloads ZTEMPLATE_TESTCASE from SMW0
*& Called from PAI fcode DN_TC on Screen 0200
*& User must upload this template to SMW0 (Binary, relid = MI)
*&=====================================================================*
FORM download_testcase_template.
  PERFORM download_smw0_template USING 'ZTEMPLATE_TESTCASE'.
ENDFORM.

*&=====================================================================*
*& DOWNLOAD CONFIRM TEMPLATE (v4.0 — Feature #7)
*& Wrapper: downloads ZTEMPLATE_CONFIRM from SMW0
*& Called from PAI fcode DN_CONF on Screen 0200
*& User must upload this template to SMW0 (Binary, relid = MI)
*&=====================================================================*
FORM download_confirm_template.
  PERFORM download_smw0_template USING 'ZTEMPLATE_CONFIRM'.
ENDFORM.

*&=====================================================================*
*& DOWNLOAD BUGPROOF TEMPLATE (v4.0 — Feature #7)
*& Wrapper: downloads ZTEMPLATE_BUGPROOF from SMW0
*& Called from PAI fcode DN_PROOF on Screen 0200
*& User must upload this template to SMW0 (Binary, relid = MI)
*&=====================================================================*
FORM download_bugproof_template.
  PERFORM download_smw0_template USING 'ZTEMPLATE_BUGPROOF'.
ENDFORM.
