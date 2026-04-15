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
        IMPORTING e_ucomm,
      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING e_row e_column es_row_no.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_hotspot_click.

    " ===== BUG_ID hotspot — open Bug Detail =====
    IF e_column_id-fieldname = 'BUG_ID'.
      " Search Results screen (0220) reads from gt_search_results
      IF sy-dynnr = '0220'.
        READ TABLE gt_search_results INTO DATA(ls_search) INDEX e_row_id-index.
        IF sy-subrc = 0.
          gv_current_bug_id   = ls_search-bug_id.
          gv_mode             = gc_mode_display.
          gv_active_subscreen = '0310'.
          gv_active_tab       = 'TAB_INFO'.
          CLEAR gv_detail_loaded.
          CALL SCREEN 0300.
        ENDIF.
      ELSE.
        " Standard Bug List (Screen 0200)
        READ TABLE gt_bugs INTO DATA(ls_bug) INDEX e_row_id-index.
        IF sy-subrc = 0.
          gv_current_bug_id   = ls_bug-bug_id.
          gv_mode             = gc_mode_display.
          gv_active_subscreen = '0310'.
          gv_active_tab       = 'TAB_INFO'.
          CLEAR gv_detail_loaded.
          CALL SCREEN 0300.
        ENDIF.
      ENDIF.
    ENDIF.

    " ===== PROJECT_ID hotspot — context depends on which screen =====
    IF e_column_id-fieldname = 'PROJECT_ID'.
      IF sy-dynnr = '0400'.
        " From Project List → open Bug List with project filter
        READ TABLE gt_projects INTO DATA(ls_prj) INDEX e_row_id-index.
        IF sy-subrc = 0.
          gv_current_project_id = ls_prj-project_id.
          gv_bug_filter_mode    = 'P'.  " Project mode — show ALL bugs of this project
          CALL SCREEN 0200.
        ENDIF.
      ELSE.
        " From Bug List (0200/0220) → open Project Detail (display mode)
        READ TABLE gt_bugs INTO DATA(ls_bug2) INDEX e_row_id-index.
        IF sy-subrc = 0 AND ls_bug2-project_id IS NOT INITIAL.
          gv_current_project_id = ls_bug2-project_id.
          gv_mode               = gc_mode_display.
          CLEAR gv_prj_detail_loaded.
          CALL SCREEN 0500.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD handle_toolbar.
  ENDMETHOD.

  METHOD handle_user_command.
  ENDMETHOD.

  " Double-click on Evidence ALV → download selected file
  METHOD handle_double_click.
    DATA: ls_evidence TYPE ty_evidence_alv.
    READ TABLE gt_evidence INTO ls_evidence INDEX es_row_no-row_id.
    IF sy-subrc = 0.
      PERFORM download_evidence_file USING ls_evidence-evd_id.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&--- BUG LIST FIELD CATALOG ---*
FORM build_bug_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_bug.

  DEFINE add_fcat.
    CLEAR ls_fcat.
    ls_fcat-tabname   = 'GT_BUGS'.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_bug.
  END-OF-DEFINITION.

  add_fcat 'BUG_ID'           'Bug ID'          12.
  add_fcat 'TITLE'            'Title'           40.
  add_fcat 'PROJECT_ID'       'Project'         15.
  add_fcat 'STATUS_TEXT'      'Status'          15.
  add_fcat 'PRIORITY_TEXT'    'Priority'        10.
  add_fcat 'SEVERITY_TEXT'    'Severity'        15.
  add_fcat 'BUG_TYPE_TEXT'    'Type'            18.
  add_fcat 'SAP_MODULE'       'Module'          12.
  add_fcat 'TESTER_ID'        'Tester'          12.
  add_fcat 'VERIFY_TESTER_ID' 'Verify Tester'   12.
  add_fcat 'DEV_ID'           'Developer'       12.
  add_fcat 'CREATED_AT'       'Created'         10.

  " Hotspot on BUG_ID
  READ TABLE gt_fcat_bug ASSIGNING FIELD-SYMBOL(<fc>)
    WITH KEY fieldname = 'BUG_ID'.
  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.

  " Hotspot on PROJECT_ID (click → Project Detail from Bug List)
  READ TABLE gt_fcat_bug ASSIGNING <fc>
    WITH KEY fieldname = 'PROJECT_ID'.
  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.

  " Hide raw code columns (display _TEXT instead)
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
  ls_fcat-fieldname = 'STATUS'.   ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
  ls_fcat-fieldname = 'PRIORITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
  ls_fcat-fieldname = 'SEVERITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_BUGS'.
  ls_fcat-fieldname = 'BUG_TYPE'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_bug.
ENDFORM.

