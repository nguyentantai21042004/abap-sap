# Legacy Artifact Removal Guide — Z_BUG_WORKSPACE_MP

> **Version:** 1.0 — 11/04/2026
> **Mục đích:** Hướng dẫn chi tiết xoá toàn bộ legacy/unused artifacts trong SAP system sau khi chuyển sang Module Pool `Z_BUG_WORKSPACE_MP` với T-code `ZBUG_WS` (Screen 0400).
> **Lưu ý:** Chỉ thực hiện SAU KHI QC test pass và hệ thống stable. Backup trước khi xoá.

---

## 1. DEPRECATED TRANSACTION CODES (SE93)

Các T-code cũ đã được thay thế hoàn toàn bởi `ZBUG_WS`:

| T-code | Program cũ | Lý do xoá |
|--------|-----------|-----------|
| `ZBUG_CREATE` | `Z_BUG_CREATE_SCREEN` | Create Bug nằm trong Screen 0300 (mode X) |
| `ZBUG_UPDATE` | `Z_BUG_UPDATE_SCREEN` | Change Bug nằm trong Screen 0300 (mode C) |
| `ZBUG_REPORT` | `Z_BUG_REPORT_ALV` | Bug List nằm trong Screen 0200 |
| `ZBUG_MANAGER` | `Z_BUG_MANAGER_DASHBOARD` | Dashboard bị CANCELLED (Screen 0100 deprecated) |
| `ZBUG_PRINT` | `Z_BUG_PRINT` | Print chưa implement (SmartForm ZBUG_FORM chưa build) |
| `ZBUG_USERS` | (unknown) | User Management nằm trong Screen 0500 (Add/Remove User) |

### Cách xoá:

1. **SE93** → nhập T-code cần xoá (vd: `ZBUG_CREATE`)
2. Menu: **Transaction Code → Delete** (hoặc nhấn nút Delete)
3. Confirm → nhập Package `ZBUGTRACK` → Save to Transport Request
4. Lặp lại cho từng T-code

### Kiểm tra trước khi xoá:

```
SE93 → nhập T-code → nếu thấy "does not exist" → đã xoá hoặc chưa tạo → bỏ qua
```

---

## 2. DEPRECATED PROGRAMS (SE38/SE80)

Các programs standalone cũ (nếu tồn tại) — đã thay thế bởi Module Pool:

| Program | Mô tả | Thay thế bởi |
|---------|--------|--------------|
| `Z_BUG_CREATE_SCREEN` | Tạo bug (standalone) | Screen 0300 mode X |
| `Z_BUG_UPDATE_SCREEN` | Sửa bug (standalone) | Screen 0300 mode C |
| `Z_BUG_REPORT_ALV` | Bug report ALV | Screen 0200 |
| `Z_BUG_MANAGER_DASHBOARD` | Manager dashboard | CANCELLED |
| `Z_BUG_PRINT` | Print bug PDF | Chưa implement |

### Cách xoá:

1. **SE38** → nhập tên program → **Display**
2. Nếu tồn tại: Menu **Program → Delete** → Confirm → Save to TR
3. Nếu "does not exist" → bỏ qua (chưa bao giờ tạo)

> **Lưu ý:** Có thể các program này chưa bao giờ được tạo trong SAP. Chỉ xoá nếu tồn tại.

---

## 3. UNUSED FUNCTION MODULES (SE37)

Requirements spec (Section 3) định nghĩa 10 Function Modules trong Function Group `ZBUG_FG`. Tuy nhiên, **KHÔNG CÓ FM NÀO được gọi** bởi Module Pool code. Tất cả business logic đều inline trong FORM routines (`Z_BUG_WS_F01`).

| FM | Mô tả | Status |
|----|--------|--------|
| `Z_BUG_CREATE` | Tạo bug | NOT CALLED — logic in `FORM save_bug_detail` |
| `Z_BUG_AUTO_ASSIGN` | Auto-assign dev | NOT CALLED — chưa implement auto-assign |
| `Z_BUG_UPDATE_STATUS` | Update status | NOT CALLED — logic in `FORM change_bug_status` |
| `Z_BUG_CHECK_PERMISSION` | Check quyền | NOT CALLED — role check inline |
| `Z_BUG_LOG_HISTORY` | Ghi history | NOT CALLED — logic in `FORM add_history_entry` |
| `Z_BUG_SEND_EMAIL` | Gửi email | NOT CALLED — logic in `FORM send_mail_notification` |
| `Z_BUG_UPLOAD_ATTACHMENT` | Upload file | NOT CALLED — logic in `FORM upload_evidence` |
| `Z_BUG_REASSIGN` | Reassign dev | NOT CALLED — logic in `FORM change_bug_status` |
| `Z_BUG_GET_STATISTICS` | Dashboard stats | NOT CALLED — Dashboard CANCELLED |
| `Z_BUG_GOS_UPLOAD` / `Z_BUG_GOS_LIST` | GOS integration | NOT CALLED — Evidence tự viết (ZBUG_EVIDENCE) |

