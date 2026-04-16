# ZBUG_* System - Full Requirements Specification (Module Pool Edition)

> **Version:** 2.0 — Cập nhật: 24/03/2026  
> **Deadline:** 03/04/2026 (Demo Day)  
> **Mục tiêu:** Tổng hợp toàn bộ requirements từ client, kết hợp phân tích reference system ZPG_BUGTRACKING_*, để xây dựng hệ thống Bug Tracking vượt trội hơn reference — sử dụng **Module Pool** (Type M) thay vì Executable Program.

---

## 1. TỔNG QUAN HỆ THỐNG

### 1.1 Thông tin môi trường

| Mục | Giá trị |
|-----|---------|
| System | S40 (FU) |
| Application Server | S40Z00 |
| Instance | 00 |
| SAP Version | 770 |
| Client | 324 |
| Package | ZBUGTRACK |

### 1.2 Kiến trúc tổng thể

```
┌──────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                         │
│  Module Pool Z_BUG_WORKSPACE_MP (Type M)                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────┐ │
│  │ Scr 0100 │ │ Scr 0200 │ │ Scr 0300 │ │Scr 0400│ │Sc0500│ │
│  │ Main Hub │ │ Bug List │ │ Bug Det. │ │Prj List│ │PrjDet│ │
│  │ (Router) │ │ (ALV)    │ │ (Tabs)   │ │(ALV)   │ │(Form)│ │
│  └──────────┘ └──────────┘ └──────────┘ └────────┘ └──────┘ │
│  GUI Status | Tab Strip | Table Control | F4 Help | GOS     │
├──────────────────────────────────────────────────────────────┤
│                    APPLICATION LAYER                          │
│  Function Group: ZBUG_FG                                      │
│  ┌──────────────┐ ┌────────────────┐ ┌────────────────┐      │
│  │Z_BUG_CREATE  │ │Z_BUG_AUTO_     │ │Z_BUG_CHECK_   │      │
│  │Z_BUG_UPDATE  │ │  ASSIGN        │ │  PERMISSION    │      │
│  │Z_BUG_DELETE  │ │Z_BUG_REASSIGN  │ │Z_BUG_LOG_     │      │
│  │              │ │                │ │  HISTORY       │      │
│  └──────────────┘ └────────────────┘ └────────────────┘      │
│  ┌──────────────┐ ┌────────────────┐ ┌────────────────┐      │
│  │Z_BUG_SEND_   │ │Z_BUG_GOS_     │ │Z_BUG_GET_     │      │
│  │  EMAIL       │ │  UPLOAD/LIST   │ │  STATISTICS    │      │
│  └──────────────┘ └────────────────┘ └────────────────┘      │
├──────────────────────────────────────────────────────────────┤
│                      DATA LAYER                               │
│  ZBUG_TRACKER | ZBUG_USERS | ZBUG_HISTORY | ZBUG_PROJECT      │
│  ZBUG_USER_PROJECT | Number Range: ZNRO_BUG                   │
│  Text Object: ZBUG_NOTE | Message Class: ZBUG_MSG             │
│  SmartForm: ZBUG_FORM | ZBUG_EMAIL_FORM                       │
└──────────────────────────────────────────────────────────────┘
```

### 1.3 Các vai trò (Roles)

| Role | Code | Mô tả |
|------|------|--------|
| Tester | T | Tạo bug, upload evidence, tự fix Config bug, verify fix |
| Developer | D | Fix Code bug, upload evidence, reject & request reassign |
| Manager | M | Full access, approve assignment, quản lý account, dashboard |

---

## 2. DATABASE LAYER

### 2.1 Table: ZBUG_TRACKER (Bug Information)

| # | Field | Data Element | Type | Length | Mô tả | Ghi chú |
|---|-------|-------------|------|--------|--------|---------|
| 1 | MANDT | MANDT | CLNT | 3 | Client | Key |
| 2 | BUG_ID | ZDE_BUGID | CHAR | 10 | Bug ID | Key, auto-gen (ZNRO_BUG), format: BUG0000001 |
| 3 | TITLE | ZDE_BUG_TITLE | CHAR | 100 | Tiêu đề bug | Mandatory |
| 4 | MODULE | ZDE_MODULE | CHAR | 20 | SAP Module (MM, SD, FI...) | Mandatory |
| 5 | PRIORITY | ZDE_PRIORITY | CHAR | 1 | H=High, M=Medium, L=Low | Mandatory |
| 6 | STATUS | ZDE_BUG_STATUS | CHAR | 1 | Trạng thái (xem 2.4) | Default '1' |
| 7 | BUG_TYPE | ZDE_BUG_TYPE | CHAR | 1 | C=Code, F=Config | Default 'C' |
| 8 | TESTER_ID | ZDE_USERID | CHAR | 12 | Người report (auto = SY-UNAME) | |
| 9 | DEV_ID | ZDE_USERID | CHAR | 12 | Developer được assign | |
| 10 | VERIFY_TESTER_ID | ZDE_USERID | CHAR | 12 | Tester verify fix | |
| 11 | APPROVED_BY | ZDE_USERID | CHAR | 12 | Manager approve | |
| 12 | APPROVED_AT | DATS | DATS | 8 | Ngày approve | |
| 13 | ATT_REPORT | ZDE_ATT_PATH | CHAR | 100 | File path Evidence 1 (Report) | |
| 14 | ATT_FIX | ZDE_ATT_PATH | CHAR | 100 | File path Evidence 2 (Fix) | |
| 15 | ATT_VERIFY | ZDE_ATT_PATH | CHAR | 100 | File path Evidence 3 (Verify) | |
| 16 | REASONS | ZDE_REASONS | STRG | - | Root cause / lý do | Unlimited |
| 17 | ERNAM | ERNAM | CHAR | 12 | Created by | Auto = SY-UNAME |
| 18 | ERDAT | ERDAT | DATS | 8 | Created date | Auto = SY-DATUM |
| 19 | ERZET | ERZET | TIMS | 6 | Created time | Auto = SY-UZEIT |
| 20 | AENAM | AENAM | CHAR | 12 | Last changed by | Auto on update |
| 21 | AEDAT | AEDAT | DATS | 8 | Last changed date | Auto on update |
| 22 | AEZET | AEZET | TIMS | 6 | Last changed time | Auto on update |
| 23 | SEVERITY | ZDE_SEVERITY | CHAR | 1 | 1=Dump,2=VHigh,3=High,4=Normal,5=Minor | Default '4' |
| 24 | CLOSED_AT | DATS | DATS | 8 | Ngày đóng bug | |
| 25 | IS_DEL | ZDE_IS_DEL | CHAR | 1 | Soft delete flag | 'X' = deleted |