*&--- SEARCH RESULTS FIELD CATALOG ---*
*& Same columns as build_bug_fieldcat but tabname GT_SEARCH_RESULTS
FORM build_search_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_search.

  DEFINE add_sfcat.
    CLEAR ls_fcat.
    ls_fcat-tabname   = 'GT_SEARCH_RESULTS'.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_search.
  END-OF-DEFINITION.

  add_sfcat 'BUG_ID'           'Bug ID'          12.
  add_sfcat 'TITLE'            'Title'           40.
  add_sfcat 'PROJECT_ID'       'Project'         15.
  add_sfcat 'STATUS_TEXT'      'Status'          15.
  add_sfcat 'PRIORITY_TEXT'    'Priority'        10.
  add_sfcat 'SEVERITY_TEXT'    'Severity'        15.
  add_sfcat 'BUG_TYPE_TEXT'    'Type'            18.
  add_sfcat 'SAP_MODULE'       'Module'          12.
  add_sfcat 'TESTER_ID'        'Tester'          12.
  add_sfcat 'VERIFY_TESTER_ID' 'Verify Tester'   12.
  add_sfcat 'DEV_ID'           'Developer'       12.
  add_sfcat 'CREATED_AT'       'Created'         10.

  " Hotspot on BUG_ID (click → Bug Detail from search results)
  READ TABLE gt_fcat_search ASSIGNING FIELD-SYMBOL(<fc>)
    WITH KEY fieldname = 'BUG_ID'.
  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.

  " Hide raw code columns
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
  ls_fcat-fieldname = 'STATUS'.   ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
  ls_fcat-fieldname = 'PRIORITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
  ls_fcat-fieldname = 'SEVERITY'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_SEARCH_RESULTS'.
  ls_fcat-fieldname = 'BUG_TYPE'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_search.
ENDFORM.

*&--- PROJECT LIST FIELD CATALOG ---*
FORM build_pro_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_project.

  DEFINE add_fcat_p.
    CLEAR ls_fcat.
    ls_fcat-tabname   = 'GT_PROJECTS'.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_project.
  END-OF-DEFINITION.

  add_fcat_p 'PROJECT_ID'      'Project ID'     20.
  add_fcat_p 'PROJECT_NAME'    'Project Name'   40.
  add_fcat_p 'STATUS_TEXT'     'Status'         12.
  add_fcat_p 'START_DATE'      'Start Date'     10.
  add_fcat_p 'END_DATE'        'End Date'       10.
  add_fcat_p 'PROJECT_MANAGER' 'Manager'        12.
  add_fcat_p 'NOTE'            'Note'           30.

  " Hotspot on PROJECT_ID — click → Bug List (project filter)
  READ TABLE gt_fcat_project ASSIGNING FIELD-SYMBOL(<fc>)
    WITH KEY fieldname = 'PROJECT_ID'.
  IF sy-subrc = 0. <fc>-hotspot = 'X'. ENDIF.

  " Hide raw status code
  CLEAR ls_fcat. ls_fcat-tabname = 'GT_PROJECTS'.
  ls_fcat-fieldname = 'PROJECT_STATUS'. ls_fcat-no_out = 'X'. APPEND ls_fcat TO gt_fcat_project.
ENDFORM.

*&--- HISTORY FIELD CATALOG ---*
FORM build_history_fieldcat CHANGING pt_fcat TYPE lvc_t_fcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR pt_fcat.

  DEFINE add_hfcat.
    CLEAR ls_fcat.
    ls_fcat-tabname   = 'GT_HISTORY'.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO pt_fcat.
  END-OF-DEFINITION.

  add_hfcat 'CHANGED_AT'   'Date'        10.
  add_hfcat 'CHANGED_TIME' 'Time'         8.
  add_hfcat 'CHANGED_BY'   'Changed By'  12.
  add_hfcat 'ACTION_TEXT'  'Action'      15.
  add_hfcat 'OLD_VALUE'    'Old Value'   30.
  add_hfcat 'NEW_VALUE'    'New Value'   30.
  add_hfcat 'REASON'       'Reason'      40.
ENDFORM.

*&--- EVIDENCE FIELD CATALOG ---*
FORM build_evidence_fieldcat.
  DATA: ls_fcat TYPE lvc_s_fcat.
  CLEAR gt_fcat_evidence.

  DEFINE add_efcat.
    CLEAR ls_fcat.
    ls_fcat-tabname   = 'GT_EVIDENCE'.
    ls_fcat-fieldname = &1.
    ls_fcat-coltext   = &2.
    ls_fcat-outputlen = &3.
    APPEND ls_fcat TO gt_fcat_evidence.
  END-OF-DEFINITION.

  add_efcat 'EVD_ID'    'ID'         10.
  add_efcat 'FILE_NAME' 'File Name'  50.
  add_efcat 'MIME_TYPE' 'Type'       25.
  add_efcat 'FILE_SIZE' 'Size (B)'   12.
  add_efcat 'ERNAM'     'Uploaded By' 12.
  add_efcat 'ERDAT'     'Date'       10.
ENDFORM.