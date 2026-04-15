# Phân Tích Bug & Hướng Sửa Chi Tiết — Z_BUG_WORKSPACE_MP

> Phân tích dựa trên:  
> - Bug report khách hàng: `update/BUG_Report.md`  
> - Ảnh minh họa: `testfile1_images/` (12 screenshots từ SAP)  
> - Source code: `analysis/guides/CODE_*.md`  
> - Cấu trúc bảng: `analysis/guides/verify-notes/table-fields.md`  
> - Kiến trúc: `analysis/guides/context.md`

---

## Tổng quan nhanh

| Bug # | Mô tả ngắn | Severity | File cần sửa |
|-------|-----------|----------|--------------|
| 1 & 9 | Short dump khi mở tab Description / Dev Note / Tester Note | 🔴 CRITICAL | `CODE_F02.md` |
| 2 | Ô Description quá nhỏ | 🟡 MEDIUM | SE51 Screen 0310 |
| 3 | Description giới hạn ký tự/dòng | 🟡 MEDIUM | `CODE_F01.md` |
| 4 | Hiển thị text thiếu/bị cắt ở một số trường | 🟠 HIGH | SE51 Screen 0310 |
| 5 | Remove User không cần chọn user vẫn xóa được | 🟠 HIGH | `CODE_F01.md` |
| 6a | Status không bị khóa = 1 trong Create mode | 🟠 HIGH | `CODE_PBO.md` |
| 6b | SAP Module không có Search Help (F4) | 🟡 MEDIUM | `CODE_F02.md` + `CODE_PAI.md` + SE51 |
| 6c | Không có nút Upload Evidence trên Create Bug | 🟡 MEDIUM | `CODE_PBO.md` |
| 6d | Created Date có thể nhập tay | 🟡 MEDIUM | SE51 Screen 0310 |
| 7 | Sau validation error các field bị khóa | 🟠 HIGH | `CODE_F01.md` |
| 8 | Description biến mất khi xem chi tiết bug | 🟠 HIGH | `CODE_F01.md` |
| 10 | Có thể đổi status từ 3 → 1 không có cảnh báo | 🟠 HIGH | `CODE_F01.md` |
| 11 | Đổi status không cần evidence | 🔴 CRITICAL | SE11 + `CODE_F01.md` |

---

## Bug 1 & 9 — SHORT DUMP khi nhấn tab Description / Dev Note / Tester Note

### Triệu chứng
- Ảnh minh họa: `runtime-error-read-text-type-conflict-115802.png`, `runtime-error-read-text-type-conflict-123322.png`
- Runtime Error: `CALL_FUNCTION_CONFLICT_TYPE`
- Exception: `CX_SY_DYN_CALL_ILLEGAL_TYPE`
- Xảy ra trong procedure `LOAD_LONG_TEXT (FORM)` khi gọi FM `READ_TEXT`

### Root Cause
Trong `CODE_F02.md` → `FORM load_long_text`:

```abap
CALL FUNCTION 'READ_TEXT'
  EXPORTING
    name = gv_current_bug_id   " ← LỖI Ở ĐÂY
    ...
```

- `gv_current_bug_id` khai báo `TYPE zde_bug_id` = **CHAR 10** (per `table-fields.md`)
- Tham số `NAME` của FM `READ_TEXT` kỳ vọng kiểu `THEAD-TDNAME` = **CHAR 70**
- ABAP 7.70 strict type checking → dump `CALL_FUNCTION_CONFLICT_TYPE`

### Fix — `CODE_F02.md` (FORM load_long_text)

**Thêm biến trung gian `lv_tdname TYPE thead-tdname` trước khi gọi READ_TEXT:**

```abap
FORM load_long_text USING pv_text_id TYPE thead-tdid.
  CHECK gv_current_bug_id IS NOT INITIAL.

  DATA: lr_editor TYPE REF TO cl_gui_textedit.
  CASE pv_text_id.
    WHEN 'Z001'. lr_editor = go_edit_desc.
    WHEN 'Z002'. lr_editor = go_edit_dev_note.
    WHEN 'Z003'. lr_editor = go_edit_tstr_note.
  ENDCASE.
  CHECK lr_editor IS NOT INITIAL.

  DATA: lt_lines TYPE TABLE OF tline,
        ls_line  TYPE tline,
        lv_tdname TYPE thead-tdname.    " ← THÊM DÒNG NÀY

  lv_tdname = gv_current_bug_id.       " ← THÊM DÒNG NÀY (CHAR 10 → CHAR 70: safe)

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id       = pv_text_id
      language = sy-langu
      name     = lv_tdname             " ← ĐỔI từ gv_current_bug_id
      object   = 'ZBUG'
    TABLES
      lines    = lt_lines
    EXCEPTIONS
      OTHERS   = 4.
  ...
ENDFORM.
```

