# Configuration Note — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **Package:** `ZBUGTRACK`
**Program Type:** Module Pool (Type M) | **T-Code:** `ZBUG_WS`
**Version:** v5.0 | **Date:** 17/04/2026
**Prepared by:** DEV-089 (Manager)

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Module | ABAP / Cross-Module (FI, MM, SD, BASIS) |
| Created by | DEV-089 |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Scope of Configuration

This document covers all SAP customizing (SPRO) and system configuration performed for the Bug Tracking project. Since this is a **pure ABAP development** project (no standard SAP functional module config), configuration items consist of:

- ABAP Dictionary objects (SE11)
- Program and Include registration (SE38 / SE80)
- Screen layouts (SE51)
- GUI Statuses and Title Bars (SE41)
- Transaction Code (SE93)
- Message Class (SE91)
- Web Repository objects — SMW0 templates
- Number Range objects
- SAPScript Text Objects (SE75)

---

## 3. Configuration Checklist

### 3.1 ABAP Dictionary (SE11)

| # | Object Type | Object Name | Description | Status |
|---|------------|-------------|-------------|--------|
| 1 | Domain | `zde_bug_status` | Bug status codes (CHAR 20): 1/2/3/4/5/6/7/W/R/V | ✅ Done |
| 2 | Domain | `zde_sap_module` | SAP module codes (CHAR 20): FI/MM/SD/ABAP/BASIS | ✅ Done |
| 3 | Domain | `zde_bug_role` | User roles (CHAR 1): M/D/T | ✅ Done |
| 4 | Data Element | `ZDE_BUG_ID` | Bug ID (CHAR 10) | ✅ Done |
| 5 | Data Element | `ZDE_PROJECT_ID` | Project ID (CHAR 20) | ✅ Done |
| 6 | Data Element | `ZDE_PRIORITY` | Priority (CHAR 1): H/M/L | ✅ Done |
| 7 | Data Element | `ZDE_SEVERITY` | Severity (CHAR 1): D/V/H/N/M | ✅ Done |
| 8 | Data Element | `ZDE_BUG_TYPE` | Bug type (CHAR 1) | ✅ Done |
| 9 | Data Element | `ZDE_REASONS` | Root causes (STRING) | ✅ Done |
| 10 | Data Element | `ZDE_USERNAME` | SAP username (CHAR 12) | ✅ Done |
| 11 | Data Element | `ZDE_IS_DEL` | Soft-delete flag (CHAR 1) | ✅ Done |
| 12 | Table | `ZBUG_TRACKER` | Core bug records — 29 fields | ✅ Done |
| 13 | Table | `ZBUG_USERS` | User registry — 12 fields | ✅ Done |
| 14 | Table | `ZBUG_PROJECT` | Project records — 16 fields | ✅ Done |
| 15 | Table | `ZBUG_USER_PROJEC` | User-Project M:N mapping — 10 fields | ✅ Done |
| 16 | Table | `ZBUG_HISTORY` | Bug change history — 10 fields | ✅ Done |
| 17 | Table | `ZBUG_EVIDENCE` | Binary evidence storage — 11 fields | ❌ Pending |
| 18 | Package | `ZBUGTRACK` | Development package for all objects | ✅ Done |

### 3.2 ABAP Program Objects (SE38 / SE80)

| # | Object Name | Type | Description | Status |
|---|------------|------|-------------|--------|
| 1 | `Z_BUG_WORKSPACE_MP` | Module Pool (M) | Main program | ✅ Done (v5.0 code ready) |
| 2 | `Z_BUG_WS_TOP` | Include | Global declarations, types, constants | ✅ Done |
| 3 | `Z_BUG_WS_F00` | Include | ALV field catalog + LCL_EVENT_HANDLER | ✅ Done |
| 4 | `Z_BUG_WS_PBO` | Include | Process Before Output modules | ✅ Done |
| 5 | `Z_BUG_WS_PAI` | Include | Process After Input modules | ✅ Done |
| 6 | `Z_BUG_WS_F01` | Include | Business logic FORMs | ✅ Done |
| 7 | `Z_BUG_WS_F02` | Include | Helpers: F4, Long Text, Popup, Download | ✅ Done |

