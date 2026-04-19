# TR Management — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **Package:** `ZBUGTRACK`
**Version:** v5.0 | **Phase:** SIT / UAT / Go-Live | **Date:** 17/04/2026
**Team Lead / Basis:** DEV-089 | **Developer:** DEV-061 | **Tester:** DEV-118

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Transport Phase | v5.0 Deployment (UAT → PRD) |
| SAP System | S40 Client 324 |
| Package | `ZBUGTRACK` |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Modified Date | Modified by |
|-----|---------|-------------|--------------|-------------|
| 1 | 1.0 | Initial TR plan for v5.0 deployment | 17/04/2026 | DEV-089 |

---

## 3. TR Type Reference

| Type | Description |
|------|-------------|
| Workbench | ABAP code, screens, GUI statuses, Data Dictionary objects (SE38, SE51, SE41, SE11, SE93) |
| Customizing | SPRO configuration (not applicable for this project — custom ABAP only) |

---

## 4. Transport Request Log

> **Note:** TR numbers below are placeholders in format `S40K9XXXXX`. Actual TR numbers are assigned by SAP during development. Fill in real numbers when TRs are created.
>
> **Import order is critical.** Always import in sequence (TR-01 → TR-02 → ... → TR-08). Importing code before DB objects causes activation errors.

| No. | Owner | Account | Type | TR | Prerequisite TR | Description | Import By (UAT) | Release Date (UAT) | Import By (PRD) | Release Date (PRD) |
|-----|-------|---------|------|-----|----------------|-------------|----------------|-------------------|----------------|-------------------|
| TR-01 | DEV-089 | DEV-089 | Workbench | S40K9000001 | — | **DB: ZBUG_EVIDENCE table** — Create table ZBUG_EVIDENCE (11 fields: BUG_ID, EVIDENCE_ID, FILE_NAME, FILE_TYPE, FILE_SIZE, UPLOADED_BY, UPLOADED_AT, CONTENT TYPE RAWSTRING, DESCRIPTION, PROJECT_ID, EVIDENCE_TYPE) in SE11. Package ZBUGTRACK. | DEV-089 | | DEV-089 | |
| TR-02 | DEV-089 | DEV-089 | Workbench | S40K9000002 | TR-01 | **DB: ZBUG_TRACKER extension** — Add 13 new fields to ZBUG_TRACKER: SAP_MODULE (zde_sap_module CHAR20), BUG_TYPE, PRIORITY, SEVERITY, DEVELOPER_ID, TESTER_ID, FIXED_DATE, TESTED_DATE, TRANS_NOTE (STRING), CREATED_TIME, UPDATED_TIME + any missing Data Elements/Domains. | DEV-089 | | DEV-089 | |
| TR-03 | DEV-089 | DEV-089 | Workbench | S40K9000003 | TR-02 | **DB: ZBUG_PROJECT table** — Create table ZBUG_PROJECT (16 fields: PROJECT_ID, PROJECT_NAME, DESCRIPTION, STATUS, MANAGER_ID, CREATED_BY, CREATED_AT, CREATED_TIME, UPDATED_BY, UPDATED_AT, UPDATED_TIME, PRIORITY, CATEGORY, START_DATE, END_DATE, MEMBER_COUNT). | DEV-089 | | DEV-089 | |
| TR-04 | DEV-089 | DEV-089 | Workbench | S40K9000004 | TR-03 | **DB: ZBUG_USER_PROJEC + ZBUG_USERS extension** — Create ZBUG_USER_PROJEC (10 fields: PROJECT_ID, USER_ID, ROLE, ASSIGNED_BY, ASSIGNED_AT, ACTIVE, etc.). Add 4 new fields to ZBUG_USERS: EMAIL, FULL_NAME, DEPARTMENT, SKILL_LEVEL. | DEV-089 | | DEV-089 | |
| TR-05 | DEV-089 | DEV-089 | Workbench | S40K9000005 | TR-04 | **SE51: 4 new screens** — Screen 0410 (Project Search, Normal), Screen 0370 (Status Transition Popup, Modal Dialog 80x15), Screen 0210 (Bug Search Input, Modal Dialog 80x20), Screen 0220 (Bug Search Results, Normal 80x35). Includes flow logic PBO/PAI and all layout elements. | DEV-089 | | DEV-089 | |
| TR-06 | DEV-089 | DEV-089 | Workbench | S40K9000006 | TR-05 | **SE41: GUI Statuses + Title Bars** — Create STATUS_0410 (EXECUTE/BACK/EXIT/CANCEL), STATUS_0370 (CONFIRM/UP_TRANS/CANCEL), STATUS_0210 (EXECUTE/CANCEL), STATUS_0220 (BACK/EXIT/CANCEL). Update STATUS_0200 (+SEARCH button). Create Title Bars T_0410/T_0370/T_0210/T_0220. | DEV-089 | | DEV-089 | |
| TR-07 | DEV-089 | DEV-089 | Workbench | S40K9000007 | TR-06 | **SE38: CODE v5.0 — All 6 includes** — Z_BUG_WS_TOP, Z_BUG_WS_F00, Z_BUG_WS_PBO, Z_BUG_WS_PAI, Z_BUG_WS_F01, Z_BUG_WS_F02. Includes all v5.0 features: 10-state lifecycle, auto-assign, Screen 0370 popup, matrix logic, bug search, dashboard header, 11 UAT bug fixes. | DEV-089 | | DEV-089 | |
| TR-08 | DEV-089 | DEV-089 | Workbench | S40K9000008 | TR-07 | **SE93: T-Code ZBUG_WS update** — Change initial screen from 0400 → 0410. GUI status from STATUS_0400 → STATUS_0410. | DEV-089 | | DEV-089 | |
| TR-09 | DEV-089 | DEV-089 | Workbench | S40K9000009 | TR-07 | **SMW0: Template files rename** — Upload 3 renamed templates: Bug_report.xlsx (was ZBUGTRACKER_TEMPLATE), fix_report.xlsx (was ZBUGFIX_TEMPLATE), confirm_report.xlsx (was ZBUGCONFIRM_TEMPLATE). Object type: W3MIME / Binary Web Object. | DEV-089 | | DEV-089 | |

