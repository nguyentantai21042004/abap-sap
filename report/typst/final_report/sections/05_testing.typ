// ============================================================
// 05_testing.typ — V. Software Testing Documentation
// ============================================================
#import "../template.typ": placeholder, hline, field

= V. Software Testing Documentation

== 1. Scope of Testing

=== 1.1 Target-of-Test Features

The testing scope covers the SAP Bug Tracking Management System (`ZBUG_WS` v5.0), implemented as a Module Pool program (`Z_BUG_WORKSPACE_MP`) on SAP System S40, Client 324. All functional screens, business rules, and role-based access controls are in scope.

*In-scope features:*

#table(
  columns: (0.5cm, 3.5cm, 1fr),
  align: (center, left, left),
  [*No.*], [*Feature Area*], [*Description*],
  [1], [Navigation Flow], [All screen-to-screen transitions across the 9-screen application (0410 -- 0400 -- 0200 -- 0300 -- 0370)],
  [2], [Project Search (0410)], [New initial screen: 3 filter fields (Project ID, Manager, Status); role-based project visibility],
  [3], [Project List (0400)], [ALV grid with CRUD operations; soft-delete; Excel template download and upload],
  [4], [Project Detail (0500)], [Create/Change/Display project; user assignment via Table Control `TC_USERS`],
  [5], [Bug List + Dashboard (0200)], [ALV grid with real-time dashboard; dual-mode (Project view / My Bugs)],
  [6], [Bug Detail (0300)], [6-tab strip (Bug Info, Description, Dev Note, Tester Note, Evidence, History); field-level role control via screen groups],
  [7], [Status Transition Popup (0370)], [10-state lifecycle enforced via popup; role-based transition matrix; required fields per transition],
  [8], [Auto-Assign Engine], [Phase A: auto-assign Developer on bug creation; Phase B: auto-assign Tester on Fixed transition],
  [9], [Bug Search (0210/0220)], [Popup search input (6 fields); full-screen results without dashboard],
  [10], [Evidence Management], [Upload / Download / Delete evidence files; MIME type detection; `EVD_ID` auto-increment],
  [11], [Email Notification], [BCS API email to assigned Developer and Tester (excluding current user)],
  [12], [Template Downloads], [SMW0 templates: `Bug_report.xlsx`, `fix_report.xlsx`, `confirm_report.xlsx`],
  [13], [Role-Based Access Control], [3 roles (Manager, Developer, Tester); field editability via screen groups; button visibility per role],
  [14], [Field Validation and Business Rules], [Severity/Priority consistency; required fields; unsaved changes detection; error message behavior],
  [15], [F4 Search Help], [Dropdown helpers on all key fields across screens 0300, 0410, 0370],
)

*Out-of-scope:*

- Performance load testing (multi-user concurrency scenarios)
- Network-level security penetration testing
- External SMTP server configuration (assumed pre-configured via SOST)
- SAP Basis-level authorization objects (`S_TCODE`, `S_DEVELOP`)

=== 1.2 Test Levels

Testing is conducted at four levels:

+ *Unit Testing* --- Individual FORM routines and PAI modules tested in isolation using SAP SE37 and SE38 (e.g., `auto_assign_developer`, `validate_status_transition`, `calculate_dashboard`).
+ *Integration Testing* --- Screen-to-screen navigation flows and database read/write interactions verified (e.g., Custom Control lifecycle: create on PBO, free on Back; ALV refresh after status change).
+ *System Testing* --- End-to-end workflows executed under all three user roles on a live SAP client (20-suite QC test plan).
+ *Acceptance Testing* --- Business-facing UAT happy-case scenarios validated by all three project members.

=== 1.3 Constraints and Assumptions

