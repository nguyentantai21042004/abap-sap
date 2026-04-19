# UI Guide: Screen 0500 — Project Detail + Table Control

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0 (Bug C Fix)
> **Screen quản lý Project — có Table Control TC_USERS cho user assignment**
>
> v4.0 changes: +POV modules for F4 Calendar popup on START_DATE, END_DATE
> v4.1 BUGFIX changes:
> - PROJECT_ID Group1 changed from EDT → PID (always display-only) (Bug #1/#3)
> - TC_USERS: emphasized "With Column Headers" checkbox (Bug #1/#3)
> - Added POV for PROJECT_STATUS and PROJECT_MANAGER (Bug #1)
> - status_0500: exclude ADD_USER/REMO_USR in Create mode (Bug #1)
>
> v5.0 Bug C Fix:
> - Removed `init_prj_editors` module entirely (CL_GUI_TEXTEDIT caused blank Description/Note)
> - Description and Note use plain I/O fields (GS_PROJECT-DESCRIPTION, GS_PROJECT-NOTE)
> - `modify_screen_0500` no longer hides Description/Note I/O fields
> - No Custom Controls needed on this screen for Description/Note

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0500`**
   - Short Description: `Project Detail`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0500`**
5. **Save**

---

## 2. Flow Logic

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0500.
  MODULE init_project_detail.
  MODULE compute_prj_display_texts.
  MODULE modify_screen_0500.
  LOOP AT gt_user_project INTO gs_user_project WITH CONTROL tc_users.
  ENDLOOP.

PROCESS AFTER INPUT.
  LOOP AT gt_user_project.
    MODULE tc_users_modify.
  ENDLOOP.
  MODULE user_command_0500.

PROCESS ON VALUE-REQUEST.
  FIELD gs_project-start_date      MODULE f4_prj_startdate.
  FIELD gs_project-end_date        MODULE f4_prj_enddate.
  FIELD gs_project-project_status  MODULE f4_prj_status.
  FIELD gs_project-project_manager MODULE f4_prj_manager.
```

> **v4.0 — PROCESS ON VALUE-REQUEST (POV):**
> POV block enables F4 help for date fields (calendar popup) and project fields (value list).
>
> | Field | Module | FORM called | Description |
> |-------|--------|-------------|-------------|
> | START_DATE | `f4_prj_startdate` | `f4_date USING 'PRJ_START_DATE'` | Calendar popup |
> | END_DATE | `f4_prj_enddate` | `f4_date USING 'PRJ_END_DATE'` | Calendar popup |
> | PROJECT_STATUS | `f4_prj_status` | `f4_project_status` | **v4.1 NEW** — Dropdown: Opening/In Process/Done/Cancelled |
> | PROJECT_MANAGER | `f4_prj_manager` | `f4_user_id` | **v4.1 NEW** — User list from ZBUG_USERS |
>
> Modules defined in `CODE_PAI.md`. FORMs in `CODE_F02.md`.

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0500` | PBO | SET PF-STATUS (exclude buttons cho non-Manager + Display), SET TITLEBAR |
| `init_project_detail` | PBO | Load project data từ DB (1 lần — `gv_prj_detail_loaded` flag) |
| `compute_prj_display_texts` | PBO | Map project_status code → display text |
| `modify_screen_0500` | PBO | Enable/disable EDT fields theo mode + role |
| `LOOP AT ... WITH CONTROL tc_users` | PBO | Populate Table Control từ `gt_user_project` |
| `LOOP AT ... MODULE tc_users_modify` | PAI | Sync Table Control changes back to `gt_user_project` |
| `user_command_0500` | PAI | Handle: SAVE, ADD_USER, REMO_USR, BACK/EXIT |
| `f4_prj_startdate` | PAI (POV) | **v4.0** — F4 Calendar popup cho START_DATE → `PERFORM f4_date USING 'PRJ_START_DATE'` |
| `f4_prj_enddate` | PAI (POV) | **v4.0** — F4 Calendar popup cho END_DATE → `PERFORM f4_date USING 'PRJ_END_DATE'` |
| `f4_prj_status` | PAI (POV) | **v4.1 NEW** — F4 Dropdown cho PROJECT_STATUS → `PERFORM f4_project_status` |
| `f4_prj_manager` | PAI (POV) | **v4.1 NEW** — F4 User list cho PROJECT_MANAGER → `PERFORM f4_user_id` |

### Table Control Flow Logic — Giải thích:

**PBO LOOP:** SAP dùng PBO LOOP để fill Table Control rows từ internal table. `WITH CONTROL tc_users` liên kết LOOP với Table Control UI element.

**PAI LOOP:** Module `tc_users_modify` sync changes từ Table Control UI về internal table `gt_user_project`.

---

## 3. Layout

Click **Layout** → Screen Painter mở ra.

### Bước 1: Thêm Project fields

1. Click **Dict/Program Fields** (icon quyển sách)
2. Variable: `GS_PROJECT` → click **Get from Program**
3. Tick chọn các fields:

| # | Field Name | Label | Type (SE11) |
|---|-----------|-------|-------------|
| 1 | `GS_PROJECT-PROJECT_ID` | Project ID | CHAR 20 |
| 2 | `GS_PROJECT-PROJECT_NAME` | Project Name | CHAR 100 |
| 3 | `GS_PROJECT-DESCRIPTION` | Description | CHAR 255 |
| 4 | `GS_PROJECT-PROJECT_STATUS` | Status | CHAR 1 |
| 5 | `GS_PROJECT-START_DATE` | Start Date | DATS 8 |
| 6 | `GS_PROJECT-END_DATE` | End Date | DATS 8 |
| 7 | `GS_PROJECT-PROJECT_MANAGER` | Manager | CHAR 12 |
| 8 | `GS_PROJECT-NOTE` | Note | CHAR 255 |

4. Click **Enter** → kéo thả sắp xếp

### Bước 2: Thêm Display Text cho Project Status

1. Dict/Program Fields → Variable: `GV_PRJ_STATUS_DISP` → **Get from Program**
2. Đặt cạnh `GS_PROJECT-PROJECT_STATUS`
3. **Set Input = OFF** (display-only)

### Bước 3: Set Screen Groups (Group1)

| Field | Group1 | Purpose |
|-------|--------|---------|
| `GS_PROJECT-PROJECT_ID` | **`PID`** | **v4.1 CHANGED:** ALWAYS display-only (primary key, auto-generated) |
| `GS_PROJECT-PROJECT_NAME` | **`EDT`** | Disabled khi Display mode hoặc non-Manager |
| `GS_PROJECT-DESCRIPTION` | **`EDT`** | Same |
| `GS_PROJECT-PROJECT_STATUS` | **`EDT`** | Same |
| `GS_PROJECT-START_DATE` | **`EDT`** | Same |
| `GS_PROJECT-END_DATE` | **`EDT`** | Same |
| `GS_PROJECT-PROJECT_MANAGER` | **`EDT`** | Same |
| `GS_PROJECT-NOTE` | **`EDT`** | Same |
| `GV_PRJ_STATUS_DISP` | *(none)* | Always display-only (Input = OFF) |

> **v4.1 BUGFIX #1/#3:** PROJECT_ID changed from Group `EDT` to Group **`PID`**.
> Code `modify_screen_0500` (CODE_PBO.md) handles PID group: ALWAYS `screen-input = 0`.
> This prevents users from editing the primary key in any mode.
> In Create mode, field shows "(Auto)" placeholder. After save, shows real PRJ0000001 ID.

### Bước 4: Vẽ Table Control

1. Menu → Edit → Create Element → **Table Control**
   (hoặc click icon Table Control trên toolbar)
2. Vẽ hình chữ nhật ở **phần dưới screen** (~50% diện tích)
3. Name: **`TC_USERS`**
   - ⚠️ Khớp với `CONTROLS: tc_users TYPE TABLEVIEW USING SCREEN 0500` (CODE_TOP.md line 140)

### Bước 5: Thêm Columns vào Table Control

**Cách 1 (recommended):** Click vào bên trong Table Control → Dict/Program Fields → `GS_USER_PROJECT` → **Get from Program** → tick chọn fields → kéo vào table control.

**Cách 2 (manual):** Double-click Table Control → Attributes → Columns tab → thêm từng column.

| Column # | Field Name | Header Text | Approx Width |
|----------|-----------|-------------|-------------|
| 1 | `GS_USER_PROJECT-USER_ID` | User ID | 12 |
| 2 | `GS_USER_PROJECT-ROLE` | Role | 5 |
| 3 | `GS_USER_PROJECT-ERNAM` | Created By | 12 |
| 4 | `GS_USER_PROJECT-ERDAT` | Created On | 10 |

> Columns hiển thị data từ `ZBUG_USER_PROJEC` (M:N relationship table).

### Bước 6: Table Control Attributes

Double-click `TC_USERS` → check:
- **With Column Headers**: ✅ **PHẢI check** — nếu thiếu, TC_USERS sẽ hiện data mà KHÔNG có tiêu đề cột (Bug #1/#3)
- **Resizable Columns**: ✅ checked
- **Selection Column**: Optional (nếu muốn row selection)

> ⚠️ **v4.1 BUGFIX #1/#3:** Đây là nguyên nhân chính khiến TC_USERS hiện "cái ô nhỏ trống" mà user thắc mắc. Checkbox "With Column Headers" phải được check trong SE51 Layout → Attributes của TC_USERS.

### Bước 7: Thêm Labels

- Phía trên Table Control, thêm **Text field** (display-only): `Team Members`
- Sửa labels cho rõ:
  - PROJECT_ID → `Project ID *`
  - PROJECT_NAME → `Project Name *`
  - DESCRIPTION → `Description`
  - PROJECT_STATUS → `Status`
  - START_DATE → `Start Date`
  - END_DATE → `End Date`
  - PROJECT_MANAGER → `Manager`
  - NOTE → `Note`

### Bước 8: Group Boxes (optional)

1. Vẽ Box quanh project fields → text: `Project Information`
2. Vẽ Box quanh Table Control → text: `Team Members`

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Save | Add User | Remove User | Back | Exit]         │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─ Project Information ─────────────────────────────────────┐  │
│  │ Project ID *:  [____________________]                     │  │
│  │ Project Name *:[__________________________________________]│  │
│  │ Description:   [__________________________________________]│  │
│  │ Status:        [_] → [Opening     ] (display)             │  │
│  │ Start Date:    [__________]   End Date: [__________]      │  │
│  │ Manager:       [____________]                              │  │
│  │ Note:          [__________________________________________]│  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  Team Members:                                                  │
│  ┌─── TC_USERS ──────────────────────────────────────────────┐  │
│  │ User ID      │ Role │ Created By │ Created On │           │  │
│  ├──────────────┼──────┼────────────┼────────────┤           │  │
│  │ DEV-089      │ M    │ DEV-089    │ 09.04.2026 │           │  │
│  │ DEV-061      │ D    │ DEV-089    │ 09.04.2026 │           │  │
│  │ DEV-118      │ T    │ DEV-089    │ 09.04.2026 │           │  │
│  │              │      │            │            │           │  │
│  └──────────────┴──────┴────────────┴────────────┘           │  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

> **v5.0 Bug C Fix:** Description và Note là plain I/O fields (CHAR 255).
> Không cần Custom Controls hay CL_GUI_TEXTEDIT editors cho 2 fields này.

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:

SE80 → double-click Screen 0500 → tab **Element List** → phải thấy:

| Element | Type | Name |
|---------|------|------|
| Input/Output | I/O | `GS_PROJECT-PROJECT_ID` |
| Input/Output | I/O | `GS_PROJECT-PROJECT_NAME` |
| Input/Output | I/O | `GS_PROJECT-DESCRIPTION` |
| Input/Output | I/O | `GS_PROJECT-PROJECT_STATUS` |
| Input/Output | I/O | `GS_PROJECT-START_DATE` |
| Input/Output | I/O | `GS_PROJECT-END_DATE` |
| Input/Output | I/O | `GS_PROJECT-PROJECT_MANAGER` |
| Input/Output | I/O | `GS_PROJECT-NOTE` |
| Input/Output | I/O | `GV_PRJ_STATUS_DISP` |
| Table Control | TC | `TC_USERS` |
| OK Code | OK | `GV_OK_CODE` |

> ⚠️ **Bug C Fix:** `CC_PRJ_DESC` và `CC_PRJ_NOTE` Custom Controls KHÔNG được có trong Element List.
> Nếu tồn tại → xóa đi, chúng không còn cần thiết và sẽ gây lỗi vì code không tạo editors nữa.

### Quick Test:
1. Từ Screen 0400, chọn 1 project → click "Change" → phải mở Screen 0500
2. Fields phải hiện data từ DB (kể cả Description và Note)
3. Table Control phải hiện team members
4. Non-Manager: fields readonly + Save/Add/Remove hidden
5. BACK → quay về Screen 0400

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0500**. Xem `docs/final-steps.md` để tạo.

### Buttons trên STATUS_0500:

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Hidden: Display mode + non-Manager |
| 2 | *(separator)* | | | |
| 3 | `ADD_USER` | Add User | `ICON_INSERT_ROW` | Hidden: Display mode + non-Manager |
| 4 | `REMO_USR` | Remove User | `ICON_DELETE_ROW` | Hidden: Display mode + non-Manager |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

### Title Bar:

Screen này dùng **TITLE_PRJDET** — text = `&1` (nhận "Create Project" / "Change Project: {name}" / "Display Project: {name}").

---

## 7. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| Table Control trống | Internal table trống hoặc LOOP sai | Check flow logic có `LOOP AT gt_user_project INTO gs_user_project WITH CONTROL tc_users` |
| Fields không disable | Group1 chưa set | Set Group1 = `EDT` cho tất cả editable fields |
| "Module tc_users_modify not found" | Code chưa activate | Re-activate Z_BUG_WS_PAI |
| Save không work | SAVE fcode thiếu trong STATUS_0500 | Check SE41 |
| Add User popup không hiện | POPUP_GET_VALUES error | Check code save_project_detail |
| BACK không quay về 0400 | OK Code thiếu | Add GV_OK_CODE to screen attributes |
| Status display trống | Module compute_prj_display_texts missing | Verify flow logic có module này |
| Project data reload khi tab switch | (n/a — Screen 0500 không có tabs) | gv_prj_detail_loaded flag prevents reload |
| Description/Note trống | Group1 chưa set hoặc modify_screen_0500 set input=0 | Kiểm tra Group1 = EDT; kiểm tra gv_mode và gv_role |
| Description/Note không save | Fields không trong ABAP work area khi PAI chạy | Đảm bảo fields có trên screen và Group1 đúng |
