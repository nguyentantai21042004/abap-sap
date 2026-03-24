# 🎯 MILESTONES & TIMELINE

> **Tổng thời gian:** 10 ngày (24/03 – 03/04/2026)  
> **Demo Day:** 03/04/2026

---

## Timeline tổng quan

```
24/03    25/03    26/03    27/03    28/03    29/03    30/03    31/03    01/04    02/04    03/04
 T2       T3       T4       T5       T6       T7       CN       T2       T3       T4       T5
├────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┼────────┤
│Phase A:│Phase B:│Phase B │Phase C:│Phase C │Phase C │Phase C │Ph.C+D: │Phase D │Phase E │ DEMO │
│Database│Logic   │Logic   │MP UI   │MP UI   │MP UI   │MP UI   │Excel   │MsgClass│Testing │ DAY  │
│1 ngày  │        │2 ngày  │        │        │        │4 ngày  │        │1.5 ngày│1.5 ngày│      │
└────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┴────────┘
```

---

## Milestones chi tiết

### 🔵 M1: Database Ready (25/03 EOD)

| Deliverable | Criteria |
|-------------|----------|
| ZBUG_PROJECT table | Active trong SE11, có test data |
| ZBUG_USER_PROJECT table | Active, linked test data |
| ZBUG_TRACKER updated | PROJECT_ID + SEVERITY fields added |
| ZBUG_USERS updated | Audit fields + IS_DEL added, EMAIL = OBLIGATORY |
| Message Class ZBUG_MSG | Created trong SE91 (skeleton, EN messages) |

### 🟡 M2: Business Logic Complete (27/03 EOD)

| Deliverable | Criteria |
|-------------|----------|
| Z_BUG_CHECK_PERMISSION | Project permissions + user-project membership check |
| Z_BUG_CREATE | PROJECT_ID + SEVERITY + user validation working |
| Z_BUG_UPDATE_STATUS | 9 status states, transition validation updated |
| GOS integration | Upload file via GOS API working (SE37 test) |
| Z_BUG_SEND_EMAIL | SmartForm ZBUG_EMAIL_FORM generating HTML body |
| Status transition | Valid/invalid transitions tested trong SE37 |

### 🟠 M3: Module Pool Core (29/03 EOD)

| Deliverable | Criteria |
|-------------|----------|
| Module Pool program | Z_BUG_WORKSPACE_MP created with all includes |
| Screen 0200 (Bug List) | ALV grid hiển thị, toolbar buttons hoạt động |
| Screen 0300 (Bug Detail) | Tab strip, dynamic screen control cơ bản |
| Screen 0400 (Project List) | ALV project management working |
| GUI Statuses | Tạo xong cho all screens |
| Role-based toolbar | EXCLUDING buttons theo role |

### 🟢 M4: Module Pool Full Features (31/03 EOD)

| Deliverable | Criteria |
|-------------|----------|
| Screen 0500 (Project Detail) | Fields + user list table control |
| F4 Search Help | Hoạt động cho Project, Dev, Tester |
| Long Text editors | Tab strip + SAPScript tích hợp (3 notes) |
| GOS on screen | Upload/view file từ Bug Detail screen |
| History tab | ALV readonly + filter Action Type/Date |
| Refresh button | Hoạt động trên tất cả ALV screens |
| Popup confirms | Delete, Back unsaved, Reject, Close |
| Soft delete | IS_DEL flag cho Bug + Project |

### 🔴 M5: Advanced Features (01/04 EOD)

| Deliverable | Criteria |
|-------------|----------|
| Excel template | ZTEMPLATE_PROJECT trên SMW0 |
| Excel upload | Upload → validate → insert project working |
| Download template | Button trên GUI Status working |
| Message Class migration | Tất cả messages dùng ZBUG_MSG |
| Đa ngôn ngữ test | Login EN → English messages, Login VI → Vietnamese |
| Dashboard (optional) | Manager-only statistics screen |

### ⭐ M6: Release Ready (02/04 EOD)

| Deliverable | Criteria |
|-------------|----------|
| T-code ZBUG_HOME | Mở → Module Pool screen (not Selection Screen) |
| 14 test cases pass | TC-01 → TC-14 pass |
| Email working | SOST verify, SmartForm body |
| Demo script | Chuẩn bị xong, rehearsed |
| Fallback plan | Z_BUG_WORKSPACE backup nếu Module Pool lỗi |
| Clean test data | Data ready cho demo |

### 🎯 M7: Demo Day (03/04)

| Nội dung | Chi tiết |
|----------|---------|
| **Live demo flow** | PM tạo project → Upload users từ Excel → Tester tạo bug (F4, Severity) → Auto-Assign → Dev fix (Long Text note) → Upload evidence (GOS) → Tester verify → Close |
| **Highlight features** | Module Pool UI, Auto-Assign, Permission FM, History Tab, SmartForm Email, Đa ngôn ngữ (EN↔VI switch live) |
| **Technical Q&A** | FM architecture, GOS vs DMS decision, Status state machine, Message Class benefits |

---

## Phân bổ thời gian chi tiết

| Ngày | Buổi sáng (4h) | Buổi chiều (4h) |
|------|----------------|-----------------|
| **24/03 (T2)** | A1-A3: Tạo bảng ZBUG_PROJECT, ZBUG_USER_PROJECT | A4-A6: Update ZBUG_TRACKER, Message Class skeleton |
| **25/03 (T3)** | B1-B2: Permission FM + Create FM update | B3: Status refactoring + transition validation |
| **26/03 (T4)** | B4-B5: GOS integration + User validation | B6-B7: SmartForm email + Severity validation |
| **27/03 (T5)** | C1-C2: Module Pool program + Screen 0200 design | C2: Screen 0300 design + ALV setup |
| **28/03 (T6)** | C3: GUI Statuses + C4: Dynamic screen control | C4: Complete screen control + Screen 0400 |
| **29/03 (T7)** | C5: Tab Strip + Long Text integration | C6: F4 Search Help |
| **30/03 (CN)** | C7: GOS on screen + C8: History tab | C9-C10: Refresh + Popup confirms |
| **31/03 (T2)** | D1: Excel template + upload logic | C: Bug fixes + polish Module Pool |
| **01/04 (T3)** | D2: Message Class migration (EN/VI) | D3: Dashboard (optional) + final polish |
| **02/04 (T4)** | E1-E2: T-code update + Test cases TC-01→TC-07 | E2-E3: Test cases TC-08→TC-14 + UAT prep |
| **03/04 (T5)** | E4: Clean data + rehearse demo | **🎯 DEMO DAY** |

---

## Rủi ro & Contingency

| Rủi ro | Nếu xảy ra | Contingency |
|--------|-----------|-------------|
| Module Pool UI phức tạp hơn dự kiến | Dùng lại Z_BUG_WORKSPACE (Selection Screen) | Giữ backup, chuyển nhanh nếu cần |
| GOS API khó tích hợp | Tạm dùng custom binary table | XSTRING storage → migrate GOS sau |
| SmartForm email mất thời gian design | Dùng plain text CL_BCS | Upgrade SmartForm post-demo |
| Message Class migration nhiều message | Migrate critical messages trước | Còn lại hardcode, fix sau |
| Excel upload validation phức tạp | Chỉ upload basic fields | Validation nâng cao phase sau |
| Dashboard không kịp | Bỏ qua cho demo | Dashboard = nice-to-have |
