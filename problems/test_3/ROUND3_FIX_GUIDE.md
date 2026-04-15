# ROUND 3 FIX GUIDE — 6 Bugs

## Tổng quan

| Bug | Mô tả | Fix ở đâu |
|-----|--------|-----------|
| 1 | Upload Excel dump → ẩn nút | CODE_PBO (code) |
| 2 | Notes/Description không lưu | CODE_F02 (code) + **SE75** (config) |
| 3 | Project list filter reset | CODE_PBO (code) |
| 4 | Delete User không chọn được | CODE_F01 (code) + **SE51** Screen 0500 Flow Logic |
| 5 | Description/Note giới hạn ký tự | Liên quan Bug 2 — fix SE75 là xong |
| 6 | UP_REP + UP_FIX dump → ẩn | CODE_PBO + CODE_F01 (code) |

**Code đã sửa xong** trong 3 file:
- `guides/code/CODE_PBO.md`
- `guides/code/CODE_F01.md`
- `guides/code/CODE_F02.md`

**Ngoài code, cần làm thêm 2 việc**:
1. Tạo Text Object ZBUG trong **SE75** (Bug 2 + 5)
2. Sửa Flow Logic Screen 0500 trong **SE51** (Bug 4)

---

## PHẦN 1: SE75 — Tạo Text Object ZBUG

### Tại sao cần làm?

`SAVE_TEXT` và `READ_TEXT` gọi với `object = 'ZBUG'` nhưng text object này **chưa tồn tại** trong hệ thống.
→ `SAVE_TEXT` return `sy-subrc = 4` (silent fail) → text mất khi reload.
→ Đây là root cause của Bug 2 (notes không lưu) và Bug 5 (tưởng bị giới hạn ký tự nhưng thực ra text bị mất).

### Các bước:

1. Vào **SE75** → Enter

2. Ở màn hình đầu, nhìn thấy danh sách Text Objects → nhấn nút **"Change"** (bút chì)

3. Nhấn nút **"New Entry"** (hoặc Ctrl+Shift+F1) để tạo text object mới

4. Điền thông tin:
   ```
   Text Object:    ZBUG
   Description:    Bug Tracking Long Text
   Line width:     132
   ```
   - Line width = 132 vì `tline-tdline` là CHAR 132

5. Nhấn **Enter** → **Save**

6. Khi hỏi **Transport Request** → chọn request phù hợp hoặc tạo mới

7. Sau khi save Text Object, cần tạo **Text IDs**:
   - Ở màn hình SE75, double-click vào object `ZBUG` vừa tạo
   - Hoặc: chọn `ZBUG` → nhấn nút **"Text IDs"**
   - Nhấn **"New Entries"** → tạo 3 dòng:

   | Text ID | Description |
   |---------|-------------|
   | `Z001`  | Bug Description |
   | `Z002`  | Developer Note |
   | `Z003`  | Tester Note |

8. **Save** tất cả

### Verify SE75:

Sau khi tạo xong, có thể check bằng cách:
- SE75 → chọn `ZBUG` → xem Text IDs → phải thấy Z001, Z002, Z003

---

## PHẦN 2: SE51 — Sửa Flow Logic Screen 0500 (Bug 4)

### Tại sao cần làm?

Screen 0500 PAI Flow Logic hiện tại dùng `ON CHAIN-REQUEST`:
```abap
LOOP AT gt_user_project.
  MODULE tc_users_modify ON CHAIN-REQUEST.
ENDLOOP.
```

`ON CHAIN-REQUEST` = module chỉ fire khi user **sửa giá trị field** trong table control.
Nhưng table control fields là **output-only** → module **không bao giờ fire** → `tc_users-current_line` không cập nhật → Remove User luôn xóa dòng đầu hoặc báo lỗi.

### Các bước:

1. **SE51** → Program: `Z_BUG_WORKSPACE_MP` → Screen number: `0500` → nhấn **Change**

2. Nhấn tab **"Flow Logic"** (hoặc nút Flow Logic trên toolbar)

3. Tìm đoạn **PROCESS AFTER INPUT**:
   ```abap
   PROCESS AFTER INPUT.
     LOOP AT gt_user_project.
       MODULE tc_users_modify ON CHAIN-REQUEST.
     ENDLOOP.
     MODULE user_command_0500.
   ```

4. **Xóa** `ON CHAIN-REQUEST` → sửa thành:
   ```abap
   PROCESS AFTER INPUT.
     LOOP AT gt_user_project.
       MODULE tc_users_modify.
     ENDLOOP.
     MODULE user_command_0500.
   ```

