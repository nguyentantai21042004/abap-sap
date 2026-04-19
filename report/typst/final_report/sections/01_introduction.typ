// ============================================================
// 01_introduction.typ — I. Project Introduction
// ============================================================
#import "../template.typ": placeholder, hline, field

= I. Project Introduction

== 1. Overview

=== 1.1 Project Information

#table(
  columns: (4cm, 1fr),
  align: (right, left),
  [*Project Name*],   [SAP Bug Tracking Management System],
  [*Project Code*],   [`ZBUG_WS`],
  [*Program*],        [`Z_BUG_WORKSPACE_MP` (Module Pool, Type M)],
  [*SAP Package*],    [`ZBUGTRACK`],
  [*SAP System*],     [S40 \| Client 324 \| ABAP 7.70],
  [*T-code*],         [`ZBUG_WS`],
  [*Group*],          [Group ZBUG],
  [*Version*],        [v5.0 (Phase F — Enhancement)],
  [*Report Date*],    [April 2026],
)

=== 1.2 Project Team

#table(
  columns: (2.5cm, 3cm, 2cm, 1fr),
  align: (center, left, center, left),
  [*Account*], [*Name*], [*SAP Role*], [*Project Responsibilities*],
  [`DEV-089`], [Hoàng Anh], [Manager],   [Database design, core ABAP logic (Z\_BUG\_WS\_F01), documentation and deployment],
  [`DEV-242`], [Linh],      [Developer], [Bug Detail screen (0300), Z\_BUG\_CREATE / Z\_BUG\_LOG\_HISTORY FMs, helper routines (Z\_BUG\_WS\_F02)],
  [`DEV-061`], [Hiếu],      [Developer], [Bug List + Dashboard (Screen 0200), Bug Search (0210/0220), ALV infrastructure, include PAI],
  [`DEV-118`], [Ka],        [Tester],    [Email (Z\_BUG\_SEND\_EMAIL), Evidence upload, SmartForms, QC Test Plan, UAT execution],
  [`DEV-237`], [Đức],       [Developer], [Status Lifecycle + Popup (0370), Auto-Assign engine, Project Management screens (0400/0410/0500)],
)

== 2. Product Background

SAP ERP implementations involve simultaneous development across multiple modules (MM, SD, FI, CO, etc.). Without a native, structured tracking tool, bug reports are scattered across spreadsheets, emails, and instant messages. This makes it difficult to enforce accountability, track workload distribution, or maintain an auditable history of changes.

This project was initiated by FPT University to build a *centralized bug tracking system* running natively inside SAP, accessible via a single T-code (`ZBUG_WS`). The system was developed on SAP system S40 (Client 324) using ABAP 7.70, from March to April 2026, across six structured phases (A through F).

The current system (v5.0) provides the following features:
- A 10-state bug lifecycle enforced per role
- A dedicated status transition popup (Screen 0370) that enforces role-based transition rules
- An auto-assign engine for both developers and testers (based on workload and SAP module)
- A bug search engine with cross-field filtering (Screens 0210/0220)
- A real-time dashboard header on the bug list screen

== 3. Existing Solutions

The reference system `ZPG_BUGTRACKING_MAIN` / `ZPG_BUGTRACKING_DETAIL` provides a basic bug list and detail screen using an executable ABAP program. While it demonstrates the core concept, it has significant gaps compared to `ZBUG_WS`:

#table(
  columns: (1fr, 2.5cm, 2cm),
  align: (left, center, center),
  [*Feature*], [*ZPG Reference*], [*ZBUG\_WS*],
  [Module Pool (Type M) architecture], [No],  [Yes],
  [Auto-assign developer by module/workload], [No],  [Yes],
  [Centralized permission system (FM-based)], [No],  [Yes],
  [Full audit history log (`ZBUG_HISTORY`)],  [No],  [Yes],
  [Email notification via CL\_BCS],           [No],  [Yes],
  [SmartForm PDF print output],               [No],  [Yes],
  [Project management module],                [No],  [Yes],
  [10-state lifecycle with transition popup], [No],  [Yes (v5.0)],
  [Dashboard metrics header (Screen 0200)],   [No],  [Yes (v5.0)],
  [Bug search engine (Screen 0210/0220)],     [No],  [Yes (v5.0)],
)

