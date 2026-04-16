// ============================================================
// 06_release.typ — VI. Release Package & User Guides
// ============================================================
#import "../template.typ": placeholder, hline, field, diagram-placeholder

= VI. Release Package & User Guides

== 1. Release Package

The components below pertain to version v5.0 of the SAP Bug Tracking Management System (`ZBUG_WS`), implemented as Module Pool program `Z_BUG_WORKSPACE_MP` in SAP package `ZBUGTRACK`.

#table(
  columns: (auto, 3.5cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*No.*], [*Item*], [*Description*], [*Version*],
  [1], [ABAP Include `Z_BUG_WS_TOP`], [Global declarations, types, constants for the 10-state lifecycle (`gc_st_new` through `gc_st_resolved`), all ALV/GUI container objects, dashboard metric variables, Screen 0370/0410/0210/0220 field variables], [v5.0],
  [2], [ABAP Include `Z_BUG_WS_F00`], [ALV field catalog definitions for 5 ALV grids; `LCL_EVENT_HANDLER` class implementing hotspot-click and double-click events for Bug List and Project List], [v5.0],
  [3], [ABAP Include `Z_BUG_WS_PBO`], [Process Before Output modules for all 9 screens; dashboard calculation call in `status_0200`; screen group logic via `LOOP AT SCREEN` for role-based field control], [v5.0],
  [4], [ABAP Include `Z_BUG_WS_PAI`], [Process After Input modules; all fcode handlers; status transition popup call (`CALL SCREEN 0370`); bug search engine trigger (`CALL SCREEN 0210`)], [v5.0],
  [5], [ABAP Include `Z_BUG_WS_F01`], [Business logic FORMs: `save_bug_detail`, `save_project_detail`, `change_bug_status`, `auto_assign_developer` (Phase A), `auto_assign_tester` (Phase B), `upload_evidence_file`, `send_email_bcs`, `log_history`, `calculate_dashboard`], [v5.0],
  [6], [ABAP Include `Z_BUG_WS_F02`], [Helper FORMs: 10 F4 search help routines, `load_long_text` / `save_long_text` (long text API), `download_smw0_template` wrapper, `upload_excel_projects` parser], [v5.0],
  [7], [DB Table `ZBUG_TRACKER`], [Primary bug tracking table --- 29 fields. Domain `zde_bug_status` is CHAR 20 (not CHAR 1); STATUS field stores 10-state lifecycle codes (1, 2, 3, 4, 5, 6, 7, R, V, W)], [v5.0],
  [8], [DB Table `ZBUG_PROJECT`], [Project master --- 16 fields including soft-delete flag `IS_DEL` and full audit trail (ERNAM, ERDAT, AENAM, AEDAT)], [v5.0],
  [9], [DB Table `ZBUG_USERS`], [User registry --- 12 fields including `ROLE` (M/D/T), `SAP_MODULE`, `IS_ACTIVE`, `IS_DEL`, and `EMAIL` for notification], [v5.0],
  [10], [DB Table `ZBUG_USER_PROJEC`], [User-to-project M:N assignment --- 10 fields; `ROLE` column per project; basis for auto-assign filtering and role-based project visibility], [v5.0],
  [11], [DB Table `ZBUG_HISTORY`], [Change log --- 10 fields; records all status transitions and field updates with `OLD_STATUS`, `NEW_STATUS`, `ACTION` (ST/CR/UP), `REASON` (STRING), and timestamps], [v5.0],
  [12], [DB Table `ZBUG_EVIDENCE`], [Binary file storage --- 11 fields; `CONTENT` as RAWSTRING; `MIME_TYPE` (CHAR 100), `FILE_SIZE` (INT4), `FILE_NAME` (CHAR 255)], [v5.0],
  [13], [Screen Guides (8 screens)], [SE51 layout guides under `screens/` directory for screens 0200, 0210, 0220, 0300 (+ 6 subscreens 0310--0360), 0370, 0400, 0410, 0500 --- field lists, Custom Control names, flow logic], [v5.0],
  [14], [QC Test Plan + UAT Script], [QC Test Plan: 20 suites (TC-01 to TC-20), approximately 210 individual test cases covering all screens, transitions, edge cases, and RBAC. UAT Happy Case Script: 64 cases across 14 workflow categories (A--N) for Manager, Developer, and Tester roles], [v5.0],
  [15], [Final Report Document], [This document (FPT Capstone Final Report) --- covers Introduction, Project Management, Requirements, Design, Testing, and Release sections], [v5.0],
  [16], [SMW0 Templates (3 files)], [`ZBT_TMPL_01` → `Bug_report.xlsx` (Tester bug report); `ZBT_TMPL_02` → `fix_report.xlsx` (Developer fix evidence); `ZBT_TMPL_03` → `confirm_report.xlsx` (Final Tester sign-off)], [v5.0],
  [17], [Test Data Report], [`Z_BUG_POPULATE_TESTDATA` --- SE38 executable report creating 20 mock Developers + 10 mock Testers across FI/MM/SD/ABAP modules with project assignments for auto-assign algorithm testing], [v5.0],
  [18], [Status Migration Script], [One-time ABAP migration: updates all records with `STATUS = '6'` (legacy status code) to `STATUS = 'V'` (Resolved) via `UPDATE zbug_tracker SET status = 'V' WHERE status = '6' AND is_del <> 'X'` followed by `COMMIT WORK`], [v5.0],
)