5. **Ctrl+S** (Save) → **Ctrl+F3** (Activate)

### Kết quả:

- Module `tc_users_modify` sẽ fire **mỗi lần PAI chạy** (khi user bấm bất kỳ nút nào)
- `tc_users-current_line` cập nhật đúng dòng user đang click
- Remove User sẽ xóa đúng user được chọn

---

## PHẦN 2: Deploy Code

### Thứ tự paste + activate (quan trọng):

```
1. Z_BUG_WS_F02   (CODE_F02)  — helpers, long text
2. Z_BUG_WS_F01   (CODE_F01)  — main business logic
3. Z_BUG_WS_PBO   (CODE_PBO)  — PBO modules
4. Z_BUG_WORKSPACE_MP          — main program (activate lại)
```

### Cho mỗi include:

1. **SE38** → nhập tên include (vd: `Z_BUG_WS_F02`) → **Change**
2. **Ctrl+A** (select all) → **Delete** (xóa sạch code cũ)
3. Copy toàn bộ nội dung từ file tương ứng trong `guides/code/`
4. **Paste** vào editor
5. **Ctrl+S** (Save)
6. **Ctrl+F3** (Activate)
7. Nếu hỏi Transport Request → chọn request

### Sau khi paste hết 3 includes:

- SE38 → `Z_BUG_WORKSPACE_MP` → **Activate**

---

## PHẦN 3: Test

Chạy `/nZBUG_WS` và test:

| # | Test case | Expected |
|---|-----------|----------|
| 1 | Screen 0400 (Project List) | **Không thấy** nút Upload + Download Template |
| 2 | Screen 0300 (Bug Detail) | **Không thấy** nút UP_REP + UP_FIX. Nút UP_FILE vẫn có |
| 3 | Mở bug → tab Description → gõ text → Save → BACK → mở lại | Text **còn nguyên** (chỉ pass sau khi SE75 xong) |
| 4 | Mở bug → tab Dev Note → gõ text → Save → BACK → mở lại | Text **còn nguyên** |
| 5 | Screen 0410 → search → vào 0400 → vào 0200 → BACK | Project list **giữ nguyên** filter, không hiện full |
| 6 | Screen 0500 → click vào 1 user row → bấm Remove User | Popup confirm hiện ra, delete thành công |

### Nếu test #3/#4 vẫn fail:

- Kiểm tra SE75 đã tạo đúng chưa: object = `ZBUG`, text IDs = Z001/Z002/Z003
- Kiểm tra message bar: sau khi Save bug, nếu thấy warning
  `"Long text Z001 save failed (RC=4). Check text object ZBUG in SE75."`
  → SE75 chưa config đúng

---

## Tóm tắt thay đổi code

### CODE_PBO — 3 chỗ sửa:

**1. `MODULE status_0400`** (Bug 1):
```abap
" TRƯỚC: UPLOAD + DN_TMPL chỉ exclude cho non-Manager
" SAU:   Exclude unconditionally (trước IF block)
APPEND 'UPLOAD'   TO gm_excl.
APPEND 'DN_TMPL'  TO gm_excl.
```

**2. `MODULE status_0300`** (Bug 6):
```abap
" TRƯỚC: UP_REP/UP_FIX exclude theo role (T/D) + mode
" SAU:   Exclude unconditionally ngay đầu module
APPEND 'UP_REP' TO gm_excl.
APPEND 'UP_FIX' TO gm_excl.
" Xóa các IF blocks cũ cho role T/D liên quan UP_REP/UP_FIX
```

**3. `MODULE init_project_list`** (Bug 3):
```abap
" TRƯỚC: ELSE → gọi select_project_data mỗi lần quay lại
" SAU:   ELSEIF go_alv_project IS INITIAL → chỉ load lần đầu
IF gv_from_search = abap_true.
  CLEAR gv_from_search.
ELSEIF go_alv_project IS INITIAL.
  PERFORM select_project_data.
ENDIF.
```

### CODE_F01 — 2 chỗ sửa:

**4. `FORM remove_user_from_project`** (Bug 4):
```abap
" TRƯỚC: Check gv_tc_user_selected flag (never set vì ON CHAIN-REQUEST)
" SAU:   Xóa guard check. Range check vẫn giữ (line 579)
```

