# UI Guide: Screen 0410 — Project Search (NEW INITIAL SCREEN)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **Screen đầu tiên user thấy khi gõ ZBUG_WS** — thay thế Screen 0400 làm initial screen.
> Cho phép user lọc project trước khi vào danh sách.

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0410`**
   - Short Description: `Project Search`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0410`** (loop — navigation handled bởi PAI code)
5. **Save**

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_user_role.
  MODULE status_0410.

PROCESS AFTER INPUT.
  MODULE user_command_0410.

PROCESS ON VALUE-REQUEST.
  FIELD s_prj_id   MODULE f4_project_id.
  FIELD s_prj_mn   MODULE f4_manager.
  FIELD s_prj_st   MODULE f4_project_status.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `init_user_role` | PBO | Load role từ ZBUG_USERS 1 lần (CHECK gv_role IS INITIAL). **PHẢI đứng đầu PBO** |
| `status_0410` | PBO | SET PF-STATUS 'STATUS_0410', SET TITLEBAR 'T_0410' |
| `user_command_0410` | PAI | Handle: EXECUTE (search + CALL SCREEN 0400), BACK/EXIT/CANCEL (LEAVE PROGRAM) |
| `f4_project_id` | PAI (POV) | F4 help cho Project ID — list từ ZBUG_PROJECT |
| `f4_manager` | PAI (POV) | F4 help cho Manager — list từ ZBUG_USERS WHERE ROLE='M' |
| `f4_project_status` | PAI (POV) | F4 help cho Project Status — list: 1=Opening, 2=In Process, 3=Done, 4=Cancelled |

> **QUAN TRỌNG (BUG FIX):** `init_user_role` PHẢI nằm trong PBO của Screen 0410 vì đây là initial screen. Nếu thiếu, `gv_role` = INITIAL khi user nhấn Execute → `search_projects` chạy với role sai (non-Manager path) → sau đó Screen 0400 PBO set đúng role → lần BACK từ 0200 `search_projects` chạy lại với role đúng → user thấy thêm project không mong đợi (Bug #1).

---

## 3. Layout (Screen Painter)

Click nút **Layout** (hoặc Ctrl+F7) → Screen Painter mở ra.

### Bước 1: Thêm search fields từ program variables

1. Trong Layout Editor → click **Dict/Program Fields** (icon hình quyển sách trên toolbar)
2. Table/Field Name: `S_PRJ_ID` → click **Get from Program**
3. SAP tạo label + input field. Kéo thả vào vị trí mong muốn.
4. Lặp lại cho:

| # | Variable Name | Type (từ TOP) | Label gợi ý | Ghi chú |
|---|--------------|---------------|-------------|---------|
| 1 | `S_PRJ_ID` | `ZDE_PROJECT_ID` (CHAR 20) | `Project ID` | F4 help → list projects |
| 2 | `S_PRJ_MN` | `UNAME` (CHAR 12) | `Manager` | F4 help → list managers |
| 3 | `S_PRJ_ST` | `CHAR1` (CHAR 1) | `Status` | F4 help → 4 project statuses |

> **Cách nhập biến:** Gõ tên biến global (vd `S_PRJ_ID`) vào ô "Table/Field Name", nhấn **Get from Program**. SAP sẽ tìm biến trong TOP include.

### Bước 2: Đổi Label Text (optional — cho đẹp)

Double-click label → sửa text:
- `S_PRJ_ID` → `Project ID`
- `S_PRJ_MN` → `Manager`
- `S_PRJ_ST` → `Status`

### Bước 3: Thêm Display Text cho Status (optional)

Nếu muốn hiện text bên cạnh status code:
1. Thêm text element (Menu → Edit → Create Element → **Text Field**)
2. Gõ text: `(1=Opening, 2=In Process, 3=Done, 4=Cancelled)` → đặt cạnh S_PRJ_ST

### Bước 4: Thêm Group Box (optional — cho đẹp)

1. Menu → Edit → Create Element → **Box**
2. Vẽ box quanh 3 search fields
3. Text: `Search Criteria`

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Execute (F8) | Back | Exit | Cancel]                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─ Search Criteria ───────────────────────────────────────────┐│
│  │                                                             ││
│  │  Project ID:   [____________________]  (F4)                 ││
│  │                                                             ││
│  │  Manager:      [____________]  (F4)                         ││
│  │                                                             ││
│  │  Status:       [_]  (F4)  (1=Opening, 2=InProcess, ...)    ││
│  │                                                             ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│   Nhấn F8 hoặc nút Execute để tìm kiếm.                        │
│   Để trống = hiển thị tất cả projects user có quyền xem.       │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

> **GHI CHÚ:** Screen này KHÔNG có Custom Control — không có ALV. Kết quả search hiển thị trên Screen 0400 (Project List) khi user nhấn Execute.

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0410 → tab **Element List** → phải thấy:

