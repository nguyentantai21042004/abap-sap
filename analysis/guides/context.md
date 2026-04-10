# CONTEXT & STATUS — Z_BUG_WORKSPACE_MP

> **Cập nhật lần cuối:** 09/04/2026 (session 4)
> **Mục đích:** File này dùng để handoff giữa các agent/session. Đọc file này trước khi làm bất cứ thứ gì với dự án.

---

## 1. DỰ ÁN LÀ GÌ?

Hệ thống **Bug Tracking tập trung** chạy trên SAP ERP bằng ABAP thuần túy.

- **SAP System:** S40, Client 324, **ABAP 7.70** (SAP_BASIS 770 — inline declarations, SWITCH, CONV, string templates, @ host vars)
- **Package:** `ZBUGTRACK`
- **T-code entry point:** `ZBUG_HOME` → Screen **0400** (Project List)

Dự án đang ở **Phase C: Module Pool UI** — code rewritten v2.0 (Project-first flow), screens chưa tạo trong SAP.

---

## 2. CHƯƠNG TRÌNH MẪU THAM CHIẾU

Có 2 chương trình mẫu trong repo (tham khảo để hiểu pattern):

| Thư mục | Program | Vai trò |
|---------|---------|---------|
| `ZPG_BUGTRACKING_MAIN/` | `ZPG_BUGTRACKING_MAIN` | Bug List + Project List ALV, Selection Screen |
| `ZPG_BUGTRACKING_DETAIL/` | `ZPG_BUGTRACKING_DETAIL` | Bug/Project Detail + Tab Strip + Evidence upload |

**Mục tiêu:** Chương trình `Z_BUG_WORKSPACE_MP` phải **ngang hàng hoặc tốt hơn** 2 chương trình mẫu.

---

## 3. KIẾN TRÚC MỤC TIÊU (Project-First Flow — v2.0)

```
Program: Z_BUG_WORKSPACE_MP (Module Pool, Type M)
│
├── Include: Z_BUG_WS_TOP   → Global declarations, types, ALV objects
├── Include: Z_BUG_WS_F00   → ALV field catalog + LCL_EVENT_HANDLER class
├── Include: Z_BUG_WS_PBO   → Process Before Output modules
├── Include: Z_BUG_WS_PAI   → Process After Input modules (user commands)
├── Include: Z_BUG_WS_F01   → Business logic FORMs (SQL, save, history...)
└── Include: Z_BUG_WS_F02   → Helpers: F4, Long Text, Popup, GOS
│
├── Screen 0100  → ~~Hub / Router~~ **DEPRECATED** (code giữ nguyên, không navigate tới)
├── Screen 0200  → Bug List (ALV Grid, dual mode: Project bugs / My Bugs)
├── Screen 0300  → Bug Detail (Tab Strip, 6 subscreens)
│   ├── Subscreen 0310  → Tab: Bug Info (fields + Description mini editor CC_DESC_MINI)
│   ├── Subscreen 0320  → Tab: Description (Long Text Z001)
│   ├── Subscreen 0330  → Tab: Dev Note (Long Text Z002)
│   ├── Subscreen 0340  → Tab: Tester Note (Long Text Z003)
│   ├── Subscreen 0350  → Tab: Evidence (GOS attachment)
│   └── Subscreen 0360  → Tab: History (ALV readonly)
├── Screen 0400  → **Project List (ALV Grid) — INITIAL SCREEN**
└── Screen 0500  → Project Detail + User Assignment (Table Control TC_USERS)
```

### Navigation Flow (NEW):

```
ZBUG_HOME → Screen 0400 (Project List, initial)
  ├── Click Project → Screen 0200 (ALL bugs of project, gv_bug_filter_mode='P')
  │     ├── Create/Change/Display → Screen 0300
  │     └── Back → Screen 0400
  ├── [My Bugs] → Screen 0200 (bugs by role, gv_bug_filter_mode='M', CREATE hidden)
  │     └── Back → Screen 0400
  ├── Create/Change/Display Project → Screen 0500
  └── Back → LEAVE PROGRAM
```

### Key New Global Variables:

| Variable | Type | Purpose |
|----------|------|---------|
| `gv_bug_filter_mode` | `CHAR1` | `P` = Project bugs, `M` = My Bugs |
| `gv_status_disp` | `CHAR20` | Status text display on Screen 0310 |
| `gv_priority_disp` | `CHAR10` | Priority text display on Screen 0310 |
| `gv_severity_disp` | `CHAR20` | Severity text display on Screen 0310 |
| `gv_bug_type_disp` | `CHAR20` | Bug Type text display on Screen 0310 |
| `gv_prj_status_disp` | `CHAR20` | Project Status text display on Screen 0500 |
| `go_desc_mini_cont` | `CL_GUI_CUSTOM_CONTAINER` | Container for mini description editor |
| `go_desc_mini_edit` | `CL_GUI_TEXTEDIT` | Mini text editor (3-4 lines) on Bug Info tab |

