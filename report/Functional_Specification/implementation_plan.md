# Functional Specification — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **Package:** `ZBUGTRACK`
**Program:** `Z_BUG_WORKSPACE_MP` (Module Pool, Type M)
**T-Code:** `ZBUG_WS` | **Version:** v5.0 | **Date:** 17/04/2026
**Prepared by:** DEV-089 (Manager)

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Function ID | ZBUG_WS_v5 |
| Module | ABAP Cross-Module Bug Tracking |
| Created by | DEV-089 |
| Reviewed by | — |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial functional spec — v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. Function Overview

| Field | Value |
|-------|-------|
| Function ID | ZBUG_WS_v5 |
| Processing Time | Online (real-time Dynpro interaction) |
| Processing Type | Multilingual (EN/VI) |
| Function Overview | Custom ABAP Module Pool for centralised bug tracking across SAP development projects. Supports 3 roles (Manager/Developer/Tester), 10-state bug lifecycle, auto-assignment, evidence management, email notifications, and project-based access control. |
| Supplement | Replaces manual Excel-based bug tracking. Integrates with SAP BCS email API and SMW0 file templates. |

---

## 4. Business Process Flow

### 4.1 Overall System Flow

```
User runs ZBUG_WS
  │
  └─▶ Screen 0410 — Project Search (initial screen)
        │  Filter by: Project ID, Manager, Status
        └─▶ Screen 0400 — Project List (ALV)
              │
              ├─▶ [Create Project] ──▶ Screen 0500 — Project Detail + User Assignment
              ├─▶ [Change/Display Project] ──▶ Screen 0500
              ├─▶ [Double-click project] ──▶ Screen 0200 — Bug List (ALL bugs + Dashboard)
              │     │
              │     ├─▶ [Create Bug] ──▶ Screen 0300 — Bug Detail (6 tabs)
              │     │     └─▶ [Change Status] ──▶ Screen 0370 — Status Transition Popup
              │     ├─▶ [Change/Display Bug] ──▶ Screen 0300
              │     └─▶ [SEARCH] ──▶ Screen 0210 — Bug Search Popup
              │                         └─▶ Screen 0220 — Search Results ALV
              └─▶ [My Bugs] ──▶ Screen 0200 (role-filtered, no CREATE)
```

### 4.2 Bug Lifecycle Flow

```
New(1) ──auto-assign Dev──▶ Assigned(2) ──Dev accepts──▶ InProgress(3)
                                                               │
  ┌────── No Dev available ──────────────────────────────▶ Pending(4) ──Manager reassign──▶ Assigned(2)
  ▼                                                           │
Waiting(W) ──Manager assigns──▶ Assigned(2)                  ▼
                                                          Rejected(R) ←── Dev refuses
                                                              │
                                                         Fixed(5) ──auto-assign Tester──▶ FinalTesting(6)
                                                                         │
                                                                    Resolved(V) ← TERMINAL
                                                                    InProgress(3) ← test failed
```

---

## 5. Screen Definition

### Screen 0410 — Project Search (Initial Screen)

| No. | Field Name | Field Label | Type | Mandatory | Notes |
|-----|-----------|------------|------|-----------|-------|
| 1 | `GV_SEARCH_PRJ_ID` | Project ID | Input | No | F4 help available |
| 2 | `GV_SEARCH_MGR` | Manager | Input | No | F4 help available |
| 3 | `GV_SEARCH_PRJ_STATUS` | Status | Input | No | F4 help: 1/2/3/4 |

**Buttons:** Execute (F8), Back (F3), Exit (Shift+F3), Cancel (F12)

### Screen 0400 — Project List

| No. | ALV Column | Field | Type |
|-----|-----------|-------|------|
| 1 | Project ID | `PROJECT_ID` | CHAR 20 |
| 2 | Project Name | `PROJECT_NAME` | CHAR 100 |
| 3 | Manager | `PROJECT_MANAGER` | CHAR 12 |
| 4 | Status | `PROJECT_STATUS` | CHAR 1 (1/2/3/4) |
| 5 | Start Date | `START_DATE` | DATS |
| 6 | End Date | `END_DATE` | DATS |

**Buttons:** Create Project, Change, Display, Delete, My Bugs, Download Template, Upload, Refresh

### Screen 0200 — Bug List

**Dashboard Header (top section):**

| Metric | Description |
|--------|-------------|
| Total Bugs | COUNT all bugs in current project |
| New | COUNT STATUS = '1' |
| Assigned | COUNT STATUS = '2' |
| In Progress | COUNT STATUS = '3' |
| Fixed | COUNT STATUS = '5' |
| Final Testing | COUNT STATUS = '6' |
| Resolved | COUNT STATUS = 'V' |
| Waiting | COUNT STATUS = 'W' |
| By Priority | H / M / L counts |
| By Module | Per SAP_MODULE counts |

**ALV Columns:**

