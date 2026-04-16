# Test Scenario — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **T-Code:** `ZBUG_WS`
**Version:** v5.0 | **Test Phase:** SIT — End-to-End Scenarios | **Date:** 17/04/2026
**Test Executor:** DEV-089 / DEV-061 / DEV-118

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Business Flow | All cross-functional end-to-end scenarios |
| Test Level | SIT — Scenario-based integration testing |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial test scenario plan — v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. Test Scenario Coverage Matrix

The matrix maps each **Step** (row) to the **Test Cases** (columns) that cover it.
`✓` = covered | blank = not applicable

| No. | Step Name | S1 | S2 | S3 | S4 | S5 | S6 | S7 | S8 |
|-----|------------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| 1 | Run ZBUG_WS → Project Search screen (0410) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 2 | Search/filter projects → Project List (0400) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 3 | Create project + add users | ✓ | | | | | | | |
| 4 | Double-click project → Bug List (0200) + Dashboard | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 5 | Create bug (Tester) | ✓ | ✓ | ✓ | | | | | |
| 6 | Auto-assign Developer fires | ✓ | ✓ | | | | | | ✓ |
| 7 | Assigned → In Progress (Developer) | ✓ | ✓ | ✓ | | | | | |
| 8 | In Progress → Pending (pause) | | | ✓ | | | | | |
| 9 | Pending → Assigned again (reassign) | | | ✓ | | | | | |
| 10 | Upload fix evidence (Developer) | ✓ | ✓ | ✓ | | | | | |
| 11 | In Progress → Fixed | ✓ | ✓ | ✓ | | | | | |
| 12 | Auto-assign Tester fires | ✓ | ✓ | | | | | | ✓ |
| 13 | Final Testing → Resolved (Tester confirms) | ✓ | | | | | | | |
| 14 | Final Testing → In Progress (test fails) | | ✓ | | | | | | |
| 15 | Developer rejects bug (Rejected flow) | | | | ✓ | | | | |
| 16 | Manager manually assigns (Waiting flow) | | | | | ✓ | | | |
| 17 | Bug Search popup (0210 → 0220) | | | | | | ✓ | | |
| 18 | Dashboard counts verified | ✓ | | | | | | ✓ | |
| 19 | Email notification sent | ✓ | | ✓ | | | | | |
| 20 | Project marked Done after all bugs resolved | ✓ | | | | | | | |

**Scenario codes:**
- **S1** — Full Happy Path (complete lifecycle)
- **S2** — Lifecycle with test failure (Final Testing → InProgress → retry)
- **S3** — Pending / Reassign flow
- **S4** — Rejection flow
- **S5** — Waiting / Manual assign flow
- **S6** — Bug Search flow
- **S7** — Dashboard accuracy
- **S8** — Auto-assign no-match (Waiting)

---

## 4. Detailed Test Cases

### Scenario S1 — Full Happy Path

**Goal:** One bug goes through the complete lifecycle from New to Resolved, project marked Done.

**Pre-condition:** Project PRJ0000001 exists, DEV-061 is FI Developer, DEV-118 is FI Tester, both assigned to project.

