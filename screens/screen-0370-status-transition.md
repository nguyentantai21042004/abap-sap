# UI Guide: Screen 0370 — Status Transition Popup (Modal Dialog)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v5.0
> **Popup chuyển trạng thái Bug — thay thế POPUP_GET_VALUES cũ**
> Hiện từ nút "Change Status" trên Bug Detail (Screen 0300)
>
> **Screen Type:** Modal Dialog Box (popup)
> **Container:** `CC_TRANS_NOTE` (Text Editor cho transition note)

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0370`**
   - Short Description: `Status Transition Popup`
4. Tab **Attributes**:
   - Screen Type: **Modal Dialog Box** ← QUAN TRỌNG — KHÔNG phải Normal
   - Next Screen: **`0370`** (loop)
5. **Save**

> ⚠️ **CONFLICT RESOLVED:** Screen 0350 đã dùng cho Evidence ALV subscreen. Status Transition Popup dùng **Screen 0370** thay thế.

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0370.
  MODULE init_trans_popup.

PROCESS AFTER INPUT.
  MODULE user_command_0370.

PROCESS ON VALUE-REQUEST.
  FIELD gv_trans_new_status  MODULE f4_trans_status.
  FIELD gv_trans_dev_id      MODULE f4_trans_developer.
  FIELD gv_trans_ftester_id  MODULE f4_trans_ftester.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0370` | PBO | SET PF-STATUS 'STATUS_0370', SET TITLEBAR 'T_0370' |
| `init_trans_popup` | PBO | Pre-fill read-only fields, pre-fill dev/tester từ current bug, init CC_TRANS_NOTE editor, call `modify_screen_0370` |
| `user_command_0370` | PAI | Handle: CONFIRM (validate + apply transition), CANCEL (close popup), UP_TRANS (upload evidence) |
| `f4_trans_status` | PAI (POV) | F4 help cho NEW_STATUS — **chỉ hiện trạng thái hợp lệ** theo current status + role |
| `f4_trans_developer` | PAI (POV) | F4 help cho Developer — list Dev cùng project |
| `f4_trans_ftester` | PAI (POV) | F4 help cho Final Tester — list Tester cùng project |

> **CRITICAL:** `f4_trans_status` KHÔNG hiện tất cả 10 statuses — chỉ hiện những status mà user có quyền chuyển tới, dựa vào Transition Matrix (xem `docs/status-lifecycle.md` Section 2.3).

---

## 3. Layout (Screen Painter)

Click nút **Layout** → Screen Painter mở ra.

### Bước 1: Thêm Read-Only Fields

1. **Dict/Program Fields** → lần lượt nhập các biến → **Get from Program**:

| # | Variable Name | Type | Label | Input | Ghi chú |
|---|--------------|------|-------|-------|---------|
| 1 | `GV_TRANS_BUG_ID` | CHAR 10 | `Bug ID` | **OFF** (display-only) | Auto-fill từ gs_bug_detail |
| 2 | `GV_TRANS_TITLE` | CHAR 100 | `Title` | **OFF** | Auto-fill |
| 3 | `GV_TRANS_REPORTER` | CHAR 12 | `Reporter` | **OFF** | Auto-fill (= tester_id) |
| 4 | `GV_TRANS_CUR_ST_TEXT` | CHAR 20 | `Current Status` | **OFF** | Auto-fill (text, không phải code) |

> **Cách set Input = OFF:** Double-click field → Attributes tab → "Input" checkbox → **uncheck**.

### Bước 2: Thêm Input Fields

| # | Variable Name | Type | Label | Input | Screen Group | F4 |
|---|--------------|------|-------|-------|-------------|-----|
| 5 | `GV_TRANS_NEW_STATUS` | CHAR 20 | `New Status *` | **ON** | — | F4 hiện allowed statuses |
| 6 | `GV_TRANS_DEV_ID` | CHAR 12 | `Developer` | **ON** | `TDV` | F4 hiện developers cùng project |
| 7 | `GV_TRANS_FTESTER_ID` | CHAR 12 | `Final Tester` | **ON** | `TFT` | F4 hiện testers cùng project |