| No. | Column | Field | Type |
|-----|--------|-------|------|
| 1 | Bug ID | `BUG_ID` | CHAR 10 |
| 2 | Title | `TITLE` | CHAR 100 |
| 3 | Status | `STATUS` | CHAR 20 (display as text) |
| 4 | Priority | `PRIORITY` | CHAR 1 |
| 5 | Severity | `SEVERITY` | CHAR 1 |
| 6 | Bug Type | `BUG_TYPE` | CHAR 1 |
| 7 | SAP Module | `SAP_MODULE` | CHAR 20 |
| 8 | Developer | `DEV_ID` | CHAR 12 |
| 9 | Tester | `TESTER_ID` | CHAR 12 |
| 10 | Created Date | `CREATED_AT` | DATS |

**Buttons:** Create, Change, Display, Delete, Refresh, Download Testcase, Download Confirm, Download Fix, SEARCH

### Screen 0300 — Bug Detail (Tab Strip, 6 tabs)

#### Tab 1 — Bug Info (Screen 0310)

| No. | Field | Type | Editable | Screen Group |
|-----|-------|------|---------|--------------|
| 1 | BUG_ID | CHAR 10 | Never | BID |
| 2 | PROJECT_ID | CHAR 20 | Never (from context) | PRJ |
| 3 | TITLE | CHAR 100 | M/D/T | EDT |
| 4 | SAP_MODULE | CHAR 20 | M/T only | FNC |
| 5 | BUG_TYPE | CHAR 1 | M/T only | FNC |
| 6 | PRIORITY | CHAR 1 | M/T only | FNC |
| 7 | SEVERITY | CHAR 1 | M/T only | FNC |
| 8 | STATUS | CHAR 20 | Never (popup only) | STS |
| 9 | DEV_ID | CHAR 12 | M only | EDT |
| 10 | TESTER_ID | CHAR 12 | M/T | TST |
| 11 | VERIFY_TESTER_ID | CHAR 12 | M only | EDT |
| 12 | APPROVED_BY | CHAR 12 | M | EDT |
| 13 | CREATED_AT | DATS | Never (auto) | — |
| 14 | CC_DESC_MINI | Mini editor | M/D/T | EDT |

#### Tab 2 — Description (Screen 0320)
- Long Text editor (`CC_DESC`) using SAPScript text object `ZBUG_NOTE`, ID `Z001`

#### Tab 3 — Dev Note (Screen 0330)
- Long Text editor (`CC_DEVNOTE`) using SAPScript text object `ZBUG_NOTE`, ID `Z002`

#### Tab 4 — Tester Note (Screen 0340)
- Long Text editor (`CC_TSTRNOTE`) using SAPScript text object `ZBUG_NOTE`, ID `Z003`

#### Tab 5 — Evidence (Screen 0350)

| No. | Column | Field | Notes |
|-----|--------|-------|-------|
| 1 | EVD_ID | `EVD_ID` | Auto-generated |
| 2 | File Name | `FILE_NAME` | CHAR 100 |
| 3 | MIME Type | `MIME_TYPE` | CHAR 50 |
| 4 | File Size | `FILE_SIZE` | INT4 (bytes) |
| 5 | Uploaded by | `UPLOADED_BY` | CHAR 12 |
| 6 | Upload Date | `UPLOAD_DATE` | DATS |

**Buttons:** Upload Evidence, Upload Report, Upload Fix, Download Evidence

#### Tab 6 — History (Screen 0360)

| No. | Column | Field | Notes |
|-----|--------|-------|-------|
| 1 | Log ID | `LOG_ID` | NUMC 10 |
| 2 | Action | `ACTION_TYPE` | CHAR 2: CR/UP/ST/AT/DL/RJ |
| 3 | Changed by | `CHANGED_BY` | CHAR 12 |
| 4 | Date/Time | `CHANGED_AT` + `CHANGED_TIME` | DATS + TIMS |
| 5 | Old Value | `OLD_VALUE` | CHAR 100 |
| 6 | New Value | `NEW_VALUE` | CHAR 100 |
| 7 | Reason | `REASON` | STRING |

### Screen 0370 — Status Transition Popup

**Read-only fields:**

| Field | Description |
|-------|-------------|
| BUG_ID + TITLE | Bug identification |
| REPORTER (TESTER_ID) | Who reported the bug |
| CURRENT_STATUS | Current status code |
| CURRENT_STATUS_TEXT | Status in human-readable form |

**Input fields (conditional enable by current status):**

| Current Status | NEW_STATUS Dropdown | DEVELOPER_ID | FINAL_TESTER_ID | TRANS_NOTE | Upload Button |
|---------------|--------------------|--------------|-----------------|-----------  |---------------|
| 1 — New | 2, W | Open (mandatory if →2) | Locked | Locked | Locked |
| W — Waiting | 2, 6 | Open (mandatory) | Open (if →6) | Locked | Locked |
| 2 — Assigned | 3, R | Locked | Locked | Open (mandatory if →R) | Locked |
| 3 — In Progress | 5, 4, R | Locked | Locked | Open | Open (mandatory if →5) |
| 4 — Pending | 2 | Open (mandatory) | Locked | Locked | Locked |
| 6 — Final Testing | V, 3 | Locked | Locked | Open (mandatory) | Locked |

**Buttons:** Confirm, Upload Trans (UP_TRANS), Cancel (F12)

