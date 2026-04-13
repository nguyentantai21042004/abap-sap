# UI Guide: Screen 0200 — Bug List (Dual Mode)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v4.0
> **Screen hiện bugs dạng ALV Grid — 2 mode: Project bugs / My Bugs**
>
> v4.0 changes: +3 template download buttons (DN_TC, DN_CONF, DN_PROOF) on STATUS_0200

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0200`**
   - Short Description: `Bug List`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0200`** (loop — PAI handles navigation)
5. **Save**

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0200.
  MODULE init_bug_list.

PROCESS AFTER INPUT.
  MODULE user_command_0200.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0200` | PBO | SET PF-STATUS (exclude buttons theo role + filter mode), dynamic title |
| `init_bug_list` | PBO | SELECT bug data (dual mode) + create/refresh ALV grid |
| `user_command_0200` | PAI | Handle: CREATE, CHANGE, DISPLAY, DELETE, REFRESH, BACK/CANC/EXIT |

### Dual Mode Logic:

| Mode | `gv_bug_filter_mode` | Title | Buttons hidden |
|------|---------------------|-------|----------------|
| **Project** | `'P'` | `Bugs — {Project Name}` | CREATE hidden if Dev role |
| **My Bugs** | `'M'` | `My Bugs — {username}` | CREATE + DELETE always hidden |

> Mode được set **trước** khi CALL SCREEN 0200 (trong Screen 0400 PAI code).

---

## 3. Layout (Screen Painter)

Click nút **Layout** → Screen Painter mở ra.

### Bước 1: Vẽ Custom Control cho ALV

1. Menu → Edit → Create Element → **Custom Control**
   (hoặc click icon Custom Control trên toolbar)
2. Vẽ hình chữ nhật **phủ gần toàn bộ screen** (~90% diện tích)
   - Suggested position: Row 2, Col 2 → Row 20, Col 120
3. **Name:** `CC_BUG_LIST`
   - ⚠️ Phải khớp **CHÍNH XÁC** với code: `container_name = 'CC_BUG_LIST'` (CODE_PBO.md line 82)

### Bước 2: Không cần thêm gì khác

- Buttons nằm trên GUI Status toolbar
- Không cần input fields

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Create | Change | Display | Delete | Refresh]        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── CC_BUG_LIST ───────────────────────────────────────────┐  │
│  │                                                           │  │
│  │   (ALV Grid — auto-created bởi PBO code)                  │  │
│  │                                                           │  │
│  │   Bug ID  | Title      | Project | Status  | Priority...  │  │
│  │   ─────────────────────────────────────────────────────    │  │
│  │   BUG0001 | Login fail | PRJ001  | New     | High         │  │
│  │   BUG0002 | Slow query | PRJ001  | Fixed   | Medium       │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0200 → tab **Element List**:

| Element | Type | Name |
|---------|------|------|
| Custom Control | CUSTOM CONTROL | `CC_BUG_LIST` |
| OK Code | OK | `GV_OK_CODE` |

### Quick Test:
1. Từ Screen 0400, click vào 1 project (hotspot trên PROJECT_ID) → phải mở Screen 0200
2. Title phải hiện "Bugs — {Project Name}"
3. Click "My Bugs" từ Screen 0400 → phải mở Screen 0200 với title "My Bugs — {username}"
4. BACK → quay về Screen 0400

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0200**. Xem `UI_FINAL_STEPS.md` để tạo.

### Buttons trên STATUS_0200:

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `CREATE` | Create Bug | `ICON_CREATE` | Hidden: Dev role + My Bugs mode |
| 2 | `CHANGE` | Change | `ICON_CHANGE` | |
| 3 | `DISPLAY` | Display | `ICON_DISPLAY` | |
| 4 | `DELETE` | Delete | `ICON_DELETE` | Hidden: Dev + Tester roles + My Bugs mode |
| 5 | *(separator)* | | | Click ô trống giữa 2 nút, để trống FCode |
| 6 | `REFRESH` | Refresh | `ICON_REFRESH` | |
| 7 | *(separator)* | | | |
| 8 | `DN_TC` | Download TestCase | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_TESTCASE từ SMW0 |
| 9 | `DN_CONF` | Download Confirm | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_CONFIRM từ SMW0 |
| 10 | `DN_PROOF` | Download BugProof | `ICON_EXPORT` | **v4.0** — Download ZTEMPLATE_BUGPROOF từ SMW0 |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

### Title Bar:

Screen này dùng **TITLE_BUGLIST** — text = `&1` (nhận dynamic title từ code).

---

## 7. ALV Features (handled by code, không cần config trên screen)

| Feature | How |
|---------|-----|
| Hotspot trên BUG_ID | Click → mở Bug Detail (Display mode) |
| Hotspot trên PROJECT_ID | Click → mở Project Detail (Display mode) |
| Row color by status | `T_COLOR` field, mapped in `set_bug_colors` |
| Hidden raw columns | STATUS, PRIORITY, SEVERITY, BUG_TYPE hidden (show _TEXT versions) |
| Zebra striping | `layo-zebra = 'X'` |
| Auto column width | `layo-cwidth_opt = 'X'` |
| Single-row selection | `layo-sel_mode = 'D'` |

---

## 8. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| ALV không hiện | Container name sai | Layout phải có `CC_BUG_LIST` khớp code |
| Create button vẫn hiện trong My Bugs | GUI Status chưa set đúng fcodes | Verify STATUS_0200 có fcode `CREATE` |
| Hotspot không work | Event handler chưa register | Check CODE_F00.md — handler registered trong init_bug_list |
| BACK không quay về 0400 | OK Code chưa set | Screen Attributes → thêm GV_OK_CODE |
| Title hiện sai | gv_bug_filter_mode chưa set | Kiểm tra code trước CALL SCREEN 0200 đã set filter mode |
