*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PAI — User Action Logic (v4.0 → v4.1 BUGFIX)
*&---------------------------------------------------------------------*
*& v4.0 changes (over v3.0):
*&  - user_command_0300: added DL_EVD (delete evidence), SENDMAIL handlers
*&  - user_command_0300: added unsaved changes check before BACK/CANC
*&  - user_command_0500: added unsaved changes check before BACK/CANC
*&  - user_command_0200: added DN_TC, DN_CONF, DN_PROOF (template downloads)
*&
*& v4.1 BUGFIX changes:
*&  - Added 8 POV modules for Screen 0310 F4 help (Bug #5)
*&  - Added 2 POV modules for Screen 0500: project_status, project_manager (Bug #1)
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

*&=====================================================================*
*& BUG LIST SCREEN 0200
*&=====================================================================*
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
      " Button is hidden in My Bugs mode via PBO, but double-check
      IF gv_bug_filter_mode = 'M'.
        MESSAGE 'Cannot create bug without project context. Go to a project first.' TYPE 'W'.
        RETURN.
      ENDIF.
      IF gv_role = 'D'.
        MESSAGE 'Developers cannot create bugs.' TYPE 'W'.
        RETURN.
      ENDIF.
      CLEAR: gv_current_bug_id, gs_bug_detail.
      gv_mode             = gc_mode_create.
      gv_active_subscreen = '0310'.
      gv_active_tab       = 'TAB_INFO'.      " v3.0: sync tab highlight
      CLEAR gv_detail_loaded.                 " v3.0: force fresh load
      " gv_current_project_id already set from project context
      CALL SCREEN 0300.
    WHEN 'CHANGE'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_change.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.    " v3.0
        CLEAR gv_detail_loaded.               " v3.0
        CALL SCREEN 0300.
      ENDIF.
    WHEN 'DISPLAY'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_display.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.    " v3.0
        CLEAR gv_detail_loaded.               " v3.0
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
    " v4.0: Template download buttons
    WHEN 'DN_TC'.
      PERFORM download_testcase_template.
    WHEN 'DN_CONF'.
      PERFORM download_confirm_template.
    WHEN 'DN_PROOF'.
      PERFORM download_bugproof_template.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& BUG DETAIL SCREEN 0300
*&=====================================================================*
MODULE user_command_0300 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " v4.0: Check unsaved changes before leaving
      IF gv_mode <> gc_mode_display.
        DATA: lv_continue TYPE abap_bool.
        PERFORM check_unsaved_bug CHANGING lv_continue.
        IF lv_continue = abap_false.
          RETURN.  " User cancelled — stay on screen
        ENDIF.
      ENDIF.
      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
      LEAVE TO SCREEN 0200.
    WHEN 'EXIT'.
      PERFORM cleanup_detail_editors.      " v3.0: free editors before leaving
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
    WHEN 'UP_REP'.
      PERFORM upload_report_file.
    WHEN 'UP_FIX'.
      PERFORM upload_fix_file.
    " v4.0: Delete evidence
    WHEN 'DL_EVD'.
      PERFORM delete_evidence.
    " v4.0: Send email notification
    WHEN 'SENDMAIL'.
      PERFORM send_mail_notification.
    " ---- Tab switching (v3.0: sync gv_active_tab, no PERFORM load calls) ----
    WHEN 'TAB_INFO'.
      gv_active_subscreen = '0310'.
      gv_active_tab       = 'TAB_INFO'.
    WHEN 'TAB_DESC'.
      gv_active_subscreen = '0320'.
      gv_active_tab       = 'TAB_DESC'.
    WHEN 'TAB_DEVNOTE'.
      gv_active_subscreen = '0330'.
      gv_active_tab       = 'TAB_DEVNOTE'.
    WHEN 'TAB_TSTR_NOTE'.
      gv_active_subscreen = '0340'.
      gv_active_tab       = 'TAB_TSTR_NOTE'.
    WHEN 'TAB_EVIDENCE'.
      gv_active_subscreen = '0350'.
      gv_active_tab       = 'TAB_EVIDENCE'.
    WHEN 'TAB_HISTORY'.
      gv_active_subscreen = '0360'.
      gv_active_tab       = 'TAB_HISTORY'.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& PROJECT LIST SCREEN 0400 (INITIAL SCREEN)
*&=====================================================================*
MODULE user_command_0400 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " This is the initial screen — Back = exit program
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'MY_BUGS'.
      " My Bugs — show cross-project bugs filtered by role
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
      CLEAR gv_prj_detail_loaded.            " v3.0: force fresh load
      CALL SCREEN 0500.
    WHEN 'CHNG_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_change.
        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
        CALL SCREEN 0500.
      ENDIF.
    WHEN 'DISP_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_display.
        CLEAR gv_prj_detail_loaded.          " v3.0: force fresh load
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

*&=====================================================================*
*& PROJECT DETAIL SCREEN 0500
*&=====================================================================*
MODULE user_command_0500 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " v4.0: Check unsaved changes before leaving
      IF gv_mode <> gc_mode_display.
        DATA: lv_prj_continue TYPE abap_bool.
        PERFORM check_unsaved_prj CHANGING lv_prj_continue.
        IF lv_prj_continue = abap_false.
          RETURN.  " User cancelled — stay on screen
        ENDIF.
      ENDIF.
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

*&=====================================================================*
*& v4.0: POV MODULES — F4 Calendar Popup (Screen 0500)
*& Called from PROCESS ON VALUE-REQUEST in Screen 0500 flow logic.
*& These modules delegate to FORM f4_date in CODE_F02.md.
*&=====================================================================*
MODULE f4_prj_startdate INPUT.
  PERFORM f4_date USING 'PRJ_START_DATE'.
ENDMODULE.

MODULE f4_prj_enddate INPUT.
  PERFORM f4_date USING 'PRJ_END_DATE'.
ENDMODULE.

*&=====================================================================*
*& v4.1 BUGFIX #1: POV MODULES — Screen 0500 (Project Detail)
*& F4 help for PROJECT_STATUS and PROJECT_MANAGER fields
*&=====================================================================*
MODULE f4_prj_status INPUT.
  PERFORM f4_project_status USING 'GS_PROJECT-PROJECT_STATUS'.
ENDMODULE.

MODULE f4_prj_manager INPUT.
  PERFORM f4_user_id USING 'GS_PROJECT-PROJECT_MANAGER'.
ENDMODULE.

*&=====================================================================*
*& v4.1 BUGFIX #5: POV MODULES — Screen 0310 (Bug Info)
*& F4 help for STATUS, PRIORITY, SEVERITY, BUG_TYPE, PROJECT_ID,
*& TESTER_ID, DEV_ID, VERIFY_TESTER_ID fields
*& Called from PROCESS ON VALUE-REQUEST in Screen 0310 flow logic.
*&=====================================================================*
MODULE f4_bug_status INPUT.
  PERFORM f4_status USING 'GS_BUG_DETAIL-STATUS'.
ENDMODULE.

MODULE f4_bug_priority INPUT.
  PERFORM f4_priority USING 'GS_BUG_DETAIL-PRIORITY'.
ENDMODULE.

MODULE f4_bug_severity INPUT.
  PERFORM f4_severity USING 'GS_BUG_DETAIL-SEVERITY'.
ENDMODULE.

MODULE f4_bug_type INPUT.
  PERFORM f4_bug_type USING 'GS_BUG_DETAIL-BUG_TYPE'.
ENDMODULE.

MODULE f4_bug_project INPUT.
  PERFORM f4_project_id USING 'GS_BUG_DETAIL-PROJECT_ID'.
ENDMODULE.

MODULE f4_bug_tester INPUT.
  PERFORM f4_user_id USING 'GS_BUG_DETAIL-TESTER_ID'.
ENDMODULE.

MODULE f4_bug_dev INPUT.
  PERFORM f4_user_id USING 'GS_BUG_DETAIL-DEV_ID'.
ENDMODULE.

MODULE f4_bug_verify INPUT.
  PERFORM f4_user_id USING 'GS_BUG_DETAIL-VERIFY_TESTER_ID'.
ENDMODULE.