### Screen 0210 — Bug Search Input Popup

| No. | Field | Label | Type |
|-----|-------|-------|------|
| 1 | `GV_SRCH_BUG_ID` | Bug ID | Input (F4 available) |
| 2 | `GV_SRCH_TITLE` | Title (contains) | Input |
| 3 | `GV_SRCH_STATUS` | Status | Input (F4 available) |
| 4 | `GV_SRCH_PRIORITY` | Priority | Input |
| 5 | `GV_SRCH_MODULE` | SAP Module | Input |
| 6 | `GV_SRCH_REPORTER` | Reporter | Input |

**Buttons:** Execute (F8), Cancel (F12)

### Screen 0500 — Project Detail + User Assignment

| No. | Field | Table | Notes |
|-----|-------|-------|-------|
| 1 | PROJECT_ID | ZBUG_PROJECT | Locked (auto-generated) |
| 2 | PROJECT_NAME | ZBUG_PROJECT | Editable |
| 3 | DESCRIPTION | ZBUG_PROJECT | Editable |
| 4 | PROJECT_MANAGER | ZBUG_PROJECT | F4 from ZBUG_USERS |
| 5 | PROJECT_STATUS | ZBUG_PROJECT | Dropdown 1/2/3/4 |
| 6 | START_DATE / END_DATE | ZBUG_PROJECT | F4 calendar |
| 7 | NOTE | ZBUG_PROJECT | Free text |
| 8 | TC_USERS (Table Control) | ZBUG_USER_PROJEC | USER_ID + ROLE per project |

**Buttons:** Save, Add User, Remove User

---

## 6. Message Definition

| Message ID | Type | Text (EN) | Trigger |
|-----------|------|-----------|---------|
| 001 | S | Bug [&] saved successfully | Bug save OK |
| 002 | E | Bug ID is required | BUG_ID missing |
| 003 | E | Evidence required before setting Fixed | Moving to status 5 without evidence |
| 004 | E | Transition note required | Moving to R/V without TRANS_NOTE |
| 005 | S | Status changed to [&] | Status transition OK |
| 006 | E | No available Developer for module [&] | Auto-assign fails |
| 007 | S | Developer [&] auto-assigned | Auto-assign success |
| 008 | E | Project must have all bugs Resolved before Done | Project closure validation |
| 009 | S | Project [&] saved successfully | Project save OK |
| 010 | E | User [&] not found in ZBUG_USERS | Invalid user |
| 011 | E | Access denied — insufficient role | Permission check failed |
| 012 | S | Email sent successfully | BCS email OK |
| 013 | E | Cannot delete project with open bugs | Project delete validation |

---

## 7. Auto-Assign Processing Description

### Phase A — Bug creation (New → Assigned or Waiting)

1. Trigger: Bug saved with STATUS = '1' (New)
2. Query ZBUG_USER_PROJEC: get all Developers (ROLE='D') in same PROJECT_ID
3. Join ZBUG_USERS: filter by SAP_MODULE matching bug's SAP_MODULE
4. Calculate workload: COUNT(ZBUG_TRACKER) WHERE DEV_ID = user AND STATUS IN ('2','3','4','6')
5. Select Developer with lowest workload AND workload < 5
6. If found: set DEV_ID, STATUS = '2', log history
7. If not found: STATUS = '1' → 'W', notify Manager via email

### Phase B — Bug fixed (Fixed → Final Testing or Waiting)

1. Trigger: Developer changes STATUS to '5' (Fixed) via popup 0370
2. Query ZBUG_USER_PROJEC: get all Testers (ROLE='T') in same PROJECT_ID
3. Join ZBUG_USERS: filter by SAP_MODULE matching bug's SAP_MODULE
4. Calculate workload: COUNT(ZBUG_TRACKER) WHERE VERIFY_TESTER_ID = user AND STATUS = '6'
5. Select Tester with lowest workload AND workload < 5
6. If found: set VERIFY_TESTER_ID, STATUS = '6', log history
7. If not found: STATUS → 'W', notify Manager

---

## 8. Role-Based Access Matrix

### Bug Operations

| Action | Manager (M) | Developer (D) | Tester (T) |
|--------|:-----------:|:-------------:|:----------:|
| Create Bug | ✅ | ❌ | ✅ |
| Delete Bug | ✅ | ❌ | ❌ |
| Change Bug Info | ✅ | Limited | Limited |
| Change Status (via popup) | Per matrix | Per matrix | Per matrix |
| Upload Evidence | ✅ | ✅ (fix file) | ✅ (report file) |
| Download Templates | ✅ | ❌ | ✅ |
| View all bugs in project | ✅ | ❌ (own only) | ❌ (own only) |

### Project Operations

| Action | Manager (M) | Developer (D) | Tester (T) |
|--------|:-----------:|:-------------:|:----------:|
| Create/Edit/Delete Project | ✅ | ❌ | ❌ |
| Add/Remove Users | ✅ | ❌ | ❌ |
| Upload Project Excel | ✅ | ❌ | ❌ |
| View Project | ✅ (all) | ✅ (assigned) | ✅ (assigned) |
