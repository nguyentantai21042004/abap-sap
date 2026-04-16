# Bug Analysis v5.0 — Phân tích 11 lỗi từ UAT Testing

> **Ngày:** 13/04/2026
> **Nguồn:** `update/BUG_Report.md` + screenshots trong `update/` *(file gốc đã xoá — tài liệu này là bản phân tích lưu trữ)*
> **Phạm vi:** Tất cả bugs chưa nhắc tới = PASS. Chỉ 11 bugs dưới đây cần fix.

---

## Tổng quan

| # | Mô tả ngắn | Severity | Root Cause | Cần sửa Code? | Cần sửa Screen? |
|---|-----------|----------|-----------|:-----------:|:-----------:|
| 1 | Short dump khi mở tab Desc/DevNote/TesterNote | **CRITICAL** | Type conflict hoặc Custom Control thiếu | ✅ | ✅ |
| 2 | Description cần box lớn riêng | Medium | Design — đã có tab nhưng crash | ❌ | Liên quan Bug 1 |
| 3 | Description bị giới hạn ký tự | Medium | STRING field trên screen layout | ✅ | ✅ |
| 4 | Hiển thị trường bị thiếu (SAP Module, Severity...) | High | Screen field không map đúng WA | ❌ | ✅ |
| 5 | Remove User không chọn vẫn xóa | Medium | tc_users-current_line mặc định | ✅ | ❌ |
| 6 | Create Bug: Status/Date/Module/Evidence | High | Thiếu logic + F4 help | ✅ | ✅ |
| 7 | Fields bị khóa sau validation error | High | MESSAGE TYPE 'E' locks screen | ✅ | ❌ |
| 8 | Description biến mất khi xem detail | High | Liên quan Bug 1 + mini editor | ✅ | ❌ |
| 9 | Short dump Change Bug = Bug 1 | **CRITICAL** | Cùng root cause với Bug 1 | ✅ | ✅ |
| 10 | Status chuyển ngược 3→1 không lỗi | **CRITICAL** | Manager bypass validation | ✅ | ❌ |
| 11 | Status chuyển không cần evidence | High | Thiếu validation logic | ✅ | ❌ |

---

## Chi tiết từng Bug

### Bug 1+9: Short dump CALL_FUNCTION_CONFLICT_TYPE khi mở tab long text

**Triệu chứng:**
- Change Bug → click tab Description/Dev Note/Tester Note → short dump
- Create Bug → click các tab đó → không crash nhưng không hiện gì

**Screenshots:** `runtime-error-read-text-type-conflict-115802.png`, `runtime-error-read-text-type-conflict-123322.png`

**Root Cause Analysis (3 khả năng, theo thứ tự khả năng cao nhất):**

1. **Custom Control chưa tạo đúng trên SE51** — Subscreens 0320/0330/0340 cần có Custom Control element với tên chính xác `CC_DESC`, `CC_DEVNOTE`, `CC_TSTRNOTE`. Nếu thiếu, `CREATE OBJECT cl_gui_custom_container EXPORTING container_name = 'CC_DESC'` sẽ raise exception không bắt.

2. **STRING field trên screen layout** — Nếu user đã đặt `GS_BUG_DETAIL-DESC_TEXT` (TYPE STRING) hoặc `GS_BUG_DETAIL-REASONS` (TYPE STRING) lên layout của subscreen 0310, SAP screen transport sẽ crash vì screen KHÔNG hỗ trợ deep types (STRING, RAWSTRING, TABLE).

3. **READ_TEXT type mismatch** — `gv_current_bug_id` (TYPE `zde_bug_id` = CHAR 10) truyền vào param `name` (TYPE `TDOBNAME` = CHAR 70). Thông thường ABAP sẽ implicit convert, nhưng nếu Data Element `zde_bug_id` có conversion exit lạ thì có thể conflict.

**Tại sao Create không crash:** Vì `gv_current_bug_id IS INITIAL` → `CHECK` skip toàn bộ `load_long_text`.

**Fix đề xuất:**

