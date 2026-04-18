*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Template Downloads
*&---------------------------------------------------------------------*

*&=====================================================================*
*& F4 VALUE HELPS — Existing
*&=====================================================================*

*&=== F4: PROJECT ID (for Screen 0300/0500) ===*
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

*&=== F4: BUG STATUS (10 states — 6=FinalTesting, V=Resolved) ===*
FORM f4_status USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_st_f4,
           code TYPE char2,
           text TYPE char20,
         END OF ty_st_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_st_f4.

  APPEND VALUE ty_st_f4( code = '1' text = 'New' )            TO lt_val.
  APPEND VALUE ty_st_f4( code = '2' text = 'Assigned' )       TO lt_val.
  APPEND VALUE ty_st_f4( code = '3' text = 'In Progress' )    TO lt_val.
  APPEND VALUE ty_st_f4( code = '4' text = 'Pending' )        TO lt_val.
  APPEND VALUE ty_st_f4( code = '5' text = 'Fixed' )          TO lt_val.
  APPEND VALUE ty_st_f4( code = '6' text = 'Final Testing' )  TO lt_val.
  APPEND VALUE ty_st_f4( code = '7' text = 'Closed' )         TO lt_val.
  APPEND VALUE ty_st_f4( code = 'W' text = 'Waiting' )        TO lt_val.
  APPEND VALUE ty_st_f4( code = 'R' text = 'Rejected' )       TO lt_val.
  APPEND VALUE ty_st_f4( code = 'V' text = 'Resolved' )       TO lt_val.

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

*&=== F4: PROJECT STATUS (for Screen 0500) ===*
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
*& F4 DATE CALENDAR POPUP
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

*&=====================================================================*
*& NEW F4 VALUE HELPS
*&=====================================================================*

*&=== F4: SAP MODULE (for Screen 0310) ===*
*& Static list of SAP modules.
*& Called from PAI MODULE f4_bug_sapmodule → PERFORM f4_sap_module USING ...
FORM f4_sap_module USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mod_f4,
           sap_module TYPE zde_sap_module,
         END OF ty_mod_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mod_f4.

  lt_val = VALUE #(
    ( sap_module = 'FI' )
    ( sap_module = 'MM' )
    ( sap_module = 'SD' )
    ( sap_module = 'ABAP' )
    ( sap_module = 'BASIS' )
    ( sap_module = 'PP' )
    ( sap_module = 'HR' )
    ( sap_module = 'QM' )
    ( sap_module = 'CO' )
    ( sap_module = 'PM' )
    ( sap_module = 'WM' )
    ( sap_module = 'PS' ) ).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SAP_MODULE'
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

*&=== F4: PROJECT ID HELP (for Screen 0410 search) ===*
*& Same logic as f4_project_id but separate form name for PAI module clarity.
*& Called from PAI MODULE f4_project_id → PERFORM f4_project_id_help USING 'S_PRJ_ID'
FORM f4_project_id_help USING pv_fn TYPE dynfnam.
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

*&=== F4: MANAGER HELP (for Screen 0410 search) ===*
*& Filters ZBUG_USERS by role = 'M' (Manager).
*& Called from PAI MODULE f4_manager → PERFORM f4_manager_help USING 'S_PRJ_MN'
FORM f4_manager_help USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mgr_f4,
           user_id   TYPE zde_username,
           full_name TYPE zde_bug_full_name,
         END OF ty_mgr_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mgr_f4.

  SELECT user_id, full_name FROM zbug_users
    INTO CORRESPONDING FIELDS OF TABLE @lt_val
    WHERE role = 'M' AND is_del <> 'X'
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