### 2.2 Table: ZBUG_USERS (Account Management)

| # | Field | Data Element | Type | Length | Mô tả | Ghi chú |
|---|-------|-------------|------|--------|--------|---------|
| 1 | MANDT | MANDT | CLNT | 3 | Client | Key |
| 2 | USER_ID | ZDE_USERID | CHAR | 12 | SAP Username | Key |
| 3 | ROLE | ZDE_ROLE | CHAR | 1 | T/D/M | Mandatory |
| 4 | FULL_NAME | ZDE_FULLNAME | CHAR | 50 | Họ tên | |
| 5 | MODULE | ZDE_MODULE | CHAR | 20 | Module phụ trách | |
| 6 | AVAILABLE_STATUS | ZDE_AVAIL | CHAR | 1 | A=Available, B=Busy, L=Leave, W=Working | |
| 7 | IS_ACTIVE | ZDE_IS_ACTIVE | CHAR | 1 | X=Active | |
| 8 | EMAIL | ZDE_EMAIL | CHAR | 100 | Email address | |
| 9 | ERNAM | ERNAM | CHAR | 12 | Created by | |
| 10 | ERDAT | ERDAT | DATS | 8 | Created date | |
| 11 | ERZET | ERZET | TIMS | 6 | Created time | |
| 12 | AENAM | AENAM | CHAR | 12 | Last changed by | |
| 13 | AEDAT | AEDAT | DATS | 8 | Last changed date | |
| 14 | AEZET | AEZET | TIMS | 6 | Last changed time | |
| 15 | IS_DEL | ZDE_IS_DEL | CHAR | 1 | Soft delete flag | |

### 2.3 Table: ZBUG_HISTORY (Change Log)

| # | Field | Data Element | Type | Length | Mô tả | Ghi chú |
|---|-------|-------------|------|--------|--------|---------|
| 1 | MANDT | MANDT | CLNT | 3 | Client | Key |
| 2 | LOG_ID | ZDE_LOGID | NUMC | 10 | Log ID | Key, auto-gen |
| 3 | BUG_ID | ZDE_BUGID | CHAR | 10 | FK → ZBUG_TRACKER | |
| 4 | CHANGED_BY | ZDE_USERID | CHAR | 12 | Ai thay đổi | Auto = SY-UNAME |
| 5 | CHANGED_AT | DATS | DATS | 8 | Ngày thay đổi | Auto = SY-DATUM |
| 6 | CHANGED_TIME | TIMS | TIMS | 6 | Giờ thay đổi | Auto = SY-UZEIT |
| 7 | ACTION_TYPE | ZDE_ACTION | CHAR | 2 | CR/AS/RS/ST/UP/DL | Xem 2.5 |
| 8 | OLD_VALUE | CHAR50 | CHAR | 50 | Giá trị cũ | |
| 9 | NEW_VALUE | CHAR50 | CHAR | 50 | Giá trị mới | |
| 10 | REASON | ZDE_REASONS | STRG | - | Lý do thay đổi | |

### 2.4 Status Codes & Workflow (9 States — REQ-04 confirmed)

| Code | Status | Color (ALV) | Mô tả |
|------|--------|------------|--------|
| 1 | New | 🔵 Blue (C510) | Bug mới tạo, chưa assign |
| W | Waiting | 🟡 Yellow (C310) | Không tìm được Dev, chờ Manager assign |
| 2 | Assigned | 🟠 Orange (C710) | Đã gán cho Developer |
| 3 | InProgress | 🟣 Purple (C610) | Developer đang fix |
| 4 | Pending | 🔶 Orange-Light (C310) | Chờ phản hồi / bị block |
| 5 | Fixed | 🟢 Green (C510) | Dev đã fix, chờ Tester verify |
| 6 | Resolved | 🟩 Green-Light (C410) | Tester verify pass, chờ Manager close |
| 7 | Closed | ⚪ Grey (C110) | Đóng hoàn tất (terminal) |
| R | Rejected | 🔴 Red (C610) | Dev reject, cần reassign |

**Valid Status Transitions:**

| From | → Valid To | Ai thực hiện | Điều kiện |
|------|-----------|-------------|----------|
| 1 | 2, W | System/Manager | Auto-assign hoặc manual |
| W | 2 | Manager | Manual assign |
| 2 | 3, R | Developer | Start fix hoặc Reject |
| 3 | 5, 4 | Developer | Fix xong hoặc bị Pending |
| 4 | 3 | Developer | Resume sau pending |
| 5 | 6, 3 | Tester | Verify pass hoặc fail (back to dev) |
| 6 | 7 | Manager | Close bug |
| 7 | — | — | Terminal state (no transition) |
| R | 2 | Manager | Reassign cho dev khác |

**Workflow Diagram:**