```abap
" 1. Thêm TRY-CATCH cho container creation (CODE_PBO)
MODULE init_long_text_desc OUTPUT.
  IF go_cont_desc IS INITIAL.
    TRY.
        CREATE OBJECT go_cont_desc EXPORTING container_name = 'CC_DESC'.
        CREATE OBJECT go_edit_desc EXPORTING parent = go_cont_desc.
      CATCH cx_root.
        MESSAGE 'Cannot create Description editor. Check Custom Control CC_DESC on screen 0320.' TYPE 'S' DISPLAY LIKE 'W'.
        RETURN.
    ENDTRY.
    ...
  ENDIF.
ENDMODULE.

" 2. Ép kiểu name trong READ_TEXT (CODE_F02)
DATA: lv_tdname TYPE tdobname.
lv_tdname = gv_current_bug_id.    " Explicit conversion CHAR 10 → CHAR 70
CALL FUNCTION 'READ_TEXT'
  EXPORTING
    id     = pv_text_id
    language = sy-langu
    name   = lv_tdname             " Dùng biến đã ép kiểu
    object = 'ZBUG'
  ...
```

**Cần verify trên SE51:**
- Screen 0320: phải có Custom Control tên `CC_DESC`
- Screen 0330: phải có Custom Control tên `CC_DEVNOTE`
- Screen 0340: phải có Custom Control tên `CC_TSTRNOTE`
- Screen 0310: **KHÔNG** được có field `GS_BUG_DETAIL-DESC_TEXT` hoặc `GS_BUG_DETAIL-REASONS` trên layout

---

### Bug 2: Description cần box lớn riêng biệt

**Triệu chứng:** Nội dung mô tả nằm chung khu vực Bug Info (subscreen 0310).

**Analysis:** Thiết kế hiện tại đã đúng:
- Subscreen 0310 (Bug Info) có **mini editor** (`CC_DESC_MINI`, 3-4 dòng) để xem nhanh
- Subscreen 0320 (Description tab) có **full editor** (`CC_DESC`) để xem/sửa đầy đủ

**Vấn đề thực tế:** Tab Description crash (Bug 1) nên user không thấy được full editor. Fix Bug 1 sẽ giải quyết Bug 2.

**Fix:** Không cần thay đổi design. Fix Bug 1 là đủ.

---

### Bug 3: Description bị giới hạn ký tự

**Triệu chứng:** Không nhập được mô tả dài.

**Root Cause:** 
- `ZBUG_TRACKER.DESC_TEXT` = TYPE STRING (không giới hạn) ✅
- `cl_gui_textedit` (mini editor) = không giới hạn ✅
- **NẾU** user đặt `GS_BUG_DETAIL-DESC_TEXT` làm input field trên screen layout → screen field bị giới hạn bởi visible length (thường 132 chars)

**Fix:** Xóa `GS_BUG_DETAIL-DESC_TEXT` khỏi screen 0310 layout nếu có. Description chỉ nên nằm trong `cl_gui_textedit` (Custom Control `CC_DESC_MINI`).

---

### Bug 4: Hiển thị trường bị thiếu (SAP Module, Severity, Created Date)

**Triệu chứng:** Display Bug BUG0000023 — trường SAP Module, Severity, Created Date hiển thị trống.

**Screenshot:** `display-bug-bug0023-empty-metadata.png`

**Root Cause Analysis:**

1. **Screen fields không link đúng:** Kiểm tra trên SE51 Screen 0310 → mỗi input/output field phải reference đúng tên biến global:
   - SAP Module → `GS_BUG_DETAIL-SAP_MODULE`
   - Severity display → `GV_SEVERITY_DISP` (display text) hoặc `GS_BUG_DETAIL-SEVERITY` (raw code)
   - Created Date → `GS_BUG_DETAIL-CREATED_AT`

2. **Thiếu field trên screen layout:** User có thể chưa thêm các field này lên subscreen 0310.

3. **Bug 0000023 thực sự không có data:** Kiểm tra SE16 → ZBUG_TRACKER WHERE bug_id = 'BUG0000023' → xem SAP_MODULE, SEVERITY, CREATED_AT có giá trị không.

**Fix:** Verify screen layout + field references trên SE51.

---

### Bug 5: Remove User không chọn vẫn xóa

**Triệu chứng:** Nhấn "Remove User" khi không chọn user nào → vẫn thực hiện xóa.

**Screenshots:** `change-project-remove-user-confirm.png`, `change-project-assign-user-popup.png`

**Root Cause:** `tc_users-current_line` luôn có giá trị (mặc định = dòng cuối cùng focus) nếu Table Control có dữ liệu. Check `IF lv_line = 0` không đủ.

**Code hiện tại** (`CODE_F01.md:652-679`):
```abap
FORM remove_user_from_project.
  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.
  IF lv_line = 0.
    MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
  ENDIF.
  ...
```