**Cũng kiểm tra `save_long_text`** — phần `ls_header-tdname = gv_current_bug_id` gán vào struct THEAD thì OK (ABAP tự widening CHAR→CHAR), nhưng nên đổi cho đồng nhất:

```abap
DATA: ls_header TYPE thead.
ls_header-tdobject = 'ZBUG'.
ls_header-tdname   = gv_current_bug_id.   " OK — THEAD-TDNAME CHAR 70, gán từ CHAR 10
```

→ Dòng này không cần sửa vì đây là assignment vào struct field (không phải EXPORTING parameter trực tiếp).

---

## Bug 2 — Ô nhập Description quá nhỏ, không riêng biệt

### Triệu chứng
Mini editor `CC_DESC_MINI` trên subscreen 0310 chỉ hiển thị 3–4 dòng.

### Root Cause
Đây là UX Decision #8 trong `context.md`: "Description mini editor (cl_gui_textedit, 3-4 dòng) trên Bug Info tab (0310)". Khách muốn box lớn hơn.

### Fix — SE51 (Screen 0310)
Trong SE51, mở Screen 0310, tìm Custom Control `CC_DESC_MINI`:
- Tăng chiều cao của container lên 8–12 dòng (đủ để nhập mô tả vừa phải)
- Hoặc: xóa mini editor, thêm field `GS_BUG_DETAIL-DESC_TEXT` dạng TEXTEDIT với `VISIBLE LENGTH` lớn hơn

**Phương án tốt hơn (không cần mini editor):** Trên 0310, thay `CC_DESC_MINI` bằng field thông thường:
```
GS_BUG_DETAIL-DESC_TEXT  SCRFNAME  (output length 70, visible rows 5)
```
Đổi `init_desc_mini` trong `CODE_PBO.md` để không tạo GUI control nữa, đọc/ghi trực tiếp qua screen field. Điều này cũng giải quyết Bug 8.

---

## Bug 3 — Description bị giới hạn ký tự

### Triệu chứng
Khách không thể nhập quá X ký tự trong Description.

### Root Cause
Trong `CODE_F01.md` → `save_desc_mini_to_workarea`:
```abap
DATA: lt_mini TYPE TABLE OF char255.
go_desc_mini_edit->get_text_as_r3table( IMPORTING table = lt_mini ... )
```

- Mỗi dòng trong `TABLE OF char255` tối đa **255 ký tự/dòng**
- Nếu khách nhập 1 đoạn liên tục không xuống dòng mà dài hơn 255 ký tự → bị cắt

### Fix — `CODE_F01.md` (save_desc_mini_to_workarea)

Dùng method `get_text_as_stream` để lấy toàn bộ text dạng string liên tục thay vì bảng dòng 255:

```abap
FORM save_desc_mini_to_workarea.
  CHECK go_desc_mini_edit IS NOT INITIAL.

  cl_gui_cfw=>flush( ).

  " Phương án: get raw text as one string
  DATA: lv_text TYPE string.
  go_desc_mini_edit->get_text_as_stream(
    IMPORTING text = lv_text
    EXCEPTIONS OTHERS = 3 ).
  IF sy-subrc = 0.
    gs_bug_detail-desc_text = lv_text.
  ELSE.
    " Fallback: dùng r3table như cũ
    DATA: lt_mini TYPE TABLE OF char255.
    go_desc_mini_edit->get_text_as_r3table(
      IMPORTING table = lt_mini
      EXCEPTIONS OTHERS = 3 ).
    IF sy-subrc = 0.
      CLEAR lv_text.
      LOOP AT lt_mini INTO DATA(lv_line).
        IF lv_text IS NOT INITIAL.
          lv_text &&= cl_abap_char_utilities=>cr_lf && lv_line.
        ELSE.
          lv_text = lv_line.
        ENDIF.
      ENDLOOP.
      gs_bug_detail-desc_text = lv_text.
    ENDIF.
  ENDIF.
ENDFORM.
```

> **Lưu ý:** `DESC_TEXT` trong `ZBUG_TRACKER` là kiểu STRING (per table-fields.md dòng 4) nên không có giới hạn DB. Vấn đề chỉ ở bước đọc từ GUI control.