- All tests execute on SAP System S40, Client 324 (non-production environment).
- Test accounts `DEV-089`, `DEV-061`, `DEV-118` must have correct role assignments in `ZBUG_USERS` prior to testing (verified 11/04/2026).
- Auto-assign tests (TC-09) require additional mock users created by the test data report `Z_BUG_POPULATE_TESTDATA` (20 Developers + 10 Testers across FI/MM/SD/ABAP modules).
- Status migration script (old `status = '6'` Resolved → new `status = 'V'` Resolved) must be executed before regression testing of the v5.0 lifecycle (TC-19.20).
- v5.0 deployment (screens, GUI Statuses, updated ABAP code) must be complete before the full QC test run can proceed.

== 2. Test Strategy

=== 2.1 Testing Types

#table(
  columns: (0.5cm, 3cm, 1fr, 2.5cm, 2.5cm),
  align: (center, left, left, left, left),
  [*No.*], [*Type*], [*Objective*], [*Technique*], [*Completion Criteria*],
  [1], [Functional Testing], [Verify each screen, button, and business rule behaves per the requirements specification], [Black-box: provide input, verify expected output; switch between 3 role accounts to test RBAC], [All test cases across 20 TC suites pass with no critical (blocking) failures],
  [2], [Regression Testing], [Confirm that v4.x bug fixes and v5.0 enhancements do not reintroduce previously resolved defects], [Re-execute TC-19 (19 cases: 8 v4.x bugs + 11 v5.0 UAT bugs) after deployment], [All 19 regression cases pass; no prior defect reappears in the v5.0 build],
  [3], [Acceptance Testing (UAT)], [Validate that the deployed system meets business workflow requirements from an end-user perspective], [Happy-case walkthrough by all 3 roles following the UAT happy-case script (64 cases across 14 categories)], [All 64 UAT cases pass; no critical blockers remain; all 3 role members sign off],
)

=== 2.2 Test Levels

#table(
  columns: (0.5cm, 2.5cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*No.*], [*Level*], [*Description*], [*Test Types Applied*],
  [1], [Unit], [Individual FORM routines tested in isolation --- `auto_assign_developer`, `validate_status_transition`, `calculate_dashboard`, `f4_trans_status`; DB read/write operations verified via SE16N], [Functional],
  [2], [Integration], [Screen navigation flows verified end-to-end; Custom Control lifecycle (create/free); ALV refresh after data changes; DB consistency after status transitions], [Functional, Regression],
  [3], [System], [Full end-to-end scenarios under all 3 roles on SAP S40/324; 20-suite QC Test Plan executed systematically by QC lead], [Functional, Regression],
  [4], [Acceptance], [Business-facing happy-case scenarios: project lifecycle (Manager), bug reporting (Tester), bug resolution (Developer), status transitions across the full 10-state lifecycle], [Acceptance (UAT)],
)

=== 2.3 Supporting Tools

#table(
  columns: (0.5cm, 3.5cm, 1fr),
  align: (center, left, left),
  [*No.*], [*Tool*], [*Purpose*],
  [1], [SAP SE38 / SE80], [ABAP code editing, syntax check, and activation of all 6 program includes],
  [2], [SAP SE37], [Unit testing of individual Function Modules: `READ_TEXT`, `SAVE_TEXT`, `F4IF_INT_TABLE_VALUE_REQUEST`, BCS email APIs],
  [3], [SAP SE16N], [Direct database table inspection --- verify DB state after each Create/Update/Delete operation on `ZBUG_TRACKER`, `ZBUG_HISTORY`, `ZBUG_EVIDENCE`],
  [4], [SAP SOST], [Verify outgoing email queue; confirm BCS API email delivery is queued for assigned users],
  [5], [SAP SE51], [Screen layout verification; Custom Control placement; flow logic syntax check for all 9 screens],
  [6], [SAP SE41], [GUI Status and Title Bar inspection; fcode assignment; button visibility validation],
  [7], [SAP SE93], [Verify T-code `ZBUG_WS` initial screen is set to 0410 (v5.0 requirement)],
  [8], [SAP SM50 / SM04], [Session and process monitoring during multi-tab switch stress tests (TC-07.15, TC-20.07)],
)

