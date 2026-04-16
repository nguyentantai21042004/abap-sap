// ============================================================
// 03_requirements.typ — III. Software Requirement Specification
// ============================================================
#import "../template.typ": placeholder, hline, field, diagram-placeholder

= III. Software Requirement Specification

== 1. Requirement Overview

=== 1.1 Context Diagram

`ZBUG_WS` is a closed, internal SAP application. All actors interact via SAP GUI using a single T-code entry point. There are no external integrations at the presentation layer; email is the only outbound channel, routed through SAP's internal SCOT/SMTP infrastructure.

#diagram-placeholder("System Context Diagram", "docs/diagrams/context-diagram.mmd")

Actors:
- *Manager (`DEV-089`):* Full access — create/delete projects, manage users, approve assignments, view dashboard
- *Developer (`DEV-061`):* Receives assigned bugs, updates status (In Progress / Fixed / Pending / Rejected), uploads fix evidence
- *Tester (`DEV-118`):* Creates bugs, uploads bug report evidence, verifies fixes, confirms resolution

=== 1.2 User Requirements

*Use Case Diagram (textual representation):*

#table(
  columns: (2cm, 1fr, 1fr),
  align: (center, left, left),
  [*UC Code*], [*Use Case Name*], [*Actor(s)*],
  [UC-01], [Search and view project list],                   [Manager, Developer, Tester],
  [UC-02], [Create / Edit / Delete project],                 [Manager],
  [UC-03], [Manage project members (assign role)],           [Manager],
  [UC-04], [View bug list for a project],                    [Manager, Developer, Tester],
  [UC-05], [Create bug report],                              [Tester, Manager],
  [UC-06], [View bug detail],                                [Manager, Developer, Tester],
  [UC-07], [Edit bug information],                           [Manager, Developer (limited), Tester (limited)],
  [UC-08], [Change bug status via transition popup],         [Manager, Developer, Tester (per transition matrix)],
  [UC-09], [Delete bug (soft delete)],                       [Manager],
  [UC-10], [Upload evidence file],                           [Manager, Developer, Tester (per evidence type)],
  [UC-11], [Download evidence template],                     [Manager, Tester],
  [UC-12], [Search bugs by multiple criteria],               [Manager, Developer, Tester],
  [UC-13], [View dashboard metrics],                         [Manager],
  [UC-14], [Send email notification],                        [System (automatic) + Manager, Developer, Tester (manual)],
  [UC-15], [View change history log],                        [Manager, Developer, Tester],
)

=== 1.3 System Functionalities

*Screen flow (v5.0):*

#diagram-placeholder("Screen Navigation Flow (v5.0)", "docs/diagrams/screen-flow.mmd")

*System roles and screen authorization:*

#table(
  columns: (3cm, 1.5cm, 1.5cm, 1.5cm),
  align: (left, center, center, center),
  [*Capability*], [*M*], [*D*], [*T*],
  [Access all projects], [✓], [own], [own],
  [Create / Delete project], [✓], [—], [—],
  [Add / Remove project users], [✓], [—], [—],
  [Create bug], [✓], [—], [✓],
  [Delete bug], [✓], [—], [—],
  [Change bug info fields (FNC group: type/priority/severity)], [✓], [—], [✓],
  [Change bug info fields (DEV group: dev note)], [✓], [✓], [—],
  [Change status (via popup 0370)], [matrix], [matrix], [matrix],
  [Upload bug report evidence], [✓], [—], [✓ (reporter)],
  [Upload fix evidence], [✓], [✓ (assigned)], [✓ (config bug)],
  [Download templates from SMW0], [✓], [—], [✓],
  [View dashboard header], [✓], [✓], [✓],
  [Send email manually], [✓], [✓], [✓],
)

== 2. Functional Specifications

=== 2.1 Bug Management

==== 2.1.1 UC-05 — Create Bug

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Use Case ID*],      [UC-05],
  [*Name*],             [Create Bug],
  [*Actor(s)*],         [Tester, Manager],
  [*Description*],      [User creates a new bug record linked to the current project context],
  [*Pre-condition*],    [User is logged in; a project is selected in Screen 0400; user has Tester or Manager role],
  [*Post-condition*],   [New record in `ZBUG_TRACKER` with STATUS='1' (New); auto-assign triggers; email sent],
  [*Normal Flow*],      [1. User clicks "Create" on Screen 0200 \n 2. Screen 0300 opens in Create mode \n 3. User fills TITLE, SAP\_MODULE, BUG\_TYPE, PRIORITY, SEVERITY \n 4. User writes description (Tab 0320) and optional tester note (Tab 0340) \n 5. User clicks "Save" \n 6. BUG\_ID auto-generated (format BUG0000001 via ZNRO\_BUG) \n 7. Auto-assign phase A runs (New → Assigned or Waiting) \n 8. Email sent to assigned developer and manager],
  [*Exception Flow*],   [Mandatory fields missing → error message, no save \n Auto-assign finds no eligible dev → STATUS = 'W' (Waiting)],
)