```
                    ┌─────────────────────────────┐
                    │     TESTER tạo Bug          │
                    │     STATUS = 1 (New)        │
                    └─────────┬───────────────────┘
                              │
                    ┌─────────▼───────────────────┐
                    │     BUG_TYPE = ?             │
                    └─────┬───────────┬───────────┘
                          │           │
                    Code (C)    Config (F)
                          │           │
                          │     ┌─────▼───────────────┐
                          │     │ Tester tự fix       │
                          │     │ DEV_ID = Tester     │
                          │     │ STATUS = 2→3→5→6    │
                          │     └─────┬───────────────┘
                          │           │
                    ┌─────▼───────────────────┐   │
                    │ Auto-Assign chạy        │   │
                    │ Tìm Dev cùng Module     │   │
                    └─────┬──────────┬────────┘   │
                          │          │            │
                    Found Dev   No Dev Found      │
                          │          │            │
                    ┌─────▼────┐ ┌───▼──────┐    │
                    │STATUS = 2│ │STATUS = W │    │
                    │(Assigned)│ │(Waiting)  │    │
                    └─────┬────┘ └───┬───────┘    │
                          │          │            │
                          │    Manager assign     │
                          │    thủ công           │
                          │          │            │
                    ┌─────▼──────────▼────────┐   │
                    │ Dev nhận bug            │   │
                    │ STATUS = 3 (InProgress) │   │
                    └─────┬──────────┬────────┘   │
                          │          │            │
                    Fix OK    Reject              │
                          │          │            │
                    ┌─────▼────┐ ┌───▼──────┐    │
                    │STATUS = 5│ │STATUS = R│    │
                    │(Fixed)   │ │(Rejected)│    │
                    └─────┬────┘ └───┬───────┘    │
                          │          │            │
                          │    Manager reassign   │
                          │    → STATUS = 2       │
                          │                       │
                    ┌─────▼───────────────────┐   │
                    │ Tester Verify           │◄──┘
                    └─────┬──────────┬────────┘
                          │          │
                    Pass        Fail
                          │          │
                    ┌─────▼────┐ ┌───▼──────────┐
                    │STATUS = 6│ │STATUS = 3    │
                    │(Resolved)│ │(back to Dev) │
                    └─────┬────┘ └──────────────┘
                          │
                    ┌─────▼────┐
                    │STATUS = 7│
                    │(Closed)  │
                    └──────────┘
```

### 2.5 Action Types (ZBUG_HISTORY)

| Code | Action | Mô tả |
|------|--------|--------|
| CR | Create | Tạo bug mới |
| AS | Assign | Gán cho developer (auto hoặc manual) |
| RS | Reassign | Gán lại cho developer khác |
| ST | Status Change | Thay đổi status |
| UP | Update | Cập nhật thông tin bug |
| DL | Delete | Xoá bug (soft delete) |
| AT | Attachment | Upload/thay đổi evidence file |

### 2.6 Number Range Object: ZNRO_BUG

- Object: ZNRO_BUG
- Interval: 01
- From: 0000000001
- To: 9999999999
- Format output: `BUG` + NUMC(7) → BUG0000001

### 2.7 SAPScript Long Text (Text Object)

- Text Object: `ZBUG_NOTE` (tạo via SE75)
- Text Name: `{BUG_ID}` (e.g., BUG0000001)

| Text ID | Mô tả | Ai write | Khi nào |
|---------|--------|----------|---------|
| Z001 | Developer Note | Developer | Khi fix bug |
| Z002 | Tester Note | Tester | Khi report / verify |
| Z003 | Root Cause | Developer/Tester | Khi phân tích |

---

## 3. APPLICATION LAYER (Function Modules)

### 3.1 Z_BUG_CREATE

**Mục đích:** Tạo bug mới với auto-generate ID, auto-fill metadata

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_TITLE | Import | CHAR(100) | Tiêu đề |
| IV_DESC | Import | STRING | Mô tả chi tiết (→ Long Text Z002) |
| IV_MODULE | Import | CHAR(20) | SAP Module |
| IV_PRIORITY | Import | CHAR(1) | H/M/L |
| IV_BUG_TYPE | Import | CHAR(1) | C/F (default C) |
| IV_ATT_PATH | Import | CHAR(100) | File path evidence (optional) |
| IV_PROJECT_ID | Import | ZDE_PROJECT_ID | Project bug thuộc về |
| IV_SEVERITY | Import | ZDE_SEVERITY | 1-5, default '4' (Normal) |
| EV_BUG_ID | Export | CHAR(10) | Generated Bug ID |
| EV_SUCCESS | Export | CHAR(1) | X = success |
| EV_MESSAGE | Export | CHAR(200) | Message |

**Logic:**

1. Check permission (call Z_BUG_CHECK_PERMISSION action='CREATE')
2. Generate BUG_ID via NUMBER_GET_NEXT (ZNRO_BUG)
3. Fill TESTER_ID = SY-UNAME, ERNAM = SY-UNAME, ERDAT = SY-DATUM, ERZET = SY-UZEIT
4. If BUG_TYPE = 'F': DEV_ID = SY-UNAME, STATUS = '2'
5. If BUG_TYPE = 'C': STATUS = '1', DEV_ID = space
6. INSERT INTO ZBUG_TRACKER
7. Save Long Text (SAVE_TEXT) cho description → Text ID Z002
8. If ATT_PATH provided → store in ATT_REPORT
9. Call Z_BUG_LOG_HISTORY (action='CR')
10. If BUG_TYPE = 'C' → call Z_BUG_AUTO_ASSIGN
11. Call Z_BUG_SEND_EMAIL (notify relevant parties)
12. COMMIT WORK / ROLLBACK WORK

### 3.2 Z_BUG_AUTO_ASSIGN

**Mục đích:** Tự động gán bug cho developer có ít workload nhất trong cùng module

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID cần assign |
| EV_DEV_ID | Export | CHAR(12) | Developer được chọn |
| EV_SUCCESS | Export | CHAR(1) | X = success |
| EV_MESSAGE | Export | CHAR(200) | Message |

**Logic:**

1. SELECT MODULE FROM ZBUG_TRACKER WHERE BUG_ID = IV_BUG_ID
2. SELECT * FROM ZBUG_USERS WHERE MODULE = lv_module AND ROLE = 'D' AND AVAILABLE_STATUS = 'A' AND IS_ACTIVE = 'X' AND IS_DEL <> 'X'
3. Nếu không tìm được dev → STATUS = 'W' (Waiting), return message
4. Với mỗi dev, COUNT bugs WHERE DEV_ID = dev AND STATUS IN ('2','3') (assigned + inprogress)
5. Chọn dev có count nhỏ nhất
6. UPDATE ZBUG_TRACKER SET DEV_ID = dev, STATUS = '2'
7. UPDATE ZBUG_USERS SET AVAILABLE_STATUS = 'W' (Working) WHERE USER_ID = dev
8. Call Z_BUG_LOG_HISTORY (action='AS')
9. Call Z_BUG_SEND_EMAIL (notify dev)

