# CONTEXT & STATUS — Z_BUG_WORKSPACE_MP

> **Cập nhật lần cuối:** 16/04/2026 (repo restructured — professional layout)
> **Mục đích:** File này dùng để handoff giữa các agent/session. Đọc file này trước khi làm bất cứ thứ gì với dự án.

---

## 1. DỰ ÁN LÀ GÌ?

Hệ thống **Bug Tracking tập trung** chạy trên SAP ERP bằng ABAP thuần túy.

- **SAP System:** S40, Client 324, **ABAP 7.70** (SAP_BASIS 770 — inline declarations, SWITCH, CONV, string templates, @ host vars)
- **Package:** `ZBUGTRACK`
- **T-code entry point:** `ZBUG_WS` → Screen **0410** (Project Search) → Screen **0400** (Project List)

Dự án đang ở **Phase F v5.0: Enhancement** — planning documents hoàn thành, chuẩn bị viết CODE v5.0.

### v5.0 — Thay đổi lớn so với v4.2:

| # | Thay đổi | Loại | Status |
|---|---------|------|--------|
| 1 | **10-state lifecycle** (breaking: `6`=Final Testing, `V`=Resolved) | BREAKING CHANGE | ✅ Designed |
| 2 | **Status Transition Popup** (Screen 0370) thay POPUP_GET_VALUES | New Feature | ✅ Designed |
| 3 | **Matrix Logic** — role-based transition rules, Manager không bypass | New Feature | ✅ Designed |
| 4 | **Auto-Assign** — auto-assign Developer (Phase A) + Tester (Phase B) | New Feature | ✅ Designed |
| 5 | **Project Search** (Screen 0410) — new initial screen | New Feature | ✅ Designed |
| 6 | **Dashboard Header** trên Screen 0200 — metrics by status/priority/module | New Feature | ✅ Designed |
| 7 | **Bug Search Engine** (Screen 0210 popup + Screen 0220 results) | New Feature | ✅ Designed |
| 8 | **Template Rename** (SMW0) — Bug_report, fix_report, confirm_report | Enhancement | ✅ Designed |
| 9 | **11 Bug Fixes** từ UAT round 1 | Bug Fix | ✅ Analyzed |
| 10 | **Test Data Population** — 30 mock users for auto-assign testing | Testing | ✅ Designed |

### v4.0 — 10 tính năng (all COMPLETE):

| # | Tính năng | Status |
|---|-----------|--------|
| 1 | Evidence/Attachment upload (ZBUG_EVIDENCE) | ✅ |
| 2 | Send Email qua BCS API | ✅ |
| 3 | File naming enforcement | ✅ |
| 4 | F4 Calendar popup | ✅ |
| 5 | Unsaved changes detection | ✅ |
| 6 | Role-based field access (FNC group) | ✅ |
| 7 | Multiple template downloads | ✅ |
| 8 | Bug type vs Priority validation | ✅ |
| 9 | Project completion validation | ✅ |
| 10 | Auto-open file after download | ✅ |

---

## 2. CHƯƠNG TRÌNH MẪU THAM CHIẾU

> Thư mục `references/` đã bị xoá — không còn cần thiết.
> `Z_BUG_WORKSPACE_MP` đã **vượt xa** cả 2 chương trình mẫu (ZPG_BUGTRACKING_MAIN / DETAIL). ✅ v4.0 đạt, v5.0 vượt xa.

---

## 3. KIẾN TRÚC MỤC TIÊU (v5.0)

