// ============================================================
// acronyms.typ — Definition and Acronyms
// ============================================================
#import "../template.typ": placeholder, hline, field

= Definition and Acronyms

#table(
  columns: (2.5cm, 1fr),
  align: (center, left),
  [*Acronym*], [*Definition*],
  [ABAP],      [Advanced Business Application Programming — SAP's proprietary language],
  [ALV],       [ABAP List Viewer — standard SAP grid component],
  [BCS],       [Business Communication Services — SAP email API (CL_BCS)],
  [BUG_ID],    [Unique bug identifier, format BUG0000001, auto-generated via ZNRO_BUG],
  [CRUD],      [Create, Read, Update, Delete — basic data operations],
  [DEV],       [Developer — role responsible for fixing bugs],
  [ERD],       [Entity Relationship Diagram],
  [GOS],       [Generic Object Services — SAP file attachment framework],
  [GUI],       [Graphical User Interface],
  [MGR],       [Manager — role with full system access],
  [PAI],       [Process After Input — screen event after user action],
  [PBO],       [Process Before Output — screen event before screen display],
  [PDF],       [Portable Document Format — SmartForm print output],
  [SAP],       [Systems, Applications and Products in Data Processing],
  [SDD],       [Software Design Description],
  [SMTP],      [Simple Mail Transfer Protocol],
  [SPMP],      [Software Project Management Plan],
  [SRS],       [Software Requirement Specification],
  [SE11],      [SAP Data Dictionary — table/domain/data element creation],
  [SE41],      [Menu Painter — GUI Status and Title Bar editor],
  [SE51],      [Screen Painter — Dynpro screen layout editor],
  [SE80],      [Object Navigator — main ABAP Workbench],
  [SE93],      [Transaction Maintenance — T-code editor],
  [T-Code],    [Transaction Code — SAP program shortcut (e.g., ZBUG_WS)],
  [UAT],       [User Acceptance Test],
  [UC],        [Use Case],
  [ZBUGTRACK], [SAP Development Package containing all `ZBUG_*` objects],
  [ZBUG_WS],   [Entry T-Code for the Bug Tracking system],
)