== 2. Installation Guides

=== 2.1 System Requirements

#table(
  columns: (auto, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*No.*], [*Component*], [*Requirement*], [*Version / Value*],
  [1], [SAP System], [SAP ERP with full ABAP Workbench (SE11, SE38/SE80, SE51, SE41, SE93, SE37, SM30 available)], [S40],
  [2], [SAP Basis], [SAP_BASIS 770 or higher --- required for ABAP 7.70 syntax (inline `DATA`, `SWITCH`, `CONV`, `@` host variables, string template `|...|`)], [770+],
  [3], [SAP Client], [Dedicated development/test client with Table Maintenance Generator accessible for `ZBUG_USERS` via SM30], [Client 324],
  [4], [Email (SOST)], [SOST / BCS API configured with valid SMTP profile for outgoing email notifications to Developer and Tester], [Pre-configured],
  [5], [Web Repository (SMW0)], [SMW0 repository accessible; `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03` objects created and Excel files uploaded], [Active],
  [6], [Number Range Objects], [`ZNR_BUGS` (10-digit Bug ID, format `BUG0000001`) and `ZNR_PROJECTS` (10-digit Project ID, format `PRJ0000001`) must exist in `SNRO`], [Pre-configured],
  [7], [Text Object], [`ZBUG` text object registered in `SE75` for `READ_TEXT`/`SAVE_TEXT` long text storage (Description, Dev Note, Tester Note)], [Pre-configured],
  [8], [Development Package], [`ZBUGTRACK` package must exist in SE80; all program objects assigned to this package], [Active],
)

=== 2.2 Installation Steps

The following steps deploy `Z_BUG_WORKSPACE_MP` v5.0 into the SAP system. Execute in the listed order. Steps F11--F17 correspond to Phase F deployment tasks.

*Step F11 --- Create 4 New Screens in SE51:*

+ Open transaction *SE51*. Set Program = `Z_BUG_WORKSPACE_MP`.
+ *Screen 0410* (Normal screen): Create screen, set short description "Project Search". In the layout, add 3 input fields: `S_PRJ_ID` (label "Project ID"), `S_PRJ_MN` (label "Manager"), `S_PRJ_ST` (label "Status"). In Flow Logic, add: PBO → `MODULE status_0410 OUTPUT`; PAI → `MODULE user_command_0410 INPUT`; POV → F4 modules for all 3 fields. Activate.
+ *Screen 0370* (Modal Dialog Box, ~80 columns × 20 rows): Add read-only display fields for `gv_trans_bug_id`, `gv_trans_title`, `gv_trans_reporter`, `gv_trans_cur_st_text`. Add input fields: `gv_trans_new_status` (label "New Status"), `gv_trans_dev_id` (label "Developer"), `gv_trans_ftester_id` (label "Final Tester"). Add Custom Control named `CC_TRANS_NOTE`. Flow Logic: PBO → `status_0370`, `init_trans_popup`; PAI → `user_command_0370`; POV → F4 modules. Activate.
+ *Screen 0210* (Modal Dialog Box, ~70 columns × 15 rows): Add 7 input fields: `s_bug_id`, `s_title`, `s_status`, `s_prio`, `s_mod`, `s_reporter`, `s_dev`. Flow Logic: PBO → `status_0210`; PAI → `user_command_0210`; POV → F4 modules. Activate.
+ *Screen 0220* (Normal screen): Add Custom Control named `CC_SEARCH_RESULTS`. Flow Logic: PBO → `status_0220 OUTPUT`, `display_search_alv OUTPUT`; PAI → `user_command_0220 INPUT`. Activate.

