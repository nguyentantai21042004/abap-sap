HƯỚNG DẪN TRIỂN KHAI CHO DEVELOPER (BẢN CẬP NHẬT MVP BIG UPDATE)
Dự án: SAP Bug Tracking Management System Ngày cập nhật: 21/03/2026 Phiên bản: 4.0 (MVP Big Update - Centralized Workspace & Config Bug Flow)
--------------------------------------------------------------------------------

MỤC LỤC
Phase 1: Cập nhật Database Layer (Chuẩn hóa Evidence & Config Bug)
Phase 2: Cập nhật Business Logic Layer (State Tree mới)
Phase 3: Presentation Layer - Xây dựng Centralized Workspace (ZBUG_HOME)
Phase 4: Cải tiến Trải nghiệm Người dùng (UX/UI Enhancements)
Phase 5: Testing & UAT Script (MVP)
--------------------------------------------------------------------------------

PHASE 1: CẬP NHẬT DATABASE LAYER
Tài khoản sử dụng: DEV-089 (Pass: @Anhtuoi123) Mục tiêu: Cập nhật bảng ZBUG_TRACKER để lưu trữ 3 file Evidence riêng biệt và hỗ trợ phân loại Bug (Code/Config).
Bước 1.1: Bổ sung Data Elements & Domains mới
Vào T-code SE11, tạo/cập nhật các Domain và Data Element sau:
Data Element
Domain
Type
Length
Mô tả (Short Text)
ZDE_BUG_TYPE
ZDOM_BUG_TYPE
CHAR
1
Loại Bug (C: Code, F: Config)
ZDE_BUG_ATT_PATH
ZDOM_ATT_PATH
CHAR
100
Đường dẫn lưu Evidence File
ZDE_REASONS
ZDOM_LONGTEXT
STRING
-

Nguyên nhân gốc rễ (Root Cause)
Nhấn Activate.
Bước 1.2: Cập nhật cấu trúc bảng ZBUG_TRACKER
Vào SE11 -> Bảng ZBUG_TRACKER -> Change.
Bổ sung các trường sau vào cấu trúc bảng:
Field Name
Data Element
Chức năng mới theo Business Requirement
BUG_TYPE
ZDE_BUG_TYPE
Phân loại Bug Code hay Config
REASONS
ZDE_REASONS
Lưu lý do đổi trạng thái / re-assign
ATT_REPORT
ZDE_BUG_ATT_PATH
Evidence 1 (Lúc Tester báo lỗi)
ATT_FIX
ZDE_BUG_ATT_PATH
Evidence 2 (Lúc Dev sửa xong)
ATT_VERIFY
ZDE_BUG_ATT_PATH
Evidence 3 (Lúc Final Tester đóng Bug)
Nhấn Save và Activate. Database Utility có thể yêu cầu Adjust Database (SE14) nếu bảng đã có dữ liệu.
Checkpoint: Bảng ZBUG_TRACKER Active với các cột chứa File đính kèm
--------------------------------------------------------------------------------

