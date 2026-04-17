// ============================================================
// 03_business_process.typ — BUSINESS PROCESS
// ============================================================
#import "../template.typ": placeholder, hline, diagram-placeholder

= BUSINESS PROCESS

// ─────────────────────────────────────────────────────────
== BP-BUG-01: Bug Lifecycle Management

=== Process Flow

#diagram-placeholder("BP-BUG-01: Bug Lifecycle Management", "docs/diagrams/bp-bug-01-lifecycle.mmd")

=== Process Description

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Step \#*], [*Step Name*], [*Detailed Description*], [*Role*],
  [1], [Create Bug],
    [Tester navigates Screen 0300 (from a project context). Fills Title, SAP Module, Priority, Severity, Bug Type. BUG_ID is auto-generated. STATUS auto-set to `1` (New). TESTER_ID auto-set to SY-UNAME.],
    [Tester / Manager],
  [2], [Auto-Assign Developer],
    [System queries ZBUG_USER_PROJEC for Developers in the same project + module. Selects the one with workload < 5 and lowest active bugs. Sets STATUS → `2` (Assigned), DEV_ID = selected user. If none found → STATUS = `W` (Waiting), Manager notified by email.],
    [System (auto)],
  [3], [Manual Assignment],
    [If STATUS = `W`, Manager opens Status Transition Popup (Screen 0370), selects Developer manually, sets STATUS → `2`. Manager can also directly assign from any state.],
    [Manager],
  [4], [Start Working],
    [Developer opens popup 0370, transitions STATUS → `3` (In Progress). Developer may set `4` (Pending) if blocked.],
    [Developer],
  [5], [Fix Bug],
    [Developer uploads fix evidence (fix_report.xlsx via ZBUG_EVIDENCE). Status must have at least 1 evidence file. Transitions STATUS → `5` (Fixed) via popup 0370.],
    [Developer],
  [6], [Auto-Assign Final Tester],
    [System queries ZBUG_USER_PROJEC for Testers in same project + module. Workload = COUNT bugs WHERE status = `6`. Selects lowest-workload Tester < 5. Sets STATUS → `6`, VERIFY_TESTER_ID = selected tester. If none → STATUS = `W`.],
    [System (auto)],
  [7], [Final Testing],
    [Assigned Tester verifies the fix. Opens popup 0370. *Pass:* enters TRANS_NOTE → STATUS = `V` (Resolved). *Fail:* enters TRANS_NOTE → STATUS = `3` (back to InProgress).],
    [Tester (Final)],
  [8], [Resolved],
    [STATUS = `V` is the terminal state. No further transitions allowed. Bug is considered complete.],
    [—],
  [9], [Rejection Flow],
    [Developer may reject (`R`) with mandatory TRANS_NOTE. Manager reassigns to another Developer → STATUS = `2`. This is logged in ZBUG_HISTORY with Action = `RS`.],
    [Developer / Manager],
)

// ─────────────────────────────────────────────────────────
== BP-BUG-02: Status Transition Popup (Screen 0370)

=== Process Flow

#diagram-placeholder("BP-BUG-02: Status Transition Popup (Screen 0370)", "docs/diagrams/bp-bug-02-status-popup.mmd")

=== Process Description

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Step \#*], [*Step Name*], [*Detailed Description*], [*Role*],
  [1], [Open Popup], [User clicks STATUS_CHG button on Screen 0300. CALL SCREEN 0370 STARTING AT col row. Screen fields populated from current ZBUG_TRACKER record.], [Developer / Tester / Manager],
  [2], [Select Transition], [User selects target status from dropdown (NEW_STATUS). Available options depend on current status and user role. System enforces transition matrix.], [Developer / Tester / Manager],
  [3], [Fill Required Fields], [Depending on transition: fill DEVELOPER_ID, FINAL_TESTER_ID (via F4), or TRANS_NOTE (free text). Upload button available for evidence when transitioning to Fixed (5).], [Developer / Tester / Manager],
  [4], [Confirm], [User clicks CONFIRM. System validates: permission check, mandatory fields, evidence check (for → 5), TRANS_NOTE check (for → R, → V, → 3-from-6). If valid → update DB + log + email.], [System],
  [5], [Auto-Assign Trigger], [If transitioning to Fixed (5): system auto-assigns Final Tester. If → Assigned (2) from status 1/W/4: system may auto-assign or use DEVELOPER_ID from popup.], [System (auto)],
)

// ─────────────────────────────────────────────────────────
== BP-PRJ-01: Project Management

=== Process Flow

#diagram-placeholder("BP-PRJ-01: Project Management Lifecycle", "docs/diagrams/bp-prj-01-project.mmd")

=== Process Description

#table(
  columns: (1.5cm, 3cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*Step \#*], [*Step Name*], [*Detailed Description*], [*Role*],
  [1], [Create Project], [Manager opens Screen 0500 (from Project List 0400, action: CREA_PRJ). Fills PROJECT_ID (CHAR 20), PROJECT_NAME, DESCRIPTION, START_DATE, END_DATE, NOTE. STATUS auto-set to `1` (Opening).], [Manager],
  [2], [Assign Team], [On Screen 0500, Table Control TC_USERS shows project members. Manager uses ADD_USER button to add SAP users with role M/D/T. Uses REMO_USR to remove.], [Manager],
  [3], [Activate Project], [Manager changes status → `2` (In Process). Bugs can now be created under this project.], [Manager],
  [4], [Search Projects], [Screen 0410 (Project Search) is the initial screen. User fills filters (Project ID, Name, Status) and clicks Execute → Screen 0400 (Project List ALV).], [All Roles],
  [5], [Upload Projects], [Manager uploads Excel file (template: ZTEMPLATE_PROJECT via SMW0). System parses via TEXT_CONVERT_XLS_TO_SAP, validates, and batch-inserts into ZBUG_PROJECT.], [Manager],
  [6], [Close Project], [Manager sets STATUS → `3` (Done). System checks: all bugs must be Resolved (V). If any open bug exists → error message, transition blocked.], [Manager],
)