**Fix đề xuất — Thêm selection column hoặc dùng marking:**
```abap
FORM remove_user_from_project.
  " Dùng GET_CURRENT_CELL hoặc check mark_field
  DATA: lv_line TYPE i.
  GET CURSOR LINE lv_line.
  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
    MESSAGE 'Please select a user row first by clicking on it.' TYPE 'W'.
    RETURN.
  ENDIF.
  ...
```

Hoặc đơn giản hơn — thêm validation:
```abap
FORM remove_user_from_project.
  DATA: lv_line TYPE i.
  lv_line = tc_users-current_line.
  " Validate: current_line phải trong phạm vi dữ liệu
  IF lv_line <= 0 OR lv_line > lines( gt_user_project ).
    MESSAGE 'Please select a user row to remove.' TYPE 'W'. RETURN.
  ENDIF.
  ...
```

---

### Bug 6: Create Bug — 4 vấn đề

**Screenshot:** `create-bug-bug-info-status-3-no-upload.png`, `create-bug-validation-error-footer.png`

#### 6a. Status luôn phải là 1 (New)

**Root Cause:** Code hiện tại cho phép user chọn status khác khi tạo bug. Field STATUS có F4 help với 9 giá trị.

**Code hiện tại** (`CODE_F01.md:169-171`):
```abap
IF gs_bug_detail-status IS INITIAL.
  gs_bug_detail-status = gc_st_new.
ENDIF.
```

Vấn đề: nếu user đã chọn status = '3' qua F4, `status IS NOT INITIAL` → không override.

**Fix:**
```abap
" Create mode: FORCE status to New, không cho user đổi
gs_bug_detail-status = gc_st_new.  " Luôn = 1, bỏ IF
```

**Và trên Screen 0310:** Thêm STATUS vào screen group `STS` mới → PBO lock khi Create mode:
```abap
IF screen-group1 = 'STS'.
  screen-input = 0.  " STATUS luôn locked — chỉ đổi qua popup
  MODIFY SCREEN.
ENDIF.
```

#### 6b. SAP Module cần Search Help (F4)

**Root Cause:** Không có `f4_sap_module` form hay POV module cho SAP_MODULE field.

**Fix — Thêm vào CODE_F02:**
```abap
FORM f4_sap_module USING pv_fn TYPE dynfnam.
  TYPES: BEGIN OF ty_mod_f4,
           sap_module TYPE zde_sap_module,
         END OF ty_mod_f4.
  DATA: lt_ret TYPE TABLE OF ddshretval,
        lt_val TYPE TABLE OF ty_mod_f4.
  APPEND VALUE ty_mod_f4( sap_module = 'FI' )    TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'MM' )    TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'SD' )    TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'ABAP' )  TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'BASIS' ) TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'PP' )    TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'HR' )    TO lt_val.
  APPEND VALUE ty_mod_f4( sap_module = 'QM' )    TO lt_val.
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING retfield = 'SAP_MODULE' dynpprog = sy-repid
              dynpnr = sy-dynnr dynprofield = pv_fn value_org = 'S'
    TABLES value_tab = lt_val return_tab = lt_ret
    EXCEPTIONS OTHERS = 1.
ENDFORM.
```

**Thêm vào CODE_PAI:**
```abap
MODULE f4_bug_sapmodule INPUT.
  PERFORM f4_sap_module USING 'GS_BUG_DETAIL-SAP_MODULE'.
ENDMODULE.
```

**Thêm vào Screen 0310 Flow Logic (POV):**
```
PROCESS ON VALUE-REQUEST.
  FIELD gs_bug_detail-sap_module MODULE f4_bug_sapmodule.
```

#### 6c. Upload Evidence ngay khi tạo bug

**Root Cause:** PBO hiện tại exclude `UP_FILE` trong Create mode.

**Fix (IMPLEMENTED in v5.0):** Bỏ `UP_FILE` khỏi Create mode exclusion list. Khi user nhấn UP_FILE trong Create mode, form `upload_evidence` sẽ **auto-save bug trước** (tạo bug_id), rồi tiếp tục upload:
```abap
" Trong upload_evidence (CODE_F01.md):
IF gv_current_bug_id IS INITIAL.
  IF gv_mode = gc_mode_create.
    PERFORM save_bug.
    IF gv_current_bug_id IS INITIAL.
      RETURN.  " Save failed — validation errors already shown
    ENDIF.
  ELSE.
    MESSAGE 'Bug ID not available.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
ENDIF.
```

> **Flow:** User tạo bug → điền fields → nhấn UP_FILE → bug tự động save → bug_id sinh → upload tiếp tục → mode chuyển sang Change.
> UP_REP và UP_FIX vẫn excluded trong Create mode (chỉ UP_FILE mở).

