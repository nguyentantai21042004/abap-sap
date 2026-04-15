# Round 2 — QC Happy Case Test Notes

> **Date:** ___/04/2026
> **Tester:** ___
> **Version:** v4.2
> **SAP System:** S40 | Client: 324

---

## Screenshots

Luu vao folder: `bugs/screenshots/round-2/`

Naming convention:
- `TC-XX.YY-mo-ta-ngan.png`
- Vi du: `TC-01.01-project-list-load.png`, `TC-05.08-display-mode-fields.png`

---

## Test Results

### TC-01: Navigation Flow

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 1.01 | T-code entry → Screen 0400 | | |
| 1.02 | Project click → Screen 0200 | | |
| 1.03 | My Bugs → Screen 0200 | | |
| 1.04 | Create Bug → Screen 0300 | | |
| 1.05 | Change Bug → Screen 0300 | | |
| 1.06 | Display Bug → Screen 0300 | | |
| 1.07 | Bug Detail → Back → 0200 | | |
| 1.08 | Bug List → Back → 0400 | | |
| 1.09 | Create Project → Screen 0500 | | |
| 1.10 | Change Project → Screen 0500 | | |
| 1.11 | Project Detail → Back → 0400 | | |
| 1.12 | Exit → LEAVE PROGRAM | | |
| 1.13 | Cancel (Fn+F12) | | |

---

### TC-02: Screen 0400 — Project List

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 2.01 | ALV hien thi projects | | |
| 2.05 | Create project (Manager) | | |
| 2.07 | Change project | | |
| 2.09 | Display project | | |
| 2.10 | Delete project | | |

---

### TC-03: Screen 0500 — Project Detail

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 3.01 | Auto-generate PROJECT_ID | | |
| 3.02 | Save thanh cong | | |
| 3.05 | Change fields & Save | | |
| 3.09 | Add user thanh cong | | |
| 3.15 | Remove user | | |
| 3.17 | TC_USERS headers | | |
| 3.18 | F4 Start Date | | |
| 3.19 | F4 End Date | | |
| 3.20 | F4 Project Status | | |
| 3.21 | F4 Project Manager | | |

---

### TC-04: Screen 0200 — Bug List

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 4.01 | Project mode — all bugs | | |
| 4.02 | My Bugs — Manager | | |
| 4.06 | Create bug (Tester) | | |
| 4.09 | Delete bug | | |

---

### TC-05: Screen 0300 — Bug Detail

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 5.01 | Auto-generate BUG_ID | | |
| 5.02 | PROJECT_ID pre-fill + locked | | |
| 5.03 | Save thanh cong | | |
| 5.06 | Mode chuyen Change sau Save | | |
| 5.07 | Default values khi Create | | |
| 5.08 | Display mode — ALL fields readonly | | |
| 5.10 | Change mode — EDT fields editable | | |
| 5.12 | BUG_ID LUON readonly | | |
| 5.13 | Title bar hien dung | | |
| 5.14 | Status display text | | |
| 5.15 | Priority display text | | |
| 5.16 | Severity display text | | |
| 5.17 | Bug Type display text | | |

---

### TC-06: Tab Strip & Subscreens

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 6.01 | 6 tabs hien day du | | |
| 6.02 | Tab switch — Bug Info | | |
| 6.03 | Tab switch — Description | | |
| 6.04 | Tab switch — Dev Note | | |
| 6.05 | Tab switch — Tester Note | | |
| 6.06 | Tab switch — Evidence | | |
| 6.07 | Tab switch — History | | |
| 6.08 | Tab switch KHONG mat data | | |
| 6.09 | Tab highlight dung | | |
| 6.15 | Tab switch KHONG crash | | |

---

### TC-07: Status Transition

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 7.01 | New → Assigned (Tester) | | |
| 7.03 | Assigned → In Progress (Dev) | | |
| 7.05 | In Progress → Fixed (Dev) | | |
| 7.08 | Fixed → Resolved (Tester) | | |
| 7.10 | Resolved → Closed (Tester) | | |
| 7.15 | Popup hien valid targets | | |
| 7.19 | History record created | | |

---

### TC-08: Evidence

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 8.01 | Upload generic evidence | | |
| 8.08 | Download evidence | | |
| 8.10 | Delete evidence | | |
| 8.13 | Fixed + BUGPROOF_ file | | |
| 8.15 | Resolved + TESTCASE_ file | | |
| 8.17 | Closed + CONFIRM_ file | | |

---

### TC-10: Template Download

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 10.01 | Download Project Template | | |
| 10.02 | Download Testcase Template | | |
| 10.03 | Download Confirm Template | | |
| 10.04 | Download Bugproof Template | | |

---

### TC-14: F4 Search Help

| # | Test Case | Result | Notes / Bug |
|---|-----------|--------|-------------|
| 14.01 | F4 Status | | |
| 14.02 | F4 Priority | | |
| 14.03 | F4 Severity | | |
| 14.04 | F4 Bug Type | | |
| 14.05 | F4 Project ID | | |
| 14.06 | F4 Tester ID | | |
| 14.07 | F4 Developer ID | | |
| 14.08 | F4 Verify Tester | | |

---

## Bugs Found

### Bug R2-01: (ten bug)
- **TC ref:** TC-XX.YY
- **Steps to reproduce:** ...
- **Expected:** ...
- **Actual:** ...
- **Screenshot:** `bugs/screenshots/round-2/TC-XX.YY-xxx.png`
- **Severity:** HIGH / MEDIUM / LOW

---

### Bug R2-02: (ten bug)
- **TC ref:** TC-XX.YY
- **Steps to reproduce:** ...
- **Expected:** ...
- **Actual:** ...
- **Screenshot:** `bugs/screenshots/round-2/TC-XX.YY-xxx.png`
- **Severity:** HIGH / MEDIUM / LOW

---

### Bug R2-03: (ten bug)
- **TC ref:**
- **Steps to reproduce:** ...
- **Expected:** ...
- **Actual:** ...
- **Screenshot:**
- **Severity:**

---

*Them bug moi: copy block tren, doi so R2-XX*