### 3.3 Z_BUG_UPDATE_STATUS

**Mục đích:** Cập nhật status bug với validation workflow

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID |
| IV_NEW_STATUS | Import | CHAR(1) | Status mới |
| IV_REASON | Import | STRING | Lý do (optional) |
| IV_ATT_PATH | Import | CHAR(100) | File path evidence (optional) |
| EV_SUCCESS | Export | CHAR(1) | |
| EV_MESSAGE | Export | CHAR(200) | |

**Logic:**

1. Check permission (Z_BUG_CHECK_PERMISSION action='UPDATE_STATUS')
2. Validate status transition (xem 3.3.1)
3. UPDATE ZBUG_TRACKER SET STATUS, AENAM, AEDAT, AEZET
4. If STATUS → '7' (Closed) → SET CLOSED_AT = SY-DATUM, APPROVED_BY = SY-UNAME
5. If STATUS → '5' (Fixed) → store ATT_FIX
6. If STATUS → '6' (Resolved) → SET VERIFY_TESTER_ID = SY-UNAME, store ATT_VERIFY
7. Call Z_BUG_LOG_HISTORY (action='ST')
8. Call Z_BUG_SEND_EMAIL

**3.3.1 Valid Status Transitions (9 States — khớp Section 2.4):**

| From → To | Ai thực hiện | Điều kiện |
|-----------|-------------|-----------|
| 1 → 2 | System/Manager | Auto-assign hoặc manual assign |
| 1 → W | System | Không tìm được dev |
| W → 2 | Manager | Manual assign |
| 2 → 3 | Developer | Dev bắt đầu fix |
| 2 → R | Developer | Reject assignment |
| 3 → 5 | Developer | Dev hoàn thành fix, upload ATT_FIX |
| 3 → 4 | Developer | Bị block, chờ phản hồi (Pending) |
| 4 → 3 | Developer | Resume sau pending |
| 5 → 6 | Tester | Verify pass → Resolved |
| 5 → 3 | Tester | Verify fail, gửi lại dev |
| 6 → 7 | Manager | Close bug (terminal) |
| R → 2 | Manager | Reassign cho dev khác |
| (Config) 2 → 3 → 5 → 6 → 7 | Tester + Manager | Tester tự fix config bug |

### 3.4 Z_BUG_CHECK_PERMISSION

**Mục đích:** Kiểm tra quyền truy cập tập trung, 1 điểm duy nhất

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_ACTION | Import | CHAR(20) | Action cần check |
| IV_BUG_ID | Import | CHAR(10) | Bug ID (optional) |
| EV_ALLOWED | Export | CHAR(1) | X = allowed |
| EV_MESSAGE | Export | CHAR(200) | Lý do từ chối |

**Permission Matrix:**

| Action | Tester (T) | Developer (D) | Manager (M) |
|--------|-----------|---------------|-------------|
| CREATE | ✅ | ❌ | ✅ |
| UPDATE_STATUS | ✅ (own bugs + config) | ✅ (assigned bugs) | ✅ (all) |
| ASSIGN | ❌ | ❌ | ✅ |
| REASSIGN | ❌ | ✅ (reject own) | ✅ |
| DELETE | ❌ | ❌ | ✅ |
| UPLOAD_REPORT | ✅ (reporter only) | ❌ | ✅ |
| UPLOAD_FIX | ✅ (config + assigned) | ✅ (assigned) | ✅ |
| UPLOAD_VERIFY | ✅ (any tester) | ❌ | ✅ |
| VIEW_ALL | ❌ | ❌ | ✅ |
| MANAGE_USERS | ❌ | ❌ | ✅ |
| VIEW_DASHBOARD | ❌ | ❌ | ✅ |
| PRINT | ✅ | ✅ | ✅ |

**Special rules:**

- Config bug (BUG_TYPE='F'): Tester có quyền UPDATE_STATUS + UPLOAD_FIX nếu DEV_ID = SY-UNAME
- Developer chỉ thao tác trên bug assigned cho mình (DEV_ID = SY-UNAME)
- Tester chỉ thấy bug mình report (TESTER_ID = SY-UNAME) trừ khi verify

### 3.5 Z_BUG_LOG_HISTORY

**Mục đích:** Ghi log mọi thay đổi vào ZBUG_HISTORY

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID |
| IV_ACTION | Import | CHAR(2) | CR/AS/RS/ST/UP/DL/AT |
| IV_OLD_VALUE | Import | CHAR(50) | Giá trị cũ |
| IV_NEW_VALUE | Import | CHAR(50) | Giá trị mới |
| IV_REASON | Import | STRING | Lý do |

### 3.6 Z_BUG_SEND_EMAIL

**Mục đích:** Gửi email notification tự động

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID |
| IV_EVENT | Import | CHAR(20) | CREATE/ASSIGN/STATUS_CHANGE/REJECT |
| EV_SUCCESS | Export | CHAR(1) | |

**Logic:**

- Dùng **SmartForm** `ZBUG_EMAIL_FORM` để generate email body (HTML format)
- Gọi SmartForm → generate HTML document → pass to CL_BCS
- SMTP config via SCOT
- Email recipients tùy event:
  - CREATE → Dev team + Manager
  - ASSIGN → Assigned dev
  - STATUS_CHANGE → Tester + Dev
  - REJECT → Manager

### 3.7 Z_BUG_UPLOAD_ATTACHMENT

**Mục đích:** Upload evidence file (Excel ≤10MB)

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID |
| IV_ATT_TYPE | Import | CHAR(10) | REPORT/FIX/VERIFY |
| IV_FILE_PATH | Import | CHAR(100) | File path |
| EV_SUCCESS | Export | CHAR(1) | |

