# Technical Specification — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **Package:** `ZBUGTRACK`
**Program:** `Z_BUG_WORKSPACE_MP` (Module Pool, Type M)
**T-Code:** `ZBUG_WS` | **ABAP Version:** 7.70 | **Date:** 17/04/2026
**Developer:** DEV-089

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Function ID | ZBUG_WS_v5 |
| Module | ABAP Cross-Module |
| Developer | DEV-089 |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial technical spec for v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. Introduction

| Field | Value |
|-------|-------|
| Function ID | ZBUG_WS_v5 |
| Processing Time | Online (Dynpro-based, immediate response) |
| Processing Type | Multilingual (EN/VI) |
| Introduction | Custom Module Pool program providing centralised bug tracking for SAP development teams. Built entirely in ABAP 7.70 using modern syntax (inline DATA(), SWITCH, CONV, string templates, @ host variables). |
| Supplement | No batch jobs. No RFC calls. No BAdIs. Direct DB operations on 6 custom Z-tables. |

---

## 4. Scope

### In Scope

- `Z_BUG_WORKSPACE_MP` Module Pool (all 6 includes)
- 10 Dynpro screens (0200, 0210, 0220, 0300, 0310–0360, 0370, 0400, 0410, 0500)
- 6 custom database tables (ZBUG_TRACKER, ZBUG_USERS, ZBUG_PROJECT, ZBUG_USER_PROJEC, ZBUG_HISTORY, ZBUG_EVIDENCE)
- ABAP Dictionary objects: 3 domains, 10+ data elements
- SAP BCS email integration via `CL_BCS`
- SMW0 web repository templates (3 report templates + 1 project upload template)
- SAPScript long text (3 text IDs in ZBUG_NOTE text object)
- GUI Statuses / Title Bars (SE41), Transaction Code ZBUG_WS (SE93)

### Out of Scope

- No standard SAP module configuration (no SPRO SD/FI/MM)
- No Fiori / BSP / Web Dynpro UI
- No function group (ZBUG_FG) — all logic is inlined as FORM routines
- No ALE/IDoc/RFC interfaces

---

## 5. Assumptions

1. SAP system S40, Client 324, ABAP version 7.70 (SAP_BASIS 770).
2. Development account `DEV-089` has SE11, SE38, SE51, SE41, SE93, SM30 access.
3. Users `DEV-089`, `DEV-061`, `DEV-118` are pre-registered in `ZBUG_USERS` with roles M, D, T respectively.
4. Test projects and mock user data exist in system before UAT testing.
5. SAP email system (SAPConnect) is configured — BCS API can send external emails.
6. SMW0 web repository is accessible for template upload.
7. Status migration script (6→V) will be run exactly once, after v5.0 deployment.

---

## 6. Functional Requirements Mapping

| Functional Requirement | Technical Implementation | Include |
|------------------------|------------------------|---------|
| 3-role system (M/D/T) | Read from ZBUG_USERS.ROLE, stored in `gv_role` | Z_BUG_WS_TOP |
| 10-state bug lifecycle | Status constants `gc_st_*`, transition matrix in FORM `validate_transition` | Z_BUG_WS_F01 |
| Auto-assign Developer | FORM `auto_assign_developer` | Z_BUG_WS_F01 |
| Auto-assign Tester | FORM `auto_assign_tester` | Z_BUG_WS_F01 |
| Status via popup only | Screen group `STS` locks STATUS field; fcode `STATUS_CHG` opens screen 0370 | Z_BUG_WS_PBO/PAI |
| Evidence upload | FORM `upload_evidence` — writes RAWSTRING to ZBUG_EVIDENCE | Z_BUG_WS_F01 |
| Evidence download | FORM `download_evidence` — reads RAWSTRING, writes to frontend | Z_BUG_WS_F01 |
| Long text (3 types) | `CL_GUI_TEXTEDIT` in CC_DESC / CC_DEVNOTE / CC_TSTRNOTE | Z_BUG_WS_F00/F01 |
| Email notification | `CL_BCS`, `CL_DOCUMENT_BCS`, `CL_SAPUSER_BCS` | Z_BUG_WS_F01 |
| ALV Grid (4 lists) | `CL_GUI_ALV_GRID` — Bug List, Project List, Evidence List, History List | Z_BUG_WS_F00 |
| Dashboard Header | Aggregation query on ZBUG_TRACKER, display in text fields | Z_BUG_WS_PBO |
| Bug Search (popup) | Screen 0210 input → FORM `execute_bug_search` → Screen 0220 results | Z_BUG_WS_F01 |
| Project Search | Screen 0410 input → FORM `execute_project_search` → Screen 0400 | Z_BUG_WS_F01 |
| Template download | FORM `download_template` reading from SMW0 (`WWWDATA`) | Z_BUG_WS_F02 |
| History logging | FORM `log_history` writes to ZBUG_HISTORY on every change | Z_BUG_WS_F01 |
| Unsaved changes detection | Global flag `gv_data_changed`, checked before BACK/EXIT | Z_BUG_WS_PAI |
| F4 calendar | FORM `f4_date` using `POPUP_GET_VALUES` | Z_BUG_WS_F02 |
| Soft delete | IS_DEL = 'X', never physically delete rows | Z_BUG_WS_F01 |

