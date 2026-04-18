*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_PAI — User Action Logic (PAI modules for all screens)
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
*& SCREEN 0410 — PROJECT SEARCH (initial screen)
*&=====================================================================*
MODULE user_command_0410 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'EXECUTE' OR 'ONLI'.   " F8 = Execute
      PERFORM search_projects.
      CALL SCREEN 0400.

    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& BUG LIST SCREEN 0200
*&=====================================================================*
MODULE user_command_0200 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " LEAVE TO SCREEN 0 → returns to caller (Screen 0400 via CALL SCREEN)
      " Destroy Bug ALV to force rebuild on re-entry
      IF go_alv_bug IS NOT INITIAL.
        go_alv_bug->free( ).
        FREE go_alv_bug.
        go_cont_bug->free( ).
        FREE go_cont_bug.
        CLEAR: go_alv_bug, go_cont_bug.
      ENDIF.
      " Force project list reload on return so role-filter is always applied
      gv_prj_list_dirty = abap_true.
      LEAVE TO SCREEN 0.
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
      gv_active_tab       = 'TAB_INFO'.
      CLEAR gv_detail_loaded.
      " gv_current_project_id already set from project context
      CALL SCREEN 0300.
    WHEN 'CHANGE'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_change.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.
        CLEAR gv_detail_loaded.
        CALL SCREEN 0300.
      ENDIF.
    WHEN 'DISPLAY'.
      PERFORM get_selected_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_display.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.
        CLEAR gv_detail_loaded.
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

    " Bug Search Engine
    WHEN 'SEARCH'.
      " Clear previous search fields + results
      CLEAR: s_bug_id, s_title, s_status, s_prio, s_mod, s_reporter, s_dev.
      CLEAR gv_search_executed.
      " Open search popup (modal dialog)
      CALL SCREEN 0210 STARTING AT 5 3 ENDING AT 75 18.
      " After popup closes, check if search was executed
      " (Cannot CALL SCREEN 0220 from inside modal dialog — use flag pattern)
      IF gv_search_executed = abap_true.
        CLEAR gv_search_executed.
        CALL SCREEN 0220.
      ENDIF.

    " Template download buttons
    WHEN 'DN_TC'.
      PERFORM download_bug_report_template.
    WHEN 'DN_CONF'.
      PERFORM dl_confirm_report_tmpl.
    WHEN 'DN_PROOF'.
      PERFORM download_fix_report_template.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& BUG DETAIL SCREEN 0300
*&=====================================================================*
MODULE user_command_0300 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " Check unsaved changes before leaving
      IF gv_mode <> gc_mode_display.
        DATA: lv_continue TYPE abap_bool.
        PERFORM check_unsaved_bug CHANGING lv_continue.
        IF lv_continue = abap_false.
          RETURN.  " User cancelled — stay on screen
        ENDIF.
      ENDIF.
      PERFORM cleanup_detail_editors.
      " LEAVE TO SCREEN 0 → returns to caller (Screen 0200)
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      PERFORM cleanup_detail_editors.
      LEAVE PROGRAM.
    WHEN 'SAVE'.
      IF gv_mode = gc_mode_display.
        MESSAGE 'Switch to Change mode before saving.' TYPE 'W'.
        RETURN.
      ENDIF.
      PERFORM save_desc_mini_to_workarea.
      PERFORM save_bug_detail.

    " STATUS_CHG opens popup Screen 0370 (replaces old change_bug_status)
    WHEN 'STATUS_CHG'.
      IF gv_mode = gc_mode_create.
        MESSAGE 'Save the bug first before changing status.' TYPE 'W'.
        RETURN.
      ENDIF.
      IF gv_mode = gc_mode_display.
        MESSAGE 'Switch to Change mode before changing status.' TYPE 'W'.
        RETURN.
      ENDIF.
      " Clear previous transition state
      CLEAR: gv_trans_new_status, gv_trans_confirmed.
      " Open Status Transition Popup
      CALL SCREEN 0370 STARTING AT 5 3 ENDING AT 85 22.
      " After popup returns, check if transition was confirmed
      IF gv_trans_confirmed = abap_true.
        " Refresh bug detail (status may have changed + auto-assign may have fired)
        gv_detail_loaded = abap_false.
        CLEAR gv_trans_confirmed.
      ENDIF.

    WHEN 'UP_FILE'.
      PERFORM upload_evidence_file.
    WHEN 'UP_REP'.
      PERFORM upload_report_file.
    WHEN 'UP_FIX'.
      PERFORM upload_fix_file.
    " Delete evidence
    WHEN 'DL_EVD'.
      PERFORM delete_evidence.
    " Download evidence (selected row via button)
    WHEN 'DW_EVD'.
      PERFORM download_evidence_selected.
    " Send email notification
    WHEN 'SENDMAIL'.
      PERFORM send_mail_notification.
    " ---- Tab switching ----
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
*& SCREEN 0370 — STATUS TRANSITION POPUP
*&=====================================================================*
MODULE user_command_0370 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'CONFIRM'.
      " Validate transition (matrix + role + required fields)
      PERFORM validate_status_transition.
      IF gv_trans_confirmed = abap_true.
        " Apply transition (update DB + log history + auto-assign)
        PERFORM apply_status_transition.
        " Free container before leaving popup
        IF go_cont_trans_note IS NOT INITIAL.
          go_cont_trans_note->free( ).
          CLEAR: go_cont_trans_note, go_edit_trans_note.
        ENDIF.
        LEAVE TO SCREEN 0.  " Close popup → return to Screen 0300
      ENDIF.

    WHEN 'CANCEL' OR 'BACK'.
      CLEAR gv_trans_confirmed.
      IF go_cont_trans_note IS NOT INITIAL.
        go_cont_trans_note->free( ).
        CLEAR: go_cont_trans_note, go_edit_trans_note.
      ENDIF.
      LEAVE TO SCREEN 0.

    WHEN 'UP_TRANS'.
      " Upload evidence from within popup
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Bug not saved yet. Cannot upload evidence.' TYPE 'S' DISPLAY LIKE 'W'.
      ELSE.
        PERFORM upload_evidence_file.
      ENDIF.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0210 — BUG SEARCH INPUT (Modal Dialog popup)