PHASE 2: CẬP NHẬT BUSINESS LOGIC LAYER
Mục tiêu: Áp dụng State Tree mới cho Config Bug (Tự động gán cho Tester) và nới lỏng quyền hạn cho Tester đối với lỗi cấu hình.
Bước 2.1: Sửa logic sinh Bug (Function Z_BUG_CREATE)
Vào SE37, mở FM Z_BUG_CREATE ở chế độ Change.
Sửa logic: Nếu IV_BUG_TYPE = 'F', tự động gán DEV_ID = SY-UNAME và STATUS = '2' (Assigned). Source code cập nhật:
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
*"  EXPORTING
*"     VALUE(EV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug TYPE zbug_tracker,
        lv_number TYPE numc10.

  " 1. Sinh Bug ID tự động từ Number Range
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
    ev_message = 'Failed to generate Bug ID'.
    RETURN.
  ENDIF.

  " Format BUG_ID (Ví dụ: BUG0000001)
  CONCATENATE 'BUG' lv_number+3(7) INTO ev_bug_id.

  " 2. Gán thông tin cơ bản
  ls_bug-bug_id     = ev_bug_id.
  ls_bug-title      = iv_title.
  ls_bug-desc_text  = iv_desc.
  ls_bug-sap_module = iv_module.
  ls_bug-priority   = iv_priority.
  ls_bug-tester_id  = sy-uname.
  ls_bug-created_at = sy-datum.
  ls_bug-created_time = sy-uzeit.

  " Đảm bảo Bug Type luôn có giá trị hợp lệ, mặc định là Code 'C' nếu user không truyền
  IF iv_bug_type IS INITIAL.
    ls_bug-bug_type = 'C'.
  ELSE.
    ls_bug-bug_type = iv_bug_type.
  ENDIF.

  " 3. Xử lý đường dẫn file đính kèm (Evidence)
  IF iv_att_path IS NOT INITIAL.
    ls_bug-att_report = iv_att_path.
  ENDIF.

  " 4. RẼ NHÁNH LUỒNG THEO BUSINESS RULE MỚI
  IF ls_bug-bug_type = 'F'.
    " Lỗi Configuration: Tester tự xử lý.
    " Chuyển status sang Assigned và tự động gán DEV_ID = Tên của Tester.
    ls_bug-status = '2'.
    ls_bug-dev_id = sy-uname.
  ELSE.
    " Lỗi Code: Để trạng thái New (1) và ĐẢM BẢO DEV_ID TRỐNG
    " Điều này chặn đứng việc user tự truyền iv_dev_id vượt quyền Auto-Assign
    ls_bug-status = '1'.
    ls_bug-dev_id = ''.
  ENDIF.

  " 5. Lưu xuống cơ sở dữ liệu
  INSERT zbug_tracker FROM ls_bug.

  IF sy-subrc = 0.
    ev_success = 'Y'.
    CONCATENATE 'Bug' ev_bug_id 'created successfully' INTO ev_message SEPARATED BY space.

    " 6. Ghi log lịch sử hệ thống
    CALL FUNCTION 'Z_BUG_LOG_HISTORY'
      EXPORTING
        iv_bug_id      = ev_bug_id
        iv_action_type = 'CR' " CR = Create
        iv_old_value   = ''
        iv_new_value   = iv_title
        iv_reason      = 'New bug created'.

    COMMIT WORK AND WAIT.
  ELSE.
    ev_success = 'N'.
    ev_message = 'Database insert failed'.
    ROLLBACK WORK.
  ENDIF.

ENDFUNCTION.
Nhấn Activate.
Bước 2.2: Sửa logic phân quyền (Function Z_BUG_CHECK_PERMISSION)
Mở FM Z_BUG_CHECK_PERMISSION.
Bổ sung ngoại lệ: Cho phép Tester (Role 'T') được quyền UPDATE trạng thái nếu BUG_TYPE = 'F' VÀ DEV_ID = SY-UNAME. Source code cập nhật:
FUNCTION z_bug_check_permission.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_USER) TYPE  ZDE_USERNAME
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_ACTION) TYPE  CHAR20
*"  EXPORTING
*"     VALUE(EV_ALLOWED) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_user TYPE zbug_users,
        ls_bug  TYPE zbug_tracker.

  " 1. Lấy thông tin Role của User
  SELECT SINGLE * FROM zbug_users INTO @ls_user
    WHERE user_id = @iv_user.

  IF sy-subrc <> 0.
    ev_allowed = 'N'.
    ev_message = 'User not found in system'.
    RETURN.
  ENDIF.

  " 2. ĐẶC QUYỀN: Manager (M) có toàn quyền thao tác
  IF ls_user-role = 'M'.
    ev_allowed = 'Y'.
    RETURN.
  ENDIF.

  " 3. Lấy thông tin Bug hiện tại (nếu có truyền Bug ID)
  IF iv_bug_id IS NOT INITIAL.
    SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
      WHERE bug_id = @iv_bug_id.
  ENDIF.

  " 4. RẼ NHÁNH KIỂM TRA QUYỀN THEO HÀNH ĐỘNG
  CASE iv_action.
    WHEN 'CREATE'.
      IF ls_user-role = 'T'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only Tester can create bugs'.
      ENDIF.

    WHEN 'UPDATE_STATUS'.
      " ---> [RULE MỚI] Mở khóa: Nếu là Lỗi cấu hình (F) và Tester đang giữ Bug này
      IF ls_bug-bug_type = 'F' AND ls_user-role = 'T' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      " ---> [RULE CŨ] Developer được quyền update bug do mình giữ
      ELSEIF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      " ---> [RULE CŨ] Tester được quyền update trạng thái khi Bug mới tạo (Status 1)
      ELSEIF ls_user-role = 'T' AND ls_bug-status = '1'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Not authorized to update this bug'.
      ENDIF.

    WHEN 'UPLOAD_REPORT'.
      IF ls_user-role = 'T' AND ls_bug-tester_id = iv_user.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only the assigned Tester can upload report'.
      ENDIF.

    WHEN 'UPLOAD_FIX'.
      " ---> [RULE MỚI] Mở khóa: Tester tự xử lý lỗi cấu hình được quyền up bằng chứng FIX
      IF ls_bug-bug_type = 'F' AND ls_user-role = 'T' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      " ---> [RULE CŨ] Developer tải bằng chứng FIX
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

    WHEN OTHERS.
      ev_allowed = 'N'.
      ev_message = 'Unknown action'.
  ENDCASE.

