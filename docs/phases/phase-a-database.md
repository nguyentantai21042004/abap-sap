# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE A: DATABASE HARDENING

**Dự án:** SAP Bug Tracking Management System
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)
**Thời gian ước tính:** 1 ngày (24-25/03)
**Development Account:** `DEV-089` (Pass: `@Anhtuoi123`) — *Quyền SE11, SE80*

---

## MỤC LỤC

1. [Bước A1: Tạo Domains & Data Elements mới](#bước-a1-tạo-domains--data-elements-mới)
2. [Bước A2: Tạo bảng ZBUG_PROJECT](#bước-a2-tạo-bảng-zbug_project)
3. [Bước A3: Tạo bảng ZBUG_USER_PROJEC](#bước-a3-tạo-bảng-zbug_user_projec)
4. [Bước A4: Cập nhật bảng ZBUG_TRACKER (thêm PROJECT_ID, SEVERITY, Audit, IS_DEL)](#bước-a4-cập-nhật-bảng-zbug_tracker)
5. [Bước A5: Cập nhật bảng ZBUG_USERS (thêm Audit, IS_DEL, Email OBLIGATORY)](#bước-a5-cập-nhật-bảng-zbug_users)
6. [Bước A6: Tạo Message Class ZBUG_MSG](#bước-a6-tạo-message-class-zbug_msg)
7. [Bước A7: Tạo Text Object ZBUG_NOTE (Long Text)](#bước-a7-tạo-text-object-zbug_note-long-text)
8. [Bước A8: Status Code Migration Script (CRITICAL)](#bước-a8-status-code-migration-script)

---

## Bước A1: Tạo Domains & Data Elements mới

**Mục tiêu:** Tạo các Domain và Data Element cần thiết cho Project, Severity, Soft Delete.

Vào T-code **SE11**, tạo lần lượt:

### 1. Domains

| Domain | Type | Length | Fixed Values |
| :--- | :--- | :--- | :--- |
| `ZDOM_PROJECT_ID` | CHAR | 20 | |
| `ZDOM_PRJ_STATUS` | CHAR | 1 | 1=Opening, 2=InProcess, 3=Done, 4=Cancel |
| `ZDOM_SEVERITY` | CHAR | 1 | 1=Dump, 2=VeryHigh, 3=High, 4=Normal, 5=Minor |
| `ZDOM_IS_DEL` | CHAR | 1 | (space)=Active, X=Deleted |

**Cách tạo Domain (ví dụ ZDOM_SEVERITY):**

1. **SE11** → nhập `ZDOM_SEVERITY` → **Create**
2. **Short Description:** "Severity Level"
3. Tab **Definition:** Data Type = `CHAR`, No. Characters = `1`
4. Tab **Value Range** → Fixed Values:
   - `1` = Dump
   - `2` = Very High
   - `3` = High
   - `4` = Normal
   - `5` = Minor
5. **Save** → **Activate**
6. Lặp lại cho các Domain còn lại.

### 2. Data Elements

| Data Element | Domain | Short Text |
| :--- | :--- | :--- |
| `ZDE_PROJECT_ID` | `ZDOM_PROJECT_ID` | Project ID |
| `ZDE_PRJ_NAME` | `CHAR100` | Project Name |
| `ZDE_PRJ_DESC` | `CHAR255` | Project Description |
| `ZDE_PRJ_STATUS` | `ZDOM_PRJ_STATUS` | Project Status |
| `ZDE_SEVERITY` | `ZDOM_SEVERITY` | Bug Severity Level |
| `ZDE_IS_DEL` | `ZDOM_IS_DEL` | Soft Delete Flag |

**Cách tạo Data Element (ví dụ ZDE_SEVERITY):**

1. **SE11** → nhập `ZDE_SEVERITY` → **Create**
2. **Short Description:** "Bug Severity Level"
3. Tab **Data Type:** Domain = `ZDOM_SEVERITY`
4. Tab **Field Label:**
   - Short: Severity
   - Medium: Severity Level
   - Long: Bug Severity Level
   - Heading: Severity
5. **Save** → **Activate**
6. Lặp lại cho các Data Elements còn lại.

> ✅ **Checkpoint:** Tất cả Domains và Data Elements ở trạng thái Active.

---

## Bước A2: Tạo bảng ZBUG_PROJECT

**Mục tiêu:** Bảng quản lý Project — mỗi Bug sẽ thuộc về 1 Project.

Vào **SE11** → nhập `ZBUG_PROJECT` → **Create** → **Transparent Table**.

### Tab Fields

| Field | Data Element | Type | Length | Key | Initial | Not Null |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `MANDT` | `MANDT` | CLNT | 3 | ✓ | | |
| `PROJECT_ID` | `ZDE_PROJECT_ID` | CHAR | 20 | ✓ | | |
| `PROJECT_NAME` | `ZDE_PRJ_NAME` | CHAR | 100 | | | |
| `DESCRIPTION` | `ZDE_PRJ_DESC` | CHAR | 255 | | | |
| `START_DATE` | `SYDATUM` | DATS | 8 | | | |
| `END_DATE` | `SYDATUM` | DATS | 8 | | | |
| `PROJECT_MANAGER` | `ZDE_USERNAME` | CHAR | 12 | | | |
| `PROJECT_STATUS` | `ZDE_PRJ_STATUS` | CHAR | 1 | | X | |
| `NOTE` | `CHAR255` | CHAR | 255 | | | |
| `ERNAM` | `ERNAM` | CHAR | 12 | | | |
| `ERDAT` | `ERDAT` | DATS | 8 | | | |
| `ERZET` | `ERZET` | TIMS | 6 | | | |
| `AENAM` | `AENAM` | CHAR | 12 | | | |
| `AEDAT` | `AEDAT` | DATS | 8 | | | |
| `AEZET` | `AEZET` | TIMS | 6 | | | |
| `IS_DEL` | `ZDE_IS_DEL` | CHAR | 1 | | X | |

*Lưu ý: Field `PROJECT_STATUS` default = `1` (Opening). Field `IS_DEL` default = ` ` (Active).*

### Tab Technical Settings

- **Data Class:** `APPL0` (Master Data)
- **Size Category:** `0` (0 - 2,600 records)
- **Buffering:** Not allowed

### Tab Enhancement Category

- Can Be Enhanced (Character-Type or Numeric)

Nhấn **Save** → **Activate**.

> ✅ **Checkpoint:** **SE16** → `ZBUG_PROJECT` → hiển thị bảng rỗng, cấu trúc đúng 16 fields.

---

## Bước A3: Tạo bảng ZBUG_USER_PROJEC

**Mục tiêu:** Bảng liên kết Many-to-Many giữa User và Project.

Vào **SE11** → nhập `ZBUG_USER_PROJEC` → **Create** → **Transparent Table**.

### Tab Fields

| Field | Data Element | Type | Length | Key |
| :--- | :--- | :--- | :--- | :--- |
| `MANDT` | `MANDT` | CLNT | 3 | ✓ |
| `USER_ID` | `ZDE_USERNAME` | CHAR | 12 | ✓ |
| `PROJECT_ID` | `ZDE_PROJECT_ID` | CHAR | 20 | ✓ |
| `ROLE` | `ZDE_BUG_ROLE` | CHAR | 1 | |
| `ERNAM` | `ERNAM` | CHAR | 12 | |
| `ERDAT` | `ERDAT` | DATS | 8 | |
| `ERZET` | `ERZET` | TIMS | 6 | |
| `AENAM` | `AENAM` | CHAR | 12 | |
| `AEDAT` | `AEDAT` | DATS | 8 | |
| `AEZET` | `AEZET` | TIMS | 6 | |

> ⚠️ **Lưu ý ROLE field:**
> - Data Element `ZDE_BUG_ROLE` đã có sẵn trong bảng `ZBUG_USERS` (CHAR 1, values T=Tester, D=Developer, M=Manager)
> - Đây là **cùng một data element** — user có thể có role khác nhau trong từng project
> - **Không thêm ROLE vào ZBUG_USERS** (nó đã có sẵn ở đó từ đầu)
> - Nếu SAP báo `ZDE_BUG_ROLE not found` khi tạo bảng → data element này đang được define trong domain `ZDOM_BUG_ROLE`; kiểm tra SE11 → ZBUG_USERS để xem data element thực tế đang dùng cho field ROLE

### Tab Technical Settings

- **Data Class:** `APPL0`
- **Size Category:** `0`

Nhấn **Save** → **Activate**.

> ✅ **Checkpoint:** **SE16** → `ZBUG_USER_PROJEC` → hiển thị bảng rỗng, 3 key fields + field ROLE.

---

## Bước A4: Cập nhật bảng ZBUG_TRACKER

**Mục tiêu:** Thêm `PROJECT_ID`, `SEVERITY`, Audit Fields, `IS_DEL` vào bảng bug hiện có.

> ⚠️ **QUAN TRỌNG — Audit Fields:**
>
> Bảng ZBUG_TRACKER hiện tại (từ developer-guide.md) chỉ có `CREATED_AT` (DATS) và `CREATED_TIME` (TIMS) — đây KHÔNG phải ERNAM/ERDAT/ERZET chuẩn SAP.
>
> - `ERNAM`/`ERDAT`/`ERZET` là **fields MỚI** (Created by/date/time theo SAP convention)
> - `AENAM`/`AEDAT`/`AEZET` cũng là **fields MỚI** (Last changed by/date/time)
> - Giữ lại `CREATED_AT`/`CREATED_TIME` cũ (không xóa, tránh mất data), nhưng code mới sẽ dùng `ERNAM`/`ERDAT`/`ERZET`
>
> Sau khi thêm fields, cần **backfill** data cũ:
> ```abap
> UPDATE zbug_tracker SET ernam = tester_id, erdat = created_at, erzet = created_time
>   WHERE ernam IS INITIAL.
> ```

Vào **SE11** → nhập `ZBUG_TRACKER` → **Change**.

Thêm các trường sau vào cuối bảng:

| Field | Data Element | Chức năng | Ghi chú |
| :--- | :--- | :--- | :--- |
| `PROJECT_ID` | `ZDE_PROJECT_ID` | FK → ZBUG_PROJECT, Bug thuộc project nào | |
| `SEVERITY` | `ZDE_SEVERITY` | 1=Dump, 2=VHigh, 3=High, 4=Normal, 5=Minor | Default '4' |
| `VERIFY_TESTER_ID` | `ZDE_USERNAME` | Tester verify fix (khi status → Resolved) | |
| `APPROVED_BY` | `ZDE_USERNAME` | Manager approve close | |
| `APPROVED_AT` | `DATS` | Ngày approve close | |
| `CLOSED_AT` | `DATS` | Ngày đóng bug (auto fill khi status → 7) | |
| `ERNAM` | `ERNAM` | Created by (SAP standard) | **MỚI** — backfill từ TESTER_ID |
| `ERDAT` | `ERDAT` | Created date (SAP standard) | **MỚI** — backfill từ CREATED_AT |
| `ERZET` | `ERZET` | Created time (SAP standard) | **MỚI** — backfill từ CREATED_TIME |
| `AENAM` | `AENAM` | Last changed by | **MỚI** |
| `AEDAT` | `AEDAT` | Last changed date | **MỚI** |
| `AEZET` | `AEZET` | Last changed time | **MỚI** |
| `IS_DEL` | `ZDE_IS_DEL` | Soft delete flag ('X' = deleted) | |

*Lưu ý:*

- Dùng `ZDE_USERNAME` (CHAR 12) cho `VERIFY_TESTER_ID` và `APPROVED_BY` — nhất quán với `TESTER_ID`/`DEV_ID` đã có trong bảng
- SEVERITY default nên là '4' (Normal)
- `CLOSED_AT` tự động fill khi status chuyển sang 7 (Closed) trong FM `Z_BUG_UPDATE_STATUS`
- `VERIFY_TESTER_ID` fill khi Tester verify pass (status 5→6)

Nhấn **Save** → **Activate**.

> ⚠️ **NẾU bảng đã có dữ liệu:**
>
> - SAP sẽ yêu cầu Adjust Database
> - Vào **SE14** → nhập `ZBUG_TRACKER` → **Adjust**
> - Chọn "Activate and adjust database table"
> - Kiểm tra log, đảm bảo không mất dữ liệu

**Backfill audit fields cho dữ liệu cũ (chạy 1 lần trong SE38):**

```abap
REPORT z_bug_backfill_audit.
" Backfill ERNAM/ERDAT/ERZET từ CREATED_AT/CREATED_TIME/TESTER_ID
UPDATE zbug_tracker
  SET ernam = tester_id
      erdat = created_at
      erzet = created_time
  WHERE ernam = '' OR ernam IS INITIAL.
COMMIT WORK.
WRITE: / 'Backfill complete. Records updated:', sy-dbcnt.
```

> ✅ **Checkpoint:** **SE11** → `ZBUG_TRACKER` → Display → thấy `PROJECT_ID`, `SEVERITY`, `ERNAM`, `ERDAT`, `ERZET`, `IS_DEL` (tổng cộng +13 fields mới).

---

## Bước A5: Cập nhật bảng ZBUG_USERS

**Mục tiêu:** Thêm Audit Fields, `IS_DEL`, Email OBLIGATORY.

Vào **SE11** → nhập `ZBUG_USERS` → **Change**.

Thêm các trường (nếu chưa có):

| Field | Data Element | Chức năng |
| :--- | :--- | :--- |
| `AENAM` | `AENAM` | Last changed by |
| `AEDAT` | `AEDAT` | Last changed date |
| `AEZET` | `AEZET` | Last changed time |
| `IS_DEL` | `ZDE_IS_DEL` | Soft delete flag |

**Cập nhật field EMAIL:**

1. Click vào field `EMAIL`
2. Nếu dùng Data Element → vào Data Element → sửa Domain → Check "Required Entry" / "Obligatory"
3. Hoặc trực tiếp trong bảng: check column "Not Null" cho field `EMAIL`

Nhấn **Save** → **Activate** → **SE14** Adjust nếu cần.

> ✅ **Checkpoint:** **SE16** → `ZBUG_USERS` → cấu trúc có `AENAM`, `AEDAT`, `AEZET`, `IS_DEL`.

---

## Bước A6: Tạo Message Class ZBUG_MSG

**Mục tiêu:** Tạo Message Class để hỗ trợ đa ngôn ngữ (EN/VI).

Vào **SE91** → nhập `ZBUG_MSG` → **Create**.

- **Short Text:** "Bug Tracking System Messages"

Tab **Messages** — tạo các message số sau (EN trước):

| No. | Short Text (EN) |
| :--- | :--- |
| `000` | `&1 &2 &3 &4` (Generic placeholder) |
| `001` | `Bug &1 created successfully` |
| `002` | `Bug &1 updated successfully` |
| `003` | `User not found in system` |
| `004` | `User is not a member of this project` |
| `005` | `Only Tester can create bugs` |
| `006` | `Not authorized to update this bug` |
| `007` | `Only Manager can delete projects` |
| `008` | `Project must be Done or Cancel to delete` |
| `009` | `Please select a row first` |
| `010` | `Database insert failed` |
| `011` | `Failed to generate Bug ID` |
| `012` | `Project &1 created successfully` |
| `013` | `Project still has unresolved bugs` |
| `014` | `Employee cannot work on multiple projects at same time` |
| `015` | `Upload BUGPROOF file before creating bug` |
| `016` | `Upload TESTCASE file before marking as Fixed` |
| `017` | `Upload CONFIRM file before marking as Resolved` |
| `018` | `Invalid status transition from &1 to &2` |
| `019` | `Are you sure you want to delete this &1?` |
| `020` | `Operation cancelled` |
| `021` | `Project &1 does not exist or is inactive` |
| `022` | `Bug can only be created in InProcess projects` |
| `023` | `Email is required for user registration` |
| `024` | `Invalid email format` |
| `025` | `Successfully saved` |
| `026` | `Data refreshed` |
| `027` | `Email sent successfully` |
| `028` | `Status changed from &1 to &2` |
| `029` | `User &1 does not exist or is inactive` |
| `030` | `High severity bug must have High priority` |
| `031` | `Bug &1 reassigned to &2 successfully` |
| `032` | `New developer must belong to the same project` |
| `033` | `Bug is already closed, cannot modify` |

Nhấn **Save** → **Activate**.

**Thêm bản dịch Tiếng Việt:**

1. Vẫn ở **SE91** → `ZBUG_MSG` → chọn **Goto** → **Translation**
2. Hoặc dùng T-code **SE63** → Short Texts → SE91 Messages
3. Target Language: **VI** (Vietnamese)
4. Dịch từng message, ví dụ:
   - `001`: "Bug &1 đã tạo thành công"
   - `003`: "Không tìm thấy user trong hệ thống"
   - `005`: "Chỉ Tester mới được tạo bug"
   - `031`: "Bug &1 đã chuyển giao cho &2 thành công"
5. **Save**

**Cách sử dụng Message Class trong code:**

```abap
" Thay vì hardcode:
" ev_message = 'User not found in system'.

" Dùng Message Class:
MESSAGE s003(zbug_msg) INTO ev_message.
" hoặc
MESSAGE s001(zbug_msg) WITH ev_bug_id INTO ev_message.
" hoặc hiển thị trực tiếp (popup/status bar):
MESSAGE s026(zbug_msg).  " 'Data refreshed'
MESSAGE s018(zbug_msg) WITH lv_old_status lv_new_status DISPLAY LIKE 'E'.
```

> ✅ **Checkpoint:** **SE91** → `ZBUG_MSG` → thấy 33+ messages, chuyển logon language EN/VI → text thay đổi.

---

## Bước A7: Tạo Text Object ZBUG_NOTE (Long Text)

**Mục tiêu:** Tạo Text Object để lưu Long Text cho Dev Note, Tester Note, Root Cause.

Vào **SE75** → **Create**:

**Text Object:** `ZBUG`

- **Description:** "Bug Tracking Long Texts"

Tạo 3 Text IDs:

| Text ID | Description | Text Format |
| :--- | :--- | :--- |
| `Z001` | Developer Note | `*` |
| `Z002` | Tester/Functional Note | `*` |
| `Z003` | Root Cause Analysis | `*` |

**Cách đọc / ghi Long Text bằng ABAP:**

```abap
" --- Đọc Long Text ---
DATA: lt_lines TYPE TABLE OF tline,
      ls_header TYPE thead.

ls_header-tdname    = lv_bug_id.       " Object key = Bug ID
ls_header-tdid      = 'Z001'.          " Text ID: Dev Note
ls_header-tdobject  = 'ZBUG'.          " Text Object
ls_header-tdspras   = sy-langu.        " Language

CALL FUNCTION 'READ_TEXT'
  EXPORTING
    id        = ls_header-tdid
    language  = ls_header-tdspras
    name      = ls_header-tdname
    object    = ls_header-tdobject
  TABLES
    lines     = lt_lines
  EXCEPTIONS
    not_found = 1
    OTHERS    = 2.

" --- Ghi Long Text ---
CALL FUNCTION 'SAVE_TEXT'
  EXPORTING
    header   = ls_header
    insert   = 'X'           " 'X' = tạo mới nếu chưa có
  TABLES
    lines    = lt_lines
  EXCEPTIONS
    OTHERS   = 1.
COMMIT WORK.
```

> ✅ **Checkpoint:** **SE75** → Text Object `ZBUG` → 3 Text IDs (`Z001`, `Z002`, `Z003`) active.

---

## Bước A8: Status Code Migration Script

**Mục tiêu:** Migrate status codes cũ sang 9-state model mới. Đây là bước **CRITICAL** — phải chạy SAU khi A4 hoàn thành (IS_DEL field tồn tại) và TRƯỚC khi Phase B code goes live.

> ⚠️ **CONFLICT GIỮA HỆ THỐNG CŨ VÀ MỚI:**
>
> | Status Code | Ý nghĩa CŨ (developer-guide.md) | Ý nghĩa MỚI (9-state) |
> | :--- | :--- | :--- |
> | `4` | Fixed | **Pending** |
> | `5` | Closed | **Fixed** |
> | `6` | Deleted | **Resolved** |
> | `7` | *(không có)* | **Closed** |
> | `R` | *(không có)* | **Rejected** |
>
> Nếu KHÔNG migrate, bugs cũ có status=4 (Fixed) sẽ bị hiểu nhầm là Pending!

Tạo report `Z_BUG_MIGRATE_STATUS` trong **SE38** → chạy 1 lần duy nhất:

```abap
REPORT z_bug_migrate_status.

*&---------------------------------------------------------------------*
*& Status Code Migration: Old → New 9-State Model
*& Chạy 1 lần SAU Phase A4 (IS_DEL field exists), TRƯỚC Phase B
*&---------------------------------------------------------------------*

DATA: lv_cnt_4  TYPE i,  " Old Fixed
      lv_cnt_5  TYPE i,  " Old Closed
      lv_cnt_6  TYPE i,  " Old Deleted
      lv_answer TYPE char1.

" ====== PRE-CHECK: Đếm records cần migrate ======
SELECT COUNT(*) FROM zbug_tracker INTO @lv_cnt_4 WHERE status = '4'.
SELECT COUNT(*) FROM zbug_tracker INTO @lv_cnt_5 WHERE status = '5'.
SELECT COUNT(*) FROM zbug_tracker INTO @lv_cnt_6 WHERE status = '6'.

DATA: lv_total TYPE i.
lv_total = lv_cnt_4 + lv_cnt_5 + lv_cnt_6.

WRITE: / '=== STATUS MIGRATION PRE-CHECK ==='.
WRITE: / 'Status 4 (Old Fixed → New 5 Fixed):', lv_cnt_4, 'records'.
WRITE: / 'Status 5 (Old Closed → New 7 Closed):', lv_cnt_5, 'records'.
WRITE: / 'Status 6 (Old Deleted → IS_DEL=X):', lv_cnt_6, 'records'.
WRITE: / 'Total records to migrate:', lv_total.
SKIP.

IF lv_total = 0.
  WRITE: / 'Không có records nào cần migrate. Kết thúc.'.
  RETURN.
ENDIF.

" ====== CONFIRMATION ======
CALL FUNCTION 'POPUP_TO_CONFIRM'
  EXPORTING
    titlebar      = 'Status Migration'
    text_question = |Migrate { lv_total } records? This cannot be undone.|
    text_button_1 = 'Yes, Migrate'
    text_button_2 = 'Cancel'
  IMPORTING
    answer        = lv_answer.

IF lv_answer <> '1'.
  WRITE: / 'Migration cancelled by user.'.
  RETURN.
ENDIF.

" ====== STEP 1: Remap status codes ======
" THỨ TỰ QUAN TRỌNG: Phải remap 5→7 TRƯỚC, rồi mới 4→5
" Nếu làm ngược (4→5 trước), thì khi remap 5→7 sẽ bắt cả records vừa đổi!

" Step 1a: Old 5 (Closed) → New 7 (Closed)
UPDATE zbug_tracker SET status = '7',
                        aenam  = @sy-uname,
                        aedat  = @sy-datum,
                        aezet  = @sy-uzeit
  WHERE status = '5'.
DATA(lv_migrated_5) = sy-dbcnt.
WRITE: / 'Step 1a: Status 5→7 (Closed):', lv_migrated_5, 'records updated'.

" Step 1b: Old 4 (Fixed) → New 5 (Fixed)
UPDATE zbug_tracker SET status = '5',
                        aenam  = @sy-uname,
                        aedat  = @sy-datum,
                        aezet  = @sy-uzeit
  WHERE status = '4'.
DATA(lv_migrated_4) = sy-dbcnt.
WRITE: / 'Step 1b: Status 4→5 (Fixed):', lv_migrated_4, 'records updated'.

" ====== STEP 2: Convert old Deleted (status=6) → IS_DEL='X' ======
" Set status to '7' (Closed) vì bug đã bị xóa = effectively closed
UPDATE zbug_tracker SET is_del = 'X',
                        status = '7',
                        aenam  = @sy-uname,
                        aedat  = @sy-datum,
                        aezet  = @sy-uzeit
  WHERE status = '6'.
DATA(lv_migrated_6) = sy-dbcnt.
WRITE: / 'Step 2: Status 6→IS_DEL=X:', lv_migrated_6, 'records soft-deleted'.

" ====== STEP 3: Update ZBUG_HISTORY references ======
" Remap old_value/new_value trong history (cùng thứ tự: 5→7 trước, 4→5 sau)
UPDATE zbug_history SET new_value = '7' WHERE new_value = '5' AND action_type = 'ST'.
UPDATE zbug_history SET old_value = '7' WHERE old_value = '5' AND action_type = 'ST'.
UPDATE zbug_history SET new_value = '5' WHERE new_value = '4' AND action_type = 'ST'.
UPDATE zbug_history SET old_value = '5' WHERE old_value = '4' AND action_type = 'ST'.
WRITE: / 'Step 3: ZBUG_HISTORY old/new values remapped'.

" ====== STEP 4: COMMIT ======
COMMIT WORK AND WAIT.
WRITE: / ''.
WRITE: / '=== MIGRATION COMPLETE ==='.
lv_total = lv_migrated_4 + lv_migrated_5 + lv_migrated_6.
WRITE: / 'Total migrated:', lv_total, 'records'.

" ====== POST-CHECK ======
SKIP.
WRITE: / '=== POST-MIGRATION VERIFICATION ==='.
SELECT COUNT(*) FROM zbug_tracker INTO @DATA(lv_check_4) WHERE status = '4'.
SELECT COUNT(*) FROM zbug_tracker INTO @DATA(lv_check_6)
  WHERE status = '6' AND is_del <> 'X'.
WRITE: / 'Records still at status 4 (should be 0 unless new Pending):', lv_check_4.
WRITE: / 'Records at status 6 without IS_DEL (should be 0):', lv_check_6.

IF lv_check_4 = 0 AND lv_check_6 = 0.
  WRITE: / '✅ Migration verified successfully!'.
ELSE.
  WRITE: / '⚠️ WARNING: Unexpected records found. Please check manually.'.
ENDIF.
```

> ⚠️ **Chạy report này ĐÚNG 1 LẦN, sau A4 và TRƯỚC Phase B.**
>
> Nếu chạy nhầm 2 lần, Step 1 sẽ không gây hại (vì không còn records status=4/5 cũ), nhưng cần verify lại.

> ✅ **Checkpoint sau khi chạy:**
> - **SE16** → `ZBUG_TRACKER` → không còn status='6' với IS_DEL='' (space)
> - **SE16** → `ZBUG_TRACKER` → tất cả bug cũ "Fixed" giờ có status='5', "Closed" có status='7'
> - Report output hiện "Migration verified successfully!"

---

## TỔNG KẾT PHASE A

Sau khi hoàn thành Phase A, bạn phải có:

- [x] **4 Domains mới:** `ZDOM_PROJECT_ID`, `ZDOM_PRJ_STATUS`, `ZDOM_SEVERITY`, `ZDOM_IS_DEL`
- [x] **6 Data Elements mới:** `ZDE_PROJECT_ID`, `ZDE_PRJ_NAME`, `ZDE_PRJ_DESC`, `ZDE_PRJ_STATUS`, `ZDE_SEVERITY`, `ZDE_IS_DEL`
- [x] **2 Bảng mới:** `ZBUG_PROJECT` (16 fields), `ZBUG_USER_PROJEC` (9 fields)
- [x] **2 Bảng cập nhật:** `ZBUG_TRACKER` (+13 fields: PROJECT_ID, SEVERITY, VERIFY_TESTER_ID, APPROVED_BY/AT, CLOSED_AT, ERNAM/DAT/ZET, AENAM/DAT/ZET, IS_DEL), `ZBUG_USERS` (+4 fields)
- [x] **1 Message Class:** `ZBUG_MSG` (33+ messages, EN + VI)
- [x] **1 Text Object:** `ZBUG` (3 Text IDs: `Z001`, `Z002`, `Z003`)
- [x] **1 Migration Report:** `Z_BUG_MIGRATE_STATUS` (đã chạy thành công)

**Kiểm tra cuối cùng:**

1. SE11 → `ZBUG_PROJECT` → Active
2. SE11 → `ZBUG_USER_PROJEC` → Active
3. SE11 → `ZBUG_TRACKER` → có `PROJECT_ID`, `SEVERITY`, `ERNAM`, `ERDAT`, `ERZET`, `IS_DEL`
4. SE11 → `ZBUG_USERS` → có `AENAM`, `IS_DEL`, `EMAIL` obligatory
5. SE91 → `ZBUG_MSG` → 33+ messages
6. SE75 → `ZBUG` → 3 Text IDs
7. `Z_BUG_MIGRATE_STATUS` → đã chạy, output hiện "Migration verified successfully!"

👉 **Chuyển sang Phase B: Business Logic Update**