*Step F12 --- Create GUI Statuses and Title Bars in SE41:*

+ Open transaction *SE41*. Set Program = `Z_BUG_WORKSPACE_MP`.
+ Create GUI Status `STATUS_0410`: Application Toolbar with buttons Execute (fcode `EXECUTE`, F8), Back (fcode `BACK`, F3), Exit (fcode `EXIT`, Shift+F3), Cancel (fcode `CANCEL`, F12). Create Title Bar `T_0410` with text "Project Search". Activate both.
+ Create GUI Status `STATUS_0370`: Application Toolbar with Confirm (fcode `CONFIRM`), Upload Evidence (fcode `UP_TRANS`), Cancel (fcode `CANCEL`, F12). Create Title Bar `T_0370` with text "Change Bug Status". Activate.
+ Create GUI Status `STATUS_0210`: Application Toolbar with Execute (fcode `EXECUTE`, F8) and Cancel (fcode `CANCEL`, F12). Create Title Bar `T_0210` with text "Bug Search". Activate.
+ Create GUI Status `STATUS_0220`: Application Toolbar with Back (fcode `BACK`, F3), Exit (fcode `EXIT`, Shift+F3), Cancel (fcode `CANCEL`, F12). Create Title Bar `T_0220` with text "Search Results". Activate.
+ Update existing GUI Status `STATUS_0200`: add button Search (fcode `SEARCH`) to the Application Toolbar. Re-activate.

*Step F13 --- Copy v5.0 ABAP Code into SAP:*

+ Open transaction *SE80* or *SE38*.
+ For each of the 6 includes listed below, open the include program in SE38, paste the v5.0 source code, then check (Ctrl+F2) and activate (Ctrl+F3):

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  [*SAP Include Program*], [*Content Summary*],
  [`Z_BUG_WS_TOP`], [Global declarations, types, constants, ALV objects],
  [`Z_BUG_WS_F00`], [ALV field catalog, `LCL_EVENT_HANDLER` class],
  [`Z_BUG_WS_PBO`], [Process Before Output modules (all 9 screens)],
  [`Z_BUG_WS_PAI`], [Process After Input modules, all fcode handlers],
  [`Z_BUG_WS_F01`], [Business logic FORMs: save, status change, auto-assign, email],
  [`Z_BUG_WS_F02`], [Helper FORMs: F4, long text API, popup, template download],
)

+ After all 6 includes are copied, open the main program `Z_BUG_WORKSPACE_MP` in SE80 and perform a mass activation (select all objects → Activate). Resolve any syntax errors before proceeding.

*Step F14 --- Update T-code Initial Screen in SE93:*

+ Open transaction *SE93*. Enter `ZBUG_WS` → Change.
+ Under "Default values", change field "Screen number" from `0400` to `0410`.
+ Save and activate. Run `/nZBUG_WS` to confirm Screen 0410 appears as the first screen.

*Step F15 --- Create `ZBUG_EVIDENCE` Table (if not already present):*

+ Open transaction *SE11*. Create database table `ZBUG_EVIDENCE` with 11 fields as listed below. Key fields: `CLIENT` (MANDT, CLNT 3, Key), `EVD_ID` (CHAR 10, Key). The `CONTENT` field must use type `RAWSTRING` (binary blob). Additional fields: `BUG_ID` (CHAR 10), `FILE_NAME` (CHAR 255), `MIME_TYPE` (CHAR 100), `FILE_SIZE` (INT4), `ERNAM` (CHAR 12), `ERDAT` (DATS 8), `ERZET` (TIMS 6), `EVD_TYPE` (CHAR 1 --- R=Report, F=Fix, V=Verify). Activate the table and generate the Table Maintenance Generator if needed.

*Step F16 --- Run Status Migration Script:*

+ Open *SE38*. Create a temporary report and run the following ABAP:

```abap
UPDATE zbug_tracker SET status = 'V'
  WHERE status = '6' AND is_del <> 'X'.
COMMIT WORK.
WRITE: / 'Migrated', sy-dbcnt, 'records from status 6 to V.'.
```

+ Verify via *SE16N* on `ZBUG_TRACKER` that no records remain with `STATUS = '6'`. After verification, delete the temporary report.

*Step F17 --- Upload SMW0 Templates:*

+ Open transaction *SMW0*. Navigate to "Binary data for WebRFC applications".
+ Upload the 3 Excel template files to the corresponding objects:
  - Object `ZBT_TMPL_01` ← `Bug_report.xlsx` (Tester bug report template)
  - Object `ZBT_TMPL_02` ← `fix_report.xlsx` (Developer fix evidence template)
  - Object `ZBT_TMPL_03` ← `confirm_report.xlsx` (Final Tester sign-off template)
