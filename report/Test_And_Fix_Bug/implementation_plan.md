# Test And Fix Bug — Implementation Plan
## Project: Z_BUG_WORKSPACE_MP (Bug Tracking System)

**SAP System:** S40 | **Client:** 324 | **T-Code:** `ZBUG_WS`
**Version:** v5.0 | **Test Phase:** SIT / UAT Round 1 | **Date:** 17/04/2026
**Reported by:** DEV-089 (Manager) | **Analyzed by:** DEV-089, DEV-061, DEV-118

---

## 1. Document Information

| Field | Value |
|-------|-------|
| Project Name | Z_BUG_WORKSPACE_MP — Bug Tracking System |
| Test Phase | SIT + UAT Round 1 |
| Total Bugs Logged | 11 |
| Version | 1.0 |
| Date | 17/04/2026 |
| Source | UAT Round 1 testing on S40 Client 324 |

---

## 2. Change History

| No. | Version | Description | Sheet | Modified Date | Modified by |
|-----|---------|-------------|-------|--------------|-------------|
| 1 | 1.0 | Initial bug log from UAT Round 1 (11 bugs) | All | 13/04/2026 | DEV-089 |
| 2 | 1.1 | Root cause analysis + fix proposals for all 11 bugs | All | 13/04/2026 | DEV-089 |
| 3 | 1.2 | Linked to v5.0 CODE changes (F10 COMPLETE) | All | 16/04/2026 | DEV-089 |

---

## 3. Bug Severity Classification

| Severity | Description | SLA |
|----------|-------------|-----|
| CRITICAL | Short dump / system crash — blocks all testing | Fix before re-test |
| High | Functional defect — incorrect behavior, data loss risk | Fix before UAT Round 2 |
| Medium | UX/design issue — workaround exists | Fix before go-live |
| Low | Minor cosmetic issue | Post go-live |

---

## 4. Bug Tracker — Fix and Bugs Sheet

### Phase: UAT Round 1 (13/04/2026)