---

## Bug 4 — Hiển thị text bị thiếu/cắt ở một số trường

### Triệu chứng
Một số trường như Status, Bug Type, Severity, Priority hiển thị trống hoặc bị cắt ngắn trên screen.

### Root Cause
`compute_bug_display_texts` ghi vào các biến:
- `gv_status_disp TYPE char20` — "In Progress" = 11 ký tự ✅
- `gv_priority_disp TYPE char10` — "Medium" = 6 ký tự ✅
- `gv_severity_disp TYPE char20` — "Dump/Critical" = 13 ký tự ✅
- `gv_bug_type_disp TYPE char20` — "Functional" = 10 ký tự ✅

Nhưng nếu trong **SE51 Screen 0310** các field được khai báo với `OUTPUT LENGTH` nhỏ hơn giá trị thực → text bị cắt và trông như "thiếu".

Ví dụ: nếu field `GV_STATUS_DISP` trên screen được đặt `VIS LEN = 8` thì "In Progress" chỉ hiện "In Progr".

### Fix — SE51 (Screen 0310)

| Biến toàn cục | Giá trị dài nhất | Độ dài tối thiểu cần set trên screen |
|--------------|-----------------|--------------------------------------|
| `GV_STATUS_DISP` | "In Progress" = 11 | ≥ 15 |
| `GV_PRIORITY_DISP` | "Medium" = 6 | ≥ 10 |
| `GV_SEVERITY_DISP` | "Dump/Critical" = 13 | ≥ 15 |
| `GV_BUG_TYPE_DISP` | "Integration" = 11 | ≥ 15 |
| `GV_PRJ_STATUS_DISP` | "In Process" = 10 | ≥ 12 |

Trong SE51: chọn từng field → Layout → tăng `VIS LEN` và `OUTPUT LEN` cho phù hợp.

---

## Bug 5 — Nhấn "Remove User" không chọn user vẫn xóa

### Triệu chứng
- Ảnh: `change-project-remove-user-confirm.png` — popup hỏi xóa DEV-061 dù người dùng chưa click chọn dòng nào
- `tc_users-current_line` trả về 1 (dòng đầu tiên) kể cả khi user không click vào dòng nào

### Root Cause
Trong `CODE_F01.md` → `FORM remove_user_from_project`:
```abap
lv_line = tc_users-current_line.
IF lv_line = 0.
  MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
ENDIF.
```

`tc_users-current_line` trong ABAP Table Control mặc định = 1 khi bảng có dữ liệu (không = 0 trừ khi bảng rỗng). Nên check `lv_line = 0` không bao giờ trigger được.

### Fix — `CODE_F01.md` (FORM remove_user_from_project)

**Thêm cơ chế theo dõi user có thực sự click không**, dùng một biến flag:

Thêm vào `CODE_TOP.md`:
```abap
DATA: gv_tc_user_selected TYPE abap_bool.  " True = user clicked a row in TC_USERS
```

Trong `CODE_PAI.md` → `MODULE tc_users_modify INPUT`, cập nhật flag:
```abap
MODULE tc_users_modify INPUT.
  MODIFY gt_user_project FROM gs_user_project INDEX tc_users-current_line.
  gv_tc_user_selected = abap_true.  " ← User đã interact với table control
ENDMODULE.
```

Trong `CODE_F01.md` → `FORM remove_user_from_project`:
```abap
FORM remove_user_from_project.
  " Kiểm tra user có thực sự chọn dòng
  IF gv_tc_user_selected = abap_false OR gt_user_project IS INITIAL.
    MESSAGE 'Please click on a user row to select it first.' TYPE 'W'. RETURN.
  ENDIF.
  CLEAR gv_tc_user_selected.  " Reset flag sau khi dùng

  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.
  IF lv_line = 0. RETURN. ENDIF.

  READ TABLE gt_user_project INTO gs_user_project INDEX lv_line.
  IF sy-subrc <> 0.
    MESSAGE 'Invalid selection.' TYPE 'W'. RETURN.
  ENDIF.

  " Popup confirm (đã có — hiển thị tên user sẽ bị xóa)
  DATA: lv_confirmed TYPE abap_bool, lv_msg TYPE string.
  lv_msg = |Remove user { gs_user_project-user_id } from project?|.
  PERFORM confirm_action USING lv_msg CHANGING lv_confirmed.
  CHECK lv_confirmed = abap_true.
  ...
ENDFORM.
```

