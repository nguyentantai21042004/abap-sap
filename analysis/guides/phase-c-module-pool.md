# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE C: MODULE POOL UI (v2.0)

**Dự án:** SAP Bug Tracking Management System
**Cập nhật:** 09/04/2026 | **Phiên bản:** 2.0 (Project-First Flow)
**SAP:** S40 | Client 324 | **ABAP 770**
**Package:** `ZBUGTRACK` | **Program:** `Z_BUG_WORKSPACE_MP` (Type M)
**Yêu cầu:** Phase A (database) hoàn thành, Phase B (business logic) đã có FMs

> **BREAKING CHANGES so với v1.0:**
> - Screen 0400 (Project List) là **initial screen** — thay vì Screen 0100 (Hub)
> - Screen 0100 (Hub) **deprecated** — code giữ nhưng không navigate tới
> - Bug **bắt buộc thuộc 1 Project** — không cho tạo bug lỏng
> - Project hotspot trên Project ALV → **mở Bug List** (thay vì Project Detail)
> - Nút **My Bugs** trên Project List → xem bugs cross-project theo role
> - Description mini editor trên Bug Info tab (subscreen 0310)
> - Type fixes: STATUS = CHAR 20, SAP_MODULE = CHAR 20, REASON = STRING

---

## MỤC LỤC