**5. `FORM upload_evidence`** (Bug 6 defensive):
```abap
" TRƯỚC: lv_fname_only(100)  → dump khi filename < 100 chars
" SAU:   lv_fname_only       → ABAP auto-truncate to CHAR 100
```

### CODE_F02 — 2 chỗ sửa:

**6. `FORM save_long_text`** (Bug 2):
```abap
" TRƯỚC: Không check sy-subrc sau SAVE_TEXT
" SAU:   Thêm IF sy-subrc <> 0 → warning message
```

**7. `FORM save_long_text_direct`** (Bug 2):
```abap
" Tương tự — thêm sy-subrc check + warning message
```

---

## PHẦN 4: NEW FEATURE — Project Description/Note Editors (Screen 0500)

### Mô tả

Thay thế I/O fields `GS_PROJECT-DESCRIPTION` và `GS_PROJECT-NOTE` trên Screen 0500 bằng **CL_GUI_TEXTEDIT** multi-line editors. Giống như Bug Description trên Screen 0310.

> **DB limit vẫn CHAR 255** — editors chỉ cải thiện UX (multi-line typing), không thay đổi storage.

### Code changes (đã sửa trong 4 files):

| File | Thay đổi |
|------|----------|
| `CODE_TOP.md` | +4 global vars: `go_cont_prj_desc`, `go_edit_prj_desc`, `go_cont_prj_note`, `go_edit_prj_note` |
| `CODE_PBO.md` | +`MODULE init_prj_editors` (tạo editors, load text, set readonly). `modify_screen_0500` thêm hide old I/O fields |
| `CODE_F01.md` | +`FORM read_prj_editor_to_field` (đọc text từ editors → work area). +`FORM cleanup_prj_editors` (free containers). `save_project_detail` gọi read trước validate. `check_unsaved_prj` gọi read trước compare |
| `CODE_PAI.md` | `user_command_0500` BACK/CANC/EXIT gọi `cleanup_prj_editors` trước leave |

### SE51 changes cần làm trên Screen 0500:

**A. Thêm 2 Custom Controls:**

1. SE51 → Program `Z_BUG_WORKSPACE_MP` → Screen `0500` → Change → Layout
2. Tạo Custom Control → Name: **`CC_PRJ_DESC`** → đặt ở vị trí Description field
3. Tạo Custom Control → Name: **`CC_PRJ_NOTE`** → đặt ở vị trí Note field
4. I/O fields `GS_PROJECT-DESCRIPTION` và `GS_PROJECT-NOTE` **giữ nguyên** (code tự hide)
5. Save + Activate

**B. Thêm module `init_prj_editors` vào Flow Logic PBO:**

Flow Logic cuối cùng phải là:
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
```

> Chi tiết hướng dẫn SE51: xem `guides/screens/screen-0500-project-detail.md` section 3.

### Deploy order (bao gồm cả bug fixes):

```
1. SE75  → Tạo text object ZBUG + 3 Text IDs (nếu chưa xong)
2. SE38  → Paste CODE_TOP  (Z_BUG_WS_TOP)   → Save → Activate
3. SE38  → Paste CODE_F02  (Z_BUG_WS_F02)   → Save → Activate
4. SE38  → Paste CODE_F01  (Z_BUG_WS_F01)   → Save → Activate
5. SE38  → Paste CODE_PBO  (Z_BUG_WS_PBO)   → Save → Activate
6. SE38  → Paste CODE_PAI  (Z_BUG_WS_PAI)   → Save → Activate
7. SE38  → Z_BUG_WORKSPACE_MP               → Activate
8. SE51  → Screen 0500 Flow Logic            → Sửa (add init_prj_editors + remove ON CHAIN-REQUEST)
9. SE51  → Screen 0500 Layout                → Tạo CC_PRJ_DESC + CC_PRJ_NOTE
10. SE51 → Save + Activate Screen 0500
```

### Test mới (sau deploy):

| # | Test case | Expected |
|---|-----------|----------|
| 7 | Screen 0500 (Change mode) | Thấy 2 multi-line editors cho Description + Note |
| 8 | Gõ text vào Description editor → Save → BACK → mở lại | Text **còn nguyên** |
| 9 | Gõ text vào Note editor → Save → BACK → mở lại | Text **còn nguyên** |
| 10 | Non-Manager vào Display Project | Editors hiện text nhưng **readonly** (không gõ được) |
| 11 | Create Project → gõ Name + Description + Note → Save | Project tạo thành công, text lưu đúng |