Cũng thêm vào PBO `MODULE init_project_detail` (hoặc `MODULE status_0500`):
```abap
CLEAR gv_tc_user_selected.  " Reset mỗi lần vào màn Project Detail
```

---

## Bug 6a — Status không bị khóa = 1 (New) khi Create Bug

### Triệu chứng
- Ảnh: `create-bug-bug-info-status-3-no-upload.png` — Status = 3 trong khi tạo bug
- Người dùng có thể gõ/chọn bất kỳ status nào khi tạo bug mới

### Root Cause
Trong `CODE_PBO.md` → `modify_screen_0300`:
- Trường STATUS được gán group `EDT` → editable trong Create mode
- Không có logic khóa STATUS = 1 trong Create mode

### Fix — `CODE_PBO.md` (modify_screen_0300)

**Bước 1:** Trong SE51 Screen 0310, gán thêm group thứ 2 `STA` (ngoài `EDT`) cho field `GS_BUG_DETAIL-STATUS`.

**Bước 2:** Thêm vào `modify_screen_0300`:
```abap
" STATUS: locked in Create mode (must always start as New = '1')
IF screen-group2 = 'STA'.
  IF gv_mode = gc_mode_create.
    screen-input = 0.
  ENDIF.
  MODIFY SCREEN.
ENDIF.
```

**Bước 3:** Đảm bảo `load_bug_detail` (trong Create mode) đặt:
```abap
gs_bug_detail-status = gc_st_new.  " '1' = New — đã có trong code ✅
```

---

## Bug 6b — SAP Module không có Search Help (F4)

### Triệu chứng
Nhấn F4 tại field SAP Module → không có popup gợi ý giá trị.

### Root Cause
Không có FORM `f4_sap_module` trong code, không có POV module trong flow logic Screen 0310.

### Fix 3 bước:

**Bước 1:** Thêm vào `CODE_F02.md`:
```abap
*&=== F4: SAP MODULE ===*
FORM f4_sap_module USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mod_f4,
           code TYPE zde_sap_module,
           text TYPE char40,
         END OF ty_mod_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mod_f4.

  APPEND VALUE ty_mod_f4( code = 'FI'    text = 'Financial Accounting' ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'MM'    text = 'Materials Management' ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'SD'    text = 'Sales & Distribution'  ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'PP'    text = 'Production Planning'   ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'HR'    text = 'Human Resources'       ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'ABAP'  text = 'ABAP Development'      ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'BASIS' text = 'SAP Basis'             ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'CO'    text = 'Controlling'           ) TO lt_val.
  APPEND VALUE ty_mod_f4( code = 'PS'    text = 'Project System'        ) TO lt_val.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CODE'
      dynpprog        = sy-repid
      dynpnr          = sy-dynnr
      dynprofield     = pv_fn
      value_org       = 'S'
    TABLES
      value_tab       = lt_val
      return_tab      = lt_ret
    EXCEPTIONS
      OTHERS          = 1.
ENDFORM.
```

**Bước 2:** Thêm vào `CODE_PAI.md`:
```abap
MODULE f4_bug_sap_module INPUT.
  PERFORM f4_sap_module USING 'GS_BUG_DETAIL-SAP_MODULE'.
ENDMODULE.
```

**Bước 3:** Trong SE51 → Screen 0310 → Flow Logic, thêm vào `PROCESS ON VALUE-REQUEST`:
```
FIELD gs_bug_detail-sap_module MODULE f4_bug_sap_module.
```

---

## Bug 6c — Không có nút "Upload Evidence" trên màn hình Create Bug

### Triệu chứng
Khi tạo bug mới (Create mode), nút Upload Evidence (UP_FILE) bị ẩn.

### Root Cause
Trong `CODE_PBO.md` → `status_0300`, Create mode exclusions:
```abap
IF gv_mode = gc_mode_create.
  APPEND 'STATUS_CHG' TO gm_excl.
  APPEND 'UP_FILE'    TO gm_excl.   " ← Ẩn Upload Evidence
  APPEND 'UP_REP'     TO gm_excl.
  APPEND 'UP_FIX'     TO gm_excl.
  ...
ENDIF.
```

### Fix — `CODE_PBO.md` (MODULE status_0300)

**Xóa** dòng `APPEND 'UP_FILE' TO gm_excl.` khỏi Create mode exclusion block:

```abap
IF gv_mode = gc_mode_create.
  APPEND 'STATUS_CHG' TO gm_excl.
  " UP_FILE: giữ hiển thị — upload_evidence_file tự check bug đã save chưa
  APPEND 'UP_REP'     TO gm_excl.   " Tester report — chỉ khi đã có bug_id
  APPEND 'UP_FIX'     TO gm_excl.   " Fix upload — chỉ khi đã có bug_id
  APPEND 'SENDMAIL'   TO gm_excl.
  APPEND 'DL_EVD'     TO gm_excl.
ENDIF.
```

`FORM upload_evidence_file` → `upload_evidence` đã có guard:
```abap
IF gv_current_bug_id IS INITIAL.
  MESSAGE 'Save the bug first before uploading evidence.' TYPE 'W'.
  RETURN.
ENDIF.
```
Nên người dùng sẽ thấy nút, nhưng bấm trước khi save sẽ được nhắc "Save first" — UX đúng.

---

## Bug 6d — Created Date có thể nhập tay

### Triệu chứng
Field "Created Date" trên Screen 0310 cho phép user gõ vào.

### Root Cause
Field `GS_BUG_DETAIL-ERDAT` (Created Date) trong SE51 Screen 0310 được gán group `EDT` → editable.

### Fix — SE51 Screen 0310

Trong SE51, tìm field `GS_BUG_DETAIL-ERDAT` và `GS_BUG_DETAIL-ERNAM` (Created By):
- Xóa group `EDT` khỏi hai field này
- Thay bằng group `BID` (đã được xử lý trong `modify_screen_0300` là always `screen-input = 0`)

Hoặc thêm explicit rule trong `CODE_PBO.md` → `modify_screen_0300`:
```abap
" Created date/time/user: always read-only (system-generated)
IF screen-group1 = 'CRE'.
  screen-input = 0.
  MODIFY SCREEN.
ENDIF.
```
Gán group `CRE` cho `ERDAT`, `ERZET`, `ERNAM` trong SE51.

---

## Bug 7 — Sau validation error, tất cả field bị khóa

### Triệu chứng
Sau khi nhấn Save và bị báo lỗi (ví dụ "Severity Dump/VeryHigh/High requires Priority = High"), người dùng không thể sửa các field.

### Root Cause
Trong `CODE_F01.md` → `save_bug_detail`, các validation dùng `MESSAGE ... TYPE 'E'`:
```abap
MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'E'.
RETURN.
```

Trong ABAP Module Pool, `MESSAGE TYPE 'E'` gây ra:
- PAI bị dừng giữa chừng
- ABAP thực hiện **rollback transport** — tức là giá trị màn hình bị đặt lại về trước khi user nhập
- Screen được re-display nhưng với giá trị DB cũ → user mất tất cả input vừa gõ, cảm giác như bị "khóa"

### Fix — `CODE_F01.md` (FORM save_bug_detail)

Đổi tất cả `MESSAGE TYPE 'E'` trong validation block sang `TYPE 'S' DISPLAY LIKE 'E'` và dùng cờ `lv_error`:

```abap
FORM save_bug_detail.
  DATA: lv_error TYPE abap_bool.

  " Validate PROJECT_ID
  IF gs_bug_detail-project_id IS INITIAL.
    MESSAGE 'Project ID is required.' TYPE 'S' DISPLAY LIKE 'E'.
    lv_error = abap_true.
  ENDIF.

  " Validate TITLE
  IF gs_bug_detail-title IS INITIAL.
    MESSAGE 'Title is required.' TYPE 'S' DISPLAY LIKE 'E'.
    lv_error = abap_true.
  ENDIF.

  " Severity vs Priority cross-validation
  IF gs_bug_detail-severity IS NOT INITIAL
     AND ( gs_bug_detail-severity = '1' OR gs_bug_detail-severity = '2'
           OR gs_bug_detail-severity = '3' ).
    IF gs_bug_detail-priority <> 'H'.
      MESSAGE 'Severity Dump/VeryHigh/High requires Priority = High.' TYPE 'S' DISPLAY LIKE 'E'.
      lv_error = abap_true.
    ENDIF.
  ENDIF.

  " Stop if any validation failed
  IF lv_error = abap_true. RETURN. ENDIF.

  " ... rest of save logic unchanged ...
ENDFORM.
```

`TYPE 'S' DISPLAY LIKE 'E'` hiển thị message màu đỏ như lỗi nhưng KHÔNG rollback transport → user giữ được input vừa nhập.

---

