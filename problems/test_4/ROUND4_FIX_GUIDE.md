# Round 4 — Fix Guide (4 Bugs)

## Tổng quan

| Bug | Mô tả | File sửa | Loại fix |
|-----|--------|----------|----------|
| Bug 1 | Notes/Description không lưu được | CODE_F01, CODE_F02 | Code only |
| Bug 2 | Project list stale + refresh bỏ qua filter | CODE_TOP, CODE_F01, CODE_PBO, CODE_PAI | Code only |
| Bug 3 | Old I/O fields ẩn khi editors fail | CODE_PBO | Code only |
| Bug 4 | Delete User luôn xoá dòng đầu | CODE_F01 | Code only |

**Không có SE41/SE51/SE75 changes** — round này chỉ sửa code.

---

## Thứ tự deploy (SAP SE38)

**Activate theo thứ tự:**
1. `Z_BUG_WS_TOP` (CODE_TOP)
2. `Z_BUG_WS_F00` (CODE_F00 — không đổi, nhưng activate cho chắc)
3. `Z_BUG_WS_F01` (CODE_F01)
4. `Z_BUG_WS_F02` (CODE_F02)
5. `Z_BUG_WS_PBO` (CODE_PBO)
6. `Z_BUG_WS_PAI` (CODE_PAI)
7. `Z_BUG_WORKSPACE_MP` (Main program)

---

## Chi tiết từng Bug

### Bug 1: Notes/Description không lưu được

**Root cause**: `SAVE_TEXT` FM buffer changes — **KHÔNG** tự COMMIT. Trong `save_bug_detail`, `COMMIT WORK` chạy TRƯỚC 3 lần gọi `save_long_text`. Kết quả: long text bị mất khi session kết thúc.

**Fix (2 thay đổi):**

#### 1a. CODE_F01 — `save_bug_detail` (line ~175)
Thêm `COMMIT WORK` **SAU** 3 lần gọi `save_long_text`:
```abap
" Save long text tabs (SAVE_TEXT buffers changes — needs explicit COMMIT)
PERFORM save_long_text USING 'Z001'.  " Description
PERFORM save_long_text USING 'Z002'.  " Dev Note
PERFORM save_long_text USING 'Z003'.  " Tester Note
COMMIT WORK.                          " Flush SAVE_TEXT buffer to DB
```

#### 1b. CODE_F02 — `save_long_text` + `save_long_text_direct`
Thêm `savemode_direct = 'X'` vào EXPORTING của cả 2 SAVE_TEXT calls:
```abap
CALL FUNCTION 'SAVE_TEXT'
  EXPORTING
    header          = ls_header
    savemode_direct = 'X'        " ← THÊM: write trực tiếp không qua buffer
  TABLES
    lines           = lt_lines
  EXCEPTIONS
    OTHERS          = 4.
```
> `savemode_direct = 'X'` bảo SAVE_TEXT commit trực tiếp thay vì buffer. Kết hợp với COMMIT WORK ở F01 = double safety.

---

### Bug 2: Project list stale + refresh bỏ qua filter

**Root cause (2 phần):**
1. `init_project_list` (PBO) chỉ load khi `go_alv_project IS INITIAL`. Khi BACK từ 0500 → ALV vẫn tồn tại → data KHÔNG reload → project mới không hiện.
2. REFRESH button gọi `select_project_data` — form này KHÔNG áp dụng search filters từ 0410.

**Fix (4 thay đổi):**

#### 2a. CODE_TOP — Thêm flag `gv_prj_list_dirty`
```abap
" gv_prj_list_dirty: set after save/delete project → tells PBO to reload
DATA: gv_prj_list_dirty  TYPE abap_bool.
```

#### 2b. CODE_F01 — `save_project_detail`
Thêm sau `gs_prj_snapshot = gs_project`:
```abap
gv_prj_list_dirty = abap_true.
```

#### 2c. CODE_F01 — `delete_project`
Thêm trước `PERFORM select_project_data`:
```abap
gv_prj_list_dirty = abap_true.
```