```
Program: Z_BUG_WORKSPACE_MP (Module Pool, Type M)
│
├── Include: Z_BUG_WS_TOP   → Global declarations, types, ALV objects
├── Include: Z_BUG_WS_F00   → ALV field catalog + LCL_EVENT_HANDLER class
├── Include: Z_BUG_WS_PBO   → Process Before Output modules
├── Include: Z_BUG_WS_PAI   → Process After Input modules (user commands)
├── Include: Z_BUG_WS_F01   → Business logic FORMs
└── Include: Z_BUG_WS_F02   → Helpers: F4, Long Text, Popup, Download Template
│
├── Screen 0100  → ~~Hub / Router~~ **DEPRECATED**
├── Screen 0200  → Bug List (ALV Grid + Dashboard Header, dual mode)
├── Screen 0210  → **v5.0 NEW** — Bug Search Input (Modal Dialog popup)
├── Screen 0220  → **v5.0 NEW** — Bug Search Results (Full screen ALV, no dashboard)
├── Screen 0300  → Bug Detail (Tab Strip, 6 subscreens)
│   ├── Subscreen 0310  → Tab: Bug Info (fields + CC_DESC_MINI)
│   ├── Subscreen 0320  → Tab: Description (Long Text Z001, CC_DESC)
│   ├── Subscreen 0330  → Tab: Dev Note (Long Text Z002, CC_DEVNOTE)
│   ├── Subscreen 0340  → Tab: Tester Note (Long Text Z003, CC_TSTRNOTE)
│   ├── Subscreen 0350  → Tab: Evidence (Evidence ALV, CC_EVIDENCE)
│   └── Subscreen 0360  → Tab: History (ALV readonly, CC_HISTORY)
├── Screen 0370  → **v5.0 NEW** — Status Transition Popup (Modal Dialog)
├── Screen 0400  → Project List (ALV Grid, CC_PROJECT_LIST)
├── Screen 0410  → **v5.0 NEW** — Project Search (**NEW INITIAL SCREEN**)
└── Screen 0500  → Project Detail + User Assignment (TC_USERS)
```

### Navigation Flow (v5.0):

```
ZBUG_WS → Screen 0410 (Project Search, initial — NEW)
  └── Execute → Screen 0400 (Project List, filtered)
        ├── Click Project → Screen 0200 (ALL bugs + Dashboard, gv_bug_filter_mode='P')
        │     ├── Create/Change/Display → Screen 0300
        │     │     └── Change Status → Screen 0370 (popup — NEW)
        │     ├── Search Bug → Screen 0210 (popup — NEW)
        │     │     └── Execute → Screen 0220 (results, no dashboard — NEW)
        │     ├── DN_TC/DN_CONF/DN_PROOF → Download templates
        │     └── Back → Screen 0400
        ├── [My Bugs] → Screen 0200 (bugs by role, CREATE hidden)
        │     └── Back → Screen 0400
        ├── Create/Change/Display Project → Screen 0500
        └── Back → Screen 0410

Screen 0410 → Back → LEAVE PROGRAM
```

### Custom Control Container Names (v5.0):

| Screen | Container Name | Purpose |
|--------|---------------|---------|
| 0200 | `CC_BUG_LIST` | Bug ALV Grid |
| 0220 | `CC_SEARCH_RESULTS` | **v5.0 NEW** — Search Results ALV |
| 0310 | `CC_DESC_MINI` | Mini text editor |
| 0320 | `CC_DESC` | Full description editor |
| 0330 | **`CC_DEVNOTE`** | Dev Note editor (NO underscore!) |
| 0340 | **`CC_TSTRNOTE`** | Tester Note editor (NO underscore!) |
| 0350 | `CC_EVIDENCE` | Evidence ALV |
| 0360 | `CC_HISTORY` | History ALV |
| 0370 | `CC_TRANS_NOTE` | **v5.0 NEW** — Transition Note editor |
| 0400 | `CC_PROJECT_LIST` | Project ALV Grid |

### Screen Groups (v5.0):

| Group | Purpose |
|-------|---------|
| `EDT` | Editable fields — disabled in Display mode |
| `BID` | BUG_ID — locked after creation |
| `PRJ` | PROJECT_ID — locked when creating from project context |
| `TST` | Tester-specific fields |
| `DEV` | Developer-specific fields |
| `FNC` | Functional fields (BUG_TYPE, PRIORITY, SEVERITY) — Dev cannot edit |
| `STS` | **v5.0 NEW** — STATUS field — always locked (change via popup only) |