==== 2.1.2 UC-08 — Change Bug Status

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Use Case ID*],      [UC-08],
  [*Name*],             [Change Bug Status via Popup],
  [*Actor(s)*],         [Manager, Developer, Tester (per transition matrix)],
  [*Description*],      [User changes bug status through the dedicated popup Screen 0370, which enforces role-based transition rules],
  [*Pre-condition*],    [Bug is loaded in Screen 0300 Change mode; user has the correct role for the current status],
  [*Post-condition*],   [STATUS updated in `ZBUG_TRACKER`; history record in `ZBUG_HISTORY`; email sent; auto-assign Phase B may trigger],
  [*Normal Flow*],      [1. User clicks "Change Status" on Screen 0300 \n 2. Popup Screen 0370 opens with current bug info read-only \n 3. User selects new status from dropdown (role-filtered options) \n 4. User fills required fields (DEVELOPER\_ID, TRANS\_NOTE, or uploads evidence per matrix) \n 5. User clicks "Confirm" \n 6. Transition validated; STATUS updated; history logged \n 7. If Fixed (5): auto-assign Phase B runs (→ Final Testing 6 or Waiting W)],
  [*Exception Flow*],   [Required field missing (e.g., evidence for Fixed, TRANS\_NOTE for Resolved) → error message \n Transition not allowed for role → popup fields locked, confirm blocked],
)

=== 2.2 Project Management

==== 2.2.1 UC-02 — Create / Edit Project

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Use Case ID*],      [UC-02],
  [*Name*],             [Create / Edit Project],
  [*Actor(s)*],         [Manager],
  [*Description*],      [Manager creates or edits a project with name, dates, status, and note],
  [*Pre-condition*],    [User has Manager role in `ZBUG_USERS`],
  [*Post-condition*],   [New/updated record in `ZBUG_PROJECT`; PROJECT\_ID auto-generated on create (format PRJ0000001)],
  [*Normal Flow*],      [1. Manager clicks "Create Project" on Screen 0400 \n 2. Screen 0500 opens in Create mode \n 3. Manager fills PROJECT\_NAME, START\_DATE, END\_DATE, PROJECT\_MANAGER, PROJECT\_STATUS, NOTE \n 4. Manager clicks "Save" \n 5. PROJECT\_ID auto-generated; record saved; mode switches to Change],
  [*Exception Flow*],   [PROJECT\_NAME empty → error "Project Name is required." \n Set status = 3 (Done) when open bugs exist → error "Cannot set project to Done. N bug(s) not yet Resolved/Closed."],
)

==== 2.2.2 UC-03 — Manage Project Members

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Use Case ID*],      [UC-03],
  [*Name*],             [Manage Project Members],
  [*Actor(s)*],         [Manager],
  [*Description*],      [Manager adds or removes users from a project with a specific role (M/D/T)],
  [*Pre-condition*],    [Project already saved in `ZBUG_PROJECT`; target user exists in `ZBUG_USERS`],
  [*Post-condition*],   [Record in `ZBUG_USER_PROJEC` created or deleted],
  [*Exception Flow*],   [User not found in `ZBUG_USERS` → error \n Duplicate user → error \n Invalid role → error],
)

== 3. UI Requirements

=== 3.1 Project Search (Screen 0410 — Initial Screen)

The initial screen presented when the user runs T-code `ZBUG_WS`. Filters the project list before displaying it.

*UI Requirements:*

#table(
  columns: (0.5cm, 3cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*No.*], [*Field*], [*Description*], [*Required*],
  [1], [`S_PRJ_ID` (Project ID)],         [Select-options: filter by project ID, F4 from `ZBUG_PROJECT`], [No],
  [2], [`S_PRJ_MN` (Project Manager)],    [Select-options: filter by manager user ID, F4 from `ZBUG_USERS`], [No],
  [3], [`S_PRJ_ST` (Project Status)],     [Select-options: filter by status (1/2/3/4), F4 domain values], [No],
)