**Rules:**

- ATT_REPORT: Chỉ Tester report (TESTER_ID = SY-UNAME) mới upload
- ATT_FIX: Dev assigned (code bug) hoặc Tester assigned (config bug)
- ATT_VERIFY: Bất kỳ Tester nào
- Sau khi STATUS = '7' (Closed): KHÔNG được xoá attachment
- Max file size: 10MB
- Format: .xlsx

### 3.8 Z_BUG_REASSIGN

**Mục đích:** Gán lại bug cho developer khác

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| IV_BUG_ID | Import | CHAR(10) | Bug ID |
| IV_NEW_DEV_ID | Import | CHAR(12) | Developer mới |
| IV_REASON | Import | STRING | Lý do reassign |
| EV_SUCCESS | Export | CHAR(1) | |

### 3.9 Z_BUG_GET_STATISTICS

**Mục đích:** Lấy dữ liệu thống kê cho Dashboard

| Parameter | Direction | Type | Mô tả |
|-----------|-----------|------|--------|
| ET_BY_STATUS | Export | TABLE | Count bugs group by status |
| ET_BY_MODULE | Export | TABLE | Count bugs group by module |
| ET_BY_DEV | Export | TABLE | Count bugs group by developer |
| ET_BY_PRIORITY | Export | TABLE | Count bugs group by priority |
| EV_TOTAL | Export | INT4 | Tổng số bug |
| EV_OPEN | Export | INT4 | Bug đang mở (status <> '7') |
| EV_CLOSED | Export | INT4 | Bug đã đóng (status = '7') |

---

## 4. PRESENTATION LAYER - MODULE POOL

### 4.1 Program Structure

```
Z_BUG_WORKSPACE_MP (Type M - Module Pool)
├── Z_BUG_WS_TOP          → Global data declarations
├── Z_BUG_WS_PBO          → Process Before Output modules
├── Z_BUG_WS_PAI          → Process After Input modules
├── Z_BUG_WS_F00          → Class definitions, ALV setup, Event handler
├── Z_BUG_WS_F01          → Business logic FORM routines
└── Z_BUG_WS_F02          → Helper routines (F4, Long Text, GOS, Popup)
```

### 4.2 Transaction Codes

| T-Code | Screen | Mô tả | Target |
|--------|--------|--------|--------|
| ZBUG_WS | 0100 | Main Hub / Router | Screen 0100 |

> **Note:** Một T-code duy nhất ZBUG_WS là entry point. Tất cả navigation qua CALL SCREEN bên trong Module Pool.

### 4.3 Screen Flow

```
Screen 0100 (Main Hub / Router)
  │
  ├── [BUG_LIST] → Screen 0200 (Bug List - ALV Grid)
  │                   ├── [CREATE]  → Screen 0300 (Bug Detail - Create mode 'X')
  │                   ├── [CHANGE]  → Screen 0300 (Bug Detail - Change mode 'C')
  │                   ├── [DISPLAY] → Screen 0300 (Bug Detail - Display mode 'D')
  │                   ├── [DELETE]  → POPUP_TO_CONFIRM → Soft delete
  │                   ├── [PRINT]   → SmartForm ZBUG_FORM → PDF
  │                   └── [REFRESH] → Reload ALV data
  │
  ├── Screen 0300 (Bug Detail - Tab Strip)
  │     ├── Tab 0310: Bug Info Fields
  │     ├── Tab 0320: Developer Note (cl_gui_textedit)
  │     ├── Tab 0330: Tester/Functional Note (cl_gui_textedit)
  │     ├── Tab 0340: Root Cause Analysis (cl_gui_textedit)
  │     ├── Tab 0350: Evidence / GOS Files
  │     └── Tab 0360: History Log (ALV readonly + filter)
  │
  └── [PROJECT_LIST] → Screen 0400 (Project List - ALV Grid)
                          ├── [CREATE_PRO]    → Screen 0500 (Project Detail - Create)
                          ├── [CHANGE_PRO]    → Screen 0500 (Project Detail - Change)
                          ├── [DELETE_PRO]    → POPUP_TO_CONFIRM → Soft delete
                          ├── [UPLOAD]        → Excel upload
                          ├── [DOWNLOAD_TMPL] → Download template from SMW0
                          └── [REFRESH]       → Reload ALV data
```

### 4.4 Screen 0200 - Bug List (ALV Grid)

**Type:** Normal Screen
**PBO:** `MODULE pbo_0200`, `MODULE init_alv_0200`
**PAI:** `MODULE pai_0200`

**GUI Status: STATUS_0200**

| Button | FCode | Icon | Mô tả | Role |
|--------|-------|------|--------|------|
| Create | CREATE | ICON_CREATE | Tạo bug mới | T, M |
| Change | CHANGE | ICON_CHANGE | Sửa bug | T, D, M |
| Display | DISPLAY | ICON_DISPLAY | Xem bug | All |
| Delete | DELETE | ICON_DELETE | Xoá bug | M |
| Refresh | REFRESH | ICON_REFRESH | Reload data | All |
| Print | PRINT | ICON_PRINT | In SmartForm | All |
| Dashboard | DASHBOARD | ICON_OVERVIEW | Thống kê | M |
| User Mgt | USERMGT | ICON_EMPLOYEE | Quản lý user | M |
| Back | BACK | ICON_BACK | Thoát | All |

**ALV Grid Features:**

- cl_gui_alv_grid trong cl_gui_custom_container
- Field catalog (xem 4.4.1)
- Color-coded status (C_COLOR field)
- Hotspot trên BUG_ID (click → Display)
- Hotspot trên ATT_REPORT, ATT_FIX, ATT_VERIFY (click → Open file)
- Toolbar: Sort, Filter, Export Excel, Sum, Find
- Event handler class: LCL_EVENT_HANDLER
  - HANDLE_HOTSPOT_CLICK
  - HANDLE_TOOLBAR
  - HANDLE_USER_COMMAND