ENDFUNCTION.
Nhấn Activate
--------------------------------------------------------------------------------

PHASE 3: XÂY DỰNG CENTRALIZED WORKSPACE (ZBUG_HOME)
Tài khoản sử dụng: DEV-061 (Pass: @57Dt766) Mục tiêu: Gom toàn bộ T-code rời rạc thành một "Trạm làm việc trung tâm" một chạm.
Bước 3.1: Khai báo lớp sự kiện & Cấu trúc ALV (Tích hợp Evidence 1)
Vào SE38, tạo program mới Z_BUG_WORKSPACE.
Định nghĩa Event Handler để xử lý click mở file đính kèm (Hotspot Click-to-open). Khai báo Data & Class:
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.
Bước 3.2: Logic hiển thị màn hình (Main Program)
Tích hợp màn hình Popup Create (có Bug Type, ẩn Dev_ID) và Popup Update (có logic ẩn Upload File khi Manager Assign). Source code Main Logic:
*&---------------------------------------------------------------------*
*& Report Z_BUG_WORKSPACE
*&---------------------------------------------------------------------*
REPORT z_bug_workspace.

TYPE-POOLS: vrm. " BẮT BUỘC: Dùng để tạo Dropdown List

" --- 1. KHAI BÁO BIẾN ---
DATA: go_docking  TYPE REF TO cl_gui_docking_container,
      go_splitter TYPE REF TO cl_gui_splitter_container,
      go_cont_top TYPE REF TO cl_gui_container,
      go_cont_bot TYPE REF TO cl_gui_container,
      go_alv      TYPE REF TO cl_gui_alv_grid,
      go_doc      TYPE REF TO cl_dd_document.

" Cấu trúc ALV có thêm cột ảo để hiện chữ và cột Evidence
TYPES: BEGIN OF ty_bug_alv,
         bug_id        TYPE zde_bug_id,
         title         TYPE zde_bug_title,
         sap_module    TYPE zde_sap_module,
         priority      TYPE zde_priority,
         priority_text TYPE char20,
         status        TYPE zde_bug_status,
         status_text   TYPE char20,
         bug_type      TYPE zde_bug_type,
         tester_id     TYPE zde_username,
         dev_id        TYPE zde_username,
         created_at    TYPE dats,
         att_report    TYPE zbug_tracker-att_report, " <-- BƯỚC 2: THÊM DÒNG NÀY CHO EVIDENCE 1
       END OF ty_bug_alv.

DATA: gt_bugs   TYPE TABLE OF ty_bug_alv,
      gt_fcat   TYPE lvc_t_fcat,
      gs_layout TYPE lvc_s_layo,
      ok_code   TYPE sy-ucomm,
      lv_role   TYPE zbug_users-role.