#### 6d. Created Date tự động

**Root Cause:** `CREATED_AT` được set khi save (`gs_bug_detail-erdat = sy-datum`), nhưng trên screen hiển thị trống trước khi save.

**Fix — PBO Create mode pre-fill:**
```abap
IF gv_mode = gc_mode_create.
  ...
  gs_bug_detail-created_at = sy-datum.   " Auto-fill ngày tạo
  gs_bug_detail-created_time = sy-uzeit. " Auto-fill giờ tạo
ENDIF.
```

**Và trên Screen 0310:** CREATED_AT field thuộc screen group `BID` hoặc group mới `CRD` → luôn locked.

---

### Bug 7: Fields bị khóa sau validation error

**Triệu chứng:** Nhập liệu lỗi → message lỗi → tất cả fields locked.

**Screenshot:** `create-bug-validation-error-footer.png`

**Root Cause:** Sử dụng `MESSAGE ... TYPE 'E'` trong FORM (gọi từ PAI). Trong Module Pool, `MESSAGE TYPE 'E'` có hành vi:
1. Hiển thị lỗi trên status bar
2. **Lock toàn bộ screen fields** cho đến khi user nhấn Enter
3. **Chỉ unlock** fields có `GROUP1` matching — nhưng nếu không có field group mapping, tất cả bị locked

**Fix — Đổi sang MESSAGE TYPE 'S' DISPLAY LIKE 'E':**

Trong `save_bug_detail` (`CODE_F01.md`):
```abap
" TRƯỚC (gây lock screen):
MESSAGE 'Title is required.' TYPE 'E'.

" SAU (hiển thị lỗi nhưng KHÔNG lock screen):
MESSAGE 'Title is required.' TYPE 'S' DISPLAY LIKE 'E'.
RETURN.
```

**Áp dụng cho TẤT CẢ MESSAGE TYPE 'E'** trong:
- `save_bug_detail` (5 messages)
- `save_project_detail` (3 messages)
- Bất kỳ form nào gọi từ PAI

---

### Bug 8: Description biến mất khi xem detail

**Triệu chứng:** Display Bug — vùng text lớn trống.

**Root Cause:** Liên quan Bug 1. Nếu tab Description crash, user chỉ thấy mini editor trên Bug Info tab. Mini editor load `gs_bug_detail-desc_text` khi tạo lần đầu. Nếu:
1. `gs_bug_detail-desc_text` trống trong DB (chưa lưu description)
2. Hoặc text lưu qua Long Text (SAVE_TEXT) nhưng không lưu vào `desc_text` field → mini editor trống

**Phân tích code:**
- Save flow: `save_desc_mini_to_workarea` → đọc mini editor → ghi vào `gs_bug_detail-desc_text` → save cả record
- Load flow: `load_bug_detail` → SELECT * từ DB → `gs_bug_detail-desc_text` có data → mini editor hiển thị

**Vấn đề tiềm ẩn:** Nếu user chỉ edit trên tab Description (full editor, subscreen 0320) và nhấn Save → `save_long_text USING 'Z001'` lưu vào Text Object nhưng **KHÔNG update `gs_bug_detail-desc_text`**. Lần load sau, `desc_text` từ DB sẽ là giá trị cũ.

**Fix:** Sau `save_long_text`, sync lại desc_text:
```abap
" Sau save_long_text, đọc lại text để sync:
IF go_edit_desc IS NOT INITIAL.
  DATA: lt_desc_sync TYPE TABLE OF char255.
  go_edit_desc->get_text_as_r3table( IMPORTING table = lt_desc_sync ).
  CLEAR gs_bug_detail-desc_text.
  LOOP AT lt_desc_sync INTO DATA(lv_sync_line).
    IF gs_bug_detail-desc_text IS NOT INITIAL.
      gs_bug_detail-desc_text = gs_bug_detail-desc_text && cl_abap_char_utilities=>cr_lf && lv_sync_line.
    ELSE.
      gs_bug_detail-desc_text = lv_sync_line.
    ENDIF.
  ENDLOOP.
ENDIF.
```

---

### Bug 10: Status chuyển ngược 3 → 1 không lỗi

**Triệu chứng:** BUG0000024 đang In Progress (3), lưu thành New (1) mà không có cảnh báo.

**Screenshots:** `change-bug-bug0024-status-in-progress.png`, `change-bug-bug0024-status-1-new-saved.png`