== 3. Test Plan

=== 3.1 Human Resources

#table(
  columns: (0.5cm, 2cm, 2.5cm, 1fr),
  align: (center, left, left, left),
  [*No.*], [*Account*], [*Role*], [*Testing Responsibilities*],
  [1], [`DEV-118`], [QC Lead / Tester], [Primary test executor for all 20 TC suites; reports defects with screenshots; validates v5.0 behavior as Tester role (bug creation, evidence upload, Final Testing transition)],
  [2], [`DEV-089`], [Manager], [Co-tester for Manager-role test cases: TC-02 (Project Search), TC-03/04 (Project CRUD), TC-08 Manager transitions, TC-15 RBAC; validates project lifecycle completion rules],
  [3], [`DEV-061`], [Developer], [Co-tester for Developer-role test cases: TC-08 Dev transitions (Assigned → In Progress → Fixed), TC-09 Auto-Assign, TC-12 Evidence (Upload Fix, Download)],
)

=== 3.2 Test Environment

#table(
  columns: (0.5cm, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*No.*], [*Component*], [*Details*], [*Status*],
  [1], [SAP System], [S40 --- dedicated internal development and test system], [Ready],
  [2], [SAP Client], [324 (test client; Table Maintenance Generator available via SM30)], [Ready],
  [3], [ABAP Version], [7.70 (SAP_BASIS 770) --- supports inline declarations, SWITCH expression, @ host variables, string templates], [Verified],
  [4], [Development Package], [`ZBUGTRACK` --- contains all program objects (screens, includes, GUI Statuses)], [Active],
  [5], [Network], [EBS_SAP internal network], [Ready],
  [6], [Test Accounts], [`DEV-089` (Manager), `DEV-061` (Developer), `DEV-118` (Tester) --- roles verified in `ZBUG_USERS` on 11/04/2026], [Verified],
  [7], [Auto-Assign Test Data], [20 mock Developers + 10 mock Testers across FI/MM/SD/ABAP modules; created by report `Z_BUG_POPULATE_TESTDATA`; assigned to a test project via `ZBUG_USER_PROJEC`], [Pending],
  [8], [SMW0 Templates], [3 Excel templates uploaded: `ZBT_TMPL_01` (Bug_report.xlsx), `ZBT_TMPL_02` (fix_report.xlsx), `ZBT_TMPL_03` (confirm_report.xlsx)], [Pending],
)

=== 3.3 Test Milestones

#table(
  columns: (0.5cm, 3.5cm, 2cm, 2cm, 1fr),
  align: (center, left, center, center, left),
  [*No.*], [*Milestone*], [*Start Date*], [*End Date*], [*Deliverable*],
  [1], [Test Environment Setup], [01/04/2026], [11/04/2026], [`ZBUG_USERS` role assignments verified; test accounts confirmed; SE16N screenshots captured],
  [2], [UAT Round 1 (v4.2 build)], [11/04/2026], [13/04/2026], [64 UAT happy cases executed; 11 defects identified and documented in the v5.0 Defect Analysis document],
  [3], [v5.0 Bug Analysis & Design], [13/04/2026], [14/04/2026], [Root-cause analysis and fix proposals for all 11 UAT defects; Phase F v5.0 architecture finalized],
  [4], [v5.0 Code Development (F10)], [14/04/2026], [16/04/2026], [All 6 ABAP includes (`Z_BUG_WS_TOP` through `Z_BUG_WS_F02`) updated to v5.0; verified complete on 16/04/2026],
  [5], [v5.0 Deployment to SAP (F11--F17)], [Post 16/04/2026], [TBD], [4 new screens (SE51), 4 GUI Statuses + 4 Title Bars (SE41), SE93 initial screen update, `ZBUG_EVIDENCE` table, migration script, SMW0 templates],
  [6], [Full QC Test Run --- 20 Suites], [After Deployment], [TBD], [Approximately 210 test cases executed; defect report; pass/fail statistics per suite],
  [7], [UAT Round 2 (v5.0 build)], [After QC Run], [TBD], [64 UAT happy cases re-executed on deployed v5.0 system; all 3 members sign off; final acceptance],
)

