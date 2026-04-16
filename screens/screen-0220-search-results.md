# UI Guide: Screen 0220 — Bug Search Results (Full Screen ALV)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **Full screen hiển thị kết quả tìm kiếm bug — KHÔNG có Dashboard Header**
> Mở sau khi user Execute từ Screen 0210 (Bug Search popup)
>
> **Screen Type:** Normal (full screen)
> **Container:** `CC_SEARCH_RESULTS` (ALV Grid cho search results)

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0220`**
   - Short Description: `Bug Search Results`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0220`** (loop — PAI handles navigation)
5. **Save**

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0220.
  MODULE init_search_results.

PROCESS AFTER INPUT.
  MODULE user_command_0220.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0220` | PBO | SET PF-STATUS 'STATUS_0220', SET TITLEBAR 'T_0220' |
| `init_search_results` | PBO | Create/refresh ALV grid trong CC_SEARCH_RESULTS, dùng gt_search_results |
| `user_command_0220` | PAI | Handle: BACK/EXIT/CANCEL (free container + LEAVE TO SCREEN 0 → quay về 0200) |

> **KHÔNG có PROCESS ON VALUE-REQUEST** — screen này chỉ hiển thị kết quả ALV, không có input fields.

---

## 3. Layout (Screen Painter)

Click nút **Layout** → Screen Painter mở ra.

### Bước 1: Vẽ Custom Control cho ALV

1. Menu → Edit → Create Element → **Custom Control**
   (hoặc click icon Custom Control trên toolbar)
2. Vẽ hình chữ nhật **phủ gần toàn bộ screen** (~90% diện tích)
   - Suggested position: Row 2, Col 2 → Row 20, Col 120
3. **Name:** `CC_SEARCH_RESULTS`
   - ⚠️ Phải khớp **CHÍNH XÁC** với code: `container_name = 'CC_SEARCH_RESULTS'`

### Bước 2: Không cần thêm gì khác

- **KHÔNG CÓ Dashboard Header** — đây là điểm khác biệt chính so với Screen 0200
- Buttons nằm trên GUI Status toolbar
- Không cần input fields — ALV hiển thị search results

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Back | Exit | Cancel]                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── CC_SEARCH_RESULTS ───────────────────────────────────┐    │
│  │                                                         │    │
│  │   (ALV Grid — Bug search results)                       │    │
│  │                                                         │    │
│  │   Bug ID  | Title         | Project | Status  | Prio... │    │
│  │   ────────────────────────────────────────────────────── │    │
│  │   BUG0001 | Login fail    | PRJ001  | New     | High    │    │
│  │   BUG0005 | Slow query    | PRJ001  | Fixed   | Medium  │    │
│  │                                                         │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

> **So sánh Screen 0200 vs 0220:**
> | | Screen 0200 (Bug List) | Screen 0220 (Search Results) |
> |---|---|---|
> | Dashboard Header | ✅ Có (metrics phía trên) | ❌ KHÔNG có |
> | Data source | `gt_bug_list` (full project bugs) | `gt_search_results` (filtered) |
> | ALV Container | `CC_BUG_LIST` | `CC_SEARCH_RESULTS` |
> | CRUD buttons | CREATE, CHANGE, DISPLAY, DELETE | Không (chỉ xem) |
> | SEARCH button | ✅ Có | ❌ Không |

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0220 → tab **Element List** → phải thấy:

| Element | Type | Name |
|---------|------|------|
| Custom Control | CUSTOM CONTROL | `CC_SEARCH_RESULTS` |
| OK Code | OK | `GV_OK_CODE` |

### Quick Test:
1. Từ Screen 0200 → SEARCH → nhập criteria → Execute
2. Screen 0220 phải mở ra với ALV hiển thị kết quả
3. ALV phải có đầy đủ columns (Bug ID, Title, Status, Priority, ...)
4. BACK → quay về Screen 0200 (Bug List)
5. ALV columns và formatting reuse từ `build_bug_fieldcat` (giống Screen 0200)

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0220** (v5.0 NEW). Xem `final-steps.md` để tạo.

### Buttons trên STATUS_0220:

| # | FCode | Text | Icon |
|---|-------|------|------|
| 1 | `BACK` | Back | (Standard back arrow) |
| 2 | `EXIT` | Exit | (Standard exit) |
| 3 | `CANCEL` | Cancel | (Standard cancel) |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

> **Minimal toolbar:** Screen 0220 chỉ có Back/Exit/Cancel — không có CRUD buttons vì search results là read-only view.

### Title Bar:

Screen này dùng **T_0220** — text = `Search Results`

---

## 7. ALV Features (handled by code, không cần config trên screen)

| Feature | How |
|---------|-----|
| Field catalog | Reuse `build_bug_fieldcat` từ CODE_F00 (giống Bug List ALV) |
| Zebra striping | `layo-zebra = 'X'` |
| Selection mode | `layo-sel_mode = 'A'` (cho phép multi-select, hoặc 'D' single) |
| Hidden raw columns | STATUS, PRIORITY, SEVERITY, BUG_TYPE hidden (show _TEXT versions) |
| Row color by status | Reuse logic từ `set_bug_colors` (nếu implement) |

> **Reuse field catalog:** PBO module `init_search_results` gọi `PERFORM build_bug_fieldcat CHANGING lt_fcat` — cùng FORM mà Screen 0200 dùng. Không cần viết field catalog riêng.

---

## 8. Navigation Flow

```
Screen 0200 (Bug List + Dashboard)
  │
  └── [SEARCH] → Screen 0210 (Popup — nhập criteria)
       │
       └── [EXECUTE] → Screen 0220 (Full screen — kết quả, KHÔNG dashboard)
            │
            └── [BACK/EXIT/CANCEL] → Quay về Screen 0200