| No. | Bug Title | Details (Reproduction Steps) | Expected Result | Actual Result | Root Cause | Fix Applied | Evidence | Severity | Status |
|-----|-----------|------------------------------|-----------------|---------------|-----------|------------|----------|----------|--------|
| 1 | Short dump on tab Description/Dev Note/Tester Note (Change Bug) | 1. Open existing bug BUG0000023 in Change mode (Screen 0300) 2. Click tab Description or Dev Note or Tester Note 3. → ABAP short dump immediately | Tab opens, text editor displays with existing content | CALL_FUNCTION_CONFLICT_TYPE short dump. Program terminates. | (a) Custom Controls CC_DESC / CC_DEVNOTE / CC_TSTRNOTE not created on screens 0320/0330/0340 in SE51; or (b) STRING field placed on screen layout causing deep type crash | CODE_PBO: Add TRY-CATCH around `CREATE OBJECT go_cont_desc`. CODE_F02: Explicit type cast `lv_tdname TYPE tdobname` before READ_TEXT call. SE51: Verify CC_DESC on 0320, CC_DEVNOTE on 0330, CC_TSTRNOTE on 0340. Remove any STRING field from screen 0310 layout. | `runtime-error-read-text-type-conflict-115802.png` | CRITICAL | Fixed in v5.0 design |
| 2 | Description text area too small — no dedicated full-screen view | User creates or views a bug. Description field appears in the Bug Info area only, no large editing space visible. | Dedicated full Description tab with large text editor (CC_DESC) | Description full editor (Screen 0320) not visible because tab crashes (Bug 1). Mini editor on Bug Info is small. | Root cause = Bug 1 tab crash | Fix Bug 1 → full editor on tab Description (subscreen 0320 with CC_DESC) becomes accessible. No design change needed. | — | Medium | Resolved by Bug 1 fix |
| 3 | Description field character limit | User types long description (>132 chars) in Description input area — text is cut off | Unlimited text (TYPE STRING) | Limited to ~132 visible characters | STRING field `GS_BUG_DETAIL-DESC_TEXT` placed directly on screen layout → screen field limits visible length | Remove `GS_BUG_DETAIL-DESC_TEXT` from screen 0310 layout. Description stored only through `cl_gui_textedit` (Custom Control CC_DESC_MINI). | — | Medium | Fixed in v5.0 design |
| 4 | SAP Module, Severity, Created Date fields display empty | Open Display Bug for BUG0000023 (Screen 0310). SAP Module, Severity, Created Date all show blank. | Fields display correct values from ZBUG_TRACKER | Fields appear empty | (a) Screen 0310 fields not mapped to correct global variables `GS_BUG_DETAIL-SAP_MODULE`, `GS_BUG_DETAIL-SEVERITY`, `GS_BUG_DETAIL-CREATED_AT`; or (b) Fields not added to screen layout in SE51 | Verify SE51 Screen 0310 field references. Add missing fields to layout. Check SE16 data for BUG0000023. | `display-bug-bug0023-empty-metadata.png` | High | Fix in SE51 screen 0310 |
| 5 | Remove User deletes row without selection | In Project Detail Screen 0500, press "Remove User" without clicking any row. User is deleted anyway. | Message: "Please select a user row to remove." No deletion occurs. | Row is silently removed (default current_line used) | `tc_users-current_line` always has a value when TC has data. `IF lv_line = 0` check insufficient. | Replace with `GET CURSOR LINE lv_line` and validate `lv_line > 0 AND lv_line <= lines(gt_user_project)` | `change-project-remove-user-confirm.png`, `change-project-assign-user-popup.png` | Medium | Fixed in v5.0 CODE_F01 |
| 6a | Create Bug: Status field allows non-New value | On Screen 0310 Create mode, open STATUS F4 help → select status '3' (In Progress) → save. Bug saved with status 3. | Status must always be '1' (New) when creating a bug | Status accepts any value from F4 | `IF gs_bug_detail-status IS INITIAL` guard bypassed when user explicitly selects via F4 | Force `gs_bug_detail-status = gc_st_new` unconditionally in save_bug. Lock STATUS field (screen group STS) in Create mode PBO. | `create-bug-bug-info-status-3-no-upload.png` | High | Fixed in v5.0 CODE_F01 + CODE_PBO |
| 6b | Create Bug: SAP Module has no F4 search help | On Screen 0310, click SAP Module field → no F4 help popup | F4 popup shows list: FI, MM, SD, ABAP, BASIS, PP, HR, QM | No search help appears; field is free-text only | Missing `f4_sap_module` FORM and POV module for SAP_MODULE field | Add `FORM f4_sap_module` in CODE_F02 using `F4IF_INT_TABLE_VALUE_REQUEST`. Add POV module `f4_bug_sapmodule` in CODE_PAI. Add PROCESS ON VALUE-REQUEST in Screen 0310 flow logic. | — | High | Fixed in v5.0 CODE_F02 + CODE_PAI |
| 6c | Create Bug: Cannot upload evidence before bug is saved | On Screen 0310 Create mode, button UP_FILE (Upload Evidence) is hidden/disabled | UP_FILE available in Create mode — auto-saves bug first, then uploads | UP_FILE button not visible in Create mode | UP_FILE excluded from Create mode exclusion list in PBO | Remove UP_FILE from Create mode exclusion list. In `upload_evidence`, auto-call `save_bug` when `gv_current_bug_id IS INITIAL AND gv_mode = gc_mode_create`. | — | High | Fixed in v5.0 CODE_PBO + CODE_F01 |
| 6d | Create Bug: Created Date field shows empty before save | On Screen 0310 Create mode, CREATED_AT field shows blank | Created Date auto-populated with today's date immediately | Field blank until save is triggered | `CREATED_AT` only set inside save_bug (post-save). PBO Create mode does not pre-fill. | PBO Create mode: add `gs_bug_detail-created_at = sy-datum` and `gs_bug_detail-created_time = sy-uzeit`. Mark CREATED_AT as locked (screen group BID or new group CRD). | — | Medium | Fixed in v5.0 CODE_PBO |
| 7 | All screen fields lock after validation error | On Screen 0310, enter invalid data → press Save → validation error triggers → ALL fields on screen become locked/uneditable | Error message shown in status bar, fields remain editable for correction | All screen fields locked, user cannot correct input | `MESSAGE ... TYPE 'E'` in Module Pool locks screen fields for all non-grouped elements | Replace all `MESSAGE TYPE 'E'` in save_bug_detail and save_project_detail with `MESSAGE TYPE 'S' DISPLAY LIKE 'E'` followed by `RETURN` | `create-bug-validation-error-footer.png` | High | Fixed in v5.0 CODE_F01 |
| 8 | Description text disappears in Display/Change mode | Open existing bug in Display mode (Screen 0300) → Bug Info tab → mini Description area is empty | Mini editor shows the bug's description text | Mini editor blank even when description was saved | Description saved to Long Text Object (SAVE_TEXT) but not synced back to `gs_bug_detail-desc_text` DB field. Load re-reads DB field → gets old/empty value. | After save_long_text, sync back: read go_edit_desc text → concatenate lines → assign to `gs_bug_detail-desc_text` → update DB | — | High | Fixed in v5.0 CODE_F01 |
| 9 | Short dump CALL_FUNCTION_CONFLICT_TYPE in Change Bug | Same as Bug 1 but confirmed on Change Bug path. Screen 0300 → Change → tab click → short dump | Same as Bug 1 | CALL_FUNCTION_CONFLICT_TYPE short dump | Same root cause as Bug 1 (Custom Control missing or STRING on layout) | Same fix as Bug 1 | `runtime-error-read-text-type-conflict-123322.png` | CRITICAL | Fixed in v5.0 design (same as Bug 1) |
| 10 | Manager can set status backward (3 → 1) without warning | Bug BUG0000024 status = '3' (In Progress). Manager opens Change → changes status to '1' (New) → saves. No warning. | Transition 3→1 should be blocked. Status must follow allowed transition matrix. | Status saved as '1' (New). System allows illegal backward transition. | Manager role case in `change_bug_status` appends ALL statuses to `lt_allowed` — no backward transition check | v5.0 redesign: Remove Manager bypass. Manager must follow transition matrix. Popup Screen 0370 only shows allowed next states. | `change-bug-bug0024-status-in-progress.png`, `change-bug-bug0024-status-1-new-saved.png` | CRITICAL | Fixed in v5.0 CODE_F01 (validate_transition) |
| 11 | Status transition to Fixed (5) allowed without evidence | Bug BUG0000024 → Change Status → select Fixed (5) → confirm → saved without uploading any evidence file | Transition to Fixed (5) requires at least 1 evidence file in ZBUG_EVIDENCE | Status saved as Fixed with no evidence | `check_evidence_for_status` logic bypassed by Manager role (`IF sy-subrc <> 0 AND gv_role <> 'M'`) | Remove Manager bypass in check_evidence_for_status. Popup Screen 0370 enforces evidence upload for Fixed (5). ZBUG_EVIDENCE COUNT check applies to all roles. | `change-bug-bug0024-status-5-fixed-saved.png` | High | Fixed in v5.0 CODE_F01 |