== 4. Test Cases

Test cases are organized into 20 suites (TC-01 to TC-20), totaling approximately 210 individual cases. Detailed test case steps and expected results are maintained in the QC Test Plan document. UAT happy cases (64 cases across 14 workflow categories, A--N) are documented in the UAT Happy Case Script.

*Test Suite Summary:*

#table(
  columns: (0.5cm, 1.5cm, 3.5cm, 1fr, 1.5cm),
  align: (center, center, left, left, center),
  [*No.*], [*TC ID*], [*Suite Name*], [*Coverage*], [*Cases*],
  [1], [TC-01], [Navigation Flow], [All screen transitions: 0410→0400→0200→0300→0370; Back/Exit/Cancel from every screen], [20],
  [2], [TC-02], [Screen 0410 -- Project Search], [Filter by Project ID / Manager / Status; role-based project visibility; F4 help on 3 fields], [14],
  [3], [TC-03], [Screen 0400 -- Project List], [ALV display; Project CRUD; soft-delete; Refresh; non-Manager restriction], [12],
  [4], [TC-04], [Screen 0500 -- Project Detail], [Create/Change/Display; user assignment Table Control; F4 calendar; non-Manager blocking], [25],
  [5], [TC-05], [Screen 0200 -- Bug List + Dashboard], [Dual-mode (Project / My Bugs); dashboard accuracy; Bug CRUD; ALV row coloring], [18],
  [6], [TC-06], [Screen 0300 -- Bug Detail], [Create/Change/Display; STATUS always locked; display text mapping for all 10 states], [18],
  [7], [TC-07], [Tab Strip and Subscreens], [All 6 tabs; data persistence on switch; role-specific editor read-only; crash prevention], [15],
  [8], [TC-08], [Status Transition (10-State + Popup 0370)], [All valid transitions; blocked/invalid transitions; required fields per transition; history logging], [30],
  [9], [TC-09], [Auto-Assign System], [Phase A (Developer): module match + workload < 5; Phase B (Tester): same logic on Fixed transition], [9],
  [10], [TC-10], [Bug Search (Screens 0210/0220)], [All 6 search fields; wildcard title; combined filters; results ALV; back navigation], [15],
  [11], [TC-11], [Dashboard Metrics], [Count accuracy per status / priority; sum validation (status sum = Total); real-time refresh], [12],
  [12], [TC-12], [Evidence Management], [Upload (generic / report / fix); download; delete; MIME detection; `EVD_ID` auto-increment; popup upload], [12],
  [13], [TC-13], [Email Notification], [BCS API send; no-recipient handling; current-user exclusion from recipient list; SOST verification], [4],
  [14], [TC-14], [Template Download and Upload], [3 SMW0 template downloads; Excel project upload; duplicate/invalid record handling], [11],
  [15], [TC-15], [Role-Based Access Control], [Field editability by role (FNC/DEV/TST groups); button visibility per role (Create/Delete/Upload)], [16],
  [16], [TC-16], [Field Validation and Business Rules], [Severity/Priority consistency rule; required fields; long text persistence; error message does not lock fields], [9],
  [17], [TC-17], [Unsaved Changes Detection], [Save/Discard/Cancel popup; snapshot comparison; mini editor text sync before compare], [9],
  [18], [TC-18], [F4 Search Help], [All F4 helpers on screens 0300 (9 fields), 0410 (3 fields), 0370 (3 fields); value fill-back], [16],
  [19], [TC-19], [Regression -- Fixed Bugs v4.x + v5.0], [8 v4.x bugs + 11 v5.0 UAT bugs: verify none reappear in the v5.0 build], [19],
  [20], [TC-20], [Edge Cases and Boundary Testing], [Empty DB; max-length fields; large file upload; memory leak on Back; unregistered user handling], [20],
  [], [], [*Total (estimated)*], [], [*~210*],
)