#### 2d. CODE_PBO — `init_project_list`
Thêm ELSEIF check dirty flag giữa `gv_from_search` và `go_alv_project IS INITIAL`:
```abap
ELSEIF gv_prj_list_dirty = abap_true.
  " Project was saved/deleted — reload with current search filters preserved
  PERFORM search_projects.
  CLEAR gv_prj_list_dirty.
```

#### 2e. CODE_PAI — `user_command_0400` REFRESH
Đổi `select_project_data` → `search_projects`:
```abap
WHEN 'REFRESH'.
  " Reload with search filters preserved (Bug 2 fix)
  PERFORM search_projects.
  IF go_alv_project IS NOT INITIAL.
    go_alv_project->refresh_table_display( ).
  ENDIF.
```

---

### Bug 3: Old I/O fields ẩn khi editors fail

**Root cause**: `modify_screen_0500` hide `GS_PROJECT-DESCRIPTION` và `GS_PROJECT-NOTE` vô điều kiện. Nếu Custom Controls (CC_PRJ_DESC, CC_PRJ_NOTE) không tạo được (Mac Screen Painter) → editors NULL → user thấy NOTHING.

**Fix: CODE_PBO — `modify_screen_0500`**
Chỉ hide khi editor tương ứng tạo thành công:
```abap
" Hide old Description/Note I/O fields ONLY when editors were created successfully.
IF screen-name = 'GS_PROJECT-DESCRIPTION' AND go_edit_prj_desc IS NOT INITIAL.
  screen-active = 0.
  MODIFY SCREEN.
ENDIF.
IF screen-name = 'GS_PROJECT-NOTE' AND go_edit_prj_note IS NOT INITIAL.
  screen-active = 0.
  MODIFY SCREEN.
ENDIF.
```

---

### Bug 4: Delete User luôn xoá dòng đầu

**Root cause**: `tc_users-current_line` sau PAI LOOP = index dòng cuối được xử lý, KHÔNG phải dòng user click. `GET CURSOR LINE` không hoạt động vì cursor đã di chuyển sang button.

**Fix: CODE_F01 — `remove_user_from_project`**
Thay thế hoàn toàn: dùng **F4 popup** (`F4IF_INT_TABLE_VALUE_REQUEST`) hiện danh sách users trong project → user chọn → confirm → delete.

Ưu điểm:
- Không phụ thuộc vào `tc_users-current_line`
- Không cần SE51 layout change
- User thấy rõ mình đang xoá ai

---

## Checklist sau deploy

- [ ] Activate tất cả 6 includes + main program (theo thứ tự ở trên)
- [ ] Test Bug 1: Tạo bug mới → nhập text ở Description/Dev Note/Tester Note tabs → Save → Back → mở lại bug → text vẫn còn
- [ ] Test Bug 2: Tạo project mới → Back → project hiện trong list. Click Refresh → chỉ hiện projects đã filter
- [ ] Test Bug 3: Nếu CC_PRJ_DESC/CC_PRJ_NOTE chưa tạo trên Screen 0500 → old I/O fields vẫn visible
- [ ] Test Bug 4: Vào Project Detail → có 3+ users → click Remove User → popup hiện danh sách → chọn user → confirm → đúng user bị xoá

## Lưu ý quan trọng

1. **SE75 vẫn cần đúng** cho Bug 1: Text Object `ZBUG` phải có Line Width = 132, 3 Text IDs: Z001 (Description), Z002 (Dev Note), Z003 (Tester Note). Nếu chưa configure → long text vẫn lỗi dù code đúng.

2. **SE51 Screen 0500 Custom Controls** (CC_PRJ_DESC, CC_PRJ_NOTE): Nếu chưa tạo được (Mac limitation) thì Bug 3 fix sẽ giữ old I/O fields visible — functional nhưng limited to 255 chars. Khi nào có Windows SAP GUI thì tạo Custom Controls sau.
