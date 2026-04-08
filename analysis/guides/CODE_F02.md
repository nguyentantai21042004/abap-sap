*&---------------------------------------------------------------------*
*& Include Z_BUG_WS_F02 — Helpers & F4 Search Help
*&---------------------------------------------------------------------*

*&--- F4 FOR PROJECT ID ---*
FORM f4_project_id USING pv_fn TYPE dynfnam.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF zbug_project.

  SELECT project_id, project_name FROM zbug_project
    INTO CORRESPONDING FIELDS OF TABLE @lt_val
    WHERE is_del <> 'X'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'PROJECT_ID'
      dynpprog         = sy-repid
      dynpnr           = sy-dynnr
      dynprofield      = pv_fn
      value_org        = 'S'
    TABLES
      value_tab        = lt_val
      return_tab       = lt_ret
    EXCEPTIONS
      OTHERS           = 1.
ENDFORM.

*&--- F4 FOR USER ID ---*
FORM f4_user_id USING pv_fn TYPE dynfnam.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF zbug_users.

  SELECT user_id, user_name, role FROM zbug_users
    INTO CORRESPONDING FIELDS OF TABLE @lt_val
    WHERE is_del <> 'X'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'USER_ID'
      dynpprog         = sy-repid
      dynpnr           = sy-dynnr
      dynprofield      = pv_fn
      value_org        = 'S'
    TABLES
      value_tab        = lt_val
      return_tab       = lt_ret
    EXCEPTIONS
      OTHERS           = 1.
ENDFORM.
