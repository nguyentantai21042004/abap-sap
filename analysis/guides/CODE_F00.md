*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F00 — ALV Setup & Event Classes
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id,
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_hotspot_click.
    " Bug List: click Bug ID → open Bug Detail (Display mode)
    IF e_column_id-fieldname = 'BUG_ID'.
      READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
      IF sy-subrc = 0.
        gv_current_bug_id  = ls_bug-bug_id.
        gv_mode            = gc_mode_display.
        gv_active_subscreen = '0310'.
        CALL SCREEN 0300.
      ENDIF.
    ENDIF.

    " Project List: click Project ID → open Project Detail (Display mode)
    IF e_column_id-fieldname = 'PROJECT_ID'.
      READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
      IF sy-subrc = 0.
        gv_current_project_id = ls_prj-project_id.
        gv_mode               = gc_mode_display.
        CALL SCREEN 0500.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD handle_toolbar.
  ENDMETHOD.

  METHOD handle_user_command.
  ENDMETHOD.
ENDCLASS.

*&--- BUG LIST FIELD CATALOG ---*
FORM build_bug_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_bug.

  DEFINE add_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1. ls_fcat-coltext = &2. ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_bug.
  END-OF-DEFINITION.

  add_fcat 'BUG_ID'        'Bug ID'     12.
  add_fcat 'TITLE'         'Title'      40.
  add_fcat 'PROJECT_ID'    'Project'    15.
  add_fcat 'STATUS_TEXT'   'Status'     15.
  add_fcat 'PRIORITY_TEXT' 'Priority'   10.
  add_fcat 'CREATED_AT'    'Created'    10.

  " Set Hotspot (Clickable)
  READ TABLE gt_fcat_bug ASSIGNING FIELD-SYMBOL(<fc>)
    WITH KEY fieldname = 'BUG_ID'.
  IF sy-subrc = 0.
    <fc>-hotspot = 'X'.
  ENDIF.
ENDFORM.

*&--- PROJECT LIST FIELD CATALOG ---*
FORM build_pro_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_project.

  DEFINE add_fcat_p.
    CLEAR ls_fcat.
    ls_fcat-fieldname = &1. ls_fcat-coltext = &2. ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_project.
  END-OF-DEFINITION.

  add_fcat_p 'PROJECT_ID'      'Project ID'     15.
  add_fcat_p 'PROJECT_NAME'    'Project Name'   40.
  add_fcat_p 'STATUS_TEXT'     'Status'         15.
  add_fcat_p 'START_DATE'      'Start Date'     10.
  add_fcat_p 'END_DATE'        'End Date'       10.
ENDFORM.
