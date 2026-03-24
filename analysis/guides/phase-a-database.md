# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE A: DATABASE HARDENING

**Dự án:** SAP Bug Tracking Management System  
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)  
**Thời gian ước tính:** 1 ngày (24-25/03)  

---

## MỤC LỤC

1. [Bước A1: Tạo Domains & Data Elements mới](#bước-a1-tạo-domains--data-elements-mới)
2. [Bước A2: Tạo bảng ZBUG_PROJECT](#bước-a2-tạo-bảng-zbug_project)
3. [Bước A3: Tạo bảng ZBUG_USER_PROJECT](#bước-a3-tạo-bảng-zbug_user_project)
4. [Bước A4: Cập nhật bảng ZBUG_TRACKER (thêm PROJECT_ID, SEVERITY, Audit, IS_DEL)](#bước-a4-cập-nhật-bảng-zbug_tracker)
5. [Bước A5: Cập nhật bảng ZBUG_USERS (thêm Audit, IS_DEL, Email OBLIGATORY)](#bước-a5-cập-nhật-bảng-zbug_users)
6. [Bước A6: Tạo Message Class ZBUG_MSG](#bước-a6-tạo-message-class-zbug_msg)
7. [Bước A7: Tạo Text Object ZBUG_NOTE (Long Text)](#bước-a7-tạo-text-object-zbug_note-long-text)

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

## Bước A3: Tạo bảng ZBUG_USER_PROJECT

**Mục tiêu:** Bảng liên kết Many-to-Many giữa User và Project.

Vào **SE11** → nhập `ZBUG_USER_PROJECT` → **Create** → **Transparent Table**.

### Tab Fields

| Field | Data Element | Type | Length | Key |
| :--- | :--- | :--- | :--- | :--- |
| `MANDT` | `MANDT` | CLNT | 3 | ✓ |
| `USER_ID` | `ZDE_USERNAME` | CHAR | 12 | ✓ |
| `PROJECT_ID` | `ZDE_PROJECT_ID` | CHAR | 20 | ✓ |
| `ERNAM` | `ERNAM` | CHAR | 12 | |
| `ERDAT` | `ERDAT` | DATS | 8 | |
| `ERZET` | `ERZET` | TIMS | 6 | |
| `AENAM` | `AENAM` | CHAR | 12 | |
| `AEDAT` | `AEDAT` | DATS | 8 | |
| `AEZET` | `AEZET` | TIMS | 6 | |

### Tab Technical Settings

- **Data Class:** `APPL0`
- **Size Category:** `0`

Nhấn **Save** → **Activate**.

> ✅ **Checkpoint:** **SE16** → `ZBUG_USER_PROJECT` → hiển thị bảng rỗng, 3 key fields.

---

## Bước A4: Cập nhật bảng ZBUG_TRACKER

**Mục tiêu:** Thêm `PROJECT_ID`, `SEVERITY`, Audit Fields, `IS_DEL` vào bảng bug hiện có.

Vào **SE11** → nhập `ZBUG_TRACKER` → **Change**.

Thêm các trường sau vào cuối bảng:

| Field | Data Element | Chức năng |
| :--- | :--- | :--- |
| `PROJECT_ID` | `ZDE_PROJECT_ID` | FK → ZBUG_PROJECT, Bug thuộc project nào |
| `SEVERITY` | `ZDE_SEVERITY` | 1=Dump, 2=VHigh, 3=High, 4=Normal, 5=Minor |
| `VERIFY_TESTER_ID` | `ZDE_USERID` | Tester verify fix (khi status → Resolved) |
| `APPROVED_BY` | `ZDE_USERID` | Manager approve close |
| `APPROVED_AT` | `DATS` | Ngày approve close |
| `CLOSED_AT` | `DATS` | Ngày đóng bug (auto fill khi status → 7) |
| `AENAM` | `AENAM` | Last changed by (auto fill khi UPDATE) |
| `AEDAT` | `AEDAT` | Last changed date |
| `AEZET` | `AEZET` | Last changed time |
| `IS_DEL` | `ZDE_IS_DEL` | Soft delete flag ('X' = deleted) |

*Lưu ý:*

- Nếu bảng đã có AENAM/AEDAT/AEZET từ trước (check trước khi thêm)
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

> ✅ **Checkpoint:** **SE11** → `ZBUG_TRACKER` → Display → thấy `PROJECT_ID`, `SEVERITY`, `IS_DEL`.

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

Nhấn **Save** → **Activate**.

**Thêm bản dịch Tiếng Việt:**

1. Vẫn ở **SE91** → `ZBUG_MSG` → chọn **Goto** → **Translation**
2. Hoặc dùng T-code **SE63** → Short Texts → SE91 Messages
3. Target Language: **VI** (Vietnamese)
4. Dịch từng message, ví dụ:
   - `001`: "Bug &1 đã tạo thành công"
   - `003`: "Không tìm thấy user trong hệ thống"
   - `005`: "Chỉ Tester mới được tạo bug"
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

> ✅ **Checkpoint:** **SE91** → `ZBUG_MSG` → thấy 30+ messages, chuyển logon language EN/VI → text thay đổi.

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

## TỔNG KẾT PHASE A

Sau khi hoàn thành Phase A, bạn phải có:

- [x] **4 Domains mới:** `ZDOM_PROJECT_ID`, `ZDOM_PRJ_STATUS`, `ZDOM_SEVERITY`, `ZDOM_IS_DEL`
- [x] **6 Data Elements mới:** `ZDE_PROJECT_ID`, `ZDE_PRJ_NAME`, `ZDE_PRJ_DESC`, `ZDE_PRJ_STATUS`, `ZDE_SEVERITY`, `ZDE_IS_DEL`
- [x] **2 Bảng mới:** `ZBUG_PROJECT` (16 fields), `ZBUG_USER_PROJECT` (9 fields)
- [x] **2 Bảng cập nhật:** `ZBUG_TRACKER` (+10 fields: PROJECT_ID, SEVERITY, VERIFY_TESTER_ID, APPROVED_BY/AT, CLOSED_AT, AENAM/DAT/ZET, IS_DEL), `ZBUG_USERS` (+4 fields)
- [x] **1 Message Class:** `ZBUG_MSG` (30+ messages, EN + VI)
- [x] **1 Text Object:** `ZBUG` (3 Text IDs: `Z001`, `Z002`, `Z003`)

**Kiểm tra cuối cùng:**

1. SE11 → `ZBUG_PROJECT` → Active
2. SE11 → `ZBUG_USER_PROJECT` → Active
3. SE11 → `ZBUG_TRACKER` → có `PROJECT_ID`, `SEVERITY`, `IS_DEL`
4. SE11 → `ZBUG_USERS` → có `AENAM`, `IS_DEL`, `EMAIL` obligatory
5. SE91 → `ZBUG_MSG` → 30+ messages
6. SE75 → `ZBUG` → 3 Text IDs

👉 **Chuyển sang Phase B: Business Logic Update**
