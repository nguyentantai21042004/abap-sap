// ============================================================
// 04_reports.typ — REPORTS
// ============================================================
#import "../template.typ": placeholder, hline

= REPORTS

Based on system requirements, the following reports and outputs are available within the SAP Bug Tracking Management System.

#table(
  columns: (1cm, 4cm, 1fr, 3cm),
  align: (center, left, left, center),
  [*No.*], [*Description*], [*Detail*], [*T-Code / Access*],
  [1],
    [Bug List ALV Report],
    [Full list of bugs per project with color-coded status, priority, module, tester, developer. Supports filter, sort, export to Excel. Role-based: Tester sees own bugs, Developer sees assigned bugs, Manager sees all.],
    [ZBUG_WS → Screen 0200],
  [2],
    [Bug Detail SmartForm (PDF)],
    [Printable PDF report for a selected bug. Includes: Bug ID, Title, Module, Priority, Status, Severity, Type, Tester, Developer, Created/Closed dates, history log, notes. Triggered by PRINT button on Screen 0200.],
    [ZBUG_WS → Screen 0200 → PRINT],
  [3],
    [Project List ALV Report],
    [List of all projects accessible to the current user. Shows Project ID, Name, Status, Manager, Start/End date, user count. Filtered from Screen 0410 (Project Search).],
    [ZBUG_WS → Screen 0400],
  [4],
    [Bug History Log],
    [Complete audit trail for a single bug. Shows all status changes, assignments, uploads, field edits with timestamp, user, old value, new value, and reason. Readonly ALV on Tab 0360 of Bug Detail.],
    [ZBUG_WS → Screen 0300 → Tab History],
  [5],
    [Bug Search Results],
    [Ad-hoc search report across all bugs in a project. Supports multi-field filter (Bug ID, Title, Status, Priority, Module, Tester, Developer). Output on Screen 0220.],
    [ZBUG_WS → Screen 0200 → SEARCH],
  [6],
    [Dashboard Statistics (Manager only)],
    [Real-time summary header on Screen 0200 showing: Total bugs, by Status (New/Assigned/InProgress/Fixed/FinalTesting/Waiting/Resolved/Rejected), by Priority (H/M/L), by Module.],
    [ZBUG_WS → Screen 0200 (Manager)],
  [7],
    [Email Notification Log],
    [Automatic email sent on key events: Bug Created, Assigned, Status Changed, Rejected, Resolved. Sent via SAP BCS API (CL_BCS). Viewable in SOST.],
    [SOST (SAP standard)],
  [8],
    [Evidence Files (ZBUG_EVIDENCE)],
    [Binary evidence files stored in custom table ZBUG_EVIDENCE. Three types per bug: Bug_report.xlsx (Tester), fix_report.xlsx (Developer), confirm_report.xlsx (Final Tester). Downloadable from Screen 0300 Evidence tab.],
    [ZBUG_WS → Screen 0300 → Tab Evidence],
)
