# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE D: EXCEL & ADVANCED FEATURES

**Dự án:** SAP Bug Tracking Management System
**Ngày:** 09/04/2026 | **Phiên bản:** 6.0 (Project-First Flow)
**Thời gian ước tính:** 2 ngày
**Yêu cầu:** Hoàn thành Phase A + B + C trước
**ABAP Version:** 7.70 (SAP_BASIS 770 — inline declarations, SWITCH, CONV, string templates, @ host vars)
**Development Account:**
- `DEV-089` (Pass: `@Anhtuoi123`) — *Excel & Logic*
- `DEV-061` (Pass: `@57Dt766`) — *SmartForms*
- `DEV-242` (Pass: `12345678`) — *Email configuration*

---

## MỤC LỤC

1. [Bước D1: Tạo Excel Template trên SMW0](#bước-d1-tạo-excel-template-trên-smw0)
2. [Bước D2: Download Template Button](#bước-d2-download-template-button)
3. [Bước D3: Upload Excel Logic (TEXT_CONVERT_XLS_TO_SAP)](#bước-d3-upload-excel-logic)
4. [Bước D4: Message Class Migration (ZBUG_MSG)](#bước-d4-message-class-migration)
5. [Bước D5: Orphan Bug Cleanup Script](#bước-d5-orphan-bug-cleanup-script)

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

> Checkpoint: **SMW0** → `ZTEMPLATE_PROJECT` → **Download** → mở được file Excel chuẩn format.

---

## Bước D2: Download Template Button

**Mục tiêu:** Nút trên GUI Status cho user download template.

**Fcode:** `DN_TMPL` trên `STATUS_0400` (Project List screen — initial screen trong flow mới).

> **Lưu ý flow mới:** Screen 0400 (Project List) là initial screen. Nút `DN_TMPL` và `UPLOAD` nằm trên `STATUS_0400`, chỉ visible cho Manager (xem `CODE_PBO.md` — non-Manager users exclude `UPLOAD` và `DN_TMPL`).

Trong `Z_BUG_WS_PAI`, handler đã có sẵn trong `user_command_0400`:

```abap
WHEN 'DN_TMPL'.
  PERFORM download_template.
```

**FORM `download_template` (trong `Z_BUG_WS_F02`):**

```abap
FORM download_template.
  DATA: lv_objid   TYPE wwwdatatab-objid VALUE 'ZTEMPLATE_PROJECT',
        lv_uaction TYPE i.

  " Chọn đường dẫn lưu file
  cl_gui_frontend_services=>file_save_dialog(
    EXPORTING
      default_extension = 'xlsx'
      default_file_name = 'ZTEMPLATE_PROJECT.xlsx'
      file_filter       = 'Excel Files (*.xlsx)|*.xlsx'
    CHANGING
      filename    = DATA(lv_filename)
      path        = DATA(lv_path)
      fullpath    = DATA(lv_fullpath)
      user_action = lv_uaction
    EXCEPTIONS OTHERS = 1 ).

  IF lv_uaction <> 0. " User cancelled
    MESSAGE s020(zbug_msg).
    RETURN.
  ENDIF.

  " Download từ SMW0 (primary method)
  DATA: lv_subrc TYPE sy-subrc.
  CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
    EXPORTING
      key         = VALUE wwwdatatab( relid = 'MI' objid = lv_objid )
      destination = lv_fullpath
    IMPORTING
      rc          = lv_subrc.

  IF lv_subrc = 0.
    MESSAGE s025(zbug_msg).  " 'Successfully saved'
  ELSE.
    " Fallback: SAP_OBJ_READ + GUI_DOWNLOAD (WWWDATA_IMPORT pattern)
    DATA: lt_mime TYPE TABLE OF w3mime,
          lv_size TYPE i.
    CALL FUNCTION 'SAP_OBJ_READ'
      EXPORTING
        p_objid   = lv_objid
        p_relid   = 'MI'
      TABLES
        p_content = lt_mime
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.

    IF sy-subrc = 0.
      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          filename = lv_fullpath
          filetype = 'BIN'
        TABLES
          data_tab = lt_mime
        EXCEPTIONS
          OTHERS   = 1.

      IF sy-subrc = 0.
        MESSAGE s025(zbug_msg).
      ELSE.
        MESSAGE s000(zbug_msg) WITH 'Failed to save' 'template file' DISPLAY LIKE 'E'.
      ENDIF.
    ELSE.
      MESSAGE s000(zbug_msg) WITH 'Template not found' 'on server (SMW0)' DISPLAY LIKE 'E'.
    ENDIF.
  ENDIF.
ENDFORM.
```

> Checkpoint: Bấm nút `DN_TMPL` trên Screen 0400 toolbar → chọn folder → file `.xlsx` lưu thành công.

---

## Bước D3: Upload Excel Logic

**Mục tiêu:** Upload file Excel → validate → insert vào `ZBUG_PROJECT`.

**Fcode:** `UPLOAD` trên `STATUS_0400`.

Trong `Z_BUG_WS_PAI`, handler đã có sẵn trong `user_command_0400`:

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
    MESSAGE s000(zbug_msg) WITH 'Failed to read' 'Excel file' DISPLAY LIKE 'E'.
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

    " Validate Project Manager exists + is Manager role + active
    SELECT COUNT(*) FROM zbug_users
      WHERE user_id = @<fs>-project_manager AND role = 'M' AND is_del <> 'X'.
    IF sy-dbcnt = 0.
      ADD 1 TO lv_errors.
      CONTINUE.
    ENDIF.

    " Map data to structure
    ls_project-project_id      = <fs>-project_id.
    ls_project-project_name    = <fs>-project_name.
    ls_project-description     = <fs>-description.
    ls_project-project_manager = <fs>-project_manager.
    ls_project-note            = <fs>-note.

    " Parse dates (DD.MM.YYYY → YYYYMMDD)
    IF <fs>-start_date IS NOT INITIAL AND strlen( <fs>-start_date ) = 10.
      CONCATENATE <fs>-start_date+6(4) <fs>-start_date+3(2) <fs>-start_date(2)
        INTO ls_project-start_date.
    ENDIF.
    IF <fs>-end_date IS NOT INITIAL AND strlen( <fs>-end_date ) = 10.
      CONCATENATE <fs>-end_date+6(4) <fs>-end_date+3(2) <fs>-end_date(2)
        INTO ls_project-end_date.
    ENDIF.

    " Default values
    ls_project-project_status = '1'.  " Opening
    ls_project-ernam          = sy-uname.
    ls_project-erdat          = sy-datum.
    ls_project-erzet          = sy-uzeit.

    APPEND ls_project TO lt_projects.
    ADD 1 TO lv_success.
  ENDLOOP.

  " 4. Batch insert
  IF lt_projects IS NOT INITIAL.
    INSERT zbug_project FROM TABLE lt_projects.
    COMMIT WORK.
    MESSAGE s000(zbug_msg) WITH 'Uploaded' lv_success 'project(s).' lv_errors.
    " Refresh project ALV after upload
    PERFORM select_project_data.
    PERFORM display_project_alv.
  ELSE.
    MESSAGE s000(zbug_msg) WITH 'No valid data' 'to upload' DISPLAY LIKE 'E'.
  ENDIF.
ENDFORM.
```

> Checkpoint: Upload file Excel 3 rows:
>
> - Row 1: Valid → Insert thành công
> - Row 2: Duplicate `PROJECT_ID` → Skip
> - Row 3: PM not Manager → Skip
> - Message: "Uploaded 1 project(s). 2"
> - Project ALV refreshes automatically

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

" TRƯỚC (trong D2/D3):
MESSAGE 'Failed to read Excel file' TYPE 'S' DISPLAY LIKE 'E'.
" SAU:
MESSAGE s000(zbug_msg) WITH 'Failed to read' 'Excel file' DISPLAY LIKE 'E'.

" TRƯỚC:
MESSAGE 'Template downloaded successfully' TYPE 'S'.
" SAU:
MESSAGE s025(zbug_msg).
```

### Quy tắc

1. Dùng `MESSAGE sXXX(zbug_msg)` cho popup messages (`S` = Success, `E` = Error)
2. Dùng `MESSAGE sXXX(zbug_msg) INTO lv_msg` cho internal messages
3. Dùng `DISPLAY LIKE 'E'` để hiện error icon dù type `S` (tránh dump màn hình)
4. Dùng `MESSAGE s000(zbug_msg) WITH '...' '...'` cho dynamic/fallback messages khi chưa có message number riêng (s000 = `&1 &2 &3 &4` generic placeholder)

> Checkpoint: Chạy global search (Ctrl+F in SE80) `MESSAGE '` → không còn hardcoded message strings trong ZBUG_WORKSPACE_MP.

---

## Bước D5: Orphan Bug Cleanup Script

**Mục tiêu:** Fix bugs cũ (tạo trước Phase A) không có `PROJECT_ID` — gán chúng vào 1 project hoặc đánh dấu.

> **Background:** Trong flow mới, bug bắt buộc thuộc 1 project (`PROJECT_ID` enforce khi create). Nhưng bugs tạo từ hệ thống cũ có thể có `PROJECT_ID = ''`. Cần cleanup để tránh dữ liệu orphan.

### Option A: Gán vào Default Project (Recommended)

Tạo report `Z_BUG_CLEANUP_ORPHAN` (SE38, Type 1 = Executable):

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_CLEANUP_ORPHAN
*&---------------------------------------------------------------------*
*& Cleanup orphan bugs (no PROJECT_ID) — run ONCE after Phase A migration
*& Creates a default project "LEGACY" and assigns all orphan bugs to it
*&---------------------------------------------------------------------*
REPORT z_bug_cleanup_orphan.

CONSTANTS: lc_default_prj TYPE zde_project_id VALUE 'LEGACY'.

" ── Step 1: Check if default project exists, create if not ──
SELECT COUNT(*) FROM zbug_project
  WHERE project_id = @lc_default_prj.

IF sy-dbcnt = 0.
  DATA(ls_project) = VALUE zbug_project(
    project_id      = lc_default_prj
    project_name    = 'Legacy Bugs (Pre-Project)'
    description     = 'Auto-created to hold bugs from before Project entity was introduced'
    project_status  = '1'   " Opening
    project_manager = sy-uname
    start_date      = sy-datum
    ernam           = sy-uname
    erdat           = sy-datum
    erzet           = sy-uzeit ).

  INSERT zbug_project FROM ls_project.
  IF sy-subrc = 0.
    WRITE: / 'Created default project:', lc_default_prj.
  ELSE.
    WRITE: / 'ERROR: Failed to create default project'.
    RETURN.
  ENDIF.
ELSE.
  WRITE: / 'Default project already exists:', lc_default_prj.
ENDIF.

" ── Step 2: Count orphan bugs ──
SELECT COUNT(*) FROM zbug_tracker
  WHERE project_id = @( CONV zde_project_id( '' ) )
    AND is_del <> 'X'.
DATA(lv_orphan_count) = sy-dbcnt.

WRITE: / 'Orphan bugs found:', lv_orphan_count.

IF lv_orphan_count = 0.
  WRITE: / 'Nothing to do — all bugs have a project.'.
  RETURN.
ENDIF.

" ── Step 3: Update orphan bugs ──
UPDATE zbug_tracker
  SET project_id = @lc_default_prj
      aenam      = @sy-uname
      aedat      = @sy-datum
      aezet      = @sy-uzeit
  WHERE project_id = @( CONV zde_project_id( '' ) )
    AND is_del <> 'X'.

IF sy-subrc = 0.
  COMMIT WORK.
  WRITE: / 'Successfully assigned', lv_orphan_count, 'bug(s) to project', lc_default_prj.
ELSE.
  ROLLBACK WORK.
  WRITE: / 'ERROR: Update failed. Rolled back.'.
ENDIF.

" ── Step 4: Verify ──
SELECT COUNT(*) FROM zbug_tracker
  WHERE project_id = @( CONV zde_project_id( '' ) )
    AND is_del <> 'X'.
WRITE: / 'Remaining orphan bugs:', sy-dbcnt.
```

### Option B: List-only (Dry Run)

Nếu chưa muốn gán ngay, chạy report này trước để xem danh sách orphan bugs:

```abap
REPORT z_bug_list_orphan.

SELECT bug_id, title, status, tester_id, dev_id, erdat
  FROM zbug_tracker
  WHERE project_id = @( CONV zde_project_id( '' ) )
    AND is_del <> 'X'
  INTO TABLE @DATA(lt_orphans).

IF lt_orphans IS INITIAL.
  WRITE: / 'No orphan bugs found.'.
ELSE.
  WRITE: / 'Orphan bugs (no PROJECT_ID):', lines( lt_orphans ).
  SKIP.
  LOOP AT lt_orphans ASSIGNING FIELD-SYMBOL(<o>).
    WRITE: / <o>-bug_id, <o>-title, <o>-status, <o>-tester_id, <o>-dev_id, <o>-erdat.
  ENDLOOP.
ENDIF.
```

### Khi nào chạy?

- Chạy **1 lần duy nhất** sau khi Phase A hoàn tất (tables đã có `PROJECT_ID` field)
- Chạy **trước** Phase C go-live (trước khi users bắt đầu dùng Project-first flow)
- Sau khi chạy, verify: `SELECT COUNT(*) FROM zbug_tracker WHERE project_id = '' AND is_del <> 'X'` → phải = 0

> Checkpoint: Chạy `Z_BUG_CLEANUP_ORPHAN` (hoặc list trước rồi cleanup) → tất cả bugs đều có `PROJECT_ID` → Project ALV → click LEGACY → thấy tất cả bugs cũ.

---

## TỔNG KẾT PHASE D

Sau khi hoàn thành Phase D, bạn phải có:

- [ ] Excel template `ZTEMPLATE_PROJECT` trên SMW0
- [ ] Download Template button (`DN_TMPL`) hoạt động trên Screen 0400 (với fallback SAP_OBJ_READ)
- [ ] Upload Excel (`UPLOAD`) → validate PM role + duplicate check + date parsing → insert `ZBUG_PROJECT` + auto-refresh ALV
- [ ] Message Class `ZBUG_MSG` dùng xuyên suốt (không còn hardcode)
- [ ] Orphan bugs cleanup — tất cả bugs có `PROJECT_ID` (no orphans)

**Lưu ý:** Dashboard Statistics (D5 trong phiên bản cũ) đã **cancelled** — Screen 0100 (Homepage) deprecated trong flow mới. Nếu cần statistics sau này, có thể implement trực tiếp trên Screen 0400 toolbar hoặc popup report riêng.

Chuyển sang **Phase E: Testing & Go-Live**