+ Save and activate all 3 objects.

*Deployment Verification:* After completing all steps, run `/nZBUG_WS`. Confirm Screen 0410 (Project Search) appears first. Press Execute → Screen 0400 shows filtered project list. Click a project → Screen 0200 shows bug list with Dashboard header. Select a bug in Change mode → click "Change Status" → Screen 0370 popup opens with correct bug info and status dropdown.

== 3. User Manual

=== 3.1 Overview

The SAP Bug Tracking Management System (`ZBUG_WS`) is a centralized defect tracking application built natively on SAP ERP using ABAP Module Pool programming. The system supports three user roles --- *Manager*, *Developer*, and *Tester* --- each with distinct permissions enforced at the screen group and fcode level.

*System entry:* Transaction code `ZBUG_WS` → Screen 0410 (Project Search)

*Screen map:*

#table(
  columns: (1.5cm, 2.5cm, 1fr),
  align: (center, left, left),
  [*Screen*], [*Name*], [*Purpose*],
  [0410], [Project Search], [Initial screen: filter accessible projects before entering the list (New in v5.0)],
  [0400], [Project List], [ALV grid of projects; create/change/delete projects; launch My Bugs],
  [0200], [Bug List + Dashboard], [Bug listing for a selected project with real-time status / priority / module metrics],
  [0300], [Bug Detail], [Create/view/edit a bug; 6-tab strip: Bug Info, Description, Dev Note, Tester Note, Evidence, History],
  [0370], [Status Transition Popup], [Change bug status via 10-state matrix; validates role and required fields (New in v5.0)],
  [0500], [Project Detail], [Manage project metadata and assign/remove users from a project (Manager only)],
  [0210/0220], [Bug Search], [Search bugs by keyword, status, priority, module, or reporter across the current project],
)

*10-State Bug Lifecycle (v5.0):*

#diagram-placeholder("10-State Bug Lifecycle (v5.0)", "docs/diagrams/bug-lifecycle.mmd")

Note: `Closed (7)` is a legacy terminal state retained for backward compatibility.

=== 3.2 Workflow 1 --- Bug Reporting (Tester Role)

*Purpose:* A Tester discovers a defect during SAP system testing, logs it in the system, and attaches supporting evidence.

*Prerequisites:* Logged in with a Tester account (role `T` in `ZBUG_USERS`); at least one project exists with this Tester assigned.

*Steps:*

+ Run transaction `/nZBUG_WS`. Screen 0410 (Project Search) appears with three filter fields.
+ Press *Execute* (F8) to list all accessible projects (or enter a Project ID filter first). Screen 0400 shows the project list.
+ Double-click the target project row. Screen 0200 opens, showing all bugs for that project and the real-time Dashboard header.
+ Click the *Create* button in the toolbar. Screen 0300 opens in Create mode.
+ On the *Bug Info* tab, fill in the required fields:
  - *Title*: concise defect description (required, max 100 characters)
  - *SAP Module*: press F4 to select from FI / MM / SD / ABAP / Basis / PP / HR / QM
  - *Priority*: press F4 to select H (High) / M (Medium) / L (Low)
  - *Severity*: press F4 to select 1 (Dump/Critical) through 5 (Minor)
  - *Bug Type*: press F4 to select 1 (Functional) through 5 (Security)
  - *Project ID*: pre-filled and locked from the project context (cannot be changed)
+ Switch to the *Description* tab: enter a full description of the defect using the text editor.
+ Switch to the *Evidence* tab: click *Upload Evidence* → select a screenshot or log file from the local PC. The file is stored in `ZBUG_EVIDENCE` and appears as a new row in the Evidence table.
+ Click *Save*. The system auto-generates a `BUG_ID` (format `BUG0000001`) and immediately runs the auto-assign engine:
  - *If a matching Developer is found* (same SAP Module, active in the project, workload < 5 bugs): `DEV_ID` is filled, status becomes *Assigned (2)*.
  - *If no matching Developer is available*: status becomes *Waiting (W)* and a notification message is shown.
+ The bug now appears in the Bug List on Screen 0200. Dashboard counters update accordingly.

=== 3.3 Workflow 2 --- Bug Resolution (Developer Role)

*Purpose:* A Developer picks up an assigned bug, investigates, applies a fix, uploads fix evidence, and marks the bug as Fixed.