1. [C1: Tạo Program + Includes](#c1-tạo-program--includes)
2. [C2: Copy Code vào 6 Includes](#c2-copy-code-vào-6-includes)
3. [C3: SE93 — Đổi T-code Initial Screen](#c3-se93--đổi-t-code-initial-screen)
4. [C4: SE41 — Tạo 5 GUI Statuses](#c4-se41--tạo-5-gui-statuses)
5. [C5: SE41 — Tạo 5 Title Bars](#c5-se41--tạo-5-title-bars)
6. [C6: Screen 0400 — Project List (INITIAL)](#c6-screen-0400--project-list-initial)
7. [C7: Screen 0200 — Bug List (Dual Mode)](#c7-screen-0200--bug-list-dual-mode)
8. [C8: Screen 0300 — Bug Detail (Tab Strip Host)](#c8-screen-0300--bug-detail-tab-strip-host)
9. [C9: Subscreens 0310-0360](#c9-subscreens-0310-0360)
10. [C10: Screen 0500 — Project Detail + Table Control](#c10-screen-0500--project-detail--table-control)
11. [C11: Screen 0100 — Hub (DEPRECATED)](#c11-screen-0100--hub-deprecated)
12. [C12: Deprecate Old Programs](#c12-deprecate-old-programs)
13. [C13: Testing Checklist](#c13-testing-checklist)

---

## C1: Tạo Program + Includes

> **Skip nếu đã tạo** — program `Z_BUG_WORKSPACE_MP` + 6 includes đã tồn tại.

### SE80 Steps:

1. **SE80** → chọn "Program" → nhập `Z_BUG_WORKSPACE_MP` → Enter
2. "With TOP INCL." = Yes → Type = **Module Pool (M)** → Status = Test (T) → Package = `ZBUGTRACK`
3. SAP tự tạo `Z_BUG_WS_TOP`
4. Right-click program → Create → Include → lần lượt tạo:
   - `Z_BUG_WS_F00`
   - `Z_BUG_WS_PBO`
   - `Z_BUG_WS_PAI`
   - `Z_BUG_WS_F01`
   - `Z_BUG_WS_F02`

### Main Program Code:

```abap
PROGRAM z_bug_workspace_mp.
INCLUDE z_bug_ws_top.    " 1. Global data
INCLUDE z_bug_ws_f00.    " 2. Event class (PHẢI trước PBO/PAI)
INCLUDE z_bug_ws_pbo.    " 3. PBO
INCLUDE z_bug_ws_pai.    " 4. PAI
INCLUDE z_bug_ws_f01.    " 5. Business logic
INCLUDE z_bug_ws_f02.    " 6. Helpers
```

> **Thứ tự bắt buộc:** F00 TRƯỚC PBO/PAI vì class `lcl_event_handler` cần define trước khi reference.

Save + Activate.

**Checkpoint:** SE80 → thấy 6 includes trong navigation tree.

---

## C2: Copy Code vào 6 Includes

Mở từng include trong SE80, **xóa hết nội dung cũ**, paste code mới từ các file guide:

| Include | Copy từ file | Nội dung |
|---------|-------------|----------|
| `Z_BUG_WS_TOP` | `CODE_TOP.md` | Global vars, types, constants, ALV objects |
| `Z_BUG_WS_F00` | `CODE_F00.md` | Event handler class + 3 field catalogs |
| `Z_BUG_WS_PBO` | `CODE_PBO.md` | 11 PBO modules |
| `Z_BUG_WS_PAI` | `CODE_PAI.md` | 5 PAI modules + table control sync |
| `Z_BUG_WS_F01` | `CODE_F01.md` | 15 FORM routines (SQL, save, delete, status...) |
| `Z_BUG_WS_F02` | `CODE_F02.md` | 8 FORM routines (F4 helps, long text load/save) |

### Quy trình copy:

1. Mở `CODE_TOP.md` → copy toàn bộ nội dung ABAP (bỏ dòng markdown/comment đầu nếu có)
2. SE80 → double-click `Z_BUG_WS_TOP` → **Change** → Ctrl+A → Delete → Paste
3. **Save (Ctrl+S)**
4. Lặp lại cho 5 includes còn lại
5. Sau khi paste xong tất cả 6 → **Activate All** (Ctrl+Shift+F3):
   - Chọn tất cả objects → Activate
   - Nếu có warning (unused variables) → OK, bỏ qua
   - Nếu có **error** → xem Section "Troubleshooting" cuối file

**Checkpoint:** Program activate thành công, không có syntax error.

---

## C3: SE93 — Đổi T-code Initial Screen

> **Quan trọng:** T-code `ZBUG_HOME` phải trỏ tới Screen **0400** (Project List) thay vì 0100.

1. **SE93** → nhập `ZBUG_HOME` → **Change**
2. Field "Initial Screen": đổi từ `0100` → **`0400`**
3. Program name vẫn là `Z_BUG_WORKSPACE_MP`
4. **Save** → Activate

> Nếu T-code chưa tồn tại: SE93 → `ZBUG_HOME` → Create → Transaction with parameters (Dialog transaction) → Program = `Z_BUG_WORKSPACE_MP`, Screen = `0400`.

**Checkpoint:** Gõ `ZBUG_HOME` → mở thẳng Screen 0400 (Project List).

---

## C4: SE41 — Tạo 5 GUI Statuses

### Cách vào SE41:

1. Gõ **SE41** → Enter
2. Program: `Z_BUG_WORKSPACE_MP`
3. Status: nhập tên (vd `STATUS_0100`) → **Create (F5)**
4. Short Description → Enter → màn hình vẽ nút hiện ra

### Cách thêm nút:

- Click ô trống trong **Application Toolbar**
- Điền Function Code (FCode) + Text → Enter
- Trong **Function Keys** tab: gán phím tắt cho BACK/EXIT/CANC

### Standard Toolbar (tích cho MỌI status):

Tất cả 5 statuses đều cần 3 nút standard:

| Function Code | Gán vào phím | Mô tả |
|---------------|-------------|-------|
| `BACK` | F3 (= Standard Back) | Back |
| `EXIT` | Shift+F3 | Exit |
| `CANC` | F12 | Cancel |

---

### STATUS_0100 — Hub (DEPRECATED)

**Short Description:** `Bug Tracking Hub (Deprecated)`

| # | FCode | Text | Icon |
|---|-------|------|------|
| 1 | `BUG_LIST` | Bug List | — |
| 2 | `PROJ_LIST` | Project List | — |

> Status này giữ để code không dump nếu ai đó vô tình call Screen 0100.

---

### STATUS_0200 — Bug List

**Short Description:** `Bug List`

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `CREATE` | Create Bug | `ICON_CREATE` | Hidden: Dev role, My Bugs mode |
| 2 | `CHANGE` | Change | `ICON_CHANGE` | |
| 3 | `DISPLAY` | Display | `ICON_DISPLAY` | |
| 4 | `DELETE` | Delete | `ICON_DELETE` | Hidden: Dev, Tester, My Bugs mode |
| 5 | — | *(separator)* | | |
| 6 | `REFRESH` | Refresh | `ICON_REFRESH` | |

---

### STATUS_0300 — Bug Detail

**Short Description:** `Bug Detail`

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Hidden: Display mode |
| 2 | `STATUS_CHG` | Change Status | `ICON_CHANGE` | Hidden: Create mode |
| 3 | — | *(separator)* | | |
| 4 | `UP_FILE` | Upload Evidence | `ICON_IMPORT` | Hidden: Create mode |
| 5 | `UP_REP` | Upload Report | `ICON_IMPORT` | Hidden: Dev role |
| 6 | `UP_FIX` | Upload Fix | `ICON_IMPORT` | Hidden: Tester role |

> **CRITICAL:** Đảm bảo fcode `SAVE` có trong status. Thiếu `SAVE` = nút Save sẽ không hiện kể cả ở Change mode.

---

### STATUS_0400 — Project List (INITIAL SCREEN)

**Short Description:** `Project List`

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `MY_BUGS` | My Bugs | `ICON_BIW_REPORT` | **NEW** — All roles |
| 2 | — | *(separator)* | | |
| 3 | `CREA_PRJ` | Create Project | `ICON_CREATE` | Manager only |
| 4 | `CHNG_PRJ` | Change | `ICON_CHANGE` | Manager only |
| 5 | `DISP_PRJ` | Display | `ICON_DISPLAY` | All |
| 6 | `DEL_PRJ` | Delete | `ICON_DELETE` | Manager only |
| 7 | — | *(separator)* | | |
| 8 | `UPLOAD` | Upload Excel | `ICON_IMPORT` | Manager only |
| 9 | `DN_TMPL` | Download Template | `ICON_EXPORT` | Manager only |
| 10 | `REFRESH` | Refresh | `ICON_REFRESH` | All |

> **LƯU Ý:** Nút `MY_BUGS` là mới — không có trong version cũ.

---

### STATUS_0500 — Project Detail

**Short Description:** `Project Detail`

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Manager + Change/Create only |
| 2 | — | *(separator)* | | |
| 3 | `ADD_USER` | Add User | `ICON_INSERT_ROW` | Manager + Change/Create only |
| 4 | `REMO_USR` | Remove User | `ICON_DELETE_ROW` | Manager + Change/Create only |

> Fcode `REMO_USR` (không phải `REMOVE_USER`) — giới hạn 8 ký tự cho fcode.

---

Save + Activate từng status.

**Checkpoint:** SE41 → tất cả 5 statuses hiện xanh (activated).

---

## C5: SE41 — Tạo 5 Title Bars

Trong SE41, chuyển sang **Object Type: Title** (dropdown ở đầu màn hình):

1. Program: `Z_BUG_WORKSPACE_MP`
2. Object Type: **Title**
3. Nhập tên → Create

| Title Name | Text | Used by |
|------------|------|---------|
| `TITLE_MAIN` | `&1` | Screen 0100 — nhận 1 param |
| `TITLE_BUGLIST` | `&1` | Screen 0200 — nhận title text |
| `TITLE_BUGDETAIL` | `&1` | Screen 0300 — nhận mode + bug_id |
| `TITLE_PROJLIST` | `&1` | Screen 0400 — nhận "Project List" |
| `TITLE_PRJDET` | `&1` | Screen 0500 — nhận project name |

> **Cách SET TITLEBAR hoạt động:** Khi code viết `SET TITLEBAR 'TITLE_BUGLIST' WITH 'Bugs — ProjectX'`, SAP thay `&1` bằng text đó. Vì vậy chỉ cần define `&1` trong Title.

Save + Activate.

---

## C6: Screen 0400 — Project List (INITIAL)

> **Đây là screen đầu tiên user thấy** khi mở T-code `ZBUG_HOME`.

### C6.1: Tạo Screen trong SE51

1. **SE80** → `Z_BUG_WORKSPACE_MP` → Right-click → Create → **Screen** → Number: **0400**
2. Short Description: `Project List`
3. Screen Type: **Normal**
4. Next Screen: `0400` (loop back to itself — navigation handled by PAI)

### C6.2: Flow Logic (tab "Flow Logic")

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_user_role.
  MODULE status_0400.
  MODULE init_project_list.

PROCESS AFTER INPUT.
  MODULE user_command_0400.
```

> **LƯU Ý:** `init_user_role` phải chạy ở đây vì 0400 là initial screen. Module này chỉ load role 1 lần (CHECK gv_role IS INITIAL).

### C6.3: Layout (tab "Layout")

Click **Layout** button → Screen Painter mở ra.

1. **Vẽ Custom Control:**
   - Menu: Edit → Create Element → Custom Control
   - Hoặc: click icon Custom Control trên toolbar → vẽ hình chữ nhật phủ gần toàn bộ screen
   - Name: **`CC_PROJECT_LIST`**
   - Size: chiếm ~90% diện tích screen (để lại chút margin trên/dưới)

2. **Không cần vẽ thêm gì khác** — tất cả buttons nằm trên GUI Status toolbar

3. Save + Activate Screen

**Checkpoint:** SE80 → double-click Screen 0400 → thấy `CC_PROJECT_LIST` trong Element List.

---

## C7: Screen 0200 — Bug List (Dual Mode)

### C7.1: Tạo Screen

1. SE80 → Right-click program → Create → Screen → **0200**
2. Short Description: `Bug List`
3. Screen Type: Normal
4. Next Screen: `0200`

### C7.2: Flow Logic

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  MODULE init_bug_list.

PROCESS AFTER INPUT.
  MODULE user_command_0200.
```

### C7.3: Layout

1. Vẽ Custom Control: **`CC_BUG_LIST`** — phủ gần toàn bộ screen
2. Save + Activate

**Checkpoint:** Screen 0200 activated.

---

## C8: Screen 0300 — Bug Detail (Tab Strip Host)

### C8.1: Tạo Screen

1. SE80 → Create Screen → **0300**
2. Short Description: `Bug Detail`
3. Screen Type: Normal
4. Next Screen: `0300`

### C8.2: Flow Logic

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0300.
  MODULE load_bug_detail.
  MODULE modify_screen_0300.
  CALL SUBSCREEN ss_tab INCLUDING sy-repid gv_active_subscreen.

PROCESS AFTER INPUT.
  CALL SUBSCREEN ss_tab.
  MODULE user_command_0300.
```

> **CALL SUBSCREEN** yêu cầu:
> - Có Subscreen Area tên `SS_TAB` trên layout
> - `gv_active_subscreen` chứa screen number (0310-0360)
> - PBO: `INCLUDING sy-repid gv_active_subscreen`
> - PAI: chỉ `CALL SUBSCREEN ss_tab.` (không có INCLUDING)

### C8.3: Layout — Tab Strip + Subscreen Area

**Bước 1: Vẽ Tab Strip**

1. Mở Layout Editor
2. Menu: Edit → Create Element → Tab Strip (hoặc click icon TabStrip trên toolbar)
3. Vẽ hình chữ nhật phủ ~85% screen (để chừa toolbar phía trên)
4. Name: **`TS_DETAIL`**
5. SAP hỏi số tabs → nhập **6**
6. SAP tạo 6 tab buttons. Đặt tên + FCode cho từng tab:

| Tab # | Name (button) | Text | FCode |
|-------|--------------|------|-------|
| 1 | `TAB_INFO` | Bug Info | `TAB_INFO` |
| 2 | `TAB_DESC` | Description | `TAB_DESC` |
| 3 | `TAB_DEVNOTE` | Dev Note | `TAB_DEVNOTE` |
| 4 | `TAB_TSTR_NOTE` | Tester Note | `TAB_TSTR_NOTE` |
| 5 | `TAB_EVIDENCE` | Evidence | `TAB_EVIDENCE` |
| 6 | `TAB_HISTORY` | History | `TAB_HISTORY` |

**Bước 2: Vẽ Subscreen Area bên trong Tab Strip**

1. Click vào vùng trống bên trong tab strip body
2. Menu: Edit → Create Element → Subscreen Area
3. Vẽ hình chữ nhật lấp đầy phần body của tab strip
4. Name: **`SS_TAB`**

**Bước 3: Kết nối Tab Strip với subscreen (Reference Field)**

1. Double-click vào tab strip `TS_DETAIL` → Attributes
2. Đảm bảo "Control" Reference: `TS_DETAIL` (trong TOP đã có `CONTROLS: ts_detail TYPE TABSTRIP`)
3. Mỗi tab button có FCode tương ứng — PAI sẽ handle switch

Save + Activate Screen 0300.

**Checkpoint:** Screen 0300 có Tab Strip với 6 tabs + Subscreen Area `SS_TAB`.

---

## C9: Subscreens 0310-0360

> **Tất cả subscreens** phải có Screen Type = **Subscreen**.

### C9.1: Screen 0310 — Bug Info (Fields + Description Mini Editor)

**Tạo Screen:**
1. SE80 → Create Screen → **0310**
2. Short Description: `Bug Info`
3. Screen Type: **Subscreen**

**Flow Logic:**

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_desc_mini.

PROCESS AFTER INPUT.
```

> PBO module `init_desc_mini` tạo/load description mini editor.

**Layout — Step by step:**

**Bước 1: Thêm fields từ Dictionary**

1. Mở Layout Editor → click **Dict/Program Fields** (icon book trên toolbar)
2. Table/Field Name: `GS_BUG_DETAIL` → Get from Program
3. SAP liệt kê tất cả fields của `gs_bug_detail` (work area TYPE zbug_tracker)
4. Tick chọn các fields cần hiện:
   - `BUG_ID`, `TITLE`, `PROJECT_ID`, `STATUS`, `PRIORITY`
   - `SEVERITY`, `BUG_TYPE`, `SAP_MODULE`
   - `TESTER_ID`, `DEV_ID`, `VERIFY_TESTER_ID`
   - `CREATED_AT`
5. Click **Enter** → SAP tạo labels + input fields → kéo thả sắp xếp

**Bước 2: Thêm display text fields**

1. Dict/Program Fields → Variable: `GV_STATUS_DISP` → Get from Program
2. Kéo field ra cạnh STATUS field → Set **Input = OFF** (display-only)
3. Lặp lại cho: `GV_PRIORITY_DISP`, `GV_SEVERITY_DISP`, `GV_BUG_TYPE_DISP`

**Bước 3: Set Screen Groups**

Double-click từng field → tab Attributes → set Group1:

| Field | Group1 | Purpose |
|-------|--------|---------|
| `GS_BUG_DETAIL-BUG_ID` | **BID** | Display-only after creation |
| `GS_BUG_DETAIL-PROJECT_ID` | **PRJ** | Locked when creating from project |
| `GS_BUG_DETAIL-TITLE` | **EDT** | Editable (disabled in Display mode) |
| `GS_BUG_DETAIL-STATUS` | **EDT** | Editable |
| `GS_BUG_DETAIL-PRIORITY` | **EDT** | Editable |
| `GS_BUG_DETAIL-SEVERITY` | **EDT** | Editable |
| `GS_BUG_DETAIL-BUG_TYPE` | **EDT** | Editable |
| `GS_BUG_DETAIL-SAP_MODULE` | **EDT** | Editable |
| `GS_BUG_DETAIL-TESTER_ID` | **TST** | Only Tester/Manager can edit |
| `GS_BUG_DETAIL-VERIFY_TESTER_ID` | **TST** | Only Tester/Manager can edit |
| `GS_BUG_DETAIL-DEV_ID` | **DEV** | Only Dev/Manager can edit |
| `GS_BUG_DETAIL-CREATED_AT` | — | Always display-only (Input = OFF) |
| `GV_STATUS_DISP` | — | Always display-only |
| `GV_PRIORITY_DISP` | — | Always display-only |
| `GV_SEVERITY_DISP` | — | Always display-only |
| `GV_BUG_TYPE_DISP` | — | Always display-only |

**Bước 4: Thêm Group Boxes (optional UX)**

1. Menu: Edit → Create Element → Box
2. Vẽ box quanh nhóm fields → set Text:
   - **"Bug Information"** — quanh BUG_ID, TITLE, PROJECT_ID, STATUS, PRIORITY
   - **"Classification"** — quanh SEVERITY, BUG_TYPE, SAP_MODULE
   - **"Assignment"** — quanh TESTER_ID, DEV_ID, VERIFY_TESTER_ID
   - **"Description"** — quanh CC_DESC_MINI

**Bước 5: Thêm Description Mini Editor (Custom Control)**

1. Edit → Create Element → Custom Control
2. Vẽ hình chữ nhật nhỏ (~60 chars wide x 4 lines high) ở phần dưới screen
3. Name: **`CC_DESC_MINI`**

**Bước 6: Labels**

Rename labels cho rõ ràng:
- `BUG_ID` → "Bug ID"
- `TITLE` → "Title *" (required indicator)
- `PROJECT_ID` → "Project *"
- `STATUS` → "Status"
- etc.

Save + Activate Screen 0310.

**Layout Preview (approximate):**

```
┌─ Bug Information ──────────────────────────────────────────┐
│ Bug ID:        [__________]                                │
│ Title *:       [________________________________________]  │
│ Project *:     [__________________]                        │
│ Status:        [____] → [New         ] (display)           │
│ Priority:      [_]   → [Medium      ] (display)           │
└────────────────────────────────────────────────────────────┘
┌─ Classification ──────────────────────────────────────────┐
│ Severity:      [_]   → [Normal      ] (display)           │
│ Bug Type:      [_]   → [Functional  ] (display)           │
│ SAP Module:    [__________________]                        │
└────────────────────────────────────────────────────────────┘
┌─ Assignment ──────────────────────────────────────────────┐
│ Tester:        [____________]                              │
│ Developer:     [____________]                              │
│ Verify Tester: [____________]                              │
│ Created Date:  [__________] (display-only)                 │
└────────────────────────────────────────────────────────────┘
┌─ Description ─────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────────────────┐  │
│ │ (CC_DESC_MINI — cl_gui_textedit, 3-4 lines)         │  │
│ │                                                      │  │
│ └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
```

---

### C9.2: Screen 0320 — Description (Long Text Z001)

1. Create Screen **0320**, Type = **Subscreen**
2. Flow Logic: empty (PBO/PAI trống)

```abap
PROCESS BEFORE OUTPUT.
PROCESS AFTER INPUT.
```

3. Layout: vẽ Custom Control **`CC_DESC`** chiếm toàn bộ subscreen
4. Save + Activate

> Long Text editor (cl_gui_textedit) được tạo trong PBO khi tab được click. Xem `load_long_text` trong CODE_PAI.md → call khi user chọn TAB_DESC.

---

### C9.3: Screen 0330 — Dev Note (Long Text Z002)

1. Create Screen **0330**, Type = Subscreen
2. Flow Logic: empty
3. Layout: Custom Control **`CC_DEV_NOTE`**
4. Save + Activate

---

### C9.4: Screen 0340 — Tester Note (Long Text Z003)

1. Create Screen **0340**, Type = Subscreen
2. Flow Logic: empty
3. Layout: Custom Control **`CC_TSTR_NOTE`**
4. Save + Activate

---

### C9.5: Screen 0350 — Evidence (GOS)

1. Create Screen **0350**, Type = Subscreen
2. Flow Logic: empty
3. Layout: Custom Control **`CC_EVIDENCE`**
4. Save + Activate

> Phase D: GOS attachment logic sẽ dùng container `CC_EVIDENCE`.

---

### C9.6: Screen 0360 — History (ALV readonly)

1. Create Screen **0360**, Type = Subscreen
2. Flow Logic: empty
3. Layout: Custom Control **`CC_HISTORY`** chiếm toàn bộ subscreen
4. Save + Activate

> History ALV được tạo trong `load_history_data` (CODE_F01.md) khi user click tab History.

---

## C10: Screen 0500 — Project Detail + Table Control

### C10.1: Tạo Screen

1. SE80 → Create Screen → **0500**
2. Short Description: `Project Detail`
3. Screen Type: Normal
4. Next Screen: `0500`

### C10.2: Flow Logic

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0500.
  MODULE init_project_detail.
  MODULE modify_screen_0500.
  LOOP AT gt_user_project INTO gs_user_project WITH CONTROL tc_users.
  ENDLOOP.

PROCESS AFTER INPUT.
  LOOP AT gt_user_project.
    MODULE tc_users_modify ON CHAIN-REQUEST.
  ENDLOOP.
  MODULE user_command_0500.
```

### C10.3: Layout

**Bước 1: Thêm Project fields**

1. Dict/Program Fields → `GS_PROJECT` → Get from Program
2. Chọn: `PROJECT_ID`, `PROJECT_NAME`, `DESCRIPTION`, `PROJECT_STATUS`, `START_DATE`, `END_DATE`, `PROJECT_MANAGER`, `NOTE`
3. Kéo thả sắp xếp thành 2 cột

**Bước 2: Thêm display text cho Project Status**

1. Dict/Program Fields → `GV_PRJ_STATUS_DISP` → Get from Program
2. Đặt cạnh `GS_PROJECT-PROJECT_STATUS` → Input = OFF (display-only)

**Bước 3: Set Screen Groups**

| Field | Group1 |
|-------|--------|
| `GS_PROJECT-PROJECT_ID` | **EDT** |
| `GS_PROJECT-PROJECT_NAME` | **EDT** |
| `GS_PROJECT-DESCRIPTION` | **EDT** |
| `GS_PROJECT-PROJECT_STATUS` | **EDT** |
| `GS_PROJECT-START_DATE` | **EDT** |
| `GS_PROJECT-END_DATE` | **EDT** |
| `GS_PROJECT-PROJECT_MANAGER` | **EDT** |
| `GS_PROJECT-NOTE` | **EDT** |
| `GV_PRJ_STATUS_DISP` | — (display-only) |

**Bước 4: Vẽ Table Control**

1. Edit → Create Element → Table Control
2. Vẽ hình chữ nhật ở phần dưới screen (~50% diện tích)
3. Name: **`TC_USERS`**
4. SAP hỏi columns → thêm columns:

| Column | Field Name | Header Text | Width |
|--------|-----------|-------------|-------|
| 1 | `GS_USER_PROJECT-USER_ID` | User ID | 12 |
| 2 | `GS_USER_PROJECT-ROLE` | Role | 5 |
| 3 | `GS_USER_PROJECT-ERNAM` | Created By | 12 |
| 4 | `GS_USER_PROJECT-ERDAT` | Created On | 10 |

**Cách thêm columns vào Table Control:**

1. Double-click Table Control `TC_USERS` → Attributes mở ra
2. Hoặc: click vào bên trong table control → Dict/Program Fields → `GS_USER_PROJECT` → chọn `USER_ID`, `ROLE`, `ERNAM`, `ERDAT` → kéo vào table control

**Bước 5: Labels**

- Add label "Team Members" phía trên Table Control
- PROJECT_ID → "Project ID *"
- PROJECT_NAME → "Project Name *"

Save + Activate Screen 0500.

**Layout Preview:**

```
┌─ Project Information ─────────────────────────────────────┐
│ Project ID *:  [__________________]                       │
│ Project Name *:[________________________________________] │
│ Description:   [________________________________________] │
│ Status:        [_] → [Opening     ] (display)             │
│ Start Date:    [__________]   End Date: [__________]      │
│ Manager:       [____________]                              │
│ Note:          [________________________________________] │
└───────────────────────────────────────────────────────────┘

Team Members:
┌────────────┬──────┬────────────┬──────────┐
│ User ID    │ Role │ Created By │ Created  │
├────────────┼──────┼────────────┼──────────┤
│ DEV-089    │ M    │ DEV-089    │ 09.04.26 │
│ DEV-061    │ D    │ DEV-089    │ 09.04.26 │
│ DEV-118    │ T    │ DEV-089    │ 09.04.26 │
└────────────┴──────┴────────────┴──────────┘
```

---

## C11: Screen 0100 — Hub (DEPRECATED)

> Screen 0100 **không được sử dụng** trong flow mới. Giữ lại để tránh dump.

### Tạo Screen (nếu chưa tạo):

1. SE80 → Create Screen → **0100**
2. Short Description: `Hub (DEPRECATED)`
3. Screen Type: Normal

### Flow Logic:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.
  MODULE init_user_role.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

### Layout:

- Trống hoặc 1 text "This screen is deprecated. Use Project List instead."
- Không cần buttons — PAI chỉ handle BACK/EXIT/CANC → LEAVE PROGRAM

Save + Activate.

---

## C12: Deprecate Old Programs

Sau khi Module Pool hoạt động, đánh dấu SE38 programs cũ:

1. SE38 → mỗi program cũ → Attributes → Title thêm `[DEPRECATED]`
2. Thêm comment đầu program:

```abap
* ============================================
* [DEPRECATED] — Replaced by Z_BUG_WORKSPACE_MP
* Use T-code ZBUG_HOME instead.
* ============================================
```

| Old Program | Old T-Code | Replaced by |
|-------------|-----------|-------------|
| `Z_BUG_CREATE_SCREEN` | `ZBUG_CREATE` | Screen 0300 (Create mode) |
| `Z_BUG_UPDATE_SCREEN` | `ZBUG_UPDATE` | Screen 0300 (Change mode) |
| `Z_BUG_REPORT_ALV` | `ZBUG_REPORT` | Screen 0200 (Bug List ALV) |
| `Z_BUG_MANAGER_DASHBOARD` | `ZBUG_MANAGER` | Screen 0400 (Project List) |
| `Z_BUG_PRINT` | `ZBUG_PRINT` | Screen 0200 (Print button) |

> **KHÔNG XÓA** programs cũ — chỉ deprecate. Xóa sau Phase E testing.

---

## C13: Testing Checklist

### Flow Tests:

- [ ] `ZBUG_HOME` → mở Screen 0400 (Project List)
- [ ] Click project hotspot → mở Screen 0200 (Bug List, all bugs of project)
- [ ] "My Bugs" button → mở Screen 0200 (filtered by role)
- [ ] Back từ Bug List → Screen 0400
- [ ] Back từ Project List → LEAVE PROGRAM
- [ ] Create Bug (từ project) → Screen 0300 (PROJECT_ID pre-filled + locked)
- [ ] Create Bug button hidden trong My Bugs mode
- [ ] Back từ Bug Detail → Screen 0200

### CRUD Tests:

- [ ] Create Bug → auto-gen BUG_ID → save → status changes to "Change" mode
- [ ] BUG_ID display-only after creation
- [ ] Change Bug → modify fields → Save successful
- [ ] Display Bug → all fields readonly
- [ ] Delete Bug → confirm popup → soft delete → ALV refreshes
- [ ] Create Project (Manager only) → save → success
- [ ] Add User to Project → popup → save → table control updates
- [ ] Remove User from Project → confirm → success

### Display Tests:

- [ ] Status shows text (New/Assigned/...) not raw code (1/2/...)
- [ ] Priority shows text (High/Medium/Low) not raw code (H/M/L)
- [ ] Severity shows text in ALV (Dump/Critical, Very High, ...)
- [ ] Bug Type shows text in ALV (Functional, Performance, ...)
- [ ] Project Status shows text (Opening/In Process/...)
- [ ] Title bar shows mode: "Create Bug" / "Change Bug: BUG0000001"
- [ ] ALV rows color-coded by status

### Role Tests:

- [ ] Tester: cannot create bugs, cannot delete bugs
- [ ] Developer: cannot create bugs, cannot delete bugs, cannot edit Tester fields
- [ ] Manager: full access
- [ ] Tester: cannot see Dev-only fields (DEV group disabled)
- [ ] Non-manager: cannot create/change/delete projects

### Tab Tests:

- [ ] Tab Info → fields + description mini editor visible
- [ ] Tab Description → long text editor (Z001)
- [ ] Tab Dev Note → long text editor (Z002)
- [ ] Tab Tester Note → long text editor (Z003)
- [ ] Tab Evidence → placeholder (Phase D)
- [ ] Tab History → ALV with change log

---

## TROUBLESHOOTING

### "Screen field not found" error

**Nguyên nhân:** Layout reference field tên khác với code (vd `GS_BUG_DETAIL-BUG_ID` vs `GS_BUG-BUG_ID`).
**Fix:** Trong SE51 Layout, double-click field → kiểm tra name khớp chính xác với `GS_BUG_DETAIL-xxx` (global work area).

### "Module xxx not found" error

**Nguyên nhân:** Flow Logic reference module chưa tồn tại trong PBO/PAI include.
**Fix:** Kiểm tra tên module trong Flow Logic khớp với tên trong `Z_BUG_WS_PBO`/`Z_BUG_WS_PAI`. Module Pool không cho phép typo.

### "Class lcl_event_handler unknown" error

**Nguyên nhân:** Include `Z_BUG_WS_F00` nằm SAU `PBO`/`PAI` trong main program.
**Fix:** Đảm bảo thứ tự include: TOP → **F00** → PBO → PAI → F01 → F02.

### ALV không hiện data

**Nguyên nhân:** Custom Container name trên screen khác với code.
**Fix:** Layout có `CC_BUG_LIST` → code có `container_name = 'CC_BUG_LIST'`. Phải khớp chính xác (case-insensitive).

### Tab strip không switch

**Nguyên nhân:** Subscreen Area name không khớp hoặc FCode tab buttons chưa set.
**Fix:** Double-click mỗi tab button → Attributes → Function Code phải = `TAB_INFO`/`TAB_DESC`/etc.

### Save button không hiện

**Nguyên nhân:** Fcode `SAVE` thiếu trong GUI Status `STATUS_0300`.
**Fix:** SE41 → `STATUS_0300` → thêm `SAVE` vào Application Toolbar.

---

## TỔNG KẾT PHASE C (v2.0)

Sau khi hoàn thành:

- [x] Program `Z_BUG_WORKSPACE_MP` + 6 includes (code mới v2.0)
- [x] T-code `ZBUG_HOME` → Screen **0400** (thay vì 0100)
- [x] Screen 0400 — Project List (initial, ALV, My Bugs button)
- [x] Screen 0200 — Bug List (dual mode: Project / My Bugs)
- [x] Screen 0300 — Bug Detail (Tab Strip, 6 subscreens)
- [x] Subscreen 0310 — Bug Info + Description Mini Editor + Group Boxes
- [x] Subscreens 0320-0360 — Long Text / Evidence / History
- [x] Screen 0500 — Project Detail + Table Control (with ROLE column)
- [x] Screen 0100 — Hub (deprecated, kept for safety)
- [x] 5 GUI Statuses with correct fcodes (MY_BUGS, REMO_USR, etc.)
- [x] 5 Title Bars with dynamic `&1` parameter
- [x] Role-based button exclusion (Manager/Tester/Dev)
- [x] Screen groups: EDT, BID, PRJ, TST, DEV
- [x] Display text fields: status/priority/severity/bug_type/project_status
- [x] ALV: severity_text, bug_type_text columns (raw hidden)
- [x] Old programs deprecated

**Next:** Phase D — Excel Upload, GOS Attachments, Message Class Migration
