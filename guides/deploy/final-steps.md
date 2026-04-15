# UI Guide: Final Steps — GUI Status, Title Bars, SE93, Activation, Testing

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **File này hướng dẫn tất cả bước còn lại sau khi đã tạo screens**
>
> **v5.0 changes:**
> - **+4 new GUI Statuses:** STATUS_0410, STATUS_0370, STATUS_0210, STATUS_0220
> - **+4 new Title Bars:** T_0410, T_0370, T_0210, T_0220
> - **STATUS_0200:** +SEARCH button
> - **+4 new Screens:** 0410 (initial), 0370 (popup), 0210 (popup), 0220 (full)
> - **SE93:** initial screen đổi từ `0400` → `0410`
> - **Testing checklist:** Updated cho 10-state lifecycle, auto-assign, dashboard, search, transition popup
> - **STATUS_0400:** KHÔNG còn là initial screen
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
1. [Step 1: Copy Code v5.0 vào SAP](#step-1-copy-code-v50-vào-sap)
2. [Step 2: Tạo GUI Statuses (SE41)](#step-2-tạo-gui-statuses-se41) — **v5.0: 9 statuses (5 existing + 4 new)**
3. [Step 3: Tạo Title Bars (SE41)](#step-3-tạo-title-bars-se41) — **v5.0: 9 title bars (5 existing + 4 new)**
4. [Step 4: Tạo Screens (SE51)](#step-4-tạo-screens-se51) — **v5.0: 15 screens (11 existing + 4 new)**
5. [Step 5: Đổi T-code Initial Screen (SE93)](#step-5-đổi-t-code-initial-screen-se93) — **v5.0: 0400 → 0410**
6. [Step 6: Activation Order](#step-6-activation-order)
7. [Step 7: Screen 0100 (Deprecated)](#step-7-screen-0100-deprecated)
8. [Step 8: Testing Checklist](#step-8-testing-checklist) — **v5.0: updated**
9. [Phase D: SMW0 Template Upload](#step-9-phase-d-smw0-template-upload) — **v5.0: template rename**
10. [Phase D: Orphan Bug Cleanup](#step-10-phase-d-orphan-bug-cleanup)
11. [Step 11: v5.0 Status Data Migration](#step-11-v50-status-data-migration) — **v5.0 NEW**

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

## Step 1: Copy Code v5.0 vào SAP

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

| Step | Include | Copy từ file | Lines (v5.0 est.) |
|------|---------|-------------|-------|
| 1 | `Z_BUG_WS_TOP` | `CODE_TOP.md` | ~250 |
| 2 | `Z_BUG_WS_F00` | `CODE_F00.md` | ~280 |
| 3 | `Z_BUG_WS_PBO` | `CODE_PBO.md` | ~700 |
| 4 | `Z_BUG_WS_PAI` | `CODE_PAI.md` | ~450 |
| 5 | `Z_BUG_WS_F01` | `CODE_F01.md` | ~1800 |
| 6 | `Z_BUG_WS_F02` | `CODE_F02.md` | ~650 |

> **v5.0 NOTE:** Code lớn hơn đáng kể so với v4.0 do: 4 new screens, dashboard, search engine, status matrix, auto-assign.

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
| 7 | **`SEARCH`** | **Search Bug** | **`ICON_SEARCH`** | **v5.0 NEW** — Mở popup Screen 0210 |
| 8 | *(separator)* | | | |
| 9 | `DN_TC` | Download TestCase | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_01 |
| 10 | `DN_CONF` | Download Confirm | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_03 |
| 11 | `DN_PROOF` | Download BugProof | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_02 |

**Cách thêm icon:** Khi tạo button, column "Icon Name" → nhập tên icon (vd `ICON_CREATE`). Hoặc click icon picker.

> **v5.0 NOTE:** Nếu STATUS_0200 đã tạo rồi (v4.0), chỉ cần mở lại → thêm SEARCH button sau REFRESH.

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
| 4 | `UP_FILE` | Upload Evidence | `ICON_IMPORT` | **v5.0:** Available in ALL modes (Create: auto-save first) |
| 5 | `UP_REP` | Upload Report | `ICON_IMPORT` | Excluded: Dev role + Create mode |
| 6 | `UP_FIX` | Upload Fix | `ICON_IMPORT` | Excluded: Tester role + Create mode |
| 7 | *(separator)* | | | |
| 8 | `DL_EVD` | Delete Evidence | `ICON_DELETE` | **v5.0** — Delete selected evidence row |
| 9 | `SENDMAIL` | Send Email | `ICON_MAIL` | **v4.0** — Send bug info via BCS API |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

> **CRITICAL:** Fcode `SAVE` **BẮT BUỘC** phải có trong status. Thiếu = nút Save không hiện kể cả ở Change mode.
> **v5.0:** `DL_EVD` deletes selected evidence row (with confirmation popup). `SENDMAIL` triggers `cl_bcs` email with bug summary.

Save + Activate.

---

### STATUS_0400 — Project List

> **v5.0:** Screen 0400 KHÔNG còn là initial screen. Initial screen là 0410 (Project Search).

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

### STATUS_0410 — Project Search (v5.0 NEW)

> **v5.0:** Screen mới — initial screen thay thế 0400.

**Short Description:** `Project Search`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `EXECUTE` | Execute | `ICON_EXECUTE_OBJECT` | Search projects + CALL SCREEN 0400 |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

> **BACK/EXIT/CANCEL** đều → `LEAVE PROGRAM` (vì đây là initial screen).

Save + Activate.

---

### STATUS_0370 — Status Transition Popup (v5.0 NEW)

> **v5.0:** Modal dialog popup — thay thế `POPUP_GET_VALUES` cho status changes.

**Short Description:** `Change Bug Status`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `CONFIRM` | Confirm | `ICON_OKAY` | Validate + save transition |
| 2 | `UP_TRANS` | Upload Evidence | `ICON_IMPORT` | Upload evidence cho transition |

**Function Keys:** CANC (F12 — mapped to `CANCEL`)

> **LƯU Ý:** Modal dialogs thường KHÔNG có BACK/EXIT — chỉ có CANCEL (F12) để đóng popup.
> FCode `CANCEL` → `LEAVE TO SCREEN 0` (đóng popup, quay về calling screen).

Save + Activate.

---

### STATUS_0210 — Bug Search Input (v5.0 NEW)

> **v5.0:** Modal dialog popup — nhập search criteria.

**Short Description:** `Bug Search`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `EXECUTE` | Search | `ICON_SEARCH` | Execute search + CALL SCREEN 0220 |

**Function Keys:** CANC (F12 — mapped to `CANCEL`)

> **LƯU Ý:** Modal dialog — chỉ có EXECUTE + CANCEL.

Save + Activate.

---

### STATUS_0220 — Bug Search Results (v5.0 NEW)

> **v5.0:** Full screen — hiển thị kết quả search (ALV Grid, KHÔNG có dashboard).

**Short Description:** `Search Results`

**Application Toolbar buttons:**

| # | FCode | Text on Button | Icon | Notes |
|---|-------|---------------|------|-------|
| 1 | `CHANGE` | Change | `ICON_CHANGE` | Mở Bug Detail (Change mode) |
| 2 | `DISPLAY` | Display | `ICON_DISPLAY` | Mở Bug Detail (Display mode) |

**Function Keys:** BACK (F3), EXIT (Shift+F3), CANC (F12)

Save + Activate.

---

## Step 3: Tạo Title Bars (SE41)

### Cách tạo:

1. **SE41** → Program: `Z_BUG_WORKSPACE_MP`
2. Đổi **Object Type** dropdown (ở đầu screen) từ "Status" sang **"Title"**
3. Nhập tên title → **Create**
4. Nhập text (có `&1` placeholder) → **Save** + **Activate**

### 9 Title Bars cần tạo:

| Title Name | Text | Mô tả |
|------------|------|-------|
| `TITLE_MAIN` | `&1` | Screen 0100 — nhận "Bug Tracking Hub" |
| `TITLE_BUGLIST` | `&1` | Screen 0200 — nhận "Bugs — {project}" hoặc "My Bugs — {user}" |
| `TITLE_BUGDETAIL` | `&1` | Screen 0300 — nhận "Create Bug" / "Change Bug: BUG0001" |
| `TITLE_PROJLIST` | `&1` | Screen 0400 — nhận "Project List" |
| `TITLE_PRJDET` | `&1` | Screen 0500 — nhận "Create Project" / "Change Project: {name}" |
| **`T_0410`** | **`Project Search`** | **v5.0 NEW** — Screen 0410 (static text, no placeholder) |
| **`T_0370`** | **`Change Bug Status`** | **v5.0 NEW** — Screen 0370 (static text) |
| **`T_0210`** | **`Bug Search`** | **v5.0 NEW** — Screen 0210 (static text) |
| **`T_0220`** | **`Search Results`** | **v5.0 NEW** — Screen 0220 (static text) |

> **v5.0 NOTE:** 4 title bars mới dùng **static text** (không cần `&1` placeholder) vì title không thay đổi dynamically.

> **`&1` là placeholder:** Khi code viết `SET TITLEBAR 'TITLE_BUGLIST' WITH lv_title`, SAP thay `&1` bằng giá trị của `lv_title`. Chỉ cần `&1` — không cần text khác.

Save + Activate tất cả.

---

## Step 4: Tạo Screens (SE51)

Tạo screens theo thứ tự sau (subscreens trước, host screens sau, new screens cuối):

| Order | Screen | Guide File | Complexity |
|-------|--------|-----------|------------|
| 1 | **0410** | `screens/screen-0410-project-search.md` | **v5.0 NEW** — 3 input fields + 3 F4 |
| 2 | **0400** | `screens/screen-0400-project-list.md` | Simple — 1 Custom Control |
| 3 | **0200** | `screens/screen-0200-bug-list.md` | **v5.0 UPDATED** — 18 output fields (Dashboard) + 1 Custom Control |
| 4 | **0310** | `screens/screen-0300-bug-detail.md` Phần 2 | Complex — 12+ fields + groups + mini editor. **v5.0:** STATUS→STS group, +SAP_MODULE F4 |
| 5 | **0320** | `screens/screen-0300-bug-detail.md` Phần 3 | Simple — 1 Custom Control |
| 6 | **0330** | `screens/screen-0300-bug-detail.md` Phần 4 | Simple — 1 Custom Control (**CC_DEVNOTE**!) |
| 7 | **0340** | `screens/screen-0300-bug-detail.md` Phần 5 | Simple — 1 Custom Control (**CC_TSTRNOTE**!) |
| 8 | **0350** | `screens/screen-0300-bug-detail.md` Phần 6 | Simple — 1 Custom Control (Evidence ALV) |
| 9 | **0360** | `screens/screen-0300-bug-detail.md` Phần 7 | Simple — 1 Custom Control |
| 10 | **0300** | `screens/screen-0300-bug-detail.md` Phần 1 | Complex — Tab Strip + Subscreen Area |
| 11 | **0370** | `screens/screen-0370-status-transition.md` | **v5.0 NEW** — Modal Dialog, fields + Custom Control |
| 12 | **0210** | `screens/screen-0210-bug-search.md` | **v5.0 NEW** — Modal Dialog, search input fields |
| 13 | **0220** | `screens/screen-0220-search-results.md` | **v5.0 NEW** — Normal, 1 Custom Control (ALV) |
| 14 | **0500** | `screens/screen-0500-project-detail.md` | Complex — Fields + Table Control |
| 15 | **0100** | Below (Step 7) | Simple — deprecated screen |

> **v5.0 NOTE:**
> - Tạo **Screen 0410 ĐẦU TIÊN** (vì nó là initial screen mới)
> - Tạo **Screen 0370, 0210, 0220** sau khi host screens xong
> - Subscreens 0310-0360 vẫn phải tạo **TRƯỚC** host 0300
> - **Tổng:** 15 screens (11 existing + 4 new)

---

## Step 5: Đổi T-code Initial Screen (SE93)

> **v5.0 CHANGE:** Initial screen đổi từ `0400` → `0410` (Project Search).

1. Gõ **SE93** → nhập `ZBUG_WS` → **Change**
2. Field **"Screen number"**: đổi từ `0400` → **`0410`**
3. Program name vẫn là `Z_BUG_WORKSPACE_MP`
4. **Save**

> Nếu T-code chưa tồn tại:
> 1. SE93 → `ZBUG_WS` → **Create**
> 2. Transaction Type: **Dialog transaction** (Type T)
> 3. Program: `Z_BUG_WORKSPACE_MP`
> 4. Screen: **`0410`**
> 5. Save → assign to package `ZBUGTRACK`

**Verify:** Gõ `ZBUG_WS` → phải mở thẳng **Screen 0410** (Project Search), KHÔNG còn mở 0400.

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
8.  Screen 0410 (v5.0 NEW — initial screen)
9.  Screen 0310 (subscreen)
10. Screen 0320 (subscreen)
11. Screen 0330 (subscreen)
12. Screen 0340 (subscreen)
13. Screen 0350 (subscreen)
14. Screen 0360 (subscreen)
15. Screen 0300 (host — SAU subscreens)
16. Screen 0370 (v5.0 NEW — popup)
17. Screen 0210 (v5.0 NEW — popup)
18. Screen 0220 (v5.0 NEW — full screen)
19. Screen 0400
20. Screen 0200
21. Screen 0500
22. Screen 0100 (deprecated)
```

Sau screens:
```
23. GUI Statuses (SE41) — 9 total (5 existing + 4 new)
24. Title Bars (SE41) — 9 total (5 existing + 4 new)
25. T-code ZBUG_WS (SE93) — initial screen = 0410
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
| 1 | Gõ `ZBUG_WS` | **v5.0:** Mở Screen 0410 (Project Search) | ☐ |
| 2 | Nhập filter trên 0410 → Execute | Mở Screen 0400 (Project List, filtered) | ☐ |
| 3 | Click project hotspot (PROJECT_ID) | Mở Screen 0200 (ALL bugs + Dashboard, gv_bug_filter_mode='P') | ☐ |
| 4 | Click "My Bugs" button | Mở Screen 0200 (filtered by role, cross-project) | ☐ |
| 5 | BACK từ Bug List | Quay về Screen 0400 | ☐ |
| 6 | BACK từ Project List | Quay về Screen 0410 | ☐ |
| 7 | BACK từ Project Search | LEAVE PROGRAM | ☐ |
| 8 | Create Bug từ project | Screen 0300, PROJECT_ID pre-filled + locked | ☐ |
| 9 | Create Bug button ẩn ở My Bugs mode | Nút CREATE không hiện | ☐ |
| 10 | BACK từ Bug Detail | Quay về Screen 0200 | ☐ |
| 11 | Create/Change/Display Project | Screen 0500 mở đúng mode | ☐ |
| 12 | BACK từ Project Detail | Quay về Screen 0400 | ☐ |
| 13 | **v5.0:** Click SEARCH trên Bug List | Mở popup Screen 0210 | ☐ |
| 14 | **v5.0:** Nhập search criteria → Execute | Mở Screen 0220 (Search Results) | ☐ |
| 15 | **v5.0:** BACK từ Search Results | Quay về Screen 0200 | ☐ |

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
| 3 | **v5.0:** Manager CANNOT bypass transition rules | Must follow matrix like Tester/Dev | ☐ |
| 4 | **v5.0:** Manager can see broader transition options | More targets than Dev/Tester, but NOT arbitrary | ☐ |

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

### 8.7 Status Transition Tests (v5.0 — 10-state lifecycle):

> **v5.0 BREAKING CHANGE:** `6` = Final Testing (không phải Resolved), `V` = Resolved (mới). Manager KHÔNG bypass.
> Status change qua popup **Screen 0370** (không sửa trực tiếp trên screen).

| From Status | Tester Can → | Developer Can → | Manager Can → |
|-------------|-------------|----------------|---------------|
| New (1) | Assigned(2), Waiting(W) | — | Assigned(2), Waiting(W), Rejected(R) |
| Assigned (2) | — | InProgress(3) | InProgress(3) |
| InProgress (3) | — | Pending(4), Fixed(5) | Pending(4), Fixed(5) |
| Pending (4) | — | Assigned(2) | Assigned(2) |
| Fixed (5) | — | — | FinalTesting(6), Waiting(W) |
| FinalTesting (6) | Resolved(V), InProgress(3) | — | Resolved(V), InProgress(3) |
| Resolved (V) | — | — | — *(TERMINAL)* |
| Rejected (R) | — | — | — *(TERMINAL)* |
| Waiting (W) | Assigned(2) | — | Assigned(2) |
| Closed (7) | — | — | — *(LEGACY)* |

> **Auto-assign triggers:**
> - New(1) → Assigned(2): auto-assign Developer (least loaded, same module, <5 bugs)
> - Fixed(5) → FinalTesting(6): auto-assign Tester (least loaded)
> - If no available Dev/Tester → status goes to Waiting(W) instead

| # | v5.0 Specific Transition Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Status field trên Bug Info tab | ALWAYS locked (screen group STS) | ☐ |
| 2 | Click "Change Status" button | Mở popup Screen 0370 | ☐ |
| 3 | Popup hiển thị target status dropdown | Chỉ hiện statuses được phép theo matrix + role | ☐ |
| 4 | Transition New→Assigned | Auto-assign Developer (check DEV_ID filled) | ☐ |
| 5 | Transition Fixed→FinalTesting | Auto-assign Tester (check VERIFY_TESTER_ID filled) | ☐ |
| 6 | Transition to Fixed | Yêu cầu evidence (COUNT > 0 trong ZBUG_EVIDENCE) | ☐ |
| 7 | Transition to Resolved | Yêu cầu Transition Note (bắt buộc nhập) | ☐ |
| 8 | Manager cố chuyển 3→1 (ngược) | BLOCKED — không có trong matrix | ☐ |
| 9 | Tester cố chuyển InProgress→Fixed | BLOCKED — chỉ Dev được | ☐ |
| 10 | Cancel popup 0370 | Không thay đổi status | ☐ |

### 8.8 v4.0 Feature Tests — Evidence:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Upload Evidence (UP_FILE) | File dialog → upload → evidence ALV refresh | ☐ |
| 2 | Upload Report (UP_REP) | Same + sets ATT_REPORT field | ☐ |
| 3 | Upload Fix (UP_FIX) | Same + sets ATT_FIX field | ☐ |
| 4 | Delete Evidence (DL_EVD) | Select row on Evidence ALV → confirm popup → DELETE from ZBUG_EVIDENCE → ALV refresh | ☐ |
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
| 4 | Transition to Fixed without evidence | **v5.0:** Validation error in popup 0370 | ☐ |
| 5 | **v5.0:** Validation error shows `TYPE 'S' DISPLAY LIKE 'E'` | Screen fields NOT locked after error | ☐ |

### 8.12 v5.0 Feature Tests — Dashboard:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Screen 0200 hiển thị Dashboard phía trên | Total Bugs, By Status, By Priority, By Module | ☐ |
| 2 | Total Bugs = số bugs trong ALV | Khớp chính xác | ☐ |
| 3 | Sum of By Status = Total Bugs | Tổng tất cả status counts = Total | ☐ |
| 4 | Dashboard update khi ALV data thay đổi | Sau REFRESH → metrics update | ☐ |
| 5 | My Bugs mode cũng hiện Dashboard | Dashboard tính từ gt_bug_list (filtered) | ☐ |

### 8.13 v5.0 Feature Tests — Bug Search:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Click SEARCH trên Screen 0200 | Popup Screen 0210 hiện lên | ☐ |
| 2 | Nhập Bug ID → Execute | Screen 0220 hiện với bug tìm được | ☐ |
| 3 | Nhập keyword trong Title → Execute | Screen 0220 hiện bugs có keyword trong title | ☐ |
| 4 | Nhập không khớp gì → Execute | Screen 0220 hiện ALV trống hoặc message "No results" | ☐ |
| 5 | Screen 0220 KHÔNG có Dashboard | Chỉ có ALV Grid, không có metrics | ☐ |
| 6 | Click Display trên 0220 | Mở Bug Detail (Display mode) | ☐ |
| 7 | BACK từ 0220 | Quay về Screen 0200 | ☐ |

### 8.14 v5.0 Feature Tests — Project Search:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Screen 0410 là initial screen | Gõ ZBUG_WS → mở 0410 | ☐ |
| 2 | F4 trên Project ID | Hiện danh sách projects | ☐ |
| 3 | F4 trên Manager | Hiện danh sách Managers | ☐ |
| 4 | F4 trên Status | Hiện 4 statuses (Opening/InProcess/Done/Cancelled) | ☐ |
| 5 | Execute không nhập gì | Screen 0400 hiện ALL projects (mà user có quyền) | ☐ |
| 6 | Execute với filter Project ID | Screen 0400 chỉ hiện matching projects | ☐ |
| 7 | BACK từ 0410 | LEAVE PROGRAM | ☐ |

### 8.15 v5.0 Feature Tests — Auto-Assign:

| # | Test | Expected | ✓ |
|---|------|----------|---|
| 1 | Transition New→Assigned | DEV_ID tự động fill = least-loaded Dev (cùng module, <5 bugs) | ☐ |
| 2 | Transition Fixed→FinalTesting | VERIFY_TESTER_ID tự động fill = least-loaded Tester | ☐ |
| 3 | No available Dev (all ≥5 bugs) | Status chuyển sang Waiting(W) thay vì Assigned | ☐ |
| 4 | No available Tester | Status chuyển sang Waiting(W) thay vì FinalTesting | ☐ |

### 8.16 v5.0 Bug Fix Verification:

| # | Bug # | Test | Expected | ✓ |
|---|-------|------|----------|---|
| 1 | Bug 1+9 | Mở tab Description/DevNote/TesterNote | KHÔNG short dump | ☐ |
| 2 | Bug 4 | Bug Info tab hiện SAP Module, Severity, Created Date | Fields visible | ☐ |
| 3 | Bug 5 | Click Remove User không chọn row | Warning message, KHÔNG xóa | ☐ |
| 4 | Bug 6 | Create Bug → Status = 1 (New), Created Date auto | Auto-fill | ☐ |
| 5 | Bug 6 | F4 trên SAP Module | Hiện: FI, MM, SD, ABAP, BASIS, PP, HR, QM | ☐ |
| 6 | Bug 7 | Validation error → fields NOT locked | User có thể sửa lại ngay | ☐ |
| 7 | Bug 8 | Save bug → view detail lại | Description KHÔNG biến mất | ☐ |
| 8 | Bug 10 | Manager cố chuyển status 3→1 | BLOCKED | ☐ |
| 9 | Bug 11 | Chuyển status mà chưa có evidence (khi cần) | BLOCKED | ☐ |

---

## Step 9: Phase D — SMW0 Template Upload

> Cần làm **trước** khi "Download Template" buttons hoạt động.
> **v5.0 NOTE:** Template download filenames đổi tên (xem bảng F4 trong Phase F guide):
> - `ZBT_TMPL_01` → download name: `Bug_report.xlsx`
> - `ZBT_TMPL_02` → download name: `fix_report.xlsx`
> - `ZBT_TMPL_03` → download name: `confirm_report.xlsx`

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

## Step 11: v5.0 Status Data Migration — NEW

> **CRITICAL:** Chạy **sau** khi deploy code v5.0 và **trước** khi test.
> Status `6` đổi ý nghĩa từ "Resolved" (v4.x) sang "Final Testing" (v5.0).

### 11.1 Migration Script

Chạy trong SE38 (tạo report tạm hoặc chạy trực tiếp):

```abap
" Migrate existing status '6' (old Resolved) → 'V' (new Resolved)
UPDATE zbug_tracker SET status = 'V' WHERE status = '6'.
IF sy-subrc = 0.
  WRITE: / 'Migrated', sy-dbcnt, 'bugs from status 6 (old Resolved) to V (new Resolved).'.
ELSE.
  WRITE: / 'No bugs with status 6 found. Migration not needed.'.
ENDIF.
COMMIT WORK.
```

### 11.2 Verify Migration

```sql
" SE16 → ZBUG_TRACKER → Execute
" Check: Không còn bugs nào có STATUS = '6' mà nghĩa là "Resolved"
" STATUS = '6' bây giờ = "Final Testing" (chỉ có bugs mới tạo sau v5.0)
" STATUS = 'V' = "Resolved" (bugs đã migrate)
```

### 11.3 Test Data Population (Optional)

Xem Phase F guide `docs/phases/phase-f-v5-enhancement.md` Bước F8 — tạo 20 mock Developers + 10 mock Testers cho auto-assign testing.

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
| **v5.0:** Screen 0410 không hiện | SE93 chưa đổi initial screen | SE93 → ZBUG_WS → Change → Screen = 0410 |
| **v5.0:** Status vẫn sửa trực tiếp được | Screen group chưa đổi STS | SE51 → Screen 0310 → STATUS field → Group1 = `STS` |
| **v5.0:** Status `6` bugs hiện sai text | Chưa chạy migration script | Step 11 — UPDATE status '6' → 'V' |
| **v5.0:** Dashboard toàn 0 | `calculate_dashboard` chưa gọi | Verify PBO `status_0200` → `PERFORM calculate_dashboard` |
| **v5.0:** SEARCH button không hiện | Chưa thêm vào STATUS_0200 | SE41 → STATUS_0200 → thêm SEARCH fcode |

---

## TỔNG KẾT — FULL WORKFLOW (v5.0)

```
0.  Tạo bảng ZBUG_EVIDENCE (SE11)        (Step 0 — v4.0, nếu chưa tạo)
1.  Copy 6 CODE files (v5.0) vào SAP     (Step 1)
2.  Activate All includes                (Step 1)
3.  Tạo 9 GUI Statuses trong SE41        (Step 2 — 5 existing + 4 new)
4.  Tạo 9 Title Bars trong SE41          (Step 3 — 5 existing + 4 new)
5.  Tạo 15 Screens trong SE51            (Step 4 — 11 existing + 4 new)
    → Screen 0410 đầu tiên (initial screen mới)
    → Subscreens 0310-0360 trước host 0300
    → Screens 0370, 0210, 0220 sau
6.  Activate tất cả screens              (Step 6)
7.  Đổi SE93 ZBUG_WS → Screen 0410      (Step 5 — v5.0 change)
8.  Chạy Status Migration (6→V)          (Step 11 — v5.0 NEW)
9.  (Optional) Populate test data        (Step 11.3)
10. Test toàn bộ flow                    (Step 8 — v5.0 updated checklist)
11. (Phase D) Upload 4 SMW0 templates    (Step 9 — renamed in v5.0)
12. (Phase D) Chạy orphan cleanup        (Step 10)
```

**Estimated time:** ~5-6 giờ cho toàn bộ (15 screens + 9 GUI Statuses + 9 Title Bars + migration + testing).
