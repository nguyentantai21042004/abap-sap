// ============================================================
// 02_management.typ — II. Project Management Plan
// ============================================================
#import "../template.typ": placeholder, hline, field

= II. Project Management Plan

== 1. Overview

=== 1.1 Scope & Estimation

The following table categorizes each major software function by complexity and estimates the development effort in man-days.

#table(
  columns: (0.5cm, 3.5cm, 1fr, 1.5cm, 1.5cm, 1.5cm, 2cm),
  align: (center, left, left, center, center, center, center),
  [*No.*], [*Feature*], [*Description*], [*Simple*], [*Medium*], [*Complex*], [*Total (MD)*],
  [1],  [DB Hardening],           [Domains, data elements, tables (5 tables, 77 fields), number ranges],  [],   [],   [1], [3],
  [2],  [Function Modules],       [`Z_BUG_CREATE`, `Z_BUG_AUTO_ASSIGN`, `Z_BUG_CHECK_PERMISSION`, `Z_BUG_LOG_HISTORY`, `Z_BUG_SEND_EMAIL`], [], [], [1], [5],
  [3],  [Module Pool UI],         [Program `Z_BUG_WORKSPACE_MP` + 6 includes, 12 screens, GUI Statuses], [],   [1],  [],  [4],
  [4],  [Bug List (Screen 0200)], [ALV Grid, toolbar, role filter, Dashboard Header (v5.0)],              [],   [1],  [],  [3],
  [5],  [Bug Detail (Screen 0300)],[Tab Strip (6 tabs), long text editors, evidence ALV, history ALV],    [],   [],   [1], [4],
  [6],  [Status Transition Popup],[Screen 0370, 10-state lifecycle, role-based field matrix],              [],   [],   [1], [3],
  [7],  [Project Management],     [Screens 0400/0410/0500, project CRUD, user-project assignment],        [],   [1],  [],  [3],
  [8],  [Auto-Assign Engine],     [Phase A (New→Assigned) + Phase B (Fixed→FinalTesting), workload calc], [],   [],   [1], [3],
  [9],  [Bug Search Engine],      [Screens 0210/0220, cross-field filter, result ALV],                    [],   [1],  [],  [2],
  [10], [Email & Evidence],       [CL\_BCS email, `ZBUG_EVIDENCE` upload/download, template (SMW0)],      [],   [1],  [],  [2],
  [11], [Testing & Bug Fixes],    [QC Test Plan (140 cases), UAT (43 cases), 11 UAT bug fixes (v5.0)],    [1],  [],   [],  [3],
  [],   [*TOTAL*],                [],                                                                     [*1*],[*5*],[*5*],[*35 MD*],
)

=== 1.2 Project Objectives

*Overall objective:* Deliver a production-ready, role-based bug tracking system running natively on SAP, surpassing the reference system (`ZPG_BUGTRACKING_*`) in all dimensions, within the 10-day sprint window (24 March – 03 April 2026) plus the Phase F enhancement (April 2026).

*Specific targets:*

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Quality*],           [All 140+ QC test cases executed; pass rate ≥ 90% on UAT Round 2],
  [*Functionality*],     [10-state lifecycle enforced per role; auto-assign success rate 100% when eligible developer/tester exists],
  [*Performance*],       [ALV screens load within 3 seconds on S40; no timeout on evidence upload ≤ 10 MB],
  [*Effort distribution*],[Req 10% \| Design 15% \| Coding 45% \| Testing 20% \| PM 10%],
)

=== 1.3 Project Risks

#table(
  columns: (0.5cm, 2.5cm, 1fr, 1.5cm, 1.5cm, 2cm),
  align: (center, left, left, center, center, left),
  [*No.*], [*Risk*], [*Description*], [*Prob.*], [*Impact*], [*Mitigation*],
  [1], [SAP system downtime],        [S40 system unavailable during dev/test windows],                         [Low],    [High],   [Schedule critical work in off-peak hours; use SE38 offline editing],
  [2], [Breaking change: status `6`],[v5.0 redefines status `6` from Resolved → Final Testing; migration required], [High], [High], [Write migration script; run only after v5.0 is fully deployed],
  [3], [`ZBUG_EVIDENCE` not created], [Table may not exist in SAP DB; blocks evidence upload feature],          [Medium], [High],   [Create table in SE11 before running test cases TC-12],
  [4], [SCOT email not configured],  [CL\_BCS email send silently fails if SMTP not set up in SCOT],            [Medium], [Medium], [Verify SOST after each email-triggering test; document as known limitation],
  [5], [Auto-assign no eligible dev],[If no Developer has workload < 5 in the correct module, bug → Waiting],  [Low],    [Medium], [Insert 30 mock users in `ZBUG_USERS` / `ZBUG_USER_PROJEC` for testing],
  [6], [Phase F deploy incomplete],  [New screens (0410/0370/0210/0220) and GUI Statuses not yet created in SAP], [High], [High], [Follow the step-by-step Phase F Enhancement Guide (F11--F17)],
)