## Bug 8 — Dữ liệu Description biến mất khi xem chi tiết bug

### Triệu chứng
- Ảnh: `bug-list-warning-could-not-read-description.png` — warning "Warning: Could not read description text." trên bug list
- Khi vào xem chi tiết bug, Description text trong mini editor trống

### Root Cause
Trong `CODE_F01.md` → `save_desc_mini_to_workarea`:
```abap
cl_gui_cfw=>flush( ).
go_desc_mini_edit->get_text_as_r3table(
  IMPORTING table = lt_mini
  EXCEPTIONS error_dp = 1 error_dp_create = 2 OTHERS = 3 ).
IF sy-subrc <> 0.
  MESSAGE 'Warning: Could not read description text.' TYPE 'S' DISPLAY LIKE 'W'.
  RETURN.  " ← RETURN mà không cập nhật gs_bug_detail-desc_text
ENDIF.
```

Khi `get_text_as_r3table` thất bại (GUI flush lỗi, editor chưa fully initialized):
1. Hàm RETURN mà **không** cập nhật `gs_bug_detail-desc_text`
2. `save_bug_detail` tiếp tục save `gs_bug_detail` (với `desc_text` cũ/rỗng) vào DB
3. → DB mất description

### Fix — `CODE_F01.md` (FORM save_desc_mini_to_workarea)

```abap
FORM save_desc_mini_to_workarea.
  CHECK go_desc_mini_edit IS NOT INITIAL.
  DATA: lt_mini TYPE TABLE OF char255,
        lv_text TYPE string.

  " Flush với error handling — không abort nếu flush lỗi
  cl_gui_cfw=>flush(
    EXCEPTIONS
      cntl_error              = 1
      cntl_system_error       = 2
      OTHERS                  = 3 ).
  " Nếu flush lỗi → vẫn thử get text (editor có thể vẫn hoạt động)

  go_desc_mini_edit->get_text_as_r3table(
    IMPORTING table = lt_mini
    EXCEPTIONS error_dp        = 1
               error_dp_create = 2
               OTHERS          = 3 ).

  IF sy-subrc <> 0.
    " KHÔNG xóa desc_text — giữ giá trị cũ trong gs_bug_detail
    " Không hiển thị warning vì gây confuse cho user
    RETURN.
  ENDIF.

  CLEAR lv_text.
  LOOP AT lt_mini INTO DATA(lv_line).
    IF lv_text IS NOT INITIAL.
      lv_text &&= cl_abap_char_utilities=>cr_lf && lv_line.
    ELSE.
      lv_text = lv_line.
    ENDIF.
  ENDLOOP.
  gs_bug_detail-desc_text = lv_text.
ENDFORM.
```

**Quan trọng:** Bỏ MESSAGE warning → tránh confuse user, và KHÔNG ghi đè `desc_text` nếu read lỗi (tránh mất dữ liệu cũ).

---

## Bug 10 — Có thể chuyển Status từ 3 → 1 không có cảnh báo

### Triệu chứng
- Ảnh: `change-bug-0024-status-popup-new2.png`, `change-bug-0024-status-popup-new5.png`
- Manager có thể set bất kỳ status nào không cần kiểm tra thứ tự
- Bug đang In Progress (3) → có thể về New (1) tùy tiện

### Root Cause
Trong `CODE_F01.md` → `change_bug_status`:
```abap
WHEN 'M'. " Manager: can set any status
  APPEND gc_st_new        TO lt_allowed.
  " ... tất cả status đều được append
```

Manager được phép đổi tự do hoàn toàn — không có logic backward protection.

### Fix — `CODE_F01.md` (FORM change_bug_status)

