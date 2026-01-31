# HƯỚNG DẪN TRIỂN KHAI CHO DEVELOPER

**Dự án:** SAP Bug Tracking Management System  
**Đối tượng:** Developer chưa có kinh nghiệm SAP hoặc chưa setup môi trường  
**Ngày:** 31/01/2026  
**Phiên bản:** 1.0

---

## 📋 MỤC LỤC

- [Phase 0: Chuẩn Bị Môi Trường](#phase-0-chuẩn-bị-môi-trường)
- [Phase 1: Database Layer](#phase-1-database-layer-tuần-1)
- [Phase 2: Business Logic Layer](#phase-2-business-logic-layer-tuần-2-3)
- [Phase 3: Presentation Layer](#phase-3-presentation-layer-tuần-2-3)
- [Phase 4: Reporting Module](#phase-4-reporting-module-tuần-4-5)
- [Phase 5: Testing & Deployment](#phase-5-testing--deployment-tuần-6-8)

---

## PHASE 0: CHUẨN BỊ MÔI TRƯỜNG

> **Thời gian:** Trước khi bắt đầu Week 1  
> **Mục tiêu:** Setup đầy đủ môi trường development

### Bước 0.1: Cài Đặt SAP GUI

#### **Download SAP GUI**

1. Truy cập SAP Software Download Center (cần SAP S-User)
2. Download **SAP GUI for Windows 7.70** (hoặc version mới nhất)
3. File cài đặt: `SAPGUI_7.70_*.exe`

#### **Cài Đặt**

```bash
# Chạy file installer
SAPGUI_7.70_*.exe

# Chọn options:
- Installation Type: Custom
- Components:
  ✓ SAP GUI for Windows
  ✓ SAP GUI Scripting
  ✓ SAP Business Explorer
```

#### **Verify Installation**

- Mở **SAP Logon** từ Start Menu
- Nếu thấy giao diện SAP Logon → Cài đặt thành công

---

### Bước 0.2: Cấu Hình Kết Nối SAP

#### **Thông Tin Kết Nối**

Từ `requirements.md`, ta có:

```
System ID: S40
Application Server: S40Z
Instance Number: 00
SAProuter String: /H/sapper
Network: EBS_SAP
```

#### **Tạo Connection trong SAP Logon**

1. Mở **SAP Logon**
2. Click **New** → **Next**
3. Chọn **Custom Application Server**
4. Điền thông tin:

```
Description: S40 - Bug Tracking Development
Application Server: S40Z
Instance Number: 00
System ID: S40
SAProuter String: /H/sapper
```

5. Click **Next** → **Finish**

#### **Test Connection**

1. Double-click vào connection `S40`
2. Nhập credentials:
   - **Client:** 100 (hoặc theo hướng dẫn)
   - **User:** Qwer123@
   - **Password:** [Nhập password]
   - **Language:** EN
3. Click **Log On**

**✅ Success:** Nếu vào được SAP Easy Access screen → Connection OK

**❌ Error:** Nếu lỗi kết nối:

- Kiểm tra VPN (nếu work from home)
- Kiểm tra firewall
- Liên hệ SAP Basis team

---

### Bước 0.3: Verify Permissions

#### **Check Development Permissions**

Sau khi login SAP, verify các T-code sau:

| T-code | Mô tả                   | Expected Result       |
| ------ | ----------------------- | --------------------- |
| `SE11` | ABAP Dictionary         | Mở được màn hình SE11 |
| `SE38` | ABAP Editor             | Mở được màn hình SE38 |
| `SE80` | Object Navigator        | Mở được màn hình SE80 |
| `SE93` | Transaction Maintenance | Mở được màn hình SE93 |

**Cách check:**

1. Gõ T-code vào command field (góc trên bên trái)
2. Nhấn Enter
3. Nếu mở được → Permission OK
4. Nếu báo lỗi "No authorization" → Liên hệ SAP Security team

---

### Bước 0.4: Request Developer Key

#### **Check Developer Key**

1. Vào T-code `SE38`
2. Nhập program name: `ZTEST_DEVKEY`
3. Click **Create**
4. Chọn **Executable Program** → Enter

**Nếu xuất hiện popup "Developer Key Required":**

- Bạn chưa có Developer Key → Cần request

**Nếu vào được ABAP Editor:**

- Bạn đã có Developer Key → Skip bước này

#### **Request Developer Key**

1. Copy **Installation Number** từ popup (hoặc T-code `SLICENSE`)
2. Truy cập: https://go.support.sap.com/minisap/#/minisap
3. Login bằng SAP S-User
4. Request Developer Key với:
   - Installation Number
   - Username: Qwer123@
5. Nhận key qua email (thường trong vài phút)
6. Paste key vào popup trong SAP

---

### Bước 0.5: Create Package

#### **Tạo Package ZBUGTRACK**

1. Vào T-code `SE80`
2. Dropdown chọn **Package**
3. Nhập: `ZBUGTRACK`
4. Click **Create** (icon tạo mới)
5. Điền thông tin:

```
Package: ZBUGTRACK
Short Description: Bug Tracking Management System
Application Component: (để trống hoặc chọn Z-component)
Software Component: HOME (local objects)
```

6. Click **Save**
7. Chọn **Local Object** (hoặc assign Transport Request nếu có)

**✅ Checkpoint:** Package `ZBUGTRACK` xuất hiện trong SE80

---

## PHASE 1: DATABASE LAYER (Tuần 1)

> **Mục tiêu:** Tạo bảng `ZBUG_TRACKER` và các Data Dictionary objects

### Bước 1.1: Tạo Domains

#### **Domain 1: ZDOM_BUG_ID**

1. Vào T-code `SE11`
2. Chọn radio button **Domain**
3. Nhập: `ZDOM_BUG_ID`
4. Click **Create**
5. Tab **Definition**:

```
Data Type: CHAR
No. Characters: 10
Output Length: 10
```

6. Tab **Value Range**: (để trống)
7. Click **Save** → Assign to package `ZBUGTRACK`
8. Click **Activate** (icon đèn giao thông)

**✅ Checkpoint:** Domain status = Active (màu xanh)

#### **Tạo Các Domains Còn Lại**

Lặp lại quy trình trên cho các domains sau:

| Domain          | Data Type | Length | Description |
| --------------- | --------- | ------ | ----------- |
| `ZDOM_TITLE`    | CHAR      | 100    | Bug title   |
| `ZDOM_LONGTEXT` | STRG      | -      | Long text   |
| `ZDOM_MODULE`   | CHAR      | 20     | SAP module  |
| `ZDOM_PRIORITY` | CHAR      | 1      | Priority    |
| `ZDOM_STATUS`   | CHAR      | 1      | Status      |
| `ZDOM_USER`     | CHAR      | 12     | Username    |
| `ZDOM_DATE`     | DATS      | 8      | Date        |
| `ZDOM_TIME`     | TIMS      | 6      | Time        |

**💡 Tip:** Với `ZDOM_PRIORITY` và `ZDOM_STATUS`, thêm **Fixed Values** trong tab Value Range:

**ZDOM_PRIORITY:**

```
H - High
M - Medium
L - Low
```

**ZDOM_STATUS:**

```
1 - New
2 - Assigned
3 - In Progress
4 - Fixed
5 - Closed
```

---

### Bước 1.2: Tạo Data Elements

#### **Data Element 1: ZDE_BUG_ID**

1. Vào T-code `SE11`
2. Chọn radio button **Data Type**
3. Nhập: `ZDE_BUG_ID`
4. Click **Create**
5. Chọn **Data Element** → Enter
6. Tab **Data Type**:

```
Domain: ZDOM_BUG_ID
```

7. Tab **Field Label**:

```
Short: Bug ID
Medium: Bug ID
Long: Bug Tracking ID
Heading: Bug ID
```

8. Click **Save** → Package `ZBUGTRACK`
9. Click **Activate**

#### **Tạo Các Data Elements Còn Lại**

| Data Element       | Domain        | Short Label | Medium Label | Long Label           |
| ------------------ | ------------- | ----------- | ------------ | -------------------- |
| `ZDE_BUG_TITLE`    | ZDOM_TITLE    | Title       | Bug Title    | Bug Title            |
| `ZDE_BUG_DESC`     | ZDOM_LONGTEXT | Desc        | Description  | Detailed Description |
| `ZDE_SAP_MODULE`   | ZDOM_MODULE   | Module      | SAP Module   | SAP Module           |
| `ZDE_PRIORITY`     | ZDOM_PRIORITY | Priority    | Priority     | Priority Level       |
| `ZDE_BUG_STATUS`   | ZDOM_STATUS   | Status      | Bug Status   | Bug Status           |
| `ZDE_USERNAME`     | ZDOM_USER     | User        | Username     | SAP Username         |
| `ZDE_CREATED_DATE` | ZDOM_DATE     | Created     | Created Date | Created Date         |
| `ZDE_CREATED_TIME` | ZDOM_TIME     | Time        | Created Time | Created Time         |
| `ZDE_CLOSED_DATE`  | ZDOM_DATE     | Closed      | Closed Date  | Closed Date          |

---

### Bước 1.3: Tạo Bảng ZBUG_TRACKER

#### **Create Table**

1. Vào T-code `SE11`
2. Chọn radio button **Database table**
3. Nhập: `ZBUG_TRACKER`
4. Click **Create**
5. Tab **Delivery and Maintenance**:

```
Delivery Class: A (Application table)
Data Browser/Table View Maint.: Display/Maintenance Allowed
```

6. Tab **Fields**:

| Field Name   | Key | Data Element     | Short Description |
| ------------ | --- | ---------------- | ----------------- |
| MANDT        | ✓   | MANDT            | Client            |
| BUG_ID       | ✓   | ZDE_BUG_ID       | Bug ID            |
| TITLE        |     | ZDE_BUG_TITLE    | Bug Title         |
| DESC_TEXT    |     | ZDE_BUG_DESC     | Description       |
| MODULE       |     | ZDE_SAP_MODULE   | SAP Module        |
| PRIORITY     |     | ZDE_PRIORITY     | Priority          |
| STATUS       |     | ZDE_BUG_STATUS   | Status            |
| REPORTER     |     | ZDE_USERNAME     | Reporter          |
| DEV_ID       |     | ZDE_USERNAME     | Developer         |
| CREATED_AT   |     | ZDE_CREATED_DATE | Created Date      |
| CREATED_TIME |     | ZDE_CREATED_TIME | Created Time      |
| CLOSED_AT    |     | ZDE_CLOSED_DATE  | Closed Date       |

7. Tab **Technical Settings**:

```
Data Class: APPL0 (Master data)
Size Category: 1 (0-10,000 records)
```

8. Click **Save** → Package `ZBUGTRACK`
9. Click **Activate**

**✅ Checkpoint:** Table status = Active

---

### Bước 1.4: Tạo Number Range Object

#### **Create Number Range**

1. Vào T-code `SNRO`
2. Object: `ZNRO_BUG`
3. Click **Create** (F5)
4. Điền:

```
Object: ZNRO_BUG
Short Text: Bug ID Number Range
```

5. Click **Save**
6. Click **Number Ranges** button
7. Click **Insert Interval** (F6)
8. Điền:

```
No: 01
From Number: 0000001
To Number: 9999999
Current Number: (để trống)
Ext: (unchecked)
```

9. Click **Save**

**✅ Checkpoint:** Number range created

---

### Bước 1.5: Test Database

#### **Insert Test Data**

1. Vào T-code `SE16N`
2. Table: `ZBUG_TRACKER`
3. Click **Create** (nếu không có, dùng `SM30`)
4. Nhập test data:

```
BUG_ID: BUG0000001
TITLE: Test Bug
DESC_TEXT: This is a test bug
MODULE: SD
PRIORITY: H
STATUS: 1
REPORTER: (your username)
CREATED_AT: (today's date)
```

5. Click **Save**

**✅ Checkpoint:** Data saved successfully

---

## PHASE 2: BUSINESS LOGIC LAYER (Tuần 2-3)

> **Mục tiêu:** Tạo Function Group và CRUD logic

### Bước 2.1: Tạo Function Group

#### **Create Function Group ZBUG_FG**

1. Vào T-code `SE80`
2. Dropdown chọn **Function Group**
3. Nhập: `ZBUG_FG`
4. Click **Create**
5. Điền:

```
Function Group: ZBUG_FG
Short Text: Bug Tracking Function Group
```

6. Click **Save** → Package `ZBUGTRACK`

---

### Bước 2.2: Tạo Function Module - Create Bug

#### **Function: Z_BUG_CREATE**

1. Trong SE80, right-click `ZBUG_FG` → Create → Function Module
2. Function Module: `Z_BUG_CREATE`
3. Short Text: `Create New Bug`

#### **Import Parameters**

| Parameter   | Type | Associated Type | Description          |
| ----------- | ---- | --------------- | -------------------- |
| IV_TITLE    | TYPE | ZDE_BUG_TITLE   | Bug title            |
| IV_DESC     | TYPE | ZDE_BUG_DESC    | Description          |
| IV_MODULE   | TYPE | ZDE_SAP_MODULE  | Module               |
| IV_PRIORITY | TYPE | ZDE_PRIORITY    | Priority             |
| IV_DEV_ID   | TYPE | ZDE_USERNAME    | Developer (optional) |

#### **Export Parameters**

| Parameter  | Type | Associated Type | Description      |
| ---------- | ---- | --------------- | ---------------- |
| EV_BUG_ID  | TYPE | ZDE_BUG_ID      | Generated Bug ID |
| EV_SUCCESS | TYPE | CHAR1           | Success flag     |
| EV_MESSAGE | TYPE | STRING          | Message          |

#### **Source Code**

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
*"  EXPORTING
*"     VALUE(EV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: lv_number TYPE i,
        ls_bug    TYPE zbug_tracker.

  " Validation
  IF iv_title IS INITIAL.
    ev_success = 'N'.
    ev_message = 'Title is mandatory'.
    RETURN.
  ENDIF.

  IF strlen( iv_title ) < 10.
    ev_success = 'N'.
    ev_message = 'Title must be at least 10 characters'.
    RETURN.
  ENDIF.

  " Generate Bug ID
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr = '01'
      object      = 'ZNRO_BUG'
    IMPORTING
      number      = lv_number
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Failed to generate Bug ID'.
    RETURN.
  ENDIF.

  " Format Bug ID
  ev_bug_id = |BUG{ lv_number WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.

  " Prepare data
  ls_bug-mandt        = sy-mandt.
  ls_bug-bug_id       = ev_bug_id.
  ls_bug-title        = iv_title.
  ls_bug-desc_text    = iv_desc.
  ls_bug-module       = iv_module.
  ls_bug-priority     = iv_priority.
  ls_bug-status       = '1'.  " New
  ls_bug-reporter     = sy-uname.
  ls_bug-dev_id       = iv_dev_id.
  ls_bug-created_at   = sy-datum.
  ls_bug-created_time = sy-uzeit.

  " Insert to database
  INSERT zbug_tracker FROM ls_bug.

  IF sy-subrc = 0.
    COMMIT WORK.
    ev_success = 'Y'.
    ev_message = |Bug { ev_bug_id } created successfully|.
  ELSE.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Failed to save bug to database'.
  ENDIF.

ENDFUNCTION.
```

4. Click **Save** → **Activate**

---

### Bước 2.3: Tạo Function Module - Update Status

#### **Function: Z_BUG_UPDATE_STATUS**

```abap
FUNCTION z_bug_update_status.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_NEW_STATUS) TYPE  ZDE_BUG_STATUS
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug TYPE zbug_tracker.

  " Check if bug exists
  SELECT SINGLE * FROM zbug_tracker INTO ls_bug
    WHERE bug_id = iv_bug_id.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Bug not found'.
    RETURN.
  ENDIF.

  " Update status
  UPDATE zbug_tracker
    SET status = iv_new_status
        closed_at = CASE WHEN iv_new_status = '5'
                         THEN sy-datum
                         ELSE closed_at END
    WHERE bug_id = iv_bug_id.

  IF sy-subrc = 0.
    COMMIT WORK.
    ev_success = 'Y'.
    ev_message = 'Status updated successfully'.
  ELSE.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Failed to update status'.
  ENDIF.

ENDFUNCTION.
```

---

### Bước 2.4: Email Configuration

#### **Setup SMTP (T-code SCOT)**

1. Vào T-code `SCOT`
2. Click **Settings** → **Default Domain**
3. Nhập domain email (e.g., `company.com`)
4. Click **SMTP** node → **Create**
5. Điền:

```
Mail Host: smtp.company.com (hoặc IP)
Port: 25 (hoặc 587)
```

6. Click **Save**
7. Test bằng T-code `SBWP` (SAP Business Workplace)

#### **Function: Z_BUG_SEND_EMAIL**

```abap
FUNCTION z_bug_send_email.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_RECIPIENT) TYPE  AD_SMTPADR
*"----------------------------------------------------------------------

  DATA: lo_send_request TYPE REF TO cl_bcs,
        lo_document     TYPE REF TO cl_document_bcs,
        lo_recipient    TYPE REF TO if_recipient_bcs,
        lv_subject      TYPE so_obj_des,
        lt_text         TYPE bcsy_text,
        ls_bug          TYPE zbug_tracker.

  " Get bug details
  SELECT SINGLE * FROM zbug_tracker INTO ls_bug
    WHERE bug_id = iv_bug_id.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Prepare email content
  lv_subject = |New Bug: { ls_bug-title }|.

  APPEND |Bug ID: { ls_bug-bug_id }| TO lt_text.
  APPEND |Title: { ls_bug-title }| TO lt_text.
  APPEND |Module: { ls_bug-module }| TO lt_text.
  APPEND |Priority: { ls_bug-priority }| TO lt_text.
  APPEND |Reporter: { ls_bug-reporter }| TO lt_text.
  APPEND |Description: { ls_bug-desc_text }| TO lt_text.

  TRY.
      " Create send request
      lo_send_request = cl_bcs=>create_persistent( ).

      " Create document
      lo_document = cl_document_bcs=>create_document(
        i_type    = 'RAW'
        i_text    = lt_text
        i_subject = lv_subject ).

      lo_send_request->set_document( lo_document ).

      " Add recipient
      lo_recipient = cl_cam_address_bcs=>create_internet_address( iv_recipient ).
      lo_send_request->add_recipient( lo_recipient ).

      " Send email
      lo_send_request->send( ).
      COMMIT WORK.

    CATCH cx_bcs INTO DATA(lx_bcs).
      " Log error
      WRITE: / 'Email send failed:', lx_bcs->get_text( ).
  ENDTRY.

ENDFUNCTION.
```

---

## PHASE 3: PRESENTATION LAYER (Tuần 2-3)

> **Mục tiêu:** Tạo màn hình nhập liệu

### Bước 3.1: Tạo Report Program

#### **Create Program Z_BUG_CREATE_SCREEN**

1. Vào T-code `SE38`
2. Program: `Z_BUG_CREATE_SCREEN`
3. Click **Create**
4. Type: **Executable Program**
5. Source code:

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_CREATE_SCREEN
*&---------------------------------------------------------------------*
REPORT z_bug_create_screen.

TABLES: zbug_tracker.

" Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_title  TYPE zde_bug_title OBLIGATORY,
              p_module TYPE zde_sap_module OBLIGATORY,
              p_prior  TYPE zde_priority DEFAULT 'M',
              p_devid  TYPE zde_username.
  SELECTION-SCREEN SKIP 1.
  PARAMETERS: p_desc TYPE zde_bug_desc LOWER CASE OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

" Text symbols
TEXT-001: 'Create New Bug'.

START-OF-SELECTION.

  DATA: lv_bug_id  TYPE zde_bug_id,
        lv_success TYPE char1,
        lv_message TYPE string.

  " Call function to create bug
  CALL FUNCTION 'Z_BUG_CREATE'
    EXPORTING
      iv_title    = p_title
      iv_desc     = p_desc
      iv_module   = p_module
      iv_priority = p_prior
      iv_dev_id   = p_devid
    IMPORTING
      ev_bug_id   = lv_bug_id
      ev_success  = lv_success
      ev_message  = lv_message.

  IF lv_success = 'Y'.
    MESSAGE lv_message TYPE 'S'.

    " Send email notification
    CALL FUNCTION 'Z_BUG_SEND_EMAIL'
      EXPORTING
        iv_bug_id    = lv_bug_id
        iv_recipient = 'developer@company.com'.
  ELSE.
    MESSAGE lv_message TYPE 'E'.
  ENDIF.
```

6. Click **Save** → **Activate**

---

### Bước 3.2: Tạo T-code

#### **Create T-code ZBUG_CREATE**

1. Vào T-code `SE93`
2. Transaction Code: `ZBUG_CREATE`
3. Click **Create**
4. Chọn **Program and Selection Screen (Report Transaction)**
5. Điền:

```
Program: Z_BUG_CREATE_SCREEN
Screen Number: 1000 (default)
```

6. Click **Save**

**✅ Checkpoint:** Test T-code `ZBUG_CREATE` → Màn hình nhập liệu hiển thị

---

## PHASE 4: REPORTING MODULE (Tuần 4-5)

### Bước 4.1: Tạo ALV Report

#### **Program: Z_BUG_REPORT_ALV**

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_REPORT_ALV
*&---------------------------------------------------------------------*
REPORT z_bug_report_alv.

TABLES: zbug_tracker.

" Selection Screen
SELECT-OPTIONS: s_bugid FOR zbug_tracker-bug_id,
                s_status FOR zbug_tracker-status,
                s_module FOR zbug_tracker-module,
                s_prior FOR zbug_tracker-priority.

" Internal table
DATA: lt_bugs TYPE TABLE OF zbug_tracker,
      ls_bug  TYPE zbug_tracker.

" ALV
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv.

START-OF-SELECTION.

  " Fetch data
  SELECT * FROM zbug_tracker INTO TABLE lt_bugs
    WHERE bug_id IN s_bugid
      AND status IN s_status
      AND module IN s_module
      AND priority IN s_prior
    ORDER BY created_at DESCENDING.

  IF lt_bugs IS INITIAL.
    MESSAGE 'No bugs found' TYPE 'S'.
    RETURN.
  ENDIF.

  " Build field catalog
  PERFORM build_fieldcat.

  " Display ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = lt_fieldcat
    TABLES
      t_outtab           = lt_bugs
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

*&---------------------------------------------------------------------*
*& Form build_fieldcat
*&---------------------------------------------------------------------*
FORM build_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'BUG_ID'.
  ls_fieldcat-seltext_m = 'Bug ID'.
  ls_fieldcat-col_pos = 1.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'TITLE'.
  ls_fieldcat-seltext_m = 'Title'.
  ls_fieldcat-col_pos = 2.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'MODULE'.
  ls_fieldcat-seltext_m = 'Module'.
  ls_fieldcat-col_pos = 3.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'PRIORITY'.
  ls_fieldcat-seltext_m = 'Priority'.
  ls_fieldcat-col_pos = 4.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'STATUS'.
  ls_fieldcat-seltext_m = 'Status'.
  ls_fieldcat-col_pos = 5.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'REPORTER'.
  ls_fieldcat-seltext_m = 'Reporter'.
  ls_fieldcat-col_pos = 6.
  APPEND ls_fieldcat TO lt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CREATED_AT'.
  ls_fieldcat-seltext_m = 'Created'.
  ls_fieldcat-col_pos = 7.
  APPEND ls_fieldcat TO lt_fieldcat.
ENDFORM.
```

#### **Create T-code ZBUG_REPORT**

1. T-code `SE93`
2. Transaction: `ZBUG_REPORT`
3. Program: `Z_BUG_REPORT_ALV`

---

### Bước 4.2: SmartForms

#### **Create SmartForm ZBUG_FORM**

1. Vào T-code `SMARTFORMS`
2. Form Name: `ZBUG_FORM`
3. Click **Create**
4. Thiết kế layout:
   - **Page**: FIRST
   - **Window**: MAIN
   - **Text**: Add bug details

(Chi tiết SmartForms design cần workshop riêng)

---

## PHASE 5: TESTING & DEPLOYMENT (Tuần 6-8)

### Bước 5.1: Code Inspector

1. Vào T-code `SCI`
2. Create inspection với variant `DEFAULT`
3. Add programs: `Z_BUG_*`
4. Execute → Fix all errors/warnings

### Bước 5.2: Transport Request

1. Vào T-code `SE09`
2. Create Transport Request
3. Add all objects từ package `ZBUGTRACK`
4. Release Transport

### Bước 5.3: UAT Checklist

- [ ] Create bug successfully
- [ ] Email sent to developer
- [ ] ALV report displays correctly
- [ ] Update status works
- [ ] SmartForm prints correctly
- [ ] Performance acceptable (< 2s response)

---

## 🎯 HOÀN THÀNH!

Chúc mừng! Bạn đã hoàn thành hệ thống SAP Bug Tracking Management.

**Next Steps:**

- Deploy to Production
- Train end users
- Monitor system performance
- Collect feedback for improvements

---

**Prepared by:** [Your Name]  
**Last Updated:** 31/01/2026
