# UAT — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **T-Code:** `ZBUG_WS`
**Version:** v5.0 | **Test Phase:** UAT (User Acceptance Test) | **Date:** 17/04/2026
**Business Key Users:** DEV-089 (Manager), DEV-061 (Developer), DEV-118 (Tester)

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Business Flow | Full system acceptance by key users |
| Test Level | UAT — User Acceptance Test |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial UAT plan — v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. UAT Accounts

| Account | Role | Password | Email |
|---------|------|----------|-------|
| `DEV-089` | Manager (M) | `@Anhtuoi123` | TANTAISERVER2025@GMAIL.COM |
| `DEV-061` | Developer (D) | `@57Dt766` | HUGHNGUYEN1201@GMAIL.COM |
| `DEV-118` | Tester (T) | `Qwer123@` | NGUYENTANTAI.DEV@GMAIL.COM |

---

## 4. UAT Test Scenarios

### Scenario UAT-A: Access & Navigation

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Start the system | — | ZBUG_WS | Run `/nZBUG_WS` → Project Search screen (0410) appears with 3 input fields | DEV-089 | | |
| 2 | List all projects | Screen 0410 | — | Execute with empty filters → Project List (0400) shows all projects | DEV-089 | | |
| 3 | Enter Bug List | Screen 0400 | — | Double-click PRJ0000001 → Bug List (0200) with Dashboard at top | DEV-089 | | |
| 4 | View bug detail | Screen 0200 | — | Select bug → Display → Screen 0300 with 6 tabs | DEV-089 | | |
| 5 | Navigate back | Screen 0300 | — | Back (F3) repeatedly: 0300→0200→0400→0410 | DEV-089 | | |
| 6 | Exit system | Screen 0410 | — | Back (F3) → SAP menu | DEV-089 | | |

---

### Scenario UAT-B: Project Search (Screen 0410)

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Search by Project ID | Screen 0410 | — | Enter Project ID = PRJ0000001 → Execute → only that project shown | DEV-089 | | |
| 2 | Search by Manager | Screen 0410 | — | Enter Manager = DEV-089 → Execute → only DEV-089's projects | DEV-089 | | |
| 3 | Search by Status | Screen 0410 | — | Status = 2 (In Process) → Execute → only In Process projects | DEV-089 | | |
| 4 | F4 lookup | Screen 0410 | — | F4 on Project ID field → popup lists all projects → select fills field | DEV-089 | | |

---

### Scenario UAT-C: Project Management

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Create project | Screen 0400 → Create Project | SE80 | Fill name, manager, dates → Save → PROJECT_ID auto-generated | DEV-089 | | |
| 2 | Add Developer to project | Screen 0500 → Add User | — | USER_ID=DEV-061, ROLE=D → appears in table | DEV-089 | | |
| 3 | Add Tester to project | Screen 0500 → Add User | — | USER_ID=DEV-118, ROLE=T → appears in table | DEV-089 | | |
| 4 | Change project status | Screen 0500 | — | STATUS: 1(Opening) → 2(In Process) → Save | DEV-089 | | |
| 5 | Block Delete with bugs | Screen 0400 → Delete | — | Project has open bugs → error: cannot delete | DEV-089 | | |
| 6 | Developer cannot create project | Screen 0400 | — | DEV-061 clicks Create Project → access denied | DEV-061 | | |

---

### Scenario UAT-D: Bug Management

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Create bug (Tester) | Screen 0200 → Create | ZBUG_WS | Fill TITLE, MODULE=FI, PRIORITY=H, SEVERITY=V → Save | DEV-118 | | |
| 2 | PROJECT_ID pre-filled | Screen 0300 | — | PROJECT_ID = current project, field is locked | DEV-118 | | |
| 3 | Auto-assign Dev | After create | — | If DEV-061 is FI Dev with workload<5: STATUS=Assigned, DEV_ID=DEV-061 | DEV-118 | | |
| 4 | Edit bug (Manager) | Screen 0200 → Change | — | Change TITLE, PRIORITY → Save → updated | DEV-089 | | |
| 5 | FNC fields locked for Dev | Screen 0300 (DEV-061) | — | PRIORITY/SEVERITY/BUG_TYPE fields are input-disabled | DEV-061 | | |
| 6 | Delete bug | Screen 0200 → Delete | — | Confirm → bug gone from list; IS_DEL=X in DB | DEV-089 | | |

---

### Scenario UAT-E: Status Transitions (Popup 0370)

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Open status popup | Screen 0300 → Change Status | — | Popup 0370 shows Bug ID, Title, Reporter, Current Status (read-only) + dropdown | DEV-089 | | |
| 2 | New → Assigned | Popup 0370 | — | Manager selects status=2, DEV_ID=DEV-061 → Confirm | DEV-089 | | |
| 3 | Assigned → In Progress | Popup 0370 | — | DEV-061 selects status=3 → Confirm | DEV-061 | | |
| 4 | Upload fix evidence | Tab Evidence → Upload Fix | — | fix_report.xlsx uploaded | DEV-061 | | |
| 5 | In Progress → Fixed | Popup 0370 | — | DEV-061 selects status=5 → auto-assign tester → STATUS=6 | DEV-061 | | |
| 6 | Final Testing → Resolved | Popup 0370 | — | DEV-118 selects V, TRANS_NOTE='All verified' → Confirm | DEV-118 | | |
| 7 | Cancel popup | Popup 0370 | — | Cancel (F12) → popup closes, status unchanged | DEV-089 | | |
| 8 | Invalid transition blocked | Popup 0370 | — | Tester tries to move New→Resolved directly → transition not in dropdown | DEV-118 | | |

