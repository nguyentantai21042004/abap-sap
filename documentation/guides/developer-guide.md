# HƯỚNG DẪN TRIỂN KHAI CHO DEVELOPER

**Dự án:** SAP Bug Tracking Management System  
**Đối tượng:** Developer chưa có kinh nghiệm SAP hoặc chưa setup môi trường  
**Ngày cập nhật:** 03/03/2026  
**Phiên bản:** 2.0

---

## 📋 MỤC LỤC

- [Phase 0: Chuẩn Bị Môi Trường](#phase-0-chuẩn-bị-môi-trường)
- [Ma Trận Sử Dụng Tài Khoản (Account Matrix)](#ma-trận-sử-dụng-tài-khoản-account-matrix)
- [Phase 1: Database Layer](#phase-1-database-layer-tuần-1)
- [Phase 2: Business Logic Layer](#phase-2-business-logic-layer-tuần-2-3) ✅ Hoàn thành
- [Phase 3: Presentation Layer](#phase-3-presentation-layer-tuần-2-3) ⏳ Đang thực hiện
- [Phase 4: ALV Report](#phase-4-alv-report-tuần-4-5)
- [Phase 5: Advanced Function Modules](#phase-5-advanced-function-modules-nâng-cao)
- [Phase 6: Testing & Deployment](#phase-6-testing--deployment-tuần-6-8)

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

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_UPDATE_SCREEN
*&---------------------------------------------------------------------*
REPORT z_bug_update_screen.

" Selection Screen - Nhập Bug ID
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_bugid  TYPE zde_bug_id OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  PARAMETERS: p_status TYPE zde_bug_status,
              p_devid  TYPE zde_username,
              p_reason TYPE char255 LOWER CASE. " Dùng char255 vì PARAMETERS không hỗ trợ STRING
SELECTION-SCREEN END OF BLOCK b2.

DATA: ls_bug      TYPE zbug_tracker,
      lv_success  TYPE char1,
      lv_message  TYPE string.

INITIALIZATION.
  " Nếu truyền Bug ID từ ALV (startup only)
  " IF p_bugid IS NOT INITIAL ... (logic moved below to support manual typing)

AT SELECTION-SCREEN.
  " Mỗi khi nhấn Enter hoặc thoát trường P_BUGID, pre-fill thông tin
  IF p_bugid IS NOT INITIAL.
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

  DATA: lv_reason  TYPE zde_bug_desc.

  lv_reason = p_reason.

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
    " Log lịch sử
    CALL FUNCTION 'Z_BUG_LOG_HISTORY'
      EXPORTING
        iv_bug_id      = p_bugid
        iv_action_type = 'ST'
        iv_old_value   = ls_bug-status
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

TABLES: zbug_tracker.

" Selection Screen
SELECT-OPTIONS: s_bugid FOR zbug_tracker-bug_id,
                s_status FOR zbug_tracker-status,
                s_module FOR zbug_tracker-sap_module,
                s_prior  FOR zbug_tracker-priority.

" Internal table
DATA: lt_bugs     TYPE TABLE OF zbug_tracker,
      ls_bug      TYPE zbug_tracker.

" ALV
DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
      ls_fieldcat TYPE slis_fieldcat_alv,
      ls_layout   TYPE slis_layout_alv.

START-OF-SELECTION.

  " Fetch data
  SELECT * FROM zbug_tracker INTO TABLE @lt_bugs
    WHERE bug_id  IN @s_bugid
      AND status  IN @s_status
      AND sap_module IN @s_module
      AND priority IN @s_prior
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
2. Transaction: `ZBUG_REPORT`
3. Short Description: `Bug Tracking Report`
4. Program: `Z_BUG_REPORT_ALV`
5. Click **Save**

**✅ Checkpoint:** Gõ T-code `ZBUG_REPORT` → ALV Grid hiển thị danh sách Bug

---

### Bước 4.3: Nâng cấp ALV - Thêm nút tương tác (Interactive ALV)

> **Lý do (extra-requirements #6):** User cần cập nhật Status/Assign ngay trên ALV thay vì chuyển sang màn hình khác cho các thao tác đơn giản. Thêm 2 nút: **"Update Status"** và **"Assign Dev"** vào Toolbar của ALV.

Thêm đoạn code sau vào `Z_BUG_REPORT_ALV`, bổ sung vào phần `DATA` và xây dựng thêm:

```abap
" Khai báo thêm vào phần DATA
DATA: lt_excl     TYPE slis_t_extab,
      ls_excl     TYPE slis_extab.

" --- FORM hiển thị Toolbar tùy chỉnh ---
FORM user_command USING lv_ucomm TYPE syucomm
                        ls_selfield TYPE slis_selfield.

  DATA: lv_bugid   TYPE zde_bug_id,
        lv_success TYPE char1,
        lv_message TYPE string.

  " Lấy Bug ID tại dòng được click
  READ TABLE lt_bugs INDEX ls_selfield-tabindex INTO DATA(ls_sel).
  lv_bugid = ls_sel-bug_id.

  CASE lv_ucomm.
    WHEN 'ZUPD'.  " Nút Update - Mở Z_BUG_UPDATE_SCREEN
      SET PARAMETER ID 'ZBG' FIELD lv_bugid.
      CALL TRANSACTION 'ZBUG_UPDATE' AND SKIP FIRST SCREEN.

    WHEN 'ZASGN'. " Nút Assign - Tự động assign
      CALL FUNCTION 'Z_BUG_AUTO_ASSIGN'
        EXPORTING
          iv_bug_id  = lv_bugid
          iv_module  = ls_sel-sap_module
        IMPORTING
          ev_message = lv_message.
      MESSAGE lv_message TYPE 'S'.
  ENDCASE.

  ls_selfield-refresh = 'X'.

ENDFORM.

" --- FORM thêm nút vào Toolbar ---
FORM pf_status_set USING lv_extab TYPE slis_t_extab.
  SET PF-STATUS 'ZBUG_STATUS'.
ENDFORM.
```

Sau đó trong `CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'`, thêm 2 tham số Callback:

```abap
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
```

> [!NOTE]
> Tạo thêm GUI Status `ZBUG_STATUS` trong SE80 cho program `Z_BUG_REPORT_ALV` với 2 Function Code: `ZUPD` (Update Bug) và `ZASGN` (Auto Assign).

---

### Bước 4.4: Tạo SmartForm ZBUG_FORM (In ấn Bug Report)

> **Lý do (requirements #3B):** In biên bản bàn giao lỗi dạng văn bản chính thức (PDF/Print).

1. Vào T-code **`SMARTFORMS`**
2. Form Name: `ZBUG_FORM`
3. Click **Create**
4. Thiết kế layout theo cấu trúc sau:

```
Page: FIRST
  Window: HEADER
    - Logo + Tên công ty (BMPFILE nếu có)
    - Tiêu đề: "BUG TRACKING REPORT"
    - Số Bug ID, Ngày in: &DATE& &TIME&

  Window: MAIN
    Text node:
    - Bug ID:     &BUG_ID&
    - Title:      &TITLE&
    - Module:     &SAP_MODULE&
    - Priority:   &PRIORITY&
    - Status:     &STATUS&
    - Reporter:   &TESTER_ID&
    - Developer:  &DEV_ID&
    - Created:    &CREATED_AT&
    - Closed:     &CLOSED_AT&
    - Description: &DESC_TEXT&
    - Reasons:    &REASONS&

  Window: FOOTER
    - Chữ ký Tester / Developer / Manager
```

1. Tab **Form Interface** → Khai báo Parameters vào Import:

| Parameter | Type   | Associated Type |
| --------- | ------ | --------------- |
| IS_BUG    | Import | ZBUG_TRACKER    |

1. Click **Check** → **Activate**

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

Tạo T-code `ZBUG_PRINT` → Program `Z_BUG_PRINT`.

**✅ Checkpoint:** Gõ `ZBUG_PRINT`, nhập Bug ID → Form in ấn preview hiển thị

---

### Bước 4.5: Tạo Manager Dashboard Z_BUG_MANAGER_DASHBOARD

> **Lý do (requirements #10 + extra #7):** Manager cần dashboard tổng hợp: số Bug theo Status/Module, danh sách Bug đang Waiting, và hiệu suất Tester/Developer.

1. Vào T-code `SE38`
2. Program: `Z_BUG_MANAGER_DASHBOARD`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug Manager Dashboard`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Source code:

```abap
*&---------------------------------------------------------------------*
*& Report Z_BUG_MANAGER_DASHBOARD
*&---------------------------------------------------------------------*
REPORT z_bug_manager_dashboard.

TYPES: BEGIN OF ty_stat,
         status   TYPE zde_bug_status,
         cnt      TYPE i,
       END OF ty_stat.

TYPES: BEGIN OF ty_module_stat,
         sap_module TYPE zde_sap_module,
         cnt        TYPE i,
       END OF ty_module_stat.

DATA: lt_stat        TYPE TABLE OF ty_stat,
      ls_stat        TYPE ty_stat,
      lt_mod_stat    TYPE TABLE OF ty_module_stat,
      ls_mod_stat    TYPE ty_module_stat,
      lt_waiting     TYPE TABLE OF zbug_tracker,
      lt_fieldcat    TYPE slis_t_fieldcat_alv,
      ls_fieldcat    TYPE slis_fieldcat_alv,
      ls_layout      TYPE slis_layout_alv,
      lv_total       TYPE i.

START-OF-SELECTION.

  " --- Thống kê theo Status ---
  SELECT status COUNT(*) AS cnt FROM zbug_tracker
    INTO TABLE @lt_stat
    GROUP BY status.

  SELECT COUNT(*) FROM zbug_tracker INTO @lv_total.

  WRITE: / '=== BUG TRACKING DASHBOARD ==='.
  WRITE: / 'Total bugs:', lv_total.
  SKIP.
  WRITE: / '-- By Status --'.

  LOOP AT lt_stat INTO ls_stat.
    WRITE: / ls_stat-status, ':', ls_stat-cnt.
  ENDLOOP.

  " --- Thống kê theo Module ---
  SELECT sap_module COUNT(*) AS cnt FROM zbug_tracker
    INTO TABLE @lt_mod_stat
    GROUP BY sap_module
    ORDER BY cnt DESCENDING.

  SKIP.
  WRITE: / '-- By Module --'.
  LOOP AT lt_mod_stat INTO ls_mod_stat.
    WRITE: / ls_mod_stat-sap_module, ':', ls_mod_stat-cnt.
  ENDLOOP.

  " --- Danh sách Bug đang Waiting (cần Manager assign thủ công) ---
  SELECT * FROM zbug_tracker INTO TABLE @lt_waiting
    WHERE status = 'W'
    ORDER BY created_at ASCENDING.

  SKIP.
  WRITE: / '-- Waiting Bugs (Manual Assign Required) --'.

  " Build fieldcat cho Waiting ALV
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

  ls_layout-zebra = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = ls_layout
      it_fieldcat        = lt_fieldcat
    TABLES
      t_outtab           = lt_waiting
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
```

1. Click **Save** → **Activate**
2. Tạo T-code `ZBUG_MANAGER` → Program `Z_BUG_MANAGER_DASHBOARD` (SE93)

**✅ Checkpoint:** Gõ `ZBUG_MANAGER` → Thấy thống kê tổng Bug + bảng Waiting Bugs

---

### Bước 4.6: Tạo Program Z_BUG_USER_MANAGEMENT (Quản lý tài khoản)

> **Lý do (requirements #6 + #10):** Manager cần màn hình để xem và quản lý danh sách Users, đặc biệt là chỉnh `AVAILABLE_STATUS` của Developer.

> [!TIP]
> **Tài khoản sử dụng:** **DEV-118** (Pass: `Qwer123@`) — Full system access.

1. Vào T-code `SE38`
2. Program: `Z_BUG_USER_MANAGEMENT`
3. Click **Create**
4. Điền các thuộc tính (Attributes):
   - **Title:** `Bug User Management`
   - **Type:** `Executable program`
   - **Status:** `SAP Standard Production Program`
   - **Application:** `Basis`
   - **Fixed point arithmetic:** Tích chọn (Checked)

5. Click **Save** → Chọn Package `ZBUGTRACK`.
6. Xóa phần gán `TEXT-001` (nếu có) và nhấn **Save**.
7. **Định nghĩa Text Symbol:**
   - Lên menu: **Goto** -> **Text Elements** -> **Text Symbols**.
   - Dòng `001`: Nhập `Filter by Role (T=Tester D=Developer M=Manager)`.
   - Nhấn **Save** và **Activate**.
8. Quay lại code và nhấn **Activate** (Ctrl+F3).

**Source code:**

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

### Bước 4.7: Tạo T-code ZBUG_USERS

1. Vào T-code `SE93`
2. Transaction: `ZBUG_USERS`
3. Short Description: `User Management`
4. Program: `Z_BUG_USER_MANAGEMENT`
5. Click **Save**

**✅ Checkpoint:** Gõ `ZBUG_USERS` → ALV hiển thị danh sách Users, lọc được theo Role (T/D/M)

---

## PHASE 5: ADVANCED FUNCTION MODULES (Nâng Cao)

> [!TIP]
> **Tài khoản sử dụng:** **DEV-089** (Pass: `@Anhtuoi123`)  
> Thêm các Function Modules nâng cao vào Function Group `ZBUG_FG`.

> **Mục tiêu:** Auto-assign, Permission Check, History Logging và ALV màu sắc

### Bước 5.1: Z_BUG_AUTO_ASSIGN (Tự động phân công)

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

Để thêm màu vào **`Z_BUG_REPORT_ALV`**, sửa `Z_BUG_REPORT_ALV` như sau:

**1. Tạo type mới có field `ROW_COLOR`:**

```abap
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

DATA: lt_display TYPE TABLE OF ty_bug_display,
      ls_display TYPE ty_bug_display.
```

**2. Map data và gán màu sau khi SELECT:**

```abap
LOOP AT lt_bugs INTO ls_bug.
  CLEAR ls_display.
  ls_display-bug_id     = ls_bug-bug_id.
  ls_display-title      = ls_bug-title.
  ls_display-sap_module = ls_bug-sap_module.
  ls_display-priority   = ls_bug-priority.
  ls_display-status     = ls_bug-status.
  ls_display-tester_id  = ls_bug-tester_id.
  ls_display-created_at = ls_bug-created_at.

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
```

**3. Set layout để kích hoạt màu:**

```abap
ls_layout-info_fieldname = 'ROW_COLOR'.
```

---

### Bước 5.5: Z_BUG_UPLOAD_ATTACHMENT (Đính kèm file qua GOS)

> **Lý do (requirements #5 + extra #4):** Mỗi Bug có 3 loại file đính kèm (ATT_REPORT/ATT_FIX/ATT_VERIFY), mỗi loại do đúng người có trách nhiệm upload. Dùng GOS (Generic Object Services) của SAP với account **DEV-237**.

> [!IMPORTANT]
> Sử dụng account **DEV-237** (Pass: `toiyeufpt`) để thực hiện bước này.

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
    SET dev_id = iv_new_dev_id,
        status = '2'
    WHERE bug_id = iv_bug_id.

  IF sy-subrc <> 0.
    ROLLBACK WORK.
    ev_success = 'N'.
    ev_message = 'Re-assign failed'.
    RETURN.
  ENDIF.

  " Trả Dev cũ về Available
  UPDATE zbug_users
    SET available_status = 'A'
    WHERE user_id = lv_old_dev_id.

  " Đặt Dev mới thành Working
  UPDATE zbug_users
    SET available_status = 'W'
    WHERE user_id = iv_new_dev_id.

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

## PHASE 6: TESTING & DEPLOYMENT (Tuần 6-8)

> [!TIP]
> **Tài khoản sử dụng:**
>
> - Code Inspector: **DEV-118** (Pass: `Qwer123@`)
> - Đính kèm file (GOS): **DEV-237** (Pass: `toiyeufpt`)
> - Cấu hình Email/Verify: **DEV-242** → **DEV-118**

### Bước 6.1: Code Inspector (SCI)

1. Vào T-code `SCI`
2. Create inspection với variant `DEFAULT`
3. Add programs: `Z_BUG_*`
4. Execute → Fix all errors/warnings

### Bước 6.2: Transport Request (SE09)

1. Vào T-code `SE09`
2. Create Transport Request
3. Add all objects từ package `ZBUGTRACK`
4. Release Transport

### Bước 6.3: UAT Checklist (Đầy đủ)

| # | Test Case | T-code / Object | Expected |
| :-- | :--- | :--- | :--- |
| 1 | Tạo Bug mới | `ZBUG_CREATE` | Bug ID sinh tự động, email gửi cho Dev |
| 2 | Xem & Cập nhật Bug | `ZBUG_UPDATE` | Nhập Bug ID → thấy thông tin, đổi Status thành công |
| 3 | Danh sách Bug có màu | `ZBUG_REPORT` | ALV hiển thị Bug với màu theo Status |
| 4 | Nút tương tác trên ALV | `ZBUG_REPORT` | Click row → Nút Update/Assign xuất hiện, hoạt động |
| 5 | In biên bản | `ZBUG_PRINT` | Preview PDF SmartForm hiện đúng thông tin Bug |
| 6 | Manager Dashboard | `ZBUG_MANAGER` | Thống kê Bug + danh sách Waiting hiển thị |
| 7 | Auto Assign | FM `Z_BUG_AUTO_ASSIGN` | Dev ít việc nhất nhận Bug, AVAILABLE_STATUS = W |
| 8 | Re-assign | FM `Z_BUG_REASSIGN` | Dev cũ trở về A, Dev mới nhận Bug, log ghi vào ZBUG_HISTORY |
| 9 | Upload attachment | FM `Z_BUG_UPLOAD_ATTACHMENT` | File path ghi vào ATT_REPORT/FIX/VERIFY tương ứng |
| 10 | Phân quyền | FM `Z_BUG_CHECK_PERMISSION` | Dev không tạo được Bug, Tester không sửa Bug đã assign |
| 11 | History Log | FM `Z_BUG_LOG_HISTORY` | Mọi thay đổi được ghi vào ZBUG_HISTORY |
| 12 | Performance | Tất cả T-code | Response time < 3 giây |

---

## 🎯 HOÀN THÀNH

Chúc mừng! Bạn đã hoàn thành hệ thống SAP Bug Tracking Management.

**Tóm tắt những gì đã xây dựng:**

| Phase | Nội dung | Deliverables | Status |
| :--- | :--- | :--- | :--- |
| 0 | Môi trường | SAP GUI, Package ZBUGTRACK | ✅ |
| 1 | Database Layer | ZBUG_TRACKER, ZBUG_USERS, ZBUG_HISTORY, ZNRO_BUG | ✅ |
| 2 | Business Logic | Z_BUG_CREATE/GET/UPDATE_STATUS/DELETE/SEND_EMAIL, SCOT | ✅ |
| 3 | Presentation | Z_BUG_CREATE_SCREEN, Z_BUG_UPDATE_SCREEN, ZBUG_CREATE, ZBUG_UPDATE | ⏳ |
| 4 | Reporting | Z_BUG_REPORT_ALV (Interactive), ZBUG_FORM, Z_BUG_MANAGER_DASHBOARD, Z_BUG_USER_MANAGEMENT | ⏳ |
| 5 | Advanced FMs | Z_BUG_LOG_HISTORY, Z_BUG_AUTO_ASSIGN, Z_BUG_CHECK_PERMISSION, Z_BUG_UPLOAD_ATTACHMENT, Z_BUG_REASSIGN, ALV Colors | ⏳ |
| 6 | Testing & Deploy | SCI, Transport Request, UAT 12 test cases | ⏳ |

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

**Prepared by:** [Your Name]  
**Last Updated:** 03/03/2026
