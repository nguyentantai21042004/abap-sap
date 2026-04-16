// ============================================================
// 01_overview.typ — OVERVIEW
// ============================================================
#import "../template.typ": placeholder, hline

= OVERVIEW

== Glossary

#table(
  columns: (3.5cm, 1fr, 3cm),
  align: (left, left, left),
  [*Term*], [*Definition*], [*Note*],
  [ABAP],         [Advanced Business Application Programming — SAP's proprietary language], [],
  [ALV],          [ABAP List Viewer — SAP's standard grid/list display component], [],
  [BCS],          [Business Communication Services — SAP API for sending emails], [],
  [Bug],          [A defect or issue found during software testing], [],
  [BUG_ID],       [Unique identifier for a bug record, format: BUG0000001 (auto-generated)], [],
  [Custom Control],[A region on a Dynpro screen reserved for GUI controls (ALV, TextEdit)], [],
  [DEV],          [Developer — role responsible for fixing bugs], [],
  [Dynpro],       [Dynamic Program — SAP screen technology (also called Dynscreen)], [],
  [Evidence],     [Proof file (Excel .xlsx) uploaded to confirm bug report, fix, or verify], [],
  [F4 Help],      [SAP search help — dropdown/popup for field value selection], [],
  [Final Testing],[Status `6` — bug has been fixed, Final Tester is verifying], [],
  [GOS],          [Generic Object Services — SAP framework for attaching files to records], [],
  [GUI Status],   [SAP toolbar/menu definition for a screen (created in SE41)], [],
  [In Progress],  [Status `3` — Developer is actively working on the bug], [],
  [MGR],          [Manager — role with full system access], [],
  [Module Pool],  [Type M ABAP program — the basis of complex SAP screen applications], [],
  [New],          [Status `1` — bug just created, not yet assigned], [],
  [Package],      [`ZBUGTRACK` — SAP development package grouping all objects], [],
  [PAI],          [Process After Input — screen event triggered after user action], [],
  [PBO],          [Process Before Output — screen event triggered before display], [],
  [Pending],      [Status `4` — temporarily blocked, awaiting information], [],
  [Project],      [A development project that groups related bugs (table: ZBUG_PROJECT)], [],
  [Rejected],     [Status `R` — Developer rejected the bug assignment], [],
  [Resolved],     [Status `V` — Final Tester confirmed fix; terminal state], [],
  [SE11],         [SAP Data Dictionary — tool for creating tables, domains, data elements], [],
  [SE38/SE80],    [SAP ABAP Workbench — code editor], [],
  [SE41],         [SAP Menu Painter — tool for creating GUI Statuses and Title Bars], [],
  [SE51],         [SAP Screen Painter — tool for creating Dynpro screens], [],
  [SE93],         [SAP Transaction Maintenance — for creating/editing T-codes], [],
  [SmartForm],    [SAP form printing tool — used for PDF reports and email body], [],
  [T-Code],       [Transaction Code — SAP shortcut to launch a program (e.g., ZBUG_WS)], [],
  [Tester],       [Role responsible for reporting bugs and verifying fixes], [],
  [Waiting],      [Status `W` — no suitable Dev/Tester found; awaiting Manager assignment], [],
  [Workload],     [Number of active bugs (status 2/3/4/6) assigned to a user], [],
  [ZBUG_WS],      [The T-Code entry point for the Bug Tracking system], [],
)

== Flow Chart Shapes Usage

#table(
  columns: (4cm, 1fr),
  align: (center, left),
  [*Shape*], [*Usage / Meaning*],
  [Rectangle (solid border)],     [Process step / System action (e.g., Auto-assign, Save record)],
  [Diamond],                      [Decision / Condition branch (e.g., Bug Type = Code or Config?)],
  [Rounded Rectangle (oval)],     [Start / End terminal state],
  [Parallelogram],                [Input from user / Output to user],
  [Dashed arrow],                 [Conditional flow (only under certain conditions)],
  [Solid arrow],                  [Normal sequential flow],
  [Bold border rectangle],        [System-automated step (no user interaction required)],
)
