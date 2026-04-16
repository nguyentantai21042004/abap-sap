# Unit Test — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **Package:** `ZBUGTRACK`
**T-Code:** `ZBUG_WS` | **Version:** v5.0 | **Date:** 17/04/2026
**Developer:** DEV-089 (Manager) / DEV-061 (Developer)

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Function ID | ZBUG_WS_v5 |
| Test Level | Unit Test (developer-level, pre-SIT) |
| Test Executor | DEV-089 / DEV-061 |
| Version | 1.0 |
| Date | 17/04/2026 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial unit test plan for v5.0 | All | 17/04/2026 | DEV-089 |

---

## 3. Scope

Unit tests cover individual FORM routines and processing modules at the code level. Each test verifies one specific function in isolation using known input data.

**Target includes:**
- `Z_BUG_WS_F01` — Business logic (primary target)
- `Z_BUG_WS_F02` — Helper functions
- `Z_BUG_WS_PAI` — User command processing
- `Z_BUG_WS_PBO` — Screen population logic

**Test accounts:**

| Account | Role | Purpose |
|---------|------|---------|
| `DEV-089` | Manager (M) | Tests requiring Manager role |
| `DEV-061` | Developer (D) | Tests requiring Developer role |
| `DEV-118` | Tester (T) | Tests requiring Tester role |

---

## 4. Unit Test Cases

### 1. FORM auto_assign_developer

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 1.1 | Assign Dev when suitable Dev exists | BUG_ID='BUG000001', SAP_MODULE='FI', PROJECT_ID='PRJ001' — DEV-061 is FI Dev with 0 workload | DEV_ID set to 'DEV-061', STATUS changes '1'→'2', ZBUG_HISTORY record inserted | | |
| 1.2 | No Dev → status Waiting | SAP_MODULE='MM' — no MM Developer in project | STATUS = 'W', DEV_ID empty, history log ACTION='ST' | | |
| 1.3 | Dev at max workload (5) → skip | DEV-061 has 5 active bugs | System skips DEV-061, tries next Dev; if none → Waiting | | |
| 1.4 | Module mismatch → Waiting | Bug module='SD', no SD Developer in project | STATUS = 'W' | | |

### 2. FORM auto_assign_tester

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 2.1 | Assign Tester when available | BUG_ID='BUG000001', STATUS='5' (Fixed), SAP_MODULE='FI', PROJECT_ID='PRJ001' — DEV-118 is FI Tester with 0 workload | VERIFY_TESTER_ID='DEV-118', STATUS='6' (Final Testing), history logged | | |
| 2.2 | No Tester → Waiting | No Tester with matching module in project | STATUS='W', VERIFY_TESTER_ID empty | | |
| 2.3 | Tester at max workload (5) | DEV-118 has 5 bugs in Final Testing | Skip, try next; if none → Waiting | | |

### 3. FORM validate_transition

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 3.1 | Manager: New → Assigned (valid) | current='1', new='2', role='M' | cv_valid = TRUE | | |
| 3.2 | Manager: New → Waiting (valid) | current='1', new='W', role='M' | cv_valid = TRUE | | |
| 3.3 | Developer cannot move New → Assigned | current='1', new='2', role='D' | cv_valid = FALSE | | |
| 3.4 | Developer: Assigned → In Progress (valid) | current='2', new='3', role='D' | cv_valid = TRUE | | |
| 3.5 | Developer: In Progress → Fixed (valid) | current='3', new='5', role='D' | cv_valid = TRUE | | |
| 3.6 | Tester: Final Testing → Resolved (valid) | current='6', new='V', role='T' | cv_valid = TRUE | | |
| 3.7 | Tester: Final Testing → In Progress (test fail) | current='6', new='3', role='T' | cv_valid = TRUE | | |
| 3.8 | Invalid direct jump New → Resolved | current='1', new='V', role='M' | cv_valid = FALSE | | |
| 3.9 | Developer cannot reject from Resolved | current='V', new='R', role='D' | cv_valid = FALSE | | |

### 4. FORM log_history

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 4.1 | Create action logged | ACTION_TYPE='CR', BUG_ID='BUG000001' | New row in ZBUG_HISTORY with LOG_ID, CHANGED_BY=sy-uname, CHANGED_AT=sy-datum | | |
| 4.2 | Status change logged | ACTION_TYPE='ST', OLD_VALUE='1', NEW_VALUE='2' | ZBUG_HISTORY row has correct OLD/NEW values | | |
| 4.3 | LOG_ID auto-increments | 3 history entries for same bug | LOG_IDs are sequential (MAX+1) | | |
| 4.4 | Reason stored as STRING | REASON='Long text with special chars äöü' | REASON saved and retrieved without truncation | | |