| NO. | Step | Menu Path | T-Code | Action | Expected Result | Exec | Pass/Fail |
|-----|------|-----------|--------|--------|----------------|------|-----------|
| 1 | Login as Tester | SAP GUI | — | Login DEV-118 | SAP menu shown | DEV-118 | |
| 2.1 | Open system | — | ZBUG_WS | Run t-code | Screen 0410 (Project Search) appears | DEV-118 | |
| 2.2 | Find project | Screen 0410 | — | Execute with empty fields | PRJ0000001 visible in list | DEV-118 | |
| 2.3 | Enter project | Screen 0400 | — | Double-click PRJ0000001 | Screen 0200 Bug List + Dashboard | DEV-118 | |
| 3 | Create bug | Screen 0200 | — | Create → fill TITLE='FI tax calc wrong', MODULE=FI, PRIORITY=H | BUG000001 created, STATUS=Assigned, DEV_ID=DEV-061 | DEV-118 | |
| 4 | Login as Developer | — | — | Switch to DEV-061 | — | DEV-061 | |
| 5.1 | Accept bug | Screen 0200 | — | Select BUG000001 → Change → Change Status | Popup 0370 appears | DEV-061 | |
| 5.2 | Set In Progress | Screen 0370 | — | Select status=3 → Confirm | STATUS=In Progress | DEV-061 | |
| 6.1 | Upload fix | Screen 0300 | — | Tab Evidence → Upload Fix → fix_report.xlsx | Evidence row appears | DEV-061 | |
| 6.2 | Set Fixed | Screen 0300 | — | Change Status → select 5 → Confirm | STATUS=Fixed, auto-assign Tester → STATUS=Final Testing(6) | DEV-061 | |
| 7 | Login as Tester | — | — | Switch to DEV-118 | — | DEV-118 | |
| 8.1 | Open bug | Screen 0200 | — | Select BUG000001 → Change → Change Status | Popup 0370 shows status=Final Testing | DEV-118 | |
| 8.2 | Resolve | Screen 0370 | — | Select V, TRANS_NOTE='Verified all OK' → Confirm | STATUS=Resolved(V) | DEV-118 | |
| 9 | Login as Manager | — | — | Switch to DEV-089 | — | DEV-089 | |
| 10.1 | Mark project Done | Screen 0400 | — | Change PRJ0000001 → STATUS=3 (Done) → Save | PROJECT_STATUS=Done(3) | DEV-089 | |

---

### Scenario S2 — Lifecycle with Test Failure

**Goal:** Tester fails the bug, sends it back to In Progress; Dev fixes again; Tester resolves.

| NO. | Step | Action | Expected Result | Exec | Pass/Fail |
|-----|------|--------|----------------|------|-----------|
| 1 | Reach Final Testing | (same as S1 steps 1–6.2) | STATUS=6 | DEV-061 | |
| 2.1 | Tester opens popup | Change Status on bug in Final Testing | Popup 0370, dropdown: V or 3 | DEV-118 | |
| 2.2 | Fail test → In Progress | Select status=3, TRANS_NOTE='Field X still wrong' | STATUS=3, TRANS_NOTE saved, history logged | DEV-118 | |
| 3.1 | Developer re-fixes | Upload new fix evidence + Change Status → 5 | STATUS=Fixed, auto-assign tester again | DEV-061 | |
| 3.2 | Tester re-verifies | Change Status → V, TRANS_NOTE='All clear' | STATUS=V (Resolved) | DEV-118 | |

---

### Scenario S3 — Pending / Reassign

**Goal:** Developer pauses a bug (Pending), Manager reassigns to different Developer.

| NO. | Step | Action | Expected Result | Exec | Pass/Fail |
|-----|------|--------|----------------|------|-----------|
| 1 | Bug is In Progress | DEV-061 has STATUS=3 | — | DEV-061 | |
| 2 | Set Pending | Change Status → 4 | STATUS=Pending | DEV-061 | |
| 3 | Manager reassigns | Change Status → 2, DEV_ID=DEV-061 (or new Dev) | STATUS=Assigned | DEV-089 | |
| 4 | Dev re-accepts | Change Status → 3 | STATUS=In Progress | DEV-061 | |

---

### Scenario S4 — Rejection Flow

**Goal:** Developer rejects bug as invalid; Manager reviews.

| NO. | Step | Action | Expected Result | Exec | Pass/Fail |
|-----|------|--------|----------------|------|-----------|
| 1 | Bug is Assigned | STATUS=2, DEV_ID=DEV-061 | — | — | |
| 2 | Dev rejects without note | Change Status → R, TRANS_NOTE='' | Error: note required | DEV-061 | |
| 3 | Dev rejects with note | Change Status → R, TRANS_NOTE='Not a bug — by design' | STATUS=R, note saved | DEV-061 | |
| 4 | History shows rejection | Open History tab | ACTION_TYPE='ST', NEW_VALUE='R', REASON='Not a bug...' | DEV-089 | |

