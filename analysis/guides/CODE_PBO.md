*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PBO — Presentation Logic (Display)
*&---------------------------------------------------------------------*

*&--- GLOBAL ---*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Hub'.
ENDMODULE.

MODULE init_user_role OUTPUT.
  gv_uname = sy-uname.
  SELECT SINGLE role FROM zbug_users INTO @gv_role
    WHERE user_id = @gv_uname AND is_del <> 'X'.
  IF sy-subrc <> 0.
    MESSAGE 'User not found or authorized in system' TYPE 'E' DISPLAY LIKE 'I'.
    LEAVE PROGRAM.
  ENDIF.
ENDMODULE.

*&--- SCREEN 0200: BUG LIST ---*
MODULE status_0200 OUTPUT.
  DATA: lt_excl_0200 TYPE TABLE OF sy-ucomm.
  " Role-based button hiding
  IF gv_role = 'D'.
    APPEND 'CREATE' TO lt_excl_0200.
    APPEND 'DELETE' TO lt_excl_0200.
  ENDIF.
  IF gv_role = 'T'.
    APPEND 'DELETE' TO lt_excl_0200.
  ENDIF.
  SET PF-STATUS 'STATUS_0200' EXCLUDING lt_excl_0200.
  SET TITLEBAR 'TITLE_BUGLIST' WITH 'Bug List'.
ENDMODULE.

MODULE init_bug_list OUTPUT.
  PERFORM select_bug_data.
  IF go_alv_bug IS INITIAL.
    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
    CREATE OBJECT go_alv_bug EXPORTING i_parent = go_cont_bug.
    PERFORM build_bug_fieldcat.
    DATA: ls_layo TYPE lvc_s_layo.
    ls_layo-zebra = 'X'. ls_layo-cwidth_opt = 'X'.
    go_alv_bug->set_table_for_first_display(
      EXPORTING is_layout = ls_layo
      CHANGING it_outtab = gt_bugs it_fieldcatalog = gt_fcat_bug ).
    " Register Event Handler (hotspot click)
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_bug.
  ELSE.
    go_alv_bug->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&--- SCREEN 0300: BUG DETAIL ---*
MODULE status_0300 OUTPUT.
  DATA: lt_excl_0300 TYPE TABLE OF sy-ucomm.
  IF gv_mode = gc_mode_display. APPEND 'SAVE' TO lt_excl_0300. ENDIF.
  IF gv_role = 'D'. APPEND 'UP_REP' TO lt_excl_0300. ENDIF. " Hide Upload Report if Dev
  IF gv_role = 'T'. APPEND 'UP_FIX' TO lt_excl_0300. ENDIF. " Hide Upload Fix if Tester
  SET PF-STATUS 'STATUS_0300' EXCLUDING lt_excl_0300.
  SET TITLEBAR 'TITLE_BUGDETAIL' WITH gs_bug_detail-bug_id.
ENDMODULE.

MODULE load_bug_detail OUTPUT.
  " 1. LUÔN gán subscreen mặc định TRƯỚC - tránh DYNPRO_NOT_FOUND khi Create
  IF gv_active_subscreen IS INITIAL.
    gv_active_subscreen = '0310'.
  ENDIF.

  " 2. Chỉ SELECT dữ liệu nếu đang Change/Display
  IF gv_mode <> gc_mode_create AND gv_current_bug_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
      WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
  ENDIF.

  " 3. Create mode: xóa trắng vùng nhớ để nhập mới
  IF gv_mode = gc_mode_create.
    CLEAR gs_bug_detail.
  ENDIF.
ENDMODULE.

MODULE modify_screen_0300 OUTPUT.
  " Dynamic field property control (Readonly if Display only or Closed)
  LOOP AT SCREEN.
    IF gv_mode = gc_mode_display OR gs_bug_detail-status = '7'.
      IF screen-group1 = 'EDT'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDMODULE.

*&--- SCREEN 0400: PROJECT LIST ---*
MODULE status_0400 OUTPUT.
  DATA: lt_excl_0400 TYPE TABLE OF sy-ucomm.
  " Only Manager can CRUD projects
  IF gv_role <> 'M'.
    APPEND 'CREA_PRJ' TO lt_excl_0400.
    APPEND 'CHNG_PRJ' TO lt_excl_0400.
    APPEND 'DEL_PRJ'  TO lt_excl_0400.
    APPEND 'UPLOAD'   TO lt_excl_0400.
    APPEND 'DN_TMPL'  TO lt_excl_0400.
  ENDIF.
  SET PF-STATUS 'STATUS_0400' EXCLUDING lt_excl_0400.
  SET TITLEBAR 'TITLE_PROJLIST' WITH 'Project List'.
ENDMODULE.

MODULE init_project_list OUTPUT.
  PERFORM select_project_data.
  IF go_alv_project IS INITIAL.
    CREATE OBJECT go_cont_project EXPORTING container_name = 'CC_PROJECT_LIST'.
    CREATE OBJECT go_alv_project EXPORTING i_parent = go_cont_project.
    PERFORM build_pro_fieldcat.
    go_alv_project->set_table_for_first_display(
      CHANGING it_outtab = gt_projects it_fieldcatalog = gt_fcat_project ).
    " Register Event Handler (hotspot click)
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_project.
  ELSE.
    go_alv_project->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&--- SCREEN 0500: PROJECT DETAIL ---*
MODULE status_0500 OUTPUT.
  DATA: lt_excl_0500 TYPE TABLE OF sy-ucomm.
  IF gv_role <> 'M'.
    APPEND 'SAVE' TO lt_excl_0500.
    APPEND 'ADD_USER' TO lt_excl_0500.
    APPEND 'REMO_USR' TO lt_excl_0500.
  ENDIF.
  IF gv_mode = gc_mode_display. APPEND 'SAVE' TO lt_excl_0500. ENDIF.
  SET PF-STATUS 'STATUS_0500' EXCLUDING lt_excl_0500.
  SET TITLEBAR 'TITLE_PRJDET' WITH 'Project Detail'.
ENDMODULE.

MODULE init_project_detail OUTPUT.
  " Load project header data when Change/Display mode
  IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_project INTO @gs_project
      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
      WHERE project_id = @gv_current_project_id.
  ENDIF.
  IF gv_mode = gc_mode_create.
    CLEAR: gs_project, gt_user_project.
  ENDIF.
ENDMODULE.
