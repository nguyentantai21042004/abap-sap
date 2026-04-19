# Functional Test — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **T-Code:** `ZBUG_WS`
**Version:** v5.0 | **Test Phase:** SIT (System Integration Test) | **Date:** 17/04/2026
**Test Executor:** DEV-089 (Manager), DEV-061 (Developer), DEV-118 (Tester)

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Function ID | ZBUG_WS_v5 |
| Business Flow | Full end-to-end bug lifecycle + project management |
| Test Level | Functional / System Integration Test (SIT) |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial SIT functional test plan — v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. Test Accounts

| Account | Role | Password | Purpose |
|---------|------|----------|---------|
| `DEV-089` | Manager (M) | `@Anhtuoi123` | Project management, status oversight |
| `DEV-061` | Developer (D) | `@57Dt766` | Bug fixing, dev note, evidence |
| `DEV-118` | Tester (T) | `Qwer123@` | Bug creation, testing, confirmation |

---

## 4. Test Cases

### Business Flow 1 — Project Lifecycle

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | Create project | TC-1.1: Create project with valid data | PROJECT_NAME='SIT_Project_01', Manager=DEV-089 | PROJECT_ID auto-generated (PRJ0000001), STATUS=Opening(1) | DEV-089 | |
| 1 | | TC-1.2: Create project — name missing | PROJECT_NAME='' | Error: name required | DEV-089 | |
| 2.1 | Add users | TC-2.1: Add Developer to project | USER_ID=DEV-061, ROLE=D | User listed in TC_USERS table | DEV-089 | |
| 2.2 | | TC-2.2: Add Tester to project | USER_ID=DEV-118, ROLE=T | User listed in TC_USERS table | DEV-089 | |
| 2.3 | | TC-2.3: Duplicate user add | Same USER_ID+PROJECT_ID again | Error or graceful warning | DEV-089 | |
| 2.4 | | TC-2.4: Remove user from project | Select DEV-061 → Remove User | DEV-061 removed from TC_USERS | DEV-089 | |
| 3.1 | Activate project | TC-3.1: Change status Opening → In Process | PROJECT_STATUS → 2 | Status updated, save success | DEV-089 | |
| 3.2 | | TC-3.2: Developer cannot change project status | DEV-061 tries to save project | Error: access denied | DEV-061 | |
| 3.3 | | TC-3.3: Complete project with open bugs | PROJECT_STATUS → 3 (Done), 1 bug still open | Error: cannot mark Done — X open bug(s) | DEV-089 | |
| 3.4 | | TC-3.4: Complete project — all resolved | All bugs STATUS=V → set project Done | PROJECT_STATUS=3, save OK | DEV-089 | |
| 4.1 | Delete project | TC-4.1: Delete empty project | No bugs in project | Project gone from list (IS_DEL=X) | DEV-089 | |

### Business Flow 2 — Bug Creation and Display

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | Create bug | TC-1.1: Create bug valid data | TITLE='Login fails on FI screen', MODULE=FI, PRIORITY=H, SEVERITY=V | BUG_ID auto-gen, STATUS=New(1) or Assigned(2) if Dev available | DEV-118 | |
| 1 | | TC-1.2: Auto-assign fires on create | DEV-061 is FI Dev with workload<5 | STATUS=Assigned(2), DEV_ID=DEV-061 | DEV-118 | |
| 1 | | TC-1.3: Auto-assign → Waiting (no dev) | MODULE=MM, no MM Developer in project | STATUS=Waiting(W), DEV_ID empty | DEV-118 | |
| 2.1 | View bug | TC-2.1: Display mode — all fields locked | Bug List → Display | Screen 0300 opens, all fields input=0, no Save button | DEV-089 | |
| 2.2 | | TC-2.2: Tab navigation | Click each tab | Tabs Bug Info/Description/Dev Note/Tester Note/Evidence/History all load | DEV-089 | |
| 2.3 | | TC-2.3: History tab shows creation | Open History tab after create | Row with ACTION_TYPE=CR, CHANGED_BY=DEV-118, date correct | DEV-089 | |
| 2.4 | | TC-2.4: Bug Info shows pre-filled PROJECT_ID | Open bug from project context | PROJECT_ID matches project, field locked | DEV-118 | |
| 3.1 | Edit bug | TC-3.1: Manager edits all fields | Change TITLE, MODULE, PRIORITY, SEVERITY | All saved to ZBUG_TRACKER, AENAM=DEV-089 | DEV-089 | |
| 3.2 | | TC-3.2: Developer cannot edit FNC group | DEV-061 changes PRIORITY | Field disabled (screen group FNC) | DEV-061 | |
| 3.3 | | TC-3.3: Tester can edit FNC group | DEV-118 changes PRIORITY | Saved OK | DEV-118 | |
| 3.4 | | TC-3.4: Delete bug | Manager deletes bug | IS_DEL=X, bug gone from list | DEV-089 | |