*&=== F4: PROJECT STATUS HELP (for Screen 0410 search) ===*
*& Same logic as f4_project_status but separate form name for PAI module clarity.
*& Called from PAI MODULE f4_project_status → PERFORM f4_project_status_help USING 'S_PRJ_ST'
FORM f4_project_status_help USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_st_f4,
           status TYPE char1,
           text   TYPE char20,
         END OF ty_st_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_st_f4.

  lt_val = VALUE #(
    ( status = '1' text = 'Opening' )
    ( status = '2' text = 'In Process' )
    ( status = '3' text = 'Done' )
    ( status = '4' text = 'Cancelled' ) ).

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'STATUS'
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
*& F4: TRANSITION STATUS (for Screen 0370 popup)
*&
*& Shows ONLY valid target statuses based on current status
*& (gv_trans_cur_status) + user role (gv_role).
*& Enforces the transition matrix at the UI level.
*&
*& Called from PAI MODULE f4_trans_status_mod → PERFORM f4_trans_status
*& Note: hardcoded dynprofield = 'GV_TRANS_NEW_STATUS' (Screen 0370)
*&=====================================================================*
FORM f4_trans_status.
  TYPES: BEGIN OF ty_st_f4,
           status TYPE zde_bug_status,
           text   TYPE char20,
         END OF ty_st_f4.
  DATA: lt_val TYPE TABLE OF ty_st_f4,
        lt_ret TYPE TABLE OF ddshretval.

  " Build allowed list based on current status + role
  CASE gv_trans_cur_status.
    WHEN gc_st_new.        " New → Assigned, Waiting (Manager only)
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned text = 'Assigned' )
          ( status = gc_st_waiting  text = 'Waiting' ) ).
      ENDIF.

    WHEN gc_st_waiting.    " Waiting → Assigned, FinalTesting (Manager only)
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned     text = 'Assigned' )
          ( status = gc_st_finaltesting text = 'Final Testing' ) ).
      ENDIF.

    WHEN gc_st_assigned.   " Assigned → InProgress, Rejected (Dev assigned or Manager)
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lt_val = VALUE #(
          ( status = gc_st_inprogress text = 'In Progress' )
          ( status = gc_st_rejected   text = 'Rejected' ) ).
      ENDIF.

    WHEN gc_st_inprogress. " InProgress → Fixed, Pending, Rejected (Dev assigned or Manager)
      IF gv_role = 'M' OR ( gv_role = 'D' AND gs_bug_detail-dev_id = sy-uname ).
        lt_val = VALUE #(
          ( status = gc_st_fixed    text = 'Fixed' )
          ( status = gc_st_pending  text = 'Pending' )
          ( status = gc_st_rejected text = 'Rejected' ) ).
      ENDIF.

    WHEN gc_st_pending.    " Pending → Assigned (Manager only)
      IF gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_assigned text = 'Assigned' ) ).
      ENDIF.

    WHEN gc_st_finaltesting. " FinalTesting → Resolved, InProgress (FinalTester or Manager)
      IF gs_bug_detail-verify_tester_id = sy-uname OR gv_role = 'M'.
        lt_val = VALUE #(
          ( status = gc_st_resolved   text = 'Resolved' )
          ( status = gc_st_inprogress text = 'In Progress' ) ).
      ENDIF.

    " Fixed(5), Resolved(V), Closed(7), Rejected(R) → terminal/automatic, no manual transitions
  ENDCASE.

  IF lt_val IS INITIAL.
    MESSAGE 'No valid transitions available for your role.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'STATUS'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = 'GV_TRANS_NEW_STATUS'
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.

*&=====================================================================*
*& LONG TEXT OPERATIONS
*&=====================================================================*