### Fcode Naming (v5.0):

| Screen | Key Fcodes |
|--------|-----------|
| 0410 | **v5.0 NEW** — `EXECUTE`, `BACK`, `EXIT`, `CANCEL` |
| 0400 | `CREA_PRJ`, `CHNG_PRJ`, `DISP_PRJ`, `DEL_PRJ`, `MY_BUGS`, `DN_TMPL`, `UPLOAD`, `REFRESH` |
| 0200 | `CREATE`, `CHANGE`, `DISPLAY`, `DELETE`, `REFRESH`, `DN_TC`, `DN_CONF`, `DN_PROOF`, **`SEARCH`** |
| 0210 | **v5.0 NEW** — `EXECUTE`, `CANCEL` |
| 0220 | **v5.0 NEW** — `BACK`, `EXIT`, `CANCEL` |
| 0300 | `SAVE`, `STATUS_CHG`, `UP_FILE`, `UP_REP`, `UP_FIX`, `DL_EVD`, `SENDMAIL`, `TAB_*` |
| 0370 | **v5.0 NEW** — `CONFIRM`, `CANCEL`, `UP_TRANS` |
| 0500 | `SAVE`, `ADD_USER`, `REMO_USR` |

### GUI Statuses (v5.0):

| Status Name | Screen | Changes |
|-------------|--------|---------|
| `STATUS_0410` | 0410 | **v5.0 NEW** |
| `STATUS_0400` | 0400 | Unchanged |
| `STATUS_0200` | 0200 | **+SEARCH button** |
| `STATUS_0210` | 0210 | **v5.0 NEW** |
| `STATUS_0220` | 0220 | **v5.0 NEW** |
| `STATUS_0300` | 0300 | Unchanged |
| `STATUS_0370` | 0370 | **v5.0 NEW** |
| `STATUS_0500` | 0500 | Unchanged |

### Title Bars (v5.0):

| Title | Text | New? |
|-------|------|------|
| `T_0410` | Project Search | **v5.0 NEW** |
| `T_0370` | Change Bug Status | **v5.0 NEW** |
| `T_0210` | Bug Search | **v5.0 NEW** |
| `T_0220` | Search Results | **v5.0 NEW** |

---

## 4. DATABASE TABLES

| Table | Status | Fields | Source of Truth |
|-------|--------|--------|-----------------|
| `ZBUG_TRACKER` | Updated (+13 fields) | 29 fields total | `database/table-fields.md` |
| `ZBUG_USERS` | Updated (+4 fields) | 12 fields total | `database/table-fields.md` |
| `ZBUG_PROJECT` | Created | 16 fields | `database/table-fields.md` |
| `ZBUG_USER_PROJEC` | Created | 10 fields (M:N User↔Project, có ROLE) | `database/table-fields.md` |
| `ZBUG_HISTORY` | Unchanged | 10 fields (Change log) | `database/table-fields.md` |
| `ZBUG_EVIDENCE` | v4.0 | 11 fields (binary file storage) | `database/zbug-evidence.md` |

### Critical Type Mappings (from SE11 verification):

| Field | Type | Note |
|-------|------|------|
| `ZBUG_TRACKER.STATUS` | `zde_bug_status` = **CHAR 20** | NOT CHAR 1 |
| `ZBUG_TRACKER.SAP_MODULE` | `zde_sap_module` = **CHAR 20** | NOT CHAR 10 |
| `ZBUG_TRACKER.DESC_TEXT` | **STRING** | CANNOT place on screen layout |
| `ZBUG_HISTORY.REASON` | **STRING** | NOT CHAR 255 |
| `ZBUG_EVIDENCE.CONTENT` | **RAWSTRING** | Binary file storage |

### ⚠️ CRITICAL: ZBUG_TRACKER does NOT have DEADLINE or START_DATE fields

