# Bug Analysis — Z_BUG_WORKSPACE_MP v4.0

> **Ngày phân tích:** 11/04/2026
> **Screenshots:** `1.png` → `6.png` (cùng thư mục)
> **Status:** Phân tích xong, đang cập nhật code guides

---

## Bug 1 (1.png) — Project Create: No Auto-ID + Empty Table Control

### Triệu chứng
- Mở Screen 0500 ở **Create mode** → field PROJECT_ID **trống**, user phải nhập tay
- Phía dưới có cái **"ô nhỏ"** = Table Control `TC_USERS` hiện trống, không có column headers

### Root Cause
1. **PROJECT_ID trống:** FORM `save_project_detail` (CODE_F01.md line 221) **KHÔNG** auto-generate PROJECT_ID — khác với BUG_ID có auto-gen (`BUG` + 7 digits). Hiện tại code validate `IF gs_project-project_id IS INITIAL → error`, nghĩa là user BẮT BUỘC nhập tay.
2. **TC_USERS trống + no headers:** Đây là Table Control `TC_USERS`. Ở Create mode, `gt_user_project` rỗng (đúng — project chưa save, chưa có users). Nhưng column headers phải hiện dù trống data. Nguyên nhân: trong SE51 Layout, checkbox **"With Column Headers"** chưa được check cho TC_USERS.

### Fix
1. **Auto-gen PROJECT_ID:** Thêm logic `MAX(project_id) + 1` vào `save_project_detail` (trước validation block), tương tự BUG_ID auto-gen. Format: `PRJ` + 7-digit number → `PRJ0000001`.
2. **PBO placeholder:** Trong `init_project_detail` Create mode, set `gs_project-project_id = '(Auto)'` để user biết ID sẽ tự sinh.
3. **Always display-only:** Tạo screen group mới **`PID`** cho PROJECT_ID field. Logic `modify_screen_0500`: **luôn** `screen-input = 0` (user không bao giờ nhập tay PROJECT_ID).
4. **TC_USERS headers:** Trong SE51 → double-click TC_USERS → check **"With Column Headers"** ✅.
5. **Hide ADD_USER/REMO_USR ở Create mode:** Project chưa save → `gv_current_project_id` trống → add user sẽ fail. Exclude 2 buttons trong `status_0500` khi `gv_mode = gc_mode_create`.

### Files cần sửa
- `CODE_PBO.md`: `init_project_detail` (line 501), `modify_screen_0500` (line 524), `status_0500` (line 462)
- `CODE_F01.md`: `save_project_detail` (line 221)
- `UI_SCREEN_0500.md`: GROUP1 cho PROJECT_ID = `PID`, TC_USERS headers

---

## Bug 2 (2.png) — Add User: "Internal error: Table..."

### Triệu chứng
- Khi bấm nút **Add User** → popup POPUP_GET_VALUES hiện ra
- Bấm F4 (search help) cho field **ROLE** → SAP báo lỗi `Internal error: Table...`

### Root Cause
Trong FORM `add_user_to_project` (CODE_F01.md line 536), field ROLE được khai báo:
```abap
ls_field-tabname   = 'ZBUG_USER_PROJEC'.
ls_field-fieldname = 'ROLE'.
```
Khi user bấm F4, SAP cố tìm Search Help cho domain `ZDE_BUG_ROLE` (CHAR 1) → nhưng domain này KHÔNG có Fixed Values hoặc Search Help → SAP cố resolve bằng DDIC → **crash internal error**.

Ngoài ra, nếu `gv_current_project_id IS INITIAL` (Create mode), INSERT sẽ fail vì primary key trống.

### Fix
1. **Đổi ROLE field:** Dùng `tabname = space`, `fieldname = 'P_ROLE'` (không reference DDIC → không trigger F4 search help → không crash).
2. **Thêm validation text:** Đổi `fieldtext` thành `'Role (M/D/T)'` — ngắn gọn, user biết giá trị hợp lệ.
3. **Validate ROLE value:** Sau khi user nhập, check `lv_role = 'M' OR 'D' OR 'T'`, nếu sai → message warning.
4. **Check project saved:** Thêm `IF gv_current_project_id IS INITIAL → message 'Save project first'`.

### Files cần sửa
- `CODE_F01.md`: `add_user_to_project` (line 536)