> **Screen Groups (Group1):**
> - `TDV` = Transition Developer field — enable/disable theo current status
> - `TFT` = Transition Final Tester field — enable/disable theo current status
> - Không cần set Group1 cho `GV_TRANS_NEW_STATUS` — luôn mở (F4 filter đã enforce valid options)

### Bước 3: Set Screen Groups (Group1)

Double-click từng field → tab **Attributes** → field **Group1** → nhập:

| Field | Group1 | Logic Enable/Disable |
|-------|--------|---------------------|
| `GV_TRANS_DEV_ID` | **`TDV`** | MỞ khi current status = New (1), Waiting (W), Pending (4). KHÓA cho các status khác. |
| `GV_TRANS_FTESTER_ID` | **`TFT`** | MỞ khi current status = Waiting (W). KHÓA cho các status khác. |

### Screen Group Logic (trong `modify_screen_0370`, CODE_F01):

| Group | Current Status → Enable | Current Status → Disable |
|-------|------------------------|------------------------|
| `TDV` | New (1), Waiting (W), Pending (4) | Assigned (2), In Progress (3), Final Testing (6) |
| `TFT` | Waiting (W) | Tất cả status khác |

### Bước 4: Thêm Custom Control cho Transition Note

1. Menu → Edit → Create Element → **Custom Control**
2. Vẽ hình chữ nhật ở **phần dưới** popup (~60 chars wide x 4-5 lines high)
3. Name: **`CC_TRANS_NOTE`**
   - ⚠️ Phải khớp **CHÍNH XÁC** với code: `container_name = 'CC_TRANS_NOTE'`

> **Transition Note** dùng `cl_gui_textedit` — cho phép user ghi lý do chuyển trạng thái.
> - **Bắt buộc** khi chuyển sang Rejected (R) — ghi lý do từ chối
> - **Bắt buộc** khi chuyển sang Resolved (V) — ghi kết quả test
> - Enable/disable theo current status (code trong `modify_screen_0370`)

### Bước 5: Thêm Label cho Transition Note (optional)

1. Menu → Edit → Create Element → **Text Field**
2. Text: `Transition Note:` → đặt phía trên CC_TRANS_NOTE

### Layout Preview:

```
┌──── Change Bug Status ──────────────────────────────────────┐
│                                                              │
│  Bug ID:         [BUG00001      ] (display-only)             │
│  Title:          [Login fail when password expired...] (ro)  │
│  Reporter:       [DEV-118       ] (display-only)             │
│  Current Status: [In Progress   ] (display-only)             │
│                                                              │
│  ─────────────────────────────────────────────────────────── │
│                                                              │
│  New Status *:   [___________________ ] (F4 — filtered)      │
│  Developer:      [____________] (F4)   ← enable/disable     │
│  Final Tester:   [____________] (F4)   ← enable/disable     │
│                                                              │
│  Transition Note:                                            │
│  ┌─── CC_TRANS_NOTE ─────────────────────────────────────┐   │
│  │                                                       │   │
│  │  (cl_gui_textedit — ghi lý do / kết quả)             │   │
│  │                                                       │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  [Confirm]  [Upload Evidence]  [Cancel]                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

> **Kích thước popup:** Code gọi `CALL SCREEN 0370 STARTING AT 5 3 ENDING AT 85 22` — khoảng 80 columns x 20 rows.

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0370 → tab **Element List** → phải thấy:

| Element | Type | Name | Group1 |
|---------|------|------|--------|
| Input/Output | — | `GV_TRANS_BUG_ID` | — |
| Input/Output | — | `GV_TRANS_TITLE` | — |
| Input/Output | — | `GV_TRANS_REPORTER` | — |
| Input/Output | — | `GV_TRANS_CUR_ST_TEXT` | — |
| Input/Output | — | `GV_TRANS_NEW_STATUS` | — |
| Input/Output | — | `GV_TRANS_DEV_ID` | TDV |
| Input/Output | — | `GV_TRANS_FTESTER_ID` | TFT |
| Custom Control | CUSTOM CONTROL | `CC_TRANS_NOTE` | — |
| OK Code | OK | `GV_OK_CODE` | — |

### Quick Test:
1. Mở Bug Detail (Change mode) → nhấn nút "Change Status"
2. Popup 0370 phải mở ra
3. Read-only fields (Bug ID, Title, Reporter, Current Status) phải hiện đúng data
4. Nhấn F4 trên New Status → chỉ hiện statuses hợp lệ theo current status + role
5. Developer field mở/khóa tùy theo current status
6. Final Tester field chỉ mở khi current status = Waiting
7. Transition Note editor hiện hoặc khóa tùy status
8. Nhấn Confirm → validation chạy → nếu pass thì status updated
9. Nhấn Cancel → popup đóng, không thay đổi gì

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0370** (v5.0 NEW). Xem `final-steps.md` để tạo.

### Buttons trên STATUS_0370:

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `CONFIRM` | Confirm | `ICON_OKAY` | Validate + apply transition |
| 2 | `UP_TRANS` | Upload Evidence | `ICON_IMPORT` | Upload evidence file từ popup |
| 3 | `CANCEL` | Cancel | `ICON_CANCEL` | Close popup, no changes |

Standard: `BACK` (F3 — maps to CANCEL logic), `CANC` (F12)

> **LƯU Ý:** Popup thường chỉ cần CONFIRM + CANCEL. `UP_TRANS` cho phép upload evidence trực tiếp từ popup (vd khi chuyển sang Fixed, cần evidence).

### Title Bar:

Screen này dùng **T_0370** — text = `Change Bug Status`

---

## 7. Transition Matrix — Field Enable/Disable

> Bảng này mô tả chi tiết field nào mở/khóa cho từng current status. Code implement trong `modify_screen_0370` (CODE_F01).

| Current Status | NEW_STATUS (F4 options) | DEV_ID | FTESTER_ID | TRANS_NOTE | UP_TRANS |
|---------------|------------------------|--------|-----------|-----------|---------|
| **1 — New** | 2=Assigned, W=Waiting | **MỞ** (bắt buộc nếu →2) | KHÓA | KHÓA | KHÓA |
| **W — Waiting** | 2=Assigned, 6=Final Testing | **MỞ** (bắt buộc) | **MỞ** (bắt buộc nếu →6) | KHÓA | KHÓA |
| **2 — Assigned** | 3=In Progress, R=Rejected | KHÓA | KHÓA | **MỞ** (bắt buộc nếu →R) | KHÓA |
| **3 — In Progress** | 5=Fixed, 4=Pending, R=Rejected | KHÓA | KHÓA | **MỞ** (ghi giải pháp) | **MỞ** (bắt buộc nếu →5 hoặc →4) |
| **4 — Pending** | 2=Assigned | **MỞ** (bắt buộc, có thể đổi Dev) | KHÓA | KHÓA | KHÓA |
| **6 — Final Testing** | V=Resolved, 3=In Progress | KHÓA | KHÓA | **MỞ** (kết quả test) | KHÓA |

### Ai có quyền cho từng transition:

| Current Status | Manager (M) | Developer (D) | Tester (T) |
|---------------|:-----------:|:-------------:|:----------:|
| 1 — New | ✅ | ❌ | ❌ |
| W — Waiting | ✅ | ❌ | ❌ |
| 2 — Assigned | ✅ | ✅ (nếu là Dev được gán) | ❌ |
| 3 — In Progress | ✅ | ✅ (nếu là Dev được gán) | ❌ |
| 4 — Pending | ✅ | ❌ | ❌ |
| 6 — Final Testing | ✅ | ❌ | ✅ (nếu là Final Tester được gán) |

> **v5.0 CRITICAL:** Manager **KHÔNG** bypass transition rules nữa. Manager cũng phải chọn từ danh sách allowed transitions — chỉ khác là Manager có quyền ở nhiều status hơn.

---

## 8. Validation Logic (khi nhấn Confirm)

Validate theo thứ tự:

1. **New status phải được chọn** — `GV_TRANS_NEW_STATUS` không được trống
2. **Transition hợp lệ** — New status phải nằm trong allowed list theo current status
3. **Role check** — User phải có quyền thực hiện transition này
4. **Required fields:**
   - → Assigned (2): `DEVELOPER_ID` bắt buộc
   - Waiting → Final Testing (6): `DEVELOPER_ID` + `FINAL_TESTER_ID` bắt buộc
   - → Rejected (R): `TRANS_NOTE` bắt buộc (lý do từ chối)
   - → Fixed (5): **Evidence bắt buộc** (SELECT COUNT từ ZBUG_EVIDENCE)
   - → Resolved (V): `TRANS_NOTE` bắt buộc (kết quả test)

> Tất cả message dùng `TYPE 'S' DISPLAY LIKE 'E'` — KHÔNG dùng `TYPE 'E'` để tránh lock screen (Bug 7 fix).

---

## 9. Apply Transition — Sau khi Confirm

```
User nhấn Confirm → validate_status_transition PASS
  │
  ├── Update gs_bug_detail-status = new status
  ├── Update gs_bug_detail-dev_id (nếu có)
  ├── Update gs_bug_detail-verify_tester_id (nếu có)
  │
  ├── Save TRANS_NOTE:
  │     ├── → Rejected: Save vào Dev Note (Text ID Z002)
  │     └── → Resolved hoặc ← Final Testing: Save vào Tester Note (Text ID Z003)
  │
  ├── Update timestamps (aenam, aedat, aezet)
  ├── UPDATE zbug_tracker + COMMIT
  ├── Log history (PERFORM log_history)
  │
  ├── Trigger auto-assign nếu status = Fixed (5):
  │     └── PERFORM auto_assign_tester
  │
  ├── Free CC_TRANS_NOTE container
  └── LEAVE TO SCREEN 0 (close popup)
