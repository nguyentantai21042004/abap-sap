*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PAI — User Action Logic (Khớp SE41)
*&---------------------------------------------------------------------*

*&--- HUB SCREEN 0100 ---*
MODULE user_command_0100 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'. LEAVE PROGRAM.
    WHEN 'BUG_LIST'.  CALL SCREEN 0200.
    WHEN 'PROJ_LIST'. CALL SCREEN 0400. " Khớp với PROJ_LIST trong SE41
  ENDCASE.
ENDMODULE.

*&--- BUG LIST SCREEN 0200 ---*
MODULE user_command_0200 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'. LEAVE TO SCREEN 0100.
    WHEN 'CREATE'.
      CLEAR: gv_current_bug_id, gs_bug_detail.
      gv_mode = gc_mode_create.
      gv_active_subscreen = '0310'.
      CALL SCREEN 0300.
    WHEN 'CHANGE' OR 'DISPLAY'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first' TYPE 'W'.
      ELSE.
        gv_mode = COND #( WHEN gv_save_ok = 'CHANGE' THEN gc_mode_change
                          ELSE gc_mode_display ).
        gv_active_subscreen = '0310'.
        CALL SCREEN 0300.
      ENDIF.
    WHEN 'DELETE'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS NOT INITIAL.
        PERFORM delete_bug.
      ELSE.
        MESSAGE 'Please select a bug to delete' TYPE 'W'.
      ENDIF.
    WHEN 'REFRESH'. PERFORM select_bug_data.
  ENDCASE.
ENDMODULE.

*&--- BUG DETAIL SCREEN 0300 ---*
MODULE user_command_0300 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK'. LEAVE TO SCREEN 0200.
    WHEN 'SAVE'. PERFORM save_bug_detail.
    WHEN 'STATUS_CHG'. PERFORM change_bug_status.
    WHEN 'UP_FILE'. PERFORM upload_evidence_file.
    " Tab switching
    WHEN 'TAB_INFO'.     gv_active_subscreen = '0310'.
    WHEN 'TAB_DEVNOTE'.  gv_active_subscreen = '0320'.
    WHEN 'TAB_FUNCNOTE'. gv_active_subscreen = '0330'.
    WHEN 'TAB_ROOTCAUSE'.gv_active_subscreen = '0340'.
    WHEN 'TAB_EVIDENCE'. gv_active_subscreen = '0350'.
    WHEN 'TAB_HISTORY'.  gv_active_subscreen = '0360'.
                         PERFORM load_history_data.
  ENDCASE.
ENDMODULE.

*&--- PROJECT LIST SCREEN 0400 ---*
MODULE user_command_0400 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'. LEAVE TO SCREEN 0100.
    WHEN 'CREA_PRJ'.
      CLEAR: gv_current_project_id, gs_project.
      gv_mode = gc_mode_create.
      CALL SCREEN 0500.
    WHEN 'CHNG_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_change. CALL SCREEN 0500.
      ENDIF.
    WHEN 'DISP_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_display. CALL SCREEN 0500.
      ENDIF.
    WHEN 'DEL_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS NOT INITIAL.
        PERFORM delete_project.
      ELSE.
        MESSAGE 'Please select a project to delete' TYPE 'W'.
      ENDIF.
    WHEN 'REFRESH'. PERFORM select_project_data.
  ENDCASE.
ENDMODULE.


*&--- PROJECT DETAIL SCREEN 0500 ---*
MODULE user_command_0500 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'. LEAVE TO SCREEN 0400.
    WHEN 'SAVE'.       PERFORM save_project_detail.
    WHEN 'ADD_USER'.   PERFORM add_user_to_project.
    WHEN 'REMO_USR'.   PERFORM remove_user_from_project.
  ENDCASE.
ENDMODULE.

*&--- TABLE CONTROL TABLE SYNC ---*
MODULE tc_users_modify INPUT.
  MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
ENDMODULE.