---

## 5. Bug Statistics

| Severity | Count | Fixed in v5.0 | Pending |
|----------|-------|--------------|---------|
| CRITICAL | 2 (Bug 1, 9+10) | 3 | 0 |
| High | 7 | 7 | 0 |
| Medium | 4 | 4 | 0 |
| **Total** | **11** | **11** | **0** |

> All 11 bugs have been analyzed with root causes and fix proposals incorporated into CODE v5.0 (F10 COMPLETE as of 16/04/2026).

---

## 6. Files Changed (v5.0 Bug Fixes)

| File / SAP Include | Bugs Fixed | Change Description |
|--------------------|-----------|-------------------|
| `CODE_TOP` / `Z_BUG_WS_TOP` | 10, 11 | Add `gc_st_finaltesting = '6'`, `gc_st_resolved = 'V'`, screen group `STS` |
| `CODE_PBO` / `Z_BUG_WS_PBO` | 1, 6a, 6c, 6d, 9 | TRY-CATCH for container creation; lock STATUS (group STS); UP_FILE in Create mode; pre-fill CREATED_AT |
| `CODE_PAI` / `Z_BUG_WS_PAI` | 6b | Add POV module `f4_bug_sapmodule` |
| `CODE_F01` / `Z_BUG_WS_F01` | 5, 7, 8, 10, 11 | Fix `remove_user_from_project` cursor check; replace MESSAGE TYPE 'E' with TYPE 'S' DISPLAY LIKE 'E'; sync desc_text after save_long_text; enforce transition matrix for Manager; remove Manager bypass in evidence check |
| `CODE_F02` / `Z_BUG_WS_F02` | 1, 6b, 9 | Explicit type cast `lv_tdname TYPE tdobname` before READ_TEXT; add `f4_sap_module` FORM |

---

## 7. Screens to Verify in SE51

| Screen | Action | Bugs |
|--------|--------|------|
| 0310 | Remove STRING fields from layout; add SAP_MODULE, SEVERITY, CREATED_AT fields; add STATUS to group STS; add POV for SAP_MODULE | 3, 4, 6a, 6b, 6d |
| 0320 | Verify Custom Control `CC_DESC` exists | 1, 2, 9 |
| 0330 | Verify Custom Control `CC_DEVNOTE` exists (no underscore) | 1, 9 |
| 0340 | Verify Custom Control `CC_TSTRNOTE` exists (no underscore) | 1, 9 |

---

## 8. Issue Overflow — Category Breakdown

### Issue Category A: Screen Layout / SE51 Issues
Bugs 1, 2, 3, 4, 9 — all require SE51 screen layout verification and correction.

### Issue Category B: Business Logic (ABAP Code)
Bugs 5, 7, 8, 10, 11 — fixed in CODE_F01 v5.0.

### Issue Category C: Missing Features (Field / F4 Help)
Bugs 6a, 6b, 6c, 6d — missing validations and helpers added in CODE_PAI + CODE_F02 v5.0.

---

## 9. UAT Round 2 — Regression Plan

After deploying v5.0:

| Re-test Item | Bug Ref | Test Account |
|-------------|---------|-------------|
| Open Change Bug → tab Description/Dev Note/Tester Note | 1, 9 | DEV-089 |
| Description full editor shows content | 2, 3, 8 | DEV-089 |
| SAP Module, Severity, Created Date visible on Bug Info | 4 | DEV-089 |
| Remove User requires row selection | 5 | DEV-089 |
| Create Bug → status forced to New | 6a | DEV-089 |
| Create Bug → SAP Module F4 shows list | 6b | DEV-089 |
| Create Bug → UP_FILE button visible + auto-saves bug | 6c | DEV-089 |
| Create Bug → Created Date pre-filled | 6d | DEV-089 |
| Validation error → fields remain editable | 7 | DEV-089 |
| Manager cannot set status backward | 10 | DEV-089 |
| Fixed requires evidence upload | 11 | DEV-089 |