### 10-State Bug Lifecycle (v5.0):

```
New(1) → Auto-assign → Assigned(2) → InProgress(3) → Fixed(5) → Auto-assign → FinalTesting(6) → Resolved(V)
                  ↘ Waiting(W) [no Dev]                                   ↘ Waiting(W) [no Tester]
                                        ↘ Pending(4) → Assigned(2)
                                        ↘ Rejected(R)
                                                                    FinalTesting(6) ↗ Resolved(V) ← TERMINAL
                                                                                    ↘ InProgress(3) [fail]
                                                                    Closed(7) ← LEGACY
```

**BREAKING CHANGE v4.x → v5.0:**

| Trước (v4.x) | Sau (v5.0) | Impact |
|---------------|-----------|--------|
| `6` = Resolved | `6` = **Final Testing** | Ý nghĩa hoàn toàn khác |
| Không có | `V` = Resolved | Trạng thái kết thúc mới |
| `gc_st_resolved = '6'` | `gc_st_resolved = 'V'`, `gc_st_finaltesting = '6'` | Update ALL status references |
| Manager bypass transitions | Manager tuân theo matrix | Bug 10+11 fix |

> **Source of truth cho lifecycle:** `docs/status-lifecycle.md`

### Evidence Rules (v5.0):

| Chuyển sang | Điều kiện |
|-------------|-----------|
| Fixed (5) | Evidence file bất kỳ trong ZBUG_EVIDENCE (COUNT > 0) |
| Final Testing (6) | Tự động (auto-assign Tester) |
| Resolved (V) | TRANS_NOTE bắt buộc |

---

## 5. TRẠNG THÁI TRIỂN KHAI (13/04/2026)

### PHASE A — DATABASE HARDENING ✅ DONE

| Bước | Nội dung | Status |
|------|---------|--------|
| A1-A8 | Domains, Data Elements, Tables, Migration | ✅ Xong |
| A9 | Bảng `ZBUG_EVIDENCE` (11 fields) | ❌ Chưa tạo (guide: `database/zbug-evidence.md`) |

### PHASE B — BUSINESS LOGIC UPDATE ❓ CHƯA XÁC NHẬN

| Bước | Nội dung | Status |
|------|---------|--------|
| B1-B9 | Function Modules update | ❓ Chưa xác nhận |

### PHASE C+D — MODULE POOL UI + ADVANCED FEATURES ✅ CODE v4.2 COMPLETE

All 6 CODE files v4.2 COMPLETE + all UI guides UPDATED. Deployed to SAP.

### PHASE E — TESTING

| Bước | Nội dung | Status |
|------|---------|--------|
| E1 | UAT Happy Case (43 cases) | ✅ Created |
| E2 | QC Test Plan (~140 cases) | ✅ Created |
| E3 | UAT Round 1 → 11 bugs found | ✅ Analyzed → `docs/v5-bug-analysis.md` |

### PHASE F — v5.0 ENHANCEMENT ⏳ IN PROGRESS (DOCUMENTATION COMPLETE)

| Bước | Nội dung | Status |
|------|---------|--------|
| F0 | Bug Fixes (11 bugs from UAT) | ✅ Analyzed, fix proposals ready |
| F1 | Status Lifecycle v5.0 (breaking change) | ✅ Designed → `docs/status-lifecycle.md` |
| F2 | Screen 0410 — Project Search | ✅ Designed → `docs/phase-f-v5-enhancement.md` |
| F3 | Dashboard Header (Screen 0200) | ✅ Designed |
| F4 | Template Rename (SMW0) | ✅ Designed |
| F5 | Status Transition Popup (Screen 0370) | ✅ Designed |
| F6 | Matrix Logic — Transition Rules | ✅ Designed |
| F7 | Auto-Assign System | ✅ Designed |
| F8 | Test Data Population | ✅ Designed |
| F9 | Bug Search Engine (Screen 0210/0220) | ✅ Designed |
| F10 | **Write CODE v5.0 files** | ❌ **NEXT STEP** |
| F11 | Create new screens in SE51 | ❌ Chưa làm |
| F12 | Create new GUI Statuses + Title Bars in SE41 | ❌ Chưa làm |
| F13 | Update SE93 (initial screen 0400 → 0410) | ❌ Chưa làm |
| F14 | Full regression + UAT round 2 | ❌ Chưa làm |