### Cách xoá:

1. **SE37** → nhập tên FM → nếu tồn tại thì **Delete**
2. Hoặc xoá toàn bộ Function Group: **SE80** → Function Group `ZBUG_FG` → Right-click → Delete
3. Save to Transport Request

### Quan trọng:

- **Kiểm tra trước:** `SE37 → Where-Used List` cho mỗi FM để chắc chắn không có program nào khác gọi
- Nếu Phase B đã build xong (user chưa xác nhận), FMs có thể tồn tại nhưng không ai dùng
- **Nếu không chắc** → giữ nguyên, chỉ đánh dấu "DEPRECATED" trong description

---

## 4. UNUSED SMARTFORMS (SMARTFORMS)

| SmartForm | Mô tả | Status |
|-----------|--------|--------|
| `ZBUG_FORM` | Print Bug Detail PDF | **CHƯA BUILD** — SmartForm program không tồn tại |
| `ZBUG_EMAIL_FORM` | Email body template HTML | **KHÔNG CẦN** — Email dùng BCS API trực tiếp (plain text) |

### Cách kiểm tra + xoá:

1. **T-code SMARTFORMS** → nhập tên → Display
2. Nếu "does not exist" → bỏ qua
3. Nếu tồn tại nhưng không dùng → Delete → Save to TR

> **Decision:** Email dùng BCS API (`cl_bcs` + `cl_document_bcs`) với RAW text. SmartForm email **KHÔNG CẦN**.

---

## 5. UNUSED NUMBER RANGE (SNRO)

| Object | Mô tả | Status |
|--------|--------|--------|
| `ZNRO_BUG` | Bug ID number range | **KHÔNG ĐƯỢC DÙNG** — Auto-ID dùng `SELECT MAX(bug_id) + 1` |

### Code hiện tại (CODE_F01.md line 156-165):

```abap
" Auto-generate Bug ID: BUG + 7-digit number
SELECT MAX( bug_id ) FROM zbug_tracker INTO @lv_max_id.
lv_num_str = lv_max_id+3(7).
lv_num = CONV i( lv_num_str ) + 1.
gs_bug_detail-bug_id = |BUG{ lv_num WIDTH = 7 ALIGN = RIGHT PAD = '0' }|.
```

### Quyết định:

- **Option A (Recommended):** Giữ `ZNRO_BUG` nhưng đánh dấu "unused". Không gây hại, tốn 0 resource.
- **Option B:** Xoá qua `SNRO` → nhập `ZNRO_BUG` → Delete. Cần xoá cả Intervals trước.

> **Rủi ro xoá:** Nếu tương lai muốn chuyển sang number range (chính xác hơn cho concurrent access), phải tạo lại.

---

## 6. SCREEN 0100 DEAD CODE

Screen 0100 (Hub/Router) đã **DEPRECATED** — không có navigation nào dẫn tới (T-code `ZBUG_WS` → Screen 0400).

### Dead code trong includes:

| Location | Code | Purpose |
|----------|------|---------|
| `CODE_PBO.md` line 22-25 | `MODULE status_0100` | Set PF-STATUS, SET TITLEBAR cho Screen 0100 |
| `CODE_PAI.md` line 16-27 | `MODULE user_command_0100` | Handle BACK/BUG_LIST/PROJ_LIST commands |

### GUI Status trong SE41:

| Status | Screen | Dead? |
|--------|--------|-------|
| `STATUS_0100` | 0100 | **YES** — không ai gọi |
| `TITLE_MAIN` | 0100 | **YES** — không ai gọi |

### Quyết định:

- **Option A (Recommended — hiện tại):** Giữ nguyên code + GUI Status "for safety". Nếu tương lai muốn mở lại Dashboard, có sẵn.
- **Option B (Clean up):**
  1. Xoá Screen 0100 trong SE51
  2. Comment out `MODULE status_0100` + `MODULE user_command_0100` trong code
  3. Xoá `STATUS_0100` trong SE41
  4. Re-compile, activate

---

## 7. MIGRATION SCRIPTS (SE38)

