*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PBO — Presentation Logic (Display)
*&---------------------------------------------------------------------*

*&--- HUB SCREEN 0100 (DEPRECATED — kept for safety, no navigation leads here) ---*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_MAIN' WITH 'Bug Tracking Hub'.
ENDMODULE.

*&--- INIT USER ROLE (runs on initial screen 0400, loaded once) ---*
MODULE init_user_role OUTPUT.
  " Chỉ load role 1 lần khi khởi động
  CHECK gv_role IS INITIAL.
  gv_uname = sy-uname.
  SELECT SINGLE role FROM zbug_users INTO @gv_role
    WHERE user_id = @gv_uname AND is_del <> 'X'.
  IF sy-subrc <> 0.
    MESSAGE 'User not registered in Bug Tracking system.' TYPE 'E' DISPLAY LIKE 'I'.
    LEAVE PROGRAM.
  ENDIF.
ENDMODULE.

*&--- SCREEN 0200: BUG LIST (dual mode: Project / My Bugs) ---*
MODULE status_0200 OUTPUT.
  CLEAR gm_excl.

  " Developer cannot create/delete bugs
  IF gv_role = 'D'.
    APPEND 'CREATE' TO gm_excl.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.
  " Tester cannot delete
  IF gv_role = 'T'.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.

  " My Bugs mode: hide CREATE (no project context to assign bug to)
  IF gv_bug_filter_mode = 'M'.
    APPEND 'CREATE' TO gm_excl.
    APPEND 'DELETE' TO gm_excl.
  ENDIF.

  SET PF-STATUS 'STATUS_0200' EXCLUDING gm_excl.

  " Dynamic title based on filter mode
  DATA: lv_title TYPE string.
  IF gv_bug_filter_mode = 'P' AND gv_current_project_id IS NOT INITIAL.
    " Project mode: show project name in title
    DATA: lv_prj_name TYPE zde_prj_name.
    SELECT SINGLE project_name FROM zbug_project INTO @lv_prj_name
      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
    IF sy-subrc = 0.
      lv_title = |Bugs — { lv_prj_name }|.
    ELSE.
      lv_title = |Bugs — { gv_current_project_id }|.
    ENDIF.
  ELSE.
    " My Bugs mode
    lv_title = |My Bugs — { gv_uname }|.
  ENDIF.
  SET TITLEBAR 'TITLE_BUGLIST' WITH lv_title.
ENDMODULE.

MODULE init_bug_list OUTPUT.
  PERFORM select_bug_data.
  IF go_alv_bug IS INITIAL.
    " Khởi tạo ALV lần đầu
    CREATE OBJECT go_cont_bug EXPORTING container_name = 'CC_BUG_LIST'.
    CREATE OBJECT go_alv_bug  EXPORTING i_parent = go_cont_bug.
    PERFORM build_bug_fieldcat.
    CLEAR gm_layo_bug.
    gm_layo_bug-zebra      = 'X'.
    gm_layo_bug-cwidth_opt = 'X'.
    gm_layo_bug-sel_mode   = 'D'.  " Single-row selection
    gm_layo_bug-ctab_fname = 'T_COLOR'.
    go_alv_bug->set_table_for_first_display(
      EXPORTING is_layout      = gm_layo_bug
      CHANGING  it_outtab      = gt_bugs
                it_fieldcatalog = gt_fcat_bug ).
    " Register event handler
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_bug.
  ELSE.
    go_alv_bug->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&--- SCREEN 0300: BUG DETAIL (Tab Strip) ---*
MODULE status_0300 OUTPUT.
  CLEAR gm_excl.
  " Display mode: ẩn SAVE
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE' TO gm_excl.
  ENDIF.
  " Tester không upload fix
  IF gv_role = 'T'.
    APPEND 'UP_FIX' TO gm_excl.
  ENDIF.
  " Developer không upload report
  IF gv_role = 'D'.
    APPEND 'UP_REP' TO gm_excl.
  ENDIF.
  " Create mode: ẩn status change (chưa có bug_id)
  IF gv_mode = gc_mode_create.
    APPEND 'STATUS_CHG' TO gm_excl.
    APPEND 'UP_FILE'    TO gm_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0300' EXCLUDING gm_excl.

  " Title shows mode (Create/Change/Display)
  DATA(lv_mode_text) = SWITCH string( gv_mode
    WHEN gc_mode_create  THEN 'Create Bug'
    WHEN gc_mode_change  THEN |Change Bug: { gs_bug_detail-bug_id }|
    WHEN gc_mode_display THEN |Display Bug: { gs_bug_detail-bug_id }| ).
  SET TITLEBAR 'TITLE_BUGDETAIL' WITH lv_mode_text.
ENDMODULE.