== 5. Test Reports

=== 5.1 UAT Round 1 --- Phase E Results (11--13 April 2026)

UAT Round 1 was conducted in Phase E on the v4.2 deployed build (SAP System S40, Client 324). All three project members participated as their designated roles, following the UAT happy-case script (64 cases across 14 categories).

*Summary:*

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr),
  align: center,
  [*Total Cases*], [*Passed*], [*Failed*], [*Blocked*], [*Defects Found*],
  [64], [53], [11], [0], [11],
)

*Defects Found in UAT Round 1:*

#table(
  columns: (0.7cm, 1.2cm, 1fr, 2.5cm),
  align: (center, center, left, center),
  [*No.*], [*Bug ID*], [*Defect Description*], [*Severity*],
  [1], [UAT-01], [Tab switch between Description/Dev Note/Tester Note tabs triggers `CALL_FUNCTION_CONFLICT_TYPE` short dump (Custom Control not freed before re-creation)], [Critical],
  [2], [UAT-02], [`DESC_TEXT` (STRING type) placed on screen 0310 layout causes screen rendering failure -- STRING fields not supported on Dynpro layouts], [High],
  [3], [UAT-03], [Bug Info tab (0310) missing fields: `SAP_MODULE`, `DEV_ID`, `VERIFY_TESTER_ID`, `ATT_REPORT`, `ATT_FIX` -- not placed on screen layout], [High],
  [4], [UAT-04], [Remove User button deletes without checking current selected row in Table Control `TC_USERS` -- removes wrong or no row], [Medium],
  [5], [UAT-05], [Create Bug: incorrect default values; `SAP_MODULE` F4 help not registered; description text lost after save and reopen], [High],
  [6], [UAT-06], [F4 help on `SAP_MODULE` field shows no popup -- POV flow logic entry missing for that field on screen 0310], [Medium],
  [7], [UAT-07], [Validation error message using `TYPE 'E'` locks all screen fields -- user cannot correct input without navigating away], [High],
  [8], [UAT-08], [Description text disappears after reopening a saved bug -- long text not re-loaded correctly on PBO when bug is re-entered], [High],
  [9], [UAT-09], [Backward status transition allowed (e.g., Fixed → In Progress) -- no transition matrix enforced in v4.2], [Critical],
  [10], [UAT-10], [No evidence file check before marking bug as Fixed -- transition proceeds even with empty `ZBUG_EVIDENCE`], [High],
  [11], [UAT-11], [Manager can bypass transition matrix -- direct status assignment in `save_bug_detail` overwrites any status without validation], [Critical],
)

*Resolution:* All 11 defects were root-cause analyzed and resolved in Phase F v5.0. Fixes are incorporated into the 6 ABAP includes (`Z_BUG_WS_TOP` through `Z_BUG_WS_F02`), all updated to v5.0 (F10 COMPLETE as of 16/04/2026). UAT Round 2 verification is scheduled after Phase F deployment (Steps F11--F17).

=== 5.2 QC Full Test Run --- Phase F (Planned)

The full 20-suite QC test plan (~210 cases) is scheduled for Phase F, Step F14, after successful deployment of all v5.0 components to SAP System S40. Priority execution order: TC-19 (Regression) → TC-01 (Navigation) → TC-08 (Status Transition) → TC-09 (Auto-Assign) → TC-06 (Bug Detail) → TC-15 (RBAC) → TC-11 (Dashboard) → TC-10 (Bug Search) → TC-02 (Project Search) → remaining suites.

*Target metrics for QC completion:*

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr),
  align: center,
  [*Total TCs*], [*Target Pass*], [*Max Failures*], [*Blocked*], [*Pass Rate Target*],
  [~210], [>= 200], [< 10], [0], [>= 95%],
)