| Element | Type | Name |
|---------|------|------|
| Input/Output | — | `S_PRJ_ID` |
| Input/Output | — | `S_PRJ_MN` |
| Input/Output | — | `S_PRJ_ST` |
| OK Code | OK | `GV_OK_CODE` |

> OK Code field: Nếu chưa có, vào tab **Attributes** → Element List → thêm OK Code field name = `GV_OK_CODE`.

### Quick Test:
1. **SE93** → ZBUG_WS → đổi initial screen thành **`0410`** (xem Step 5 trong `final-steps.md`)
2. Chạy ZBUG_WS → phải thấy Screen 0410 (search form)
3. Nhấn F4 trên Project ID → popup hiện list projects
4. Nhấn F4 trên Manager → popup hiện list managers (role = M)
5. Nhấn F4 trên Status → popup hiện 4 statuses
6. Để trống tất cả → nhấn Execute (F8) → phải mở Screen 0400 với tất cả projects
7. Nhập Project ID cụ thể → Execute → Screen 0400 chỉ hiện project đó
8. BACK → LEAVE PROGRAM (thoát chương trình)

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0410** (v5.0 NEW). Xem `final-steps.md` để tạo.

### Buttons trên STATUS_0410:

| # | FCode | Text | Icon | Assign to Key |
|---|-------|------|------|---------------|
| 1 | `EXECUTE` | Execute | `ICON_EXECUTE_OBJECT` | **F8** (Standard toolbar Execute key) |
| 2 | *(separator)* | | | |
| 3 | `BACK` | Back | (Standard back arrow) | Standard toolbar Back |
| 4 | `EXIT` | Exit | (Standard exit) | Shift+F3 |
| 5 | `CANCEL` | Cancel | (Standard cancel) | F12 |

> **Cách assign F8:** Trong Function Keys tab, tìm dòng **F8** hoặc **Ctrl+Enter** (Execute button trên standard toolbar) → điền `EXECUTE`.

### Title Bar:

Screen này dùng **T_0410** — text = `Project Search`

> **Khác với title bars khác:** T_0410 KHÔNG cần `&1` placeholder — text cố định "Project Search".
> Tuy nhiên nếu muốn dùng `&1` cũng OK, khi đó code PBO sẽ viết:
> `SET TITLEBAR 'T_0410' WITH 'Project Search'.`

---

## 7. Security Logic

### Non-Manager chỉ thấy project mình tham gia:

```
User role = M (Manager) → Thấy TẤT CẢ projects (không filter theo ZBUG_USER_PROJEC)
User role = D hoặc T   → Chỉ thấy projects mà user có record trong ZBUG_USER_PROJEC
```

**Logic xử lý (trong `search_projects` FORM, CODE_F01):**

```abap
" Manager: SELECT trực tiếp từ ZBUG_PROJECT
" Non-Manager: INNER JOIN ZBUG_USER_PROJEC WHERE user_id = sy-uname
```

> Xem chi tiết code trong `docs/phase-f-v5-enhancement.md` Step F2.6.

---

## 8. PAI Flow — Khi user nhấn Execute

```
User nhấn Execute (F8) hoặc nhấn nút EXECUTE
  │
  ├── PAI: user_command_0410
  │     ├── PERFORM search_projects    ← Populate gt_project_list
  │     └── CALL SCREEN 0400          ← Mở Project List
  │
  └── Screen 0400 PBO: init_project_list
        └── Dùng gt_project_list đã populated ← ALV hiện filtered data
```

> **KEY:** `search_projects` SET `gt_project_list` global table. Screen 0400 PBO (`init_project_list`) dùng table này thay vì SELECT mới — nên phải update `init_project_list` để nhận diện khi data đã có sẵn.

---

## 9. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| F4 không hiện trên S_PRJ_ID | POV block thiếu trong flow logic | Thêm `PROCESS ON VALUE-REQUEST` section đúng format |
| Execute không mở 0400 | FCode EXECUTE chưa tạo trong STATUS_0410 | SE41 → verify STATUS_0410 có fcode EXECUTE |
| BACK không thoát program | LEAVE PROGRAM chưa gọi trong PAI | Check `user_command_0410` → case BACK → LEAVE PROGRAM |
| Screen 0400 hiện tất cả project (không filter) | `search_projects` chưa gọi hoặc `init_project_list` không dùng gt_project_list đã filter | Verify `search_projects` chạy trước `CALL SCREEN 0400` |
| "Variable S_PRJ_ID not found" khi Get from Program | Biến chưa khai báo trong TOP include | Verify `DATA: s_prj_id TYPE zde_project_id.` trong CODE_TOP v5.0 |
| User thấy project không thuộc mình | Security logic thiếu INNER JOIN | Verify search_projects code cho non-Manager dùng INNER JOIN ZBUG_USER_PROJEC |