*&=== LONG TEXT: LOAD (Text Object ZBUG) ===*
*& pv_text_id: 'Z001' = Description (only)
*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — no textedit needed.
*& Editor is resolved internally from global object go_edit_desc.
*&
*& Explicit lv_tdname TYPE tdobname cast to prevent CALL_FUNCTION_CONFLICT_TYPE:
*& gv_current_bug_id is CHAR 10, but READ_TEXT NAME expects TDOBNAME = CHAR 70.
FORM load_long_text USING pv_text_id TYPE thead-tdid.
  CHECK gv_current_bug_id IS NOT INITIAL.

  " Resolve editor reference from text_id
  DATA: lr_editor TYPE REF TO cl_gui_textedit.
  CASE pv_text_id.
    WHEN 'Z001'. lr_editor = go_edit_desc.
  ENDCASE.
  CHECK lr_editor IS NOT INITIAL.

  DATA: lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline.

  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
  DATA: lv_tdname TYPE tdobname.
  lv_tdname = gv_current_bug_id.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id       = pv_text_id
      language = sy-langu
      name     = lv_tdname
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
*& pv_text_id: 'Z001' = Description (only)
*& Dev Note and Tester Note are now CHAR fields on ZBUG_TRACKER — saved via UPDATE.
*& Caller must set gv_current_bug_id before calling.
*&
*& Explicit lv_tdname TYPE tdobname cast for SAVE_TEXT (same reason as load_long_text).
FORM save_long_text USING pv_text_id TYPE thead-tdid.
  CHECK gv_current_bug_id IS NOT INITIAL.

  " Resolve editor reference from text_id
  DATA: lr_editor TYPE REF TO cl_gui_textedit.
  CASE pv_text_id.
    WHEN 'Z001'.
      " Prefer full editor (tab 0320). If user never opened Description tab,
      " fall back to mini editor (tab 0310) to avoid losing desc_text.
      IF go_edit_desc IS NOT INITIAL.
        lr_editor = go_edit_desc.
      ELSE.
        lr_editor = go_desc_mini_edit.
      ENDIF.
  ENDCASE.

  DATA: lt_text  TYPE TABLE OF char255,
        lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline.

  " Try to read text from editor
  IF lr_editor IS NOT INITIAL.
    cl_gui_cfw=>flush( ).
    lr_editor->get_text_as_r3table(
      IMPORTING table = lt_text
      EXCEPTIONS error_dp        = 1
                 error_dp_create = 2
                 OTHERS          = 3 ).
  ENDIF.

  IF lr_editor IS INITIAL OR sy-subrc <> 0.
    RETURN.
  ENDIF.

  LOOP AT lt_text INTO DATA(lv_line).
    CLEAR ls_line.
    ls_line-tdformat = '*'.
    ls_line-tdline   = lv_line.
    APPEND ls_line TO lt_lines.
  ENDLOOP.

  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
  DATA: lv_tdname TYPE tdobname.
  lv_tdname = gv_current_bug_id.

  DATA: ls_header TYPE thead.
  ls_header-tdobject = 'ZBUG'.
  ls_header-tdname   = lv_tdname.
  ls_header-tdid     = pv_text_id.
  ls_header-tdspras  = sy-langu.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = ls_header
      savemode_direct = 'X'
    TABLES
      lines           = lt_lines
    EXCEPTIONS
      OTHERS          = 4.
  IF sy-subrc <> 0.
    DATA: lv_save_msg TYPE string.
    lv_save_msg = |Long text { pv_text_id } save failed (RC={ sy-subrc }). Check text object ZBUG in SE75.|.
    MESSAGE lv_save_msg TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& LONG TEXT: SAVE DIRECT (from table param, no editor)
*&
*& Used by apply_status_transition to save transition note text directly
*& from a char255 table (e.g., text read from go_edit_trans_note popup).
*& The existing save_long_text reads from go_edit_desc/dev_note/tstr_note
*& which may not exist when the popup is active.
*&
*& Parameters:
*&   pv_text_id — Text ID (Z001/Z002/Z003)
*&   pt_text    — Text content as table of char255
*&=====================================================================*
FORM save_long_text_direct USING pv_text_id TYPE thead-tdid
                                 pt_text    TYPE gty_t_char255.
  CHECK gv_current_bug_id IS NOT INITIAL.
  CHECK pt_text IS NOT INITIAL.

  DATA: lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline.

  LOOP AT pt_text INTO DATA(lv_line).
    CLEAR ls_line.
    ls_line-tdformat = '*'.
    ls_line-tdline   = lv_line.
    APPEND ls_line TO lt_lines.
  ENDLOOP.

  " Explicit type cast CHAR 10 → CHAR 70 (tdobname)
  DATA: lv_tdname TYPE tdobname.
  lv_tdname = gv_current_bug_id.

  DATA: ls_header TYPE thead.
  ls_header-tdobject = 'ZBUG'.
  ls_header-tdname   = lv_tdname.
  ls_header-tdid     = pv_text_id.
  ls_header-tdspras  = sy-langu.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = ls_header
      savemode_direct = 'X'
    TABLES
      lines           = lt_lines
    EXCEPTIONS
      OTHERS          = 4.
  IF sy-subrc <> 0.
    DATA: lv_save_msg TYPE string.
    lv_save_msg = |Long text { pv_text_id } save failed (RC={ sy-subrc }). Check text object ZBUG in SE75.|.
    MESSAGE lv_save_msg TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.