```

---

## 10. Cách gọi Popup từ Screen 0300

Trong `user_command_0300` (CODE_PAI), thay thế POPUP_GET_VALUES cũ:

```abap
WHEN 'STATUS_CHG'.
  CLEAR gv_trans_confirmed.
  CALL SCREEN 0370 STARTING AT 5 3 ENDING AT 85 22.
  IF gv_trans_confirmed = abap_true.
    " Refresh bug detail + ALV
    gv_detail_loaded = abap_false.
  ENDIF.
```

> **STARTING AT 5 3 ENDING AT 85 22** = popup bắt đầu ở cột 5, dòng 3 → kết thúc ở cột 85, dòng 22 (~80x19).

---

## 11. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| Popup không mở | FCode STATUS_CHG chưa mapped trong Screen 0300 PAI | Verify `user_command_0300` xử lý case 'STATUS_CHG' |
| Editor không hiện | Container name sai | Layout phải có `CC_TRANS_NOTE` khớp code |
| F4 hiện tất cả status | `f4_trans_status` không filter theo current status | Verify CASE logic trong f4_trans_status (CODE_F02) |
| Developer field luôn khóa | Screen Group `TDV` chưa set hoặc `modify_screen_0370` logic sai | Verify Group1 = `TDV` trên field + FORM logic |
| "Cannot create container" sau re-open popup | Container chưa free khi close | Verify `go_cont_trans_note->free()` gọi trong CANCEL + sau CONFIRM |
| Status update nhưng ALV không refresh | `gv_detail_loaded` chưa reset | Verify `gv_detail_loaded = abap_false` sau confirm |
| Manager vẫn bypass rules | Code cũ chưa xóa Manager bypass | Verify `validate_status_transition` KHÔNG có `IF gv_role = 'M' → skip` |
