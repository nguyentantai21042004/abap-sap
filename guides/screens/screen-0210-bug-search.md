# UI Guide: Screen 0210 — Bug Search Input (Modal Dialog Popup)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **Popup tìm kiếm bug nâng cao — mở từ nút SEARCH trên Screen 0200**
>
> **Screen Type:** Modal Dialog Box (popup)
> **Không có Custom Control** — chỉ có input fields cho search criteria

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0210`**
   - Short Description: `Bug Search Input`
4. Tab **Attributes**:
   - Screen Type: **Modal Dialog Box** ← QUAN TRỌNG — popup
   - Next Screen: **`0210`** (loop)
5. **Save**

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0210.

PROCESS AFTER INPUT.
  MODULE user_command_0210.

PROCESS ON VALUE-REQUEST.
  FIELD s_status   MODULE f4_bug_search_status.
  FIELD s_prio     MODULE f4_bug_search_priority.
  FIELD s_mod      MODULE f4_bug_search_module.
  FIELD s_reporter MODULE f4_bug_search_reporter.
  FIELD s_dev      MODULE f4_bug_search_developer.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0210` | PBO | SET PF-STATUS 'STATUS_0210', SET TITLEBAR 'T_0210' |
| `user_command_0210` | PAI | Handle: EXECUTE (search → close popup → open 0220), CANCEL (close popup) |
| `f4_bug_search_status` | PAI (POV) | F4 help cho Status — list 10 bug statuses (v5.0) |
| `f4_bug_search_priority` | PAI (POV) | F4 help cho Priority — list H/M/L |
| `f4_bug_search_module` | PAI (POV) | F4 help cho SAP Module — list FI/MM/SD/ABAP/BASIS/etc. |
| `f4_bug_search_reporter` | PAI (POV) | F4 help cho Reporter — list all users |
| `f4_bug_search_developer` | PAI (POV) | F4 help cho Developer — list users WHERE role='D' |

> **GHI CHÚ:** `S_BUG_ID` và `S_TITLE` KHÔNG cần F4 help — user tự gõ. `S_TITLE` hỗ trợ wildcard search (dùng `*` hoặc `%`).

---

## 3. Layout (Screen Painter)

Click nút **Layout** → Screen Painter mở ra.

### Bước 1: Thêm search fields từ program variables

1. **Dict/Program Fields** → nhập biến → **Get from Program**
2. Lần lượt thêm 7 fields:

| # | Variable Name | Type | Label gợi ý | F4 Help |
|---|--------------|------|-------------|---------|
| 1 | `S_BUG_ID` | `ZDE_BUG_ID` (CHAR 10) | `Bug ID` | Không |
| 2 | `S_TITLE` | `CHAR40` | `Title (keyword)` | Không — wildcard `*keyword*` |
| 3 | `S_STATUS` | `ZDE_BUG_STATUS` (CHAR 20) | `Status` | F4 → 10 bug statuses |
| 4 | `S_PRIO` | `CHAR10` | `Priority` | F4 → H/M/L |
| 5 | `S_MOD` | `ZDE_SAP_MODULE` (CHAR 20) | `SAP Module` | F4 → FI/MM/SD/ABAP/BASIS/... |
| 6 | `S_REPORTER` | `CHAR12` | `Reporter` | F4 → all users |
| 7 | `S_DEV` | `CHAR12` | `Developer` | F4 → users where role='D' |

### Bước 2: Đổi Label Text (optional — cho đẹp)

Double-click label → sửa text:
- `S_BUG_ID` → `Bug ID`
- `S_TITLE` → `Title *` (dấu * = wildcard support)
- `S_STATUS` → `Status`
- `S_PRIO` → `Priority`
- `S_MOD` → `SAP Module`
- `S_REPORTER` → `Reporter`
- `S_DEV` → `Developer`

### Bước 3: Thêm Group Box (optional)

1. Menu → Edit → Create Element → **Box**
2. Vẽ box quanh 7 fields
3. Text: `Search Criteria`

### Bước 4: Thêm hint text (optional)

1. Text element: `* Leave fields blank to match all. Title supports wildcard (*).`
2. Đặt phía dưới các search fields

### Layout Preview:

```
┌──── Bug Search ─────────────────────────────────────────────┐
│                                                              │
│  ┌─ Search Criteria ───────────────────────────────────────┐ │
│  │                                                         │ │
│  │  Bug ID:        [__________]                            │ │
│  │                                                         │ │
│  │  Title *:       [________________________________________│ │
│  │                                                         │ │
│  │  Status:        [____________________] (F4)             │ │
│  │                                                         │ │
│  │  Priority:      [__________] (F4)                       │ │
│  │                                                         │ │
│  │  SAP Module:    [____________________] (F4)             │ │
│  │                                                         │ │
│  │  Reporter:      [____________] (F4)                     │ │
│  │                                                         │ │
│  │  Developer:     [____________] (F4)                     │ │
│  │                                                         │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                              │
│  * Leave fields blank to match all. Title supports wildcard. │
│                                                              │
│  [Execute (F8)]  [Cancel]                                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

> **Kích thước popup:** Code gọi `CALL SCREEN 0210 STARTING AT 5 3 ENDING AT 75 18` — khoảng 70 columns x 15 rows. Adjust nếu cần.

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0210 → tab **Element List** → phải thấy:

| Element | Type | Name |
|---------|------|------|
| Input/Output | — | `S_BUG_ID` |
| Input/Output | — | `S_TITLE` |
| Input/Output | — | `S_STATUS` |
| Input/Output | — | `S_PRIO` |
| Input/Output | — | `S_MOD` |
| Input/Output | — | `S_REPORTER` |
| Input/Output | — | `S_DEV` |
| OK Code | OK | `GV_OK_CODE` |

### Quick Test:
1. Từ Screen 0200 (Bug List) → nhấn nút SEARCH
2. Popup 0210 phải mở ra
3. Nhấn F4 trên Status → hiện 10 statuses (v5.0)
4. Nhấn F4 trên Priority → hiện H/M/L
5. Nhấn F4 trên SAP Module → hiện FI/MM/SD/ABAP/BASIS/...
6. Để trống tất cả → Execute → popup đóng + Screen 0220 mở với tất cả bugs
7. Nhập Bug ID cụ thể → Execute → Screen 0220 chỉ hiện bug đó
8. Cancel → popup đóng, quay về Screen 0200

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0210** (v5.0 NEW). Xem `final-steps.md` để tạo.

### Buttons trên STATUS_0210:

| # | FCode | Text | Icon | Assign to Key |
|---|-------|------|------|---------------|
| 1 | `EXECUTE` | Execute | `ICON_EXECUTE_OBJECT` | **F8** |
| 2 | `CANCEL` | Cancel | `ICON_CANCEL` | **F12** |

> **Modal Dialog:** Popup không cần BACK/EXIT — chỉ cần EXECUTE + CANCEL.

### Title Bar:

Screen này dùng **T_0210** — text = `Bug Search`

---

## 7. PAI Flow — Khi user nhấn Execute

```
User nhấn Execute (F8)
  │
  ├── PAI: user_command_0210
  │     ├── PERFORM execute_bug_search    ← Populate gt_search_results
  │     ├── LEAVE TO SCREEN 0            ← Close popup
  │     └── CALL SCREEN 0220             ← Open full screen results
  │
  └── Screen 0220 PBO: init_search_results
        └── Dùng gt_search_results ← ALV hiện search results
```

### Search Logic (trong `execute_bug_search`, CODE_F01):

```
1. SELECT FROM zbug_tracker WHERE:
   - is_del <> 'X'
   - project_id = gv_current_project_id (scope to current project)
   - AND từng field: ( @s_xxx IS INITIAL OR field = @s_xxx )

2. Title wildcard: Vì TITLE là CHAR 100 nhưng s_title là CHAR 40,
   dùng CP (Contains Pattern) post-filter:
   DELETE gt_search_results WHERE NOT title CP s_title.

3. Nếu không tìm thấy → message 'No bugs found matching criteria.'
   Nếu tìm thấy → message 'Found X bug(s).'
```

> **Security:** Search chỉ scope trong `gv_current_project_id` (project đang xem) — user không thể search bugs thuộc project khác.

---

## 8. Cách gọi Popup từ Screen 0200

Trong `user_command_0200` (CODE_PAI):

```abap
WHEN 'SEARCH'.
  " Clear previous search criteria
  CLEAR: s_bug_id, s_title, s_status, s_prio, s_mod, s_reporter, s_dev.
  CALL SCREEN 0210 STARTING AT 5 3 ENDING AT 75 18.
```

> **CLEAR trước khi gọi** — đảm bảo form search sạch, không giữ lại criteria cũ.

---

## 9. F4 Help — Danh sách 10 Bug Statuses (v5.0)

F4 cho `S_STATUS` phải hiện đầy đủ 10 statuses v5.0:

| Code | Text |
|------|------|
| `1` | New |
| `W` | Waiting |
| `2` | Assigned |
| `3` | In Progress |
| `4` | Pending |
| `5` | Fixed |
| `R` | Rejected |
| `6` | Final Testing |
| `V` | Resolved |
| `7` | Closed |

> **BREAKING CHANGE:** `6` = Final Testing (KHÔNG phải Resolved như v4.x). `V` = Resolved (MỚI).

---

## 10. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| Nút SEARCH không hiện trên Screen 0200 | FCode SEARCH chưa thêm vào STATUS_0200 | SE41 → STATUS_0200 → thêm button SEARCH |
| F4 không hiện trên S_STATUS | POV block thiếu hoặc module name sai | Verify `FIELD s_status MODULE f4_bug_search_status.` trong flow logic |
| Execute không mở Screen 0220 | Logic sai — phải LEAVE TO SCREEN 0 trước CALL SCREEN 0220 | Verify PAI code sequence: LEAVE TO SCREEN 0 → CALL SCREEN 0220 |
| Tìm không ra bug (kết quả trống) | Wildcard logic sai hoặc scope project sai | Verify `gv_current_project_id` đúng + wildcard CP logic |
| "Variable S_BUG_ID not found" | Biến chưa khai báo trong TOP include | Verify `DATA: s_bug_id TYPE zde_bug_id.` trong CODE_TOP v5.0 |
| Search kết quả lẫn bugs từ project khác | Thiếu WHERE project_id filter | Verify `AND project_id = @gv_current_project_id` trong SELECT |
