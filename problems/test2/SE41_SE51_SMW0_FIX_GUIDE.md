# Round 2 — SE41 / SE51 / SMW0 Fix Guide

> Hướng dẫn chi tiết cho 3 thay đổi NON-CODE: Bug 4, Bug 5, Bug 7.
> Thực hiện SAU khi deploy CODE files xong.

---

## Bug 7: SE41 — Fix DL_EVD Label + Add DW_EVD Button (STATUS_0300)

### Vấn đề:

Nút `DL_EVD` hiện tại có label "Delete Evidence" nhưng user nhầm với Download. Cần:
1. Giữ `DL_EVD` = Delete Evidence (chỉ verify label đúng)
2. Thêm nút MỚI `DW_EVD` = Download Evidence

### Bước thực hiện:

1. **SE41** → Program: `Z_BUG_WORKSPACE_MP` → Status: `STATUS_0300` → **Change** (bút chì)

2. **Verify DL_EVD label:**
   - Tìm button `DL_EVD` trên Application Toolbar
   - Double-click → verify:
     - FCode: `DL_EVD`
     - Text: `Delete Evidence`
     - Icon: `ICON_DELETE`
   - Nếu đã đúng → không cần sửa. Nếu text sai → sửa thành `Delete Evidence`

3. **Thêm button DW_EVD:**
   - Click ô trống trên Application Toolbar (sau `DL_EVD`, trước `SENDMAIL`)
   - Hoặc: nếu hết chỗ, click ô trống bất kỳ sau `DL_EVD`
   - Nhập:
     - **FCode:** `DW_EVD`
     - **Text:** `Download Evidence`
     - **Icon:** `ICON_EXPORT` (hoặc `ICON_DOWNLOAD` nếu có)
     - **Functional Type:** để trống (Normal)

4. **Layout mới của Application Toolbar (sau khi sửa):**

   | # | FCode | Text | Icon |
   |---|-------|------|------|
   | 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` |
   | 2 | `STATUS_CHG` | Change Status | `ICON_CHANGE` |
   | 3 | *(separator)* | | |
   | 4 | `UP_FILE` | Upload Evidence | `ICON_IMPORT` |
   | 5 | `UP_REP` | Upload Report | `ICON_IMPORT` |
   | 6 | `UP_FIX` | Upload Fix | `ICON_IMPORT` |
   | 7 | *(separator)* | | |
   | 8 | `DL_EVD` | Delete Evidence | `ICON_DELETE` |
   | 9 | `DW_EVD` | Download Evidence | `ICON_EXPORT` |
   | 10 | `SENDMAIL` | Send Email | `ICON_MAIL` |

5. **Save** (Ctrl+S) → **Activate** (Ctrl+F3)

### Verify:

- Mở Bug Detail ở **Change mode** → toolbar phải hiện cả "Delete Evidence" và "Download Evidence"
- Mở Bug Detail ở **Create mode** → `DW_EVD` phải bị ẩn (code trong CODE_PBO đã exclude)
- Mở Bug Detail ở **Display mode** → `DW_EVD` phải hiện (download cho phép ở display)

---

## Bug 4: SE51 — Add CANCEL Pushbutton on Screen 0370

### Vấn đề:

Popup 0370 chỉ có nút trên toolbar (STATUS_0370 có CANCEL fcode) nhưng không có nút visible trên layout. User khó thoát vì không thấy nút Cancel rõ ràng.

### Bước thực hiện:

1. **SE51** → Program: `Z_BUG_WORKSPACE_MP` → Screen: `0370` → **Layout** (click nút Layout)

2. **Thêm Pushbutton:**
   - Menu bar → **Edit** → **Create Element** → chọn **Pushbutton** (hoặc dùng Pushbutton icon trên toolbar bên trái)
   - Vẽ pushbutton ở **góc dưới phải** của popup layout (bên cạnh vị trí sẽ thấy nút Confirm)
   - Hoặc: vẽ ở hàng cuối, cạnh phải

3. **Set thuộc tính Pushbutton:**
   - Double-click vào pushbutton vừa tạo → cửa sổ Attributes mở ra
   - **Name:** `PUSH_CANCEL` (tên element trên layout, tùy chọn)
   - **Text:** `Cancel`
   - **FCode:** `CANCEL` ← QUAN TRỌNG — phải khớp với WHEN 'CANCEL' trong PAI
   - **Icon:** `ICON_CANCEL` (optional, nếu muốn thêm icon)
   - **FCType (Functional Type):** `E` (Exit command) ← để PAI xử lý trước MODULE

   > **Tại sao FCType = E?** Vì `CANCEL` là exit action, cần bypass mandatory field checks. Nếu để Normal (trống), SAP sẽ chạy field validation trước khi vào PAI → user bị kẹt nếu required field trống.

4. **(Optional) Thêm thêm pushbutton CONFIRM:**
   - Nếu chưa có nút Confirm visible trên layout, thêm tương tự:
   - **Name:** `PUSH_CONFIRM`
   - **Text:** `Confirm`
   - **FCode:** `CONFIRM`
   - **Icon:** `ICON_OKAY`
   - **FCType:** để trống (Normal) — Confirm cần chạy validation

5. **Save** layout (Ctrl+S)

6. **Quay lại SE51** main → **Activate** screen (Ctrl+F3)

### Layout Preview (sau khi sửa):

```
┌──── Change Bug Status ──────────────────────────────────────┐
│                                                              │
│  Bug ID:         [BUG00001      ] (display-only)             │
│  Title:          [Login fail when...            ] (ro)       │
│  Reporter:       [DEV-118       ] (display-only)             │
│  Current Status: [In Progress   ] (display-only)             │
│                                                              │
│  New Status *:   [___________________ ] (F4)                 │
│  Developer:      [____________] (F4)                         │
│  Final Tester:   [____________] (F4)                         │
│                                                              │
│  Transition Note:                                            │
│  ┌─── CC_TRANS_NOTE ─────────────────────────────────────┐   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  [Confirm]  [Upload Evidence]  [Cancel]    ← VISIBLE BUTTONS │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Verify:

1. Mở Bug Detail (Change mode) → nhấn nút "Change Status"
2. Popup 0370 mở → phải thấy nút **Cancel** rõ ràng trên layout
3. Nhấn Cancel → popup đóng, không thay đổi gì
4. Nhấn Fn+F12 (Mac) → cũng phải đóng popup (F12 → fcode CANCEL)

### Lưu ý:

- PAI đã xử lý `WHEN 'CANCEL'` rồi — chỉ cần thêm pushbutton trên layout
- OK Code field của Screen 0370 = `GV_OK_CODE` (đã fix trước đó)
- Nếu `GV_OK_CODE` trống → fcode CANCEL sẽ không hoạt động → kiểm tra lại Element List → OK field

---

## Bug 5: SMW0 — Upload 3 Excel Templates

### Vấn đề:

3 nút download template trên Project List không hoạt động vì chưa upload template files vào SMW0. Code logic đã kiểm tra template tồn tại → nếu không có → hiện error message. Cần upload 3 files.

### Chuẩn bị — Tạo 3 file Excel template:

Trước khi vào SMW0, cần tạo 3 file Excel (.xlsx hoặc .xls) trên máy tính:

#### Template 1: `ZBT_TMPL_01` — Bug Report Template
Tạo file Excel tên `ZBT_TMPL_01.xlsx` với các cột header:

| Bug ID | Title | Priority | Severity | SAP Module | Description | Steps to Reproduce |
|--------|-------|----------|----------|------------|-------------|-------------------|

> Sheet name: `Bug Report`. Để trống data rows (chỉ có header).

#### Template 2: `ZBT_TMPL_02` — Test Case Template
Tạo file Excel tên `ZBT_TMPL_02.xlsx` với các cột header:

| Test Case ID | Bug ID | Test Step | Expected Result | Actual Result | Status | Tester |
|-------------|--------|-----------|-----------------|---------------|--------|--------|

> Sheet name: `Test Cases`. Để trống data rows.

#### Template 3: `ZBT_TMPL_03` — User List Template
Tạo file Excel tên `ZBT_TMPL_03.xlsx` với các cột header:

| User ID | Full Name | Role (M/D/T) | SAP Module | Email | Is Active |
|---------|-----------|---------------|------------|-------|-----------|

> Sheet name: `User List`. Để trống data rows.

> **LƯU Ý:** Template content/columns có thể tùy chỉnh theo nhu cầu thực tế. Quan trọng là file tồn tại trong SMW0 với đúng Object Name.

### Bước thực hiện:

1. **Mở T-code SMW0**

2. Ở màn hình đầu tiên, chọn:
   - **WebRFC Binary Data** ← radio button này
   - Nhấn **Enter** hoặc **Execute**

3. **Upload Template 1:**
   - Nhấn nút **Create** (icon tạo mới, hoặc menu Edit → Create)
   - Object Name: **`ZBT_TMPL_01`**
   - Description: `Bug Report Template`
   - Nhấn **Enter**
   - Hệ thống hỏi file → **Browse** → chọn file `ZBT_TMPL_01.xlsx` từ máy tính
   - MIME Type: hệ thống tự detect (hoặc nhập `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`)
   - Nhấn **Save** → chọn package `ZBUGTRACK` → **Save** (hoặc Local Object nếu chỉ test)

4. **Upload Template 2:**
   - Lặp lại bước 3 với:
   - Object Name: **`ZBT_TMPL_02`**
   - Description: `Test Case Template`
   - File: `ZBT_TMPL_02.xlsx`

5. **Upload Template 3:**
   - Lặp lại bước 3 với:
   - Object Name: **`ZBT_TMPL_03`**
   - Description: `User List Template`
   - File: `ZBT_TMPL_03.xlsx`

### Verify:

1. Trong SMW0 → search `ZBT_TMPL*` → phải thấy 3 entries:

   | Object Name | Description |
   |-------------|-------------|
   | `ZBT_TMPL_01` | Bug Report Template |
   | `ZBT_TMPL_02` | Test Case Template |
   | `ZBT_TMPL_03` | User List Template |

2. Double-click từng entry → verify file size > 0 bytes

3. **Test trong app:**
   - Mở app → vào Project List (Screen 0400)
   - Nhấn từng nút Download Template (1, 2, 3)
   - Mỗi lần phải hiện dialog "Save As" → chọn nơi lưu → file Excel tải về thành công
   - Mở file Excel vừa tải → phải thấy đúng header columns

### Troubleshooting:

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| "Template not found" message | Object name trong SMW0 không khớp code | Verify object name CHÍNH XÁC: `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03` (case-sensitive) |
| Download gây dump | MIME type sai hoặc file corrupt | Re-upload file mới, verify MIME type |
| SMW0 không tìm thấy | Chưa chọn "WebRFC Binary Data" | Bước 2: phải chọn đúng radio button |
| File tải về bị rỗng | Upload file rỗng (0 bytes) | Re-upload file có content |

---

## Thứ tự thực hiện tổng quan

1. Deploy CODE files trước (CODE_F01, CODE_F02, CODE_PBO, CODE_PAI)
2. SE41: Fix STATUS_0300 (Bug 7) — thêm DW_EVD button
3. SE51: Fix Screen 0370 (Bug 4) — thêm CANCEL pushbutton
4. SMW0: Upload 3 templates (Bug 5) — tạo 3 Excel files + upload
5. Activate tất cả → Test