*&=====================================================================*
MODULE user_command_0210 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'EXECUTE' OR 'ONLI'.    " F8 = Execute
      PERFORM execute_bug_search.
      " Set flag — caller (user_command_0200) will navigate to Screen 0220
      " (Cannot CALL SCREEN 0220 from inside modal dialog)
      IF gt_search_results IS NOT INITIAL.
        gv_search_executed = abap_true.
      ENDIF.
      LEAVE TO SCREEN 0.  " Close popup

    WHEN 'CANCEL' OR 'BACK'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& SCREEN 0220 — BUG SEARCH RESULTS (Full screen ALV)
*&=====================================================================*
MODULE user_command_0220 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      " Free search results ALV to force rebuild on next search
      IF go_cont_search IS NOT INITIAL.
        go_cont_search->free( ).
        CLEAR: go_cont_search, go_search_alv.
      ENDIF.
      LEAVE TO SCREEN 0.   " Return to Screen 0200

    WHEN 'CHANGE'.
      PERFORM get_selected_search_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_change.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.
        CLEAR gv_detail_loaded.
        CALL SCREEN 0300.
      ENDIF.

    WHEN 'DISPLAY'.
      PERFORM get_selected_search_bug CHANGING gv_current_bug_id.
      IF gv_current_bug_id IS INITIAL.
        MESSAGE 'Please select a bug first.' TYPE 'W'.
      ELSE.
        gv_mode             = gc_mode_display.
        gv_active_subscreen = '0310'.
        gv_active_tab       = 'TAB_INFO'.
        CLEAR gv_detail_loaded.
        CALL SCREEN 0300.
      ENDIF.
  ENDCASE.
ENDMODULE.