### Screen Groups:

| Group | Purpose |
|-------|---------|
| `EDT` | Editable fields — disabled in Display mode |
| `BID` | BUG_ID — locked after creation (display-only unless Create mode) |
| `PRJ` | PROJECT_ID — locked when creating from project context (pre-filled) |
| `TST` | Tester-specific fields |
| `DEV` | Developer-specific fields |

### Fcode Naming:

| Screen | Key Fcodes |
|--------|-----------|
| 0400 | `CREA_PRJ`, `CHNG_PRJ`, `DISP_PRJ`, `DEL_PRJ`, `MY_BUGS`, `DN_TMPL`, `UPLOAD`, `REFRESH` |
| 0200 | `CREATE`, `CHANGE`, `DISPLAY`, `DELETE`, `REFRESH` |
| 0300 | `SAVE`, `TAB_INFO`, `TAB_DESC`, `TAB_DEVNOTE`, `TAB_TSTR_NOTE`, `TAB_EVIDENCE`, `TAB_HISTORY` |
| 0500 | `SAVE`, `ADD_USR`, `REMO_USR` |

---

## 4. DATABASE TABLES

| Table | Status | Fields | Source of Truth |
|-------|--------|--------|-----------------|
| `ZBUG_TRACKER` | Updated (+13 fields) | +PROJECT_ID, SEVERITY, VERIFY_TESTER_ID, IS_DEL, ERNAM/DAT/ZET, AENAM/DAT/ZET | `verify-notes/table-fields.md` |
| `ZBUG_USERS` | Updated (+4 fields) | +AENAM/DAT/ZET, IS_DEL | `verify-notes/table-fields.md` |
| `ZBUG_PROJECT` | **New** | 16 fields | `verify-notes/table-fields.md` |
| `ZBUG_USER_PROJEC` | **New** | 10 fields (M:N User↔Project, có ROLE) | `verify-notes/table-fields.md` |
| `ZBUG_HISTORY` | Unchanged | Change log | `verify-notes/table-fields.md` |

### Critical Type Mappings (from SE11 verification):

| Field | Type | Note |
|-------|------|------|
| `ZBUG_TRACKER.STATUS` | `zde_bug_status` = **CHAR 20** | NOT CHAR 1 |
| `ZBUG_TRACKER.SAP_MODULE` | `zde_sap_module` = **CHAR 20** | NOT CHAR 10 |
| `ZBUG_TRACKER.DESC_TEXT` | **STRING** | |
| `ZBUG_HISTORY.REASON` | **STRING** | NOT CHAR 255 |

**9-State Bug Lifecycle:**

```
New(1) → Assigned(2) → InProgress(3) → Pending(4) → Fixed(5) → Resolved(6) → Closed(7)
       ↘ Waiting(W) [auto when no Dev available]
                                       ↘ Rejected(R) [Dev rejected]
```

---

## 5. TRẠNG THÁI TRIỂN KHAI (09/04/2026)

### PHASE A — DATABASE HARDENING ✅ DONE

| Bước | Nội dung | Status |
|------|---------|--------|
| A1 | 4 Domains + 6 Data Elements | ✅ Xong |
| A2 | Bảng `ZBUG_PROJECT` (16 fields) | ✅ Xong |
| A3 | Bảng `ZBUG_USER_PROJEC` (9 fields) | ✅ Xong |
| A4 | Update `ZBUG_TRACKER` (+13 fields) + SE14 Adjust + backfill script | ✅ Xong |
| A5 | Update `ZBUG_USERS` (+4 fields) | ✅ Xong |
| A6 | Message Class `ZBUG_MSG` (33 messages, EN+VI) | ✅ Xong |
| A7 | Text Object `ZBUG` (3 Text IDs: Z001/Z002/Z003) | ✅ Xong |
| A8 | Migration report `Z_BUG_MIGRATE_STATUS` | ✅ Xong |

### PHASE B — BUSINESS LOGIC UPDATE ❓ CHƯA XÁC NHẬN

| Bước | Nội dung | Status |
|------|---------|--------|
| B1-B9 | Function Modules update (Z_BUG_CHECK_PERMISSION, Z_BUG_CREATE, etc.) | ❓ Chưa xác nhận xong/chưa |

### PHASE C — MODULE POOL UI ← **ĐANG LÀM**