GUI Status `STATUS_0410`: Execute (F8), Back (F3), Exit (Shift+F3), Cancel (F12).

=== 3.2 Bug List (Screen 0200)

Displays all bugs for the selected project (or "My Bugs" filtered by role). Shows a Dashboard Header above the ALV grid.

*Dashboard Header fields:* Total bugs, by status (New/Assigned/InProgress/Fixed/FinalTesting/Resolved/Waiting/Pending/Rejected), by priority (H/M/L), by module.

*ALV columns:* BUG\_ID (hotspot), TITLE, SAP\_MODULE, PRIORITY, STATUS\_TEXT, BUG\_TYPE, TESTER\_ID, DEV\_ID, CREATED\_AT, ATT\_REPORT (hotspot), ATT\_FIX (hotspot), ATT\_VERIFY (hotspot).

*Color coding:* Status field colored per SAP color codes (New = blue C510, Assigned = orange C710, In Progress = purple C610, Fixed = green C510, etc.).

=== 3.3 Bug Detail (Screen 0300 — Tab Strip)

Tab strip with 6 subscreens. STATUS field always locked (`STS` screen group); changes only via Screen 0370.

#table(
  columns: (1.5cm, 2.5cm, 1fr, 2cm),
  align: (center, left, left, center),
  [*Tab*], [*Subscreen*], [*Content*], [*Editor*],
  [1], [0310 Bug Info],      [All bug fields + mini description (`CC_DESC_MINI`)],            [Standard],
  [2], [0320 Description],   [Full description (Long Text Z001, `CC_DESC`)],                  [`cl_gui_textedit`],
  [3], [0330 Dev Note],      [Developer's fix notes (Long Text Z002, `CC_DEVNOTE`)],          [`cl_gui_textedit`],
  [4], [0340 Tester Note],   [Tester's verification notes (Long Text Z003, `CC_TSTRNOTE`)],   [`cl_gui_textedit`],
  [5], [0350 Evidence],      [Evidence upload / download ALV (`CC_EVIDENCE`)],                [ALV Grid],
  [6], [0360 History],       [Change log from `ZBUG_HISTORY` (`CC_HISTORY`, readonly)],       [ALV Grid readonly],
)

=== 3.4 Status Transition Popup (Screen 0370 — v5.0 New)

Modal dialog popup triggered by "Change Status" button on Screen 0300.

*Read-only fields:* BUG\_ID, TITLE, REPORTER, CURRENT\_STATUS.

*Input fields (enabled/locked per current status):*

#table(
  columns: (2.5cm, 1.5cm, 1.5cm, 2cm, 1.5cm, 1.5cm),
  align: (left, center, center, center, center, center),
  [*Current Status*], [*NEW\_STATUS*], [*DEV\_ID*], [*FINAL\_TESTER\_ID*], [*TRANS\_NOTE*], [*Upload*],
  [1 — New],            [2, W],    [Open (→2)],   [Locked],         [Locked],         [Locked],
  [W — Waiting],        [2, 6],    [Open],        [Open (→6)],      [Locked],         [Locked],
  [2 — Assigned],       [3, R],    [Locked],      [Locked],         [Open (→R)],      [Locked],
  [3 — In Progress],    [5, 4, R], [Locked],      [Locked],         [Open],           [Open (→5)],
  [4 — Pending],        [2],       [Open],        [Locked],         [Locked],         [Locked],
  [6 — Final Testing],  [V, 3],    [Locked],      [Locked],         [Open (→V)],      [Locked],
)

GUI Status `STATUS_0370`: CONFIRM, UP\_TRANS (upload evidence), CANCEL (F12).

== 4. Non-Functional Requirements

=== 4.1 External Interfaces

- *User interface:* SAP GUI (Dynpro) only — Module Pool screens accessed via T-code `ZBUG_WS`
- *Email:* SAP CL\_BCS API with SMTP relay via SCOT. Recipients determined by event type (create, assign, status change, reject)
- *File storage:* Evidence files stored in custom table `ZBUG_EVIDENCE` (RAWSTRING content field). Templates in SMW0 (objects `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03`)
- *Print:* SmartForms `ZBUG_FORM` (bug detail PDF) and `ZBUG_EMAIL_FORM` (email body HTML)

=== 4.2 Quality Attributes