---

## Bug 3 (3.png) — TC_USERS No Headers + Project ID Editable

### Triệu chứng
- Table Control `TC_USERS` hiện data nhưng **KHÔNG có column headers** (User ID, Role, Created By, Created On)
- Field **PROJECT_ID** đang **editable** trong Change mode → user có thể sửa primary key!

### Root Cause
1. **No headers:** SE51 Layout → TC_USERS checkbox **"With Column Headers"** chưa check.
2. **PROJECT_ID editable:** PROJECT_ID có Group1 = `EDT` → Change mode: `screen-input = 1`. Nhưng PROJECT_ID là **primary key** — KHÔNG BAO GIỜ được sửa sau khi tạo.

### Fix
1. **SE51:** Double-click TC_USERS → Attributes → check **"With Column Headers"** ✅.
2. **Screen group:** Đổi PROJECT_ID Group1 từ `EDT` sang **`PID`**. Code `modify_screen_0500` thêm: Group `PID` → **always** `screen-input = 0`.

### Files cần sửa
- `CODE_PBO.md`: `modify_screen_0500` (line 524)
- `UI_SCREEN_0500.md`: GROUP1 table, TC headers note

---

## Bug 4 (4.png) — Upload Excel: CALL_FUNCTION_CONFLICT_TYPE

### Triệu chứng
- Bấm Upload trên Screen 0400 (Project List) → chọn file Excel → SAP dump **CALL_FUNCTION_CONFLICT_TYPE**

### Root Cause
FORM `upload_project_excel` (CODE_F01.md line 1307) gọi FM `TEXT_CONVERT_XLS_TO_SAP`:
```abap
CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
  EXPORTING
    i_tab_raw_data    = lt_raw      " ← SAI! Đây là CHANGING parameter
    i_filename        = lv_file
  ...
```
Parameter `i_tab_raw_data` là **CHANGING** (read/write), nhưng code đặt nó trong **EXPORTING** block (read-only) → SAP runtime error `CALL_FUNCTION_CONFLICT_TYPE`.

### Fix
Di chuyển `i_tab_raw_data = lt_raw` từ **EXPORTING** sang **CHANGING** block:
```abap
CALL FUNCTION 'TEXT_CONVERT_XLS_TO_SAP'
  EXPORTING
    i_field_seperator    = 'X'
    i_line_header        = 'X'
    i_filename           = lv_file
  TABLES
    i_tab_converted_data = lt_upload
  CHANGING
    i_tab_raw_data       = lt_raw
  EXCEPTIONS
    conversion_failed    = 1
    OTHERS               = 2.
```

### Files cần sửa
- `CODE_F01.md`: `upload_project_excel` (line 1307)

---

## Bug 5 (5.png) — Create Bug: No Auto-ID + No F4 Help Dropdowns

### Triệu chứng
1. Mở Screen 0300 ở Create mode → **BUG_ID trống**, user phải nhập tay (tương tự Bug 1)
2. Fields STATUS, SEVERITY, BUG_TYPE **KHÔNG có F4 help** → user phải đoán giá trị code ("1", "2", etc.) rồi bấm Enter

### Root Cause
1. **BUG_ID editable ở Create mode:** Screen group `BID` logic (CODE_PBO.md line 248):
   ```abap
   IF gv_mode <> gc_mode_create.
     screen-input = 0.
   ENDIF.
   ```
   Ở Create mode, `BID` group KHÔNG bị disable → field editable → user nghĩ phải nhập tay. Thực ra BUG_ID sẽ auto-gen khi save, nhưng UX confusing.

2. **Không có F4 help:** Screen 0310 flow logic **THIẾU hoàn toàn `PROCESS ON VALUE-REQUEST` section**. Các FORM f4_status, f4_priority, f4_bug_type, f4_severity, f4_project_id, f4_user_id đã tồn tại trong CODE_F02.md, nhưng **chưa có POV modules** trong CODE_PAI.md và **chưa connected** trong screen flow logic.

