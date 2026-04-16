# UI Guide: Screen 0200 — Bug List (Dual Mode + Dashboard)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **Screen hiện bugs dạng ALV Grid — 2 mode: Project bugs / My Bugs**
>
> v4.0 changes: +3 template download buttons (DN_TC, DN_CONF, DN_PROOF) on STATUS_0200
> **v5.0 changes:** +Dashboard Header (metrics phía trên ALV), +SEARCH button trên toolbar

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
| `status_0200` | PBO | SET PF-STATUS (exclude buttons theo role + filter mode), dynamic title, **v5.0: PERFORM calculate_dashboard** |
| `init_bug_list` | PBO | SELECT bug data (dual mode) + create/refresh ALV grid |
| `user_command_0200` | PAI | Handle: CREATE, CHANGE, DISPLAY, DELETE, REFRESH, **SEARCH** (v5.0), BACK/CANC/EXIT |

### Dual Mode Logic:

| Mode | `gv_bug_filter_mode` | Title | Buttons hidden |
|------|---------------------|-------|----------------|
| **Project** | `'P'` | `Bugs — {Project Name}` | CREATE hidden if Dev role |
| **My Bugs** | `'M'` | `My Bugs — {username}` | CREATE + DELETE always hidden |

> Mode được set **trước** khi CALL SCREEN 0200 (trong Screen 0400 PAI code).

---

## 3. Layout (Screen Painter)

Click nút **Layout** → Screen Painter mở ra.

### v5.0 — Screen chia 2 phần: Dashboard (trên) + ALV (dưới)

> **QUAN TRỌNG:** Trong v4.0, `CC_BUG_LIST` chiếm gần toàn bộ screen. Trong v5.0, phải dành ~8-10 dòng phía trên cho Dashboard output fields, rồi mới đặt `CC_BUG_LIST` phía dưới.

---

### Bước 1: Vẽ Dashboard Output Fields

Tất cả fields dưới đây đều là **Output** (INPUT = 0). KHÔNG thuộc screen group nào.

> **Cách thêm output field:** Dict/Program field → nhập tên biến → Enter → SAP tự đặt type. Sau đó double-click field → tab **Program** → đảm bảo `Input = OFF` (uncheck Input box hoặc set Input = 0).

#### Row 2 — Total

| Position | Element | Type | Name | Length | Notes |
|----------|---------|------|------|--------|-------|
| Row 2, Col 2 | Label | Text | | | Text: `Total Bugs:` |
| Row 2, Col 15 | Field | Output | `GV_DASH_TOTAL` | 10 | TYPE I |

#### Row 4 — By Status (line 1)

| Position | Element | Type | Name | Length | Notes |
|----------|---------|------|------|--------|-------|
| Row 4, Col 2 | Label | Text | | | Text: `By Status:` |
| Row 4, Col 14 | Label | Text | | | Text: `New:` |
| Row 4, Col 19 | Field | Output | `GV_D_NEW` | 5 | |
| Row 4, Col 27 | Label | Text | | | Text: `Assigned:` |
| Row 4, Col 37 | Field | Output | `GV_D_ASSIGNED` | 5 | |
| Row 4, Col 45 | Label | Text | | | Text: `InProg:` |
| Row 4, Col 53 | Field | Output | `GV_D_INPROG` | 5 | |
| Row 4, Col 61 | Label | Text | | | Text: `Fixed:` |
| Row 4, Col 68 | Field | Output | `GV_D_FIXED` | 5 | |

#### Row 5 — By Status (line 2)

| Position | Element | Type | Name | Length | Notes |
|----------|---------|------|------|--------|-------|
| Row 5, Col 14 | Label | Text | | | Text: `FinalTest:` |
| Row 5, Col 25 | Field | Output | `GV_D_FINALTEST` | 5 | |
| Row 5, Col 33 | Label | Text | | | Text: `Resolved:` |
| Row 5, Col 43 | Field | Output | `GV_D_RESOLVED` | 5 | |
| Row 5, Col 51 | Label | Text | | | Text: `Rejected:` |
| Row 5, Col 61 | Field | Output | `GV_D_REJECTED` | 5 | |
| Row 5, Col 69 | Label | Text | | | Text: `Waiting:` |
| Row 5, Col 78 | Field | Output | `GV_D_WAITING` | 5 | |

#### Row 7 — By Priority

| Position | Element | Type | Name | Length | Notes |
|----------|---------|------|------|--------|-------|
| Row 7, Col 2 | Label | Text | | | Text: `By Priority:` |
| Row 7, Col 16 | Label | Text | | | Text: `High:` |
| Row 7, Col 22 | Field | Output | `GV_D_P_HIGH` | 5 | |
| Row 7, Col 30 | Label | Text | | | Text: `Medium:` |
| Row 7, Col 38 | Field | Output | `GV_D_P_MED` | 5 | |
| Row 7, Col 46 | Label | Text | | | Text: `Low:` |
| Row 7, Col 51 | Field | Output | `GV_D_P_LOW` | 5 | |

#### Row 9 — By Module