```

### Container Lifecycle:

```
User nhấn SEARCH trên 0200:
  → CALL SCREEN 0210 STARTING AT ... (popup)
  → User nhấn EXECUTE:
      → PERFORM execute_bug_search (populate gt_search_results)
      → LEAVE TO SCREEN 0 (close popup 0210)
      → CALL SCREEN 0220 (open full screen)

Screen 0220 PBO:
  → IF go_cont_search IS INITIAL:
      → CREATE go_cont_search (CC_SEARCH_RESULTS)
      → CREATE go_search_alv
      → set_table_for_first_display (gt_search_results)
  → ELSE:
      → go_search_alv->refresh_table_display()

User nhấn BACK trên 0220:
  → Free go_cont_search (QUAN TRỌNG — tránh leak)
  → CLEAR go_cont_search, go_search_alv
  → LEAVE TO SCREEN 0 (quay về 0200)
```

> ⚠️ **CRITICAL:** Phải `free()` container khi BACK — nếu không, lần mở tiếp sẽ gặp lỗi "Control already assigned" hoặc "Container already exists".

---

## 9. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| ALV không hiện | Container name sai | Layout phải có `CC_SEARCH_RESULTS` khớp code |
| "Module init_search_results not found" | Code v5.0 chưa activate | Verify PBO module `init_search_results` tồn tại trong CODE_PBO v5.0 |
| ALV hiện nhưng trống | `gt_search_results` trống (search không có kết quả) | User nên thử search khác hoặc xóa filter |
| Lỗi "Control already assigned" khi mở lần 2 | Container chưa free khi BACK lần trước | Verify `go_cont_search->free()` + `CLEAR` gọi khi BACK |
| BACK không quay về 0200 | OK Code chưa set hoặc LEAVE TO SCREEN 0 thiếu | Verify OK Code = GV_OK_CODE + PAI code |
| ALV columns khác với Bug List | Field catalog dùng sai FORM | Verify `PERFORM build_bug_fieldcat` (reuse từ CODE_F00) |
| Dashboard hiện trên screen này | Layout có output fields không mong muốn | Screen 0220 layout KHÔNG CÓ dashboard fields — chỉ CC_SEARCH_RESULTS |