### Fix
1. **BUG_ID always display-only:** Đổi `BID` group logic thành: **LUÔN** `screen-input = 0` (xóa điều kiện `IF gv_mode <> gc_mode_create`). Ở Create mode hiện "(Auto)", ở Change/Display hiện BUG_ID thật.
2. **PBO placeholder:** Trong `load_bug_detail` Create mode, thêm `gs_bug_detail-bug_id = '(Auto)'.`
3. **Add 8 POV modules** trong CODE_PAI.md: `f4_bug_status`, `f4_bug_priority`, `f4_bug_severity`, `f4_bug_type`, `f4_bug_project`, `f4_bug_tester`, `f4_bug_dev`, `f4_bug_verify`.
4. **Add PROCESS ON VALUE-REQUEST** section vào Screen 0310 flow logic.

### Files cần sửa
- `CODE_PBO.md`: `load_bug_detail` (line 178), `modify_screen_0300` (line 248)
- `CODE_PAI.md`: Thêm 8 POV modules
- `UI_SCREEN_0300_SUBSCREENS.md`: Screen 0310 flow logic (thêm POV)

---

## Bug 6 (6.png) — Create Bug Save: POTENTIAL_DATA_LOSS Runtime Error

### Triệu chứng
- Tạo bug mới → bấm Save → SAP dump **POTENTIAL_DATA_LOSS**
- Error từ class `CL_GUI_TEXTEDIT`

### Root Cause
FORM `save_desc_mini_to_workarea` (CODE_F01.md line 204) gọi:
```abap
go_desc_mini_edit->get_text_as_r3table( IMPORTING table = lt_mini ).
```
**KHÔNG có `cl_gui_cfw=>flush()`** trước khi đọc text → CL_GUI_TEXTEDIT raises exception `POTENTIAL_DATA_LOSS` vì text data chưa được flush từ frontend GUI control sang backend.

Tương tự, `set_text_as_r3table` trong `init_desc_mini` (CODE_PBO.md line 308) và `load_long_text` / `save_long_text` (CODE_F02.md) cũng thiếu EXCEPTIONS handling.

### Fix
1. **Flush trước get:** Thêm `cl_gui_cfw=>flush( ).` trước `get_text_as_r3table()`.
2. **Add EXCEPTIONS:** Thêm `EXCEPTIONS error_dp = 1 error_dp_create = 2 OTHERS = 3` cho cả `set_text_as_r3table` và `get_text_as_r3table`.
3. **Apply to all text operations:**
   - `save_desc_mini_to_workarea` (CODE_F01.md line 208)
   - `init_desc_mini` (CODE_PBO.md line 308)
   - `load_long_text` (CODE_F02.md line 264)
   - `save_long_text` (CODE_F02.md line 287)

### Files cần sửa
- `CODE_F01.md`: `save_desc_mini_to_workarea` (line 204)
- `CODE_PBO.md`: `init_desc_mini` (line 308)
- `CODE_F02.md`: `load_long_text` (line 264), `save_long_text` (line 287)

---

## Tổng hợp — Files cần cập nhật

| File | Thay đổi |
|------|---------|
| **CODE_PBO.md** | Bug 1: `init_project_detail` add "(Auto)", `modify_screen_0500` add PID group, `status_0500` exclude buttons in Create mode. Bug 5: `load_bug_detail` add "(Auto)", `modify_screen_0300` BID always display-only. Bug 6: `init_desc_mini` add EXCEPTIONS |
| **CODE_PAI.md** | Bug 5: Add 8 POV modules for Screen 0310 F4 help. Bug 1: Add 2 POV modules for Screen 0500 (project_status, project_manager) |
| **CODE_F01.md** | Bug 1: `save_project_detail` add auto-gen PROJECT_ID. Bug 2: `add_user_to_project` fix ROLE field + add project_id check + validate M/D/T. Bug 4: `upload_project_excel` move i_tab_raw_data to CHANGING. Bug 6: `save_desc_mini_to_workarea` add flush + EXCEPTIONS |
| **CODE_F02.md** | Bug 5: Add `f4_project_status` FORM. Bug 6: `load_long_text` + `save_long_text` add flush/EXCEPTIONS |
| **UI_SCREEN_0300_SUBSCREENS.md** | Bug 5: Screen 0310 flow logic add PROCESS ON VALUE-REQUEST |
| **UI_SCREEN_0500.md** | Bug 1+3: PROJECT_ID Group1 = PID, TC_USERS "With Column Headers", add POV for project_status + project_manager |