== 4. Business Opportunity

SAP development teams in large organizations face a critical gap: no built-in tool for tracking bugs assigned to individual developers, with role-based visibility and workflow enforcement. The absence of such a tool leads to:

- Bugs being missed, duplicated, or informally tracked outside the system
- Developers receiving unclear assignments without priority or module context
- Managers unable to view real-time workload distribution or project health
- No structured evidence of bug reports, fix confirmations, or test verifications

`ZBUG_WS` addresses all of these by providing a *zero-external-dependency* system embedded directly within SAP. All data is stored in ABAP tables (`ZBUG_TRACKER`, `ZBUG_PROJECT`, etc.), all notifications use SAP's built-in email (SCOT / CL\_BCS), and all UI is native SAP GUI (Module Pool). No additional licensing, infrastructure, or integration is required.

This makes it immediately deployable on any SAP ECC or S/4HANA environment supporting ABAP 7.70+.

== 5. Software Product Vision

_For SAP development teams that need structured bug management, `ZBUG_WS` is a Module Pool application providing end-to-end bug tracking with role-based access control, automated assignment, and immutable audit trails. Unlike spreadsheet-based tools or external systems, `ZBUG_WS` runs natively on the SAP platform, requires no additional licensing, and enforces workflow rules that cannot be bypassed by any user role._

Key outcomes delivered:
- Every bug follows a defined 10-state lifecycle; transitions are enforced per role via a popup (Screen 0370)
- Auto-assign engine selects the developer with the lowest workload in the correct SAP module
- All status changes, assignments, and evidence uploads are logged in `ZBUG_HISTORY`
- Managers see real-time metrics (by status, priority, module) on every bug list screen
- Three evidence templates (Bug Report, Fix Report, Confirm Report) are downloadable from SMW0 and uploaded directly from the bug detail screen

== 6. Project Scope & Limitations

=== In Scope

- *Bug lifecycle management:* 10-state lifecycle (New, Waiting, Assigned, In Progress, Pending, Fixed, Final Testing, Resolved, Rejected, Closed-legacy) with transition rules per role
- *Project management:* Create / Edit / Delete projects, user-project assignment with per-project roles
- *Role-based access control:* Manager / Developer / Tester, enforced via SAP screen groups (`EDT`, `FNC`, `TST`, `DEV`, `STS`, `BID`, `PRJ`)
- *Auto-assign system:* developer assignment on bug creation (Phase A), tester assignment on fix completion (Phase B)
- *Evidence management:* upload / download of three template-based files per bug (`ZBUG_EVIDENCE` table)
- *Email notification:* automatic send via CL\_BCS on create, assign, status change, and reject events
- *Bug search:* cross-field filter by Bug ID, Title, Status, Priority, Module, Date range (Screens 0210/0220)
- *Dashboard header:* live count metrics on Screen 0200 grouped by status, priority, module
- *Audit trail:* all changes logged in `ZBUG_HISTORY` with old/new values and mandatory reason notes

=== Out of Scope

- Integration with external tools (Jira, ServiceNow, Bugzilla, etc.)
- Web or mobile interface — SAP GUI (Dynpro) only
- Automated test execution framework
- Multi-client or cross-system synchronization
- BI/analytics reporting (BW, Fiori, etc.)

=== Constraints & Limitations

  - Development and testing confined to SAP system S40, Client 324
  - ABAP 7.70 syntax required (inline declarations, `SWITCH` expression, string templates, `@` host variables)
  - Three SAP demo accounts used for system testing: `DEV-089` (Manager role), `DEV-061` (Developer role), `DEV-118` (Tester role)
  - Evidence files must be `.xlsx` format, maximum 10 MB per file
  - Screen 0100 is deprecated (v5.0); entry point is Screen 0410 (Project Search)