| Bước | Nội dung | Status |
|------|---------|--------|
| C1 | Tạo program `Z_BUG_WORKSPACE_MP` (Type M) + 6 includes | ✅ Đã tạo trong SAP |
| C2 | **CODE v2.0** — 6 includes rewritten for Project-first flow | ✅ **Code guides complete** — sẵn sàng copy vào SAP |
| C3 | Screen 0100 (deprecated — giữ code, không dùng) | ⚠️ Giữ nguyên, không tạo mới |
| C4 | Screen 0200 (Bug List + ALV container, dual mode) | ❌ Chưa tạo trong SE51 |
| C5 | Screen 0300 (Tab Strip + 6 subscreens 0310-0360) | ❌ Chưa tạo trong SE51 |
| C6 | **Screen 0400 (Project List — INITIAL SCREEN)** | ❌ Chưa tạo trong SE51 |
| C7 | Screen 0500 (Project Detail + Table Control TC_USERS) | ❌ Chưa tạo trong SE51 |
| C8 | GUI Status (SE41): STATUS_0200/0300/0400/0500 | ❌ Chưa tạo |
| C9 | Gán Module PBO/PAI vào từng screen flow logic | ❌ Chưa làm |
| C10 | SE93: Đổi ZBUG_HOME initial screen 0100 → **0400** | ❌ Chưa làm |

### PHASE D — EXCEL & ADVANCED FEATURES

| Bước | Nội dung | Status |
|------|---------|--------|
| D1 | Excel Template trên SMW0 | ❌ Chưa làm |
| D2 | Download Template (`DN_TMPL`) trên Screen 0400 | ❌ Chưa làm |
| D3 | Upload Excel (`UPLOAD`) trên Screen 0400 | ❌ Chưa làm |
| D4 | Message Class Migration (hardcoded → ZBUG_MSG) | ❌ Chưa làm |
| D5 | Orphan Bug Cleanup Script (`Z_BUG_CLEANUP_ORPHAN`) | ❌ Chưa làm |
| ~~D5~~ | ~~Dashboard Statistics~~ | ❌ **CANCELLED** (Screen 0100 deprecated) |

### PHASE E — TESTING & GO-LIVE

| Bước | Nội dung | Status |
|------|---------|--------|
| E1 | T-code `ZBUG_HOME` → Screen **0400** (SE93) | ❌ Chưa làm |
| E2-E6 | Unit Test, Integration Test, Permission Test, etc. | ❌ Chưa làm |

---

## 6. UX DECISIONS ĐÃ CHỐT (Session 4)

Đây là các quyết định UX đã finalize — **không cần hỏi lại**:

1. **Bug bắt buộc thuộc 1 Project** — enforce, không cho tạo bug lỏng
2. **Screen 0400 (Project List) là initial screen** — thay Homepage 0100
3. **Click Project → thấy ALL bugs** (không filter theo role trong project context)
4. **Nút "My Bugs"** trên Project List toolbar → xem bugs assign cho user theo role (cross-project)
5. **Create Bug chỉ khi có project context** — ẩn nút Create trong My Bugs mode
6. **PROJECT_ID pre-fill + locked** khi tạo bug từ project context
7. **Screen 0100 deprecated** — giữ code, không navigate tới
8. **Description mini editor** (`cl_gui_textedit`, 3-4 dòng) trên Bug Info tab (0310), container `CC_DESC_MINI`
9. **Orphan bugs cần cleanup** — script `Z_BUG_CLEANUP_ORPHAN` gán vào project "LEGACY"

---

## 7. CODE GUIDES — VỊ TRÍ & CÁCH DÙNG

Tất cả code đã được rewrite v2.0 trong `analysis/guides/`, copy thẳng vào SAP:

| File guide | SAP include | Version | Notes |
|-----------|------------|---------|-------|
| `CODE_TOP.md` | `Z_BUG_WS_TOP` | **v2.0** | +gv_bug_filter_mode, display vars, desc mini objects, severity/bug_type text types |
| `CODE_F00.md` | `Z_BUG_WS_F00` | **v2.0** | Project hotspot→BugList, severity_text/bug_type_text columns, hide raw codes |
| `CODE_PBO.md` | `Z_BUG_WS_PBO` | **v2.0** | 0400 initial, dual-mode title, BID/PRJ groups, desc mini init, mode in title |
| `CODE_PAI.md` | `Z_BUG_WS_PAI` | **v2.0** | MY_BUGS, 0400 BACK=LEAVE PROGRAM, CREATE blocked in M mode, save_desc_mini |
| `CODE_F01.md` | `Z_BUG_WS_F01` | **v2.0** | Dual filter (P/M), PROJECT_ID validation, save_desc_mini_to_workarea, severity/bugtype text mapping |
| `CODE_F02.md` | `Z_BUG_WS_F02` | **v2.0** | No structural changes, kept as-is with same F4/long text helpers |