ENDFORM.

*&=====================================================================*
*& GENERIC SMW0 TEMPLATE DOWNLOAD + AUTO-OPEN
*&
*& Downloads a binary template from SMW0 (MIME Repository) to local PC
*& and auto-opens it in the default application (e.g., Excel).
*&
*& 2nd parameter pv_default_name — if provided, overrides the display
*& name from WWWDATA as the default download filename.
*& This allows custom filenames like 'Bug_report.xlsx' regardless of
*& what the SMW0 object's text field contains.
*&
*& SMW0 Object IDs:
*&   ZTEMPLATE_PROJECT — Project upload template
*&   ZBT_TMPL_01      — Bug report template (Bug_report.xlsx)
*&   ZBT_TMPL_02      — Fix report template (fix_report.xlsx)
*&   ZBT_TMPL_03      — Confirm report template (confirm_report.xlsx)
*&=====================================================================*
FORM download_smw0_template USING pv_objid        TYPE wwwdatatab-objid
                                  pv_default_name TYPE string.
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

  " 2. Get file metadata — use pv_default_name if provided, else fall back to WWWDATA text
  IF pv_default_name IS NOT INITIAL.
    lv_filename = pv_default_name.
  ELSE.
    lv_filename = ls_wdata-text.
    IF lv_filename IS INITIAL.
      lv_filename = pv_objid.
    ENDIF.
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

  " 6. Auto-open the downloaded file in default app
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

*&=====================================================================*
*& TEMPLATE DOWNLOAD WRAPPERS
*&=====================================================================*

*&=== DOWNLOAD PROJECT TEMPLATE ===*
*& Wrapper: downloads ZTEMPLATE_PROJECT from SMW0
*& Called from PAI fcode DN_TMPL on Screen 0400
FORM download_project_template.
  PERFORM download_smw0_template USING 'ZTEMPLATE_PROJECT' 'Project_template.xlsx'.
ENDFORM.

*&=== DOWNLOAD BUG REPORT TEMPLATE ===*
*& Wrapper: downloads ZBT_TMPL_01 from SMW0 as 'Bug_report.xlsx'
*& Called from PAI fcode DN_TC on Screen 0200
FORM download_bug_report_template.
  PERFORM download_smw0_template USING 'ZBT_TMPL_01' 'Bug_report.xlsx'.
ENDFORM.

*&=== DOWNLOAD FIX REPORT TEMPLATE ===*
*& Wrapper: downloads ZBT_TMPL_02 from SMW0 as 'fix_report.xlsx'
*& Called from PAI fcode DN_PROOF on Screen 0200
FORM download_fix_report_template.
  PERFORM download_smw0_template USING 'ZBT_TMPL_02' 'fix_report.xlsx'.
ENDFORM.

*&=== DOWNLOAD CONFIRM REPORT TEMPLATE ===*
*& Wrapper: downloads ZBT_TMPL_03 from SMW0 as 'confirm_report.xlsx'
*& Called from PAI fcode DN_CONF on Screen 0200
FORM dl_confirm_report_tmpl.
  PERFORM download_smw0_template USING 'ZBT_TMPL_03' 'confirm_report.xlsx'.
ENDFORM.