### Business Flow 3 — Bug Lifecycle (Status Transitions)

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | New → Assigned | TC-1.1: Manager assigns manually | Open popup 0370, select status=2, DEV_ID=DEV-061 | STATUS=2, DEV_ID=DEV-061, history ST logged | DEV-089 | |
| 1 | | TC-1.2: DEVELOPER_ID mandatory for →2 | Select status=2, leave DEV_ID empty | Error: developer required | DEV-089 | |
| 2.1 | Assigned → In Progress | TC-2.1: Dev accepts | DEV-061 opens popup, selects status=3 | STATUS=3, history logged | DEV-061 | |
| 2.2 | | TC-2.2: Tester cannot move Assigned→InProgress | DEV-118 tries | Transition blocked | DEV-118 | |
| 2.3 | In Progress → Rejected | TC-2.3: Dev rejects without note | Select status=R, TRANS_NOTE='' | Error: note required | DEV-061 | |
| 2.4 | | TC-2.4: Dev rejects with note | Select status=R, TRANS_NOTE='duplicate bug' | STATUS=R, note saved in Dev Note (Z002) | DEV-061 | |
| 3.1 | In Progress → Fixed | TC-3.1: Fixed without evidence | No evidence uploaded, select status=5 | Error: evidence required | DEV-061 | |
| 3.2 | | TC-3.2: Upload fix evidence | Tab Evidence → Upload Fix → select fix_report.xlsx | File appears in evidence list | DEV-061 | |
| 3.3 | | TC-3.3: Fixed after evidence upload | Select status=5 | STATUS=5, auto-assign Tester fires | DEV-061 | |
| 3.4 | | TC-3.4: Auto-assign to Final Testing | DEV-118 is available FI Tester | STATUS=6, VERIFY_TESTER_ID=DEV-118 | DEV-061 | |
| 4.1 | Final Testing → Resolved | TC-4.1: Resolved without note | DEV-118 selects V, TRANS_NOTE='' | Error: note required | DEV-118 | |
| 4.2 | | TC-4.2: Resolved with note | Select V, TRANS_NOTE='Verified OK' | STATUS=V (terminal), history logged | DEV-118 | |
| 4.3 | Final Testing → In Progress (fail) | TC-4.3: Test fails — reopen | Select status=3, TRANS_NOTE='Test failed: field X' | STATUS=3, log history | DEV-118 | |

### Business Flow 4 — Evidence and Templates

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | Template download | TC-1.1: Download Bug Report template | Screen 0200 → Download Testcase | Bug_report.xlsx downloaded and auto-opened | DEV-089 | |
| 1 | | TC-1.2: Download Fix template | Screen 0200 → Download Fix | fix_report.xlsx downloaded | DEV-089 | |
| 1 | | TC-1.3: Download Confirm template | Screen 0200 → Download Confirm | confirm_report.xlsx downloaded | DEV-118 | |
| 2.1 | Upload report evidence | TC-2.1: Tester uploads bug report | Tab Evidence → Upload Report → Bug_report.xlsx | File in evidence list, ATT_REPORT updated | DEV-118 | |
| 2.2 | | TC-2.2: Developer uploads fix | Upload Fix → fix_report.xlsx | File in list, ATT_FIX updated | DEV-061 | |
| 2.3 | | TC-2.3: Download evidence | Select row → Download Evidence | File saved to local PC | DEV-089 | |