---

## 6. UX DECISIONS ĐÃ CHỐT

**Từ v4.0 (giữ nguyên):**
1. Bug bắt buộc thuộc 1 Project
2. ~~Screen 0400 là initial screen~~ → **v5.0: Screen 0410 là initial screen**
3. Click Project → thấy ALL bugs
4. Nút "My Bugs" trên Project List toolbar
5. Create Bug chỉ khi có project context
6. PROJECT_ID pre-fill + locked
7. Screen 0100 deprecated
8. Description mini editor (CC_DESC_MINI) trên Bug Info tab
9. Orphan bugs cleanup → project "LEGACY"
10. Evidence: tự viết (ZBUG_EVIDENCE)
11. Email: BCS API trực tiếp

**Mới từ v5.0:**
12. **Status field LOCKED** — thay đổi chỉ qua popup Screen 0370
13. **Manager không bypass** transition rules — phải theo matrix
14. **Auto-assign** Developer (New→Assigned) và Tester (Fixed→FinalTesting)
15. **Screen 0370** cho Status Transition (KHÔNG dùng 0350 — đó là Evidence subscreen)
16. **Dashboard Header** trên Screen 0200 — real-time metrics
17. **Bug Search** — popup 0210 (input) + full screen 0220 (results, không dashboard)
18. **Template rename** — Bug_report.xlsx, fix_report.xlsx, confirm_report.xlsx

---

## 7. CODE & UI GUIDES — VỊ TRÍ & CÁCH DÙNG

> **Repo structure (v5.0 — restructured 16/04/2026):**
> ```
> abap-sap/
> ├── README.md
> ├── src/            ← ABAP source code (6 includes)
> ├── screens/        ← SE51 screen layout guides (8 screens)
> ├── database/       ← DB table schemas (table-fields.md, zbug-evidence.md)
> ├── docs/           ← Project documentation + deployment guide
> │   ├── CONTEXT.md          ← THIS FILE
> │   ├── status-lifecycle.md ← v5.0 lifecycle source of truth
> │   ├── v5-bug-analysis.md  ← 11 bugs analysis
> │   ├── requirements.md
> │   ├── legacy-removal-guide.md
> │   └── phase-f-v5-enhancement.md
> ├── tests/          ← QC test plans + UAT cases
> └── verification/   ← Screenshots as proof of current state
>     └── screenshots/
> ```

### Code Files (v4.2 — cần upgrade lên v5.0):

| File guide | SAP include | Current | Target |
|-----------|------------|---------|--------|
| `src/CODE_TOP.md` | `Z_BUG_WS_TOP` | v4.0 | **v5.0** |
| `src/CODE_F00.md` | `Z_BUG_WS_F00` | v4.0 | **v5.0** |
| `src/CODE_PBO.md` | `Z_BUG_WS_PBO` | v4.1 | **v5.0** |
| `src/CODE_PAI.md` | `Z_BUG_WS_PAI` | v4.1 | **v5.0** |
| `src/CODE_F01.md` | `Z_BUG_WS_F01` | v4.2 | **v5.0** |
| `src/CODE_F02.md` | `Z_BUG_WS_F02` | v4.1 | **v5.0** |

### Key Planning Documents:

| File | Purpose | Version |
|------|---------|---------|
| **`docs/status-lifecycle.md`** | Bug + Project lifecycle, role matrix, transition table, auto-assign | **v5.0** |
| **`docs/v5-bug-analysis.md`** | 11 bugs from UAT with root causes and fix proposals | **v5.0** |
| **`docs/phase-f-v5-enhancement.md`** | Phase F implementation guide (all 10 steps) | **v5.0** |

