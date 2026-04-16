// ============================================================
// 04_design.typ — IV. Software Design Description
// ============================================================
#import "../template.typ": placeholder, hline, field

= IV. Software Design Description

== 1. System Design

=== 1.1 System Architecture

`ZBUG_WS` uses a three-tier architecture running entirely within SAP:

#block(breakable: false)[
```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
│  Module Pool: Z_BUG_WORKSPACE_MP (Type M)                   │
│                                                             │
│  Screen 0410  Screen 0400  Screen 0200  Screen 0300         │
│  (Prj Search) (Prj List)   (Bug List)  (Bug Detail)         │
│  Screen 0210  Screen 0220  Screen 0370  Screen 0500         │
│  (Bug Search) (Search Res) (Status Pop) (Prj Detail)        │
│                                                             │
│  + GUI Statuses (SE41) + Long Text Editors (cl_gui_textedit)│
│  + ALV Grids (cl_gui_alv_grid)                              │
├─────────────────────────────────────────────────────────────┤
│                    APPLICATION LAYER                         │
│  Function Group: ZBUG_FG                                    │
│                                                             │
│  Z_BUG_CREATE          Z_BUG_AUTO_ASSIGN                    │
│  Z_BUG_UPDATE_STATUS   Z_BUG_REASSIGN                       │
│  Z_BUG_CHECK_PERMISSION Z_BUG_LOG_HISTORY                   │
│  Z_BUG_SEND_EMAIL      Z_BUG_UPLOAD_ATTACHMENT              │
│  Z_BUG_GET_STATISTICS                                       │
├─────────────────────────────────────────────────────────────┤
│                      DATA LAYER                              │
│  ZBUG_TRACKER (29 fields)  ZBUG_USERS (12 fields)           │
│  ZBUG_PROJECT (16 fields)  ZBUG_USER_PROJEC (10 fields)     │
│  ZBUG_HISTORY (10 fields)  ZBUG_EVIDENCE (11 fields)        │
│  Number Range: ZNRO_BUG    Text Object: ZBUG_NOTE           │
│  Message Class: ZBUG_MSG   SmartForms: ZBUG_FORM / EMAIL    │
│  SMW0 Templates: ZBT_TMPL_01/02/03                          │
└─────────────────────────────────────────────────────────────┘
```
]

The Module Pool calls Function Modules for all business logic — no ABAP logic is coded directly in PBO/PAI modules beyond screen navigation and FM calls.

=== 1.2 Package Diagram

All objects belong to the SAP development package `ZBUGTRACK`:

#block(breakable: false)[
```
Package: ZBUGTRACK
│
├── Program:       Z_BUG_WORKSPACE_MP  (Module Pool, Type M)
│     ├── Include: Z_BUG_WS_TOP   ← Global declarations, types, constants, ALV objects
│     ├── Include: Z_BUG_WS_F00   ← ALV field catalog, LCL_EVENT_HANDLER class
│     ├── Include: Z_BUG_WS_PBO   ← Process Before Output modules (all screens)
│     ├── Include: Z_BUG_WS_PAI   ← Process After Input modules (user commands)
│     ├── Include: Z_BUG_WS_F01   ← Business logic FORMs (load/save/validate)
│     └── Include: Z_BUG_WS_F02   ← Helpers: F4, long text, popup, template download
│
├── Function Group: ZBUG_FG
│     ├── Z_BUG_CREATE
│     ├── Z_BUG_AUTO_ASSIGN
│     ├── Z_BUG_UPDATE_STATUS
│     ├── Z_BUG_CHECK_PERMISSION
│     ├── Z_BUG_LOG_HISTORY
│     ├── Z_BUG_SEND_EMAIL
│     ├── Z_BUG_UPLOAD_ATTACHMENT
│     ├── Z_BUG_REASSIGN
│     └── Z_BUG_GET_STATISTICS
│
├── Tables:        ZBUG_TRACKER, ZBUG_USERS, ZBUG_PROJECT,
│                  ZBUG_USER_PROJEC, ZBUG_HISTORY, ZBUG_EVIDENCE
│
├── Domains/DEs:   ZDE_BUG_STATUS (CHAR 20), ZDE_PRIORITY (CHAR 1),
│                  ZDE_BUG_TYPE (CHAR 1), ZDE_SEVERITY (CHAR 1),
│                  ZDE_USERNAME (CHAR 12), ZDE_PROJECT_ID (CHAR 20), ...
│
├── SmartForms:    ZBUG_FORM, ZBUG_EMAIL_FORM
├── Number Range:  ZNRO_BUG
├── Text Object:   ZBUG_NOTE (Text IDs: Z001, Z002, Z003)
├── Message Class: ZBUG_MSG
└── SMW0 Objects:  ZBT_TMPL_01, ZBT_TMPL_02, ZBT_TMPL_03
```
]

