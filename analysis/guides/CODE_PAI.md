*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PAI — User Action Logic
*&---------------------------------------------------------------------*

*&--- HUB SCREEN 0100 (DEPRECATED — kept for safety) ---*
MODULE user_command_0100 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.
    WHEN 'BUG_LIST'.
      gv_bug_filter_mode = 'M'.  " Legacy: My Bugs mode
      CALL SCREEN 0200.
    WHEN 'PROJ_LIST'.
      CALL SCREEN 0400.
  ENDCASE.
ENDMODULE.

*&--- BUG LIST SCREEN 0200 ---*
MODULE user_command_0200 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " Always go back to Project List (initial screen)
      LEAVE TO SCREEN 0400.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'CREATE'.
      " Only available in Project mode (gv_bug_filter_mode = 'P')
      " Button is hidden in My Bugs mode via PBO, but double-check here
      IF gv_bug_filter_mode = 'M'.
        MESSAGE 'Cannot create bug without project context. Go to a project first.' TYPE 'W'.
        RETURN.
      ENDIF.
      IF gv_role = 'D'.
        MESSAGE 'Developers cannot create bugs.' TYPE 'W'.
        RETURN.
      ENDIF.
      CLEAR: gv_current_bug_id, gs_bug_detail.
      gv_mode = gc_mode_create.
      gv_active_subscreen = '0310'.
      " gv_current_project_id is already set from project context
      CALL SCREEN 0300.
    WHEN 'CHANGE'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_change.
        gv_active_subscreen = '0310'.
        CALL SCREEN 0300.
      ENDIF.
    WHEN 'DISPLAY'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_display.
        gv_active_subscreen = '0310'.
        CALL SCREEN 0300.
      ENDIF.
    WHEN 'DELETE'.
      IF gv_role = 'D'.
        MESSAGE 'Developers cannot delete bugs.' TYPE 'W'.
        RETURN.
      ENDIF.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS NOT INITIAL.
        PERFORM delete_bug.
      ELSE.
        MESSAGE 'Please select a bug to delete.' TYPE 'W'.
      ENDIF.
    WHEN 'REFRESH'.
      PERFORM select_bug_data.
      IF go_alv_bug IS NOT INITIAL.
        go_alv_bug->refresh_table_display( ).
      ENDIF.
  ENDCASE.
ENDMODULE.

*&--- BUG DETAIL SCREEN 0300 ---*
MODULE user_command_0300 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      LEAVE TO SCREEN 0200.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'SAVE'.
      IF gv_mode = gc_mode_display.
        MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
        RETURN.
      ENDIF.
      " Save description mini editor content to gs_bug_detail-desc_text
      PERFORM save_desc_mini_to_workarea.
      PERFORM save_bug_detail.
    WHEN 'STATUS_CHG'.
      IF gv_mode = gc_mode_create.
        MESSAGE 'Save the bug first before changing status.' TYPE 'W'.
        RETURN.
      ENDIF.
      PERFORM change_bug_status.
    WHEN 'UP_FILE'.
      PERFORM upload_evidence_file.
    " ---- Tab switching ----
    WHEN 'TAB_INFO'.
      gv_active_subscreen = '0310'.
    WHEN 'TAB_DESC'.
      gv_active_subscreen = '0320'.
      PERFORM load_long_text USING 'Z001'.
    WHEN 'TAB_DEVNOTE'.
      gv_active_subscreen = '0330'.
      PERFORM load_long_text USING 'Z002'.
    WHEN 'TAB_TSTR_NOTE'.
      gv_active_subscreen = '0340'.
      PERFORM load_long_text USING 'Z003'.
    WHEN 'TAB_EVIDENCE'.
      gv_active_subscreen = '0350'.
    WHEN 'TAB_HISTORY'.
      gv_active_subscreen = '0360'.
      PERFORM load_history_data.
  ENDCASE.
ENDMODULE.

*&--- PROJECT LIST SCREEN 0400 (INITIAL SCREEN) ---*
MODULE user_command_0400 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " This is the initial screen — Back = exit program
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'MY_BUGS'.
      " NEW: My Bugs — show cross-project bugs filtered by role
      CLEAR gv_current_project_id.
      gv_bug_filter_mode = 'M'.
      " Destroy existing Bug ALV to force rebuild with new data
      IF go_alv_bug IS NOT INITIAL.
        go_alv_bug->free( ).
        FREE go_alv_bug.
        go_cont_bug->free( ).
        FREE go_cont_bug.
        CLEAR: go_alv_bug, go_cont_bug.
      ENDIF.
      CALL SCREEN 0200.
    WHEN 'CREA_PRJ'.
      IF gv_role <> 'M'.
        MESSAGE 'Only managers can create projects.' TYPE 'W'.
        RETURN.
      ENDIF.
      CLEAR: gv_current_project_id, gs_project, gt_user_project.
      gv_mode = gc_mode_create.
      CALL SCREEN 0500.
    WHEN 'CHNG_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_change.
        CALL SCREEN 0500.
      ENDIF.
    WHEN 'DISP_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_display.
        CALL SCREEN 0500.
      ENDIF.
    WHEN 'DEL_PRJ'.
      IF gv_role <> 'M'.
        MESSAGE 'Only managers can delete projects.' TYPE 'W'.
        RETURN.
      ENDIF.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS NOT INITIAL.
        PERFORM delete_project.
      ELSE.
        MESSAGE 'Please select a project to delete.' TYPE 'W'.
      ENDIF.
    WHEN 'REFRESH'.
      PERFORM select_project_data.
      IF go_alv_project IS NOT INITIAL.
        go_alv_project->refresh_table_display( ).
      ENDIF.
    WHEN 'DN_TMPL'.
      PERFORM download_project_template.
    WHEN 'UPLOAD'.
      PERFORM upload_project_excel.
  ENDCASE.
ENDMODULE.

*&--- PROJECT DETAIL SCREEN 0500 ---*
MODULE user_command_0500 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      LEAVE TO SCREEN 0400.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'SAVE'.
      IF gv_mode = gc_mode_display.
        MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
        RETURN.
      ENDIF.
      PERFORM save_project_detail.
    WHEN 'ADD_USER'.
      PERFORM add_user_to_project.
    WHEN 'REMO_USR'.
      PERFORM remove_user_from_project.
  ENDCASE.
ENDMODULE.

*&--- TABLE CONTROL SYNC (Screen 0500) ---*
MODULE tc_users_modify INPUT.
  MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
ENDMODULE.