**4.4.1 Field Catalog cho Bug List ALV:**

| # | Fieldname | Coltext | Outputlen | Hotspot | No_out | Mô tả |
|---|-----------|---------|-----------|---------|--------|--------|
| 1 | BUG_ID | Bug ID | 12 | X | | Click → Display |
| 2 | TITLE | Title | 40 | | | |
| 3 | MODULE | Module | 10 | | | |
| 4 | PRIORITY_TEXT | Priority | 8 | | | H/M/L → High/Medium/Low |
| 5 | STATUS_TEXT | Status | 12 | | | Code → Text mapping |
| 6 | BUG_TYPE_TEXT | Type | 8 | | | C→Code, F→Config |
| 7 | TESTER_ID | Tester | 12 | | | |
| 8 | DEV_ID | Developer | 12 | | | |
| 9 | ERDAT | Created | 10 | | | |
| 10 | DEADLINE | Deadline | 10 | | | (nếu có) |
| 11 | ATT_REPORT | Evidence 1 | 10 | X | | Click → Open |
| 12 | ATT_FIX | Evidence 2 | 10 | X | | Click → Open |
| 13 | ATT_VERIFY | Evidence 3 | 10 | X | | Click → Open |
| 14 | C_COLOR | | | | X | Color field (hidden) |

**4.4.2 Data Filtering by Role (trong SELECT):**

- Tester: `WHERE TESTER_ID = SY-UNAME AND IS_DEL <> 'X'`
- Developer: `WHERE DEV_ID = SY-UNAME AND IS_DEL <> 'X'`
- Manager: `WHERE IS_DEL <> 'X'` (all bugs)

**4.4.3 Dynamic Toolbar by Role (PBO - EXCLUDING):**

- Tester: EXCLUDE → DELETE, USERMGT, DASHBOARD
- Developer: EXCLUDE → CREATE, DELETE, USERMGT, DASHBOARD
- Manager: (no exclusion - full access)

### 4.5 Screen 0300 - Bug Detail (Create / Change / Display)

**Type:** Normal Screen with Tab Strip
**PBO:** `MODULE pbo_0300`, `MODULE modify_screen_0300`, `MODULE create_editor`
**PAI:** `MODULE pai_0300`

**GUI Status: STATUS_0300**

| Button | FCode | Mô tả |
|--------|-------|--------|
| Save | SAVE | Lưu bug |
| Back | BACK | Quay lại list |
| Send Email | EMAIL | Gửi email thủ công |

**Tab Strip: TABSTRIP_BUG**

| Tab | FCode | SubScreen | Mô tả | Khi nào hiện |
|-----|-------|-----------|--------|-------------|
| Bug Info | TAB_INFO | 0310 | Thông tin bug | Always |
| Tester Note | TAB_TESTER | 0320 | Long text tester | Create, Change, Display |
| Dev Note | TAB_DEV | 0330 | Long text developer | Change, Display (only if assigned) |
| Root Cause | TAB_CAUSE | 0340 | Long text root cause | Change, Display |
| Evidence | TAB_EVID | 0350 | Upload/download files (GOS) | Always |
| History | TAB_HIST | 0360 | ALV history log | Change, Display |

**4.5.1 SubScreen 0310 - Bug Info Fields:**

| Field | Screen Element | Create (X) | Change (C) | Display (D) |
|-------|---------------|-----------|-----------|-------------|
| BUG_ID | GS_BUG-BUG_ID | Hidden (auto) | Readonly | Readonly |
| TITLE | GS_BUG-TITLE | Input | Input (T,M) / Readonly (D) | Readonly |
| MODULE | GS_BUG-MODULE | Input (dropdown) | Readonly | Readonly |
| PRIORITY | GS_BUG-PRIORITY | Input (dropdown) | Input (T,M) / Readonly (D) | Readonly |
| STATUS | GS_BUG-STATUS | Hidden (auto=1) | Input (theo role) | Readonly |
| BUG_TYPE | GS_BUG-BUG_TYPE | Input (dropdown) | Readonly | Readonly |
| TESTER_ID | GS_BUG-TESTER_ID | Readonly (auto) | Readonly | Readonly |
| DEV_ID | GS_BUG-DEV_ID | Hidden | Input (M only, F4) | Readonly |
| ERDAT | GS_BUG-ERDAT | Hidden | Readonly | Readonly |
| REASONS | GS_BUG-REASONS | Hidden | Input (D,M) | Readonly |

**4.5.2 Dynamic Screen Control (MODULE modify_screen_0300 OUTPUT):**

```abap
MODULE modify_screen_0300 OUTPUT.
  PERFORM get_user_role.  " lv_role = T/D/M

  LOOP AT SCREEN.
    " === Display mode: tất cả readonly ===
    IF gv_mode = 'D'.
      screen-input = 0.
    ENDIF.

    " === Create mode ===
    IF gv_mode = 'X'.
      IF screen-name = 'GS_BUG-BUG_ID'
        OR screen-name = 'GS_BUG-TESTER_ID'
        OR screen-name = 'GS_BUG-DEV_ID'
        OR screen-name = 'GS_BUG-STATUS'.
        screen-input = 0.   " auto-fill, không cho nhập
      ENDIF.
    ENDIF.

    " === Change mode: tuỳ role ===
    IF gv_mode = 'C'.
      " Developer: chỉ được đổi status + reasons
      IF lv_role = 'D'.
        IF screen-name <> 'GS_BUG-STATUS'
          AND screen-name <> 'GS_BUG-REASONS'.
          screen-input = 0.
        ENDIF.
      ENDIF.

      " Tester: đổi priority, title (nhưng không status nếu Code bug)
      IF lv_role = 'T'.
        IF screen-name = 'GS_BUG-DEV_ID'.
          screen-input = 0.  " Tester không assign dev
        ENDIF.
      ENDIF.

      " Bug đã Closed → tất cả readonly
      IF gs_bug-status = '7'.
        screen-input = 0.
      ENDIF.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.
```

**4.5.3 SubScreen 0320/0330/0340 - Long Text Editors:**