MODULE load_bug_detail OUTPUT.
  " 1. Đảm bảo subscreen luôn có giá trị hợp lệ
  IF gv_active_subscreen IS INITIAL OR gv_active_subscreen = '0000'.
    gv_active_subscreen = '0310'.
  ENDIF.

  " 2. Change/Display: load dữ liệu từ DB
  IF gv_mode <> gc_mode_create AND gv_current_bug_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_tracker INTO @gs_bug_detail
      WHERE bug_id = @gv_current_bug_id AND is_del <> 'X'.
    IF sy-subrc <> 0.
      MESSAGE |Bug { gv_current_bug_id } not found| TYPE 'W'.
    ENDIF.
  ENDIF.

  " 3. Create mode: reset work area
  IF gv_mode = gc_mode_create.
    CLEAR gs_bug_detail.
    " Pre-fill PROJECT_ID from project context (locked on screen)
    IF gv_current_project_id IS NOT INITIAL.
      gs_bug_detail-project_id = gv_current_project_id.
    ENDIF.
    gs_bug_detail-tester_id = gv_uname.  " Default tester = current user
    gs_bug_detail-priority  = 'M'.       " Default priority = Medium
  ENDIF.

  " 4. Populate display text variables for Screen 0310
  gv_status_disp = SWITCH #( gs_bug_detail-status
    WHEN gc_st_new        THEN 'New'
    WHEN gc_st_assigned   THEN 'Assigned'
    WHEN gc_st_inprogress THEN 'In Progress'
    WHEN gc_st_pending    THEN 'Pending'
    WHEN gc_st_fixed      THEN 'Fixed'
    WHEN gc_st_resolved   THEN 'Resolved'
    WHEN gc_st_closed     THEN 'Closed'
    WHEN gc_st_waiting    THEN 'Waiting'
    WHEN gc_st_rejected   THEN 'Rejected'
    ELSE gs_bug_detail-status ).

  gv_priority_disp = SWITCH #( gs_bug_detail-priority
    WHEN 'H' THEN 'High'
    WHEN 'M' THEN 'Medium'
    WHEN 'L' THEN 'Low'
    ELSE gs_bug_detail-priority ).

  gv_severity_disp = SWITCH #( gs_bug_detail-severity
    WHEN '1' THEN 'Dump/Critical'
    WHEN '2' THEN 'Very High'
    WHEN '3' THEN 'High'
    WHEN '4' THEN 'Normal'
    WHEN '5' THEN 'Minor'
    ELSE gs_bug_detail-severity ).

  gv_bug_type_disp = SWITCH #( gs_bug_detail-bug_type
    WHEN '1' THEN 'Functional'
    WHEN '2' THEN 'Performance'
    WHEN '3' THEN 'UI/UX'
    WHEN '4' THEN 'Integration'
    WHEN '5' THEN 'Security'
    ELSE gs_bug_detail-bug_type ).
ENDMODULE.

MODULE modify_screen_0300 OUTPUT.
  LOOP AT SCREEN.
    " Readonly mode: disable tất cả fields có group EDT
    IF screen-group1 = 'EDT'.
      IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " BUG_ID: display-only after creation (group BID)
    IF screen-group1 = 'BID'.
      IF gv_mode <> gc_mode_create.
        screen-input = 0.  " Lock BUG_ID after creation
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " PROJECT_ID: locked when creating from project context (group PRJ)
    IF screen-group1 = 'PRJ'.
      IF gv_mode = gc_mode_create AND gv_current_project_id IS NOT INITIAL.
        screen-input = 0.  " Pre-filled + locked
      ENDIF.
      IF gv_mode = gc_mode_display.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    " Role-based field restrictions
    IF screen-group1 = 'TST' AND gv_role = 'D'.
      " Dev không sửa Tester fields
      screen-input = 0. MODIFY SCREEN.
    ENDIF.
    IF screen-group1 = 'DEV' AND gv_role = 'T'.
      " Tester không sửa Dev fields
      screen-input = 0. MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.

*&--- SUBSCREEN 0310: DESCRIPTION MINI EDITOR ---*
MODULE init_desc_mini OUTPUT.
  " Create mini text editor (3-4 lines) for quick description on Bug Info tab
  IF go_desc_mini_cont IS INITIAL.
    CREATE OBJECT go_desc_mini_cont EXPORTING container_name = 'CC_DESC_MINI'.
    CREATE OBJECT go_desc_mini_edit EXPORTING parent = go_desc_mini_cont.
    go_desc_mini_edit->set_toolbar_mode( cl_gui_textedit=>false ).
    go_desc_mini_edit->set_statusbar_mode( cl_gui_textedit=>false ).
  ENDIF.

  " Load DESC_TEXT content into mini editor
  IF gs_bug_detail-desc_text IS NOT INITIAL.
    DATA: lt_mini_text TYPE TABLE OF char255.
    APPEND CONV char255( gs_bug_detail-desc_text ) TO lt_mini_text.
    go_desc_mini_edit->set_text_as_r3table( table = lt_mini_text ).
  ELSE.
    DATA: lt_empty TYPE TABLE OF char255.
    go_desc_mini_edit->set_text_as_r3table( table = lt_empty ).
  ENDIF.

  " Disable editing in Display mode or Closed status
  IF gv_mode = gc_mode_display OR gs_bug_detail-status = gc_st_closed.
    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>true ).
  ELSE.
    go_desc_mini_edit->set_readonly_mode( cl_gui_textedit=>false ).
  ENDIF.
