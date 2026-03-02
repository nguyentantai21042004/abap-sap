# HƯỚNG DẪN TRIỂN KHAI CHO DEVELOPER

**Dự án:** SAP Bug Tracking Management System  
**Đối tượng:** Developer chưa có kinh nghiệm SAP hoặc chưa setup môi trường  
**Ngày:** 31/01/2026  
**Phiên bản:** 1.0

---

## 📋 MỤC LỤC

- [Phase 0: Chuẩn Bị Môi Trường](#phase-0-chuẩn-bị-môi-trường)
- [Ma Trận Sử Dụng Tài Khoản (Account Matrix)](#ma-trận-sử-dụng-tài-khoản-account-matrix)
- [Phase 1: Database Layer](#phase-1-database-layer-tuần-1)
- [Phase 2: Business Logic Layer](#phase-2-business-logic-layer-tuần-2-3)
- [Phase 3: Presentation Layer](#phase-3-presentation-layer-tuần-2-3)
- [Phase 4: Reporting Module](#phase-4-reporting-module-tuần-4-5)
- [Phase 5: Testing & Deployment](#phase-5-testing--deployment-tuần-6-8)

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
| **Phase 6** | **Management** | **DEV-118** | Thống kê & Kiểm tra cuối cùng |

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
| `ZDOM_STATUS` | CHAR | 1 | Status | 1: New, W: Waiting, 2: Assigned, 3: InProgress, 4: Fixed, 5: Closed |
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

1. Click **Save** → **Activate**

---

### Bước 2.3: Tạo Function Module - Update Status

#### **Function: Z_BUG_UPDATE_STATUS**

**Import Parameters**

| Parameter       | Type | Associated Type | Description     |
| --------------- | ---- | --------------- | --------------- |
| IV_BUG_ID       | TYPE | ZDE_BUG_ID      | Bug ID          |
| IV_NEW_STATUS   | TYPE | ZDE_BUG_STATUS  | New status code |
| IV_CHANGED_BY   | TYPE | ZDE_USERNAME    | User changing   |

**Export Parameters**

| Parameter  | Type | Associated Type | Description |
| ---------- | ---- | --------------- | ----------- |
| EV_SUCCESS | TYPE | CHAR1           | Y/N flag    |
| EV_MESSAGE | TYPE | STRING          | Message     |

```abap
FUNCTION z_bug_update_status.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE  ZDE_BUG_ID
*"     VALUE(IV_NEW_STATUS) TYPE  ZDE_BUG_STATUS
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

  " Update status
  UPDATE zbug_tracker
    SET status    = iv_new_status
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

1. Click **Save** → **Activate** (Ctrl+F3)

---

### Bước 2.4: Tạo Function Module - Get Bug

#### **Function: Z_BUG_GET**

**Import Parameters**

| Parameter | Type | Associated Type | Description |
| --------- | ---- | --------------- | ----------- |
| IV_BUG_ID | TYPE | ZDE_BUG_ID      | Bug ID      |

**Export Parameters**

| Parameter  | Type | Associated Type    | Description         |
| ---------- | ---- | ------------------ | ------------------- |
| ES_BUG     | TYPE | ZBUG_TRACKER       | Bug record (struct) |
| EV_SUCCESS | TYPE | CHAR1              | Y/N flag            |
| EV_MESSAGE | TYPE | STRING             | Message             |

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

  SELECT SINGLE * FROM zbug_tracker INTO es_bug
    WHERE bug_id = iv_bug_id.

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

### Bước 2.5: Tạo Function Module - Delete Bug

#### **Function: Z_BUG_DELETE**

**Import Parameters**

| Parameter | Type | Associated Type | Description |
| --------- | ---- | --------------- | ----------- |
| IV_BUG_ID | TYPE | ZDE_BUG_ID      | Bug ID      |

**Export Parameters**

| Parameter  | Type | Associated Type | Description |
| ---------- | ---- | --------------- | ----------- |
| EV_SUCCESS | TYPE | CHAR1           | Y/N flag    |
| EV_MESSAGE | TYPE | STRING          | Message     |

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

  DELETE FROM zbug_tracker WHERE bug_id = iv_bug_id.

  IF sy-subrc = 0.
    COMMIT WORK.
    ev_success = 'Y'.
    ev_message = |Bug { iv_bug_id } deleted|.
  ELSE.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Bug not found or delete failed'.
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
  APPEND |Module: { ls_bug-sap_module }| TO lt_text.
  APPEND |Priority: { ls_bug-priority }| TO lt_text.
  APPEND |Reporter: { ls_bug-tester_id }| TO lt_text.
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

> [!TIP]
> **Tài khoản sử dụng:** **DEV-061** (Pass: `@57Dt766`)  
> SE38/SE93 cho giao diện người dùng và ALV Grid.

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

1. Click **Save** → **Activate**

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

1. Click **Save**

**✅ Checkpoint:** Test T-code `ZBUG_CREATE` → Màn hình nhập liệu hiển thị

---

## PHASE 4: REPORTING MODULE (Tuần 4-5)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-061** (Pass: `@57Dt766`)  
> Dùng cho SmartForms và các Report in ấn.

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

> [!TIP]
> **Tài khoản sử dụng:**
>
> - Đính kèm file: **DEV-237** (Pass: `toiyeufpt`)
> - Cấu hình Email: **DEV-242** (Pass: `12345678`)
> - Verify & Management: **DEV-118** (Pass: `Qwer123@`)

> **Mục tiêu:** Code Inspector

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

## 🎯 HOÀN THÀNH

Chúc mừng! Bạn đã hoàn thành hệ thống SAP Bug Tracking Management.

**Next Steps:**

- Deploy to Production
- Train end users
- Monitor system performance
- Collect feedback for improvements

---

**Prepared by:** [Your Name]  
**Last Updated:** 02/02/2026

---

## PHASE 1.5: BỔ SUNG DATABASE (YÊU CẦU MỚI)

> **Cập nhật:** 02/02/2026  
> **Mục tiêu:** Thêm bảng `ZBUG_USERS`, `ZBUG_HISTORY` và fields mới cho `ZBUG_TRACKER`

### Bước 1.5.1: Tạo Thêm Domains

| Domain              | Data Type | Length | Fixed Values                                 |
| ------------------- | --------- | ------ | -------------------------------------------- |
| `ZDOM_ROLE`         | CHAR      | 1      | T=Tester, D=Developer, M=Manager             |
| `ZDOM_AVAIL_STATUS` | CHAR      | 1      | A=Available, B=Busy, L=Leave, W=Working      |
| `ZDOM_BUG_TYPE`     | CHAR      | 1      | C=Code, F=Configuration                      |
| `ZDOM_ACTION_TYPE`  | CHAR      | 2      | CR=Create, AS=Assign, RS=Reassign, ST=Status |

**Cập nhật `ZDOM_STATUS`:**

```text
1 - New
W - Waiting (Manager assign)
2 - Assigned
3 - In Progress
4 - Fixed
5 - Closed
```

---

### Bước 1.5.2: Tạo Thêm Data Elements

| Data Element       | Domain            | Short Label | Long Label       |
| ------------------ | ----------------- | ----------- | ---------------- |
| `ZDE_ROLE`         | ZDOM_ROLE         | Role        | User Role        |
| `ZDE_AVAIL_STATUS` | ZDOM_AVAIL_STATUS | Avail       | Available Status |
| `ZDE_BUG_TYPE`     | ZDOM_BUG_TYPE     | Type        | Bug Type         |
| `ZDE_ACTION_TYPE`  | ZDOM_ACTION_TYPE  | Action      | Action Type      |
| `ZDE_FULL_NAME`    | CHAR50            | Name        | Full Name        |
| `ZDE_EMAIL`        | CHAR100           | Email       | Email Address    |
| `ZDE_ATT_PATH`     | CHAR100           | File        | Attachment Path  |
| `ZDE_REASONS`      | STRG              | Reason      | Bug Reason       |

---

### Bước 1.5.3: Tạo Bảng ZBUG_USERS

1. Vào T-code `SE11` → Database table → `ZBUG_USERS`
2. Tab Fields:

| Field            | Key | Data Element     | Description      |
| ---------------- | --- | ---------------- | ---------------- |
| MANDT            | ✓   | MANDT            | Client           |
| USER_ID          | ✓   | ZDE_USERNAME     | SAP Username     |
| ROLE             |     | ZDE_ROLE         | T/D/M            |
| FULL_NAME        |     | ZDE_FULL_NAME    | Họ tên           |
| MODULE           |     | ZDE_SAP_MODULE   | Module phụ trách |
| AVAILABLE_STATUS |     | ZDE_AVAIL_STATUS | Trạng thái       |
| IS_ACTIVE        |     | CHAR1            | X=Active         |
| EMAIL            |     | ZDE_EMAIL        | Email            |

1. Technical Settings: APPL0, Size 0

---

### Bước 1.5.4: Tạo Bảng ZBUG_HISTORY

1. Vào T-code `SE11` → Database table → `ZBUG_HISTORY`
2. Tab Fields:

| Field        | Key | Data Element     | Description    |
| ------------ | --- | ---------------- | -------------- |
| MANDT        | ✓   | MANDT            | Client         |
| LOG_ID       | ✓   | NUMC10           | Log ID         |
| BUG_ID       |     | ZDE_BUG_ID       | Bug reference  |
| CHANGED_BY   |     | ZDE_USERNAME     | Người thay đổi |
| CHANGED_AT   |     | ZDE_CREATED_DATE | Ngày           |
| CHANGED_TIME |     | ZDE_CREATED_TIME | Giờ            |
| ACTION_TYPE  |     | ZDE_ACTION_TYPE  | Loại action    |
| OLD_VALUE    |     | CHAR50           | Giá trị cũ     |
| NEW_VALUE    |     | CHAR50           | Giá trị mới    |
| REASON       |     | ZDE_REASONS      | Lý do          |

---

### Bước 1.5.5: Bổ Sung Fields cho ZBUG_TRACKER

Thêm các fields sau vào bảng `ZBUG_TRACKER`:

| Field            | Data Element     | Description      |
| ---------------- | ---------------- | ---------------- |
| BUG_TYPE         | ZDE_BUG_TYPE     | C=Code, F=Config |
| REASONS          | ZDE_REASONS      | Nguyên nhân      |
| TESTER_ID        | ZDE_USERNAME     | Tester báo lỗi   |
| VERIFY_TESTER_ID | ZDE_USERNAME     | Tester verify    |
| APPROVED_BY      | ZDE_USERNAME     | Manager duyệt    |
| APPROVED_AT      | ZDE_CREATED_DATE | Ngày duyệt       |
| ATT_REPORT       | ZDE_ATT_PATH     | File report      |
| ATT_FIX          | ZDE_ATT_PATH     | File fix         |
| ATT_VERIFY       | ZDE_ATT_PATH     | File verify      |

---

## PHASE 2.5: BỔ SUNG FUNCTION MODULES (YÊU CẦU MỚI)

### Bước 2.5.1: Function Z_BUG_AUTO_ASSIGN

```abap
FUNCTION z_bug_auto_assign.
*"----------------------------------------------------------------------
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE ZDE_BUG_ID
*"     VALUE(IV_MODULE) TYPE ZDE_SAP_MODULE
*"  EXPORTING
*"     VALUE(EV_DEV_ID) TYPE ZDE_USERNAME
*"     VALUE(EV_STATUS) TYPE ZDE_BUG_STATUS
*"     VALUE(EV_MESSAGE) TYPE STRING
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_dev_workload,
           user_id  TYPE zde_username,
           workload TYPE i,
         END OF ty_dev_workload.

  DATA: lt_devs     TYPE TABLE OF ty_dev_workload,
        ls_dev      TYPE ty_dev_workload,
        lv_min_load TYPE i VALUE 999.

  " Get available developers for this module
  SELECT user_id FROM zbug_users INTO TABLE @DATA(lt_available)
    WHERE module = @iv_module
      AND role = 'D'
      AND available_status = 'A'
      AND is_active = 'X'.

  IF sy-subrc <> 0.
    " No dev available → set Waiting
    ev_status = 'W'.
    ev_message = 'No developer available. Bug set to Waiting.'.

    UPDATE zbug_tracker SET status = 'W' WHERE bug_id = iv_bug_id.
    COMMIT WORK.
    RETURN.
  ENDIF.

  " Count workload for each dev
  LOOP AT lt_available INTO DATA(ls_avail).
    CLEAR ls_dev.
    ls_dev-user_id = ls_avail-user_id.

    SELECT COUNT(*) FROM zbug_tracker INTO @ls_dev-workload
      WHERE dev_id = @ls_avail-user_id
        AND status IN ('2', '3').

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
  UPDATE zbug_tracker SET dev_id = ev_dev_id, status = '2'
    WHERE bug_id = iv_bug_id.

  " Update dev status to Working
  UPDATE zbug_users SET available_status = 'W'
    WHERE user_id = ev_dev_id.

  COMMIT WORK.
  ev_status = '2'.
  ev_message = |Bug assigned to { ev_dev_id }|.

ENDFUNCTION.
```

---

### Bước 2.5.2: Function Z_BUG_CHECK_PERMISSION

```abap
FUNCTION z_bug_check_permission.
*"----------------------------------------------------------------------
*"  IMPORTING
*"     VALUE(IV_USER) TYPE ZDE_USERNAME
*"     VALUE(IV_BUG_ID) TYPE ZDE_BUG_ID
*"     VALUE(IV_ACTION) TYPE CHAR20  " CREATE, UPDATE_STATUS, UPLOAD_REPORT, etc.
*"  EXPORTING
*"     VALUE(EV_ALLOWED) TYPE CHAR1
*"     VALUE(EV_MESSAGE) TYPE STRING
*"----------------------------------------------------------------------

  DATA: ls_user TYPE zbug_users,
        ls_bug  TYPE zbug_tracker.

  " Get user role
  SELECT SINGLE * FROM zbug_users INTO ls_user
    WHERE user_id = iv_user.

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
  SELECT SINGLE * FROM zbug_tracker INTO ls_bug
    WHERE bug_id = iv_bug_id.

  CASE iv_action.
    WHEN 'CREATE'.
      " Only Tester can create
      ev_allowed = COND #( WHEN ls_user-role = 'T' THEN 'Y' ELSE 'N' ).

    WHEN 'UPDATE_STATUS'.
      " Dev can only update if assigned to them
      IF ls_user-role = 'D' AND ls_bug-dev_id = iv_user.
        ev_allowed = 'Y'.
      ELSEIF ls_user-role = 'T' AND ls_bug-status = '1'.
        ev_allowed = 'Y'.
      ELSE.
        ev_allowed = 'N'.
        ev_message = 'Not authorized to update this bug'.
      ENDIF.

    WHEN 'UPLOAD_REPORT'.
      ev_allowed = COND #( WHEN ls_user-role = 'T' AND ls_bug-tester_id = iv_user THEN 'Y' ELSE 'N' ).

    WHEN 'UPLOAD_FIX'.
      ev_allowed = COND #( WHEN ls_user-role = 'D' AND ls_bug-dev_id = iv_user THEN 'Y' ELSE 'N' ).

    WHEN 'UPLOAD_VERIFY'.
      ev_allowed = COND #( WHEN ls_user-role = 'T' THEN 'Y' ELSE 'N' ).

    WHEN OTHERS.
      ev_allowed = 'N'.
  ENDCASE.

ENDFUNCTION.
```

---

### Bước 2.5.3: Function Z_BUG_LOG_HISTORY

```abap
FUNCTION z_bug_log_history.
*"  IMPORTING
*"     VALUE(IV_BUG_ID) TYPE ZDE_BUG_ID
*"     VALUE(IV_ACTION_TYPE) TYPE ZDE_ACTION_TYPE
*"     VALUE(IV_OLD_VALUE) TYPE CHAR50 OPTIONAL
*"     VALUE(IV_NEW_VALUE) TYPE CHAR50
*"     VALUE(IV_REASON) TYPE STRING OPTIONAL
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

  INSERT zbug_history FROM ls_log.
  COMMIT WORK.

ENDFUNCTION.
```

---

## PHASE 3.5: ALV COLOR-CODED STATUS

### Cách thêm màu cho Status trong ALV

```abap
" Thêm field màu vào internal table
TYPES: BEGIN OF ty_bug_display,
         bug_id      TYPE zde_bug_id,
         status      TYPE zde_bug_status,
         " ... other fields
         row_color   TYPE char4,  " Color field
       END OF ty_bug_display.

" Set color based on status
LOOP AT lt_bugs ASSIGNING FIELD-SYMBOL(<fs_bug>).
  CASE <fs_bug>-status.
    WHEN '1'. <fs_bug>-row_color = 'C100'. " Blue - New
    WHEN 'W'. <fs_bug>-row_color = 'C310'. " Yellow - Waiting
    WHEN '2'. <fs_bug>-row_color = 'C300'. " Orange - Assigned
    WHEN '3'. <fs_bug>-row_color = 'C500'. " Purple - In Progress
    WHEN '4'. <fs_bug>-row_color = 'C510'. " Green - Fixed
    WHEN '5'. <fs_bug>-row_color = 'C200'. " Grey - Closed
  ENDCASE.
ENDLOOP.

" Set layout for coloring
ls_layout-info_fieldname = 'ROW_COLOR'.
```

---

## 🎯 HOÀN THÀNH

Hệ thống SAP Bug Tracking Management đã được bổ sung đầy đủ các chức năng mới.

**Các thay đổi chính:**

- ✅ 2 bảng mới: `ZBUG_USERS`, `ZBUG_HISTORY`
- ✅ 9 fields mới trong `ZBUG_TRACKER`
- ✅ Auto-assign logic với Waiting status
- ✅ Role-based permissions
- ✅ ALV color-coded status