---

## 7. Technical Design

### 7.1 Business Process Architecture

```
Presentation Layer (Dynpro Screens)
├── Screen 0410 — Project Search
├── Screen 0400 — Project List (ALV)
├── Screen 0200 — Bug List (ALV + Dashboard)
├── Screen 0210/0220 — Bug Search popup + results
├── Screen 0300 — Bug Detail (Tab Strip)
│   └── Subscreens 0310–0360
├── Screen 0370 — Status Transition popup
└── Screen 0500 — Project Detail

Application Layer (ABAP Includes)
├── Z_BUG_WS_TOP  — Types, global variables, constants
├── Z_BUG_WS_F00  — LCL_EVENT_HANDLER (ALV events), field catalogs
├── Z_BUG_WS_PBO  — Module MODULE_*_PBO (screen population logic)
├── Z_BUG_WS_PAI  — Module MODULE_*_PAI (user command processing)
├── Z_BUG_WS_F01  — FORM routines (CRUD, lifecycle, auto-assign, email, history)
└── Z_BUG_WS_F02  — FORM routines (F4, long text editor, popup, template DL)

Data Layer (Custom Z-Tables in ZBUGTRACK package)
├── ZBUG_TRACKER      — 29 fields — core bug data
├── ZBUG_USERS        — 12 fields — user registry + roles
├── ZBUG_PROJECT      — 16 fields — project data
├── ZBUG_USER_PROJEC  — 10 fields — user-project assignment
├── ZBUG_HISTORY      — 10 fields — audit trail
└── ZBUG_EVIDENCE     — 11 fields — binary file storage
```

### 7.2 WBS & Timeline

| Phase | Content | Status |
|-------|---------|--------|
| A | Database Hardening (SE11 objects) | ✅ Done |
| B | Business Logic update (includes) | ❓ Unconfirmed |
| C+D | Module Pool UI + Advanced Features (v4.2) | ✅ Done |
| E | Testing (UAT Round 1 — 11 bugs found) | ✅ Done |
| F | v5.0 Enhancement (CODE complete, deployment pending) | ⏳ In Progress |

### 7.3 Data Dictionary Objects

| Object Type | Name | Type/Length | Description |
|-------------|------|------------|-------------|
| Domain | `zde_bug_status` | CHAR 20 | Bug status values: 1/2/3/4/5/6/7/W/R/V |
| Domain | `zde_sap_module` | CHAR 20 | SAP module: FI/MM/SD/ABAP/BASIS |
| Domain | `zde_bug_role` | CHAR 1 | User role: M/D/T |
| Data Element | `ZDE_BUG_ID` | CHAR 10 | Bug identifier |
| Data Element | `ZDE_PROJECT_ID` | CHAR 20 | Project identifier |
| Data Element | `ZDE_USERNAME` | CHAR 12 | SAP logon name |
| Data Element | `ZDE_BUG_TITLE` | CHAR 100 | Bug title |
| Data Element | `ZDE_BUG_DESC` | STRING | Bug description |
| Data Element | `ZDE_REASONS` | STRING | Root cause text |
| Data Element | `ZDE_PRJ_NAME` | CHAR 100 | Project name |
| Data Element | `ZDE_IS_DEL` | CHAR 1 | Soft delete flag |
| Package | `ZBUGTRACK` | — | All Z objects belong here |
| Table | `ZBUG_TRACKER` | 29 fields | Bug records |
| Table | `ZBUG_USERS` | 12 fields | User registry |
| Table | `ZBUG_PROJECT` | 16 fields | Projects |
| Table | `ZBUG_USER_PROJEC` | 10 fields | User-Project M:N |
| Table | `ZBUG_HISTORY` | 10 fields | History log |
| Table | `ZBUG_EVIDENCE` | 11 fields | Binary evidence |

---

## 8. Development Standards

### 8.1 Naming Conventions

