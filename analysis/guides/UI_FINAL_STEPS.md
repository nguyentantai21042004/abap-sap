# UI Guide: Final Steps — GUI Status, Title Bars, SE93, Activation, Testing

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v4.0
> **File này hướng dẫn tất cả bước còn lại sau khi đã tạo screens**
>
> v4.0 changes:
> - STATUS_0200: +DN_TC, +DN_CONF, +DN_PROOF (template downloads)
> - STATUS_0300: +SENDMAIL, +DL_EVD (email + evidence download)
> - New: ZBUG_EVIDENCE table (SE11) — Step 0
> - New: 3 SMW0 templates (ZTEMPLATE_TESTCASE/CONFIRM/BUGPROOF)
> - Updated: Code line counts, testing checklist

---

## MỤC LỤC

0. [Step 0: Tạo bảng ZBUG_EVIDENCE (SE11)](#step-0-tạo-bảng-zbug_evidence-se11) — **v4.0 NEW**
1. [Step 1: Copy Code v4.0 vào SAP](#step-1-copy-code-v40-vào-sap)
2. [Step 2: Tạo GUI Statuses (SE41)](#step-2-tạo-gui-statuses-se41)
3. [Step 3: Tạo Title Bars (SE41)](#step-3-tạo-title-bars-se41)
4. [Step 4: Tạo Screens (SE51)](#step-4-tạo-screens-se51)
5. [Step 5: Đổi T-code Initial Screen (SE93)](#step-5-đổi-t-code-initial-screen-se93)
6. [Step 6: Activation Order](#step-6-activation-order)
7. [Step 7: Screen 0100 (Deprecated)](#step-7-screen-0100-deprecated)
8. [Step 8: Testing Checklist](#step-8-testing-checklist)
9. [Phase D: SMW0 Template Upload](#step-9-phase-d-smw0-template-upload)
10. [Phase D: Orphan Bug Cleanup](#step-10-phase-d-orphan-bug-cleanup)

---

## Step 0: Tạo bảng ZBUG_EVIDENCE (SE11) — v4.0 NEW

> **Bắt buộc trước khi paste code v4.0** — Code references bảng `ZBUG_EVIDENCE` cho evidence upload/download.
> Chi tiết đầy đủ xem `SE11_ZBUG_EVIDENCE.md`.

### Quick Reference — Table Fields:

| # | Field | Key | Data Element / Built-in | Data Type | Length |
|---|-------|-----|------------------------|-----------|--------|
| 1 | MANDT | ✅ | MANDT | CLNT | 3 |
| 2 | EVD_ID | ✅ | NUMC10 (built-in) | NUMC | 10 |
| 3 | BUG_ID | | ZDE_BUG_ID | CHAR | 10 |
| 4 | PROJECT_ID | | ZDE_PROJECT_ID | CHAR | 20 |
| 5 | FILE_NAME | | SDOK_FILNM | CHAR | 255 |
| 6 | MIME_TYPE | | W3CONTTYPE | CHAR | 128 |
| 7 | FILE_SIZE | | INT4 (built-in) | INT4 | 10 |
| 8 | CONTENT | | RAWSTRING (built-in) | RAWSTRING | 0 |
| 9 | ERNAM | | ERNAM | CHAR | 12 |
| 10 | ERDAT | | ERDAT | DATS | 8 |
| 11 | ERZET | | ERZET | TIMS | 6 |

### Cách tạo:

1. **SE11** → Database Table → `ZBUG_EVIDENCE` → Create
2. Short Description: `Bug Evidence / Attachments`
3. Delivery Class: **A** (Application table)
4. Thêm fields theo bảng trên → **MANDT + EVD_ID** là key
5. Tab **Technical Settings**: Data Class = `APPL0`, Size Category = `2`
6. **Save** → assign to package `ZBUGTRACK`
7. **Activate** (Ctrl+F3)

> **LƯU Ý:** CONTENT field dùng **RAWSTRING** (built-in type, KHÔNG dùng data element) — dùng để lưu binary file content trực tiếp trong DB.

---

## Step 1: Copy Code v4.0 vào SAP

### Thứ tự INCLUDE bắt buộc trong Main Program:

```abap
PROGRAM z_bug_workspace_mp.
INCLUDE z_bug_ws_top.    " 1. Global data
INCLUDE z_bug_ws_f00.    " 2. Event class (PHẢI trước PBO/PAI)
INCLUDE z_bug_ws_pbo.    " 3. PBO
INCLUDE z_bug_ws_pai.    " 4. PAI
INCLUDE z_bug_ws_f01.    " 5. Business logic
INCLUDE z_bug_ws_f02.    " 6. Helpers
```

### Quy trình copy:

| Step | Include | Copy từ file | Lines (v4.0) |
|------|---------|-------------|-------|
| 1 | `Z_BUG_WS_TOP` | `CODE_TOP.md` | ~180 |
| 2 | `Z_BUG_WS_F00` | `CODE_F00.md` | ~210 |
| 3 | `Z_BUG_WS_PBO` | `CODE_PBO.md` | ~530 |
| 4 | `Z_BUG_WS_PAI` | `CODE_PAI.md` | ~290 |
| 5 | `Z_BUG_WS_F01` | `CODE_F01.md` | ~1150 |
| 6 | `Z_BUG_WS_F02` | `CODE_F02.md` | ~490 |

### Cách copy từng include:

1. Mở file `.md` → copy **toàn bộ ABAP code** (bỏ markdown header/comment nếu có)
2. **SE80** → double-click include → **Change** mode
3. **Ctrl+A** (select all) → **Delete** → **Paste** code mới
4. **Save** (Ctrl+S)
5. Lặp lại cho 5 includes còn lại

### Activate Includes:

1. Sau khi paste xong **TẤT CẢ 6**, mới activate
2. **Ctrl+Shift+F3** (Activate All) → chọn tất cả objects → Activate
3. Nếu có warning (unused variables) → OK, bỏ qua
4. Nếu có **error** → xem Troubleshooting cuối file

> **Tại sao activate cùng lúc?** Vì includes reference lẫn nhau (F00 define class, PBO/PAI reference class). Activate từng cái sẽ báo lỗi "unknown type".

---

## Step 2: Tạo GUI Statuses (SE41)

### Cách vào SE41:

1. Gõ **SE41** → Enter
2. Program: `Z_BUG_WORKSPACE_MP`
3. Status: nhập tên → **Create** (F5)
4. Status Type: chọn **Dialog status** (cho screens thông thường)
5. Short Description → Enter → vẽ nút

### Standard Toolbar (cho MỌI status):

Tất cả 5 statuses cần 3 function keys standard. Vào tab **Function Keys**:

| Function Code | Assign to Key | Type |
|---------------|--------------|------|
| `BACK` | **Standard toolbar → Back button** (hình mũi tên ←) | Standard |
| `EXIT` | **Shift+F3** | Standard |
| `CANC` | **F12** (= Ctrl+F12 trên SAP) | Standard |

> **Cách assign BACK:** Trong Function Keys tab, tìm dòng có icon mũi tên quay lại (↩) → điền `BACK`.
> **Cách assign EXIT:** Tìm dòng Shift+F3 → điền `EXIT`.
> **Cách assign CANC:** Tìm dòng F12 (hoặc Shift+F12) → điền `CANC`.

---

### STATUS_0100 — Hub (DEPRECATED)

**Short Description:** `Bug Tracking Hub (Deprecated)`

**Application Toolbar buttons:**

| # | FCode | Text | Icon | FctType |
|---|-------|------|------|---------|
| 1 | `BUG_LIST` | Bug List | — | Normal |
| 2 | `PROJ_LIST` | Project List | — | Normal |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

Save + Activate.

---

### STATUS_0200 — Bug List

**Short Description:** `Bug List`

**Application Toolbar buttons (left to right):**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `CREATE` | Create Bug | `ICON_CREATE` | Excluded: Dev + My Bugs mode |
| 2 | `CHANGE` | Change | `ICON_CHANGE` | |
| 3 | `DISPLAY` | Display | `ICON_DISPLAY` | |
| 4 | `DELETE` | Delete | `ICON_DELETE` | Excluded: Dev + Tester + My Bugs mode |
| 5 | *(separator)* | | | Click ô trống giữa 2 nút, để trống FCode |
| 6 | `REFRESH` | Refresh | `ICON_REFRESH` | |
| 7 | *(separator)* | | | |
| 8 | `DN_TC` | Download TestCase | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_TESTCASE |
| 9 | `DN_CONF` | Download Confirm | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_CONFIRM |
| 10 | `DN_PROOF` | Download BugProof | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_BUGPROOF |

**Cách thêm icon:** Khi tạo button, column "Icon Name" → nhập tên icon (vd `ICON_CREATE`). Hoặc click icon picker.

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

Save + Activate.

---

### STATUS_0300 — Bug Detail

**Short Description:** `Bug Detail`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Excluded: Display mode |
| 2 | `STATUS_CHG` | Change Status | `ICON_CHANGE` | Excluded: Create mode |
| 3 | *(separator)* | | | |
| 4 | `UP_FILE` | Upload Evidence | `ICON_IMPORT` | Excluded: Create mode |
| 5 | `UP_REP` | Upload Report | `ICON_IMPORT` | Excluded: Dev role + Create mode |
| 6 | `UP_FIX` | Upload Fix | `ICON_IMPORT` | Excluded: Tester role + Create mode |
| 7 | *(separator)* | | | |
| 8 | `DL_EVD` | Download Evidence | `ICON_EXPORT` | **v4.0** — Download selected evidence file |
| 9 | `SENDMAIL` | Send Email | `ICON_MAIL` | **v4.0** — Send bug info via BCS API |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

> **CRITICAL:** Fcode `SAVE` **BẮT BUỘC** phải có trong status. Thiếu = nút Save không hiện kể cả ở Change mode.
> **v4.0:** `DL_EVD` downloads selected evidence row (binary → GUI_DOWNLOAD). `SENDMAIL` triggers `cl_bcs` email with bug summary.

Save + Activate.

---

### STATUS_0400 — Project List (INITIAL SCREEN)

**Short Description:** `Project List`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `MY_BUGS` | My Bugs | `ICON_BIW_REPORT` | **MỚI** — All roles, cross-project |
| 2 | *(separator)* | | | |
| 3 | `CREA_PRJ` | Create Project | `ICON_CREATE` | Excluded: non-Manager |
| 4 | `CHNG_PRJ` | Change | `ICON_CHANGE` | Excluded: non-Manager |
| 5 | `DISP_PRJ` | Display | `ICON_DISPLAY` | All roles |
| 6 | `DEL_PRJ` | Delete | `ICON_DELETE` | Excluded: non-Manager |
| 7 | *(separator)* | | | |
| 8 | `UPLOAD` | Upload Excel | `ICON_IMPORT` | Excluded: non-Manager |
| 9 | `DN_TMPL` | Download Template | `ICON_EXPORT` | Excluded: non-Manager |
| 10 | `REFRESH` | Refresh | `ICON_REFRESH` | All roles |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

Save + Activate.

---

### STATUS_0500 — Project Detail

**Short Description:** `Project Detail`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Excluded: Display + non-Manager |
| 2 | *(separator)* | | | |
| 3 | `ADD_USER` | Add User | `ICON_INSERT_ROW` | Excluded: Display + non-Manager |
| 4 | `REMO_USR` | Remove User | `ICON_DELETE_ROW` | Excluded: Display + non-Manager |

> **LƯU Ý:** Fcode `REMO_USR` (không phải `REMOVE_USER`) — SAP giới hạn 8 ký tự cho fcode.

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

Save + Activate.

---

## Step 3: Tạo Title Bars (SE41)

### Cách tạo:

1. **SE41** → Program: `Z_BUG_WORKSPACE_MP`
2. Đổi **Object Type** dropdown (ở đầu screen) từ "Status" sang **"Title"**
3. Nhập tên title → **Create**
4. Nhập text (có `&1` placeholder) → **Save** + **Activate**

### 5 Title Bars cần tạo:

| Title Name | Text | Mô tả |
|------------|------|-------|
| `TITLE_MAIN` | `&1` | Screen 0100 — nhận "Bug Tracking Hub" |
| `TITLE_BUGLIST` | `&1` | Screen 0200 — nhận "Bugs — {project}" hoặc "My Bugs — {user}" |
| `TITLE_BUGDETAIL` | `&1` | Screen 0300 — nhận "Create Bug" / "Change Bug: BUG0001" |
| `TITLE_PROJLIST` | `&1` | Screen 0400 — nhận "Project List" |
| `TITLE_PRJDET` | `&1` | Screen 0500 — nhận "Create Project" / "Change Project: {name}" |

> **`&1` là placeholder:** Khi code viết `SET TITLEBAR 'TITLE_BUGLIST' WITH lv_title`, SAP thay `&1` bằng giá trị của `lv_title`. Chỉ cần `&1` — không cần text khác.

Save + Activate tất cả.

---

## Step 4: Tạo Screens (SE51)

Tạo screens theo thứ tự sau (subscreens trước, host screens sau):

| Order | Screen | Guide File | Complexity |
|-------|--------|-----------|------------|
| 1 | **0400** | `UI_SCREEN_0400.md` | Simple — 1 Custom Control |
| 2 | **0200** | `UI_SCREEN_0200.md` | Simple — 1 Custom Control |
| 3 | **0310** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 2 | Complex — 12+ fields + groups + mini editor |
| 4 | **0320** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 3 | Simple — 1 Custom Control |
| 5 | **0330** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 4 | Simple — 1 Custom Control (**CC_DEVNOTE**!) |
| 6 | **0340** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 5 | Simple — 1 Custom Control (**CC_TSTRNOTE**!) |
| 7 | **0350** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 6 | Simple — 1 Custom Control (placeholder) |
| 8 | **0360** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 7 | Simple — 1 Custom Control |
| 9 | **0300** | `UI_SCREEN_0300_SUBSCREENS.md` Phần 1 | Complex — Tab Strip + Subscreen Area |
| 10 | **0500** | `UI_SCREEN_0500.md` | Complex — Fields + Table Control |
| 11 | **0100** | Below (Step 7) | Simple — deprecated screen |

> **Quan trọng:** Tạo subscreens 0310-0360 **TRƯỚC** host 0300. Nếu tạo 0300 trước, `CALL SUBSCREEN` sẽ warning.

---

## Step 5: Đổi T-code Initial Screen (SE93)

1. Gõ **SE93** → nhập `ZBUG_WS` → **Change**
2. Field **"Screen number"**: đổi từ `0100` → **`0400`**
3. Program name vẫn là `Z_BUG_WORKSPACE_MP`
4. **Save**

> Nếu T-code chưa tồn tại:
> 1. SE93 → `ZBUG_WS` → **Create**
> 2. Transaction Type: **Dialog transaction** (Type T)
> 3. Program: `Z_BUG_WORKSPACE_MP`
> 4. Screen: `0400`
> 5. Save → assign to package `ZBUGTRACK`

**Verify:** Gõ `ZBUG_WS` → phải mở thẳng Screen 0400 (Project List).

---

## Step 6: Activation Order

### Full Activation Sequence:

```
1. Z_BUG_WS_TOP   (Ctrl+F3)
2. Z_BUG_WS_F00   (Ctrl+F3)
3. Z_BUG_WS_PBO   (Ctrl+F3)
4. Z_BUG_WS_PAI   (Ctrl+F3)
5. Z_BUG_WS_F01   (Ctrl+F3)
6. Z_BUG_WS_F02   (Ctrl+F3)
7. Z_BUG_WORKSPACE_MP (main program — Ctrl+F3)
   → Hoặc: Ctrl+Shift+F3 (Activate All) → chọn tất cả → Activate
```

Sau includes:
```
8.  Screen 0310 (subscreen)
9.  Screen 0320 (subscreen)
10. Screen 0330 (subscreen)
11. Screen 0340 (subscreen)
12. Screen 0350 (subscreen)
13. Screen 0360 (subscreen)
14. Screen 0300 (host — SAU subscreens)
15. Screen 0400 (initial)
16. Screen 0200
17. Screen 0500
18. Screen 0100 (deprecated)
```

Sau screens:
```
19. GUI Statuses (SE41) — nếu chưa activate
20. Title Bars (SE41) — nếu chưa activate
21. T-code ZBUG_WS (SE93)
```

> **Tip:** Dùng **Ctrl+Shift+F3** trong SE80 để activate tất cả objects cùng lúc.

---

## Step 7: Screen 0100 (Deprecated)

> Screen 0100 **không dùng** trong flow mới. Giữ lại để tránh dump.

### Tạo Screen:

1. SE80 → Create Screen → **`0100`**
2. Short Description: `Hub (DEPRECATED)`
3. Screen Type: **Normal**
4. Next Screen: `0100`

### Flow Logic:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE init_user_role.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

### Layout:

- Trống hoặc 1 text field: `This screen is deprecated. Use Project List instead.`
- Không cần custom controls hay buttons — PAI chỉ handle BACK/EXIT/CANC → LEAVE PROGRAM

Save + Activate.

---

## Step 8: Testing Checklist

### 8.1 Navigation Flow Tests:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Gõ `ZBUG_WS` | Mở Screen 0400 (Project List) | ☐ |
| 2 | Click project hotspot (PROJECT_ID) | Mở Screen 0200 (Bug List, all bugs of project) | ☐ |
| 3 | Click "My Bugs" button | Mở Screen 0200 (filtered by role, cross-project) | ☐ |
| 4 | BACK từ Bug List | Quay về Screen 0400 | ☐ |
| 5 | BACK từ Project List | LEAVE PROGRAM | ☐ |
| 6 | Create Bug từ project | Screen 0300, PROJECT_ID pre-filled + locked | ☐ |
| 7 | Create Bug button ẩn ở My Bugs mode | Nút CREATE không hiện | ☐ |
| 8 | BACK từ Bug Detail | Quay về Screen 0200 | ☐ |
| 9 | Create/Change/Display Project | Screen 0500 mở đúng mode | ☐ |
| 10 | BACK từ Project Detail | Quay về Screen 0400 | ☐ |

### 8.2 Bug CRUD Tests:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Create Bug | Auto-gen BUG_ID, save success, mode → Change | ☐ |
| 2 | BUG_ID readonly sau creation | Field locked (Group BID) | ☐ |
| 3 | Change Bug | Modify fields → Save success | ☐ |
| 4 | Display Bug | All fields readonly (EDT group disabled) | ☐ |
| 5 | Delete Bug | Confirm popup → soft delete → ALV refresh | ☐ |
| 6 | Save description mini editor | Text lưu vào gs_bug_detail-desc_text | ☐ |

### 8.3 Project CRUD Tests:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Create Project (Manager) | Save success | ☐ |
| 2 | Add User to Project | Popup → user appears in Table Control | ☐ |
| 3 | Remove User from Project | Confirm → user removed | ☐ |
| 4 | Delete Project | Soft delete + ALV refresh | ☐ |
| 5 | Upload Excel | File dialog → parse → insert → ALV refresh | ☐ |
| 6 | Download Template | Save dialog → file download | ☐ |

### 8.4 Display Tests:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Bug status | Shows text "New"/"Assigned"/... NOT code "1"/"2" | ☐ |
| 2 | Priority | Shows "High"/"Medium"/"Low" NOT "H"/"M"/"L" | ☐ |
| 3 | Severity | Shows "Dump/Critical"/"Normal"/... NOT "1"/"4" | ☐ |
| 4 | Bug Type | Shows "Functional"/"Performance"/... NOT "1"/"2" | ☐ |
| 5 | Project Status | Shows "Opening"/"In Process"/... NOT "1"/"2" | ☐ |
| 6 | Title bar (Bug Detail) | Shows "Create Bug" / "Change Bug: BUG0001" / "Display Bug: BUG0001" | ☐ |
| 7 | Title bar (Bug List) | Shows "Bugs — {project}" or "My Bugs — {user}" | ☐ |
| 8 | ALV row colors | Status-based coloring (Blue=New, Green=Fixed, etc.) | ☐ |

### 8.5 Role-Based Tests:

| # | Test (as Tester) | Expected | ✓ |
|---|-----------------|----------|---|
| 1 | Cannot see Create button on Bug List | Hidden by PBO | ☐ |
| 2 | Cannot see Delete button on Bug List | Hidden by PBO | ☐ |
| 3 | Cannot edit DEV_ID field | Group DEV disabled for Tester | ☐ |
| 4 | Cannot create/change/delete projects | Buttons hidden | ☐ |

| # | Test (as Developer) | Expected | ✓ |
|---|-------------------|----------|---|
| 1 | Cannot see Create button | Hidden | ☐ |
| 2 | Cannot see Delete button | Hidden | ☐ |
| 3 | Cannot edit TESTER_ID / VERIFY_TESTER_ID | Group TST disabled for Dev | ☐ |
| 4 | Cannot Upload Report (UP_REP hidden) | Hidden | ☐ |
| 5 | **v4.0** Cannot edit BUG_TYPE / PRIORITY / SEVERITY | Group FNC disabled for Dev | ☐ |

| # | Test (as Manager) | Expected | ✓ |
|---|-----------------|----------|---|
| 1 | Full access to all buttons | All visible | ☐ |
| 2 | Can create/change/delete projects | Buttons visible | ☐ |
| 3 | Can change bug status to any state | All transitions allowed | ☐ |

### 8.6 Tab Strip Tests:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Click Bug Info tab | Subscreen 0310 loads, fields visible | ☐ |
| 2 | Click Description tab | Subscreen 0320 loads, long text editor visible | ☐ |
| 3 | Click Dev Note tab | Subscreen 0330 loads, editor visible | ☐ |
| 4 | Click Tester Note tab | Subscreen 0340 loads, editor visible | ☐ |
| 5 | Click Evidence tab | Subscreen 0350 loads, **evidence ALV visible** (v4.0) | ☐ |
| 6 | Click History tab | Subscreen 0360 loads, history ALV visible | ☐ |
| 7 | Switch tabs → switch back | Data preserved (not lost on tab switch) | ☐ |
| 8 | Active tab highlight correct | Tab button highlighted matches active subscreen | ☐ |
| 9 | Open bug A → BACK → open bug B | Bug B data shown (not stale bug A data) | ☐ |

### 8.7 Status Transition Tests:

| From Status | Tester Can → | Developer Can → | Manager Can → |
|-------------|-------------|----------------|---------------|
| New (1) | Assigned, Waiting | — | Any |
| Assigned (2) | — | In Progress | Any |
| In Progress (3) | — | Pending, Fixed, Rejected | Any |
| Pending (4) | — | In Progress | Any |
| Fixed (5) | Resolved, Rejected | — | Any |
| Resolved (6) | Closed | — | Any |
| Closed (7) | — | — | Any |

### 8.8 v4.0 Feature Tests — Evidence:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Upload Evidence (UP_FILE) | File dialog → upload → evidence ALV refresh | ☐ |
| 2 | Upload Report (UP_REP) | Same + sets ATT_REPORT field | ☐ |
| 3 | Upload Fix (UP_FIX) | Same + sets ATT_FIX field | ☐ |
| 4 | Download Evidence (DL_EVD) | Select row on Evidence ALV → download binary file → auto-open | ☐ |
| 5 | Delete Evidence (via code) | Confirm popup → DELETE from ZBUG_EVIDENCE → ALV refresh | ☐ |
| 6 | Evidence ALV shows metadata | EVD_ID, File Name, MIME Type, Size, By, Date — no CONTENT | ☐ |

### 8.9 v4.0 Feature Tests — Email:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Send Email (SENDMAIL) | BCS popup → email sent with bug summary | ☐ |
| 2 | Check SOST after send | Email visible in SOST outbox | ☐ |

### 8.10 v4.0 Feature Tests — Template Downloads:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | DN_TC (Download TestCase template) | ZTEMPLATE_TESTCASE download + auto-open | ☐ |
| 2 | DN_CONF (Download Confirm template) | ZTEMPLATE_CONFIRM download + auto-open | ☐ |
| 3 | DN_PROOF (Download BugProof template) | ZTEMPLATE_BUGPROOF download + auto-open | ☐ |
| 4 | F4 Calendar on Project Start Date | Calendar popup → date filled | ☐ |
| 5 | F4 Calendar on Project End Date | Calendar popup → date filled | ☐ |

### 8.11 v4.0 Feature Tests — Validations:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Unsaved changes — change field then BACK | Popup "Save before leaving?" | ☐ |
| 2 | Bug type Dump + Priority not High | Validation error: must set Priority=High | ☐ |
| 3 | Close project with open bugs | Validation error: resolve all bugs first | ☐ |
| 4 | Transition to Fixed without BUGPROOF_ file | Validation error: upload BUGPROOF_ evidence | ☐ |
| 5 | Transition to Resolved without TESTCASE_ file | Validation error: upload TESTCASE_ evidence | ☐ |
| 6 | Transition to Closed without CONFIRM_ file | Validation error: upload CONFIRM_ evidence | ☐ |

---

## Step 9: Phase D — SMW0 Template Upload

> Cần làm **trước** khi "Download Template" buttons hoạt động.

### 9.1 Project Template (existing from v3.0)

1. Gõ **SMW0** → Enter
2. Chọn **Binary data for WebRFC applications**
3. Click **Create** → Object Name: **`ZTEMPLATE_PROJECT`**
4. Import file Excel template (`ZTEMPLATE_PROJECT.xlsx`) — file này phải có columns:

| Column A | Column B | Column C | Column D | Column E | Column F | Column G |
|----------|----------|----------|----------|----------|----------|----------|
| PROJECT_ID | PROJECT_NAME | DESCRIPTION | START_DATE | END_DATE | PROJECT_MANAGER | NOTE |
| (Char 20) | (Char 100) | (Char 255) | DD.MM.YYYY | DD.MM.YYYY | (Char 12) | (Char 255) |

5. **Save** + **Activate**

### 9.2 TestCase Template (v4.0 NEW)

1. SMW0 → **Create** → Object Name: **`ZTEMPLATE_TESTCASE`**
2. Import Excel template (`ZTEMPLATE_TESTCASE.xlsx`) — suggested columns:

| Column A | Column B | Column C | Column D | Column E |
|----------|----------|----------|----------|----------|
| Test Case ID | Test Steps | Expected Result | Actual Result | Pass/Fail |

3. **Save** + **Activate**

### 9.3 Confirm Template (v4.0 NEW)

1. SMW0 → **Create** → Object Name: **`ZTEMPLATE_CONFIRM`**
2. Import Excel template (`ZTEMPLATE_CONFIRM.xlsx`) — suggested columns:

| Column A | Column B | Column C | Column D | Column E |
|----------|----------|----------|----------|----------|
| Bug ID | Confirm Date | Confirmed By | Status | Notes |

3. **Save** + **Activate**

### 9.4 BugProof Template (v4.0 NEW)

1. SMW0 → **Create** → Object Name: **`ZTEMPLATE_BUGPROOF`**
2. Import Excel template (`ZTEMPLATE_BUGPROOF.xlsx`) — suggested columns:

| Column A | Column B | Column C | Column D | Column E |
|----------|----------|----------|----------|----------|
| Bug ID | Fix Description | Dev Notes | Screenshots Ref | Fix Date |

3. **Save** + **Activate**

> **Tổng SMW0 objects cần upload:** 4 templates (1 project + 3 bug workflow).
> Buttons: DN_TMPL (Screen 0400) → ZTEMPLATE_PROJECT | DN_TC/DN_CONF/DN_PROOF (Screen 0200) → ZTEMPLATE_TESTCASE/CONFIRM/BUGPROOF.

---

## Step 10: Phase D — Orphan Bug Cleanup

> Chạy **sau** khi tạo xong ít nhất 1 project (vd "LEGACY").

### Tạo Report Z_BUG_CLEANUP_ORPHAN:

1. **SE38** → `Z_BUG_CLEANUP_ORPHAN` → Create → Type **Executable** (1)
2. Paste code (từ `phase-d-advanced-features.md` v6.0)
3. Logic: SELECT bugs WHERE project_id IS INITIAL → UPDATE SET project_id = 'LEGACY'

### Trước khi chạy:

1. Tạo project "LEGACY" trong Screen 0500 (hoặc trực tiếp trong ZBUG_PROJECT)
2. Chạy `Z_BUG_CLEANUP_ORPHAN` (SE38 → F8)
3. Verify: tất cả bugs phải có project_id

---

## TROUBLESHOOTING CHUNG

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| "Class lcl_event_handler unknown" | Include Z_BUG_WS_F00 nằm SAU PBO trong main program | Fix include order: TOP → **F00** → PBO → PAI → F01 → F02 |
| "Module xxx not found" | Module name trong Flow Logic khác code | Compare tên chính xác — SAP phân biệt hoa/thường |
| "Screen field GS_BUG_DETAIL-xxx not found" | Field trên layout không khớp global var | Layout field name phải = `GS_BUG_DETAIL-BUG_ID` (khớp chính xác work area) |
| "Custom container CC_xxx not bound" | Container name trên layout khác code | Verify đúng tên: CC_DEVNOTE (no underscore), CC_TSTRNOTE (no underscore) |
| ALV chạy nhưng không có data | SELECT statement error hoặc table trống | SE16 → check ZBUG_PROJECT / ZBUG_TRACKER có data |
| "CONTROLS ts_detail TYPE TABSTRIP" error | Tab strip name trên layout khác code | Layout tab strip name = `TS_DETAIL`, code CONTROLS = `ts_detail` |
| Tab buttons không react khi click | FCode chưa set cho tab buttons | Double-click tab button → Attributes → FctCode |
| Buttons trên toolbar disabled (grey) | GUI Status chưa tạo hoặc fcode thiếu | SE41 → verify status + fcode list |
| `SET TITLEBAR ... WITH |...|` syntax error | String template không dùng trực tiếp trong SET TITLEBAR | Code v3.0 đã fix: dùng biến trung gian (DATA(lv_xxx) = ...) |

---

## TỔNG KẾT — FULL WORKFLOW

```
0. Tạo bảng ZBUG_EVIDENCE (SE11)       (Step 0 — v4.0 NEW)
1. Copy 6 CODE files (v4.0) vào SAP    (Step 1)
2. Activate All includes               (Step 1)
3. Tạo 5 GUI Statuses trong SE41       (Step 2)
4. Tạo 5 Title Bars trong SE41         (Step 3)
5. Tạo 11 Screens trong SE51           (Step 4)
   → Subscreens 0310-0360 trước
   → Host screens 0300, 0400, 0200, 0500, 0100 sau
6. Activate tất cả screens             (Step 6)
7. Đổi SE93 ZBUG_WS → Screen 0400    (Step 5)
8. Test toàn bộ flow                   (Step 8)
9. (Phase D) Upload 4 SMW0 templates   (Step 9 — 1 project + 3 bug workflow)
10. (Phase D) Chạy orphan cleanup      (Step 10)
```

**Estimated time:** ~3-4 giờ cho toàn bộ (screen creation + GUI Status + testing).