**Root Cause:** Trong `change_bug_status` (`CODE_F01.md:459-469`):
```abap
WHEN 'M'. " Manager: can set any status
  APPEND gc_st_new        TO lt_allowed.
  APPEND gc_st_assigned   TO lt_allowed.
  ...
```

Manager được phép chuyển sang BẤT KỲ trạng thái nào → không có validation backward transition.

**Fix — v5.0 redesign:**

Manager **KHÔNG** nên bypass transition rules. Thay thế bằng matrix logic mới (xem `status-lifecycle.md`):

```abap
" v5.0: Manager tuân theo transition matrix, KHÔNG free-form
CASE lv_current.
  WHEN gc_st_new.
    APPEND gc_st_assigned TO lt_allowed.
    APPEND gc_st_waiting  TO lt_allowed.
  WHEN gc_st_waiting.
    APPEND gc_st_assigned     TO lt_allowed.
    APPEND gc_st_finaltesting TO lt_allowed.
  WHEN gc_st_assigned.
    APPEND gc_st_inprogress TO lt_allowed.
    APPEND gc_st_rejected   TO lt_allowed.
  WHEN gc_st_inprogress.
    APPEND gc_st_fixed      TO lt_allowed.
    APPEND gc_st_pending    TO lt_allowed.
    APPEND gc_st_rejected   TO lt_allowed.
  WHEN gc_st_pending.
    APPEND gc_st_assigned   TO lt_allowed.
  WHEN gc_st_finaltesting.
    APPEND gc_st_resolved   TO lt_allowed.
    APPEND gc_st_inprogress TO lt_allowed.
ENDCASE.
```

Popup mới (Screen 0350) sẽ thay thế POPUP_GET_VALUES → chỉ hiển thị status hợp lệ.

---

### Bug 11: Status chuyển không cần evidence / sai logic

**Triệu chứng:** BUG0000024 chuyển sang Fixed (5) mà không upload evidence.

**Screenshot:** `change-bug-bug0024-status-5-fixed-saved.png`

**Root Cause:** `check_evidence_for_status` chỉ check file prefix (`BUGPROOF_`, `TESTCASE_`, `CONFIRM_`). Nhưng:
1. Có thể bảng `ZBUG_EVIDENCE` chưa tạo trong SAP → SELECT COUNT(*) trả về 0 nhưng không crash
2. Hoặc logic check bị bypass bởi Manager role (line 508: `IF sy-subrc <> 0 AND gv_role <> 'M'`)

**Code hiện tại** (`CODE_F01.md:507-511`):
```abap
READ TABLE lt_allowed TRANSPORTING NO FIELDS WITH KEY table_line = lv_new_status.
IF sy-subrc <> 0 AND gv_role <> 'M'.    " ← Manager bypass!
  MESSAGE |Invalid transition| TYPE 'W'.
  RETURN.
ENDIF.
```

**Fix v5.0:** 
1. **Xóa Manager bypass** — Manager phải tuân theo rules
2. **Popup Screen 0350** sẽ enforce evidence upload trước khi cho chuyển sang Fixed

---

## Tổng hợp thay đổi cần thiết

### Files cần sửa code:

| File | Thay đổi | Bugs liên quan |
|------|---------|---------------|
| `CODE_TOP.md` | Thêm `gc_st_finaltesting`, `gc_st_resolved='V'`, group `STS` | 10, 11 |
| `CODE_PBO.md` | TRY-CATCH container creation, screen group STS, Create mode pre-fill | 1, 6, 9 |
| `CODE_PAI.md` | Thêm `f4_bug_sapmodule` POV module, UP_FILE logic cho Create | 6 |
| `CODE_F01.md` | Fix MESSAGE types, fix Manager transition, fix Remove User validation | 5, 7, 10, 11 |
| `CODE_F02.md` | Explicit type cast in READ_TEXT, thêm `f4_sap_module` | 1, 6, 9 |

### Screens cần verify/sửa trên SE51:

| Screen | Kiểm tra | Bugs liên quan |
|--------|---------|---------------|
| 0310 | Xóa STRING fields, verify field references, thêm group STS cho STATUS | 3, 4, 6 |
| 0320 | Verify Custom Control `CC_DESC` tồn tại | 1, 2 |
| 0330 | Verify Custom Control `CC_DEVNOTE` tồn tại | 1, 9 |
| 0340 | Verify Custom Control `CC_TSTRNOTE` tồn tại | 1, 9 |

---

*File này tổng hợp phân tích 11 bugs từ UAT round 1. Mọi fix sẽ được incorporate vào CODE v5.0.*
*Tạo bởi OpenCode agent — 13/04/2026*
