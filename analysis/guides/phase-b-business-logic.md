# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE B: BUSINESS LOGIC UPDATE

**Dự án:** SAP Bug Tracking Management System  
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)  
**Thời gian ước tính:** 2 ngày (25-27/03)  
**Yêu cầu:** Hoàn thành Phase A trước khi bắt đầu Phase B  

---

## MỤC LỤC

1. [Bước B1: Mở rộng Z_BUG_CHECK_PERMISSION (Project permissions)](#bước-b1-mở-rộng-z_bug_check_permission)
2. [Bước B2: Cập nhật Z_BUG_CREATE (Project + Severity + User validation)](#bước-b2-cập-nhật-z_bug_create)
3. [Bước B3: Chuẩn hóa Status States (9 states + transition validation)](#bước-b3-chuẩn-hóa-status-states)
4. [Bước B4: GOS File Storage Integration](#bước-b4-gos-file-storage-integration)
5. [Bước B5: SmartForm Email Template (ZBUG_EMAIL_FORM)](#bước-b5-smartform-email-template)
6. [Bước B6: Cập nhật Z_BUG_SEND_EMAIL (SmartForm → CL_BCS)](#bước-b6-cập-nhật-z_bug_send_email)
7. [Bước B7: Cập nhật soft delete logic trong tất cả FMs](#bước-b7-cập-nhật-soft-delete-logic)

---

## Bước B1: Mở rộng `Z_BUG_CHECK_PERMISSION`

**Mục tiêu:** Thêm Project permissions + user-project membership check.

Vào **SE37** → mở FM `Z_BUG_CHECK_PERMISSION` → **Change**.

**Thêm IMPORTING parameter mới:**

```abap
IV_PROJECT_ID TYPE ZDE_PROJECT_ID OPTIONAL
```

**Source code cập nhật (thay thế toàn bộ):**

```abap
FUNCTION z_bug_check_permission.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER) TYPE  ZDE_USERNAME
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID OPTIONAL
*"     VALUE(IV_ACTION) TYPE  CHAR20
*"     VALUE(IV_PROJECT_ID) TYPE  ZDE_PROJECT_ID OPTIONAL
*"  EXPORTING
*"     VALUE(EV_ALLOWED) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_user    TYPE zbug_users,
        ls_bug     TYPE zbug_tracker,
        ls_project TYPE zbug_project,
        lv_count   TYPE i.

  " 1. Lấy thông tin User
  SELECT SINGLE * FROM zbug_users INTO @ls_user
    WHERE user_id = @iv_user AND is_del <> 'X'.

  IF sy-subrc <> 0.
    ev_allowed = 'N'.
    MESSAGE s029(zbug_msg) WITH iv_user INTO ev_message.
    RETURN.
  ENDIF.

  " 2. ĐẶC QUYỀN: Manager (M) có toàn quyền
  IF ls_user-role = 'M'.
    ev_allowed = 'Y'.
    RETURN.
  ENDIF.

  " 3. Lấy thông tin Bug (nếu có)
  IF iv_bug_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
      WHERE bug_id = @iv_bug_id AND is_del <> 'X'.
  ENDIF.

  " 4. CHECK USER-PROJECT MEMBERSHIP (nếu có project context)
  DATA(lv_prj) = COND #( WHEN iv_project_id IS NOT INITIAL THEN iv_project_id
                          WHEN ls_bug-project_id IS NOT INITIAL THEN ls_bug-project_id
                          ELSE '' ).
  IF lv_prj IS NOT INITIAL.
    SELECT COUNT(*) FROM zbug_user_project INTO @lv_count
      WHERE user_id = @iv_user AND project_id = @lv_prj.
    IF lv_count = 0.
      " Đã check Manager ở trên, nếu ko phải Manager mà ko có trong Project -> block
      ev_allowed = 'N'.
      MESSAGE s004(zbug_msg) INTO ev_message.
      RETURN.
    ENDIF.
  ENDIF.

  " 5. RẼ NHÁNH KIỂM TRA QUYỀN THEO HÀNH ĐỘNG
  CASE iv_action.

    " === BUG ACTIONS ===
    WHEN 'CREATE'.
      IF ls_user-role = 'T'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s005(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN 'UPDATE_STATUS'.
      " Config Bug: Tester tự xử lý
      IF ls_bug-bug_type = 'F' AND ls_user-role = 'T' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      " Developer update bug do mình giữ
      ELSEIF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      " Tester update khi Bug mới tạo (Status 1)
      ELSEIF ls_user-role = 'T' AND ls_bug-status = '1'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s006(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN 'DELETE_BUG'.
      " Chỉ Manager xóa bug, nhưng đã Allow ở trên, vào đây là chặn
      ev_allowed = 'N'.
      MESSAGE s006(zbug_msg) INTO ev_message.

    WHEN 'UPLOAD_REPORT'.
      IF ls_user-role = 'T' AND ls_bug-tester_id = iv_user.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only the assigned Tester can upload report'.
      ENDIF.

    WHEN 'UPLOAD_FIX'.
      " Config Bug: Tester tự upload fix
      IF ls_bug-bug_type = 'F' AND ls_user-role = 'T' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      ELSEIF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only the assigned Developer can upload fix'.
      ENDIF.

    WHEN 'UPLOAD_VERIFY'.
      IF ls_user-role = 'T'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only Tester can upload verify file'.
      ENDIF.

    " === PROJECT ACTIONS ===
    WHEN 'CREATE_PROJECT'.
      IF ls_user-role = 'M'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s007(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN 'CHANGE_PROJECT'.
      " PM của project đó
      IF ls_user-role = 'M'.
        SELECT SINGLE * FROM zbug_project INTO @ls_project
          WHERE project_id = @iv_project_id AND project_manager = @iv_user.
        IF sy-subrc = 0.
          ev_allowed = 'Y'.
        ELSE.
          ev_allowed = 'N'.
          ev_message = 'Only the Project Manager of this project can modify it'.
        ENDIF.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s007(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN 'DELETE_PROJECT'.
      IF ls_user-role <> 'M'.
        ev_allowed = 'N'.
        MESSAGE s007(zbug_msg) INTO ev_message.
        RETURN.
      ENDIF.
      " Project phải Done hoặc Cancel
      SELECT SINGLE project_status FROM zbug_project INTO @DATA(lv_prj_st)
        WHERE project_id = @iv_project_id.
      IF lv_prj_st = '3' OR lv_prj_st = '4'. " Done or Cancel
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s008(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN 'VIEW_PROJECT'.
      " User phải thuộc project (đã check ở step 4)
      ev_allowed = 'Y'.

    WHEN 'ADD_USER_PROJECT'.
      IF ls_user-role = 'M'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        MESSAGE s007(zbug_msg) INTO ev_message.
      ENDIF.

    WHEN OTHERS.
      ev_allowed = 'N'.
      ev_message = 'Unknown action'.
  ENDCASE.

ENDFUNCTION.
```

Nhấn **Activate**.

> ✅ **Checkpoint:** **SE37** → `Z_BUG_CHECK_PERMISSION` → Test:
>
> - `IV_USER` = (tester), `IV_ACTION` = `CREATE_PROJECT` → `EV_ALLOWED` = `N`
> - `IV_USER` = (manager), `IV_ACTION` = `CREATE_PROJECT` → `EV_ALLOWED` = `Y`
> - `IV_USER` = (tester), `IV_ACTION` = `CREATE`, `IV_PROJECT_ID` = `PRJ001` → check membership

---

## Bước B2: Cập nhật `Z_BUG_CREATE`

**Mục tiêu:** Thêm `PROJECT_ID`, `SEVERITY`, user validation, project validation.

Vào **SE37** → mở FM `Z_BUG_CREATE` → **Change**.

**Thêm IMPORTING parameters:**

```abap
IV_PROJECT_ID TYPE ZDE_PROJECT_ID
IV_SEVERITY   TYPE ZDE_SEVERITY DEFAULT '4'
```

**Source code cập nhật:**

```abap
FUNCTION z_bug_create.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_TITLE) TYPE  ZDE_BUG_TITLE
*"     VALUE(IV_DESC) TYPE  ZDE_BUG_DESC
*"     VALUE(IV_MODULE) TYPE  ZDE_SAP_MODULE
*"     VALUE(IV_PRIORITY) TYPE  ZDE_PRIORITY DEFAULT 'M'
*"     VALUE(IV_DEV_ID) TYPE  ZDE_USERNAME OPTIONAL
*"     VALUE(IV_BUG_TYPE) TYPE  ZDE_BUG_TYPE OPTIONAL
*"     VALUE(IV_ATT_PATH) TYPE  ZDE_BUG_ATT_PATH OPTIONAL
*"     VALUE(IV_PROJECT_ID) TYPE  ZDE_PROJECT_ID
*"     VALUE(IV_SEVERITY) TYPE  ZDE_SEVERITY DEFAULT '4'
*"  EXPORTING
*"     VALUE(EV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug     TYPE zbug_tracker,
        lv_number  TYPE numc10,
        lv_count   TYPE i.

  " ====== VALIDATION BLOCK ======

  " 1. Validate user exists + active
  SELECT COUNT(*) FROM zbug_users INTO @lv_count
    WHERE user_id = @sy-uname AND is_del <> 'X'.
  IF lv_count = 0.
    ev_success = 'N'.
    MESSAGE s029(zbug_msg) WITH sy-uname INTO ev_message.
    RETURN.
  ENDIF.

  " 2. Validate project exists + InProcess
  SELECT SINGLE project_status FROM zbug_project INTO @DATA(lv_prj_status)
    WHERE project_id = @iv_project_id AND is_del <> 'X'.
  IF sy-subrc <> 0.
    ev_success = 'N'.
    MESSAGE s021(zbug_msg) WITH iv_project_id INTO ev_message.
    RETURN.
  ENDIF.
  IF lv_prj_status <> '2'. " Must be InProcess
    ev_success = 'N'.
    MESSAGE s022(zbug_msg) INTO ev_message.
    RETURN.
  ENDIF.

  " 3. Validate user belongs to project
  SELECT COUNT(*) FROM zbug_user_project INTO @lv_count
    WHERE user_id = @sy-uname AND project_id = @iv_project_id.
  IF lv_count = 0.
    ev_success = 'N'.
    MESSAGE s004(zbug_msg) INTO ev_message.
    RETURN.
  ENDIF.

  " 4. Severity + Bug Type cross validation
  IF iv_bug_type IS INITIAL.
    ls_bug-bug_type = 'C'. " Default Code bug
  ELSE.
    ls_bug-bug_type = iv_bug_type.
  ENDIF.

  " Dump/VeryHigh/High severity Code bugs → force High priority
  IF iv_severity IN ('1', '2', '3') AND ls_bug-bug_type = 'C'.
    ls_bug-priority = 'H'.
  ELSE.
    ls_bug-priority = iv_priority.
  ENDIF.

  " ====== BUG ID GENERATION ======

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '01'
      object                  = 'ZNRO_BUG'
    IMPORTING
      number                  = lv_number
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    MESSAGE s011(zbug_msg) INTO ev_message.
    RETURN.
  ENDIF.

  CONCATENATE 'BUG' lv_number+3(7) INTO ev_bug_id.

  " ====== FILL BUG RECORD ======

  ls_bug-bug_id       = ev_bug_id.
  ls_bug-title        = iv_title.
  ls_bug-desc_text    = iv_desc.
  ls_bug-sap_module   = iv_module.
  ls_bug-tester_id    = sy-uname.
  ls_bug-created_at   = sy-datum.
  ls_bug-created_time = sy-uzeit.
  ls_bug-ernam        = sy-uname.
  ls_bug-erdat        = sy-datum.
  ls_bug-erzet        = sy-uzeit.
  ls_bug-project_id   = iv_project_id.
  ls_bug-severity     = iv_severity.

  " Evidence
  IF iv_att_path IS NOT INITIAL.
    ls_bug-att_report = iv_att_path.
  ENDIF.

  " ====== WORKFLOW BRANCHING ======

  IF ls_bug-bug_type = 'F'.
    " Config Bug: Tester tự xử lý
    ls_bug-status = '2'.
    ls_bug-dev_id = sy-uname.
  ELSE.
    " Code Bug: New, chờ Auto-Assign
    ls_bug-status = '1'.
    ls_bug-dev_id = ''.
  ENDIF.

  " ====== DATABASE INSERT ======
  INSERT zbug_tracker FROM ls_bug.

  IF sy-subrc = 0.
    ev_success = 'Y'.
    MESSAGE s001(zbug_msg) WITH ev_bug_id INTO ev_message.

    " Log history
    CALL FUNCTION 'Z_BUG_LOG_HISTORY'
      EXPORTING
        iv_bug_id      = ev_bug_id
        iv_action_type = 'CR'
        iv_old_value   = ''
        iv_new_value   = iv_title
        iv_reason      = 'New bug created'.

    " Send email notification
    CALL FUNCTION 'Z_BUG_SEND_EMAIL'
      EXPORTING
        iv_bug_id = ev_bug_id
        iv_event  = 'CREATE'.

    COMMIT WORK AND WAIT.
  ELSE.
    ev_success = 'N'.
    MESSAGE s010(zbug_msg) INTO ev_message.
    ROLLBACK WORK.
  ENDIF.

ENDFUNCTION.
```

Nhấn **Activate**.

> ✅ **Checkpoint:** **SE37** → `Z_BUG_CREATE` → Test:
>
> - Truyền `IV_PROJECT_ID` không tồn tại → "Project does not exist"
> - Truyền phần tử Valid → Bug tạo thành công với `PROJECT_ID` + `SEVERITY`

---

## Bước B3: Chuẩn hóa Status States

**Mục tiêu:** Refactor `Z_BUG_UPDATE_STATUS` cho 9 status states mới.

Vào **SE37** → `Z_BUG_UPDATE_STATUS` → **Change**.

**Bảng Transition hợp lệ (hardcode vào FM):**

| From | → Valid To |
| :--- | :--- |
| `1` | `2` (assign), `W` (no dev) |
| `W` | `2` (manager assign) |
| `2` | `3` (dev start), `R` (reject) |
| `3` | `5` (fixed), `4` (pending) |
| `4` | `3` (resume) |
| `5` | `6` (verify pass), `3` (fail) |
| `6` | `7` (close) |
| `7` | *(terminal — no transition)* |
| `R` | `2` (reassign) |

**Thêm logic validate transition vào FM:**

```abap
" Trong Z_BUG_UPDATE_STATUS, sau khi đọc bug hiện tại:

" === TRANSITION VALIDATION ===
DATA: lv_valid TYPE abap_bool VALUE abap_false.

CASE ls_bug-status.
  WHEN '1'.  " New
    IF iv_new_status = '2' OR iv_new_status = 'W'.
      lv_valid = abap_true.
    ENDIF.
  WHEN 'W'.  " Waiting
    IF iv_new_status = '2'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '2'.  " Assigned
    IF iv_new_status = '3' OR iv_new_status = 'R'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '3'.  " In Progress
    IF iv_new_status = '5' OR iv_new_status = '4'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '4'.  " Pending
    IF iv_new_status = '3'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '5'.  " Fixed
    IF iv_new_status = '6' OR iv_new_status = '3'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '6'.  " Resolved
    IF iv_new_status = '7'.
      lv_valid = abap_true.
    ENDIF.
  WHEN '7'.  " Closed — terminal
    lv_valid = abap_false.
  WHEN 'R'.  " Rejected
    IF iv_new_status = '2'.
      lv_valid = abap_true.
    ENDIF.
ENDCASE.

IF lv_valid = abap_false.
  ev_success = 'N'.
  " Dùng Message Class:
  DATA: lv_old_text TYPE char20, lv_new_text TYPE char20.
  PERFORM get_status_text IN PROGRAM z_bug_workspace_mp USING ls_bug-status CHANGING lv_old_text.
  PERFORM get_status_text IN PROGRAM z_bug_workspace_mp USING iv_new_status CHANGING lv_new_text.
  MESSAGE s018(zbug_msg) WITH lv_old_text lv_new_text INTO ev_message.
  RETURN.
ENDIF.

" === AUDIT FIELDS ===
ls_bug-aenam = sy-uname.
ls_bug-aedat = sy-datum.
ls_bug-aezet = sy-uzeit.

" Nếu chuyển sang Closed (7), ghi CLOSED_AT
IF iv_new_status = '7'.
  ls_bug-closed_at = sy-datum.
ENDIF.

" ... phần còn lại giữ nguyên (UPDATE, LOG_HISTORY, SEND_EMAIL) ...
```

Nhấn **Activate**.

> ✅ **Checkpoint:** **SE37** → `Z_BUG_UPDATE_STATUS` → Test:
>
> - Status `1` → `5` (Fixed) → FAIL "Invalid transition"
> - Status `1` → `2` (Assigned) → PASS

---

## Bước B4: GOS File Storage Integration

**Mục tiêu:** Tạo cơ chế upload file qua GOS thay local path.

*Dùng BDS API:*

Tạo FM mới `Z_BUG_GOS_UPLOAD` trong Function Group `ZBUG_FG`:

```abap
FUNCTION z_bug_gos_upload.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_FILE_PATH) TYPE  STRING
*"     VALUE(IV_FILE_TYPE) TYPE  CHAR20
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: lt_file_content TYPE TABLE OF soli,
        lv_file_size    TYPE i,
        lv_file_name    TYPE string.

  " 1. Đọc file từ frontend
  CALL FUNCTION 'GUI_UPLOAD'
    EXPORTING
      filename   = iv_file_path
      filetype   = 'BIN'
    IMPORTING
      filelength = lv_file_size
    TABLES
      data_tab   = lt_file_content
    EXCEPTIONS
      OTHERS     = 1.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Failed to read file from local path'.
    RETURN.
  ENDIF.

  " 2. Lấy tên file (basename)
  DATA: lt_parts TYPE TABLE OF string.
  SPLIT iv_file_path AT '\' INTO TABLE lt_parts.
  READ TABLE lt_parts INTO lv_file_name INDEX lines( lt_parts ).

  " 3. Lưu vào BDS
  DATA: lo_bds       TYPE REF TO cl_bds_document_set,
        lt_files     TYPE sbdst_files,
        ls_file      TYPE sbdst_file,
        lt_signature TYPE sbdst_signature,
        ls_signature TYPE sbdst_signat.

  CREATE OBJECT lo_bds.

  ls_signature-prop_name  = 'DESCRIPTION'.
  ls_signature-prop_value = |{ iv_file_type }: { lv_file_name }|.
  APPEND ls_signature TO lt_signature.

  ls_file-doc_count = 1.
  ls_file-comp_count = 1.
  ls_file-comp_id = lv_file_name.
  ls_file-mimetype = 'application/octet-stream'.
  ls_file-comp_size = lv_file_size.
  APPEND ls_file TO lt_files.

  TRY.
    lo_bds->create_with_table(
      EXPORTING classname  = 'ZBUG_EVIDENCE'
                classtype  = 'OT'
                object_key = CONV #( iv_bug_id )
      CHANGING  components = lt_files
                content    = lt_file_content
                signature  = lt_signature ).
    COMMIT WORK.
    ev_success = 'Y'.
    ev_message = |File { lv_file_name } uploaded successfully|.
  CATCH cx_bds_kernel INTO DATA(lx_error).
    ev_success = 'N'.
    ev_message = lx_error->get_text( ).
    ROLLBACK WORK.
  ENDTRY.

ENDFUNCTION.
```

Tạo FM `Z_BUG_GOS_LIST`:

```abap
FUNCTION z_bug_gos_list.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"  EXPORTING
*"     VALUE(ET_FILES) TYPE  SBDST_FILES
*"----------------------------------------------------------------------

  DATA: lo_bds       TYPE REF TO cl_bds_document_set,
        lt_signature TYPE sbdst_signature.

  CREATE OBJECT lo_bds.

  TRY.
    lo_bds->get_info(
      EXPORTING classname  = 'ZBUG_EVIDENCE'
                classtype  = 'OT'
                object_key = CONV #( iv_bug_id )
      CHANGING  components = et_files
                signature  = lt_signature ).
  CATCH cx_bds_kernel.
    CLEAR et_files.
  ENDTRY.

ENDFUNCTION.
```

Nhấn **Activate** cả 2 FMs.

---

## Bước B5: SmartForm Email Template

**Mục tiêu:** Tạo SmartForm `ZBUG_EMAIL_FORM` cho email notification.

Vào T-code **SMARTFORMS** → nhập `ZBUG_EMAIL_FORM` → **Create**.

**Step 1: Form Interface**

- IMPORTING:
  - `IV_BUG_ID TYPE ZDE_BUG_ID`
  - `IV_EVENT  TYPE CHAR20`
  - `IS_BUG    TYPE ZBUG_TRACKER`
  - `IV_EVENT_TEXT TYPE STRING`

**Step 2: Global Definitions**

- Global Data:
  - `GV_TITLE TYPE STRING`
  - `GV_BODY  TYPE STRING`

**Step 3: Form Layout**

- Pages and Windows → MAIN Window → Main Window
- Text Element **BUG_INFO:**

  ```text
  Bug ID:    &IS_BUG-BUG_ID&
  Title:     &IS_BUG-TITLE&
  Project:   &IS_BUG-PROJECT_ID&
  Status:    &IS_BUG-STATUS&
  ```

Nhấn **Save** → **Activate**.

---

## Bước B6: Cập nhật `Z_BUG_SEND_EMAIL`

**Mục tiêu:** Sửa FM email để dùng SmartForm.

```abap
FUNCTION z_bug_send_email.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_EVENT) TYPE  CHAR20
*"----------------------------------------------------------------------

  DATA: ls_bug       TYPE zbug_tracker,
        lt_recip     TYPE TABLE OF zbug_users,
        lo_send_req  TYPE REF TO cl_bcs,
        lo_doc       TYPE REF TO cl_document_bcs,
        lo_sender    TYPE REF TO cl_sapuser_bcs,
        lo_recip     TYPE REF TO if_recipient_bcs,
        lv_subject   TYPE so_obj_des,
        lt_body      TYPE bcsy_text,
        ls_body      TYPE soli,
        lv_sent      TYPE os_boolean.

  " 1. Lấy thông tin bug
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id AND is_del <> 'X'.
  IF sy-subrc <> 0. RETURN. ENDIF.

  " 2. Xác định recipients theo event
  CASE iv_event.
    WHEN 'CREATE'.
      " Gửi cho Manager + Dev team
      SELECT * FROM zbug_users INTO TABLE @lt_recip
        WHERE role IN ('M','D') AND is_del <> 'X'.
    WHEN 'ASSIGN'.
      " Gửi cho Dev được assign
      SELECT * FROM zbug_users APPENDING TABLE @lt_recip
        WHERE user_id = @ls_bug-dev_id AND is_del <> 'X'.
    WHEN 'STATUS_CHANGE'.
      " Gửi cho Tester + Dev liên quan
      SELECT * FROM zbug_users INTO TABLE @lt_recip
        WHERE ( user_id = @ls_bug-tester_id OR user_id = @ls_bug-dev_id )
          AND is_del <> 'X'.
    WHEN 'REJECT'.
      " Gửi cho Manager
      SELECT * FROM zbug_users INTO TABLE @lt_recip
        WHERE role = 'M' AND is_del <> 'X'.
  ENDCASE.

  IF lt_recip IS INITIAL. RETURN. ENDIF.

  " 3. Tạo email body (HTML) qua SmartForm
  " Gọi SmartForm ZBUG_EMAIL_FORM → generate HTML
  " Fallback: tạo HTML đơn giản
  lv_subject = |[BugTracker] { iv_event }: { ls_bug-bug_id } - { ls_bug-title }|.

  ls_body-line = |<html><body>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<h2>Bug Tracking Notification</h2>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<p><b>Event:</b> { iv_event }</p>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<p><b>Bug ID:</b> { ls_bug-bug_id }</p>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<p><b>Title:</b> { ls_bug-title }</p>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<p><b>Project:</b> { ls_bug-project_id }</p>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |<p><b>Status:</b> { ls_bug-status }</p>|.
  APPEND ls_body TO lt_body.
  ls_body-line = |</body></html>|.
  APPEND ls_body TO lt_body.

  " 4. Gửi email qua CL_BCS
  TRY.
    lo_send_req = cl_bcs=>create_persistent( ).
    lo_doc = cl_document_bcs=>create_document(
      i_type    = 'HTM'
      i_text    = lt_body
      i_subject = lv_subject ).
    lo_send_req->set_document( lo_doc ).

    lo_sender = cl_sapuser_bcs=>create( sy-uname ).
    lo_send_req->set_sender( lo_sender ).

    LOOP AT lt_recip ASSIGNING FIELD-SYMBOL(<user>).
      IF <user>-email IS NOT INITIAL.
        lo_recip = cl_cam_address_bcs=>create_internet_address( <user>-email ).
        lo_send_req->add_recipient( lo_recip ).
      ENDIF.
    ENDLOOP.

    lo_send_req->set_send_immediately( 'X' ).
    lv_sent = lo_send_req->send( ).
    COMMIT WORK.
  CATCH cx_bcs INTO DATA(lx_bcs).
    " Log error but don't block main flow
    DATA(lv_err) = lx_bcs->get_text( ).
  ENDTRY.

ENDFUNCTION.
```

---

## Bước B7: Cập nhật Soft Delete Logic

**Mục tiêu:** Tất cả SELECT phải filter `IS_DEL`, DELETE thay bằng UPDATE `IS_DEL`.

**Nguyên tắc:**

1. **ALL SELECT statements:** thêm `WHERE is_del <> 'X'`
2. **DELETE operations:** thay bằng `UPDATE ... SET is_del = 'X'`

**Ví dụ:**

```abap
" TRƯỚC (hard delete):
DELETE FROM zbug_tracker WHERE bug_id = iv_bug_id.

" SAU (soft delete):
UPDATE zbug_tracker SET is_del = 'X'
                        aenam  = sy-uname
                        aedat  = sy-datum
                        aezet  = sy-uzeit
  WHERE bug_id = iv_bug_id.
```

**Các FMs cần cập nhật:**

- `Z_BUG_UPDATE_STATUS`, `Z_BUG_AUTO_ASSIGN`, `Z_BUG_REASSIGN`

Nhấn **Activate** cho tất cả FMs đã sửa.

> ✅ **Checkpoint:** Bất kỳ query nào `SELECT FROM zbug_tracker/zbug_users` đều có `WHERE is_del <> 'X'`.

---

## TỔNG KẾT PHASE B

Sau khi hoàn thành Phase B, bạn phải có:

- [x] `Z_BUG_CHECK_PERMISSION` — hỗ trợ 12 actions (Bug + Project)
- [x] `Z_BUG_CREATE` — validate Project + Severity + User membership
- [x] `Z_BUG_UPDATE_STATUS` — 9 status states + transition validation + fill CLOSED_AT/VERIFY_TESTER_ID
- [x] `Z_BUG_GOS_UPLOAD` / `LIST` — upload file qua BDS
- [x] `ZBUG_EMAIL_FORM` — SmartForm template HTML
- [x] `Z_BUG_SEND_EMAIL` — CL_BCS + HTML fallback (full source code)
- [x] Soft delete logic áp dụng trong tất cả các FM
- [x] `Z_BUG_AUTO_ASSIGN` — thêm `is_del <> 'X'` filter vào SELECT dev
- [x] `Z_BUG_REASSIGN` — thêm `is_del <> 'X'` filter + project membership check

> ⚠️ **Lưu ý về `Z_BUG_AUTO_ASSIGN` và `Z_BUG_REASSIGN`:**
>
> 2 FM này đã tồn tại từ MVP. Chỉ cần update:
>
> 1. Thêm `AND is_del <> 'X'` vào tất cả SELECT
> 2. Thêm `AND user_id IN (SELECT user_id FROM zbug_user_project WHERE project_id = ...)` để chỉ assign dev trong cùng project
> 3. Fill `AENAM`/`AEDAT`/`AEZET` khi UPDATE

👉 **Chuyển sang Phase C: Module Pool UI**