*&=====================================================================*
*& PROJECT LIST SCREEN 0400
*& No longer initial screen — called from 0410 via CALL SCREEN
*&=====================================================================*
MODULE user_command_0400 INPUT.
  gv_save_ok = gv_ok_code. CLEAR gv_ok_code.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANC'.
      " LEAVE TO SCREEN 0 → returns to caller (Screen 0410)
      " Destroy Project ALV to force rebuild on re-entry (filtered data may differ)
      IF go_alv_project IS NOT INITIAL.
        go_alv_project->free( ).
        FREE go_alv_project.
        go_cont_project->free( ).
        FREE go_cont_project.
        CLEAR: go_alv_project, go_cont_project.
      ENDIF.
      LEAVE TO SCREEN 0.
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
      CLEAR gv_prj_detail_loaded.
      CALL SCREEN 0500.
    WHEN 'CHNG_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_change.
        CLEAR gv_prj_detail_loaded.
        CALL SCREEN 0500.
      ENDIF.
    WHEN 'DISP_PRJ'.
      PERFORM get_selected_project CHANGING gv_current_project_id.
      IF gv_current_project_id IS INITIAL.
        MESSAGE 'Please select a project first.' TYPE 'W'.
      ELSE.
        gv_mode = gc_mode_display.
        CLEAR gv_prj_detail_loaded.
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
      " Reload with search filters preserved (Bug 2 fix)
      PERFORM search_projects.
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
      " Check unsaved changes before leaving
      IF gv_mode <> gc_mode_display.
        DATA: lv_prj_continue TYPE abap_bool.
        PERFORM check_unsaved_prj CHANGING lv_prj_continue.
        IF lv_prj_continue = abap_false.
          RETURN.  " User cancelled — stay on screen
        ENDIF.
      ENDIF.
      " Free project editors before leaving
      PERFORM cleanup_prj_editors.
      " LEAVE TO SCREEN 0 → returns to caller (Screen 0400)
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.
      PERFORM cleanup_prj_editors.
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
  " Track that user actually interacted with the table control row
  gv_tc_user_selected = abap_true.
ENDMODULE.

*&=====================================================================*
*& POV MODULES — F4 Help (Screen 0500 — Project Detail)
*&=====================================================================*
MODULE f4_prj_startdate INPUT.
  PERFORM f4_date USING 'PRJ_START_DATE'.
ENDMODULE.

MODULE f4_prj_enddate INPUT.
  PERFORM f4_date USING 'PRJ_END_DATE'.
ENDMODULE.

MODULE f4_prj_status INPUT.
  PERFORM f4_project_status USING 'GS_PROJECT-PROJECT_STATUS'.
ENDMODULE.

MODULE f4_prj_manager INPUT.
  PERFORM f4_user_id USING 'GS_PROJECT-PROJECT_MANAGER'.
ENDMODULE.

*&=====================================================================*
*& POV MODULES — F4 Help (Screen 0310 — Bug Info)
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

" SAP Module F4 (Screen 0310)
MODULE f4_bug_sapmodule INPUT.
  PERFORM f4_sap_module USING 'GS_BUG_DETAIL-SAP_MODULE'.
ENDMODULE.

*&=====================================================================*
*& POV MODULES — F4 Help (Screen 0410 — Project Search)
*&=====================================================================*
MODULE f4_project_id INPUT.
  PERFORM f4_project_id_help USING 'S_PRJ_ID'.
ENDMODULE.

MODULE f4_manager INPUT.
  PERFORM f4_manager_help USING 'S_PRJ_MN'.
ENDMODULE.

MODULE f4_project_status INPUT.
  PERFORM f4_project_status_help USING 'S_PRJ_ST'.
ENDMODULE.

*&=====================================================================*
*& POV MODULES — F4 Help (Screen 0370 — Status Transition)
*&=====================================================================*

" F4 for New Status — shows only valid transitions based on current status + role
MODULE f4_trans_status_mod INPUT.
  PERFORM f4_trans_status.
ENDMODULE.

" F4 for Developer (assign)
MODULE f4_trans_developer INPUT.
  PERFORM f4_user_id USING 'GV_TRANS_DEV_ID'.
ENDMODULE.

" F4 for Final Tester (assign)
MODULE f4_trans_ftester INPUT.
  PERFORM f4_user_id USING 'GV_TRANS_FTESTER_ID'.
ENDMODULE.

*&=====================================================================*
*& POV MODULES — F4 Help (Screen 0210 — Bug Search)
*&=====================================================================*

" Status F4 for search — shows all 10 statuses
MODULE f4_bug_search_status INPUT.
  PERFORM f4_status USING 'S_STATUS'.
ENDMODULE.

" Priority F4 for search
MODULE f4_bug_search_priority INPUT.
  PERFORM f4_priority USING 'S_PRIO'.
ENDMODULE.

" SAP Module F4 for search
MODULE f4_bug_search_module INPUT.
  PERFORM f4_sap_module USING 'S_MOD'.
ENDMODULE.

" Reporter F4 for search (all users)
MODULE f4_bug_search_reporter INPUT.
  PERFORM f4_user_id USING 'S_REPORTER'.
ENDMODULE.

" Developer F4 for search (all users — filter by Dev role is optional)
MODULE f4_bug_search_developer INPUT.
  PERFORM f4_user_id USING 'S_DEV'.
ENDMODULE.