*Prerequisites:* Logged in with a Developer account (role `D` in `ZBUG_USERS`); at least one bug is assigned with `DEV_ID` matching the current user.

*Steps:*

+ Run `/nZBUG_WS` → Execute → click the relevant project. On Screen 0200, find the assigned bug (status = Assigned).
  - Alternatively, click *My Bugs* on the Screen 0400 toolbar to see only bugs where `DEV_ID = current user`.
+ Select the bug → click *Change*. Screen 0300 opens in Change mode.
+ Click the *Change Status* button. Popup Screen 0370 opens displaying the bug's current information:
  - Read-only fields: Bug ID, Title, Reporter, Current Status ("Assigned")
  - Dropdown: *New Status* --- press F4, select "In Progress (3)"
  - Click *Confirm*. Status changes to In Progress.
+ Investigate the defect. Document findings and the fix approach in the *Dev Note* tab (text editor).
+ Switch to the *Evidence* tab and click *Upload Fix* → select the fix proof file (e.g., `fix_report.xlsx`). At least one evidence file must exist before the Fixed transition is allowed.
+ Click *Change Status* again. In popup 0370:
  - Press F4 on New Status → select "Fixed (5)"
  - Click *Confirm*. The system validates that at least one evidence file exists in `ZBUG_EVIDENCE`. On success:
    - Status changes to Fixed (5).
    - Auto-Assign Phase B triggers immediately: the system searches for a Tester with matching `SAP_MODULE` in the project and workload < 5 active Final Testing bugs.
    - *If a Tester is found*: `VERIFY_TESTER_ID` is set, status advances to *Final Testing (6)*.
    - *If no Tester is available*: status becomes *Waiting (W)*.
+ A history record is written to `ZBUG_HISTORY` for the Fixed transition. The bug responsibility transfers to the assigned Tester.

=== 3.4 Workflow 3 --- Project Management (Manager Role)

*Purpose:* A Manager creates a new project, assigns the development team, monitors bug progress using the Dashboard, and closes the project when all bugs are resolved.

*Steps --- Create Project and Assign Team:*

+ Run `/nZBUG_WS` → Execute (F8) on Screen 0410 to view all projects. Screen 0400 opens.
+ Click *Create Project* in the toolbar. Screen 0500 opens in Create mode.
+ Fill in the project fields:
  - *Project Name*: required
  - *Start Date* / *End Date*: press F4 for a calendar picker
  - *Project Status*: defaults to "1 --- Opening"
  - *Project Manager*: pre-filled with the current user's ID
+ Click *Save*. A `PROJECT_ID` is auto-generated (format `PRJ0000001`). Mode switches to Change.
+ In the *User Assignment* Table Control at the bottom of Screen 0500:
  - Click *Add User* → enter User ID (press F4 to browse `ZBUG_USERS`) and Role (M/D/T)
  - Repeat for each team member (Developers, Testers, co-Managers as needed)
  - Save after each addition
+ Click *Back* to return to Screen 0400. The new project appears in the list.

*Steps --- Monitor Bug Progress:*

+ On Screen 0400, click the project row to open Screen 0200 (Bug List + Dashboard).
+ The Dashboard header at the top of Screen 0200 displays real-time metrics:
  - *Total Bugs*: total bug count in this project
  - *By Status*: count per lifecycle state (New / Assigned / In Progress / Fixed / Final Testing / Resolved / Waiting / Rejected)
  - *By Priority*: High / Medium / Low counts
  - *By Module*: FI / MM / SD / ABAP / Basis counts
+ Click *Refresh* in the toolbar at any time to reload bug data and recalculate the Dashboard.
+ Click *Search* to open the Bug Search popup (Screen 0210): enter up to 6 search criteria (Bug ID, title keyword, status, priority, module, reporter). Screen 0220 shows filtered results without a dashboard.
+ A Manager can perform manual status transitions on any bug: select bug → Change → *Change Status* → Screen 0370 popup → select any valid transition per the matrix → Confirm.

*Steps --- Close Project:*

+ On Screen 0400, select the project → *Change*. Screen 0500 opens.
+ In the *Project Status* field, select "3 --- Done".
+ Click *Save*. The system validates that all bugs in this project are in terminal states (Resolved V, Rejected R, or Closed 7).
  - *If open bugs exist*: message "Cannot set project to Done. N bug(s) not yet Resolved/Closed." Save is rejected.
  - *If all bugs are terminal*: project status changes to Done; save succeeds.
+ Return to Screen 0410 and filter by Status = "3 --- Done" to confirm the project is closed.