== 2. Management Approach

=== 2.1 Project Process

The project followed an *incremental waterfall* model divided into six phases, each building upon the previous:

#table(
  columns: (1.5cm, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*Phase*], [*Name*], [*Deliverables*], [*Status*],
  [A], [Database Hardening],         [5 custom tables, domains, data elements, number ranges (`ZNRO_BUG`)], [Done],
  [B], [Business Logic (FMs)],       [6 Function Modules: Create, AutoAssign, Permission, History, Email, Evidence], [Done],
  [C], [Module Pool UI (v4.x)],      [Program `Z_BUG_WORKSPACE_MP`, 8 screens, GUI Statuses, ALV grids, tab strips], [Done],
  [D], [Advanced Features (v4.x)],   [SmartForms, Excel upload/download, message class, F4 helpers, unsaved-changes detection], [Done],
  [E], [Testing (v4.x)],             [QC Test Plan (140 cases), UAT (43 cases), UAT Round 1 results (11 bugs found)], [Done],
  [F], [v5.0 Enhancement],           [10-state lifecycle, Screen 0370/0410/0210/0220, auto-assign v2, bug search, dashboard], [CODE done; deploy pending],
)

=== 2.2 Quality Management

- *Code review:* Each include (`Z_BUG_WS_TOP`, `_F00`, `_PBO`, `_PAI`, `_F01`, `_F02`) reviewed against the Screen layout guides in `screens/` before activation in SAP
- *Static analysis:* SAP syntax check (SE38 Activate) and extended program check (Program → Check → Extended) run on every code change
- *Test-driven verification:* All 140 QC test cases in the QC Test Plan executed before each UAT round
- *Audit consistency:* `ZBUG_HISTORY` checked after every status-change test to verify log entries
- *Breaking-change validation:* Status constant references (`gc_st_resolved = 'V'`, `gc_st_finaltesting = '6'`) verified against the Status Lifecycle Specification after v5.0 code change

=== 2.3 Training Plan

No formal training was required — all team members had prior SAP ABAP exposure. Specific knowledge gaps were addressed as follows:

#table(
  columns: (3cm, 1fr, 2cm),
  align: (left, left, center),
  [*Topic*], [*Resource*], [*Member*],
  [ALV Grid / Custom Container],    [SAP Help + reference program `ZPG_BUGTRACKING_MAIN`], [`DEV-061`],
  [SmartForms / CL\_BCS],           [SAP Help + SCOT configuration guide],                  [`DEV-061`],
  [Module Pool / Screen Painter],   [SE51 built-in help + project screen guides in `screens/`], [All],
  [10-state lifecycle (v5.0)],      [Status Lifecycle Specification --- v5.0 state machine, transition matrix, auto-assign rules; reviewed before coding Phase F],  [All],
)

== 3. Project Deliverables

*Internal deliverables (development artifacts):*

#table(
  columns: (0.5cm, 3cm, 1fr),
  align: (center, left, left),
  [*No.*], [*Deliverable*], [*Description*],
  [1], [Source Code (6 includes)],         [ABAP includes `Z_BUG_WS_TOP`, `_F00`, `_PBO`, `_PAI`, `_F01`, `_F02` — v5.0 complete],
  [2], [Screen Layout Guides (8 screens)], [SE51 layout instructions for Screens 0200/0210/0220/0300/0370/0400/0410/0500 — field lists, Custom Control names, flow logic],
  [3], [Database Schema],                  [Table definitions for 6 custom tables (88 fields) --- field names, data types, key fields, descriptions],
  [4], [QC Test Plan],                     [140 test cases organized in 20 test suites covering all screens, transitions, and edge cases],
  [5], [UAT Happy Case Script],            [64 user-flow test scenarios across 14 workflow categories (A--N) covering all 3 roles],
  [6], [Status Lifecycle Specification],   [v5.0 state machine, role-based transition matrix, auto-assign trigger conditions],
  [7], [Phase F Enhancement Guide],        [Step-by-step deployment instructions F11--F17 for all v5.0 additions],
)

*External deliverables (submitted to FPT University):*

#table(
  columns: (0.5cm, 3cm, 1fr),
  align: (center, left, left),
  [*No.*], [*Deliverable*], [*Description*],
  [1], [Business Blueprint],     [SAP Business Blueprint document --- compiled Typst PDF],
  [2], [Final Report],           [This document --- FPT Capstone Final Report, compiled Typst PDF],
  [3], [Test Evidence],          [Screenshots of UAT Round 1 results and v5.0 regression testing],
  [4], [Presentation Slide],     [Project demo slide deck],
)

== 4. Responsibility Assignments