| Program | Mục đích | Status |
|---------|----------|--------|
| `Z_BUG_MIGRATE_STATUS` | Migrate status codes (1-char → multi-char) | **ĐÃ CHẠY XONG** — one-time |
| `Z_BUG_CLEANUP_ORPHAN` | Gán orphan bugs vào project "LEGACY" | **CHƯA CHẠY** — optional |

### Cách xử lý:

- `Z_BUG_MIGRATE_STATUS`: **Có thể xoá** sau khi xác nhận data đã migrate thành công (check `ZBUG_TRACKER` status field values qua SE16)
- `Z_BUG_CLEANUP_ORPHAN`: **Giữ lại** cho đến khi chạy xong. Sau đó có thể xoá.

### Kiểm tra migration đã xong:

```sql
" SE16 → ZBUG_TRACKER → check STATUS column
" Nếu tất cả status = '1','2','3','4','5','6','7','W','R' → migration OK
" Nếu còn giá trị cũ (New, Assigned, etc.) → CHƯA migrate xong
```

---

## 8. OUTDATED DOCUMENTATION FILES (trong repo)

Các file đã OUTDATED — có thể archive hoặc đánh dấu:

| File | Lý do | Action |
|------|-------|--------|
| `docs/phases/phase-c-module-pool.md` | v2.0, OUTDATED — thay bằng `screens/` | Đánh dấu "OUTDATED" ở đầu file |
| `docs/phases/phase-e-testing.md` | Partially outdated — test checklist mới ở `docs/final-steps.md` | Đánh dấu "PARTIALLY OUTDATED" |
| `docs/phases/phase-d-advanced-features.md` | Code đã integrate vào CODE files | Đánh dấu "INTEGRATED — see src/" |

### Không xoá:

Các file documentation **KHÔNG NÊN XOÁ** — giữ cho historical reference. Chỉ thêm disclaimer ở đầu file.

---

## 9. SESSION ARTIFACTS

| File pattern | Mô tả | Action |
|-------------|--------|--------|
| `ses_*.json` | OpenCode agent session files | Xoá nếu không cần (`.gitignore` đã skip) |
| `.specstory/` | Cursor AI history | Xoá nếu không cần |

### Cách xoá:

```bash
# Trong repo root
rm -f ses_*.json
rm -rf .specstory/
```

---

## 10. TEXT OBJECT NAME DISCREPANCY

| Source | Object Name |
|--------|------------|
| `requirements.md` Section 2.7 | `ZBUG_NOTE` |
| `CONTEXT.md` Section 4 | `ZBUG` |
| Actual code (`CODE_F02.md` line 348) | `ZBUG` |

### Kết luận:

- Code dùng `ZBUG` — đây là tên **thật** trong SAP system
- `ZBUG_NOTE` trong requirements là tên dự kiến ban đầu, **CHƯA BAO GIỜ TẠO**
- **Không cần action** — chỉ cần biết discrepancy này tồn tại

---

## 11. THỨ TỰ XOÁ KHUYẾN NGHỊ

Nếu quyết định clean up, thực hiện theo thứ tự sau:

1. **Backup** — tạo Transport Request mới cho tất cả objects cần xoá
2. **T-codes** (SE93) — xoá 6 deprecated T-codes
3. **Programs** (SE38) — xoá 5 standalone programs (nếu tồn tại)
4. **Function Modules** (SE37/SE80) — xoá từng FM hoặc cả function group (nếu tồn tại)
5. **SmartForms** (SMARTFORMS) — xoá 2 SmartForms (nếu tồn tại)
6. **Screen 0100** — optional: xoá screen + comment code + xoá GUI Status
7. **Migration scripts** — xoá `Z_BUG_MIGRATE_STATUS` (đã chạy xong)
8. **Number Range** — giữ nguyên (không gây hại)
9. **Repo documentation** — đánh dấu outdated files

---

## 12. OBJECTS GIỮ LẠI (KHÔNG XOÁ)

| Object | Lý do giữ |
|--------|-----------|
| `ZBUG_WS` (T-code) | Entry point chính |
| `Z_BUG_WORKSPACE_MP` (Program) | Module Pool chính |
| 6 includes (`Z_BUG_WS_TOP/F00/PBO/PAI/F01/F02`) | Source code |
| 11 Screens (0100-0500 + subscreens) | UI |
| 5 GUI Statuses | Toolbar/menu |
| 6 DB Tables | Data layer |
| Text Object `ZBUG` | Long text storage |
| Message Class `ZBUG_MSG` | Error/info messages |
| 4 SMW0 Templates | Excel templates |
| `Z_BUG_CLEANUP_ORPHAN` | Chưa chạy |

---

*File này được tạo bởi OpenCode agent. Cập nhật: 11/04/2026 v1.0*
