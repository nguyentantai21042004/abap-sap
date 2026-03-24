# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE D: EXCEL & ADVANCED FEATURES

**Dự án:** SAP Bug Tracking Management System  
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)  
**Thời gian ước tính:** 2 ngày (31/03-01/04)  
**Yêu cầu:** Hoàn thành Phase A + B + C trước  

---

## MỤC LỤC

1. [Bước D1: Tạo Excel Template trên SMW0](#bước-d1-tạo-excel-template-trên-smw0)
2. [Bước D2: Download Template Button](#bước-d2-download-template-button)
3. [Bước D3: Upload Excel Logic (TEXT_CONVERT_XLS_TO_SAP)](#bước-d3-upload-excel-logic)
4. [Bước D4: Message Class Migration (ZBUG_MSG)](#bước-d4-message-class-migration)
5. [Bước D5: Dashboard Statistics (Optional)](#bước-d5-dashboard-statistics-optional)

---

## Bước D1: Tạo Excel Template trên SMW0

**Mục tiêu:** Upload file Excel template chuẩn lên SAP server (SMW0).

### Step 1: Tạo file Excel template trên máy local

Tạo file `ZTEMPLATE_PROJECT.xlsx` với các cột sau:

| Column A | Column B | Column C | Column D | Column E | Column F | Column G |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **`PROJECT_ID`** | **`PROJECT_NAME`** | **`DESCRIPTION`** | **`START_DATE`** | **`END_DATE`** | **`PROJECT_MANAGER`** | **`NOTE`** |
| `(Char 20)` | `(Char 100)` | `(Char 255)` | `DD.MM.YYYY` | `DD.MM.YYYY` | `(Char 12)` | `(Char 255)` |
| `PRJ001` | `Example Proj` | `Description` | `01.04.2026` | `30.06.2026` | `DEV-089` | |

- **Row 1:** Headers (in đậm, có border)
- **Row 2:** Format hints / data types
- **Row 3:** Dữ liệu mẫu (highlight vàng)

### Step 2: Upload lên SMW0

1. Vào T-code **SMW0**
2. Chọn **Binary data for WebRFC Applications**
3. Nhấn **Create** → nhập Object Name: `ZTEMPLATE_PROJECT`
4. Description: "Project Upload Template"
5. Chọn file `ZTEMPLATE_PROJECT.xlsx` từ local
6. **Save**

> ✅ **Checkpoint:** **SMW0** → `ZTEMPLATE_PROJECT` → **Download** → mở được file Excel chuẩn format.

---

## Bước D2: Download Template Button

**Mục tiêu:** Nút trên GUI Status cho user download template.

Trong `Z_BUG_WS_PAI`, thêm handler cho nút `DOWNLOAD_TMPL` trên Screen `0400`:

```abap
WHEN 'DOWNLOAD_TMPL'.
  PERFORM download_template.
```

**FORM `download_template` (trong `Z_BUG_WS_F02`):**

```abap
FORM download_template.
  DATA: lv_objid   TYPE wwwdatatab-objid VALUE 'ZTEMPLATE_PROJECT',
        lv_dest    TYPE rlgrap-filename,
        lv_rc      TYPE sy-subrc.

  " Chọn đường dẫn lưu file
  DATA: lt_file_table TYPE filetable,
        lv_urc        TYPE i,
        lv_uaction    TYPE i.

  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = 'xlsx'
      default_file_name = 'ZTEMPLATE_PROJECT.xlsx'
      file_filter       = 'Excel Files (*.xlsx)|*.xlsx'
    CHANGING
      filename   = lv_dest
      path       = DATA(lv_path)
      fullpath   = DATA(lv_fullpath)
      user_action = lv_uaction
    EXCEPTIONS OTHERS = 1 ).

  IF lv_uaction <> 0. " User cancelled
    MESSAGE s020(zbug_msg).
    RETURN.
  ENDIF.

  " Download từ SMW0
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = VALUE wwwdatatab( relid = 'MI' objid = lv_objid )
      destination = lv_fullpath
    IMPORTING
      rc          = lv_rc.

  IF lv_rc = 0.
    MESSAGE 'Template downloaded successfully' TYPE 'S'.
  ELSE.
    MESSAGE 'Failed to download template' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
```

> ✅ **Checkpoint:** Bấm nút `DOWNLOAD_TMPL` trên ALV → chọn folder → file `.xlsx` lưu thành công.

---

## Bước D3: Upload Excel Logic

**Mục tiêu:** Upload file Excel → validate → insert vào `ZBUG_PROJECT`.

Trong `Z_BUG_WS_PAI`, thêm handler cho nút `UPLOAD` trên Screen `0400`:

```abap
WHEN 'UPLOAD'.
  PERFORM upload_project_excel.
```

**FORM `upload_project_excel` (trong `Z_BUG_WS_F01`):**

```abap
FORM upload_project_excel.
  DATA: lv_file     TYPE string,
        lt_raw      TYPE truxs_t_text_data,
        lt_projects TYPE TABLE OF zbug_project,
        ls_project  TYPE zbug_project,
        lv_errors   TYPE i,
        lv_success  TYPE i.

  " 1. Chọn file
  DATA: lt_file_table TYPE filetable, lv_rc TYPE i.
  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING file_filter = 'Excel Files (*.xlsx)|*.xlsx'
    CHANGING  file_table  = lt_file_table
              rc          = lv_rc
    EXCEPTIONS OTHERS = 1 ).

  IF lv_rc <= 0. RETURN. ENDIF.
  READ TABLE lt_file_table INTO DATA(ls_file) INDEX 1.
  lv_file = ls_file-filename.

  " 2. Đọc Excel vào internal table
  TYPES: BEGIN OF ty_upload,
           project_id      TYPE char20,
           project_name    TYPE char100,
           description     TYPE char255,
           start_date      TYPE char10,
           end_date        TYPE char10,
           project_manager TYPE char12,
           note            TYPE char255,
         END OF ty_upload.
  DATA: lt_upload TYPE TABLE OF ty_upload.

  CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
    EXPORTING
      i_field_seperator = 'X'
      i_line_header     = 'X'    " Bỏ qua header row
      i_tab_raw_data    = lt_raw
      i_filename        = lv_file
    TABLES
      i_tab_converted_data = lt_upload
    EXCEPTIONS
      conversion_failed   = 1
      OTHERS              = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Failed to read Excel file' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 3. Validate + Insert
  LOOP AT lt_upload ASSIGNING FIELD-SYMBOL(<fs>).
    CLEAR ls_project.
    
    " Bỏ qua Header 2 dòng đầu (nếu i_line_header chưa clear hết)
    IF <fs>-project_id CS 'PROJECT_ID' OR <fs>-project_id CS '(Char'.
      CONTINUE.
    ENDIF.

    " Validate PROJECT_ID không trống
    IF <fs>-project_id IS INITIAL.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " Validate PROJECT_ID chưa tồn tại
    SELECT COUNT(*) FROM zbug_project
      WHERE project_id = @<fs>-project_id.
    IF sy-dbcnt > 0.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " ... [Validate Project Manager + Mapping Data] ...

    APPEND ls_project TO lt_projects.
    ADD 1 TO lv_success.
  ENDLOOP.

  " 4. Batch insert
  IF lt_projects IS NOT INITIAL.
    INSERT zbug_project FROM TABLE lt_projects.
    COMMIT WORK.
    MESSAGE |Uploaded { lv_success } project(s). { lv_errors } error(s).| TYPE 'S'.
  ENDIF.
ENDFORM.
```

> ✅ **Checkpoint:** Upload file Excel 3 rows:
>
> - Row 1: Valid → Insert thành công
> - Row 2: Duplicate `PROJECT_ID` → Skip
> - Row 3: PM not Manager → Skip
> - Message: "Uploaded 1 project(s). 2 error(s)."

---

## Bước D4: Message Class Migration

**Mục tiêu:** Thay tất cả hardcoded strings → `MESSAGE` class `ZBUG_MSG`.

**TRƯỚC → SAU:**

```abap
" TRƯỚC:
MESSAGE 'Chọn 1 dòng để cập nhật!' TYPE 'I'.
" SAU:
MESSAGE s009(zbug_msg).

" TRƯỚC:
MESSAGE 'Cập nhật thành công!' TYPE 'S'.
" SAU:
MESSAGE s025(zbug_msg).
```

### Quy tắc

1. Dùng `MESSAGE sXXX(zbug_msg)` cho popup messages (`S` = Success, `E` = Error)
2. Dùng `MESSAGE sXXX(zbug_msg) INTO lv_msg` cho internal messages
3. Dùng `DISPLAY LIKE 'E'` để hiện error icon dù type `S` (tránh dump màn hình)

> ✅ **Checkpoint:** Chạy global search (Ctrl+F in SE80) `MESSAGE '` → không còn hardcoded message strings trong ZBUG_WORKSPACE_MP.

---

## Bước D5: Dashboard Statistics (Optional)

**Mục tiêu:** Nếu đủ thời gian, tạo dashboard cho Manager.

**Logic đếm:**

```abap
" Đếm bug theo status
SELECT status, COUNT(*) AS cnt
  FROM zbug_tracker
  INTO TABLE @DATA(lt_status_count)
  WHERE is_del <> 'X'
  GROUP BY status.
```

Hiển thị bằng `CL_DD_DOCUMENT` trên màn hình `0100`.

---

## TỔNG KẾT PHASE D

Sau khi hoàn thành Phase D, bạn phải có:

- [x] Excel template `ZTEMPLATE_PROJECT` trên SMW0
- [x] Download Template button hoạt động
- [x] Upload Excel → validate → insert `ZBUG_PROJECT`
- [x] Message Class `ZBUG_MSG` dùng xuyên suốt (không còn hardcode)
- [ ] Dashboard (*optional — nếu đủ thời gian*)

👉 **Chuyển sang Phase E: Testing & Go-Live**