== 2. Database Design

Entity Relationship: `ZBUG_TRACKER` (1:N to `ZBUG_HISTORY`, 1:N to `ZBUG_EVIDENCE`) belongs to `ZBUG_PROJECT` (M:N with `ZBUG_USERS` via `ZBUG_USER_PROJEC`).

=== Table: ZBUG\_TRACKER — 29 fields

#table(
  columns: (0.5cm, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Field*], [*Type*], [*Length*], [*Description*],
  [1],  [`MANDT`],            [CLNT], [3],  [Client (Key)],
  [2],  [`BUG_ID`],           [CHAR], [10], [Bug ID — Key, auto-generated (`BUG0000001`)],
  [3],  [`TITLE`],            [CHAR], [100],[Bug title — mandatory],
  [4],  [`DESC_TEXT`],        [STRING],[0], [Full description — stored as long text Z001],
  [5],  [`SAP_MODULE`],       [CHAR], [20], [SAP module (MM, SD, FI, CO, etc.)],
  [6],  [`PRIORITY`],         [CHAR], [1],  [H=High, M=Medium, L=Low],
  [7],  [`STATUS`],           [CHAR], [20], [Bug status — 10-state lifecycle (CHAR 20, NOT CHAR 1)],
  [8],  [`BUG_TYPE`],         [CHAR], [1],  [C=Code bug (Dev fixes), F=Config bug (Tester self-fixes)],
  [9],  [`REASONS`],          [STRING],[0], [Root cause / transition note — STRING type],
  [10], [`TESTER_ID`],        [CHAR], [12], [Reporter — auto-filled with SY-UNAME on create],
  [11], [`VERIFY_TESTER_ID`], [CHAR], [12], [Final tester assigned for testing phase (Phase B auto-assign)],
  [12], [`DEV_ID`],           [CHAR], [12], [Developer assigned — auto-assign Phase A],
  [13], [`APPROVED_BY`],      [CHAR], [12], [Manager who approved (set on close)],
  [14], [`APPROVED_AT`],      [DATS], [8],  [Approval date],
  [15], [`CREATED_AT`],       [DATS], [8],  [Creation date — auto SY-DATUM],
  [16], [`CREATED_TIME`],     [TIMS], [6],  [Creation time — auto SY-UZEIT],
  [17], [`CLOSED_AT`],        [DATS], [8],  [Closed date (set when status → Resolved/Closed)],
  [18], [`ATT_REPORT`],       [CHAR], [100],[Path/name for bug report evidence file],
  [19], [`ATT_FIX`],          [CHAR], [100],[Path/name for fix confirmation evidence file],
  [20], [`ATT_VERIFY`],       [CHAR], [100],[Path/name for final test confirmation evidence file],
  [21], [`PROJECT_ID`],       [CHAR], [20], [FK → ZBUG\_PROJECT; locked after creation],
  [22], [`SEVERITY`],         [CHAR], [1],  [1=Dump, 2=Very High, 3=High, 4=Normal, 5=Minor],
  [23], [`ERNAM`],            [CHAR], [12], [Created by — auto SY-UNAME],
  [24], [`ERDAT`],            [DATS], [8],  [Created date],
  [25], [`ERZET`],            [TIMS], [6],  [Created time],
  [26], [`AENAM`],            [CHAR], [12], [Last changed by],
  [27], [`AEDAT`],            [DATS], [8],  [Last changed date],
  [28], [`AEZET`],            [TIMS], [6],  [Last changed time],
  [29], [`IS_DEL`],           [CHAR], [1],  [Soft delete flag — 'X' = deleted],
)

=== Table: ZBUG\_USERS — 12 fields

