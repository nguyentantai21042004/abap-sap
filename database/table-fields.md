# SAP Table Fields — Source of Truth (from SE11 screenshots)

> Extracted from actual SAP SE11 screenshots. Do NOT use guides as truth — use this file.
> System: S40 | Client: 324 | Date: 09/04/2026

---

## ZBUG_USERS (user_table.png) — 12 fields

| # | Field | Key | Data Element | Data Type | Length | Description |
|---|-------|-----|-------------|-----------|--------|-------------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 | Client |
| 2 | USER_ID | ✅ | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 3 | ROLE | | ZDE_BUG_ROLE | CHAR | 1 | SAP Role |
| 4 | FULL_NAME | | ZDE_BUG_FULL_NAME | CHAR | 50 | Full Name |
| 5 | SAP_MODULE | | ZDE_SAP_MODULE | CHAR | 20 | SAP Module |
| 6 | AVAILABLE_STATUS | | ZDE_AVAIL_STATUS | CHAR | 1 | Available Status |
| 7 | IS_ACTIVE | | CHAR1 | CHAR | 1 | Single-Character Flag |
| 8 | EMAIL | | ZDE_BUG_EMAIL | CHAR | 100 | Email Address |
| 9 | AENAM | | AENAM | CHAR | 12 | Name of Person Who Changed Object |
| 10 | AEDAT | | AEDAT | DATS | 8 | Last Changed On |
| 11 | AEZET | | AEZET | TIMS | 6 | Time last change was made |
| 12 | IS_DEL | | ZDE_IS_DEL | CHAR | 1 | ZDE_IS_DEL |

**Notes:**

- NO field named `USER_NAME` — use `USER_ID` (CHAR 12)
- Key fields: MANDT + USER_ID

---

## ZBUG_HISTORY (hisotry_table.png) — 10 fields

| # | Field | Key | Data Element | Data Type | Length | Description |
|---|-------|-----|-------------|-----------|--------|-------------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 | Client |
| 2 | LOG_ID | ✅ | NUMC10 | NUMC | 10 | Numeric Character Field, Length 10 |
| 3 | BUG_ID | | ZDE_BUG_ID | CHAR | 10 | ZDE_BUG_ID |
| 4 | CHANGED_BY | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 5 | CHANGED_AT | | ZDE_BUG_CR_DATE | DATS | 8 | Created Date |
| 6 | CHANGED_TIME | | ZDE_BUG_CR_TIME | TIMS | 6 | Created Time |
| 7 | ACTION_TYPE | | ZDE_BUG_ACT_TYPE | CHAR | 2 | Action Type |
| 8 | OLD_VALUE | | ZDE_BUG_TITLE | CHAR | 100 | Bug Title |
| 9 | NEW_VALUE | | ZDE_BUG_TITLE | CHAR | 100 | Bug Title |
| 10 | REASON | | ZDE_REASONS | STRING | 0 | Root Causes |

**Notes:**

- Key fields: MANDT + LOG_ID
- REASON is STRING (no fixed length)

---

## ZBUG_USER_PROJEC (use_projec_table.png) — 10 fields

| # | Field | Key | Data Element | Data Type | Length | Description |
|---|-------|-----|-------------|-----------|--------|-------------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 | Client |
| 2 | USER_ID | ✅ | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 3 | PROJECT_ID | ✅ | ZDE_PROJECT_ID | CHAR | 20 | ZDE_PROJECT_ID |
| 4 | ERNAM | | ERNAM | CHAR | 12 | Name of Person Responsible for Creating the Object |
| 5 | ERDAT | | ERDAT | DATS | 8 | Record Created On |
| 6 | ERZET | | ERZET | TIMS | 6 | Entry time |
| 7 | AENAM | | AENAM | CHAR | 12 | Name of Person Who Changed Object |
| 8 | AEDAT | | AEDAT | DATS | 8 | Last Changed On |
| 9 | AEZET | | AEZET | TIMS | 6 | Time last change was made |
| 10 | ROLE | | ZDE_BUG_ROLE | CHAR | 1 | SAP Role |

**Notes:**

- Key fields: MANDT + USER_ID + PROJECT_ID
- Table name in SAP is `ZBUG_USER_PROJEC` (truncated, not `ZBUG_USER_PROJECT`)
- ROLE field exists here (confirmed added to phase-a-database.md)

---

## ZBUG_PROJECT (project_table_1.png + project_table_2.png) — 16 fields

| # | Field | Key | Data Element | Data Type | Length | Description |
|---|-------|-----|-------------|-----------|--------|-------------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 | Client |
| 2 | PROJECT_ID | ✅ | ZDE_PROJECT_ID | CHAR | 20 | ZDE_PROJECT_ID |
| 3 | PROJECT_NAME | | ZDE_PRJ_NAME | CHAR | 100 | ZDE_PRJ_NAME |
| 4 | DESCRIPTION | | ZDE_PRJ_DESC | CHAR | 255 | ZDE_PRJ_DESC |
| 5 | START_DATE | | SYDATUM | DATS | 8 | System Date |
| 6 | END_DATE | | SYDATUM | DATS | 8 | System Date |
| 7 | PROJECT_MANAGER | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 8 | PROJECT_STATUS | | ZDE_PRJ_STATUS | CHAR | 1 | ZDE_PRJ_STATUS |
| 9 | NOTE | | CHAR255 | CHAR | 255 | Char255 |
| 10 | ERNAM | | ERNAM | CHAR | 12 | Name of Person Responsible for Creating the Object |
| 11 | ERDAT | | ERDAT | DATS | 8 | Record Created On |
| 12 | ERZET | | ERZET | TIMS | 6 | Entry time |
| 13 | AENAM | | AENAM | CHAR | 12 | Name of Person Who Changed Object |
| 14 | AEDAT | | AEDAT | DATS | 8 | Last Changed On |
| 15 | AEZET | | AEZET | TIMS | 6 | Time last change was made |
| 16 | IS_DEL | | ZDE_IS_DEL | CHAR | 1 | ZDE_IS_DEL |