| Guide file | Purpose | Version |
|-----------|---------|---------|
| `phase-a-database.md` | SE11/SE91/SE75 steps | v1.0 — unchanged |
| `phase-b-business-logic.md` | SE37 FM updates | v1.0 — unchanged |
| `phase-c-module-pool.md` | SE51/SE41 step-by-step (Project-first flow) | **v2.0** — full rewrite |
| `phase-d-advanced-features.md` | Excel/Cleanup | **v6.0** — updated for new flow + cleanup script |
| `phase-e-testing.md` | T-code + UAT | v1.0 — may need update |

| Reference file | Purpose |
|---------------|---------|
| `UI_STATUS.md` | Snapshot of UI before refactor (for reference) |
| `UI_SCREEN_FLOW.md` | Navigation flow diagram (new Project-first) |
| `UI_REFACTOR_PLAN.md` | 16-item refactor plan, 5 phases |
| `verify-notes/table-fields.md` | Source of truth for field names/types (from SE11 screenshots) |

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

## 8. ĐIỂM KHÁC BIỆT SO VỚI CHƯƠNG TRÌNH MẪU (ZPG_BUGTRACKING_*)

| Tính năng | ZPG_BUGTRACKING_* (mẫu) | Z_BUG_WORKSPACE_MP (target) |
|-----------|------------------------|------------------------------|
| Entry point | Hub / Selection Screen | **Project List (0400)** — Project-first |
| Status model | ~5 states đơn giản | **9 states** với transition validation |
| Project entity | `ZTB_PROJECT` | `ZBUG_PROJECT` + `ZBUG_USER_PROJEC` (M:N) |
| Bug list | Single mode | **Dual mode** (Project bugs / My Bugs) |
| File attachment | `ZTB_EVD` (table tự tạo) | **GOS** (Generic Object Services — SAP standard) |
| Email | Không rõ | SmartForm + CL_BCS |
| Permission | Role check cơ bản | Role + Project membership check |
| Long Text | SAVE_TEXT (SAPScript) | Text Object `ZBUG` (Z001/Z002/Z003) |
| History | Có | Có + filter theo Action Type/Date |
| Soft Delete | Không có (hard delete) | `IS_DEL = 'X'` trên tất cả entities |
| Auto-assign | Không có | Có (workload-based + Waiting fallback) |
| Severity | Không có | 5 levels (Dump/VeryHigh/High/Normal/Minor) |
| Multi-language | Không có | Message Class `ZBUG_MSG` (EN + VI) |

---

## 9. THÔNG TIN HỆ THỐNG & ACCOUNTS

| Account | Password | Quyền |
|---------|----------|-------|
| `DEV-089` | `@Anhtuoi123` | SE11, SE38, SE80, SE93 — account chính |
| `DEV-061` | `@57Dt766` | ALV Grid & SmartForms |
| `DEV-118` | `Qwer123@` | Quản lý lỗi, Testing |
| `DEV-242` | `12345678` | Email config (SCOT, SOST) |
| `DEV-237` | `toiyeufpt` | GOS attachments |

**SAP System:** S40 | **Client:** 324 | **Network:** EBS_SAP

---

## 10. LỖI ĐANG GẶP

**Không có lỗi** — `Z_BUG_WORKSPACE_MP` đã activate thành công ngày 09/04/2026.

Code guides v2.0 đã rewrite hoàn chỉnh. Chưa copy vào SAP (cần tạo screens trước).

---

## 11. NEXT STEPS

**Việc cần làm tiếp theo** (theo thứ tự):

1. **Copy CODE v2.0 vào SAP** — Replace nội dung 6 includes trong SE80 bằng code từ CODE_*.md v2.0
2. **Tạo screens trong SE51** — Theo hướng dẫn `phase-c-module-pool.md` v2.0 (step-by-step)
3. **Tạo GUI Statuses trong SE41** — STATUS_0200, STATUS_0300, STATUS_0400, STATUS_0500
4. **Đổi T-code initial screen** — SE93: ZBUG_HOME → Screen 0400
5. **Run orphan bug cleanup** — `Z_BUG_CLEANUP_ORPHAN` (Phase D5)
6. **Phase D: Excel features** — SMW0 template, Download/Upload buttons
7. **Phase E: Testing** — Full workflow test

### Câu hỏi mở:

- [ ] Phase B (Function Modules) đã làm xong hết chưa? → Cần user xác nhận
- [ ] Code v2.0 đã copy vào SAP chưa? → User cần làm thủ công
- [ ] Orphan bugs: chọn Option A (gán LEGACY) hay Option B (list only)? → User chưa chốt

---

*File này được tạo bởi OpenCode agent. Cập nhật lần cuối: 09/04/2026 (session 4 — Project-first flow rewrite complete).*