#table(
  columns: (0.5cm, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Field*], [*Type*], [*Length*], [*Description*],
  [1], [`MANDT`],             [CLNT], [3],  [Client (Key)],
  [2], [`USER_ID`],           [CHAR], [12], [SAP username (Key)],
  [3], [`ROLE`],              [CHAR], [1],  [M=Manager, D=Developer, T=Tester],
  [4], [`FULL_NAME`],         [CHAR], [50], [Full name],
  [5], [`SAP_MODULE`],        [CHAR], [20], [SAP module the user specializes in (for auto-assign matching)],
  [6], [`AVAILABLE_STATUS`],  [CHAR], [1],  [A=Available, B=Busy, L=Leave, W=Working],
  [7], [`IS_ACTIVE`],         [CHAR], [1],  [X=Active; used to filter in F4 and auto-assign],
  [8], [`EMAIL`],             [CHAR], [100],[Email address for CL\_BCS notifications],
  [9], [`AENAM`],             [CHAR], [12], [Last changed by],
  [10],[`AEDAT`],             [DATS], [8],  [Last changed date],
  [11],[`AEZET`],             [TIMS], [6],  [Last changed time],
  [12],[`IS_DEL`],            [CHAR], [1],  [Soft delete flag],
)

=== Table: ZBUG\_PROJECT — 16 fields

#table(
  columns: (0.5cm, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Field*], [*Type*], [*Length*], [*Description*],
  [1], [`MANDT`],           [CLNT], [3],   [Client (Key)],
  [2], [`PROJECT_ID`],      [CHAR], [20],  [Project ID (Key) — auto-generated (`PRJ0000001`)],
  [3], [`PROJECT_NAME`],    [CHAR], [100], [Project name — mandatory],
  [4], [`DESCRIPTION`],     [CHAR], [255], [Project description],
  [5], [`START_DATE`],      [DATS], [8],   [Project start date],
  [6], [`END_DATE`],        [DATS], [8],   [Project end date],
  [7], [`PROJECT_MANAGER`], [CHAR], [12],  [Manager user ID (FK → ZBUG\_USERS)],
  [8], [`PROJECT_STATUS`],  [CHAR], [1],   [1=Opening, 2=In Process, 3=Done, 4=Cancelled],
  [9], [`NOTE`],            [CHAR], [255], [Free-text note],
  [10],[`ERNAM`],           [CHAR], [12],  [Created by],
  [11],[`ERDAT`],           [DATS], [8],   [Created date],
  [12],[`ERZET`],           [TIMS], [6],   [Created time],
  [13],[`AENAM`],           [CHAR], [12],  [Last changed by],
  [14],[`AEDAT`],           [DATS], [8],   [Last changed date],
  [15],[`AEZET`],           [TIMS], [6],   [Last changed time],
  [16],[`IS_DEL`],          [CHAR], [1],   [Soft delete flag],
)

=== Table: ZBUG\_USER\_PROJEC — 10 fields

Maps users to projects with a per-project role. Key: MANDT + USER\_ID + PROJECT\_ID.

Note: table name is `ZBUG_USER_PROJEC` (truncated at 18 characters — no final 'T').

=== Table: ZBUG\_HISTORY — 10 fields

#table(
  columns: (0.5cm, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Field*], [*Type*], [*Length*], [*Description*],
  [1], [`MANDT`],        [CLNT], [3],  [Client (Key)],
  [2], [`LOG_ID`],       [NUMC], [10], [Auto-generated log ID (Key)],
  [3], [`BUG_ID`],       [CHAR], [10], [FK → ZBUG\_TRACKER],
  [4], [`CHANGED_BY`],   [CHAR], [12], [Who made the change — SY-UNAME],
  [5], [`CHANGED_AT`],   [DATS], [8],  [Date of change],
  [6], [`CHANGED_TIME`], [TIMS], [6],  [Time of change],
  [7], [`ACTION_TYPE`],  [CHAR], [2],  [CR=Create, AS=Assign, RS=Reassign, ST=Status Change, UP=Update, DL=Delete, AT=Attachment],
  [8], [`OLD_VALUE`],    [CHAR], [100],[Previous value],
  [9], [`NEW_VALUE`],    [CHAR], [100],[New value],
  [10],[`REASON`],       [STRING],[0], [Reason / transition note — STRING type],
)

== 3. Detailed Design

=== 3.1 Bug Creation (UC-05)

The creation flow involves the PAI module, the `Z_BUG_CREATE` FM, and the auto-assign engine. The sequence is:

+ User fills fields on Screen 0300 (Create mode) and clicks "Save"
+ PAI calls `Z_BUG_CHECK_PERMISSION` — verifies role = 'T' or 'M'
+ PAI calls `Z_BUG_CREATE`:
  - Calls `NUMBER_GET_NEXT` on `ZNRO_BUG` → generates BUG\_ID
  - Sets TESTER\_ID = SY-UNAME, ERNAM, ERDAT, ERZET, STATUS = '1'
  - If BUG\_TYPE = 'F' (Config): DEV\_ID = SY-UNAME, STATUS = '2'
  - Calls `SAVE_TEXT` for description (Text ID Z001)
  - Inserts into `ZBUG_TRACKER`
  - Calls `Z_BUG_LOG_HISTORY` (action = 'CR')
  - If BUG\_TYPE = 'C': calls `Z_BUG_AUTO_ASSIGN` (Phase A)
  - Calls `Z_BUG_SEND_EMAIL` (event = 'CREATE' or 'ASSIGN')
  - COMMIT WORK

=== 3.2 Status Transition (UC-08)

The status change flow enforces the role-based transition matrix via Screen 0370:

+ User clicks "Change Status" on Screen 0300
+ PAI calls `CALL SCREEN 0370 STARTING AT 5 5` (modal popup)
+ PBO of 0370 loads current bug info and determines which fields to enable/lock based on current STATUS
+ User selects new status, fills required fields, and clicks "Confirm"
+ PAI of 0370 calls `Z_BUG_CHECK_PERMISSION` (action = 'UPDATE\_STATUS')
+ Validates transition per the v5.0 role-based transition matrix
+ If STATUS → '5' (Fixed): verifies evidence exists in `ZBUG_EVIDENCE` (COUNT > 0)
+ If STATUS → 'V' or 'R': verifies TRANS\_NOTE is non-empty
+ Calls `Z_BUG_UPDATE_STATUS` → updates `ZBUG_TRACKER`, calls `Z_BUG_LOG_HISTORY` (action = 'ST')
+ If STATUS → '5': calls auto-assign Phase B (Fixed → Final Testing or Waiting)
+ Calls `Z_BUG_SEND_EMAIL` (event = 'STATUS\_CHANGE')

=== 3.3 Auto-Assign Engine

The auto-assign engine is implemented in FM `Z_BUG_AUTO_ASSIGN` and called at two points:

*Phase A (on bug create, BUG\_TYPE = 'C'):*
- SELECT DEVs from `ZBUG_USER_PROJEC` WHERE project\_id = bug.project\_id AND role = 'D'
- JOIN `ZBUG_USERS` WHERE sap\_module = bug.sap\_module AND is\_active = 'X' AND is\_del ≠ 'X'
- For each dev: COUNT bugs WHERE dev\_id = dev AND STATUS IN ('2','3','4','6')
- Select dev with lowest count AND count < 5
- If found: set DEV\_ID, STATUS = '2', log history, send email
- If not found: STATUS = 'W', notify Manager

*Phase B (on status → Fixed):*
- SELECT Testers from `ZBUG_USER_PROJEC` WHERE project\_id = bug.project\_id AND role = 'T'
- JOIN `ZBUG_USERS` WHERE sap\_module = bug.sap\_module AND is\_active = 'X'
- For each tester: COUNT bugs WHERE verify\_tester\_id = tester AND STATUS = '6'
- Select tester with lowest count AND count < 5
- If found: set VERIFY\_TESTER\_ID, STATUS = '6', log history, send email
- If not found: STATUS = 'W', notify Manager

=== 3.4 Role-Based Screen Control (LOOP AT SCREEN)

Dynamic field locking is implemented in MODULE `modify_screen_0300 OUTPUT` using screen groups:

#table(
  columns: (2cm, 2.5cm, 1fr),
  align: (center, left, left),
  [*Group*], [*Fields*], [*Lock Condition*],
  [`STS`], [STATUS],                          [Always locked — change only via popup 0370],
  [`BID`], [BUG\_ID],                         [Always locked — auto-generated],
  [`PRJ`], [PROJECT\_ID],                     [Locked once set from project context],
  [`FNC`], [BUG\_TYPE, PRIORITY, SEVERITY],   [Locked for Developer role],
  [`TST`], [TESTER\_ID],                      [Locked for Developer role],
  [`DEV`], [DEV\_ID, VERIFY\_TESTER\_ID],     [Locked for Tester role],
  [`EDT`], [All editable fields],             [Locked in Display mode (input = 0)],
)

The PBO module evaluates `gv_role` (loaded from `ZBUG_USERS` at login) and sets `screen-input = 0` for all fields in the locked groups via `LOOP AT SCREEN ... MODIFY SCREEN`.