| Position | Element | Type | Name | Length | Notes |
|----------|---------|------|------|--------|-------|
| Row 9, Col 2 | Label | Text | | | Text: `By Module:` |
| Row 9, Col 14 | Label | Text | | | Text: `FI:` |
| Row 9, Col 18 | Field | Output | `GV_D_M_FI` | 5 | |
| Row 9, Col 26 | Label | Text | | | Text: `MM:` |
| Row 9, Col 30 | Field | Output | `GV_D_M_MM` | 5 | |
| Row 9, Col 38 | Label | Text | | | Text: `SD:` |
| Row 9, Col 42 | Field | Output | `GV_D_M_SD` | 5 | |
| Row 9, Col 50 | Label | Text | | | Text: `ABAP:` |
| Row 9, Col 56 | Field | Output | `GV_D_M_ABAP` | 5 | |
| Row 9, Col 64 | Label | Text | | | Text: `BASIS:` |
| Row 9, Col 71 | Field | Output | `GV_D_M_BASIS` | 5 | |

---

### Bước 2: Vẽ Custom Control cho ALV

1. Menu → Edit → Create Element → **Custom Control**
   (hoặc click icon Custom Control trên toolbar)
2. Vẽ hình chữ nhật **phía dưới Dashboard**, từ Row 11 trở xuống
   - **v5.0 position:** Row 11, Col 2 → Row 22, Col 120
   - (v4.0 bắt đầu từ Row 2; v5.0 phải đẩy xuống Row 11 để nhường chỗ cho Dashboard)
3. **Name:** `CC_BUG_LIST`
   - Phải khớp **CHÍNH XÁC** với code: `container_name = 'CC_BUG_LIST'`

---

### Bước 3: Không cần thêm gì khác

- Buttons nằm trên GUI Status toolbar
- Dashboard fields đều output-only, không cần input handling

---

### Layout Preview (v5.0):

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Create|Change|Display|Delete|Refresh|SEARCH|DN_*]     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Total Bugs: [125]                                              │
│                                                                 │
│  By Status:  New:[12]  Assigned:[18]  InProg:[25]  Fixed:[15]   │
│              FinalTest:[8]  Resolved:[30] Rejected:[5] Wait:[2] │
│                                                                 │
│  By Priority: High:[40]  Medium:[55]  Low:[30]                  │
│                                                                 │
│  By Module:  FI:[20]  MM:[15]  SD:[18]  ABAP:[52]  BASIS:[20]  │
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
| Output Field | OUTPUT | `GV_DASH_TOTAL` |
| Output Field | OUTPUT | `GV_D_NEW` |
| Output Field | OUTPUT | `GV_D_ASSIGNED` |
| Output Field | OUTPUT | `GV_D_INPROG` |
| Output Field | OUTPUT | `GV_D_FIXED` |
| Output Field | OUTPUT | `GV_D_FINALTEST` |
| Output Field | OUTPUT | `GV_D_RESOLVED` |
| Output Field | OUTPUT | `GV_D_REJECTED` |
| Output Field | OUTPUT | `GV_D_WAITING` |
| Output Field | OUTPUT | `GV_D_P_HIGH` |
| Output Field | OUTPUT | `GV_D_P_MED` |
| Output Field | OUTPUT | `GV_D_P_LOW` |
| Output Field | OUTPUT | `GV_D_M_FI` |
| Output Field | OUTPUT | `GV_D_M_MM` |
| Output Field | OUTPUT | `GV_D_M_SD` |
| Output Field | OUTPUT | `GV_D_M_ABAP` |
| Output Field | OUTPUT | `GV_D_M_BASIS` |

> **Tổng:** 1 Custom Control + 1 OK Code + 18 output fields = **20 elements**

### Quick Test:
1. Từ Screen 0400, click vào 1 project (hotspot trên PROJECT_ID) → phải mở Screen 0200
2. **Dashboard phải hiển thị đúng số liệu** — Total = số bugs trong ALV
3. Title phải hiện "Bugs — {Project Name}"
4. Click "My Bugs" từ Screen 0400 → mở Screen 0200 với title "My Bugs — {username}"
5. **v5.0: Click SEARCH** → phải mở Screen 0210 (popup)
6. Kiểm tra dashboard **update realtime** khi dùng ALV filter (standard filter)
7. BACK → quay về Screen 0400

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0200**. Xem `docs/final-steps.md` để tạo.

### Buttons trên STATUS_0200:

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `CREATE` | Create Bug | `ICON_CREATE` | Hidden: Dev role + My Bugs mode |
| 2 | `CHANGE` | Change | `ICON_CHANGE` | |
| 3 | `DISPLAY` | Display | `ICON_DISPLAY` | |
| 4 | `DELETE` | Delete | `ICON_DELETE` | Hidden: Dev + Tester roles + My Bugs mode |
| 5 | *(separator)* | | | Click ô trống giữa 2 nút, để trống FCode |
| 6 | `REFRESH` | Refresh | `ICON_REFRESH` | |
| 7 | **`SEARCH`** | **Search Bug** | **`ICON_SEARCH`** | **v5.0 NEW** — Mở popup Screen 0210 |
| 8 | *(separator)* | | | |
| 9 | `DN_TC` | Download TestCase | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_01 từ SMW0 |
| 10 | `DN_CONF` | Download Confirm | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_03 từ SMW0 |
| 11 | `DN_PROOF` | Download BugProof | `ICON_EXPORT` | v4.0 — Download ZBT_TMPL_02 từ SMW0 |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