" --- BƯỚC 1: CLASS XỬ LÝ SỰ KIỆN CLICK MỞ FILE TỪ ALV ---
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS on_hotspot_click FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.
  METHOD on_hotspot_click.
    " Nếu người dùng click vào cột Evidence 1 (ATT_REPORT)
    IF e_column_id-fieldname = 'ATT_REPORT'.
      " Đọc thông tin dòng đang được click
      READ TABLE gt_bugs ASSIGNING FIELD-SYMBOL(<fs_click>) INDEX e_row_id-index.
      IF sy-subrc = 0 AND <fs_click>-att_report IS NOT INITIAL.
        " Gọi hàm tự động mở file Excel từ đường dẫn
        cl_gui_frontend_services=>execute(
          EXPORTING  document = CONV string( <fs_click>-att_report )
          EXCEPTIONS OTHERS   = 1 ).
      ELSE.
        MESSAGE 'Chưa có file bằng chứng nào được tải lên!' TYPE 'S' DISPLAY LIKE 'W'.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: go_handler TYPE REF TO lcl_event_handler. " Khai báo biến giữ sự kiện

" --- 2. SCREEN DEFINITIONS (POPUP 200 & 300) ---
SELECTION-SCREEN BEGIN OF SCREEN 200 TITLE TEXT-001 AS WINDOW.
  SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-002.
    PARAMETERS: p_title  TYPE zde_bug_title OBLIGATORY,
                p_type   TYPE zde_bug_type DEFAULT 'C' OBLIGATORY,
                p_module TYPE zde_sap_module OBLIGATORY,
                p_prior  TYPE zde_priority DEFAULT 'M',
                p_desc   TYPE string LOWER CASE OBLIGATORY.
  SELECTION-SCREEN END OF BLOCK b1.
  SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-003.
    PARAMETERS: p_file TYPE string.
  SELECTION-SCREEN END OF BLOCK b2.
SELECTION-SCREEN END OF SCREEN 200.

SELECTION-SCREEN BEGIN OF SCREEN 300 TITLE TEXT-004 AS WINDOW.
  SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-005.
    PARAMETERS: p_updbug TYPE zde_bug_id MODIF ID dis,
                p_updsta TYPE zde_bug_status AS LISTBOX VISIBLE LENGTH 25 OBLIGATORY,
                p_upddev TYPE zde_username,
                p_updrsn TYPE string LOWER CASE OBLIGATORY.
  SELECTION-SCREEN END OF BLOCK b3.
  SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-006.
    PARAMETERS: p_updfil TYPE string.
  SELECTION-SCREEN END OF BLOCK b4.
SELECTION-SCREEN END OF SCREEN 300.

" --- 3. EVENT HANDLING (AT SELECTION-SCREEN) ---
AT SELECTION-SCREEN OUTPUT.
  IF sy-dynnr = '0300'.
    LOOP AT SCREEN.
      IF p_updsta = '2'.
        IF screen-name CS 'P_UPDFIL'.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDLOOP.

    DATA: lt_values TYPE vrm_values, ls_value TYPE vrm_value.
    CLEAR lt_values.
    ls_value-key = '1'. ls_value-text = '1 - New'. APPEND ls_value TO lt_values.
    ls_value-key = '2'. ls_value-text = '2 - Assigned'. APPEND ls_value TO lt_values.
    ls_value-key = '3'. ls_value-text = '3 - In Progress'. APPEND ls_value TO lt_values.
    ls_value-key = '4'. ls_value-text = '4 - Fixed'. APPEND ls_value TO lt_values.
    ls_value-key = '5'. ls_value-text = '5 - Closed'. APPEND ls_value TO lt_values.
    CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_UPDSTA' values = lt_values.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA: lt_file_table TYPE filetable, lv_rc TYPE i.
  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    CHANGING file_table = lt_file_table rc = lv_rc EXCEPTIONS OTHERS = 1.
  IF sy-subrc = 0 AND lv_rc > 0. READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1. p_file = ls_file-filename. ENDIF.

AT SELECTION-SCREEN.
  IF sy-dynnr = '0200'.
    DATA: lv_new_bug_id TYPE zde_bug_id, lv_success TYPE char1, lv_message TYPE string.
    CALL FUNCTION 'Z_BUG_CREATE'
      EXPORTING iv_title = p_title iv_desc = p_desc iv_module = p_module iv_priority = p_prior iv_bug_type = p_type iv_att_path = CONV zde_bug_att_path( p_file )
      IMPORTING ev_bug_id = lv_new_bug_id ev_success = lv_success ev_message = lv_message.
    IF lv_success = 'Y'. MESSAGE lv_message TYPE 'S'. LEAVE TO SCREEN 0. ELSE. MESSAGE lv_message TYPE 'E'. ENDIF.
  ELSEIF sy-dynnr = '0300'.
    DATA: lv_success2 TYPE char1, lv_message2 TYPE string.
    CALL FUNCTION 'Z_BUG_UPDATE_STATUS'
      EXPORTING iv_bug_id = p_updbug iv_new_status = p_updsta iv_dev_id = p_upddev iv_reason = p_updrsn iv_changed_by = sy-uname
      IMPORTING ev_success = lv_success2 ev_message = lv_message2.
    IF lv_success2 = 'Y'. MESSAGE 'Cập nhật thành công!' TYPE 'S'. LEAVE TO SCREEN 0. ELSE. MESSAGE lv_message2 TYPE 'E'. ENDIF.
  ENDIF.

