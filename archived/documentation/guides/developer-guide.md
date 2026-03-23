# HƯỚNG DẪN TRIỂN KHAI CHO DEVELOPER

**Dự án:** SAP Bug Tracking Management System
**Đối tượng:** Developer chưa có kinh nghiệm SAP hoặc chưa setup môi trường
**Ngày cập nhật:** 07/03/2026
**Phiên bản:** 3.0 (Phase 6/7/8 Detailed Expansion)

---

## 📋 MỤC LỤC

- [Phase 0: Chuẩn Bị Môi Trường](#phase-0-chuẩn-bị-môi-trường)
- [Ma Trận Sử Dụng Tài Khoản (Account Matrix)](#ma-trận-sử-dụng-tài-khoản-account-matrix)
- [Phase 1: Database Layer](#phase-1-database-layer-tuần-1)
- [Phase 2: Business Logic Layer](#phase-2-business-logic-layer-tuần-2-3) ✅ Hoàn thành
- [Phase 3: Presentation Layer](#phase-3-presentation-layer-tuần-2-3) ⏳ Đang thực hiện
- [Phase 4: ALV Report](#phase-4-alv-report-tuần-4-5)
- [Phase 5: Advanced Function Modules](#phase-5-advanced-function-modules-nâng-cao)
- [Phase 6: Testing & Optimization](#phase-6-testing--optimization-tuần-6)
- [Phase 7: Deployment & Training](#phase-7-deployment--training-tuần-7-8)
- [Phase 8: Final Presentation](#phase-8-final-presentation-295-2026)

---

## MA TRẬN SỬ DỤNG TÀI KHOẢN (ACCOUNT MATRIX)

Vì hệ thống S40 phân tách quyền hạn theo chức năng (Role-based), bạn cần sử dụng đúng tài khoản cho từng giai đoạn:

| Phase | Đối tượng | Tài khoản (Account) | Chức năng chính |
| :--- | :--- | :--- | :--- |
| **Phase 0** | **Setup/Verify** | **DEV-118** | Quản lý lỗi & Kiểm tra hệ thống |
| **Phase 1** | **Database** | **DEV-089** | Tạo bảng, domain, data element (SE11) |
| **Phase 2** | **Business Logic** | **DEV-089** | Viết code ABAP (SE38/SE80) |
| **Phase 3** | **Presentation** | **DEV-061** | ALV Grid & SmartForms |
| **Phase 4** | **Reporting** | **DEV-061** | Design Forms & ALV Reports |
| **Phase 5** | **Integration** | **DEV-237** | Đính kèm file (GOS) |
| **Phase 5** | **Email** | **DEV-242** | Cấu hình Email (SCOT) |
| **Phase 6** | **Testing** | **DEV-118** | Code Inspector, Unit Testing, Performance Testing |
| **Phase 7** | **Deployment** | **DEV-118** | Transport Request, Deployment Checklist |
| **Phase 8** | **Presentation** | **DEV-118** | Final Testing, Project Summary, Handover |

> [!IMPORTANT]
> Tất cả tài khoản `DEV-*` đều đã được cấp **Developer Key**. Nếu hệ thống yêu cầu Key khi tạo Object mới, hãy kiểm tra lại xem bạn có đang đăng nhập đúng tài khoản được phân công hay không.

---

## PHASE 0: CHUẨN BỊ MÔI TRƯỜNG

> **Thời gian:** Trước khi bắt đầu Week 1  
> **Mục tiêu:** Setup đầy đủ môi trường development

### Bước 0.1: Cài Đặt SAP GUI

Tải và cài đặt **SAP GUI for Windows/macOS 7.70+** tùy thuộc hệ điều hành. Đảm bảo bạn đã cài đặt để có thể mở **SAP Logon**.

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
2. Cấu hình Connection mới sử dụng **Expert Mode** (nếu cần) hoặc **Custom Application Server**.
3. Điền thông tin kết nối:

```
Description: S40 - Bug Tracking Development
Application Server: S40Z
Instance Number: 00
System ID: S40
SAProuter String: /H/saprouter.hcc.in.tum.de/S/3298
Chuỗi Expert Mode Route (nếu dùng): conn=/H/saprouter.hcc.in.tum.de/S/3298/H/S40Z/S/3200
```

1. Click **Next** → **Finish**

#### **Test Connection**

1. Double-click vào connection `S40`
2. Nhập credentials:
   - **Client:** 324
   - **User:** DEV-118 (hoặc các user DEV-* khác tương ứng)
   - **Password:** Qwer123@
   - **Language:** EN
3. Click **Log On**

**✅ Success:** Nếu vào được SAP Easy Access screen → Connection OK.

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

### Bước 0.4: Create Package

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

1. Click **Save**
2. Chọn **Local Object** (hoặc assign Transport Request nếu có)

**✅ Checkpoint:** Package `ZBUGTRACK` xuất hiện trong SE80

---

## PHASE 1: DATABASE LAYER (Tuần 1)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-089** (Pass: `@Anhtuoi123`)  
> Đây là tài khoản có quyền SE11 để tạo các Z-objects cơ bản cho Database.

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

1. Tab **Value Range**: (để trống)
2. Click **Save** → Assign to package `ZBUGTRACK`
   - Khi hiện pop-up **Prompt for transportable workbench request**:
   - Nếu chưa có Request, nhấn icon **Create (tờ giấy trắng)**.
   - **Short Description:** `BUG_TRACKING_DATABASE_SETUP`
   - Nhấn **Save** để lấy mã Request (ví dụ: `S40K9...`).
   - Nhấn **Continue (tích xanh)**.
3. Click **Activate** (icon đèn giao thông - Ctrl+F3)
   - Chọn object và nhấn **Enter**.

**✅ Checkpoint:** Domain status = Active (màu xanh) - Thông báo "No inconsistencies found" chỉ là kiểm tra cú pháp, bạn **BẮT BUỘC** phải nhấn Activate để hoàn tất.

> [!IMPORTANT]
> **QUY TẮC VÀNG VỀ TRANSPORT REQUEST (TR):**
>
> 1. Tất cả các Domain trong cùng một Phase **PHẢI** nằm trong cùng **một Request** và cùng **một Task** (thư mục con).
> 2. Khi nhấn **Save** cho các domain tiếp theo: **KHÔNG** tạo Request mới. Hãy nhấn nút **Own Requests** (icon xe tải), tìm và chọn đúng cái Request đã tạo ở Domain 1.
> 3. Nếu bạn lưu rời rạc, SAP sẽ báo lỗi `Object locked in inconsistent task` khi bạn cố gắng Activate hàng loạt.

#### **Tạo Các Domains Còn Lại**

Lặp lại quy trình trên cho các domains sau:

| Domain | Data Type | Length | Description | Fixed Values (Tab: Value Range) |
| :--- | :--- | :--- | :--- | :--- |
| `ZDOM_TITLE` | CHAR | 100 | Bug title | (Để trống) |
| `ZDOM_LONGTEXT` | STRING | - | Long text | (Để trống) |
| `ZDOM_MODULE` | CHAR | 20 | SAP module | (Để trống) |
| `ZDOM_PRIORITY` | CHAR | 1 | Priority | H: High, M: Medium, L: Low |
| `ZDOM_STATUS` | CHAR | 1 | Status | 1: New, W: Waiting, 2: Assigned, 3: InProgress, 4: Fixed, 5: Closed, 6: Deleted |
| `ZDOM_USER` | CHAR | 12 | Username | (Để trống) |
| `ZDOM_DATE` | DATS | 8 | Date | (Để trống) |
| `ZDOM_TIME` | TIMS | 6 | Time | (Để trống) |
| `ZDOM_ROLE` | CHAR | 1 | Role | T: Tester, D: Developer, M: Manager |
| `ZDOM_AVAIL_STATUS` | CHAR | 1 | Available status | A: Available, B: Busy, L: Leave, W: Working |
| `ZDOM_BUG_TYPE` | CHAR | 1 | Bug Type | C: Code, F: Configuration |
| `ZDOM_ACTION_TYPE` | CHAR | 2 | Action Type | CR: Create, AS: Assign, RS: Reassign, ST: Status |
| `ZDOM_ATT_PATH` | CHAR | 100 | Attachment Path | (Để trống) |

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

1. Tab **Field Label**:

```
Short: Bug ID
Medium: Bug ID
Long: Bug Tracking ID
Heading: Bug ID
```

1. Click **Save** → Package `ZBUGTRACK`
2. Click **Activate**

> [!CAUTION]
> **Tính thống nhất của TR:**
> Tương tự như Domain, tất cả **Data Elements** này cũng phải được lưu vào **cùng một Request và Task** với các Domain ở bước 1.1. Điều này đảm bảo toàn bộ Database Layer của Phase 1 có thể được vận chuyển và kích hoạt đồng bộ.
>
> - Luôn dùng nút **Own Requests** để chọn Request hiện có.

#### **Tạo Các Data Elements Còn Lại**

| Data Element       | Domain        | Short Label | Medium Label | Long Label           |
| ------------------ | ------------- | ----------- | ------------ | -------------------- |
| `ZDE_BUG_TITLE`    | ZDOM_TITLE    | Title       | Bug Title    | Bug Title            |
| `ZDE_BUG_DESC`     | ZDOM_LONGTEXT | Desc        | Description  | Detailed Description |
| `ZDE_REASONS`      | ZDOM_LONGTEXT | Reasons     | Root Causes  | Root Causes          |
| `ZDE_SAP_MODULE`   | ZDOM_MODULE   | Module      | SAP Module   | SAP Module           |
| `ZDE_PRIORITY`     | ZDOM_PRIORITY | Priority    | Priority     | Priority Level       |
| `ZDE_BUG_STATUS`   | ZDOM_STATUS   | Status      | Bug Status   | Bug Status           |
| `ZDE_USERNAME`     | ZDOM_USER     | User        | Username     | SAP Username         |
| `ZDE_BUG_ROLE`     | ZDOM_ROLE     | Role        | Role         | SAP Role             |
| `ZDE_AVAIL_STATUS` | ZDOM_AVAIL_STATUS| AvailStatus | Avail Status | Available Status     |
| `ZDE_BUG_TYPE`     | ZDOM_BUG_TYPE | BugType     | Bug Type     | Bug Type             |
| `ZDE_BUG_ACT_TYPE`  | ZDOM_ACTION_TYPE | Action   | Action Type  | Action Type          |
| `ZDE_BUG_ATT_PATH` | ZDOM_ATT_PATH | Att Path    | Attachment   | Attachment Path      |
| `ZDE_BUG_FULL_NAME` | (CHAR 50)     | Name        | Full Name    | Full Name            |
| `ZDE_BUG_EMAIL`    | (CHAR 100)    | Email       | Email Adr    | Email Address        |
| `ZDE_BUG_APP_DATE` | ZDOM_DATE     | Approved    | Approve Date | Approved Date        |
| `ZDE_BUG_CR_DATE`  | ZDOM_DATE     | Created     | Created Date | Created Date         |
| `ZDE_BUG_CR_TIME`  | ZDOM_TIME     | Time        | Created Time | Created Time         |
| `ZDE_BUG_CL_DATE`  | ZDOM_DATE     | Closed      | Closed Date  | Closed Date          |

---

### Bước 1.3: Tạo Bảng ZBUG_TRACKER

#### **Create Table**

1. Vào T-code `SE11`
2. Chọn radio button **Database table**
3. Nhập: `ZBUG_TRACKER`
4. Click **Create**
5. Điền **Short Description**: `Bug Tracking Table`
6. Tab **Delivery and Maintenance**:

```
Delivery Class: A (Application table)
Data Browser/Table View Maint.: Display/Maintenance Allowed
```

1. Tab **Fields**:

| Field Name       | Key | Data Element      |
| ---------------- | --- | ----------------- |
| MANDT            | ✓   | MANDT             |
| BUG_ID           | ✓   | ZDE_BUG_ID        |
| TITLE            |     | ZDE_BUG_TITLE     |
| DESC_TEXT        |     | ZDE_BUG_DESC      |
| SAP_MODULE       |     | ZDE_SAP_MODULE    |
| PRIORITY         |     | ZDE_PRIORITY      |
| STATUS           |     | ZDE_BUG_STATUS    |
| BUG_TYPE         |     | ZDE_BUG_TYPE      |
| REASONS          |     | ZDE_REASONS       |
| TESTER_ID        |     | ZDE_USERNAME      |
| VERIFY_TESTER_ID |     | ZDE_USERNAME      |
| DEV_ID           |     | ZDE_USERNAME      |
| APPROVED_BY      |     | ZDE_USERNAME      |
| APPROVED_AT      |     | ZDE_BUG_APP_DATE  |
| CREATED_AT       |     | ZDE_BUG_CR_DATE   |
| CREATED_TIME     |     | ZDE_BUG_CR_TIME   |
| CLOSED_AT        |     | ZDE_BUG_CL_DATE   |
| ATT_REPORT       |     | ZDE_BUG_ATT_PATH  |
| ATT_FIX          |     | ZDE_BUG_ATT_PATH  |
| ATT_VERIFY       |     | ZDE_BUG_ATT_PATH  |

1. Tab **Technical Settings**:

```
Data Class: APPL0 (Master data)
Size Category: 1 (0-10,000 records)
```

1. Click **Save** → Package `ZBUGTRACK`
2. Click **Activate**

**✅ Checkpoint:** Table `ZBUG_TRACKER` status = Active

---

### Bước 1.4: Tạo Bảng ZBUG_USERS

1. Vào T-code `SE11`, tạo bảng `ZBUG_USERS`.
2. Điền **Short Description**: `Bug Tracking Users`
3. Tab **Delivery and Maintenance**: Maintenance Allowed, Class A.
4. Tab **Fields**:

| Field Name       | Key | Data Element      |
| ---------------- | --- | ----------------- |
| MANDT            | ✓   | MANDT             |
| USER_ID          | ✓   | ZDE_USERNAME      |
| ROLE             |     | ZDE_BUG_ROLE      |
| FULL_NAME        |     | ZDE_BUG_FULL_NAME |
| SAP_MODULE       |     | ZDE_SAP_MODULE    |
| AVAILABLE_STATUS |     | ZDE_AVAIL_STATUS  |![alt text](image.png)
| IS_ACTIVE        |     | CHAR1             |
| EMAIL            |     | ZDE_BUG_EMAIL     |

1. Tab **Technical Settings**: Data Class APPL0, Size 0.
2. Click Save và Activate.

---

### Bước 1.5: Tạo Bảng ZBUG_HISTORY

1. Vào T-code `SE11`, tạo bảng `ZBUG_HISTORY`.
2. Tab **Delivery and Maintenance**: Maintenance Allowed, Class A.
3. Tab **Fields**:

| Field Name   | Key | Data Element     |
| ------------ | --- | ---------------- |
| MANDT        | ✓   | MANDT            |
| LOG_ID       | ✓   | NUMC10           |
| BUG_ID       |     | ZDE_BUG_ID       |
| CHANGED_BY   |     | ZDE_USERNAME     |
| CHANGED_AT   |     | ZDE_BUG_CR_DATE  |
| CHANGED_TIME |     | ZDE_BUG_CR_TIME  |
| ACTION_TYPE  |     | ZDE_BUG_ACT_TYPE |
| OLD_VALUE    |     | ZDE_BUG_TITLE    |
| NEW_VALUE    |     | ZDE_BUG_TITLE    |
| REASON       |     | ZDE_REASONS      |

1. Tab **Technical Settings**: Data Class APPL0, Size 1 (vì log sẽ phình to).
2. Click Save và Activate.

---

### Bước 1.6: Tạo Number Range Object

#### **Create Number Range**

1. Vào T-code `SNRO`
2. Object: `ZNRO_BUG`
3. Click **Create** (F5)
4. Điền thông tin cơ bản:

```
Short Text: Bug ID NR
Long Text: Bug Tracking ID Number Range
Number Length Domain: ZDOM_BUG_ID
% Warning: 10,0
```

1. Click **Save** (Ctrl + S)
2. Nhấn phím **F7** (hoặc Menu: *Goto -> Number Ranges*)
3. Click nút **Intervals** (biểu tượng hình cái Bút)
4. Nhấn phím **F6** (Insert Line) và điền:

```
No: 01
From Number: 0000000001
To Number: 0009999999
Ext: (để trống)
```

1. Click **Save** (Ctrl + S)

**✅ Checkpoint:** Number range created

---

### Bước 1.7: Test Database

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

1. Click **Save**

**✅ Checkpoint:** Data saved successfully

---

## PHASE 2: BUSINESS LOGIC LAYER (Tuần 2-3)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-089** (Pass: `@Anhtuoi123`)  
> Sử dụng tài khoản này để viết code ABAP, Function Modules và Classes.

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

1. Click **Save** → Package `ZBUGTRACK`

---

### Bước 2.2: Tạo Function Module - Create Bug

#### **Function: Z_BUG_CREATE**

1. Trong SE80, right-click `ZBUG_FG` → Create → Function Module
2. Function Module: `Z_BUG_CREATE`
3. Short Text: `Create New Bug`

#### **Import Parameters**

| Parameter   | Typin | Associated Type | Default | Opti | Pass | Description          |
| ----------- | ----- | --------------- | ------- | ---- | ---- | -------------------- |
| IV_TITLE    | TYPE  | ZDE_BUG_TITLE   |         | [ ]  | [x]  | Bug title            |
| IV_DESC     | TYPE  | ZDE_BUG_DESC    |         | [ ]  | [x]  | Description          |
| IV_MODULE   | TYPE  | ZDE_SAP_MODULE  |         | [ ]  | [x]  | Module               |
| IV_PRIORITY | TYPE  | ZDE_PRIORITY    | 'M'     | [x]  | [x]  | Priority             |
| IV_DEV_ID   | TYPE  | ZDE_USERNAME    |         | [x]  | [x]  | Developer (optional) |

#### **Export Parameters**

| Parameter  | Typin | Associated Type | Pass | Description      |
| ---------- | ----- | --------------- | ---- | ---------------- |
| EV_BUG_ID  | TYPE  | ZDE_BUG_ID      | [x]  | Generated Bug ID |
| EV_SUCCESS | TYPE  | CHAR1           | [x]  | Success flag     |
| EV_MESSAGE | TYPE  | STRING          | [x]  | Message          |

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
  ls_bug-sap_module   = iv_module.
  ls_bug-priority     = iv_priority.
  ls_bug-status       = '1'.  " New
  ls_bug-tester_id    = sy-uname.
  ls_bug-dev_id       = iv_dev_id.
  ls_bug-created_at   = sy-datum.
  ls_bug-created_time = sy-uzeit.

  " Insert to database
  INSERT zbug_tracker FROM @ls_bug.

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

1. Click **Save** → **Activate**

---

### Bước 2.3: Tạo Function Module - Update Status

#### **Function: Z_BUG_UPDATE_STATUS**

**Import Parameters**

| Parameter     | Typin | Associated Type | Default | Opti | Pass | Description     |
| ------------- | ----- | --------------- | ------- | ---- | ---- | --------------- |
| IV_BUG_ID     | TYPE  | ZDE_BUG_ID      |         | [ ]  | [x]  | Bug ID          |
| IV_NEW_STATUS | TYPE  | ZDE_BUG_STATUS  |         | [ ]  | [x]  | New status code |
| IV_DEV_ID     | TYPE  | ZDE_USERNAME    |         | [x]  | [x]  | Developer ID    |
| IV_REASON     | TYPE  | ZDE_BUG_DESC    |         | [x]  | [x]  | Change reason   |
| IV_CHANGED_BY | TYPE  | ZDE_USERNAME    |         | [x]  | [x]  | User changing   |

**Export Parameters**

| Parameter  | Typin | Associated Type | Pass | Description |
| ---------- | ----- | --------------- | ---- | ----------- |
| EV_SUCCESS | TYPE  | CHAR1           | [x]  | Y/N flag    |
| EV_MESSAGE | TYPE  | STRING          | [x]  | Message     |

```abap
FUNCTION z_bug_update_status.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_NEW_STATUS) TYPE  ZDE_BUG_STATUS
*"     VALUE(IV_DEV_ID) TYPE  ZDE_USERNAME OPTIONAL
*"     VALUE(IV_REASON) TYPE  ZDE_BUG_DESC OPTIONAL
*"     VALUE(IV_CHANGED_BY) TYPE  ZDE_USERNAME OPTIONAL
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

  " Update status and other fields
  IF iv_new_status = '5'. " 5 = Closed
    UPDATE zbug_tracker
      SET status    = @iv_new_status,
          dev_id    = @iv_dev_id,
          desc_text = @iv_reason,
          closed_at = @sy-datum
      WHERE bug_id = @iv_bug_id.
  ELSE.
    UPDATE zbug_tracker
      SET status    = @iv_new_status,
          dev_id    = @iv_dev_id,
          desc_text = @iv_reason
      WHERE bug_id = @iv_bug_id.
  ENDIF.

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

1. Click **Save** → **Activate** (Ctrl+F3)

---

### Bước 2.4: Tạo Function Module - Get Bug

#### **Function: Z_BUG_GET**

**Import Parameters**

| Parameter | Typin | Associated Type | Opti | Pass | Description |
| --------- | ----- | --------------- | ---- | ---- | ----------- |
| IV_BUG_ID | TYPE  | ZDE_BUG_ID      | [ ]  | [x]  | Bug ID      |

**Export Parameters**

| Parameter  | Typin | Associated Type | Pass | Description         |
| ---------- | ----- | --------------- | ---- | ------------------- |
| ES_BUG     | TYPE  | ZBUG_TRACKER    | [x]  | Bug record (struct) |
| EV_SUCCESS | TYPE  | CHAR1           | [x]  | Y/N flag            |
| EV_MESSAGE | TYPE  | STRING          | [x]  | Message             |

```abap
FUNCTION z_bug_get.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"  EXPORTING
*"     VALUE(ES_BUG) TYPE  ZBUG_TRACKER
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  SELECT SINGLE * FROM zbug_tracker INTO @es_bug
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc = 0.
    ev_success = 'Y'.
  ELSE.
    ev_success = 'N'.
    ev_message = 'Bug not found'.
  ENDIF.

ENDFUNCTION.
```

1. Click **Save** → **Activate** (Ctrl+F3)

---

### Bước 2.5: Tạo Function Module - Delete Bug (Soft Delete)

> [!IMPORTANT]
> **Soft Delete:** FM này KHÔNG xóa dữ liệu vật lý. Thay vào đó, nó cập nhật `STATUS = '6'` (Deleted) để giữ lại lịch sử.

#### **Function: Z_BUG_DELETE**

**Import Parameters**

| Parameter | Typin | Associated Type | Opti | Pass | Description |
| --------- | ----- | --------------- | ---- | ---- | ----------- |
| IV_BUG_ID | TYPE  | ZDE_BUG_ID      | [ ]  | [x]  | Bug ID      |

**Export Parameters**

| Parameter  | Typin | Associated Type | Pass | Description |
| ---------- | ----- | --------------- | ---- | ----------- |
| EV_SUCCESS | TYPE  | CHAR1           | [x]  | Y/N flag    |
| EV_MESSAGE | TYPE  | STRING          | [x]  | Message     |

```abap
FUNCTION z_bug_delete.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug TYPE zbug_tracker.

  " Check if bug exists and is not already deleted
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Bug not found'.
    RETURN.
  ENDIF.

  IF ls_bug-status = '6'.
    ev_success = 'N'.
    ev_message = 'Bug is already deleted'.
    RETURN.
  ENDIF.

  " Soft delete: update status to '6' (Deleted)
  UPDATE zbug_tracker
    SET status   = '6',
        closed_at = @sy-datum
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc = 0.
    COMMIT WORK.
    ev_success = 'Y'.
    ev_message = |Bug { iv_bug_id } marked as deleted (soft delete)|.
  ELSE.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Failed to delete bug'.
  ENDIF.

ENDFUNCTION.
```

1. Click **Save** → **Activate** (Ctrl+F3)

---

### Bước 2.6: Email Configuration

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

1. Click **Save**
2. Test bằng T-code `SBWP` (SAP Business Workplace)

#### **Function: Z_BUG_SEND_EMAIL**

**1. Import Parameters**

| Parameter Name | Typing | Associated Type | Pass Value | Optional | Short Text |
| :--- | :--- | :--- | :---: | :---: | :--- |
| `IV_BUG_ID` | TYPE | `ZDE_BUG_ID` | [x] | [ ] | Bug ID |
| `IV_RECIPIENT` | TYPE | `AD_SMTPADR` | [x] | [ ] | Recipient Email Address |

**2. Source Code**

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
        ls_bug          TYPE zbug_tracker,
        lx_bcs          TYPE REF TO cx_bcs,
        lv_content      TYPE string.

  " Get bug details
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  " Prepare email content (Legacy Compatible)
  CONCATENATE 'New Bug: ' ls_bug-title INTO lv_subject.

  CONCATENATE 'Bug ID: ' ls_bug-bug_id INTO lv_content.
  APPEND lv_content TO lt_text.

  CONCATENATE 'Title: ' ls_bug-title INTO lv_content.
  APPEND lv_content TO lt_text.

  CONCATENATE 'Module: ' ls_bug-sap_module INTO lv_content.
  APPEND lv_content TO lt_text.

  CONCATENATE 'Priority: ' ls_bug-priority INTO lv_content.
  APPEND lv_content TO lt_text.

  CONCATENATE 'Reporter: ' ls_bug-tester_id INTO lv_content.
  APPEND lv_content TO lt_text.

  CONCATENATE 'Description: ' ls_bug-desc_text INTO lv_content.
  APPEND lv_content TO lt_text.

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

    CATCH cx_bcs INTO lx_bcs.
      " Log error
      lv_content = lx_bcs->get_text( ).
      WRITE: / 'Email send failed:', lv_content.
  ENDTRY.

ENDFUNCTION.
```

---

## PHASE 3: PRESENTATION LAYER (Tuần 2-3)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-061** (Pass: `@57Dt766`)  
> SE38/SE93 cho giao diện người dùng và ALV Grid.

> **Mục tiêu:** Tạo màn hình nhập liệu và T-code cho người dùng

### Bước 3.1: Tạo Report Program Z_BUG_CREATE_SCREEN

1. Vào T-code `SE38`
2. Program: `Z_BUG_CREATE_SCREEN`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Creation Screen`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Xóa phần gán `TEXT-001` (nếu có) và nhấn **Save**.
7. **Định nghĩa Text Symbol:**
   - Lên menu: **Goto** -> **Text Elements** -> **Text Symbols**.
   - Dòng `001`: Nhập `Create New Bug`.
   - Nhấn **Save** và **Activate** (trong màn hình Text Elements).
8. Quay lại code và nhấn **Activate** (Ctrl+F3).

**Source code:**

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_CREATE_SCREEN
*&---------------------------------------------------------------------*
REPORT z_bug_create_screen.

" Không dùng TABLES zbug_tracker để tránh lỗi STRING field

" Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
PARAMETERS: p_title TYPE zde_bug_title OBLIGATORY,
            p_module TYPE zde_sap_module OBLIGATORY,
            p_prior TYPE zde_priority DEFAULT 'M',
            p_devid TYPE zde_username.
SELECTION-SCREEN SKIP 1.
" Dùng TYPE char255 cho Screen vì PARAMETERS không hỗ trợ STRING
PARAMETERS: p_desc TYPE char255 LOWER CASE OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.

  DATA: lv_bug_id  TYPE zde_bug_id,
        lv_success TYPE char1,
        lv_message TYPE string,
        lv_desc    TYPE zde_bug_desc.

  lv_desc = p_desc.

  " Call function to create bug
  CALL FUNCTION 'Z_BUG_CREATE'
    EXPORTING
      iv_title    = p_title
      iv_desc     = lv_desc
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

1. Click **Save** → **Activate** (Ctrl+F3)

**✅ Checkpoint:** Program `Z_BUG_CREATE_SCREEN` Active trong SE38

---

### Bước 3.2: Tạo T-code ZBUG_CREATE

1. Vào T-code `SE93`
2. Transaction Code: `ZBUG_CREATE`
3. Click **Create**
4. Short Description: `Create New Bug`
5. Chọn **Program and Selection Screen (Report Transaction)**
6. Điền:

```text
Program: Z_BUG_CREATE_SCREEN
Screen Number: 1000 (default)
```

1. Click **Save**

**✅ Checkpoint:** Gõ T-code `ZBUG_CREATE` → Màn hình nhập liệu "Create New Bug" hiển thị

---

### Bước 3.3: Tạo Report Program Z_BUG_UPDATE_SCREEN

> **Lý do:** Theo yêu cầu, cả Tester và Developer dùng **chung một màn hình** để xem và cập nhật Bug. Màn hình này hiển thị thông tin chi tiết một Bug và cho phép cập nhật trạng thái, lý do, hoặc gán người xử lý.

1. Vào T-code `SE38`
2. Program: `Z_BUG_UPDATE_SCREEN`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Update/View Screen`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Xóa phần gán `TEXT-001`, `TEXT-002` (nếu có) và nhấn **Save**.
7. **Định nghĩa Text Symbol:**
   - Lên menu: **Goto** -> **Text Elements** -> **Text Symbols**.
   - Dòng `001`: Nhập `Bug Information`.
   - Dòng `002`: Nhập `Update Bug`.
   - Nhấn **Save** và **Activate**.
8. Quay lại code và nhấn **Activate** (Ctrl+F3).

**Source code:**

> [!IMPORTANT]
> **Fix v3 (sy-ucomm):** Dùng `sy-ucomm` để phân biệt **Enter** (xem dữ liệu) vs **Execute/F8** (submit update).
> - Khi user nhấn **Enter** trên selection screen → `sy-ucomm = ''` → pre-fill status từ DB ✓
> - Khi user nhấn **Execute (F8)** → `sy-ucomm = 'ONLI'` → **KHÔNG pre-fill** → giữ nguyên giá trị user đã sửa ✓
>
> Fix v1 (abap_bool) và v2 (CHAR1 flag) đều thất bại vì `AT SELECTION-SCREEN` fire cả khi Enter lẫn Execute, flag không phân biệt được 2 trường hợp, và `CLEAR gv_filled` sau update reset flag.

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_UPDATE_SCREEN
*& Fix v3: Dùng sy-ucomm phân biệt Enter vs Execute
*&---------------------------------------------------------------------*
REPORT z_bug_update_screen.

" Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_bugid  TYPE zde_bug_id OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_status TYPE zde_bug_status,
              p_devid  TYPE zde_username,
              p_reason TYPE char255 LOWER CASE.
SELECTION-SCREEN END OF BLOCK b2.

DATA: ls_bug     TYPE zbug_tracker,
      lv_success TYPE char1,
      lv_message TYPE string.

AT SELECTION-SCREEN.
  " sy-ucomm = 'ONLI' khi Execute (F8)
  " sy-ucomm = ''     khi Enter
  " Chỉ pre-fill khi user nhấn Enter (xem data), KHÔNG khi Execute (submit)
  IF sy-ucomm <> 'ONLI' AND p_bugid IS NOT INITIAL.
    CALL FUNCTION 'Z_BUG_GET'
      EXPORTING iv_bug_id  = p_bugid
      IMPORTING es_bug     = ls_bug
                ev_success = lv_success.
    IF lv_success = 'Y'.
      p_status = ls_bug-status.
      p_devid  = ls_bug-dev_id.
    ENDIF.
  ENDIF.

START-OF-SELECTION.

  DATA: lv_reason     TYPE zde_bug_desc,
        lv_old_status TYPE zde_bug_status.

  lv_reason = p_reason.

  " Đọc bug hiện tại để lấy old_status (cho log history)
  CALL FUNCTION 'Z_BUG_GET'
    EXPORTING iv_bug_id  = p_bugid
    IMPORTING es_bug     = ls_bug
              ev_success = lv_success
              ev_message = lv_message.

  IF lv_success <> 'Y'.
    MESSAGE lv_message TYPE 'E'.
    RETURN.
  ENDIF.

  lv_old_status = ls_bug-status.

  CALL FUNCTION 'Z_BUG_UPDATE_STATUS'
    EXPORTING
      iv_bug_id     = p_bugid
      iv_new_status = p_status
      iv_dev_id     = p_devid
      iv_reason     = lv_reason
      iv_changed_by = sy-uname
    IMPORTING
      ev_success    = lv_success
      ev_message    = lv_message.

  IF lv_success = 'Y'.
    CALL FUNCTION 'Z_BUG_LOG_HISTORY'
      EXPORTING
        iv_bug_id      = p_bugid
        iv_action_type = 'ST'
        iv_old_value   = lv_old_status
        iv_new_value   = p_status
        iv_reason      = lv_reason.
    MESSAGE lv_message TYPE 'S'.
  ELSE.
    MESSAGE lv_message TYPE 'E'.
  ENDIF.
```

1. Click **Save** → **Activate**

---

### Bước 3.4: Tạo T-code ZBUG_UPDATE

1. Vào T-code **`SE93`**
2. Transaction Code: **`ZBUG_UPDATE`** -> Click **Create**.
3. Điền các thuộc tính (Attributes):
   - **Short text:** `View/Update Bug Detail`
   - **Start object:** Chọn **Program and selection screen (report transaction)**.
4. Nhấn **Continue (Enter)**.
5. Ở màn hình tiếp theo, điền:
   - **Program:** `Z_BUG_UPDATE_SCREEN`
   - **Selection screen:** `1000`
   - **GUI support:** Tích chọn cả 3 ô (HTML, Java, Windows).
6. Click **Save** → Gán Package `ZBUGTRACK`.

**✅ Checkpoint:** Gõ T-code `ZBUG_UPDATE` + nhập Bug ID → Thấy thông tin Bug, có thể cập nhật Status

---

### Bước 3.5: Z_BUG_LOG_HISTORY (Lưu vết thay đổi)

> [!IMPORTANT]
> **Lý do:** Đây là Function Module bắt buộc phải có để màn hình Update Bug (`Z_BUG_UPDATE_SCREEN`) hoạt động mà không bị dump.

**Import Parameters**

| Parameter      | Typing    | Associated Type  | Pass | Opt | Description     |
| -------------- | --------- | ---------------- | ---- | --- | --------------- |
| IV_BUG_ID      | TYPE      | ZDE_BUG_ID       | [x]  | [ ] | Bug ID          |
| IV_ACTION_TYPE | TYPE      | ZDE_BUG_ACT_TYPE | [x]  | [ ] | Loại action     |
| IV_OLD_VALUE   | TYPE      | C                | [x]  | [x] | Giá trị cũ     |
| IV_NEW_VALUE   | TYPE      | C                | [x]  | [x] | Giá trị mới   |
| IV_REASON      | TYPE      | ZDE_REASONS      | [x]  | [x] | Lý do           |

```abap
FUNCTION z_bug_log_history.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_ACTION_TYPE) TYPE  ZDE_BUG_ACT_TYPE
*"     VALUE(IV_OLD_VALUE) TYPE  C OPTIONAL
*"     VALUE(IV_NEW_VALUE) TYPE  C OPTIONAL
*"     VALUE(IV_REASON) TYPE  ZDE_REASONS OPTIONAL
*"----------------------------------------------------------------------

  DATA: ls_log   TYPE zbug_history,
        lv_logid TYPE numc10.

  " Get next log ID
  SELECT MAX( log_id ) FROM zbug_history INTO @lv_logid.
  lv_logid = lv_logid + 1.

  ls_log-mandt        = sy-mandt.
  ls_log-log_id       = lv_logid.
  ls_log-bug_id       = iv_bug_id.
  ls_log-changed_by   = sy-uname.
  ls_log-changed_at   = sy-datum.
  ls_log-changed_time = sy-uzeit.
  ls_log-action_type  = iv_action_type.
  ls_log-old_value    = iv_old_value.
  ls_log-new_value    = iv_new_value.
  ls_log-reason       = iv_reason.

  INSERT zbug_history FROM @ls_log.
  COMMIT WORK.

ENDFUNCTION.
```

1. Click **Save** → **Activate**

---

> [!TIP]
> **Tài khoản sử dụng:** **DEV-061** (Pass: `@57Dt766`)  
> Dùng cho Report ALV hiển thị danh sách Bug.

### Bước 4.1: Tạo Report Z_BUG_REPORT_ALV

1. Vào T-code `SE38`
2. Program: `Z_BUG_REPORT_ALV`
3. Click **Create**
   > [!TIP]
   > Bạn chỉ cần nhập tên Program và nhấn nút **Create**. Các lựa chọn trong phần *Subobjects* (như Source Code, Variants...) mặc định là *Source Code* và chỉ dùng khi bạn muốn Display/Change một chương trình đã tồn tại.
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Tracking ALV Report`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Source code:

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_REPORT_ALV
*&---------------------------------------------------------------------*
REPORT z_bug_report_alv.

" Helper variables for Selection Screen (ZBUG_TRACKER is a deep structure, cannot use TABLES)
DATA: lv_bugid  TYPE zde_bug_id,
      lv_status TYPE zde_bug_status,
      lv_module TYPE zde_sap_module,
      lv_prior  TYPE zde_priority.

" Selection Screen
SELECT-OPTIONS: s_bugid  FOR lv_bugid,
                s_status FOR lv_status,
                s_module FOR lv_module,
                s_prior  FOR lv_prior.

" Internal table
DATA: lt_bugs     TYPE TABLE OF zbug_tracker.

" ALV
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv.

START-OF-SELECTION.

  " Fetch data
  SELECT * FROM zbug_tracker INTO TABLE @lt_bugs
    WHERE bug_id     IN @s_bugid
      AND status     IN @s_status
      AND sap_module IN @s_module
      AND priority   IN @s_prior
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
  ls_fieldcat-fieldname = 'SAP_MODULE'.
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
  ls_fieldcat-fieldname = 'TESTER_ID'.
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

1. Click **Save** → **Activate**

---

### Bước 4.2: Tạo T-code ZBUG_REPORT

1. Vào T-code `SE93`
2. Transaction: `ZBUG_REPORT` -> Click **Create**.
3. Short Description: `Bug Tracking Report`
4. Chọn **Program and selection screen (report transaction)**.
   > [!IMPORTANT]
   > Đây là **dòng thứ 2 từ trên xuống**. Đừng chọn dòng đầu tiên (Program and dynpro) vì nó dành cho Module Pool.
5. Điền:
   - **Program:** `Z_BUG_REPORT_ALV`
   - **Selection screen:** `1000`
   - **GUI support:** Tích chọn cả 3 ô (HTML, Java, Windows).
6. Click **Save** -> Gán Package `ZBUGTRACK`.

**✅ Checkpoint:** Gõ T-code `ZBUG_REPORT` → ALV Grid hiển thị danh sách Bug

---

### Bước 4.3: Nâng cấp ALV - Thêm nút tương tác (Interactive ALV)

> [!NOTE]
> **Mục tiêu:** Thêm 2 nút "Update" và "Auto Assign" vào thanh công cụ của báo cáo để xử lý nhanh.

#### Phần 1: Cập nhật Code (T-code SE38)

Mở Program `Z_BUG_REPORT_ALV` trong **SE38**, xóa toàn bộ code cũ và dán đoạn code đầy đủ đã được nâng cấp dưới đây:

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_REPORT_ALV
*&---------------------------------------------------------------------*
REPORT z_bug_report_alv.

" Helper variables for Selection Screen (ZBUG_TRACKER is a deep structure, cannot use TABLES)
DATA: lv_bugid  TYPE zde_bug_id,
      lv_status TYPE zde_bug_status,
      lv_module TYPE zde_sap_module,
      lv_prior  TYPE zde_priority.

" Selection Screen
SELECT-OPTIONS: s_bugid  FOR lv_bugid,
                s_status FOR lv_status,
                s_module FOR lv_module,
                s_prior  FOR lv_prior.

" Internal table
DATA: lt_bugs     TYPE TABLE OF zbug_tracker.

" ALV Data
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv,
      lt_excl     TYPE slis_t_extab.

START-OF-SELECTION.

  " 1. Fetch data
  SELECT * FROM zbug_tracker INTO TABLE @lt_bugs
    WHERE bug_id     IN @s_bugid
      AND status     IN @s_status
      AND sap_module IN @s_module
      AND priority   IN @s_prior
    ORDER BY created_at DESCENDING.

  IF lt_bugs IS INITIAL.
    MESSAGE 'No bugs found' TYPE 'S'.
    RETURN.
  ENDIF.

  " 2. Build field catalog
  PERFORM build_fieldcat.

  " 3. Display ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PF_STATUS_SET'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = ls_layout
      it_fieldcat              = lt_fieldcat
    TABLES
      t_outtab                 = lt_bugs
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

*&---------------------------------------------------------------------*
*& Form build_fieldcat
*&---------------------------------------------------------------------*
FORM build_fieldcat.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  DEFINE m_fieldcat.
    clear ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_m = &2.
    ls_fieldcat-col_pos   = &3.
    append ls_fieldcat to lt_fieldcat.
  END-OF-DEFINITION.

  m_fieldcat 'BUG_ID'     'Bug ID'    1.
  m_fieldcat 'TITLE'      'Title'     2.
  m_fieldcat 'SAP_MODULE' 'Module'    3.
  m_fieldcat 'PRIORITY'   'Priority'  4.
  m_fieldcat 'STATUS'     'Status'    5.
  m_fieldcat 'TESTER_ID'  'Reporter'  6.
  m_fieldcat 'CREATED_AT' 'Created'   7.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_status_set
*&---------------------------------------------------------------------*
FORM pf_status_set USING lv_extab TYPE slis_t_extab.
  SET PF-STATUS 'ZBUG_STATUS'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form user_command
*&---------------------------------------------------------------------*
FORM user_command USING lv_ucomm TYPE syucomm
                        ls_selfield TYPE slis_selfield.
  DATA: lv_bugid   TYPE zde_bug_id,
        lv_message TYPE string.

  READ TABLE lt_bugs INDEX ls_selfield-tabindex INTO DATA(ls_sel).
  lv_bugid = ls_sel-bug_id.

  CASE lv_ucomm.
    WHEN 'ZUPD'.  " Nút Update
      SET PARAMETER ID 'ZBG' FIELD lv_bugid.
      CALL TRANSACTION 'ZBUG_UPDATE' AND SKIP FIRST SCREEN.

    WHEN 'ZASGN'. " Nút Auto Assign
      CALL FUNCTION 'Z_BUG_AUTO_ASSIGN'
        EXPORTING iv_bug_id = lv_bugid
                  iv_module = ls_sel-sap_module
        IMPORTING ev_message = lv_message.
      MESSAGE lv_message TYPE 'S'.
  ENDCASE.

  ls_selfield-refresh = 'X'.
ENDFORM.
```

#### Phần 2: Tạo Giao diện Nút (T-code SE80)

1. Vào T-code **SE80**.
2. Chọn **Program** và nhập `Z_BUG_REPORT_ALV`.
3. Chuột phải vào tên Program -> **Create** -> **GUI Status**.
4. **Popup "Maintain Status" hiện ra:**
   - **Status:** Nhập `ZBUG_STATUS` (phải viết hoa, không dấu).
   - **Short Text:** Nhập `ALV Toolbar`.
   - Nhấn **Enter** (Tích xanh).

5. **Trong màn hình GUI Status Editor:**

   - **A. Thanh công cụ (Application Toolbar):**
     - Tìm dòng **Application Toolbar**, nhấn vào mũi tên nhỏ bên cạnh để mở rộng nó ra.
     - Ở ô trống đầu tiên (Item 1), nhập `ZUPD` rồi nhấn **Enter**.
     - Một popup hiện ra, ở ô **Function Text**, nhập `Update Bug`. Chọn một icon (nhấn F4) như `ICON_SYSTEM_SAVE`. Nhấn **Enter**.
     - Ở ô trống thứ hai (Item 2), nhập `ZASGN` rồi nhấn **Enter**.
     - Popup hiện ra, nhập `Auto Assign` vào **Function Text**. Chọn icon `ICON_USER`. Nhấn **Enter**.

   - **B. Các phím chức năng (Function Keys):**
     - Mở rộng phần **Function Keys**.
     - Tìm biểu tượng **Mũi tên xanh (Back)**: Nhập `BACK`.
     - Tìm biểu tượng **Cửa sổ có mũi tên (Exit)**: Nhập `EXIT`.
     - Tìm biểu tượng **Dấu X đỏ (Cancel)**: Nhập `CANC`.

6. **Kích hoạt:**
   - Nhấn **Save (Ctrl+S)**.
   - Nhấn **Activate (Ctrl+F3)**. Nếu nó hỏi "Select objects", hãy tích chọn cả Program và GUI Status rồi nhấn Enter.

**✅ Checkpoint:** Chạy `ZBUG_REPORT` -> Thấy 2 nút mới hiện trên Toolbar -> Bấm thử nút Update.

> [!NOTE]
> Tạo thêm GUI Status `ZBUG_STATUS` trong SE80 cho program `Z_BUG_REPORT_ALV` với 2 Function Code: `ZUPD` (Update Bug) và `ZASGN` (Auto Assign).

---

### Bước 4.4: Manager Dashboard Z_BUG_MANAGER_DASHBOARD

> **Lý do (requirements #10 + extra #7):** Manager cần dashboard tổng hợp: số Bug theo Status/Module, danh sách Bug đang Waiting, và hiệu suất Tester/Developer.

1. Vào T-code **`SE38`**
2. Program: `Z_BUG_MANAGER_DASHBOARD`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Manager Dashboard`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Source code (Phiên bản cải tiến - Hiển thị thống kê phía trên bảng):

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_MANAGER_DASHBOARD
*&---------------------------------------------------------------------*
REPORT z_bug_manager_dashboard.

TYPE-POOLS: slis.

TYPES: BEGIN OF ty_stat,
         status TYPE zde_bug_status,
         cnt    TYPE i,
       END OF ty_stat.

DATA: lt_stat     TYPE TABLE OF ty_stat,
      ls_stat     TYPE ty_stat,
      lt_waiting  TYPE TABLE OF zbug_tracker,
      lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv,
      lv_total    TYPE i.

START-OF-SELECTION.

  " 1. Lấy thống kê tổng quát
  SELECT status, COUNT(*) AS cnt FROM zbug_tracker
    INTO TABLE @lt_stat
    GROUP BY status.

  SELECT COUNT(*) FROM zbug_tracker INTO @lv_total.

  " 2. Lấy danh sách Bug đang "Waiting" (Status = 'W')
  " LƯU Ý: Nếu dashboard trống, có thể là do bạn không có bug nào ở trạng thái 'W'
  SELECT * FROM zbug_tracker INTO TABLE @lt_waiting
    WHERE status = 'W'
    ORDER BY created_at ASCENDING.

  " 3. Hiển thị ALV
  PERFORM build_fieldcat.
  ls_layout-zebra = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program     = sy-repid
      i_callback_top_of_page = 'TOP_OF_PAGE'
      is_layout              = ls_layout
      it_fieldcat            = lt_fieldcat
    TABLES
      t_outtab               = lt_waiting
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.

*&---------------------------------------------------------------------*
*& Form TOP_OF_PAGE
*&---------------------------------------------------------------------*
FORM top_of_page.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader,
        lv_total_s TYPE string,
        lv_cnt_s   TYPE string,
        lv_status_txt TYPE string.

  ls_header-typ  = 'H'.
  ls_header-info = '=== BUG TRACKING DASHBOARD ==='.
  APPEND ls_header TO lt_header.

  lv_total_s = lv_total.
  ls_header-typ  = 'S'.
  CONCATENATE 'Tổng số Bug trong hệ thống: ' lv_total_s INTO ls_header-info.
  APPEND ls_header TO lt_header.

  LOOP AT lt_stat INTO ls_stat.
    " Ánh xạ mã trạng thái sang tên tiếng Việt
    CASE ls_stat-status.
      WHEN '1'. lv_status_txt = 'Mới (New)'.
      WHEN 'W'. lv_status_txt = 'Chờ gán (Waiting)'.
      WHEN '2'. lv_status_txt = 'Đã gán (Assigned)'.
      WHEN '3'. lv_status_txt = 'Đang sửa (In Progress)'.
      WHEN '4'. lv_status_txt = 'Đã sửa (Fixed)'.
      WHEN '5'. lv_status_txt = 'Đã đóng (Closed)'.
      WHEN OTHERS. lv_status_txt = 'Khác (Other)'.
    ENDCASE.

    lv_cnt_s = ls_stat-cnt.
    ls_header-typ = 'S'.
    CONCATENATE lv_status_txt ': ' lv_cnt_s ' bugs' INTO ls_header-info.
    APPEND ls_header TO lt_header.
  ENDLOOP.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form BUILD_FIELDCAT
*&---------------------------------------------------------------------*
FORM build_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'BUG_ID'.    ls_fieldcat-seltext_m = 'Bug ID'.    ls_fieldcat-col_pos = 1. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'TITLE'.     ls_fieldcat-seltext_m = 'Title'.     ls_fieldcat-col_pos = 2. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'SAP_MODULE'.ls_fieldcat-seltext_m = 'Module'.    ls_fieldcat-col_pos = 3. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'PRIORITY'.  ls_fieldcat-seltext_m = 'Priority'.  ls_fieldcat-col_pos = 4. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'TESTER_ID'. ls_fieldcat-seltext_m = 'Reporter'.  ls_fieldcat-col_pos = 5. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'CREATED_AT'.ls_fieldcat-seltext_m = 'Created'.   ls_fieldcat-col_pos = 6. APPEND ls_fieldcat TO lt_fieldcat.
ENDFORM.
```

1. Click **Save** → **Activate**
2. Tạo T-code **`ZBUG_MANAGER`**:
   - Vào T-code **`SE93`**.
   - Transaction Code: `ZBUG_MANAGER` -> Click **Create**.
   - Short Text: `Bug Manager Dashboard`.
   - Select: **Program and selection screen (report transaction)**.
   - Program: `Z_BUG_MANAGER_DASHBOARD`.
   - Tích chọn: **Inherit GUI attributes** (ở cuối trang).
   - Click **Save** -> Chọn Package/Transport Request.

**✅ Checkpoint:** Gõ `ZBUG_MANAGER` → Thấy thống kê tổng Bug + bảng Waiting Bugs

---

### Bước 4.5: Tạo SmartForm ZBUG_FORM (In ấn Bug Report)

> **Lý do (requirements #3B):** In biên bản bàn giao lỗi dạng văn bản chính thức (PDF/Print).

1. Vào T-code **`SMARTFORMS`**
2. Form Name: `ZBUG_FORM`
3. Click **Create**.
4. **Khai báo Interface (Dữ liệu đầu vào):**
   - Mở cây thư mục bên trái: **Global Settings** -> Click đúp vào **Form Interface**.
   - Ở màn hình bên phải, chọn tab **Import**.
   - Thêm một dòng mới:
     - **Parameter Name:** `IS_BUG`
     - **Type Assignment:** `TYPE`
     - **Associated Type:** `ZBUG_TRACKER`
     - **Pass Value:** Bắt buộc phải TICK chọn ô này.
   - Bấm **Save** (Ctrl+S).

5. **Thiết kế giao diện bằng Graphical Form Painter:**
   - Ở cây thư mục bên trái, mở rộng: **Pages and Windows** -> **%PAGE1 New Page**.
   - Mặc định đã có sẵn 1 ô là **MAIN Main Window**.
   - **Tạo HEADER:** Nhấn chuột phải vào `%PAGE1 New Page` -> **Create** -> **Window**. Đặt tên cửa sổ mới là `HEADER` và điền Description là `Tieu de bao cao`.
   - **Tạo FOOTER:** Nhấn chuột phải vào `%PAGE1 New Page` -> **Create** -> **Window**. Đặt tên cửa sổ mới là `FOOTER` và điền Description là `Chu ky`.

   - **Kéo thả Layout:** Nhìn sang khung lưới đồ họa (Form Painter) bên phải. Bấm chuột vào viền của các ô vuông để di chuyển và kéo giãn. Sắp xếp lại sao cho:
     - Ô `HEADER` nằm trên cùng.
     - Ô `MAIN` nằm ở giữa (kéo to ra để chứa nội dung).
     - Ô `FOOTER` nằm ở dưới cùng.

6. **Điền nội dung (Thêm Text Nodes):**
   - **Tắt MS Word Editor (Quan trọng):** Mở 1 cửa sổ mới (gõ `/oSE38`) -> Chạy Program `RSCPSETEDITOR` -> Bỏ tích ô MS Word ở phần Smart Forms -> Kích hoạt (Activate) và quay lại màn hình SMARTFORMS.
   - **Cho HEADER:** Chuột phải vào chữ `HEADER` trên cây bên trái -> **Create** -> **Text**.
     - Sửa tên thành `TXT_TITLE`.
     - Click vào nút `Text Editor` (biểu tượng tờ giấy và cây bút ở góc trái thẻ General Attributes).
     - Gõ nội dung (Lưu ý gõ dấu `*` ở cột lề trái nhỏ xíu): `* BUG TRACKING REPORT`. Bấm Back (`<`) màn hình màu xanh lá và Save.
   - **Cho MAIN:** Chuột phải vào chữ `MAIN Main Window` trên cây bên trái -> **Create** -> **Text**.
     - Sửa tên thành `TXT_DETAILS`.
     - Vào `Text Editor`, nhập danh sách các thông tin sau (chú ý dùng dấu `*` ở cột lề trái cho TẤT CẢ các dòng để text tự động xuống hàng):

       ```text
       * Bug ID:      &IS_BUG-BUG_ID&
       * Title:       &IS_BUG-TITLE&
       * Sap Module:  &IS_BUG-SAP_MODULE&
       * Priority:    &IS_BUG-PRIORITY&
       * Status:      &IS_BUG-STATUS&
       * Reporter:    &IS_BUG-TESTER_ID&
       * Created on:  &IS_BUG-CREATED_AT&
       ```

     - Bấm Back (`<`) và Save.

7. **Kiểm tra và Kích hoạt:**
   - Nhấn nút **Check (F8)** để kiểm tra lỗi cú pháp. Nhấn **Activate (Ctrl+F3)** để kích hoạt Form (Bắt buộc phải Activate thì Form mới nhận thay đổi).

#### Tạo Driver Program cho SmartForm: Z_BUG_PRINT

1. Vào T-code `SE38`
2. Program: `Z_BUG_PRINT`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Printing Driver Program`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Source code:

```abap
REPORT z_bug_print.

PARAMETERS: p_bugid TYPE zde_bug_id OBLIGATORY.

DATA: ls_bug           TYPE zbug_tracker,
      lv_success       TYPE char1,
      lv_fm_name       TYPE rs38l_fnam,
      lv_control_param TYPE ssfctrlop,
      lv_output_param  TYPE ssfcompop.

START-OF-SELECTION.

  " Lấy thông tin Bug
  CALL FUNCTION 'Z_BUG_GET'
    EXPORTING  iv_bug_id  = p_bugid
    IMPORTING  es_bug     = ls_bug
               ev_success = lv_success.

  IF lv_success <> 'Y'.
    MESSAGE 'Bug not found' TYPE 'E'.
    RETURN.
  ENDIF.

  " Lấy tên FM của SmartForm
  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING  formname           = 'ZBUG_FORM'
    IMPORTING  fm_name            = lv_fm_name
    EXCEPTIONS no_form            = 1
               no_function_module = 2
               OTHERS             = 3.

  lv_control_param-no_dialog = 'X'.
  lv_control_param-preview    = 'X'.

  " Gọi SmartForm
  CALL FUNCTION lv_fm_name
    EXPORTING
      control_parameters = lv_control_param
      output_options     = lv_output_param
      is_bug             = ls_bug
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

  IF sy-subrc <> 0.
    MESSAGE 'SmartForm print failed' TYPE 'E'.
  ENDIF.
```

#### Tạo T-code cho chương trình in ấn (SE93)

1. Mở một tab dòng lệnh mới bằng cách gõ `/oSE93` rồi Enter.
2. Tại ô **Transaction Code**, nhập: **`ZBUG_PRINT`** -> Bấm **Create**.
3. **Short text:** Gõ `In an Bug Tracking Report`
4. Chọn radio button **Program and selection screen (report transaction)** -> Bấm **Enter**.
5. Trong màn hình tiếp theo:
   - **Program:** Gõ **`Z_BUG_PRINT`** (Lưu ý: Chỗ này là TÊN PROGRAM mà ta vừa tạo ở trên, CÓ dấu gạch dưới `_`).
   - Phía dưới, tích chọn 3 ô:
     - [x] SAP GUI for HTML
     - [x] SAP GUI for Java
     - [x] SAP GUI for Windows
6. Bấm **Save** -> Lưu vào Package `ZBUGTRACK`.

**✅ Checkpoint:** Gõ lệnh `ZBUG_PRINT` (ra ngoài màn hình chính), nhập một số Bug ID bất kỳ (VD: 1, 2) → Bấm Execute (F8) → Form in ấn SmartForms dạng cửa sổ phụ họa sẽ bật lên!

---

### Bước 4.6: Tạo Program Z_BUG_USER_MANAGEMENT (Quản lý tài khoản)

> **Lý do (requirements #6 + #10):** Manager cần màn hình để xem và quản lý danh sách Users, đặc biệt là xem `AVAILABLE_STATUS` của Developer.

> [!TIP]
> **Tài khoản sử dụng:** **DEV-118** (Pass: `Qwer123@`) — Cần dùng user này hoặc những user có Role `M` (Manager) để test quyền (phân quyền sẽ làm ở Phase 5).

1. Mở tab dòng lệnh mới: `/oSE38`
2. Program: `Z_BUG_USER_MANAGEMENT`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug User Management`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Xóa đoạn Text mặc định (nếu có chữ `TEXT-001...`) và dán toàn bộ Source Code ở mục dưới vào. Nhấn **Save**.
7. **Định nghĩa Text Symbol (Tạo Text cho Selection Screen):**
   - Lên thanh menu trên cùng: Chọn **Goto** -> **Text Elements** -> **Text Symbols**.
   - Ở dòng mã `001`: Nhập chữ `Filter by Role (T=Tester D=Developer M=Manager)` vào cột Text.
   - Chuyển sang thẻ bên cạnh là **Selection Texts**. Tích vào ô vuông cột *Dictionary* của dòng `P_ROLE` (sẽ tự động lấy tên bảng, hoặc tự gõ vào ô Text chữ `User Role`).
   - Nhấn **Save** và **Activate** màn hình Text. Bấm Back (F3) ngoài cùng bên trái để quay lại.
8. Ở màn hình code hiện tại, nhấn **Activate** (Ctrl+F3) một lần nữa.

> [!CAUTION]
> **Thêm dữ liệu ảo (Dummy Data) cho bảng ZBUG_USERS:**
> Do bảng User của chúng ta hiện tại đang... trống trơn (Chưa có ai trong hệ thống), nên ALV in ra sẽ không có gì.
> Bạn cần mở 1 tab lệnh mới (`/oSE16N`) -> Điền bảng `ZBUG_USERS` -> Bấm Execute (F8) -> Thêm vài User mẫu (Ví dụ: `USER_ID` = `DEV-001`, `ROLE` = `D`, `IS_ACTIVE` = `X`). Bấm Save. Làm tương tự cho 2-3 người nữa với ROLE khác nhau.

**Source code (Copy & Paste):**

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_USER_MANAGEMENT
*&---------------------------------------------------------------------*
REPORT z_bug_user_management.

TABLES: zbug_users.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_role TYPE zde_bug_role.
SELECTION-SCREEN END OF BLOCK b1.

DATA: lt_users    TYPE TABLE OF zbug_users,
      lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv.

START-OF-SELECTION.

  IF p_role IS NOT INITIAL.
    SELECT * FROM zbug_users INTO TABLE @lt_users
      WHERE role = @p_role AND is_active = 'X'
      ORDER BY user_id.
  ELSE.
    SELECT * FROM zbug_users INTO TABLE @lt_users
      WHERE is_active = 'X'
      ORDER BY role.
  ENDIF.

  IF lt_users IS INITIAL.
    MESSAGE 'No users found' TYPE 'S'.
    RETURN.
  ENDIF.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'USER_ID'.          ls_fieldcat-seltext_m = 'User ID'.      ls_fieldcat-col_pos = 1. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'FULL_NAME'.        ls_fieldcat-seltext_m = 'Full Name'.    ls_fieldcat-col_pos = 2. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'ROLE'.             ls_fieldcat-seltext_m = 'Role'.         ls_fieldcat-col_pos = 3. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'SAP_MODULE'.       ls_fieldcat-seltext_m = 'Module'.       ls_fieldcat-col_pos = 4. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'AVAILABLE_STATUS'. ls_fieldcat-seltext_m = 'Avail Status'. ls_fieldcat-col_pos = 5. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'EMAIL'.            ls_fieldcat-seltext_m = 'Email'.        ls_fieldcat-col_pos = 6. APPEND ls_fieldcat TO lt_fieldcat.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'IS_ACTIVE'.        ls_fieldcat-seltext_m = 'Active'.       ls_fieldcat-col_pos = 7. APPEND ls_fieldcat TO lt_fieldcat.

  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = lt_fieldcat
    TABLES
      t_outtab           = lt_users
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
```

1. Click **Save** → **Activate**

---

### Bước 4.7: Tạo T-code cho User Management (T-code ZBUG_USERS)

1. Mở một tab lệnh mới: `/oSE93`
2. Tại ô **Transaction Code**, nhập: **`ZBUG_USERS`** -> Bấm **Create**.
3. **Short text:** Gõ `User Management`
4. Chọn lựa chọn đầu tiên: **Program and selection screen (report transaction)** -> Bấm **Enter**.
5. Màn hình tiếp theo điền thông tin:
   - **Program:** Điền tên mã nguồn **`Z_BUG_USER_MANAGEMENT`**.
   - Đảm bảo đã check đủ 3 ô SAP GUI (HTML, Java, Windows).
6. Click **Save** -> Lưu vào `ZBUGTRACK`.

**✅ Checkpoint:** Gõ lệnh `/nZBUG_USERS` (trở ra màn hình gọi app) → ALV hiển thị danh sách toàn bộ Users trong hệ thống, có cái khung viền "Filter by Role..." bao quanh ô nhập Role. Thử gõ `D` vào ô Role, bấm F8 xem list có filter chỉ hiện Developer không!

---

## PHASE 5: ADVANCED FUNCTION MODULES (Nâng Cao)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-089** (Pass: `@Anhtuoi123`)
> Thêm các Function Modules nâng cao vào Function Group `ZBUG_FG`.
> **Mục tiêu:** Auto-assign, Permission Check, History Logging và ALV màu sắc

**⚠️ Lưu ý về đánh số:** `Z_BUG_LOG_HISTORY` (checklist **Phase 5, item 5.1**) được document ở **Bước 3.5** trong Phase 3 của guide (vì được dùng ở Z_BUG_UPDATE_SCREEN). Kiểm tra xem FM này đã tồn tại trong `ZBUG_FG` chưa (vào SE80 → Functions). **Nếu chưa có, tạo ngay theo hướng dẫn ở Bước 3.5** vì Bước 5.6 (Z_BUG_REASSIGN) gọi FM này.

---

### 📌 Quy trình tạo FM chuẩn (áp dụng cho tất cả Bước 5.2–5.6)

Tất cả các Function Modules trong Phase 5 đều được tạo theo cùng một quy trình:

1. Vào T-code **`SE80`**
2. Dropdown chọn **Function Group** → nhập `ZBUG_FG` → Enter
3. Trong cây bên trái: **right-click `ZBUG_FG`** → **Create** → **Function Module**
4. Điền **Function Module name** và **Short text** (xem từng bước bên dưới)
5. Tab **Attributes**: `Processing Type` = **Normal Function Module**
6. Tab **Import**: Điền từng dòng theo bảng **Import Parameters**
7. Tab **Export**: Điền từng dòng theo bảng **Export Parameters**
8. Tab **Source code**: Paste toàn bộ code ABAP từ guide vào
9. Click **Save** → chọn package `ZBUGTRACK` → chọn **Transport Request hiện có** (Own Requests)
10. Click **Activate** (Ctrl+F3)

---

### Bước 5.2: Z_BUG_AUTO_ASSIGN (Tự động phân công)

Thực hiện **Quy trình tạo FM chuẩn** ở trên với:

- **Function Module:** `Z_BUG_AUTO_ASSIGN`
- **Short text:** `Auto Assign Bug to Developer`

> [!WARNING]
> FM này dùng cú pháp ABAP mới (`SELECT ... INTO @DATA(...)`). Nếu máy bạn báo lỗi cú pháp, hãy chuyển sang phiên bản Legacy bên dưới.

**Import Parameters**

| Parameter | Typing | Associated Type | Pass | Description     |
| --------- | ------ | --------------- | ---- | --------------- |
| IV_BUG_ID | TYPE   | ZDE_BUG_ID      | [x]  | Bug ID          |
| IV_MODULE | TYPE   | ZDE_SAP_MODULE  | [x]  | Module của Bug  |

**Export Parameters**

| Parameter  | Typing | Associated Type | Pass | Description     |
| ---------- | ------ | --------------- | ---- | --------------- |
| EV_DEV_ID  | TYPE   | ZDE_USERNAME    | [x]  | Dev được assign |
| EV_STATUS  | TYPE   | ZDE_BUG_STATUS  | [x]  | Trạng thái mới |
| EV_MESSAGE | TYPE   | STRING          | [x]  | Message         |

```abap
FUNCTION z_bug_auto_assign.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_MODULE) TYPE  ZDE_SAP_MODULE
*"  EXPORTING
*"     VALUE(EV_DEV_ID) TYPE  ZDE_USERNAME
*"     VALUE(EV_STATUS) TYPE  ZDE_BUG_STATUS
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_dev_workload,
           user_id  TYPE zde_username,
           workload TYPE i,
         END OF ty_dev_workload.

  DATA: lt_devs     TYPE TABLE OF ty_dev_workload,
        lt_available TYPE TABLE OF zde_username,
        ls_dev      TYPE ty_dev_workload,
        lv_user     TYPE zde_username,
        lv_count    TYPE i,
        lv_min_load TYPE i VALUE 999.

  " Get available developers for this module (Legacy syntax)
  SELECT user_id FROM zbug_users INTO TABLE @lt_available
    WHERE sap_module = @iv_module
      AND role = 'D'
      AND available_status = 'A'
      AND is_active = 'X'.

  IF sy-subrc <> 0.
    " No dev available - set Waiting
    ev_status = 'W'.
    ev_message = 'No developer available. Bug set to Waiting.'.
    UPDATE zbug_tracker SET status = 'W' WHERE bug_id = @iv_bug_id.
    COMMIT WORK.
    RETURN.
  ENDIF.

  " Count workload for each dev (Legacy syntax)
  LOOP AT lt_available INTO lv_user.
    CLEAR ls_dev.
    ls_dev-user_id = lv_user.

    SELECT COUNT(*) FROM zbug_tracker INTO @lv_count
      WHERE dev_id = @lv_user
        AND status IN ('2', '3').

    ls_dev-workload = lv_count.
    APPEND ls_dev TO lt_devs.
  ENDLOOP.

  " Find dev with lowest workload
  LOOP AT lt_devs INTO ls_dev.
    IF ls_dev-workload < lv_min_load.
      lv_min_load = ls_dev-workload.
      ev_dev_id = ls_dev-user_id.
    ENDIF.
  ENDLOOP.

  " Assign bug
  UPDATE zbug_tracker SET dev_id = @ev_dev_id, status = '2'
    WHERE bug_id = @iv_bug_id.

  " Update dev status to Working
  UPDATE zbug_users SET available_status = 'W'
    WHERE user_id = @ev_dev_id.

  COMMIT WORK.
  ev_status = '2'.
  CONCATENATE 'Bug assigned to ' ev_dev_id INTO ev_message.

ENDFUNCTION.
```

Click **Save** → **Activate**

---

### Bước 5.3: Z_BUG_CHECK_PERMISSION (Phân quyền theo Role)

Thực hiện **Quy trình tạo FM chuẩn** ở trên với:

- **Function Module:** `Z_BUG_CHECK_PERMISSION`
- **Short text:** `Check User Permission for Bug Action`

> [!WARNING]
> FM này cũng dùng cú pháp `COND #(...)` (ABAP 7.40+). Phiên bản dưới đây đã được viết lại theo **Legacy syntax** để đảm bảo tương thích.

**Import Parameters**

| Parameter | Typing | Associated Type | Pass | Description           |
| --------- | ------ | --------------- | ---- | --------------------- |
| IV_USER   | TYPE   | ZDE_USERNAME    | [x]  | User ID               |
| IV_BUG_ID | TYPE   | ZDE_BUG_ID      | [x]  | Bug cần kiểm tra      |
| IV_ACTION | TYPE   | CHAR20          | [x]  | Action (xem bảng)     |

> Các giá trị `IV_ACTION` hợp lệ: `CREATE`, `UPDATE_STATUS`, `UPLOAD_REPORT`, `UPLOAD_FIX`, `UPLOAD_VERIFY`

**Export Parameters**

| Parameter  | Typing | Associated Type | Pass | Description     |
| ---------- | ------ | --------------- | ---- | --------------- |
| EV_ALLOWED | TYPE   | CHAR1           | [x]  | Y=Allowed, N=No |
| EV_MESSAGE | TYPE   | STRING          | [x]  | Message lý do   |

```abap
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

  " Get user role
  SELECT SINGLE * FROM zbug_users INTO @ls_user
    WHERE user_id = @iv_user.

  IF sy-subrc <> 0.
    ev_allowed = 'N'.
    ev_message = 'User not found in system'.
    RETURN.
  ENDIF.

  " Manager has full access
  IF ls_user-role = 'M'.
    ev_allowed = 'Y'.
    RETURN.
  ENDIF.

  " Get bug info
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id.

  CASE iv_action.
    WHEN 'CREATE'.
      IF ls_user-role = 'T'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Only Tester can create bugs'.
      ENDIF.

    WHEN 'UPDATE_STATUS'.
      IF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
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
      IF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
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
```

Click **Save** → **Activate**

---

### Bước 5.4: ALV - Màu sắc theo Status (Bonus)

**Mục đích:** Sửa program `Z_BUG_REPORT_ALV` (đã tạo ở Phase 4) để thêm màu sắc hiển thị theo Status.

**Cách làm:**

1. Vào T-code **`SE38`**
2. Program: `Z_BUG_REPORT_ALV` → Click **Change**
3. Khi hiện **Create Task dialog** → Click ✓ (checkmark)
4. **Thay thế toàn bộ code bằng code dưới đây:**

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_REPORT_ALV
*&---------------------------------------------------------------------*
REPORT z_bug_report_alv.

" Helper variables for Selection Screen
DATA: lv_bugid  TYPE zde_bug_id,
      lv_status TYPE zde_bug_status,
      lv_module TYPE zde_sap_module,
      lv_prior  TYPE zde_priority.

" Selection Screen
SELECT-OPTIONS: s_bugid  FOR lv_bugid,
                s_status FOR lv_status,
                s_module FOR lv_module,
                s_prior  FOR lv_prior.

" Internal table - Original data
DATA: lt_bugs     TYPE TABLE OF zbug_tracker.

" Type with ROW_COLOR for display
TYPES: BEGIN OF ty_bug_display,
         bug_id      TYPE zde_bug_id,
         title       TYPE zde_bug_title,
         sap_module  TYPE zde_sap_module,
         priority    TYPE zde_priority,
         status      TYPE zde_bug_status,
         tester_id   TYPE zde_username,
         created_at  TYPE zde_bug_cr_date,
         row_color   TYPE c LENGTH 4,
       END OF ty_bug_display.

DATA: lt_display  TYPE TABLE OF ty_bug_display,
      ls_display  TYPE ty_bug_display.

" ALV Data
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv,
      lt_excl     TYPE slis_t_extab.

START-OF-SELECTION.

  " 1. Fetch data
  SELECT * FROM zbug_tracker INTO TABLE @lt_bugs
    WHERE bug_id     IN @s_bugid
      AND status     IN @s_status
      AND sap_module IN @s_module
      AND priority   IN @s_prior
    ORDER BY created_at DESCENDING.

  IF lt_bugs IS INITIAL.
    MESSAGE 'No bugs found' TYPE 'S'.
    RETURN.
  ENDIF.

  " 2. Map data to display table with colors
  LOOP AT lt_bugs INTO DATA(ls_bug).
    CLEAR ls_display.
    ls_display-bug_id     = ls_bug-bug_id.
    ls_display-title      = ls_bug-title.
    ls_display-sap_module = ls_bug-sap_module.
    ls_display-priority   = ls_bug-priority.
    ls_display-status     = ls_bug-status.
    ls_display-tester_id  = ls_bug-tester_id.
    ls_display-created_at = ls_bug-created_at.

    " Assign color based on status
    CASE ls_bug-status.
      WHEN '1'. ls_display-row_color = 'C100'. " Blue   - New
      WHEN 'W'. ls_display-row_color = 'C310'. " Yellow - Waiting
      WHEN '2'. ls_display-row_color = 'C300'. " Orange - Assigned
      WHEN '3'. ls_display-row_color = 'C500'. " Purple - In Progress
      WHEN '4'. ls_display-row_color = 'C510'. " Green  - Fixed
      WHEN '5'. ls_display-row_color = 'C200'. " Grey   - Closed
    ENDCASE.
    APPEND ls_display TO lt_display.
  ENDLOOP.

  " 3. Build field catalog
  PERFORM build_fieldcat.

  " 4. Display ALV with colors
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'PF_STATUS_SET'
      i_callback_user_command  = 'USER_COMMAND'
      is_layout                = ls_layout
      it_fieldcat              = lt_fieldcat
    TABLES
      t_outtab                 = lt_display
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

*&---------------------------------------------------------------------*
*& Form build_fieldcat
*&---------------------------------------------------------------------*
FORM build_fieldcat.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  ls_layout-info_fieldname = 'ROW_COLOR'.

  DEFINE m_fieldcat.
    clear ls_fieldcat.
    ls_fieldcat-fieldname = &1.
    ls_fieldcat-seltext_m = &2.
    ls_fieldcat-col_pos   = &3.
    append ls_fieldcat to lt_fieldcat.
  END-OF-DEFINITION.

  m_fieldcat 'BUG_ID'     'Bug ID'    1.
  m_fieldcat 'TITLE'      'Title'     2.
  m_fieldcat 'SAP_MODULE' 'Module'    3.
  m_fieldcat 'PRIORITY'   'Priority'  4.
  m_fieldcat 'STATUS'     'Status'    5.
  m_fieldcat 'TESTER_ID'  'Reporter'  6.
  m_fieldcat 'CREATED_AT' 'Created'   7.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form pf_status_set
*&---------------------------------------------------------------------*
FORM pf_status_set USING lv_extab TYPE slis_t_extab.
  SET PF-STATUS 'ZBUG_STATUS'.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form user_command
*&---------------------------------------------------------------------*
FORM user_command USING lv_ucomm TYPE syucomm
                        ls_selfield TYPE slis_selfield.
  DATA: lv_bugid   TYPE zde_bug_id,
        lv_message TYPE string.

  READ TABLE lt_display INDEX ls_selfield-tabindex INTO ls_display.
  lv_bugid = ls_display-bug_id.

  CASE lv_ucomm.
    WHEN 'ZUPD'.  " Nút Update
      SET PARAMETER ID 'ZBG' FIELD lv_bugid.
      CALL TRANSACTION 'ZBUG_UPDATE' AND SKIP FIRST SCREEN.

    WHEN 'ZASGN'. " Nút Auto Assign
      CALL FUNCTION 'Z_BUG_AUTO_ASSIGN'
        EXPORTING iv_bug_id = lv_bugid
                  iv_module = ls_display-sap_module
        IMPORTING ev_message = lv_message.
      MESSAGE lv_message TYPE 'S'.
  ENDCASE.

  ls_selfield-refresh = 'X'.
ENDFORM.
```

Sau khi paste code xong: Click **Save** → **Activate** (Ctrl+F3)

---

### Bước 5.5: Z_BUG_UPLOAD_ATTACHMENT (Đính kèm file qua GOS)

> **Lý do (requirements #5 + extra #4):** Mỗi Bug có 3 loại file đính kèm (ATT_REPORT/ATT_FIX/ATT_VERIFY), mỗi loại do đúng người có trách nhiệm upload. Dùng GOS (Generic Object Services) của SAP với account **DEV-237**.

> [!IMPORTANT]
> Sử dụng account **DEV-237** (Pass: `toiyeufpt`) để thực hiện bước này.

Thực hiện **Quy trình tạo FM chuẩn** ở trên (**đăng nhập bằng DEV-237**) với:

- **Function Module:** `Z_BUG_UPLOAD_ATTACHMENT`
- **Short text:** `Upload Attachment Path for Bug`

**Import Parameters**

| Parameter      | Typing | Associated Type | Pass | Description                  |
| -------------- | ------ | --------------- | ---- | ---------------------------- |
| IV_BUG_ID      | TYPE   | ZDE_BUG_ID      | [x]  | Bug ID                       |
| IV_ATT_TYPE    | TYPE   | CHAR10          | [x]  | REPORT / FIX / VERIFY        |
| IV_FILE_PATH   | TYPE   | ZDE_BUG_ATT_PATH| [x]  | Đường dẫn file lưu trên GOS  |

**Export Parameters**

| Parameter  | Typing | Associated Type | Pass | Description |
| ---------- | ------ | --------------- | ---- | ----------- |
| EV_SUCCESS | TYPE   | CHAR1           | [x]  | Y/N         |
| EV_MESSAGE | TYPE   | STRING          | [x]  | Message     |

```abap
FUNCTION z_bug_upload_attachment.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_ATT_TYPE) TYPE  CHAR10
*"     VALUE(IV_FILE_PATH) TYPE  ZDE_BUG_ATT_PATH
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug  TYPE zbug_tracker.

  " Kiểm tra Bug tồn tại
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Bug not found'.
    RETURN.
  ENDIF.

  " Kiểm tra bug đã Closed - không cho upload thêm
  IF ls_bug-status = '5'.
    ev_success = 'N'.
    ev_message = 'Bug is Closed. Attachments cannot be modified.'.
    RETURN.
  ENDIF.

  " Cập nhật path file vào trường tương ứng
  CASE iv_att_type.
    WHEN 'REPORT'.
      UPDATE zbug_tracker SET att_report = @iv_file_path
        WHERE bug_id = @iv_bug_id.
    WHEN 'FIX'.
      UPDATE zbug_tracker SET att_fix = @iv_file_path
        WHERE bug_id = @iv_bug_id.
    WHEN 'VERIFY'.
      UPDATE zbug_tracker SET att_verify = @iv_file_path
        WHERE bug_id = @iv_bug_id.
    WHEN OTHERS.
      ev_success = 'N'.
      ev_message = 'Invalid attachment type. Use: REPORT, FIX, VERIFY'.
      RETURN.
  ENDCASE.

  IF sy-subrc = 0.
    COMMIT WORK.
    ev_success = 'Y'.
    CONCATENATE 'File ' iv_att_type ' uploaded successfully for Bug ' iv_bug_id INTO ev_message.
  ELSE.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Failed to update attachment path'.
  ENDIF.

ENDFUNCTION.
```

Click **Save** → **Activate**

> [!NOTE]
> Để upload file thực sự lên GOS, sử dụng FM `GOS_EXECUTE_OPTION` hoặc class `CL_GOS_MANAGER` trong màn hình `Z_BUG_UPDATE_SCREEN`. GOS cho phép user duyệt file từ máy local và đính kèm vào object SAP.

---

### Bước 5.6: Z_BUG_REASSIGN (Developer từ chối - Re-assign)

> **Lý do (extra-requirements #3):** Developer có thể từ chối Bug và yêu cầu Manager re-assign, hoặc Manager có thể chủ động re-assign cho Dev khác.

Thực hiện **Quy trình tạo FM chuẩn** ở trên với:

- **Function Module:** `Z_BUG_REASSIGN`
- **Short text:** `Re-assign Bug to Another Developer`

**Import Parameters**

| Parameter       | Typing | Associated Type | Pass | Description                    |
| --------------- | ------ | --------------- | ---- | ------------------------------ |
| IV_BUG_ID       | TYPE   | ZDE_BUG_ID      | [x]  | Bug ID                         |
| IV_NEW_DEV_ID   | TYPE   | ZDE_USERNAME    | [x]  | Dev mới được assign            |
| IV_REASON       | TYPE   | ZDE_REASONS     | [x]  | Lý do re-assign                |
| IV_REQUESTED_BY | TYPE   | ZDE_USERNAME    | [x]  | Người yêu cầu (Dev hay Manager)|

**Export Parameters**

| Parameter  | Typing | Associated Type | Pass | Description |
| ---------- | ------ | --------------- | ---- | ----------- |
| EV_SUCCESS | TYPE   | CHAR1           | [x]  | Y/N         |
| EV_MESSAGE | TYPE   | STRING          | [x]  | Message     |

```abap
FUNCTION z_bug_reassign.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_NEW_DEV_ID) TYPE  ZDE_USERNAME
*"     VALUE(IV_REASON) TYPE  ZDE_REASONS
*"     VALUE(IV_REQUESTED_BY) TYPE  ZDE_USERNAME
*"  EXPORTING
*"     VALUE(EV_SUCCESS) TYPE  CHAR1
*"     VALUE(EV_MESSAGE) TYPE  STRING
*"----------------------------------------------------------------------

  DATA: ls_bug        TYPE zbug_tracker,
        lv_old_dev_id TYPE zde_username.

  " Kiểm tra Bug
  SELECT SINGLE * FROM zbug_tracker INTO @ls_bug
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc <> 0.
    ev_success = 'N'.
    ev_message = 'Bug not found'.
    RETURN.
  ENDIF.

  lv_old_dev_id = ls_bug-dev_id.

  " Cập nhật Dev mới
  UPDATE zbug_tracker
    SET dev_id = @iv_new_dev_id,
        status = '2'
    WHERE bug_id = @iv_bug_id.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Re-assign failed'.
    RETURN.
  ENDIF.

  " Trả Dev cũ về Available
  UPDATE zbug_users
    SET available_status = 'A'
    WHERE user_id = @lv_old_dev_id.

  " Đặt Dev mới thành Working
  UPDATE zbug_users
    SET available_status = 'W'
    WHERE user_id = @iv_new_dev_id.

  COMMIT WORK.

  " Log history
  CALL FUNCTION 'Z_BUG_LOG_HISTORY'
    EXPORTING
      iv_bug_id      = iv_bug_id
      iv_action_type = 'RS'
      iv_old_value   = lv_old_dev_id
      iv_new_value   = iv_new_dev_id
      iv_reason      = iv_reason.

  ev_success = 'Y'.
  CONCATENATE 'Bug ' iv_bug_id ' re-assigned from ' lv_old_dev_id ' to ' iv_new_dev_id INTO ev_message.

ENDFUNCTION.
```

Click **Save** → **Activate**

---

## PHASE 6: TESTING & OPTIMIZATION (Tuần 6)

> [!TIP]
> **Tài khoản sử dụng:**
>
> - Code Inspector & Testing: **DEV-118** (Pass: `Qwer123@`)
> - File Attachment Testing: **DEV-237** (Pass: `toiyeufpt`)

### Bước 6.1: Unit Testing - Toàn Bộ Edge Cases

**Mục đích:** Test từng Function Module riêng lẻ với các tình huống biên (edge cases).

#### 6.1.1 Unit Test: Z_BUG_CREATE

> **Mandatory fields trên màn hình:** P_TITLE, P_MODULE, P_DESC là OBLIGATORY. P_PRIOR có DEFAULT='M'. P_DEVID là optional.
>
> **Thứ tự fields:** P_TITLE → P_MODULE → P_PRIOR → P_DEVID → P_DESC
>
> **Lưu ý:** SAP tự động uppercase giá trị nhập vào CHAR fields (VD: "Network Error" → "NETWORK ERROR"). P_DESC có LOWER CASE nên giữ nguyên. Đây là hành vi chuẩn của SAP.

| # | Test Case | Input | Expected | Edge Case |
| :--- | :--- | :--- | :--- | :--- |
| U-1.1 | Create Bug Normal | Title="Network Error", Module="FI", Priority="M", Desc="API Down" | BUG_ID sinh (BUG0000001), Status='1' | ✅ |
| U-1.2 | Create with Empty Title | Title="", Module="FI", Priority="M" | SAP Error: "Make an entry in mandatory field "P_TITLE"" | ❌ OBLIGATORY Check |
| U-1.3 | Create with Max Length | Title=128 chars, Module="FI", Priority="M", Desc=255 chars | Bug tạo thành công. TITLE bị cắt còn 100 chars (CHAR 100 silent truncate). DESC bị cắt còn 255 chars (P_DESC là CHAR255, không phải STRING) | Edge: Boundary Test |
| U-1.4 | Create with Special Chars | Title="<BUG & TEST>'", Module="FI", Priority="M", Desc="SELECT * FROM TABLE A;" | Bug tạo thành công. SAP OpenSQL dùng parameterized query → không bị SQL Injection. Ký tự đặc biệt lưu as-is | Security: SQLi Safe |
| U-1.5 | Create with Duplicate | Title="Network Error", Module="FI", Priority="M" (run twice) | Second create = different BUG_ID | Unique ID Generation |
| U-1.6 | Create with High Priority | Title="Critical Crash", Module="FI", Priority="H", Desc="API Down" | Bug tạo thành công, Status='1' (New). Auto-assign KHÔNG tự trigger — cần gọi riêng qua ALV toolbar | Priority chỉ là metadata, không trigger auto-assign |

**Test Steps for U-1.1:**

1. T-code: `ZBUG_CREATE`
2. Nhập: P_TITLE="Network Error", P_MODULE="FI", P_PRIOR="M", P_DESC="API Down"
3. Click Execute (F8)
4. **Expected:** Status bar xanh: "Bug BUG00000xx created successfully" (xx = số tự tăng từ ZNRO_BUG)
5. **Verify:** SE16N → ZBUG_TRACKER → Check new record (P_TITLE sẽ hiển thị uppercase)

**Edge Case Handling:**

- **Concurrency:** Create 2 bugs simultaneously → Both get unique IDs (check ZBUG_TRACKER primary key)
- **Rollback:** If email fails, bug still created? (Expected: YES, email is non-blocking)
- **Data Integrity:** After create, ZBUG_HISTORY should have entry with ACTION_TYPE='CR' (Create)

---

#### 6.1.2 Unit Test: Z_BUG_UPDATE_STATUS

> [!IMPORTANT]
> **Prerequisite:** Đã apply **Fix v3** (`sy-ucomm`) cho `Z_BUG_UPDATE_SCREEN` (xem Bước 3.3).
> Nếu chưa apply, `AT SELECTION-SCREEN` sẽ ghi đè p_status mỗi lần Execute → mọi test case sẽ fail.
>
> **Hành vi FM `Z_BUG_UPDATE_STATUS`** (theo source code):
> - Luôn **ghi đè** `DESC_TEXT` bằng `IV_REASON` (dù trống → mất description gốc)
> - Luôn **ghi đè** `DEV_ID` bằng `IV_DEV_ID` (dù trống → clear dev assignment)
> - Nếu `IV_NEW_STATUS = '5'` (Closed) → thêm set `CLOSED_AT = SY-DATUM`
> - **Không** có idempotent check (same→same vẫn succeed)
> - **Không** có state machine (any→any transition được phép)
> - **Không** gọi `Z_BUG_CHECK_PERMISSION` bên trong FM

| # | Test Case | Current Status | New Status | Expected | Edge Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| U-2.1 | Update Normal | '1' (New) | '2' (Assigned) | ✅ "Status updated successfully". SE16N: STATUS='2' | Happy Path |
| U-2.2 | Invalid Status | '1' | '9' (not exists) | ❌ SAP domain check: "'9' is not in the value range". FM KHÔNG được gọi | Domain Fixed Values |
| U-2.3 | Same Status | '2' | '2' | ✅ "Status updated successfully" — FM không check old=new | No idempotent check |
| U-2.4 | Reverse Transition | '5' (Closed) | '1' (New) | ✅ "Status updated successfully" — FM cho phép '5'→'1' | No state machine |
| U-2.5 | Update with Reason | '1' (New) | '3' (InProgress) | ✅ "Status updated successfully". **⚠️ DESC_TEXT bị ghi đè** bằng P_REASON | DESC_TEXT overwrite |
| U-2.6 | Empty DEV_ID | '1' (New) | '2' (Assigned) | ✅ "Status updated successfully". **⚠️ DEV_ID bị clear** vì P_DEVID trống | DEV_ID overwrite |

---

**U-2.1: Update Normal (1→2)**

> Test bug: `BUG0000003` (Status='1', Title="NETWORK ERROR")

**Precondition:** SE16N → ZBUG_TRACKER → verify BUG0000003 has STATUS='1'

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Mở T-code `ZBUG_UPDATE` | |
| 2 | Nhập P_BUGID | `BUG0000003` |
| 3 | Nhấn **Enter** | Pre-fill: P_STATUS hiện '1', P_DEVID hiện 'DEV-118' |
| 4 | Sửa P_STATUS | Xóa '1', gõ `2` |
| 5 | Nhập P_DEVID | `DEV-118` (giữ nguyên hoặc nhập lại — **không để trống** vì FM ghi đè) |
| 6 | Nhập P_REASON | `Assigned to developer` |
| 7 | Click **Execute (F8)** | |
| 8 | **Expected:** | Status bar xanh: `"Status updated successfully"` |

**Verify:**
1. SE16N → ZBUG_TRACKER → WHERE BUG_ID = 'BUG0000003'
2. Check: `STATUS = '2'`, `DEV_ID = 'DEV-118'`, `DESC_TEXT = 'Assigned to developer'`
3. SE16N → ZBUG_HISTORY → WHERE BUG_ID = 'BUG0000003'
4. Check: Có entry mới `ACTION_TYPE='ST'`, `OLD_VALUE='1'`, `NEW_VALUE='2'`

**Kết quả thực tế: ✅ PASS** (Fix v3 `sy-ucomm` hoạt động)
- P_DEVID để trống → DEV_ID bị clear (đúng hành vi FM — xem U-2.6)
- P_REASON để trống → DESC_TEXT bị clear (đúng hành vi FM — xem U-2.5)
- STATUS thay đổi 1→2 trong DB ✓

**Screenshots:**

| Ảnh | File | Nội dung |
| :--- | :--- | :--- |
| Before | `images/verify/phase6/u2_1_before_se16n.png` | SE16N: BUG0000003 STATUS='1' |
| Action | `images/verify/phase6/u2_1_update_action.png` | ZBUG_UPDATE: P_STATUS='2', "Status updated successfully" |
| After | `images/verify/phase6/u2_1_after_se16n.png` | SE16N: BUG0000003 STATUS='2' |

---

**U-2.2: Invalid Status Value ('9')**

> Test bug: `BUG0000004` (Status='1')

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Mở T-code `ZBUG_UPDATE` | |
| 2 | Nhập P_BUGID | `BUG0000004` |
| 3 | Nhấn **Enter** | Pre-fill: P_STATUS='1' |
| 4 | Sửa P_STATUS | Xóa '1', gõ `9` |
| 5 | Nhấn **Enter** hoặc **F8** | |
| 6 | **Expected:** | Popup / error: `"'9' is not in the value range"` hoặc `"Entry 9 does not exist in ZDOM_STATUS"`. FM KHÔNG được gọi — SAP domain check chặn trước |

**Verify:**
1. SE16N → ZBUG_TRACKER → BUG0000004 → STATUS vẫn = '1' (không đổi)
2. ZBUG_HISTORY → không có entry mới cho BUG0000004

**Screenshot:** `images/verify/phase6/u2_2_invalid_status_domain.png`

> **Lưu ý:** Domain `ZDOM_STATUS` có Fixed Values: `1, W, 2, 3, 4, 5, 6`. Bất kỳ giá trị nào ngoài danh sách này đều bị SAP Selection Screen reject. Thử thêm các giá trị: `0`, `7`, `A`, `X` — tất cả đều phải bị chặn.

---

**U-2.3: Same Status (2→2, No Change)**

> Test bug: `BUG0000003` (sau U-2.1 đã update lên Status='2')

**Precondition:** BUG0000003.STATUS = '2' (đã pass U-2.1)

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Mở T-code `ZBUG_UPDATE` | |
| 2 | Nhập P_BUGID | `BUG0000003` |
| 3 | Nhấn **Enter** | Pre-fill: P_STATUS='2' |
| 4 | **KHÔNG sửa gì** | Giữ P_STATUS='2' |
| 5 | Nhập P_DEVID | `DEV-118` |
| 6 | Click **Execute (F8)** | |
| 7 | **Expected:** | `"Status updated successfully"` — FM update '2'→'2' thành công |

**Verify:**
1. SE16N → BUG0000003 → STATUS vẫn = '2'
2. ZBUG_HISTORY → có entry mới ACTION_TYPE='ST', OLD_VALUE='2', NEW_VALUE='2'

> **Ghi nhận (Limitation):** FM `Z_BUG_UPDATE_STATUS` không so sánh status cũ với mới. UPDATE cùng giá trị vẫn thành công và tạo history log. Đây không phải bug mà là thiếu idempotent check.

---

**U-2.4: Reverse Transition (Closed→New, 5→1)**

> Test bug: `BUG0000003`. Cần đưa về Status='5' trước.

**Precondition — Đưa bug lên Status='5':**

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_UPDATE` → BUG0000003 → Enter | Pre-fill P_STATUS='2' |
| 2 | Sửa P_STATUS = `5`, P_DEVID = `DEV-118` | |
| 3 | Execute (F8) | "Status updated successfully" |
| 4 | SE16N verify | STATUS='5', CLOSED_AT = ngày hôm nay (SY-DATUM) |

**Test chính — Reverse transition 5→1:**

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_UPDATE` → BUG0000003 → Enter | Pre-fill P_STATUS='5' |
| 2 | Sửa P_STATUS = `1`, P_DEVID = `DEV-118` | |
| 3 | Execute (F8) | |
| 4 | **Expected:** | `"Status updated successfully"` — FM cho phép reopen |

**Verify:**
1. SE16N → BUG0000003 → STATUS = '1' (đã reopen)
2. **Lưu ý:** CLOSED_AT vẫn giữ giá trị cũ (FM chỉ set CLOSED_AT khi status='5', không clear khi khác '5')
3. ZBUG_HISTORY → entry mới: OLD_VALUE='5', NEW_VALUE='1'

> **Ghi nhận (Limitation):** FM không có state machine. Bất kỳ transition nào đều được phép (1→5, 5→1, 6→3, etc.). Nên bổ sung validation nếu cần business logic chặt chẽ.

---

**U-2.5: Update with Reason → DESC_TEXT bị ghi đè**

> Test bug: `BUG0000005` (Title="<BUG & TEST>'", DESC_TEXT gốc = "SELECT * FROM TABLE A;")

**Precondition:** SE16N → verify BUG0000005.DESC_TEXT = 'SELECT * FROM TABLE A;'

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_UPDATE` → P_BUGID = `BUG0000005` → Enter | Pre-fill P_STATUS='1' |
| 2 | Sửa P_STATUS = `3` | |
| 3 | Nhập P_DEVID | `DEV-118` |
| 4 | Nhập P_REASON | `Bug confirmed, start fixing` |
| 5 | Execute (F8) | |
| 6 | **Expected:** | `"Status updated successfully"` |

**Verify:**
1. SE16N → BUG0000005:
   - STATUS = '3' ✓
   - **DESC_TEXT = 'Bug confirmed, start fixing'** ← ghi đè description gốc "SELECT * FROM TABLE A;"
2. ZBUG_HISTORY → entry mới: OLD_VALUE='1', NEW_VALUE='3'

> **⚠️ Side Effect nghiêm trọng:** FM `Z_BUG_UPDATE_STATUS` dùng `desc_text = @iv_reason` → reason **thay thế** toàn bộ description gốc, không append. Nếu P_REASON trống → DESC_TEXT bị xóa hoàn toàn. Đây là limitation cần ghi nhận.

---

**U-2.6: Empty DEV_ID → Clear Dev Assignment**

> Test bug: `BUG0000006` (Title="NETWORK ERROR", DEV_ID='DEV-118')

**Precondition:** SE16N → verify BUG0000006.DEV_ID = 'DEV-118'

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_UPDATE` → P_BUGID = `BUG0000006` → Enter | Pre-fill P_STATUS='1', P_DEVID='DEV-118' |
| 2 | Sửa P_STATUS = `2` | |
| 3 | **Xóa P_DEVID** | Để trống |
| 4 | Execute (F8) | |
| 5 | **Expected:** | `"Status updated successfully"` |

**Verify:**
1. SE16N → BUG0000006:
   - STATUS = '2' ✓
   - **DEV_ID = '' (trống!)** ← FM ghi đè bằng giá trị trống từ P_DEVID
2. ZBUG_HISTORY → entry mới: OLD_VALUE='1', NEW_VALUE='2'

> **⚠️ Side Effect:** FM dùng `dev_id = @iv_dev_id` → nếu user không nhập P_DEVID, DEV_ID bị clear. Ảnh hưởng: bug mất dev assignment. Workaround: luôn nhập lại P_DEVID khi update.

---

**Tổng kết chạy tuần tự U-2.x:**

| Test | Bug ID | Before | After | Status |
| :--- | :--- | :--- | :--- | :--- |
| U-2.1 | BUG0000003 | STATUS='1' | STATUS='2' | ✅ |
| U-2.2 | BUG0000004 | STATUS='1' | STATUS='1' (không đổi) | ✅ Domain check |
| U-2.3 | BUG0000003 | STATUS='2' | STATUS='2' (same) | ✅ Limitation |
| U-2.4 | BUG0000003 | STATUS='5' | STATUS='1' (reopen) | ✅ Limitation |
| U-2.5 | BUG0000005 | STATUS='1', DESC gốc | STATUS='3', DESC bị ghi đè | ✅ Side effect |
| U-2.6 | BUG0000006 | DEV_ID='DEV-118' | DEV_ID='' (cleared) | ✅ Side effect |

> **Lưu ý thứ tự:** U-2.3 và U-2.4 phụ thuộc U-2.1 (cần BUG0000003 ở status='2'). Chạy đúng thứ tự từ U-2.1 → U-2.6.

---

#### 6.1.3 Unit Test: Z_BUG_AUTO_ASSIGN

> [!IMPORTANT]
> **Hành vi FM `Z_BUG_AUTO_ASSIGN`** (theo source code):
> 1. SELECT devs từ `ZBUG_USERS` WHERE `sap_module = IV_MODULE` AND `role = 'D'` AND `available_status = 'A'` AND `is_active = 'X'`
> 2. Nếu không có dev → set bug Status='W' (Waiting), return "No developer available"
> 3. Đếm workload mỗi dev: `COUNT(*)` bugs trong ZBUG_TRACKER WHERE `dev_id = user` AND `status IN ('2','3')`
> 4. Assign bug cho dev có workload **thấp nhất** → UPDATE bug: `dev_id = dev`, `status = '2'`
> 5. UPDATE dev: `available_status = 'W'` (Working)
>
> **Trigger:** ALV Report (`ZBUG_REPORT`) → Click chọn 1 bug → Click nút **Auto Assign** (ZASGN) trên toolbar
>
> **⚠️ Lưu ý quan trọng:** FM set dev thành `available_status='W'` sau khi assign. Dev đó sẽ **KHÔNG** được assign tiếp trong lần gọi tiếp theo (vì WHERE clause chỉ lấy `available_status = 'A'`). Muốn assign bug tiếp cho cùng dev → phải sửa lại `available_status = 'A'` trong ZBUG_USERS.

**Prerequisite — Kiểm tra và chuẩn bị dữ liệu ZBUG_USERS:**

1. SE16N → `ZBUG_USERS` → F8 → Xem danh sách users hiện tại
2. Đảm bảo có **ít nhất 1 Developer** với: `ROLE='D'`, `SAP_MODULE='FI'`, `AVAILABLE_STATUS='A'`, `IS_ACTIVE='X'`
3. Nếu chưa có, thêm dummy data qua SE16N (Edit mode):

| USER_ID | ROLE | FULL_NAME | SAP_MODULE | AVAILABLE_STATUS | IS_ACTIVE | EMAIL |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| DEV-001 | D | Developer One | FI | A | X | dev1@test.com |
| DEV-002 | D | Developer Two | FI | A | X | dev2@test.com |
| DEV-003 | D | Developer Three | FI | A | X | dev3@test.com |

4. **Screenshot** ZBUG_USERS trước khi test → `images/verify/phase6/u3_0_zbug_users_before.png`

| # | Test Case | Scenario | Expected | Edge Case |
| :--- | :--- | :--- | :--- | :--- |
| U-3.1 | Assign Normal | 1+ Dev available (status='A'), bug Status='1' | Bug: Status='2', DEV_ID=dev có workload thấp nhất. Dev: available_status='W' | ✅ Load Balancing |
| U-3.2 | All Devs Busy | Tất cả Devs có AVAILABLE_STATUS='W' | Bug: Status='W' (Waiting), DEV_ID không đổi. Message: "No developer available" | Queue Waiting |
| U-3.3 | No Dev for Module | Bug Module='FI', không có Dev nào module='FI' và available | Bug: Status='W'. Message: "No developer available" | No Dev Available |
| U-3.4 | Assign 2nd Bug | Sau U-3.1, dev đã busy. Có dev thứ 2 available | Assign cho dev thứ 2 (vì dev 1 đã 'W') | Round-robin tự nhiên |
| U-3.5 | Assign Inactive Dev | Dev có available_status='A' nhưng is_active ≠ 'X' | Skip dev đó, chọn dev active khác. Nếu không có → Status='W' | Data Quality |

---

**U-3.1: Assign Normal**

> Test bug: `BUG0000003` (Status='1', Module='FI', DEV_ID trống)

**Precondition:**
1. SE16N → ZBUG_TRACKER → verify BUG0000003: STATUS='1', DEV_ID=trống
2. SE16N → ZBUG_USERS → verify có ít nhất 1 Dev: ROLE='D', SAP_MODULE='FI', AVAILABLE_STATUS='A', IS_ACTIVE='X'
3. Ghi nhận Dev nào sẽ được assign (dev có ít bug nhất ở status '2' hoặc '3')

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Mở T-code `ZBUG_REPORT` | ALV Report hiển thị danh sách bugs |
| 2 | **Click chọn dòng** BUG0000003 | Click vào dòng để highlight |
| 3 | Click nút **Auto Assign** trên toolbar | Button function code: ZASGN |
| 4 | **Expected:** | Status bar xanh: `"Bug assigned to DEV-xxx"` (DEV-xxx = dev có workload thấp nhất) |

**Verify:**
1. SE16N → ZBUG_TRACKER → WHERE BUG_ID = 'BUG0000003'
   - `STATUS = '2'` (Assigned) ✓
   - `DEV_ID = 'DEV-xxx'` (dev được assign) ✓
2. SE16N → ZBUG_USERS → WHERE USER_ID = 'DEV-xxx'
   - `AVAILABLE_STATUS = 'W'` (Working) ✓
3. ALV Report tự refresh (do `ls_selfield-refresh = 'X'`)

**Screenshot:** `images/verify/phase6/u3_1_assign_normal.png`

---

**U-3.2: All Devs Busy**

> Test bug: `BUG0000004` (Status='1', Module='FI')

**Precondition — Đưa tất cả Devs về Busy:**
1. SE16N → ZBUG_USERS → Edit mode
2. Set **tất cả** Devs có ROLE='D' AND SAP_MODULE='FI': `AVAILABLE_STATUS = 'W'`
3. Save → verify không còn Dev nào `AVAILABLE_STATUS = 'A'` cho module FI

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Mở T-code `ZBUG_REPORT` | |
| 2 | Click chọn dòng BUG0000004 | |
| 3 | Click **Auto Assign** | |
| 4 | **Expected:** | Status bar: `"No developer available. Bug set to Waiting."` |

**Verify:**
1. SE16N → ZBUG_TRACKER → BUG0000004:
   - `STATUS = 'W'` (Waiting) ✓
   - `DEV_ID` = trống (không assign) ✓
2. ZBUG_HISTORY → không có entry mới (FM không gọi Z_BUG_LOG_HISTORY)

**Screenshot:** `images/verify/phase6/u3_2_all_devs_busy.png`

> **Lưu ý:** FM **không** gọi `Z_BUG_LOG_HISTORY` khi set Status='W'. Chỉ UPDATE trực tiếp `zbug_tracker SET status = 'W'` và COMMIT. Đây là limitation — không có history log cho trạng thái Waiting.

**Cleanup sau U-3.2:** Nếu muốn test tiếp U-3.3/3.4, cần reset:
- ZBUG_USERS: đổi lại `AVAILABLE_STATUS = 'A'` cho các Devs
- ZBUG_TRACKER: đổi BUG0000004 `STATUS = '1'` nếu cần test lại

---

**U-3.3: No Dev for Module**

> Test bug: `BUG0000005` (Status='1', Module='FI')

**Precondition — Xóa hoặc đổi module tất cả Devs:**

> **Cách 1 (dễ revert):** SE16N → ZBUG_USERS → tạm đổi tất cả Devs (ROLE='D'): `SAP_MODULE = 'MM'` (khác với 'FI' của bug)
>
> **Cách 2:** Nếu hệ thống cho phép, tạm `IS_ACTIVE = ''` (deactivate) tất cả Devs module FI

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | Verify ZBUG_USERS | Không có Dev nào: ROLE='D' AND SAP_MODULE='FI' AND AVAILABLE_STATUS='A' AND IS_ACTIVE='X' |
| 2 | `ZBUG_REPORT` → Click BUG0000005 | |
| 3 | Click **Auto Assign** | |
| 4 | **Expected:** | `"No developer available. Bug set to Waiting."` |

**Verify:**
1. SE16N → BUG0000005: STATUS='W', DEV_ID trống ✓

**Cleanup:** Đổi lại `SAP_MODULE = 'FI'` cho Devs

**Screenshot:** `images/verify/phase6/u3_3_no_dev_module.png`

> **Ghi nhận:** FM trả cùng message "No developer available" cho cả trường hợp All Busy lẫn No Dev for Module. Không phân biệt lý do.

---

**U-3.4: Assign 2nd Bug (sau khi Dev đã Busy)**

> Test bug: `BUG0000006` (Status='1', Module='FI')
> Chạy **sau U-3.1** — dev đầu tiên đã bị set `available_status='W'`

**Precondition:**
1. Đã chạy U-3.1 → DEV-xxx (dev đầu tiên) đã `AVAILABLE_STATUS='W'`
2. Có ít nhất **1 Dev khác** còn `AVAILABLE_STATUS='A'`, ROLE='D', SAP_MODULE='FI', IS_ACTIVE='X'
3. Nếu chỉ có 1 dev duy nhất → test này sẽ cho kết quả giống U-3.2 (No dev available)

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_REPORT` → Click BUG0000006 | |
| 2 | Click **Auto Assign** | |
| 3 | **Expected:** | `"Bug assigned to DEV-yyy"` (DEV-yyy ≠ DEV-xxx từ U-3.1) |

**Verify:**
1. SE16N → BUG0000006: STATUS='2', DEV_ID='DEV-yyy' ✓
2. SE16N → ZBUG_USERS: DEV-yyy `AVAILABLE_STATUS='W'` ✓

**Screenshot:** `images/verify/phase6/u3_4_assign_second_bug.png`

> Nếu có 3 Devs (DEV-001, DEV-002, DEV-003) tất cả available:
> - U-3.1: BUG0000003 → DEV-001 (workload 0, lowest) → DEV-001 becomes 'W'
> - U-3.4: BUG0000006 → DEV-002 or DEV-003 (cả hai workload 0, FM lấy người đầu tiên trong SELECT)

---

**U-3.5: Inactive Dev bị Skip**

> Test bug: `BUG0000007` (Status='1', Module='FI')

**Precondition:**
1. SE16N → ZBUG_USERS → Dev A: ROLE='D', SAP_MODULE='FI', AVAILABLE_STATUS='A', **IS_ACTIVE=''** (inactive)
2. Dev B: ROLE='D', SAP_MODULE='FI', AVAILABLE_STATUS='A', IS_ACTIVE='X' (active)

| Step | Action | Chi tiết |
| :--- | :--- | :--- |
| 1 | `ZBUG_REPORT` → Click BUG0000007 | |
| 2 | Click **Auto Assign** | |
| 3 | **Expected:** | `"Bug assigned to DEV-B"` — Dev A bị skip vì IS_ACTIVE ≠ 'X' |

**Verify:**
1. SE16N → BUG0000007: DEV_ID = Dev B (active) ✓
2. Dev A không bị ảnh hưởng (AVAILABLE_STATUS vẫn 'A')

**Screenshot:** `images/verify/phase6/u3_5_skip_inactive_dev.png`

---

**Tổng kết chạy tuần tự U-3.x:**

> **Khuyến nghị thứ tự:** U-3.1 → U-3.4 → U-3.5 → U-3.2 → U-3.3
> (Chạy U-3.2 và U-3.3 cuối vì cần manipulate ZBUG_USERS — sau đó cleanup)

| Test | Bug ID | Before | After | Cần chuẩn bị ZBUG_USERS? |
| :--- | :--- | :--- | :--- | :--- |
| U-3.1 | BUG0000003 | STATUS='1', no dev | STATUS='2', DEV_ID=dev1 | Có Dev available ✓ |
| U-3.4 | BUG0000006 | STATUS='1', no dev | STATUS='2', DEV_ID=dev2 | Dev1 đã busy, có dev2 ✓ |
| U-3.5 | BUG0000007 | STATUS='1', no dev | STATUS='2', DEV_ID=active dev | 1 active + 1 inactive ✓ |
| U-3.2 | BUG0000004 | STATUS='1' | STATUS='W' | Set all devs busy ✓ |
| U-3.3 | BUG0000005 | STATUS='1' | STATUS='W' | Đổi module hoặc deactivate ✓ |

> **Cleanup cuối cùng:** Sau khi test xong, nhớ restore ZBUG_USERS về trạng thái ban đầu (đúng SAP_MODULE, AVAILABLE_STATUS, IS_ACTIVE).

---

#### 6.1.4 Unit Test: Z_BUG_CHECK_PERMISSION

| # | Test Case | User Role | Action | Bug Status | Expected | Edge Case |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| U-4.1 | Manager Full Access | M (Manager) | CREATE | - | Allowed | ✅ |
| U-4.2 | Tester Create | T (Tester) | CREATE | - | Allowed | ✅ |
| U-4.3 | Dev Create (denied) | D (Developer) | CREATE | - | Denied | ❌ Role Check |
| U-4.4 | Dev Update Own Bug | D | UPDATE_STATUS | Bug.DEV_ID=Dev | Allowed | ✅ Ownership Check |
| U-4.5 | Dev Update Others' Bug | D | UPDATE_STATUS | Bug.DEV_ID≠Dev | Denied | ❌ Unauthorized |
| U-4.6 | Tester Upload Fix (denied) | T | UPLOAD_FIX | - | Denied | ❌ Role Check |
| U-4.7 | Manager Override | M | Any action | Any | Allowed | ✅ Admin Override |

**Test Steps for U-4.4:**

1. Login as Developer 'D001'
2. Bug #001: DEV_ID='D001', Status='2'
3. Try: UPDATE_STATUS '2'→'3'
4. **Expected:** Allowed, status updated to '3'

**Test Steps for U-4.5:**

1. Login as Developer 'D001'
2. Bug #002: DEV_ID='D002' (different dev)
3. Try: UPDATE_STATUS '2'→'3'
4. **Expected:** Error message: "You can only update bugs assigned to you"

---

### Bước 6.2: Performance Testing

**Mục đích:** Verify hệ thống xử lý được lượng dữ liệu lớn với performance tốt.

#### 6.2.1 Load Test

**Setup Data:**

- Insert 1,000 bugs vào ZBUG_TRACKER
- Insert 50 users (Managers: 5, Testers: 20, Developers: 25)
- Insert 2,000+ history logs vào ZBUG_HISTORY

**Benchmark Targets:**

| T-code | Operation | Target Response Time |
| :--- | :--- | :--- |
| `ZBUG_REPORT` | Display all 1000 bugs | < 3 seconds |
| `ZBUG_REPORT` | Filter by module (200 results) | < 1.5 seconds |
| `ZBUG_UPDATE` | Load bug detail (with history) | < 2 seconds |
| `ZBUG_MANAGER` | Dashboard summary | < 2 seconds |
| `Z_BUG_AUTO_ASSIGN` | Auto-assign (3 devs, 10 available bugs) | < 1 second |
| `ZBUG_PRINT` | Generate SmartForm preview | < 5 seconds |

**Test Steps:**

1. **Use SE38 → Utility Program to bulk insert test data**

   ```abap
   REPORT Z_TEST_DATA_LOAD.

   LOOP AT i_bugs INTO wa_bug.
     INSERT INTO zbug_tracker VALUES wa_bug.
   ENDLOOP.
   COMMIT WORK.
   ```

2. **Run T-code with timer**
   - Activate SAP profiling (ST05 trace)
   - Execute T-code (e.g., ZBUG_REPORT with no filters)
   - Check: Response time in status bar
   - If > target: Check database indexes, optimize SELECT statements

3. **Verify Database Indexes**
   - SE11 → ZBUG_TRACKER → Indexes tab
   - Expected indexes:
     - Primary: BUG_ID
     - Secondary: DEV_ID (for workload query)
     - Secondary: STATUS (for status filter)

---

### Bước 6.3: Integration Testing

**Mục đích:** Test cross-system workflows & FM interactions.

#### 6.3.1 End-to-End Workflow: Create → Assign → Update → Close

**Scenario:** Complete bug lifecycle

| Step | Action | Verification | Expected Result |
| :--- | :--- | :--- | :--- |
| 1 | Create bug via `ZBUG_CREATE` | Check ZBUG_TRACKER | Bug#001 created, Status='1' (New) |
| 2 | Auto-assign via `Z_BUG_AUTO_ASSIGN` | Check DEV_ID, AVAILABLE_STATUS | Bug assigned to D001, D001.AVAILABLE_STATUS='W' |
| 3 | Dev updates status `ZBUG_UPDATE` | Check ZBUG_HISTORY | New log entry: ACTION_TYPE='ST', CHANGED_BY='D001' |
| 4 | Upload fix attachment `Z_BUG_UPLOAD_ATTACHMENT` | Check ZBUG_TRACKER.ATT_FIX | Path stored correctly |
| 5 | Manager verifies & closes | Check Status, CLOSED_AT | Status='5', CLOSED_AT=SY-DATUM |

**Test Execution:**

1. Execute step 1-5 in sequence
2. After each step, verify database state via SE16N (table display)
3. Check ZBUG_HISTORY for all changes logged
4. Check emails sent (SCOT table) for notifications

#### 6.3.2 Integration: Concurrent Operations

**Scenario:** Multiple users acting simultaneously

1. **User A** (Tester): Create Bug#001, Status='1'
2. **User B** (Manager): Simultaneously runs Auto-Assign
3. **User C** (Dev): Simultaneously tries to Update Bug#001

**Expected Behavior:**

- User A: Creates successfully
- User B: Auto-assign waits for create to finish, then assigns
- User C: Gets lock error (bug is locked by create/assign), retry succeeds after lock release

**Verify:**

- No data corruption
- No deadlock
- All operations eventually succeed

---

### Bước 6.4: UAT Checklist - 12 Test Cases (Chi Tiết)

> **Hướng dẫn:** Mỗi test case dưới đây có:
>
> - **Purpose:** Mục đích test
> - **Preconditions:** Điều kiện ban đầu
> - **Steps:** Các bước thực hiện
> - **Expected Results:** Kết quả kỳ vọng
> - **Edge Cases:** Tình huống biên
> - **Screenshot Location:** Nơi lưu evidence

---

#### TC-P6-01: Tạo Bug Mới (Create Bug)

**Purpose:** Xác minh người dùng có thể tạo bug mới với đầy đủ thông tin

**Preconditions:**

- DEV-061 đã login vào SAP (Role: Tester)
- T-code ZBUG_CREATE available

**Steps:**

1. T-code: **ZBUG_CREATE**
2. Fill form:
   - Title: "Login button not working"
   - Description: "Click login button, page hangs"
   - Priority: "M" (Medium)
   - Module: "FI"
3. Click **Submit** button

**Expected Results:**

- ✅ Dialog appears: "Bug #0001 created successfully"
- ✅ New record created in ZBUG_TRACKER
- ✅ Status = '1' (New)
- ✅ TESTER_ID = DEV-061
- ✅ CREATED_AT = Current Date
- ✅ Email notification sent (check SCOT table)

**Edge Cases:**

- **Empty Title:** Expected error "Title is required"
- **Long Title (> 100 chars):** System truncates to 100 chars (ZDOM_TITLE = CHAR 100)
- **Special Characters:** "<>&\"'" should be escaped in ABAP
- **Concurrent Create:** 2 users create simultaneously → Different BUG_IDs (check sequence/NRIV)

**Verification Image:** `verification_phase6_tc1_create_bug.png`

---

#### TC-P6-02: Xem & Cập nhật Bug (Update Bug)

**Purpose:** Verify người dùng có thể xem chi tiết bug và update status

**Preconditions:**

- Bug #0001 exists (from TC-P6-01)
- DEV-061 login as Tester

**Steps:**

1. T-code: **ZBUG_UPDATE**
2. Enter BUG_ID: **0001**
3. Click **Display** button
4. Observe: Bug details displayed
5. Change Status: '1' (New) → '2' (Assigned)
6. Enter Reason: "Assigned to John for investigation"
7. Click **Update**

**Expected Results:**

- ✅ Bug details loaded with all fields
- ✅ Status field editable (dropdown)
- ✅ Update successful message shown
- ✅ ZBUG_TRACKER.STATUS = '2'
- ✅ ZBUG_HISTORY new entry created: ACTION_TYPE='ST', CHANGED_BY='DEV-061'

**Edge Cases:**

- **Non-existent BUG_ID:** Error "Bug not found"
- **Closed Bug (Status='5'):** Try to change → Error "Cannot update closed bug"
- **No Change:** Status stays '2' → Warning "No changes detected"
- **Authorization:** Dev tries to update bug NOT assigned to them → Error "Permission denied"

**Verification Image:** `verification_phase6_tc2_update_bug.png`

---

#### TC-P6-03: Danh sách Bug với Màu Sắc (ALV Report)

**Purpose:** Verify ALV Grid displays bugs with correct colors by status

**Preconditions:**

- Multiple bugs with different statuses exist:
  - Bug #001: Status='1' (New)
  - Bug #002: Status='2' (Assigned)
  - Bug #003: Status='3' (InProgress)
  - Bug #004: Status='4' (Fixed)
  - Bug #005: Status='5' (Closed)

**Steps:**

1. T-code: **ZBUG_REPORT**
2. Leave all filters blank
3. Click **Execute** (F8)
4. Observe ALV Grid colors

**Expected Results:**

- ✅ ALV Grid displays all 5 bugs
- ✅ Status '1' rows = **Blue (C100)**
- ✅ Status '2' rows = **Orange (C300)**
- ✅ Status '3' rows = **Purple (C500)**
- ✅ Status '4' rows = **Green (C510)**
- ✅ Status '5' rows = **Grey (C200)**
- ✅ Column headers visible: BUG_ID, TITLE, STATUS, DEV_ID, PRIORITY, MODULE

**Edge Cases:**

- **Empty result:** No bugs in database → ALV shows "No data" message
- **Filter by Status:** Select only Status='2' → Show only orange rows
- **Filter by Module:** Select Module='FI' → Show only FI bugs with correct colors
- **Waiting Status (W):** If any bug has Status='W' → Yellow (C310)

**Verification Image:** `verification_phase6_tc3_alv_colors.png`

---

#### TC-P6-04: Interactive ALV - Update Navigation

**Purpose:** Verify ALV toolbar buttons work correctly

**Preconditions:**

- ALV report open with bugs displayed
- At least 1 bug in ALV grid

**Steps:**

1. From TC-P6-03, ALV Grid visible
2. Click on one row (Bug #002)
3. Click **Update Bug** button in toolbar
4. Observe: Transaction changes to ZBUG_UPDATE

**Expected Results:**

- ✅ Row selected (highlighted)
- ✅ Toolbar buttons active (not greyed out)
- ✅ Click "Update Bug" → T-code switches to ZBUG_UPDATE
- ✅ Bug ID (002) pre-filled in ZBUG_UPDATE screen
- ✅ No dump, session continues

**Edge Cases:**

- **No row selected:** Click "Update Bug" → Error "Please select a row"
- **Multiple rows selected:** Click "Update Bug" → Error "Select only one row" or updates first row
- **Invalid bug:** Click "Update Bug" → ZBUG_UPDATE tries to load, shows error "Bug not found"

**Verification Image:** `verification_phase6_tc4_alv_update_nav.png`

---

#### TC-P6-05: In Biên Bản (Print SmartForm)

**Purpose:** Verify SmartForm printing works and displays correct information

**Preconditions:**

- Bug #001 exists with complete information
- SmartForm ZBUG_FORM activated

**Steps:**

1. T-code: **ZBUG_PRINT**
2. Enter BUG_ID: **0001**
3. Click **Print Preview** button
4. Observe form output

**Expected Results:**

- ✅ SmartForm opens in preview (no "Architecture not supported" error)
- ✅ Header shows: Bug ID, Title, Priority
- ✅ Main table shows: Description, Status, Module, DEV_ID
- ✅ Footer shows: Created date, Last modified date
- ✅ No text overlap or formatting issues
- ✅ Multiple pages if content is long

**Edge Cases:**

- **Very long description (4000 chars):** Form handles wrap/truncate properly
- **Special characters in title:** <>&\"' displayed correctly
- **Missing developer:** If DEV_ID is NULL → Shows "Not yet assigned"
- **PDF export:** Click Export to PDF → File generated successfully

**Verification Image:** `verification_phase6_tc5_smartform_print.png`

---

#### TC-P6-06: Manager Dashboard

**Purpose:** Verify Manager dashboard shows statistics and status mapping

**Preconditions:**

- Multiple bugs with different statuses
- DEV-118 login as Manager

**Steps:**

1. T-code: **ZBUG_MANAGER**
2. Click **Execute** (F8)
3. Observe statistics table

**Expected Results:**

- ✅ Dashboard displays summary statistics
- ✅ Status codes mapped to text:
  - '1' → "New" (or "Mới" in Vietnamese)
  - '2' → "Assigned" (or "Đã phân công")
  - '3' → "InProgress" (or "Đang xử lý")
  - '4' → "Fixed" (or "Đã sửa")
  - '5' → "Closed" (or "Đóng")
  - 'W' → "Waiting" (or "Chờ xử lý")
- ✅ Count of bugs per status displayed correctly
- ✅ Total bugs = sum of all statuses

**Edge Cases:**

- **No bugs in "New" status:** Status '1' shows count=0
- **All bugs in "Closed" status:** Only '5' row shown with high count
- **Non-existent status:** Should not appear in report

**Verification Image:** `verification_phase6_tc6_manager_dashboard.png`

---

#### TC-P6-07: Auto Assign Developer

**Purpose:** Verify auto-assign function assigns bug to developer with minimum workload

**Preconditions:**

- 3 developers exist: D001 (0 bugs), D002 (1 bug), D003 (2 bugs)
- All developers have AVAILABLE_STATUS='A'
- Bug #010 created with Status='1' (New), DEV_ID=NULL

**Steps:**

1. T-code: **ZBUG_REPORT**
2. Select Bug #010
3. Click **Auto Assign** button
4. Observe result

**Expected Results:**

- ✅ Bug #010.DEV_ID assigned to **D001** (minimum workload)
- ✅ Bug #010.STATUS changed to '2' (Assigned)
- ✅ D001.AVAILABLE_STATUS changed to 'W' (Working)
- ✅ ZBUG_HISTORY new entry: ACTION_TYPE='AS' (Auto-assign)
- ✅ Success message shown

**Edge Cases:**

- **All devs busy:** Set all AVAILABLE_STATUS='W' → Bug stays Status='W', DEV_ID=NULL
- **No dev for module:** Bug module='XX', no dev available → Status='W'
- **Inactive dev:** D001.is_active='' (not 'X') → Skip, assign to D002
- **Equal workload:** D001 & D002 both have 1 bug → Assign to first available (D001)

**Verification Image:** `verification_phase6_tc7_auto_assign.png`

---

#### TC-P6-08: Re-assign Developer

**Purpose:** Verify manager can reassign bug from one developer to another

**Preconditions:**

- Bug #010 assigned to D001
- D002 available with lower workload
- Manager (DEV-118) logged in

**Steps:**

1. T-code: **ZBUG_UPDATE**
2. Enter BUG_ID: **010**
3. Change field: **Dev Assignment** from D001 → D002
4. Enter Reason: "Reassigning to John for expertise"
5. Click **Re-assign** button

**Expected Results:**

- ✅ Bug #010.DEV_ID changed to D002
- ✅ D001.AVAILABLE_STATUS = 'A' (Available again)
- ✅ D002.AVAILABLE_STATUS = 'W' (Working)
- ✅ ZBUG_HISTORY new entry: ACTION='RS' (Reassign), OLD_VALUE='D001', NEW_VALUE='D002'
- ✅ Email notification sent to D002

**Edge Cases:**

- **Reassign to same dev:** D001 → D001 → Warning "No change"
- **Reassign closed bug:** Status='5' → Error "Cannot reassign closed bug"
- **Dev not found:** Enter DEV_ID='D999' (not exists) → Error "Developer not found"
- **Concurrent reassign:** 2 managers reassign simultaneously → Last one wins (update lock)

**Verification Image:** `verification_phase6_tc8_reassign.png`

---

#### TC-P6-09: Upload File Attachment

**Purpose:** Verify file attachment upload and storage

**Preconditions:**

- Bug #010 exists, Status ≠ '5' (not closed)
- Test file ready: "bug_report.pdf" (< 10MB)

**Steps:**

1. T-code: **ZBUG_UPDATE**
2. Enter BUG_ID: **010**
3. In **Attachments** section, click **Upload Report**
4. Browse & select file: `bug_report.pdf`
5. Click **Submit**

**Expected Results:**

- ✅ File uploaded successfully
- ✅ ZBUG_TRACKER.ATT_REPORT = "/path/to/bug_report.pdf"
- ✅ Success message shown
- ✅ File can be re-downloaded from same screen

**Edge Cases:**

- **File too large (> 10MB):** Error "File size exceeds limit"
- **Invalid file type:** Upload `.exe` → Error "Only PDF/DOC allowed"
- **Closed bug:** Status='5' → Error "Cannot upload to closed bug"
- **Multiple uploads:** Upload 3 different files (REPORT, FIX, VERIFY) → All paths stored separately
- **Re-upload same type:** Upload new REPORT when one exists → Old one overwritten

**Verification Image:** `verification_phase6_tc9_upload_attachment.png`

---

#### TC-P6-10: Permission Check - Role-based Access

**Purpose:** Verify role-based permissions are enforced correctly

**Preconditions:**

- Users exist: Tester(T), Developer(D), Manager(M)
- Bugs in various statuses

**Steps & Expected Results:**

**Test 10a: Tester trying to UPDATE bug status**

1. Login as Tester (DEV-061)
2. T-code: ZBUG_UPDATE
3. Try to change bug status
4. **Expected:** ❌ Error "Testers cannot update bug status" OR role allows limited statuses

**Test 10b: Developer creating new bug**

1. Login as Developer (DEV-089)
2. T-code: ZBUG_CREATE
3. Try to create bug
4. **Expected:** ❌ Error "Only Testers/Managers can create bugs"

**Test 10c: Developer updating own bug**

1. Login as Developer (DEV-089)
2. Bug assigned to DEV-089
3. T-code: ZBUG_UPDATE
4. Change status '2' → '3'
5. **Expected:** ✅ Allowed

**Test 10d: Developer updating others' bug**

1. Login as Developer (DEV-089)
2. Bug assigned to DEV-099 (different dev)
3. Try to update
4. **Expected:** ❌ Error "You can only update bugs assigned to you"

**Test 10e: Manager doing any action**

1. Login as Manager (DEV-118)
2. Try: Create, Update (any bug), Delete, Upload
3. **Expected:** ✅ All allowed

**Edge Cases:**

- **Permission cache:** Change role in ZBUG_USERS, old role still active → Clear SAP cache (Ctrl+Shift+F3)
- **Missing role:** User has NULL role → Deny all access

**Verification Image:** `verification_phase6_tc10_permissions.png`

---

#### TC-P6-11: History Logging (Audit Trail)

**Purpose:** Verify all changes are logged in ZBUG_HISTORY

**Preconditions:**

- Bug #011 exists
- ZBUG_HISTORY table empty for this bug

**Steps:**

1. Create Bug #011 (TC-P6-01)
   - ZBUG_HISTORY entry: ACTION_TYPE='CR'
2. Update Status '1'→'2'
   - ZBUG_HISTORY entry: ACTION_TYPE='ST'
3. Re-assign from D001 to D002
   - ZBUG_HISTORY entry: ACTION_TYPE='RS'
4. T-code: SE16N → ZBUG_HISTORY → Filter BUG_ID=011 → Display all records

> **Lưu ý:** Upload attachment (Z_BUG_UPLOAD_ATTACHMENT) không gọi Z_BUG_LOG_HISTORY nên không tạo history entry. ZDOM_ACTION_TYPE chỉ có 4 giá trị: CR/AS/RS/ST.

**Expected Results:**

- ✅ Total 3 history entries created
- ✅ Each entry has:
  - LOG_ID (unique, NUMC 10)
  - BUG_ID = 011
  - ACTION_TYPE ('CR', 'ST', 'RS') — theo ZDOM_ACTION_TYPE
  - CHANGED_BY (correct user, from SY-UNAME)
  - CHANGED_AT (correct date, from SY-DATUM)
  - CHANGED_TIME (correct time, from SY-UZEIT)
  - REASON (if provided)
  - OLD_VALUE / NEW_VALUE (for relevant changes)

**Edge Cases:**

- **Concurrent changes:** 2 users update same bug → Both changes logged separately
- **Failed update:** If validation fails, is history created? **Expected:** NO
- **Manual DB update:** Update ZBUG_TRACKER directly (via SE16) → History NOT created (no FM call)

**Verification Image:** `verification_phase6_tc11_history_log.png`

---

#### TC-P6-12: Performance & System Stability

**Purpose:** Verify system handles load and responds within acceptable time

**Preconditions:**

- 1000 bugs in ZBUG_TRACKER
- 50 users in ZBUG_USERS
- 2000+ history entries in ZBUG_HISTORY

**Steps:**

1. **Test 12a: ALV Report with 1000 bugs**
   - T-code: ZBUG_REPORT, no filter
   - Measure response time
   - **Expected:** < 3 seconds

2. **Test 12b: Filter ALV by Module**
   - T-code: ZBUG_REPORT, filter Module='FI'
   - Measure response time
   - **Expected:** < 1.5 seconds (indexed search)

3. **Test 12c: Load Bug Detail**
   - T-code: ZBUG_UPDATE, load bug with 100+ history entries
   - Measure response time
   - **Expected:** < 2 seconds

4. **Test 12d: Auto-assign 100 bugs**
   - Create loop calling Z_BUG_AUTO_ASSIGN 100 times
   - Measure total time
   - **Expected:** < 5 seconds (< 50ms per call)

5. **Test 12e: Concurrent 10 users**
   - 10 terminals open simultaneously
   - All execute ZBUG_REPORT at same time
   - Check for deadlock/timeout
   - **Expected:** All complete successfully

**Expected Results:**

- ✅ All response times within target
- ✅ No timeout errors
- ✅ No deadlock
- ✅ CPU usage reasonable (< 50%)
- ✅ Memory stable (no leak)

**Edge Cases:**

- **Network latency:** Simulate slow network (latency tool) → Measure impact
- **Missing index:** Disable INDEX on DEV_ID → Performance degradation observed
- **Max connection:** Simulate 100+ concurrent users → System should queue gracefully

**Verification Image:** `verification_phase6_tc12_performance.png`

---

### Bước 6.5: Code Documentation & Standards

**Mục đích:** Ensure tất cả code được documented đúng cách cho maintenance.

#### 6.5.1 Function Module Header Documentation

**Format:** Mỗi FM phải có header như sau:

```abap
*&---------------------------------------------------------------------*
*& Function Module: Z_BUG_AUTO_ASSIGN
*& Description: Automatically assign bug to developer with min workload
*& Created by: DEV-089
*& Created date: 03/03/2026
*& Last modified: 07/03/2026 by DEV-089
*&---------------------------------------------------------------------*
*& Imports:
*&   IV_BUG_ID (ZDE_BUG_ID) - Bug ID to assign
*&   IV_MODULE (ZDE_SAP_MODULE) - SAP module code
*&
*& Exports:
*&   EV_DEV_ID (ZDE_USERNAME) - Assigned developer username
*&   EV_STATUS (ZDE_BUG_STATUS) - New bug status
*&   EV_MESSAGE (STRING) - Success/error message
*&
*& Exceptions:
*&   BUG_NOT_FOUND - Bug with given ID doesn't exist
*&   NO_DEV_AVAILABLE - No developer available for module
*&---------------------------------------------------------------------*
```

#### 6.5.2 Program/Screen Header Documentation

**Format:**

```abap
*&---------------------------------------------------------------------*
*& Report: Z_BUG_CREATE_SCREEN
*& Description: Selection screen & logic for creating new bugs
*& Created: DEV-061 (03/03/2026)
*& Type: Interactive Report
*&---------------------------------------------------------------------*
*& Selection Screen Fields:
*&   P_TITLE (CHAR100) - Bug title (mandatory)
*&   P_DESC (CHAR4000) - Bug description (optional)
*&   P_PRIORITY (ZDE_PRIORITY) - Priority level (mandatory)
*&   P_MODULE (ZDE_SAP_MODULE) - SAP module (mandatory)
*&---------------------------------------------------------------------*
*& Key Logic:
*&   1. Validate input fields
*&   2. Call FM Z_BUG_CREATE to insert into DB
*&   3. Send email to assigned developer
*&   4. Display success/error message
*&---------------------------------------------------------------------*
```

#### 6.5.3 Inline Code Comments

**Rule:** Every non-obvious line should have comment

❌ Bad:

```abap
SELECT MAX( log_id ) INTO lv_max_id FROM zbug_history WHERE bug_id = @iv_bug_id.
lv_logid = lv_max_id + 1.
```

✅ Good:

```abap
" Get the max LOG_ID for this bug to generate next unique ID
SELECT MAX( log_id ) INTO lv_max_id FROM zbug_history WHERE bug_id = @iv_bug_id.
" Increment for new log entry
lv_logid = lv_max_id + 1.
```

#### 6.5.4 Verification Checklist

Before marking code as "Complete", verify:

- [ ] Function header documented (module, purpose, parameters)
- [ ] All imports/exports described
- [ ] Exception handling documented
- [ ] Code comments for complex logic
- [ ] No dead code (unused variables)
- [ ] All error messages clear & actionable
- [ ] No hardcoded values (use constants/parameters)
- [ ] Data validation at entry points
- [ ] Error handling with proper error messages
- [ ] Database COMMIT/ROLLBACK explicit
- [ ] No SQL injection vulnerabilities
- [ ] Performance: O(n) or better
- [ ] Memory efficient (no large temporary arrays)

---

## PHASE 7: DEPLOYMENT & TRAINING (Tuần 7-8)

> [!IMPORTANT]
> **Tài khoản sử dụng:**
>
> - Transport & Deployment: **DEV-118** (Pass: `Qwer123@`)
> - User Training: **DEV-118** or **System Admin**

### Bước 7.1: Transport Request Management (SE09)

**Mục đích:** Tạo Transport Request để deploy toàn bộ object từ Dev sang UAT/Prod.

#### 1. Tạo Transport Request

1. **T-code:** `SE09` (Transport Organizer)
2. Tab: **Modifiable Objects**
3. Click **Create Request** button
4. Nhập:
   - **Request Name:** `ZBUG_FINAL_DEPLOY_001`
   - **Description:** "Phase 5 & 6 Final Deployment - Bug Tracking System"
   - **Target System:** Để trống (sẽ chọn sau)

#### 2. Thêm Objects vào Transport

1. Click button **Add Objects**
2. Chọn **Package:** `ZBUGTRACK`
3. SAP tự động include toàn bộ objects:
   - Bảng dữ liệu (ZBUG_TRACKER, ZBUG_USERS, ZBUG_HISTORY)
   - Function Modules (Z_BUG_*)
   - Programs (Z_BUG_*_SCREEN, Z_BUG_REPORT_ALV, etc.)
   - T-codes (ZBUG_CREATE, ZBUG_UPDATE, ZBUG_REPORT, etc.)

#### 3. Release Transport Request

1. Click **Release Transport**
2. System automatically:
   - Validates all objects
   - Creates transport file (.cofile & .data files)
   - Generates control record

**Expected Result:** ✅ Transport status = "Released"

---

### Bước 7.2: User Training Preparation

**Mục đích:** Chuẩn bị tài liệu training cho end-users

#### Training Document Checklist

- [ ] **T-code Quick Reference** - One-page cheat sheet
  - ZBUG_CREATE: Create new bug
  - ZBUG_UPDATE: Update bug status
  - ZBUG_REPORT: View bug list with colors
  - ZBUG_MANAGER: Manager dashboard

- [ ] **Role-based User Guide** - Separate guides per role:
  - Tester Guide (Create, Upload Report)
  - Developer Guide (Update Status, Upload Fix)
  - Manager Guide (Reassign, Dashboard, Analytics)

- [ ] **Screen Navigation Guide** - Step-by-step with screenshots

- [ ] **FAQ Document** - Common questions & solutions

- [ ] **Troubleshooting Guide** - Error messages & resolutions

---

### Bước 7.3: Deployment Checklist

**Pre-Deployment:**

- [ ] All Phase 6 UAT test cases passed (12/12)
- [ ] Code Inspector results reviewed (0 critical errors)
- [ ] Performance testing completed (all < 3 sec)
- [ ] Backup of production databases created
- [ ] Deployment team briefed
- [ ] Rollback plan documented

**Deployment Steps:**

1. **Schedule downtime window** (e.g., 2-4 AM on Saturday)
2. **Import transport request** in target system
3. **Activate all objects** if needed
4. **Create T-codes** if not auto-created
5. **Verify objects active** (SE80, SE16, SE93)
6. **Run smoke test** (create bug, update, view, print)
7. **Notify users** - System ready

**Post-Deployment:**

- [ ] Monitor system logs for errors
- [ ] Verify database integrity
- [ ] Check email notifications working
- [ ] Monitor performance metrics
- [ ] Collect initial user feedback
- [ ] Schedule follow-up training

---

### Bước 7.4: Rollback Plan

**If deployment fails:**

1. **Immediate:** Disable all Z_BUG_* T-codes (via SE93)
2. **Restore database** from pre-deployment backup
3. **Deactivate objects** (SE80)
4. **Notify users** of system revert
5. **Post-mortem:** Analyze root cause

---

## PHASE 8: FINAL PRESENTATION (29/03/2026)

> [!IMPORTANT]
> Finalize all documentation, conduct final testing, prepare project summary.

### Bước 8.1: Final Testing & Verification

**Conduct final regression testing covering:**

- [ ] All 12 UAT test cases from Phase 6
- [ ] All edge cases from Phase 6.1-6.3
- [ ] Performance benchmarks met
- [ ] No new bugs in ZBUG_TRACKER (system bugs)
- [ ] All code documented properly
- [ ] Transport request validated

### Bước 8.2: Project Completion Documentation

**Create final report:**

1. **System Architecture Summary**
   - Database schema overview
   - Function Module interaction diagram
   - Screen flow diagram

2. **Deliverables Summary**
   - All 8 phases completed
   - 6 Function Modules deployed
   - 6 T-codes available
   - 2000+ lines of ABAP code

3. **Key Metrics**
   - Response time: < 3 seconds (target met)
   - Bugs tracked: 1000+ capacity
   - Users supported: 50+
   - Code quality: 0 critical errors

4. **Known Limitations**
   - Current: Single system (S40)
   - Future: Multi-system support
   - Current: Email via SCOT (manual config)
   - Future: Automated SMTP integration

### Bước 8.3: Handover & Training Completion

**Conduct final user training:**

1. **Session 1:** Tester group (Creating bugs)
2. **Session 2:** Developer group (Updating status, uploading fixes)
3. **Session 3:** Manager group (Dashboard, reassigning, analytics)

**Materials provided:**

- T-code quick reference (printed)
- User guide (PDF)
- FAQ & troubleshooting guide
- Contact list for support

### Bước 8.4: Project Sign-off

**Obtain approval from:**

- [ ] Project Manager - Timeline & scope met
- [ ] QA Lead - All tests passed
- [ ] System Admin - Objects deployed correctly
- [ ] Business Owner - Requirements satisfied

---

## 🎯 HOÀN THÀNH

Chúc mừng! Bạn đã hoàn thành hệ thống SAP Bug Tracking Management.

**Tóm tắt những gì đã xây dựng:**

| Phase | Nội dung | Deliverables | Status |
| :--- | :--- | :--- | :--- |
| 0 | Môi trường | SAP GUI, Package ZBUGTRACK | ✅ |
| 1 | Database Layer | ZBUG_TRACKER, ZBUG_USERS, ZBUG_HISTORY, ZNRO_BUG | ✅ |
| 2 | Business Logic | Z_BUG_CREATE/GET/UPDATE_STATUS/DELETE/SEND_EMAIL, SCOT | ✅ |
| 3 | Presentation | Z_BUG_CREATE_SCREEN, Z_BUG_UPDATE_SCREEN, ZBUG_CREATE, ZBUG_UPDATE | ✅ |
| 4 | Reporting | Z_BUG_REPORT_ALV (Interactive), ZBUG_FORM, Z_BUG_MANAGER_DASHBOARD, Z_BUG_USER_MANAGEMENT | ✅ |
| 5 | Advanced FMs | Z_BUG_LOG_HISTORY, Z_BUG_AUTO_ASSIGN, Z_BUG_CHECK_PERMISSION, Z_BUG_UPLOAD_ATTACHMENT, Z_BUG_REASSIGN, ALV Colors | ✅ |
| 6 | Testing & Optimization | SCI, Unit Testing (6 FMs), Performance Testing, Integration Testing, UAT 12 test cases, Code Documentation | ⏳ |
| 7 | Deployment & Training | Transport Request (SE09), User Training Docs, Deployment Checklist, Rollback Plan | ⏳ |
| 8 | Final Presentation | Final Testing, Project Summary, Handover Documentation, Performance Metrics | ⏳ |

**T-codes tổng hợp:**

| T-code | Program | Người dùng |
| :--- | :--- | :--- |
| `ZBUG_CREATE` | Z_BUG_CREATE_SCREEN | Tester |
| `ZBUG_UPDATE` | Z_BUG_UPDATE_SCREEN | Tester / Developer |
| `ZBUG_REPORT` | Z_BUG_REPORT_ALV | Tester / Developer / Manager |
| `ZBUG_PRINT` | Z_BUG_PRINT | Tester / Manager |
| `ZBUG_MANAGER` | Z_BUG_MANAGER_DASHBOARD | Manager |
| `ZBUG_USERS` | Z_BUG_USER_MANAGEMENT | Manager |

---

**Prepared by:** Development Team
**Last Updated:** 07/03/2026 - Phase 6/7/8 Detailed Guide & 12 UAT Test Cases Added