**Notes:**

- Key fields: MANDT + PROJECT_ID
- PROJECT_STATUS has Initi... checked (has initial value)
- NOTE uses CHAR255 data element (not a STRING)

---

## ZBUG_TRACKER (tracker_1.png + tracker_2.png + tracker_3.png) — 29 fields

| # | Field | Key | Data Element | Data Type | Length | Description |
|---|-------|-----|-------------|-----------|--------|-------------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 | Client |
| 2 | BUG_ID | ✅ | ZDE_BUG_ID | CHAR | 10 | ZDE_BUG_ID |
| 3 | TITLE | | ZDE_BUG_TITLE | CHAR | 100 | Bug Title |
| 4 | DESC_TEXT | | ZDE_BUG_DESC | STRING | 0 | Description |
| 5 | SAP_MODULE | | ZDE_SAP_MODULE | CHAR | 20 | SAP Module |
| 6 | PRIORITY | | ZDE_PRIORITY | CHAR | 1 | Priority Level |
| 7 | STATUS | | ZDE_BUG_STATUS | CHAR | 20 | Bug Status |
| 8 | BUG_TYPE | | ZDE_BUG_TYPE | CHAR | 1 | Bug Type |
| 9 | REASONS | | ZDE_REASONS | STRING | 0 | Root Causes |
| 10 | TESTER_ID | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 11 | VERIFY_TESTER_ID | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 12 | DEV_ID | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 13 | APPROVED_BY | | ZDE_USERNAME | CHAR | 12 | SAP Username |
| 14 | APPROVED_AT | | ZDE_BUG_APP_DATE | DATS | 8 | Approved Date |
| 15 | CREATED_AT | | ZDE_BUG_CR_DATE | DATS | 8 | Created Date |
| 16 | CREATED_TIME | | ZDE_BUG_CR_TIME | TIMS | 6 | Created Time |
| 17 | CLOSED_AT | | ZDE_BUG_CL_DATE | DATS | 8 | Closed Date |
| 18 | ATT_REPORT | | ZDE_BUG_ATT_PATH | CHAR | 100 | Attachment Path |
| 19 | ATT_FIX | | ZDE_BUG_ATT_PATH | CHAR | 100 | Attachment Path |
| 20 | ATT_VERIFY | | ZDE_BUG_ATT_PATH | CHAR | 100 | Attachment Path |
| 21 | PROJECT_ID | | ZDE_PROJECT_ID | CHAR | 20 | ZDE_PROJECT_ID |
| 22 | SEVERITY | | ZDE_SEVERITY | CHAR | 1 | ZDE_SEVERITY |
| 23 | ERNAM | | ERNAM | CHAR | 12 | Name of Person Responsible for Creating the Object |
| 24 | ERDAT | | ERDAT | DATS | 8 | Record Created On |
| 25 | ERZET | | ERZET | TIMS | 6 | Entry time |
| 26 | AENAM | | AENAM | CHAR | 12 | Name of Person Who Changed Object |
| 27 | AEDAT | | AEDAT | DATS | 8 | Last Changed On |
| 28 | AEZET | | AEZET | TIMS | 6 | Time last change was made |
| 29 | IS_DEL | | ZDE_IS_DEL | CHAR | 1 | ZDE_IS_DEL |

**Notes:**

- Key fields: MANDT + BUG_ID
- STATUS is CHAR 20 (NOT CHAR 1 — important!)
- DESC_TEXT and REASONS are STRING type (no fixed length)
- 3 attachment fields: ATT_REPORT, ATT_FIX, ATT_VERIFY (all CHAR 100)
- SEVERITY field exists (ZDE_SEVERITY CHAR 1)
- CLOSED_AT uses data element ZDE_BUG_CL_DATE
- APPROVED_AT uses data element ZDE_BUG_APP_DATE

---

## Summary — All Tables

| Table | Fields | Key Fields | Source File |
|-------|--------|-----------|-------------|
| ZBUG_USERS | 12 | MANDT + USER_ID | user_table.png |
| ZBUG_HISTORY | 10 | MANDT + LOG_ID | hisotry_table.png |
| ZBUG_USER_PROJEC | 10 | MANDT + USER_ID + PROJECT_ID | use_projec_table.png |
| ZBUG_PROJECT | 16 | MANDT + PROJECT_ID | project_table_1.png + project_table_2.png |
| ZBUG_TRACKER | 29 | MANDT + BUG_ID | tracker_1.png + tracker_2.png + tracker_3.png |

**Total: 77 fields across 5 tables**

---

## Critical Findings (for CODE guides)

| Finding | Impact |
|---------|--------|
| `ZBUG_USERS` has no `USER_NAME` field — only `USER_ID` | Fix any SQL referencing `user_name` |
| `ZBUG_TRACKER.STATUS` is CHAR **20**, not CHAR 1 | Do NOT compare with single-char values |
| `ZBUG_TRACKER.DESC_TEXT` is STRING | Cannot use in CHAR comparisons |
| `ZBUG_TRACKER.REASONS` is STRING | Cannot use in CHAR comparisons |
| `ZBUG_HISTORY.REASON` is STRING | Cannot use in CHAR comparisons |
| `ZBUG_USER_PROJEC` table name is truncated (no T at end) | Use correct table name in FROM clause |