#table(
  columns: (0.5cm, 2cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*No.*], [*Attribute*], [*Requirement*], [*Priority*],
  [1], [Performance],   [ALV screens load ≤ 3 seconds on S40 with ≤ 1000 bug records], [High],
  [2], [Security],      [Role enforcement via `ZBUG_USERS` table check on every screen/action; no role bypass possible], [Critical],
  [3], [Auditability],  [Every status change, assignment, and evidence upload creates a record in `ZBUG_HISTORY`], [High],
  [4], [Reliability],   [COMMIT WORK / ROLLBACK WORK used in all save operations; no partial saves], [High],
  [5], [Usability],     [Mandatory fields highlighted; confirmation popups for delete/back without save; F4 help on all FK fields], [Medium],
  [6], [Compatibility], [Runs on SAP ABAP 7.70 (SAP\_BASIS 770); SAP GUI 7.50+], [High],
)

== 5. Requirement Appendix

=== 5.1 Business Rules

#table(
  columns: (1.5cm, 1fr),
  align: (center, left),
  [*Rule ID*], [*Description*],
  [BR-01], [Every bug must belong to exactly one project (`PROJECT_ID` is mandatory and locked after creation)],
  [BR-02], [BUG\_ID is auto-generated via Number Range `ZNRO_BUG` (format: `BUG` + 7-digit NUMC); cannot be manually entered],
  [BR-03], [STATUS field is always locked on Screen 0300; status changes are only possible via Screen 0370 (popup)],
  [BR-04], [Transitioning to "Fixed (5)" requires at least one evidence file in `ZBUG_EVIDENCE` (COUNT > 0)],
  [BR-05], [Transitioning to "Resolved (V)" requires `TRANS_NOTE` to be filled (non-empty confirmation note)],
  [BR-06], [Transitioning to "Rejected (R)" or "In Progress→Pending" requires `TRANS_NOTE` (reason for rejection/blocking)],
  [BR-07], [Auto-assign selects the developer with the lowest active workload (bugs in statuses 2, 3, 4, 6) AND workload < 5; if none found → STATUS = 'W' (Waiting)],
  [BR-08], [Setting project status to "Done (3)" is blocked if any bug in the project has STATUS not in {V, 7, R}],
  [BR-09], [Evidence files: format must be `.xlsx`; max size 10 MB; upload after STATUS = 'V' (Resolved) is blocked],
  [BR-10], [Manager follows the same transition matrix as other roles (no bypass); all transitions must comply with the v5.0 Status Lifecycle Specification],
)

=== 5.2 Common Requirements

- All screens display a title bar identifying the current screen and context (project name, bug ID)
- Back button (F3) checks for unsaved changes; shows confirmation popup before leaving
- All DELETE operations use soft delete (`IS_DEL = 'X'`); no physical row deletion
- ALV grids support: sort, filter, export to Excel (built-in), sum, find
- All timestamps use SAP system fields: `SY-DATUM`, `SY-UZEIT`, `SY-UNAME`

=== 5.3 Application Messages List

#table(
  columns: (2cm, 1fr, 1.5cm),
  align: (center, left, center),
  [*Message Class*], [*Message Content*], [*Type*],
  [`ZBUG_MSG`], [Bug saved successfully.],                                        [S (success)],
  [`ZBUG_MSG`], [Please select a bug first.],                                     [E (error)],
  [`ZBUG_MSG`], [Status transition not allowed for your role.],                   [E],
  [`ZBUG_MSG`], [Evidence is required before marking as Fixed.],                  [E],
  [`ZBUG_MSG`], [Transition note is required for this status change.],            [E],
  [`ZBUG_MSG`], [Cannot set project to Done. \{N\} bug(s) not yet Resolved/Closed.], [E],
  [`ZBUG_MSG`], [User \{uid\} not found in system.],                              [E],
  [`ZBUG_MSG`], [Only managers can create/delete projects.],                      [E],
  [`ZBUG_MSG`], [Project saved successfully.],                                    [S],
  [`ZBUG_MSG`], [Auto-assigned to developer \{dev\_id\}.],                        [S],
  [`ZBUG_MSG`], [No available developer found. Status set to Waiting.],           [W (warning)],
  [`ZBUG_MSG`], [Email sent successfully.],                                       [S],
)

=== 5.4 Other Requirements

- *Number Range:* `ZNRO_BUG` — interval 01, from 0000000001 to 9999999999, output format `BUG` + NUMC(7)
- *Long Text Object:* `ZBUG_NOTE` (created via SE75) with text IDs Z001 (Description), Z002 (Dev Note), Z003 (Tester Note)
- *SAP Text Object:* text name = BUG\_ID (e.g., `BUG0000001`); stored via `SAVE_TEXT` / read via `READ_TEXT`