> **Thứ tự include bắt buộc trong main program:**
>
> ```abap
> PROGRAM z_bug_workspace_mp.
> INCLUDE z_bug_ws_top.    " 1. Global data
> INCLUDE z_bug_ws_f00.    " 2. Event class (PHẢI trước PBO/PAI)
> INCLUDE z_bug_ws_pbo.    " 3. PBO
> INCLUDE z_bug_ws_pai.    " 4. PAI
> INCLUDE z_bug_ws_f01.    " 5. Business logic
> INCLUDE z_bug_ws_f02.    " 6. Helpers
> ```

---

## 8. KNOWN ISSUES (v5.0)

### Resolved Issues (fixed in v5.0 design):

| # | Issue | Resolution |
|---|-------|-----------|
| 1 | CODE_F02 f4_date references non-existent DEADLINE/START_DATE | Remove bug date cases from f4_date |
| 2 | CODE_F02 f4_date references gs_prj_detail instead of gs_project | Fix variable name |
| 3-13 | 11 UAT bugs | Analyzed in `docs/v5-bug-analysis.md`, fixes in Phase F |

### Open Issues:

| # | Issue | Severity | Notes |
|---|-------|----------|-------|
| 1 | ZBUG_EVIDENCE table chưa tạo trong SAP | HIGH | Guide ready: `database/zbug-evidence.md` |
| 2 | Status migration `6` → `V` chưa chạy | HIGH | Script in Phase F1.3 |

---

## 9. THÔNG TIN HỆ THỐNG & ACCOUNTS

| Account | Quyền | Role trong ZBUG_USERS |
|---------|-------|----------------------|
| `DEV-089` | SE11, SE38, SE80, SE93 — account chính | **M** (Manager) |
| `DEV-061` | ALV Grid & SmartForms | **D** (Developer) |
| `DEV-118` | Quản lý lỗi, Testing | **T** (Tester) |

**SAP System:** S40 | **Client:** 324 | **Network:** EBS_SAP

---

## 10. NEXT STEPS

**Bước tiếp theo ngay lập tức:**

### Step 1: Write CODE v5.0 (6 files)

Viết lại toàn bộ 6 CODE files, incorporate:
- 11 bug fixes (từ `docs/v5-bug-analysis.md`)
- 10-state lifecycle (từ `docs/status-lifecycle.md`)
- 8 new features (từ `docs/phase-f-v5-enhancement.md`)

**Thứ tự viết:**
1. `CODE_TOP.md` v5.0 — new constants, new vars
2. `CODE_F00.md` v5.0 — field catalogs
3. `CODE_F02.md` v5.0 — F4 helpers, fixes
4. `CODE_F01.md` v5.0 — business logic (largest file)
5. `CODE_PBO.md` v5.0 — PBO modules for 4 new screens
6. `CODE_PAI.md` v5.0 — PAI modules for 4 new screens

### Step 2: Create new UI elements in SAP

- 4 new Screens (0410, 0370, 0210, 0220) → SE51
- 4 new GUI Statuses → SE41
- 4 new Title Bars → SE41
- Update STATUS_0200 (+SEARCH button)

### Step 3: Deploy + Test

- Copy CODE v5.0 vào SAP
- Update SE93 (0400 → 0410)
- Migration script (status 6→V)
- Test data population
- Full regression + UAT round 2

### Câu hỏi mở:

- [ ] Phase B (Function Modules) đã làm xong hết chưa? → Cần user xác nhận
- [ ] ZBUG_EVIDENCE đã tạo trong SAP chưa?
- [ ] Status migration `6`→`V` sẵn sàng chạy?

---

*File này được tạo bởi OpenCode agent. Cập nhật lần cuối: 16/04/2026 (repo restructured — professional layout).*