- Mỗi tab chứa 1 cl_gui_custom_container + cl_gui_textedit
- PBO: READ_TEXT → set_text_as_r3table
- PAI: get_text_as_r3table → SAVE_TEXT
- Readonly mode tuỳ role:
  - Tab Tester Note: Dev readonly, Tester input
  - Tab Dev Note: Tester readonly, Dev input
  - Tab Root Cause: cả hai input
  - Display mode: tất cả readonly

**4.5.4 SubScreen 0350 - Evidence (GOS Integration):**

- Sử dụng **GOS** (Generic Object Services) thay local file path
- `CL_GOS_DOCUMENT_SERVICE` hoặc BDS (`BDS_BUSINESSDOCUMENT_CREA_TAB`)
- File lưu trong SAP DB, truy cập qua object key (BUG_ID)
- GOS toolbar buttons: Upload, View, Delete
- Disable upload nếu STATUS = '7' (Closed)
- Permission-based: Tester upload BUGPROOF, Dev upload TESTCASE, Tester upload CONFIRM

**4.5.5 SubScreen 0360 - History Log:**

- ALV Grid hiển thị ZBUG_HISTORY WHERE BUG_ID = current
- Readonly, không edit
- Columns: Date, Time, User, Action, Old Value, New Value, Reason

### 4.6 Project Management (Screens 0400/0500)

> **Note:** Project management was added in Phase 3 (Module Pool Integration).
> Xem chi tiết implementation trong `docs/phases/phase-c-module-pool.md` (Bước C6-C7).

- **Screen 0400:** Project List (ALV Grid) — CRUD, Excel Upload/Download, role-based filter
- **Screen 0500:** Project Detail (Form + Table Control user-project)
- **Access:** Manager có full CRUD, Tester/Dev chỉ View projects mình thuộc

### 4.7 Dashboard / Statistics (Optional — nếu đủ thời gian)

**Type:** Hiển thị trên Screen 0100 (Main Hub) hoặc tách screen riêng
**Access:** Manager role only

**Content:**

- Summary statistics box (total, open, closed, waiting)
- ALV 1: Bug count by status (with bar chart nếu có thể)
- ALV 2: Bug count by module
- ALV 3: Bug count by developer (workload overview)
- ALV 4: Pending bugs (STATUS = 'W') → click to assign

### 4.8 F4 Search Help

| Field | F4 Source | Columns hiển thị |
|-------|----------|-----------------|
| MODULE | Hardcoded list hoặc custom table | Module code, Description |
| DEV_ID | ZBUG_USERS WHERE ROLE='D' AND IS_ACTIVE='X' | User ID, Full Name, Module, Available Status |
| TESTER_ID | ZBUG_USERS WHERE ROLE='T' AND IS_ACTIVE='X' | User ID, Full Name, Email |
| BUG_ID | ZBUG_TRACKER WHERE IS_DEL <> 'X' | Bug ID, Title, Status |
| PRIORITY | Domain fixed values | Code, Description |
| STATUS | Domain fixed values | Code, Description |

**Implementation:** Dùng `CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'` trong MODULE f4_xxx INPUT.

### 4.9 Confirmation Popups

| Action | Popup Message | Buttons |
|--------|-------------|---------|
| Delete Bug | "Bạn có chắc muốn xoá bug {BUG_ID}?" | Yes / No |
| Back khi chưa Save | "Dữ liệu chưa lưu. Bạn có muốn thoát?" | Yes / No |
| Reject Bug | "Bạn có chắc muốn reject bug này?" | Yes / No |
| Close Bug | "Xác nhận đóng bug {BUG_ID}?" | Yes / No |

**Implementation:** `CALL FUNCTION 'POPUP_TO_CONFIRM'`

---

## 5. SMARTFORM & REPORTING

### 5.1 SmartForm: ZBUG_FORM

- T-code: SMARTFORMS
- Nội dung: Bug detail report (PDF)
- Data: Bug info, history, notes
- Trigger: Button PRINT trên Screen 0200 (chọn bug → print)

### 5.2 ALV Export

- Built-in ALV toolbar cho Export to Excel
- Không cần custom Excel template upload/download (giữ đơn giản, vượt reference bằng feature khác)

---

## 6. EMAIL NOTIFICATION

### 6.1 Events trigger email

| Event | Recipients | Subject template |
|-------|-----------|-----------------|
| Bug Created | Dev team cùng module + Manager | "[ZBUG] New Bug: {BUG_ID} - {TITLE}" |
| Bug Assigned | Assigned developer | "[ZBUG] Assigned to you: {BUG_ID}" |
| Status Changed | Tester + Developer | "[ZBUG] Status Update: {BUG_ID} → {STATUS}" |
| Bug Rejected | Manager | "[ZBUG] Rejected: {BUG_ID} by {DEV_ID}" |
| Bug Closed | Tester + Developer | "[ZBUG] Closed: {BUG_ID}" |

### 6.2 Email Body

- Bug ID, Title, Status, Priority, Module
- Assigned Developer, Tester
- Link hoặc hướng dẫn mở T-code ZBUG_WS

---

## 7. SO SÁNH VỚI REFERENCE (ZPG_BUGTRACKING_*)

### 7.1 Những gì ZBUG_* đã vượt trội

| Feature | ZBUG_* | ZPG_* | Vượt trội |
|---------|--------|-------|-----------|
| Auto-Assign | ✅ Smart algorithm | ❌ Không có | ✅ |
| Permission System | ✅ Centralized FM | ❌ Scattered checks | ✅ |
| History Logging | ✅ Full audit trail | ❌ Không có | ✅ |
| Email Notification | ✅ CL_BCS | ❌ Không có | ✅ |
| SmartForm Print | ✅ PDF output | ❌ Không có | ✅ |
| Config Bug Workflow | ✅ Tester self-fix | ❌ Chỉ có severity | ✅ |
| FM Architecture | ✅ Reusable, testable | ❌ FORM routines | ✅ |

### 7.2 Những gì cần bổ sung từ reference