### v5.0 — Thêm SEARCH vào STATUS_0200 (SE41):

Nếu STATUS_0200 đã tạo rồi (v4.0), cần **sửa lại**:

1. SE41 → Program `Z_BUG_WORKSPACE_MP` → Status `STATUS_0200`
2. Click **Change** (Ctrl+F1)
3. Thêm 1 nút mới sau REFRESH:
   - **FCode:** `SEARCH`
   - **Text:** `Search Bug`
   - **Icon:** `ICON_SEARCH`
   - **Function Type:** Normal (để trống)
4. **Save** + **Activate**

> **Lưu ý:** SEARCH button **KHÔNG** bị exclude ở bất kỳ mode nào (cả Project mode lẫn My Bugs mode đều hiện SEARCH).

### Title Bar:

Screen này dùng **TITLE_BUGLIST** — text = `&1` (nhận dynamic title từ code).

---

## 7. Dashboard — Code Flow (v5.0)

> Phần này mô tả **logic** code — code thực tế nằm trong CODE files.

### 7.1. Dashboard Variables

Khai báo trong **CODE_TOP** (18 biến TYPE I):

```
gv_dash_total, gv_d_new, gv_d_assigned, gv_d_inprog, gv_d_fixed,
gv_d_finaltest, gv_d_resolved, gv_d_rejected, gv_d_waiting, gv_d_closed,
gv_d_p_high, gv_d_p_med, gv_d_p_low,
gv_d_m_fi, gv_d_m_mm, gv_d_m_sd, gv_d_m_abap, gv_d_m_basis
```

### 7.2. Calculation (CODE_F01 — `calculate_dashboard`)

```abap
FORM calculate_dashboard.
  " Reset all 18 counters
  CLEAR: gv_dash_total, gv_d_new, ...

  gv_dash_total = lines( gt_bug_list ).

  LOOP AT gt_bug_list ASSIGNING FIELD-SYMBOL(<bug>).
    " Count by STATUS (CASE), PRIORITY (CASE), SAP_MODULE (CASE)
  ENDLOOP.
ENDFORM.
```

### 7.3. Gọi calculate_dashboard

| Vị trí | Khi nào |
|--------|---------|
| PBO `status_0200` | Mỗi lần screen 0200 PBO chạy (hiển thị/refresh) |
| Sau SELECT trong `select_bug_data` | Sau khi load data mới |

> Dashboard metrics **tự động update** mỗi PBO cycle vì code tính lại từ `gt_bug_list` (internal table).

---

## 8. SEARCH Button — Code Flow (v5.0)

### PAI Handler (CODE_PAI — `user_command_0200`):

```abap
WHEN 'SEARCH'.
  " Mở Bug Search popup (modal dialog)
  CALL SCREEN 0210 STARTING AT 10 5 ENDING AT 90 15.
  " Sau khi popup đóng:
  " Nếu user nhấn EXECUTE → Screen 0220 hiển thị kết quả
  " Nếu user nhấn CANCEL → quay lại Screen 0200 như bình thường
```

> **Xem thêm:**
> - `screens/screen-0210-bug-search.md` — Popup nhập criteria
> - `screens/screen-0220-search-results.md` — Full screen kết quả tìm kiếm

---

## 9. ALV Features (handled by code, không cần config trên screen)

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

## 10. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| ALV không hiện | Container name sai | Layout phải có `CC_BUG_LIST` khớp code |
| Dashboard fields trống (0) | `calculate_dashboard` chưa gọi | Verify PBO module `status_0200` có `PERFORM calculate_dashboard` |
| Dashboard không update sau filter | Filter ALV không trigger PBO | Đảm bảo ALV event handler gọi lại `calculate_dashboard` khi filter thay đổi |
| Create button vẫn hiện trong My Bugs | GUI Status chưa set đúng fcodes | Verify STATUS_0200 có fcode `CREATE` trong exclude list |
| SEARCH button không hiện | Chưa thêm vào STATUS_0200 | SE41 → mở STATUS_0200 → thêm SEARCH fcode (xem Section 6) |
| Hotspot không work | Event handler chưa register | Check CODE_F00.md — handler registered trong init_bug_list |
| BACK không quay về 0400 | OK Code chưa set | Screen Attributes → thêm GV_OK_CODE |
| Title hiện sai | gv_bug_filter_mode chưa set | Kiểm tra code trước CALL SCREEN 0200 đã set filter mode |
| CC_BUG_LIST quá nhỏ sau thêm Dashboard | Custom Control chưa resize | Di chuyển CC_BUG_LIST: Row 11+ trở xuống, đủ rộng (xem Bước 2) |
