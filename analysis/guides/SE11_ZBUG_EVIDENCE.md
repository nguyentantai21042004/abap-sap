# ZBUG_EVIDENCE — SE11 Table Creation Guide

> **Prerequisite**: Create this table BEFORE pasting v4.0 code into SAP.
> **Package**: ZBUGTRACK | **Delivery Class**: A | **Data Browser/Table View Maint.**: Allowed

---

## Step 1: SE11 → Create Table

1. Transaction **SE11** → Database table → `ZBUG_EVIDENCE` → Create
2. Short Description: `Bug Evidence / Attachment Storage`
3. Delivery and Maintenance tab:
   - Delivery Class: **A** (Application table)
   - Data Browser/Table View Maint.: **Display/Maintenance Allowed**

---

## Step 2: Fields (11 fields)

| # | Field | Key | Initial | Data Element | Built-In Type | Length | Short Description |
|---|-------|-----|---------|-------------|---------------|--------|-------------------|
| 1 | MANDT | X | X | `MANDT` | | 3 | Client |
| 2 | EVD_ID | X | X | `NUMC10` | | 10 | Evidence ID (auto-increment) |
| 3 | BUG_ID | | | `ZDE_BUG_ID` | | 10 | Bug ID |
| 4 | PROJECT_ID | | | `ZDE_PROJECT_ID` | | 20 | Project ID |
| 5 | FILE_NAME | | | `SDOK_FILNM` | | 255 | File Name |
| 6 | MIME_TYPE | | | `W3CONTTYPE` | | 128 | MIME Type |
| 7 | FILE_SIZE | | | *(none)* | **INT4** | 10 | File Size in bytes |
| 8 | CONTENT | | | *(none)* | **RAWSTRING** | 0 | Binary File Content |
| 9 | ERNAM | | | `ERNAM` | | 12 | Created By |
| 10 | ERDAT | | | `ERDAT` | | 8 | Created Date |
| 11 | ERZET | | | `ERZET` | | 6 | Created Time |

### Key fields: MANDT + EVD_ID

### How to enter fields WITHOUT data elements (FILE_SIZE, CONTENT):

1. Type the field name (e.g., `FILE_SIZE`)
2. Leave the **Data Element** column **empty**
3. Click the **Built-In Type** button (looks like a small grid icon, next to "Srch Help")
4. Enter the built-in type directly:
   - FILE_SIZE → Data Type: `INT4`, Length: `10`
   - CONTENT → Data Type: `RAWSTRING`, Length: `0`
5. Enter a short description manually

> **Note on RAWSTRING**: Length must be `0` (variable length). This is the same pattern as the reference table ZTB_EVD.

---

## Step 3: Technical Settings

1. Click **Technical Settings** button (toolbar)
2. Settings:
   - Data Class: **APPL0** (master data, general)
   - Size Category: **0** (0 to 5,400 records expected)
   - Buffering: **Buffering not allowed** (required for RAWSTRING columns)
3. Save

---

## Step 4: Activate

1. Save the table
2. Click **Activate** (Ctrl+F3)
3. Should activate without errors

---

## Verification

After activation, run **SE16** → `ZBUG_EVIDENCE` → should show empty table with 11 columns.

---

## Reference

This table design is based on the reference table `ZTB_EVD` (from ZPG_BUGTRACKING_DETAIL) with simplifications:

| Our ZBUG_EVIDENCE | Reference ZTB_EVD | Notes |
|-------------------|-------------------|-------|
| EVD_ID (NUMC 10, key) | DOCNO (DOKNR, CHAR 25, key) | Simpler auto-increment ID |
| BUG_ID | BUG_ID | Same concept |
| PROJECT_ID | PROJECT_ID | Same concept |
| FILE_NAME (SDOK_FILNM) | FILE_NAME (SDOK_FILNM) | Same |
| MIME_TYPE (W3CONTTYPE) | MIMET (W3CONTTYPE) | Same DE, different field name |
| FILE_SIZE (INT4) | *(not present)* | Added for ALV display |
| CONTENT (RAWSTRING) | CONTENT (RAWSTRING) | Same |
| ERNAM/ERDAT/ERZET | CNAM/CDAT/CTME | Same concept, different DEs |
| *(not needed)* | DKTXT, DAPPL, FILE_PATH, AICON | Omitted for simplicity |