| Object Type | Prefix | Example |
|-------------|--------|---------|
| Tables | `ZBUG_` | `ZBUG_TRACKER` |
| Programs | `Z_BUG_` | `Z_BUG_WORKSPACE_MP` |
| Includes | `Z_BUG_WS_` | `Z_BUG_WS_F01` |
| Domains | `zde_` | `zde_bug_status` |
| Data Elements | `ZDE_` | `ZDE_BUG_ID` |
| Constants (global) | `gc_` | `gc_st_new`, `gc_role_manager` |
| Global variables | `gv_` | `gv_role`, `gv_mode` |
| Global structures | `gs_` | `gs_bug`, `gs_project` |
| Global internal tables | `gt_` | `gt_bugs`, `gt_projects` |
| Local variables | `lv_` | `lv_count` |
| Local structures | `ls_` | `ls_user` |
| Local internal tables | `lt_` | `lt_evidence` |
| Form routines | snake_case | `auto_assign_developer` |
| Screen containers | `CC_` | `CC_BUG_LIST`, `CC_DESC` |

### 8.2 ABAP Coding Standards

- **ABAP 7.70** — use inline `DATA()`, `FIELD-SYMBOL`, `SWITCH`, `CONV`, `VALUE`, `REDUCE`
- **String templates**: `|Bug { lv_id } saved|` — no `CONCATENATE`
- **Host variables**: `@lv_var` in all OPEN SQL
- **No MOVE, COMPUTE, WRITE TO** — use modern assignment operators
- **No SELECT ***: always specify field list
- **Error handling**: `TRY ... CATCH cx_root INTO lx_error`
- **Soft delete**: set IS_DEL = 'X', never use DELETE on Z-tables
- **Auto-generate IDs**: `SELECT MAX(bug_id) + 1` pattern (no number range object)

### 8.3 Database Access Pattern

```abap
" Read single record
SELECT SINGLE bug_id, title, status, dev_id
  FROM zbug_tracker
  INTO @DATA(ls_bug)
  WHERE bug_id = @lv_bug_id
    AND is_del <> 'X'.

" Read list with join
SELECT bt~bug_id, bt~title, bt~status, bu~full_name AS dev_name
  FROM zbug_tracker AS bt
  LEFT JOIN zbug_users AS bu ON bu~user_id = bt~dev_id
  INTO TABLE @DATA(lt_bugs)
  WHERE bt~project_id = @lv_project_id
    AND bt~is_del <> 'X'.
```

---

## 9. Screen Layouts

### Screen 0410 — Project Search (Normal, 800×600)

| Element | Type | Name | Position |
|---------|------|------|---------|
| Label | Text | "Project ID:" | Row 3, Col 2 |
| Input | OKCODE-related | `GV_SEARCH_PRJ_ID` | Row 3, Col 15 |
| Label | Text | "Manager:" | Row 5, Col 2 |
| Input | Field | `GV_SEARCH_MGR` | Row 5, Col 15 |
| Label | Text | "Status:" | Row 7, Col 2 |
| Input | Field | `GV_SEARCH_PRJ_STATUS` | Row 7, Col 15 |
| Status Bar | — | PBAR | Bottom |

### Screen 0370 — Status Transition Popup (Modal Dialog, 600×400)

| Element | Type | Name | Notes |
|---------|------|------|-------|
| Text | READ | `GV_POPUP_BUG_ID` | Bug ID — locked |
| Text | READ | `GV_POPUP_TITLE` | Title — locked |
| Text | READ | `GV_POPUP_REPORTER` | Reporter — locked |
| Text | READ | `GV_POPUP_CUR_STATUS` | Current status — locked |
| Dropdown | INPUT | `GV_POPUP_NEW_STATUS` | Available transitions |
| Input | Field | `GV_POPUP_DEV_ID` | Developer (conditional) |
| Input | Field | `GV_POPUP_TESTER_ID` | Final Tester (conditional) |
| Custom Ctrl | Container | `CC_TRANS_NOTE` | Transition note long text |

---

## 10. Message Definition

| Message Class | ID | Type | Text |
|--------------|-----|------|------|
| `ZBUG_MSG` | 001 | S | Bug &1 saved successfully |
| `ZBUG_MSG` | 002 | E | Title is required |
| `ZBUG_MSG` | 003 | E | Evidence required before setting Fixed |
| `ZBUG_MSG` | 004 | E | Transition note required for this status change |
| `ZBUG_MSG` | 005 | S | Status changed: &1 → &2 |
| `ZBUG_MSG` | 006 | W | No available Developer for module &1 — Bug set to Waiting |
| `ZBUG_MSG` | 007 | S | Developer &1 auto-assigned |
| `ZBUG_MSG` | 008 | E | Cannot mark project Done: &1 open bug(s) exist |
| `ZBUG_MSG` | 009 | S | Project &1 saved |
| `ZBUG_MSG` | 010 | E | User &1 not registered in ZBUG_USERS |
| `ZBUG_MSG` | 011 | E | Access denied — role &1 cannot perform this action |
| `ZBUG_MSG` | 012 | S | Email notification sent |
| `ZBUG_MSG` | 013 | E | Cannot delete: project has &1 active bug(s) |

