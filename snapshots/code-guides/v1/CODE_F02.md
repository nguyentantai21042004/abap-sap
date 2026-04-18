*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F02 — Helpers: F4, Long Text, Popup
*&---------------------------------------------------------------------*

*&=== F4: PROJECT ID ===*
FORM f4_project_id USING pv_fn TYPE dynfnam.
  " Hiển thị danh sách projects để chọn
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
  " Hiển thị danh sách users để chọn
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
    lr_editor->set_text_as_r3table( table = lt_text ).
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

  lr_editor->get_text_as_r3table( IMPORTING table = lt_text ).

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