| Feature | Cần làm | Priority |
|---------|---------|----------|
| Module Pool UI | Chuyển từ Selection Screen → Dynpro | CRITICAL |
| Dynamic Screen Control | LOOP AT SCREEN / MODIFY SCREEN | CRITICAL |
| F4 Search Help | F4IF_INT_TABLE_VALUE_REQUEST | HIGH |
| Long Text (SAPScript) | READ_TEXT / SAVE_TEXT + cl_gui_textedit | HIGH |
| Audit Fields | ERNAM/ERDAT/ERZET/AENAM/AEDAT/AEZET | HIGH |
| Soft Delete | IS_DEL flag thay vì DELETE FROM | MEDIUM |
| Confirmation Popup | POPUP_TO_CONFIRM | MEDIUM |
| Tab Strip | Tab strip cho bug detail | MEDIUM |

### 7.3 Kết luận

Sau khi upgrade, hệ thống ZBUG_* sẽ:

1. **Có UI Module Pool chuyên nghiệp** (bằng hoặc hơn reference)
2. **Giữ nguyên FM architecture** (vượt reference)
3. **Có đầy đủ Long Text + Tab Strip** (bằng reference)
4. **Có Auto-Assign + Permission + History + Email(SmartForm) + SmartForm Print** (vượt xa reference)
5. **Có F4 Help + Audit Fields + Soft Delete + Confirm Popup** (bằng reference)
6. **Có Severity + Bug Type dual classification** (vượt reference)
7. **Có đa ngôn ngữ (Message Class ZBUG_MSG)** (vượt reference)
8. **Có GOS file storage** (thay DMS, không cần Content Server)
9. **Có Excel upload project** (bằng reference)
10. **Có History Tab với filter** (vượt reference — ZPG không có history)

→ Kết quả: Hệ thống **toàn diện hơn reference ở mọi khía cạnh**.

---

## 8. IMPLEMENTATION CHECKLIST (10 ngày: 24/03 → 03/04/2026)

### Phase A: Database Hardening (24-25/03)

- [ ] Thêm SEVERITY (CHAR 1) vào ZBUG_TRACKER
- [ ] Thêm audit fields (AENAM/AEDAT/AEZET) + IS_DEL vào ZBUG_TRACKER
- [ ] Thêm audit fields + IS_DEL vào ZBUG_USERS, Email = OBLIGATORY
- [ ] Tạo bảng ZBUG_PROJECT (16 fields)
- [ ] Tạo bảng ZBUG_USER_PROJECT (8 fields)
- [ ] Thêm PROJECT_ID vào ZBUG_TRACKER
- [ ] Tạo Message Class ZBUG_MSG (SE91) — skeleton EN
- [ ] Tạo Text Object ZBUG_NOTE (SE75) với Text ID Z001, Z002, Z003

### Phase B: Business Logic Update (25-27/03)

- [ ] Mở rộng Z_BUG_CHECK_PERMISSION (Project actions + user-project check)
- [ ] Update Z_BUG_CREATE (PROJECT_ID, SEVERITY, user validation)
- [ ] Chuẩn hóa 9 status states + transition validation
- [ ] GOS file storage integration (CL_GOS_DOCUMENT_SERVICE / BDS)
- [ ] SmartForm ZBUG_EMAIL_FORM (email body template)
- [ ] Update Z_BUG_SEND_EMAIL (SmartForm → CL_BCS)
- [ ] Severity + Bug Type dual validation logic
- [ ] Update soft delete logic trong tất cả FMs

### Phase C: Module Pool UI (27-31/03)

- [ ] Tạo program Z_BUG_WORKSPACE_MP (Type M) + 6 includes
- [ ] Screen 0200: Bug List (ALV Grid + toolbar + role-based excluding)
- [ ] Screen 0300: Bug Detail (Tab Strip: Info/Notes/Evidence/History)
- [ ] Screen 0400: Project List (ALV Grid)
- [ ] Screen 0500: Project Detail (fields + user table control)
- [ ] GUI Statuses: STATUS_0200, STATUS_0300, STATUS_0400, STATUS_0500
- [ ] Dynamic screen control (LOOP AT SCREEN / MODIFY SCREEN)
- [ ] Tab Strip + Long Text (cl_gui_textedit + READ_TEXT/SAVE_TEXT)
- [ ] F4 Search Help (Project, Developer, Tester, Module, Severity)
- [ ] GOS integration on Bug Detail screen
- [ ] History Tab (ALV readonly + filter Action Type/Date)
- [ ] Refresh button trên tất cả ALV screens
- [ ] POPUP_TO_CONFIRM cho delete/back/reject/close
- [ ] ALV color-coding status + hotspot BUG_ID
- [ ] Role-based data filtering (Tester/Dev/Manager)

### Phase D: Excel & Advanced Features (31/03-01/04)

- [ ] Tạo Excel template ZTEMPLATE_PROJECT trên SMW0
- [ ] Download Template button trên GUI Status
- [ ] Upload logic: TEXT_CONVERT_XLS_TO_SAP + validation
- [ ] Message Class migration: tất cả messages → ZBUG_MSG (EN + VI)
- [ ] Dashboard statistics (Manager only, optional)

### Phase E: Testing & Go-Live (02-03/04)

- [ ] Update T-Code ZBUG_WS → Z_BUG_WORKSPACE_MP Screen 0100
- [ ] Unit test FMs trong SE37 (permission, create, status, GOS)
- [ ] Integration test: Create → Assign → Fix → Verify → Close
- [ ] Test Config bug workflow (Tester self-fix)
- [ ] Test permission matrix (Tester/Developer/Manager)
- [ ] Test Severity + Bug Type dual classification
- [ ] Test GOS file upload/view
- [ ] Test SmartForm email (check SOST)
- [ ] Test đa ngôn ngữ (login EN vs VI)
- [ ] Test Excel upload project
- [ ] Test History tab + filter
- [ ] Test soft delete + popup confirm
- [ ] Clean test data + rehearse demo
- [ ] 🎯 DEMO DAY (03/04/2026)