---

## 11. Technical Implementation Notes

### 11.1 Include Dependency Order

```abap
PROGRAM z_bug_workspace_mp.
INCLUDE z_bug_ws_top.   " 1. Global data — MUST be first
INCLUDE z_bug_ws_f00.   " 2. LCL_EVENT_HANDLER class — MUST be before PBO/PAI
INCLUDE z_bug_ws_pbo.   " 3. PBO modules
INCLUDE z_bug_ws_pai.   " 4. PAI modules
INCLUDE z_bug_ws_f01.   " 5. Business logic FORMs
INCLUDE z_bug_ws_f02.   " 6. Helper FORMs
```

### 11.2 ALV Grid Initialisation Pattern

```abap
" Create container + ALV in PBO
IF go_alv_bugs IS INITIAL.
  CREATE OBJECT go_container_bugs
    EXPORTING container_name = 'CC_BUG_LIST'.
  CREATE OBJECT go_alv_bugs
    EXPORTING i_parent = go_container_bugs.
  " Register event handler
  SET HANDLER go_handler->on_double_click FOR go_alv_bugs.
ENDIF.
" Refresh display
CALL METHOD go_alv_bugs->set_table_for_first_display
  EXPORTING i_structure_name = 'ZS_BUG_DISPLAY'
  CHANGING  it_outtab = gt_bugs.
```

### 11.3 Status Transition Validation

```abap
FORM validate_transition
  USING iv_current TYPE zde_bug_status
        iv_new     TYPE zde_bug_status
        iv_role    TYPE zde_bug_role
  CHANGING cv_valid TYPE abap_bool.

  cv_valid = abap_false.
  CASE iv_current.
    WHEN gc_st_new.       " 1 → 2 or W (Manager only)
      IF iv_role = gc_role_manager AND iv_new CA '2W'. cv_valid = abap_true. ENDIF.
    WHEN gc_st_assigned.  " 2 → 3 or R
      IF iv_new = gc_st_inprogress OR iv_new = gc_st_rejected. cv_valid = abap_true. ENDIF.
    WHEN gc_st_inprogress." 3 → 5, 4, R
      IF iv_new CA '54R'. cv_valid = abap_true. ENDIF.
    WHEN gc_st_pending.   " 4 → 2 (Manager only)
      IF iv_role = gc_role_manager AND iv_new = gc_st_assigned. cv_valid = abap_true. ENDIF.
    WHEN gc_st_finaltesting. " 6 → V or 3
      IF iv_new = gc_st_resolved OR iv_new = gc_st_inprogress. cv_valid = abap_true. ENDIF.
    WHEN gc_st_waiting.   " W → 2 or 6 (Manager only)
      IF iv_role = gc_role_manager AND iv_new CA '26'. cv_valid = abap_true. ENDIF.
  ENDCASE.
ENDFORM.
```

### 11.4 Evidence Upload (ZBUG_EVIDENCE)

```abap
" Upload file from frontend to ZBUG_EVIDENCE
DATA: lv_file  TYPE string,
      lt_data  TYPE STANDARD TABLE OF raw255,
      ls_evd   TYPE zbug_evidence.

CALL METHOD cl_gui_frontend_services=>file_open_dialog
  CHANGING file_table = DATA(lt_files).

lv_file = lt_files[ 1 ].
cl_gui_frontend_services=>gui_upload(
  filename = lv_file
  filetype = 'BIN'
  CHANGING data_tab = lt_data ).

" Convert to RAWSTRING and INSERT into ZBUG_EVIDENCE
IMPORT DATA FROM INTERNAL TABLE lt_data TO ls_evd-content.
ls_evd-bug_id       = gs_bug-bug_id.
ls_evd-file_name    = lv_file.
ls_evd-uploaded_by  = sy-uname.
ls_evd-upload_date  = sy-datum.
INSERT zbug_evidence FROM ls_evd.
```

### 11.5 Email via BCS API

```abap
DATA: lo_send_req TYPE REF TO cl_bcs,
      lo_doc      TYPE REF TO cl_document_bcs,
      lo_addr     TYPE REF TO cl_sapuser_bcs.

lo_send_req = cl_bcs=>create_instance( ).
lo_doc = cl_document_bcs=>create_document(
           i_type    = 'RAW'
           i_subject = |Bug { gs_bug-bug_id } status: { lv_new_status }|
           i_text    = lt_body ).
lo_send_req->set_document( lo_doc ).
lo_addr = cl_sapuser_bcs=>create_instance( i_user = gs_bug-dev_id ).
lo_send_req->add_recipient( i_recipient = lo_addr ).
lo_send_req->send( ).
COMMIT WORK.
```