---

### Scenario UAT-F: Evidence Handling

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Download Bug Report template | Screen 0200 → Download Testcase | — | Bug_report.xlsx downloaded and auto-opens | DEV-089 | | |
| 2 | Upload Bug Report | Tab Evidence → Upload Report | — | Bug_report.xlsx uploaded → row in evidence table | DEV-118 | | |
| 3 | Upload Fix evidence | Tab Evidence → Upload Fix | — | fix_report.xlsx uploaded | DEV-061 | | |
| 4 | Upload Confirm evidence | Tab Evidence → Upload Evidence | — | confirm_report.xlsx uploaded | DEV-118 | | |
| 5 | Download evidence | Select row → Download Evidence | — | File saved to local PC with original filename | DEV-089 | | |
| 6 | Evidence required for Fixed | Popup 0370 → select 5 (no evidence) | — | Error: evidence required | DEV-061 | | |

---

### Scenario UAT-G: Dashboard & Bug Search

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Dashboard visible | Screen 0200 | — | Dashboard header shows: Total, New, Assigned, In Progress, Fixed, Final Testing, Resolved, Waiting | DEV-089 | | |
| 2 | Counts correct | Screen 0200 | — | Count bugs manually → matches Dashboard | DEV-089 | | |
| 3 | Dashboard refreshes | After status change → Refresh | — | Counts update | DEV-089 | | |
| 4 | Open Bug Search | Screen 0200 → SEARCH | — | Popup 0210 appears | DEV-089 | | |
| 5 | Search by title | Popup 0210 → Title='FI' → Execute | — | Screen 0220 shows only FI-related bugs | DEV-089 | | |
| 6 | Search by status | Popup 0210 → Status=3 → Execute | — | Only In Progress bugs shown | DEV-089 | | |

---

### Scenario UAT-H: Email, My Bugs, Templates

| No. | Step Name | Menu Path | T-Code | Scenario | Exec | Pass/Fail | Notes |
|-----|-----------|-----------|--------|----------|------|-----------|-------|
| 1 | Send email | Screen 0300 → SENDMAIL | — | Message 'Email sent' → check SOST | DEV-089 | | |
| 2 | My Bugs — Developer | Screen 0400 → My Bugs | — | Only bugs with DEV_ID=DEV-061 listed | DEV-061 | | |
| 3 | My Bugs — Tester | Screen 0400 → My Bugs | — | Bugs where TESTER_ID or VERIFY_TESTER_ID = DEV-118 | DEV-118 | | |
| 4 | Upload Project Excel | Screen 0400 → Upload | — | Upload valid Excel → projects created | DEV-089 | | |

---

## 5. UAT Test Cases (Detailed)

### UAT-TC-01 — Full Happy Path (based on UAT-E + UAT-D)

| NO. | Step | Test Cases | Test Data | Expected Result | Created by | Date |
|-----|------|-----------|-----------|----------------|------------|------|
| 1 | Create bug | TC-01.1: Valid creation | TITLE='FI tax error', MODULE=FI, PRIORITY=H | BUG auto-generated, STATUS=Assigned | DEV-118 | |
| 2 | Accept + InProgress | TC-01.2: Developer accepts | DEV-061 opens popup → status=3 | STATUS=In Progress | DEV-061 | |
| 3 | Fix + evidence | TC-01.3: Upload and fix | fix_report.xlsx → status=5 | STATUS=Final Testing, Tester assigned | DEV-061 | |
| 4 | Resolve | TC-01.4: Tester confirms | DEV-118, TRANS_NOTE='OK' → V | STATUS=Resolved | DEV-118 | |

### UAT-TC-02 — Negative Cases

| NO. | Step | Test Cases | Test Data | Expected Result | Created by | Date |
|-----|------|-----------|-----------|----------------|------------|------|
| 1 | Fixed without evidence | TC-02.1 | Status change 3→5, no evidence | Error: evidence required | DEV-061 | |
| 2 | Resolved without note | TC-02.2 | Status change 6→V, TRANS_NOTE='' | Error: note required | DEV-118 | |
| 3 | Dev create bug | TC-02.3 | DEV-061 → Create in Bug List | Access denied | DEV-061 | |
| 4 | Project Done with open bugs | TC-02.4 | STATUS=3 while bugs open | Error: X open bug(s) | DEV-089 | |

---

## 6. Test Result Sign-Off

| Scenario | Total Cases | Pass | Fail | Sign-Off (User) | Date |
|----------|:-----------:|:----:|:----:|-----------------|------|
| A. Access & Navigation | 6 | | | DEV-089 | |
| B. Project Search | 4 | | | DEV-089 | |
| C. Project Management | 6 | | | DEV-089 | |
| D. Bug Management | 6 | | | DEV-089/118 | |
| E. Status Transitions | 8 | | | DEV-089/061/118 | |
| F. Evidence | 6 | | | DEV-089/061/118 | |
| G. Dashboard & Search | 6 | | | DEV-089 | |
| H. Email, My Bugs | 4 | | | DEV-089/061/118 | |
| **Total** | **46** | | | | |

> **UAT PASS criteria:** All 46 cases Pass (0 Fail). Any Fail must be logged in Test_And_Fix_Bug tracker, fixed, and retested before go-live approval.