ENDMODULE.

*&--- SCREEN 0400: PROJECT LIST (NEW INITIAL SCREEN) ---*
MODULE status_0400 OUTPUT.
  CLEAR gm_excl.
  " Chỉ Manager được tạo/sửa/xóa Project
  IF gv_role <> 'M'.
    APPEND 'CREA_PRJ' TO gm_excl.
    APPEND 'CHNG_PRJ' TO gm_excl.
    APPEND 'DEL_PRJ'  TO gm_excl.
    APPEND 'UPLOAD'   TO gm_excl.
    APPEND 'DN_TMPL'  TO gm_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0400' EXCLUDING gm_excl.
  SET TITLEBAR 'TITLE_PROJLIST' WITH 'Project List'.
ENDMODULE.

MODULE init_project_list OUTPUT.
  PERFORM select_project_data.
  IF go_alv_project IS INITIAL.
    CREATE OBJECT go_cont_project EXPORTING container_name = 'CC_PROJECT_LIST'.
    CREATE OBJECT go_alv_project  EXPORTING i_parent = go_cont_project.
    PERFORM build_pro_fieldcat.
    CLEAR gm_layo_prj.
    gm_layo_prj-zebra      = 'X'.
    gm_layo_prj-cwidth_opt = 'X'.
    gm_layo_prj-sel_mode   = 'D'.
    go_alv_project->set_table_for_first_display(
      EXPORTING is_layout      = gm_layo_prj
      CHANGING  it_outtab      = gt_projects
                it_fieldcatalog = gt_fcat_project ).
    IF go_event_handler IS INITIAL.
      CREATE OBJECT go_event_handler.
    ENDIF.
    SET HANDLER go_event_handler->handle_hotspot_click FOR go_alv_project.
  ELSE.
    go_alv_project->refresh_table_display( ).
  ENDIF.
ENDMODULE.

*&--- SCREEN 0500: PROJECT DETAIL + TABLE CONTROL ---*
MODULE status_0500 OUTPUT.
  CLEAR gm_excl.
  IF gv_role <> 'M'.
    APPEND 'SAVE'     TO gm_excl.
    APPEND 'ADD_USER' TO gm_excl.
    APPEND 'REMO_USR' TO gm_excl.
  ENDIF.
  IF gv_mode = gc_mode_display.
    APPEND 'SAVE'     TO gm_excl.
    APPEND 'ADD_USER' TO gm_excl.
    APPEND 'REMO_USR' TO gm_excl.
  ENDIF.
  SET PF-STATUS 'STATUS_0500' EXCLUDING gm_excl.

  " Title shows mode (Create/Change/Display)
  DATA(lv_prj_title) = SWITCH string( gv_mode
    WHEN gc_mode_create  THEN 'Create Project'
    WHEN gc_mode_change  THEN |Change Project: { gs_project-project_name }|
    WHEN gc_mode_display THEN |Display Project: { gs_project-project_name }| ).
  IF lv_prj_title IS INITIAL.
    lv_prj_title = 'Project Detail'.
  ENDIF.
  SET TITLEBAR 'TITLE_PRJDET' WITH lv_prj_title.
ENDMODULE.

MODULE init_project_detail OUTPUT.
  IF gv_mode <> gc_mode_create AND gv_current_project_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_project INTO @gs_project
      WHERE project_id = @gv_current_project_id AND is_del <> 'X'.
    SELECT * FROM zbug_user_projec INTO TABLE @gt_user_project
      WHERE project_id = @gv_current_project_id.
  ENDIF.
  IF gv_mode = gc_mode_create.
    CLEAR: gs_project, gt_user_project.
    gs_project-project_manager = gv_uname.  " Default manager = current user
    gs_project-project_status  = '1'.       " Opening
  ENDIF.

  " Populate display text for Project Status on Screen 0500
  gv_prj_status_disp = SWITCH #( gs_project-project_status
    WHEN '1' THEN 'Opening'
    WHEN '2' THEN 'In Process'
    WHEN '3' THEN 'Done'
    WHEN '4' THEN 'Cancelled'
    ELSE gs_project-project_status ).
ENDMODULE.

MODULE modify_screen_0500 OUTPUT.
  LOOP AT SCREEN.
    IF screen-group1 = 'EDT'.
      IF gv_mode = gc_mode_display OR gv_role <> 'M'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
ENDMODULE.