**Phương án A (Nghiêm ngặt):** Giới hạn Manager theo transition hợp lệ:
```abap
WHEN 'M'. " Manager: can override but with reasonable constraints
  CASE lv_current.
    WHEN gc_st_new.
      APPEND gc_st_assigned   TO lt_allowed.
      APPEND gc_st_waiting    TO lt_allowed.
    WHEN gc_st_assigned.
      APPEND gc_st_new        TO lt_allowed.  " Có thể reject về New
      APPEND gc_st_inprogress TO lt_allowed.
      APPEND gc_st_waiting    TO lt_allowed.
    WHEN gc_st_inprogress.
      APPEND gc_st_pending    TO lt_allowed.
      APPEND gc_st_fixed      TO lt_allowed.
      APPEND gc_st_rejected   TO lt_allowed.
      APPEND gc_st_assigned   TO lt_allowed.  " Reassign
    WHEN gc_st_pending.
      APPEND gc_st_inprogress TO lt_allowed.
    WHEN gc_st_fixed.
      APPEND gc_st_resolved   TO lt_allowed.
      APPEND gc_st_rejected   TO lt_allowed.
      APPEND gc_st_inprogress TO lt_allowed.  " Back to work
    WHEN gc_st_resolved.
      APPEND gc_st_closed     TO lt_allowed.
      APPEND gc_st_fixed      TO lt_allowed.  " Retest
    WHEN gc_st_waiting.
      APPEND gc_st_new        TO lt_allowed.
      APPEND gc_st_assigned   TO lt_allowed.
    WHEN gc_st_rejected.
      APPEND gc_st_new        TO lt_allowed.  " Reopen
  ENDCASE.
```

**Phương án B (Cảnh báo):** Giữ Manager toàn quyền nhưng thêm popup cảnh báo khi đi ngược:
```abap
" Thêm sau validation - trước khi UPDATE zbug_tracker
" Detect nếu là backward transition
DATA: lt_forward_order TYPE TABLE OF zde_bug_status,
      lv_cur_pos TYPE i, lv_new_pos TYPE i.
APPEND gc_st_new        TO lt_forward_order.
APPEND gc_st_waiting    TO lt_forward_order.
APPEND gc_st_assigned   TO lt_forward_order.
APPEND gc_st_inprogress TO lt_forward_order.
APPEND gc_st_pending    TO lt_forward_order.
APPEND gc_st_fixed      TO lt_forward_order.
APPEND gc_st_resolved   TO lt_forward_order.
APPEND gc_st_closed     TO lt_forward_order.

READ TABLE lt_forward_order TRANSPORTING NO FIELDS
  WITH KEY table_line = lv_current.
lv_cur_pos = sy-tabix.
READ TABLE lt_forward_order TRANSPORTING NO FIELDS
  WITH KEY table_line = lv_new_status.
lv_new_pos = sy-tabix.

IF gv_role = 'M' AND lv_new_pos < lv_cur_pos AND lv_new_pos > 0.
  DATA: lv_warn_confirmed TYPE abap_bool.
  PERFORM confirm_action
    USING |Backward transition { lv_current } → { lv_new_status }. Proceed?|
    CHANGING lv_warn_confirmed.
  IF lv_warn_confirmed = abap_false. RETURN. ENDIF.
ENDIF.
```

---

## Bug 11 — Đổi status không cần evidence

### Triệu chứng
Bug có thể chuyển từ trạng thái này sang trạng thái khác (đặc biệt → Fixed/Resolved/Closed) mà không cần evidence.

### Root Cause (2 nguyên nhân)

**Nguyên nhân 1: Bảng `ZBUG_EVIDENCE` chưa tạo**  
Per `context.md` Section 5, Phase A:
```
A9 | v4.0 Bảng ZBUG_EVIDENCE | ❌ Chưa tạo
```
Nếu bảng chưa tồn tại → `SELECT COUNT(*) FROM zbug_evidence` sẽ DUMP (bảng không tồn tại) HOẶC trả 0 tùy SAP version → check_evidence luôn thất bại silently.

**Nguyên nhân 2: Logic check chỉ kiểm tra 3 transitions**  
`check_evidence_for_status` chỉ check Fixed(5)/Resolved(6)/Closed(7). Các transitions khác có `WHEN OTHERS → RETURN` không kiểm tra.

### Fix — 2 bước bắt buộc

**Bước 1: Tạo bảng ZBUG_EVIDENCE trong SE11**  
Thực hiện đúng theo hướng dẫn trong `analysis/guides/SE11_ZBUG_EVIDENCE.md`. Đây là **prerequisite bắt buộc** — tất cả evidence feature đều phụ thuộc vào bảng này.

**Bước 2: Cập nhật `check_evidence_for_status` trong `CODE_F01.md`**