#table(
  columns: (0.5cm, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*No.*], [*Activity*], [*Description*], [*Responsible*],
  [1],  [Database design],         [Table schemas, domains, data elements, number range],              [`DEV-089`],
  [2],  [Function Module design],  [FM interfaces, permission matrix, auto-assign algorithm],          [`DEV-089`],
  [3],  [ABAP coding — core],      [Includes TOP, F01, F02 (business logic + helpers)],                [`DEV-089`],
  [4],  [ABAP coding — UI],        [Includes PBO, PAI, F00 (screens, ALV, event handler)],             [`DEV-061`],
  [5],  [SmartForms / Email],      [SmartForm `ZBUG_FORM`, `ZBUG_EMAIL_FORM`, CL\_BCS integration],    [`DEV-061`],
  [6],  [Testing — QC Plan],       [Write and execute 140 QC test cases],                              [`DEV-118`],
  [7],  [UAT execution],           [Execute 43 UAT happy-case scenarios, report defects],              [`DEV-118`],
  [8],  [v5.0 Enhancement design], [10-state lifecycle, Screen 0370/0410/0210/0220 design],            [`DEV-089`],
  [9],  [Documentation],           [Blueprint, Final Report, screen layout guides, test plans],              [`DEV-089`],
  [10], [Deploy to SAP],           [SE51 new screens, SE41 GUI statuses, SE93 T-code update],         [All],
)

== 5. Project Communications

#table(
  columns: (2cm, 3cm, 1fr, 2cm),
  align: (center, left, left, center),
  [*Channel*], [*Tool*], [*Content*], [*Frequency*],
  [Team chat],       [Messenger / Zalo],    [Daily progress updates, blockers, quick decisions],          [Daily],
  [Status report],   [FPT LMS / email],     [Weekly progress summary submitted to supervisor],             [Weekly],
  [Demo / review],   [SAP GUI screen share],[Live demo of features on S40 system],                         [Per milestone],
  [Documentation],   [Shared documents],    [Screen guides, test plans, design documents --- updated per change], [Per change],
)

== 6. Configuration Management

=== 6.1 Document Management

All project documents are maintained across development phases and carry a version header indicating the last-updated date. The versioning convention used throughout this project is:

- `v4.x` --- pre-Phase F documents (initial delivery, Phases A--E)
- `v5.0` --- Phase F enhancement documents (current version)

Key document types maintained: Business Blueprint, Final Report, screen layout guides (one per screen), QC Test Plan, UAT Happy Case Script, Database Schema, Status Lifecycle Specification, and Phase F Enhancement Guide.

=== 6.2 Source Code Structure

ABAP source code for the Module Pool `Z_BUG_WORKSPACE_MP` is organized into 6 include programs under SAP package `ZBUGTRACK`. Deployment to SAP is performed manually: open each include in SE38, paste the updated code, check (Ctrl+F2), and activate (Ctrl+F3).

#table(
  columns: (3.5cm, 1fr, 1.5cm),
  align: (left, left, center),
  [*SAP Include*], [*Content*], [*Version*],
  [`Z_BUG_WS_TOP`], [Global declarations, types, constants for the 10-state lifecycle, ALV/GUI container objects], [v5.0],
  [`Z_BUG_WS_F00`], [ALV field catalog definitions for 5 grids; `LCL_EVENT_HANDLER` class], [v5.0],
  [`Z_BUG_WS_PBO`], [Process Before Output modules for all 9 screens], [v5.0],
  [`Z_BUG_WS_PAI`], [Process After Input modules; all fcode handlers], [v5.0],
  [`Z_BUG_WS_F01`], [Business logic FORMs: save, change status, auto-assign, email, evidence, history], [v5.0],
  [`Z_BUG_WS_F02`], [Helper FORMs: F4 search helps, long text API, popup, template download], [v5.0],
)

=== 6.3 Tools & Infrastructures

#table(
  columns: (0.5cm, 3cm, 1.5cm, 1fr),
  align: (center, left, center, left),
  [*No.*], [*Tool*], [*Version*], [*Purpose*],
  [1],  [SAP GUI],              [7.70+],      [Primary SAP front-end for development and testing],
  [2],  [SE11],                 [—],          [Data Dictionary: tables, domains, data elements],
  [3],  [SE38 / SE80],          [—],          [ABAP program development and code management],
  [4],  [SE51],                 [—],          [Screen Painter: Dynpro screen layout design],
  [5],  [SE41],                 [—],          [Menu Painter: GUI Status and Title Bar definition],
  [6],  [SE93],                 [—],          [Transaction Maintenance: T-code configuration],
  [7],  [SMARTFORMS],           [—],          [SmartForm designer for PDF and email templates],
  [8],  [SMW0],                 [—],          [Web Repository: storage for `.xlsx` evidence templates],
  [9],  [SCOT],                 [—],          [Email SMTP configuration for CL\_BCS notifications],
  [10], [SE16N],                [—],          [Table data browser for test data setup and verification],
  [11], [Typst],                [0.11+],      [Document compilation for Blueprint and Final Report],
)