> Include order in main program:
> `Z_BUG_WS_TOP` → `Z_BUG_WS_F00` → `Z_BUG_WS_PBO` → `Z_BUG_WS_PAI` → `Z_BUG_WS_F01` → `Z_BUG_WS_F02`

### 3.3 Screens (SE51)

| # | Screen | Type | Description | Status |
|---|--------|------|-------------|--------|
| 1 | 0200 | Normal | Bug List (ALV + Dashboard header) | ✅ Done |
| 2 | 0210 | Modal Dialog | Bug Search Input popup | ❌ Pending (F11) |
| 3 | 0220 | Normal | Bug Search Results ALV | ❌ Pending (F11) |
| 4 | 0300 | Normal + Tab Strip | Bug Detail (6 subscreens) | ✅ Done |
| 5 | 0310–0360 | Subscreens | Bug Info / Description / Dev Note / Tester Note / Evidence / History | ✅ Done |
| 6 | 0370 | Modal Dialog | Status Transition popup | ❌ Pending (F11) |
| 7 | 0400 | Normal | Project List ALV | ✅ Done |
| 8 | 0410 | Normal | Project Search (NEW initial screen) | ❌ Pending (F11) |
| 9 | 0500 | Normal + Table Control | Project Detail + User Assignment | ✅ Done |

### 3.4 GUI Statuses and Title Bars (SE41)

| # | Object | Type | Screen | Status |
|---|--------|------|--------|--------|
| 1 | `STATUS_0200` | GUI Status | 0200 | ⚠️ Update needed (+SEARCH button) |
| 2 | `STATUS_0210` | GUI Status | 0210 | ❌ Pending (F12) |
| 3 | `STATUS_0220` | GUI Status | 0220 | ❌ Pending (F12) |
| 4 | `STATUS_0300` | GUI Status | 0300 | ✅ Done |
| 5 | `STATUS_0370` | GUI Status | 0370 | ❌ Pending (F12) |
| 6 | `STATUS_0400` | GUI Status | 0400 | ✅ Done |
| 7 | `STATUS_0410` | GUI Status | 0410 | ❌ Pending (F12) |
| 8 | `STATUS_0500` | GUI Status | 0500 | ✅ Done |
| 9 | `T_0210` | Title Bar | 0210 — "Bug Search" | ❌ Pending (F12) |
| 10 | `T_0220` | Title Bar | 0220 — "Search Results" | ❌ Pending (F12) |
| 11 | `T_0370` | Title Bar | 0370 — "Change Bug Status" | ❌ Pending (F12) |
| 12 | `T_0410` | Title Bar | 0410 — "Project Search" | ❌ Pending (F12) |

### 3.5 Transaction Code (SE93)

| # | T-Code | Target Program | Initial Screen | Status |
|---|--------|---------------|---------------|--------|
| 1 | `ZBUG_WS` | `Z_BUG_WORKSPACE_MP` | 0410 (was 0400 in v4.x) | ⚠️ Update needed (F13) |

### 3.6 Message Class (SE91)

| # | Object | Name | Content | Status |
|---|--------|------|---------|--------|
| 1 | Message Class | `ZBUG_MSG` | 33 messages (EN + VI) — validation errors, success, permissions | ✅ Done |

### 3.7 Web Repository — SMW0 Templates

| # | Object Key | File Name | Purpose | Status |
|---|-----------|-----------|---------|--------|
| 1 | `ZBT_TMPL_01` | `Bug_report.xlsx` | Tester uploads bug report | ✅ Done |
| 2 | `ZBT_TMPL_02` | `fix_report.xlsx` | Developer uploads fix evidence | ✅ Done |
| 3 | `ZBT_TMPL_03` | `confirm_report.xlsx` | Final Tester uploads confirmation | ✅ Done |
| 4 | `ZTEMPLATE_PROJECT` | `project_template.xlsx` | Manager uploads projects in bulk | ✅ Done |

