# UI Guide: Screen 0500 — Project Detail + Table Control

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v4.0 → v4.1 BUGFIX
> **Screen quản lý Project — có Table Control TC_USERS cho user assignment**
>
> v4.0 changes: +POV modules for F4 Calendar popup on START_DATE, END_DATE
> v4.1 BUGFIX changes:
> - PROJECT_ID Group1 changed from EDT → PID (always display-only) (Bug #1/#3)
> - TC_USERS: emphasized "With Column Headers" checkbox (Bug #1/#3)
> - Added POV for PROJECT_STATUS and PROJECT_MANAGER (Bug #1)
> - status_0500: exclude ADD_USER/REMO_USR in Create mode (Bug #1)

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

> ⚠️ **v5.0 ROUND3 CHANGE:** Thêm module `init_prj_editors` + removed `ON CHAIN-REQUEST` from tc_users_modify

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0500.
  MODULE init_project_detail.
  MODULE compute_prj_display_texts.
  MODULE modify_screen_0500.
  MODULE init_prj_editors.
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
| `modify_screen_0500` | PBO | Enable/disable EDT fields theo mode + role. **v5.0 R3:** Also hides old Description/Note I/O fields |
| `init_prj_editors` | PBO | **v5.0 R3 NEW** — Create CL_GUI_TEXTEDIT editors for Description (CC_PRJ_DESC) and Note (CC_PRJ_NOTE) |
| `LOOP AT ... WITH CONTROL tc_users` | PBO | Populate Table Control từ `gt_user_project` |
| `LOOP AT ... MODULE tc_users_modify` | PAI | **v5.0 R3 CHANGED:** Removed `ON CHAIN-REQUEST` — sync every PBO |
| `user_command_0500` | PAI | Handle: SAVE, ADD_USER, REMO_USR, BACK/EXIT. **v5.0 R3:** BACK/EXIT calls `cleanup_prj_editors` |
| `f4_prj_startdate` | PAI (POV) | **v4.0** — F4 Calendar popup cho START_DATE → `PERFORM f4_date USING 'PRJ_START_DATE'` |
| `f4_prj_enddate` | PAI (POV) | **v4.0** — F4 Calendar popup cho END_DATE → `PERFORM f4_date USING 'PRJ_END_DATE'` |
| `f4_prj_status` | PAI (POV) | **v4.1 NEW** — F4 Dropdown cho PROJECT_STATUS → `PERFORM f4_project_status` |
| `f4_prj_manager` | PAI (POV) | **v4.1 NEW** — F4 User list cho PROJECT_MANAGER → `PERFORM f4_user_id` |

### Table Control Flow Logic — Giải thích:

**PBO LOOP:** SAP dùng PBO LOOP để fill Table Control rows từ internal table. `WITH CONTROL tc_users` liên kết LOOP với Table Control UI element.

**PAI LOOP:** `ON CHAIN-REQUEST` nghĩa là module `tc_users_modify` chỉ chạy khi user thực sự thay đổi 1 field trong row đó (performance optimization).

---

## 3. Custom Controls (v5.0 Round 3 — NEW)

Description và Note fields đã được thay bằng CL_GUI_TEXTEDIT multi-line editors.
Cần tạo 2 Custom Controls trên Screen Layout:

### Bước tạo Custom Controls trong SE51:

1. **SE80** → mở `Z_BUG_WORKSPACE_MP` → double-click Screen **0500** → tab **Layout**
2. Menu → Edit → Create Element → **Custom Control** (hoặc icon Custom Control trên toolbar)
3. Vẽ hình chữ nhật ở vị trí cũ của Description field → Name: **`CC_PRJ_DESC`**
   - Kích thước gợi ý: rộng ~60 chars, cao ~3-4 dòng
4. Vẽ thêm 1 Custom Control ở vị trí cũ của Note field → Name: **`CC_PRJ_NOTE`**
   - Kích thước gợi ý: rộng ~60 chars, cao ~3-4 dòng
5. **Hide old I/O fields**: Các I/O fields `GS_PROJECT-DESCRIPTION` và `GS_PROJECT-NOTE` vẫn giữ trên screen (code `modify_screen_0500` sẽ set `screen-active = 0` tự động) — nhưng nên di chuyển chúng ra ngoài visible area hoặc đặt chúng chồng dưới Custom Control
6. **Save** + **Activate**

> ⚠️ **CRITICAL**: Tên Custom Control phải CHÍNH XÁC là `CC_PRJ_DESC` và `CC_PRJ_NOTE` (viết hoa, khớp với code PBO `init_prj_editors`)
>
> Nếu tên sai → `CX_ROOT` exception → warning message "Cannot create Project Description/Note editor"

### Bước cho Mac (SAP GUI for Java — alphanumeric mode):

Vì Screen Painter chạy alphanumeric trên Mac, **không kéo thả được**. Làm như sau:

1. Mở Screen 0500 Flow Logic → Tab **Element List**
2. Thêm 2 entries thủ công:

| Type | Name | Text | Row | Col | Width | Height |
|------|------|------|-----|-----|-------|--------|
| Custom Control | `CC_PRJ_DESC` | Description | 6 | 20 | 60 | 4 |
| Custom Control | `CC_PRJ_NOTE` | Note | 11 | 20 | 60 | 4 |

> Row/Col tuỳ chỉnh sao cho phù hợp layout. Quan trọng là Name phải đúng.

---

## 4. Layout

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
│  │ Project Name *:[__________________________________________│  │
│  │ Description:   ┌─ CC_PRJ_DESC ───────────────────────┐    │  │
│  │                │ (CL_GUI_TEXTEDIT multi-line editor)  │    │  │
│  │                │                                      │    │  │
│  │                └──────────────────────────────────────┘    │  │
│  │ Status:        [_] → [Opening     ] (display)             │  │
│  │ Start Date:    [__________]   End Date: [__________]      │  │
│  │ Manager:       [____________]                              │  │
│  │ Note:          ┌─ CC_PRJ_NOTE ───────────────────────┐    │  │
│  │                │ (CL_GUI_TEXTEDIT multi-line editor)  │    │  │
│  │                │                                      │    │  │
│  │                └──────────────────────────────────────┘    │  │
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

---

## 5. Save + Activate

1. **Save** layout (Ctrl+S)
2. **Activate** screen (Ctrl+F3)

---

## 6. Verify

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
| Custom Control | CC | `CC_PRJ_DESC` |
| Custom Control | CC | `CC_PRJ_NOTE` |
| Table Control | TC | `TC_USERS` |
| OK Code | OK | `GV_OK_CODE` |

### Quick Test:
1. Từ Screen 0400, chọn 1 project → click "Change" → phải mở Screen 0500
2. Fields phải hiện data từ DB
3. Table Control phải hiện team members
4. Non-Manager: fields readonly + Save/Add/Remove hidden
5. BACK → quay về Screen 0400

---

## 7. GUI Status Reference

Screen này dùng **STATUS_0500**. Xem `UI_FINAL_STEPS.md` để tạo.

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

## 8. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| Table Control trống | Internal table trống hoặc LOOP sai | Check flow logic có `LOOP AT gt_user_project INTO gs_user_project WITH CONTROL tc_users` |
| Fields không disable | Group1 chưa set | Set Group1 = `EDT` cho tất cả editable fields |
| "Module tc_users_modify not found" | Code chưa activate | Re-activate Z_BUG_WS_PAI |
| Save không work | SAVE fcode thiếu trong STATUS_0500 | Check SE41 |
| Add User popup không hiện | POPUP_GET_VALUES error | Check code save_project_detail |
| BACK không quay về 0400 | OK Code thiếu | Add GV_OK_CODE to screen attributes |
| Status display trống | Module compute_prj_display_texts missing | Verify flow logic có module này (v3.0) |
| Project data reload khi tab switch | (n/a — Screen 0500 không có tabs) | gv_prj_detail_loaded flag prevents reload |
| Description/Note editor trống | Custom Control name sai | Check CC_PRJ_DESC / CC_PRJ_NOTE tên chính xác trong SE51 Layout |
| "Cannot create Project Description editor" | Custom Control chưa tạo trên Screen Layout | Tạo Custom Control CC_PRJ_DESC trong SE51 → Layout |
| Text bị cắt khi save | CHAR 255 limit từ DB | Expected — Description/Note max 255 chars. Editor chỉ cải thiện UX, không thay đổi DB limit |