" --- 4. MAIN LOGIC (SCREEN 100) ---
START-OF-SELECTION.
  CALL SCREEN 100.

MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN_STATUS'.
  SET TITLEBAR 'MAIN_TITLE' WITH 'Bug Tracking Workspace'.

  " --- BƯỚC 3: LẤY DỮ LIỆU TỪ DATABASE (Sửa lỗi không tương thích kiểu dữ liệu) ---
  SELECT SINGLE role FROM zbug_users INTO @lv_role WHERE user_id = @sy-uname.

  IF lv_role = 'T'.
    SELECT bug_id, title, sap_module, priority, status, bug_type, tester_id, dev_id, created_at, att_report
      FROM zbug_tracker
      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs " <-- QUAN TRỌNG: Thêm dòng này
      WHERE tester_id = @sy-uname.
  ELSEIF lv_role = 'D'.
    SELECT bug_id, title, sap_module, priority, status, bug_type, tester_id, dev_id, created_at, att_report
      FROM zbug_tracker
      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs " <-- QUAN TRỌNG: Thêm dòng này
      WHERE dev_id = @sy-uname.
  ELSE.
    SELECT bug_id, title, sap_module, priority, status, bug_type, tester_id, dev_id, created_at, att_report
      FROM zbug_tracker
      INTO CORRESPONDING FIELDS OF TABLE @gt_bugs. " <-- QUAN TRỌNG: Thêm dòng này
  ENDIF.

  " 2. DỊCH MÃ SANG CHỮ
  LOOP AT gt_bugs ASSIGNING FIELD-SYMBOL(<fs_bug>).
    CASE <fs_bug>-status.
      WHEN '1'. <fs_bug>-status_text = 'New'.
      WHEN '2'. <fs_bug>-status_text = 'Assigned'.
      WHEN '3'. <fs_bug>-status_text = 'In Progress'.
      WHEN '4'. <fs_bug>-status_text = 'Fixed'.
      WHEN '5'. <fs_bug>-status_text = 'Closed'.
    ENDCASE.
    CASE <fs_bug>-priority.
      WHEN 'H'. <fs_bug>-priority_text = 'High'.
      WHEN 'M'. <fs_bug>-priority_text = 'Medium'.
      WHEN 'L'. <fs_bug>-priority_text = 'Low'.
    ENDCASE.
  ENDLOOP.

  " 3. KHỞI TẠO GIAO DIỆN (Lần đầu tiên)
  IF go_docking IS INITIAL.
    CREATE OBJECT go_docking EXPORTING extension = 3000.
    CREATE OBJECT go_splitter EXPORTING parent = go_docking rows = 2 columns = 1.
    go_splitter->set_row_height( id = 1 height = 15 ).
    go_cont_top = go_splitter->get_container( row = 1 column = 1 ).
    go_cont_bot = go_splitter->get_container( row = 2 column = 1 ).

    " VẼ HEADER
    CREATE OBJECT go_doc EXPORTING style = 'ALV_GRID'.
    go_doc->add_text( text = '🚀 BẢNG ĐIỀU KHIỂN TRUNG TÂM (COMMAND CENTER)' sap_style = cl_dd_document=>heading sap_color = cl_dd_document=>list_heading_int ).
    go_doc->new_line( ).
    go_doc->add_text( text = '👉 Chọn 1 dòng Bug bên dưới rồi bấm UPDATE hoặc PRINT.' sap_fontsize = cl_dd_document=>medium ).
    go_doc->display_document( EXPORTING parent = go_cont_top ).

    " --- BƯỚC 4: VẼ CỘT EVIDENCE 1 VÀ BIẾN THÀNH LINK (HOTSPOT) ---
    gt_fcat = VALUE lvc_t_fcat(
      ( fieldname = 'BUG_ID'        scrtext_m = 'Bug ID'      outputlen = 10 )
      ( fieldname = 'TITLE'         scrtext_m = 'Bug Title'   outputlen = 30 )
      ( fieldname = 'STATUS_TEXT'   scrtext_m = 'Status'      outputlen = 12 )
      ( fieldname = 'PRIORITY_TEXT' scrtext_m = 'Priority'    outputlen = 10 )
      ( fieldname = 'SAP_MODULE'    scrtext_m = 'Module'      outputlen = 15 )
      ( fieldname = 'TESTER_ID'     scrtext_m = 'Tester'      outputlen = 12 )
      ( fieldname = 'DEV_ID'        scrtext_m = 'Developer'   outputlen = 12 )
      ( fieldname = 'CREATED_AT'    scrtext_m = 'Created On'  outputlen = 12 )
      ( fieldname = 'ATT_REPORT'    scrtext_m = 'Evidence'  outputlen = 25  hotspot = 'X' )
    ).
    gs_layout-sel_mode = 'A'.

    CREATE OBJECT go_alv EXPORTING i_parent = go_cont_bot.

    " --- BƯỚC 5: ĐĂNG KÝ SỰ KIỆN CLICK CHO ALV ---
    CALL METHOD go_alv->set_table_for_first_display
      EXPORTING is_layout = gs_layout
      CHANGING it_outtab = gt_bugs it_fieldcatalog = gt_fcat.

    CREATE OBJECT go_handler.
    SET HANDLER go_handler->on_hotspot_click FOR go_alv.

  ELSE.
    go_alv->refresh_table_display( EXPORTING is_stable = VALUE #( row = 'X' col = 'X' ) ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  DATA: lt_idx TYPE lvc_t_row, ls_idx TYPE lvc_s_row.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'. LEAVE PROGRAM.
    WHEN 'CREATE'. CALL SELECTION-SCREEN 200 STARTING AT 10 5 ENDING AT 100 20.
    WHEN 'UPDATE'.
      go_alv->get_selected_rows( IMPORTING et_index_rows = lt_idx ).
      IF lt_idx IS INITIAL.
        MESSAGE 'Chọn 1 dòng để cập nhật!' TYPE 'I'.
      ELSE.
        READ TABLE lt_idx INTO ls_idx INDEX 1.
        READ TABLE gt_bugs INTO DATA(ls_sel) INDEX ls_idx-index.
        p_updbug = ls_sel-bug_id. p_updsta = ls_sel-status. p_upddev = ls_sel-dev_id. CLEAR: p_updrsn, p_updfil.
        CALL SELECTION-SCREEN 300 STARTING AT 10 5 ENDING AT 100 20.
      ENDIF.
    WHEN 'PRINT'.
      go_alv->get_selected_rows( IMPORTING et_index_rows = lt_idx ).
      IF lt_idx IS INITIAL.
        MESSAGE 'Chọn 1 dòng để in!' TYPE 'I'.
      ELSE.
        READ TABLE lt_idx INTO ls_idx INDEX 1.
        READ TABLE gt_bugs INTO DATA(ls_prt) INDEX ls_idx-index.
        DATA: ls_form TYPE zbug_tracker, lv_fm TYPE rs38l_fnam.
        MOVE-CORRESPONDING ls_prt TO ls_form.
        CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME' EXPORTING formname = 'ZBUG_FORM' IMPORTING fm_name = lv_fm.
        IF sy-subrc = 0. CALL FUNCTION lv_fm EXPORTING is_bug = ls_form. ENDIF.
      ENDIF.
  ENDCASE.
  CLEAR ok_code.
ENDMODULE.
Nhấn Save và Activate.
Bước 3.3: Tạo T-code ZBUG_HOME
Vào SE93, nhập ZBUG_HOME -> Create.
Short text: Centralized Bug Workspace.
Chọn Program and selection screen (report transaction).
Program: Z_BUG_WORKSPACE. Check đủ 3 ô GUI support.
Nhấn Save.
Checkpoint: Gõ /nZBUG_HOME -> Màn hình ALV trung tâm hiển thị.