### 3.8 Text Objects (SE75 — SAPScript)

| # | Text Object | Text ID | Purpose | Status |
|---|------------|---------|---------|--------|
| 1 | `ZBUG_NOTE` | `Z001` | Bug Description long text | ✅ Done |
| 2 | `ZBUG_NOTE` | `Z002` | Developer Note long text | ✅ Done |
| 3 | `ZBUG_NOTE` | `Z003` | Tester Note long text | ✅ Done |

---

## 4. Critical Configuration Details

### 4.1 ZBUG_TRACKER — Key Field Types

| Field | Data Type | Length | Note |
|-------|-----------|--------|------|
| `STATUS` | CHAR | 20 | NOT CHAR 1 — uses `zde_bug_status` domain |
| `SAP_MODULE` | CHAR | 20 | NOT CHAR 10 — uses `zde_sap_module` domain |
| `DESC_TEXT` | STRING | — | Cannot place directly on Dynpro layout |
| `REASONS` | STRING | — | Cannot place directly on Dynpro layout |

### 4.2 Screen Groups — ZBUG_TRACKER fields

| Group | Fields Included | Behaviour |
|-------|----------------|-----------|
| `EDT` | All editable fields | Locked in Display mode |
| `BID` | BUG_ID | Always locked — auto-generated |
| `PRJ` | PROJECT_ID | Locked when coming from project context |
| `FNC` | BUG_TYPE, PRIORITY, SEVERITY | Locked for Developer role |
| `TST` | TESTER_ID | Locked for Developer role |
| `DEV` | DEV_ID, VERIFY_TESTER_ID | Locked for Tester role |
| `STS` | STATUS | Always locked — change via popup 0370 only |

### 4.3 Status Values (Breaking Change v4.x → v5.0)

| Code | Meaning | ABAP Constant |
|------|---------|---------------|
| `1` | New | `gc_st_new` |
| `W` | Waiting | `gc_st_waiting` |
| `2` | Assigned | `gc_st_assigned` |
| `3` | In Progress | `gc_st_inprogress` |
| `4` | Pending | `gc_st_pending` |
| `5` | Fixed | `gc_st_fixed` |
| `R` | Rejected | `gc_st_rejected` |
| `6` | Final Testing | `gc_st_finaltesting` |
| `V` | Resolved (terminal) | `gc_st_resolved` |
| `7` | Closed (legacy) | `gc_st_closed` |

> **CRITICAL:** In v4.x, `6` = Resolved. In v5.0, `6` = Final Testing, `V` = Resolved.
> Migration script required: `UPDATE ZBUG_TRACKER SET STATUS = 'V' WHERE STATUS = '6'`

---

## 5. Pending Configuration Tasks (F11–F16)

| Step | Action | SAP Transaction | Status |
|------|--------|----------------|--------|
| F11 | Create screens 0410, 0370, 0210, 0220 | SE51 | ❌ TODO |
| F12 | Create GUI Statuses: STATUS_0410, STATUS_0370, STATUS_0210, STATUS_0220 | SE41 | ❌ TODO |
| F12 | Update STATUS_0200: add SEARCH button (FCode = SEARCH) | SE41 | ❌ TODO |
| F13 | Update ZBUG_WS: change initial screen 0400 → 0410 | SE93 | ❌ TODO |
| F14 | Copy all v5.0 code includes into SAP | SE38/SE80 | ❌ TODO |
| F15 | Create ZBUG_EVIDENCE table (guide: `database/zbug-evidence.md`) | SE11 | ❌ TODO |
| F16 | Run status migration script (6 → V) | SE38 / SE16N | ❌ TODO |

---

## 6. Record of Changes

| No. | Effective Date | Version | Change Description | Changed by |
|-----|---------------|---------|-------------------|-----------|
| 1 | 17/04/2026 | 1.0 | Initial configuration note for v5.0 | DEV-089 |