### 5. FORM save_bug

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 5.1 | Create new bug | TITLE='Login crash', SAP_MODULE='FI', PRIORITY='H', TESTER_ID='DEV-118' | Bug inserted to ZBUG_TRACKER, BUG_ID auto-generated (BUG000001), CREATED_AT=sy-datum | | |
| 5.2 | BUG_ID uniqueness | Create 2 bugs in sequence | Second bug ID = first + 1 | | |
| 5.3 | Title empty → error | TITLE = '' | Message E 'Title is required', no INSERT | | |
| 5.4 | PROJECT_ID required | PROJECT_ID = '' | Message E, no INSERT | | |
| 5.5 | Update existing bug | BUG_ID='BUG000001', change TITLE | MODIFY ZBUG_TRACKER, AENAM=sy-uname, AEDAT=sy-datum | | |
| 5.6 | Soft delete | Delete BUG_ID='BUG000001' | IS_DEL='X' set, record still in DB, not visible in list | | |

### 6. FORM save_project

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 6.1 | Create project | PROJECT_NAME='Test Project' | PROJECT_ID auto-generated (PRJ0000001), PROJECT_STATUS='1' | | |
| 6.2 | Project name required | PROJECT_NAME = '' | Error message, no INSERT | | |
| 6.3 | Mark project Done — open bugs block | PROJECT_STATUS='3', 2 open bugs exist | Error: 'Cannot mark Done: 2 open bug(s)' | | |
| 6.4 | Mark project Done — all resolved OK | All bugs STATUS='V' or '7' | PROJECT_STATUS='3' saved successfully | | |
| 6.5 | Soft delete project | Delete project | IS_DEL='X', project invisible | | |

### 7. FORM upload_evidence

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 7.1 | Upload valid file | BUG_ID='BUG000001', file=Bug_report.xlsx | Row inserted in ZBUG_EVIDENCE, EVD_ID auto-generated, CONTENT populated | | |
| 7.2 | Download uploaded file | EVD_ID from 7.1 | File saved to local PC, size matches | | |
| 7.3 | Delete evidence | EVD_ID from 7.1 | Row deleted from ZBUG_EVIDENCE | | |

### 8. FORM validate_transition — Evidence Check

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 8.1 | Fixed without evidence → blocked | STATUS change 3→5, ZBUG_EVIDENCE count=0 for bug | Error: 'Evidence required before Fixed' | | |
| 8.2 | Fixed with evidence → allowed | ZBUG_EVIDENCE count>0 | Transition allowed | | |
| 8.3 | Resolved without TRANS_NOTE → blocked | STATUS change 6→V, TRANS_NOTE='' | Error: 'Transition note required' | | |
| 8.4 | Rejected without TRANS_NOTE → blocked | STATUS change 3→R, TRANS_NOTE='' | Error: 'Transition note required' | | |

### 9. FORM execute_bug_search

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 9.1 | Search by Bug ID exact | GV_SRCH_BUG_ID='BUG000001' | GT_SEARCH_RESULTS contains exactly 1 row | | |
| 9.2 | Search by title substring | GV_SRCH_TITLE='login' | All bugs with 'login' in TITLE returned | | |
| 9.3 | Search by status | GV_SRCH_STATUS='3' | Only In Progress bugs returned | | |
| 9.4 | Search by module | GV_SRCH_MODULE='FI' | Only FI bugs returned | | |
| 9.5 | Combined criteria | GV_SRCH_MODULE='FI', GV_SRCH_STATUS='3' | FI bugs that are In Progress only | | |
| 9.6 | No criteria → all project bugs | All search fields empty | All bugs in current project returned | | |
| 9.7 | No results | GV_SRCH_BUG_ID='NOTEXIST' | GT_SEARCH_RESULTS empty, message shown | | |

### 10. FORM download_template (Z_BUG_WS_F02)

| ID | Test Case | Input | Expected Result | Pass/Fail | Evidence |
|----|-----------|-------|----------------|-----------|----------|
| 10.1 | Download Bug Report template | Fcode=DN_TC | Bug_report.xlsx saved from SMW0 object ZBT_TMPL_01 | | |
| 10.2 | Download Fix template | Fcode=DN_PROOF | fix_report.xlsx saved from ZBT_TMPL_02 | | |
| 10.3 | Download Confirm template | Fcode=DN_CONF | confirm_report.xlsx saved from ZBT_TMPL_03 | | |

---

## 5. Evidence Sheet

*(Paste screenshots here per test case ID — e.g. screenshot for UT-1.1 showing SE16N record in ZBUG_HISTORY, screenshot for UT-5.1 showing ZBUG_TRACKER new row, etc.)*

---

## 6. Test Summary

| Function | Total Cases | Pass | Fail | Notes |
|----------|:-----------:|:----:|:----:|-------|
| 1. auto_assign_developer | 4 | | | |
| 2. auto_assign_tester | 3 | | | |
| 3. validate_transition | 9 | | | |
| 4. log_history | 4 | | | |
| 5. save_bug | 6 | | | |
| 6. save_project | 5 | | | |
| 7. upload_evidence | 3 | | | |
| 8. evidence check | 4 | | | |
| 9. execute_bug_search | 7 | | | |
| 10. download_template | 3 | | | |
| **Total** | **48** | | | |