Thêm guard cho trường hợp bảng chưa tạo (defensive coding):
```abap
FORM check_evidence_for_status USING    pv_new_status TYPE zde_bug_status
                               CHANGING pv_ok         TYPE abap_bool.
  pv_ok = abap_true.
  CHECK gv_current_bug_id IS NOT INITIAL.

  DATA: lv_prefix TYPE string,
        lv_count  TYPE i,
        lv_like   TYPE sdok_filnm.

  CASE pv_new_status.
    WHEN gc_st_fixed.     lv_prefix = 'BUGPROOF_'.
    WHEN gc_st_resolved.  lv_prefix = 'TESTCASE_'.
    WHEN gc_st_closed.    lv_prefix = 'CONFIRM_'.
    WHEN OTHERS.
      RETURN.  " Các transition khác không bắt buộc evidence
  ENDCASE.

  CONCATENATE lv_prefix '%' INTO lv_like.

  " Guard: nếu bảng chưa tạo → không dump, chỉ warn
  SELECT COUNT(*) FROM zbug_evidence INTO @lv_count
    WHERE bug_id    = @gv_current_bug_id
      AND file_name LIKE @lv_like
    EXCEPTIONS
      resource_failure = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
    " Bảng không tồn tại hoặc lỗi DB → warn nhưng không block
    MESSAGE |ZBUG_EVIDENCE table error. Evidence check skipped. Create table first (SE11).| TYPE 'W'.
    RETURN.  " pv_ok remains abap_true — don't block on infrastructure error
  ENDIF.

  IF lv_count = 0.
    MESSAGE |Evidence file with prefix "{ lv_prefix }" is required before this status change.| TYPE 'W'.
    pv_ok = abap_false.
  ENDIF.
ENDFORM.
```

> **Note:** `SELECT ... EXCEPTIONS resource_failure` có thể không có sẵn trên mọi FM. Phương án an toàn hơn: dùng `CATCH cx_sy_open_sql_error` nếu dùng OpenSQL nâng cao, hoặc đặt code trong `TRY ... CATCH cx_root`.

---

## Thứ tự ưu tiên sửa

```
1. [NGAY] Bug 1 & 9  → Sửa CODE_F02.md (READ_TEXT type fix) → CRITICAL, chặn dùng được app
2. [NGAY] Bug 11     → Tạo ZBUG_EVIDENCE trong SE11 → CRITICAL, evidence feature sập hoàn toàn
3. [CAO]  Bug 7      → Sửa CODE_F01.md (TYPE 'S' thay 'E') → Tránh mất input user
4. [CAO]  Bug 8      → Sửa CODE_F01.md (save_desc_mini) → Tránh mất Description data
5. [CAO]  Bug 5      → Sửa CODE_F01.md (Remove User guard) → Logic sai nghiêm trọng
6. [CAO]  Bug 10     → Sửa CODE_F01.md (Status backward) → Sai business logic
7. [TB]   Bug 6a     → Sửa CODE_PBO.md (Status lock in Create)
8. [TB]   Bug 6b     → Thêm F4 SAP Module
9. [TB]   Bug 6c     → Bỏ UP_FILE exclude trong Create
10. [TB]  Bug 4      → Sửa SE51 field output length
11. [THẤP] Bug 2     → Tăng size CC_DESC_MINI trong SE51
12. [THẤP] Bug 3     → Dùng get_text_as_stream
13. [THẤP] Bug 6d    → Lock Created Date field trong SE51
```

---

## Mapping Bug Report khách → Screenshot

| Bug report (update/BUG_Report.md) | Ảnh minh họa tương ứng |
|-----------------------------------|------------------------|
| Bug 1 — Short dump Description/DevNote/TesterNote tab | `runtime-error-read-text-type-conflict-115802.png`, `runtime-error-read-text-type-conflict-123322.png` |
| Bug 2 — Description box nhỏ | `create-bug-bug-info-status-3-no-upload.png` |
| Bug 5 — Remove User không cần chọn | `change-project-remove-user-confirm.png` |
| Bug 6 — Create Bug (Status, Upload, Create Date) | `create-bug-bug-info-status-3-no-upload.png`, `create-bug-validation-error-footer.png` |
| Bug 7 — Fields khóa sau error | `create-bug-validation-error-footer.png` |
| Bug 8 — Description biến mất | `bug-list-warning-could-not-read-description.png` |
| Bug 9 — Short dump ở Change Bug | `runtime-error-read-text-type-conflict-123322.png` |
| Bug 10 — Đổi status 3→1 | `change-bug-0024-status-popup-new2.png` |
| Bug 11 — Đổi status không cần evidence | `change-bug-0024-status-popup-fixed-note.png` |

---

*Phân tích bởi AI Agent — 14/04/2026. Cross-referenced với: CODE_TOP.md, CODE_F00.md, CODE_PBO.md, CODE_PAI.md, CODE_F01.md, CODE_F02.md, context.md, table-fields.md.*