---

### Scenario S5 — Waiting / Manual Assignment

**Goal:** No matching Developer → bug goes to Waiting; Manager manually assigns.

| NO. | Step | Action | Expected Result | Exec | Pass/Fail |
|-----|------|--------|----------------|------|-----------|
| 1 | Create bug, no MM Dev | MODULE=MM, no MM Developer in project | STATUS=W (Waiting), DEV_ID empty | DEV-118 | |
| 2 | Manager assigns manually | Change Status → 2, enter DEV_ID=DEV-061 | STATUS=Assigned, DEV_ID=DEV-061 | DEV-089 | |
| 3 | Continue lifecycle | Dev accepts → In Progress → ... | Normal flow continues | DEV-061 | |

---

### Scenario S6 — Bug Search Flow

**Goal:** Verify bug search popup and results screen work correctly.

| NO. | Step | Menu Path | Action | Expected Result | Exec | Pass/Fail |
|-----|------|-----------|--------|----------------|------|-----------|
| 1 | Open Bug Search | Screen 0200 | Click SEARCH button | Popup 0210 appears with 6 search fields | DEV-089 | |
| 2.1 | Search by Bug ID | Popup 0210 | Enter BUG000001 → Execute | Screen 0220 shows 1 result | DEV-089 | |
| 2.2 | Search by title | Popup 0210 | TITLE='tax' → Execute | All bugs with 'tax' in title shown | DEV-089 | |
| 2.3 | Search by status | Popup 0210 | STATUS=3 → Execute | Only In Progress bugs | DEV-089 | |
| 3 | View bug from results | Screen 0220 | Select row → Display | Bug Detail (0300) opens | DEV-089 | |
| 4 | Back from results | Screen 0220 | Back | Returns to Bug List (0200) | DEV-089 | |

---

### Scenario S7 — Dashboard Accuracy

**Goal:** Confirm Dashboard header shows correct counts at each step.

| NO. | Step | Action | Expected Dashboard | Exec | Pass/Fail |
|-----|------|--------|-------------------|------|-----------|
| 1 | Initial state | Open Bug List with 3 bugs: 1 New, 1 In Progress, 1 Resolved | Total=3, New=1, InProgress=1, Resolved=1 | DEV-089 | |
| 2 | Change 1 bug to Fixed | Status change → 5 | Total=3, InProgress=0, Fixed=1, Resolved=1 | DEV-089 | |
| 3 | After Refresh | Click Refresh on toolbar | Dashboard updates to reflect new counts | DEV-089 | |

---

### Scenario S8 — Auto-Assign No-Match

**Goal:** Confirm Waiting state is set correctly when no Developer/Tester matches.

| NO. | Step | Action | Expected Result | Exec | Pass/Fail |
|-----|------|--------|----------------|------|-----------|
| 1 | No Developer for module | Create bug, MODULE=SD, no SD Dev in project | STATUS=W, DEV_ID empty, email to Manager | DEV-118 | |
| 2 | No Tester available | Bug reaches Fixed, no Tester available | STATUS=W, VERIFY_TESTER_ID empty | DEV-061 | |
| 3 | Manager assigns manually | Both cases: Manager opens popup → assigns | Status progresses correctly | DEV-089 | |

---

## 5. Test Data Description

| Object | ID/Value | Notes |
|--------|----------|-------|
| Project | PRJ0000001 — SIT_Project_01 | Used across all scenarios |
| User: Manager | DEV-089, ROLE=M, MODULE=ABAP | Full access |
| User: Developer | DEV-061, ROLE=D, MODULE=FI | FI module |
| User: Tester | DEV-118, ROLE=T, MODULE=FI | FI module |
| Bug (main) | BUG000001, MODULE=FI, PRIORITY=H | S1–S4 main test bug |
| Bug (waiting) | BUG000002, MODULE=SD | S5/S8 waiting flow bug |
| Evidence files | Bug_report.xlsx, fix_report.xlsx, confirm_report.xlsx | Downloaded from SMW0 ZBT_TMPL_01/02/03 |