### Business Flow 5 — Dashboard and Bug Search

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | Dashboard | TC-1.1: Dashboard counts correct | Bug List (0200) with known bug data | Total = sum of all statuses; individual counts match SE16 data | DEV-089 | |
| 1 | | TC-1.2: Dashboard updates after change | Change 1 bug status → Refresh | Counts reflect new state | DEV-089 | |
| 2.1 | Bug search | TC-2.1: Search by Bug ID | Popup 0210, Bug ID='BUG000001' | Screen 0220 shows exactly that bug | DEV-089 | |
| 2.2 | | TC-2.2: Search by title keyword | Title='crash' | All bugs with 'crash' in title shown | DEV-089 | |
| 2.3 | | TC-2.3: Search by status | Status=3 | Only In Progress bugs shown | DEV-089 | |
| 2.4 | | TC-2.4: No match → empty result | Bug ID='XXXXXXXX' | Screen 0220 empty, message shown | DEV-089 | |

### Business Flow 6 — Access Control

| NO. | Step | Test Cases | Input | Expected Result | Exec By | Pass/Fail |
|-----|------|-----------|-------|----------------|---------|-----------|
| 1 | Role enforcement | TC-1.1: Developer cannot create bug | Bug List → Create button | Button absent or message: access denied | DEV-061 | |
| 1 | | TC-1.2: Developer cannot delete bug | Select bug → Delete | Error: access denied | DEV-061 | |
| 1 | | TC-1.3: Tester cannot create project | Project List → Create Project | Error: access denied | DEV-118 | |
| 1 | | TC-1.4: Manager can create bug and project | Create bug + create project | Both succeed | DEV-089 | |
| 2.1 | My Bugs filter | TC-2.1: Dev sees only assigned bugs | DEV-061 clicks My Bugs | Only bugs with DEV_ID=DEV-061 listed | DEV-061 | |
| 2.2 | | TC-2.2: Tester sees own bugs | DEV-118 clicks My Bugs | Bugs where TESTER_ID or VERIFY_TESTER_ID = DEV-118 | DEV-118 | |

---

## 5. Test Data Description

| Object | ID | Value | Purpose |
|--------|-----|-------|---------|
| Project | PRJ0000001 | SIT_Project_01 | Main SIT test project |
| User — Manager | DEV-089 | ROLE=M, MODULE=ABAP | All manager test cases |
| User — Developer | DEV-061 | ROLE=D, MODULE=FI | Developer test cases |
| User — Tester | DEV-118 | ROLE=T, MODULE=FI | Tester test cases |
| Bug | BUG000001 | Title='Login fails', MODULE=FI, PRIORITY=H | Status lifecycle tests |
| Evidence file | Bug_report.xlsx | Downloaded from ZBT_TMPL_01 | Evidence upload tests |
| Evidence file | fix_report.xlsx | Downloaded from ZBT_TMPL_02 | Fix upload tests |

---

## 6. Test Result Summary

| Business Flow | Total Cases | Pass | Fail | Notes |
|--------------|:-----------:|:----:|:----:|-------|
| 1. Project Lifecycle | 11 | | | |
| 2. Bug Creation & Display | 11 | | | |
| 3. Bug Lifecycle (Status) | 13 | | | |
| 4. Evidence & Templates | 6 | | | |
| 5. Dashboard & Search | 6 | | | |
| 6. Access Control | 6 | | | |
| **Total** | **53** | | | |