---

## 5. Post-Import Actions (Manual — Not in TR)

The following steps must be performed **manually after TR import** — they cannot be transported:

| Step | Action | Tool | Account | When |
|------|--------|------|---------|------|
| M-01 | Activate all imported objects (activate queue) | SE80 / SE38 Activate | DEV-089 | After TR-07 import |
| M-02 | Run data migration script: UPDATE ZBUG_TRACKER SET STATUS = 'V' WHERE STATUS = '6' | SE38 (one-time program) or SE16 mass change | DEV-089 | After TR-07 import, before UAT Round 2 |
| M-03 | Verify ZBUG_EVIDENCE table exists and is active | SE11 → ZBUG_EVIDENCE → Display | DEV-089 | After TR-01 import |
| M-04 | Load test data: 30 mock users in ZBUG_USERS (for auto-assign testing) | SE16 → ZBUG_USERS → insert | DEV-089 | Before UAT Round 2 |
| M-05 | Assign test users to test projects in ZBUG_USER_PROJEC | SE16 → ZBUG_USER_PROJEC → insert | DEV-089 | Before UAT Round 2 |
| M-06 | Quick smoke test: `/nZBUG_WS` → Screen 0410 appears | SM50 / Direct T-code | DEV-089 | After TR-08 import |

---

## 6. Import Sequence Summary

```
TR-01 (ZBUG_EVIDENCE)
  ↓
TR-02 (ZBUG_TRACKER +13 fields)
  ↓
TR-03 (ZBUG_PROJECT)
  ↓
TR-04 (ZBUG_USER_PROJEC + ZBUG_USERS ext)
  ↓
TR-05 (SE51: 4 new screens)
  ↓
TR-06 (SE41: GUI Statuses + Title Bars)
  ↓
TR-07 (SE38: CODE v5.0 — all 6 includes)  ← Core code, depends on all above
  ↓
TR-08 (SE93: T-Code update 0400→0410)     ← Must come after TR-07
TR-09 (SMW0: template files)               ← Independent, can import with TR-08
```

> **Rule:** Never import TR-07 before TR-01~TR-04. ABAP code references ZBUG_EVIDENCE and new ZBUG_TRACKER fields — activation will fail if tables not present.

---

## 7. Rollback Plan

If critical issues found in UAT that require rollback:

| TR | Rollback Action |
|----|----------------|
| TR-07 / TR-08 | Re-import previous CODE v4.2 TR (keep on file). Re-set SE93 initial screen back to 0400. |
| TR-05 / TR-06 | New screens (0410, 0370, 0210, 0220) are additive — no rollback needed unless screen 0410 must not exist. |
| TR-01~TR-04 | DB table additions are additive — no rollback needed. Do NOT delete new fields if any v4.2 code references them. |
| M-02 (migration) | If migration `6→V` run: reverse with `UPDATE ZBUG_TRACKER SET STATUS = '6' WHERE STATUS = 'V'`. Run before re-importing old code. |

---

## 8. UAT Sign-Off Checklist

| # | Checkpoint | Verified by | Date | Sign-Off |
|---|-----------|-------------|------|----------|
| 1 | All TRs (TR-01 to TR-09) successfully imported to UAT without errors | DEV-089 | | |
| 2 | Manual steps M-01 to M-06 completed | DEV-089 | | |
| 3 | Status migration script executed: no STATUS='6' records remain | DEV-089 | | |
| 4 | UAT Round 2 — all 46 cases PASS | DEV-089, DEV-061, DEV-118 | | |
| 5 | 11 UAT Round 1 bugs verified FIXED | DEV-089 | | |
| 6 | T-Code ZBUG_WS starts on Screen 0410 (Project Search) | DEV-089 | | |
| 7 | Auto-assign works: New→Assigned (Developer) | DEV-061 | | |
| 8 | Auto-assign works: Fixed→FinalTesting (Tester) | DEV-118 | | |
| 9 | Status transition matrix enforced for all 3 roles | DEV-089, DEV-061, DEV-118 | | |
| 10 | Evidence upload required before Fixed (5) transition | DEV-118 | | |
| **PRD Go-Live approved** | | **DEV-089 (Manager)** | | |

---

## 9. Accounts & Responsibilities

| Account | Role | TR Responsibility |
|---------|------|------------------|
| `DEV-089` | Manager + Basis | TR owner, all imports, sign-off authority |
| `DEV-061` | Developer | Code changes (included in TR-07) |
| `DEV-118` | Tester | UAT execution, test sign-off |
