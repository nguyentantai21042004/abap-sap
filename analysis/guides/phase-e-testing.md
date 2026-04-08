# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE E: TESTING & GO-LIVE

**Dự án:** SAP Bug Tracking Management System
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)
**Thời gian ước tính:** 2 ngày (02-03/04)
**Yêu cầu:** Hoàn thành Phase A + B + C + D trước
**Development Account:**
- `DEV-118` (Pass: `Qwer123@`) — *Testing & Final Review*

---

## MỤC LỤC

1. [Bước E1: Cập nhật T-Code ZBUG_HOME + Deprecate T-Codes cũ](#bước-e1-cập-nhật-t-code-zbug_home--deprecate-t-codes-cũ)
2. [Bước E2: Unit Test — Function Modules (SE37)](#bước-e2-unit-test--function-modules)
3. [Bước E3: Integration Test — Full Workflow](#bước-e3-integration-test--full-workflow)
4. [Bước E4: Permission Matrix Test](#bước-e4-permission-matrix-test)
5. [Bước E5: Feature-Specific Tests](#bước-e5-feature-specific-tests)
6. [Bước E6: Clean Test Data + Demo Day Rehearsal](#bước-e6-clean-test-data--demo-day)

---

## Bước E1: Cập nhật T-Code ZBUG_HOME + Deprecate T-Codes cũ

### E1.1: Chuyển T-code ZBUG_HOME sang Module Pool

**Mục tiêu:** Chuyển T-code `ZBUG_HOME` từ `Z_BUG_WORKSPACE` (SE38) sang `Z_BUG_WORKSPACE_MP` (Module Pool).

Vào **SE93** → nhập `ZBUG_HOME` → **Change** (hoặc Delete/Create mới).

1. Tạo `ZBUG_HOME`
2. Chọn **Dialog transaction**
3. **Program:** `Z_BUG_WORKSPACE_MP`
4. **Screen number:** `0100` (main hub)
5. Lựa chọn **GUI support** (Windows/Web GUI)
6. **Save**

> ✅ **Checkpoint:** Gõ `/nZBUG_HOME` → mở ngay cửa sổ Bug Tracking Workspace (Module Pool).

### E1.2: Deprecate T-Codes cũ

**Mục tiêu:** Đánh dấu các T-codes cũ (SE38) là deprecated, chưa xóa — giữ làm fallback cho đến khi go-live ổn định.

Vào **SE93** → lần lượt mở từng T-code → **Change** → sửa **Description** thêm prefix `[DEPRECATED]`:

| T-Code | Description mới | Program cũ |
| :--- | :--- | :--- |
| `ZBUG_CREATE` | `[DEPRECATED] Use ZBUG_HOME - Create Bug` | `Z_BUG_CREATE_SCREEN` |
| `ZBUG_UPDATE` | `[DEPRECATED] Use ZBUG_HOME - Update Bug` | `Z_BUG_UPDATE_SCREEN` |
| `ZBUG_REPORT` | `[DEPRECATED] Use ZBUG_HOME - Bug Report` | `Z_BUG_REPORT_ALV` |
| `ZBUG_MANAGER` | `[DEPRECATED] Use ZBUG_HOME - Manager Dashboard` | `Z_BUG_MANAGER_DASHBOARD` |
| `ZBUG_PRINT` | `[DEPRECATED] Use ZBUG_HOME - Print Bug` | `Z_BUG_PRINT` |
| `ZBUG_USERS` | `[DEPRECATED] Use ZBUG_HOME - User Management` | `Z_BUG_USER_MANAGEMENT` |

> ⚠️ **Lưu ý:** KHÔNG xóa T-codes cũ. Chỉ xóa sau khi E6 testing confirm Module Pool hoạt động ổn định và go-live thành công.

> ✅ **Checkpoint:** Gõ `/nZBUG_CREATE` → vẫn mở được (fallback), nhưng description hiện `[DEPRECATED]`.

---

## Bước E2: Unit Test — Function Modules

**Mục tiêu:** Test từng FM bằng SE37, đảm bảo data manipulation chuẩn xác.

### Test Case 01: `Z_BUG_CHECK_PERMISSION`

- **TC-01a:** `IV_USER` = 'DEV-Manager', `IV_ACTION` = `CREATE_PROJECT`
  👉 **Expected:** `EV_ALLOWED` = `Y`
- **TC-01b:** `IV_USER` = 'DEV-Tester', `IV_ACTION` = `CREATE_PROJECT`
  👉 **Expected:** `EV_ALLOWED` = `N`, `EV_MESSAGE` = "Only Manager..."

### Test Case 02: `Z_BUG_CREATE`

- **TC-02a:** Basic creation.
  👉 **Expected:** `EV_SUCCESS` = `Y`, Return Bug ID hợp lệ.
- **TC-02b:** Severity=1 (Dump), Bug Type=C.
  👉 **Expected:** Priority force thành `H` (High).

### Test Case 03: `Z_BUG_UPDATE_STATUS`

- **TC-03a:** Valid transition: 1 → 2.
  👉 **Expected:** Success.
- **TC-03b:** Invalid transition: 1 → 5.
  👉 **Expected:** `EV_SUCCESS` = `N`.

### Test Case 04: `Z_BUG_AUTO_ASSIGN`

- **TC-04a:** Create Code Bug trong project có 1 active dev (role='D', is_del<>'X', thuộc project).
  👉 **Expected:** Bug tự động STATUS=2, DEV_ID = tên dev đó.
- **TC-04b:** Create Code Bug trong project có 0 active dev.
  👉 **Expected:** STATUS = 'W' (Waiting), DEV_ID = blank.

### Test Case 05: `Z_BUG_REASSIGN`

- **TC-05a:** Manager reassign bug từ Dev1 sang Dev2 (cùng project).
  👉 **Expected:** `EV_SUCCESS` = `Y`, DEV_ID = Dev2, STATUS = '2'.
- **TC-05b:** Manager reassign sang dev KHÔNG thuộc project.
  👉 **Expected:** `EV_SUCCESS` = `N`, "User is not a member of this project".

> ✅ **Checkpoint:** Tất cả test cases trên SE37 phải PASS (EV_SUCCESS = 'Y' cho valid cases).

---

## Bước E3: Integration Test — Full Workflow

**Mục tiêu:** Test toàn diện end-to-end user journey qua UI Module Pool.

### Workflow 01: Code Bug (Happy Path)

1. Logon Tester → **/nZBUG_HOME** → Create Code Bug (Sev=3, Prio=H).
2. STATUS=1 (New), DEV_ID = *Blank*.
3. Auto-Assign hoặc Manager manually assign → STATUS=2 (Assigned to Dev).
4. Logon Dev → Bug Detail → Update Status: 2 → 3 (In Progress).
5. Dev upload *TESTCASE* (GOS).
6. Dev update Status: 3 → 5 (Fixed).
7. Logon Tester → Check *TESTCASE*, upload *CONFIRM* (GOS), 5 → 6 (Resolved).
8. Logon Manager → Close Bug (6 → 7).
9. Mở **History Tab**: Phải có log CR, AS, IP, FX, RS, CL.
10. Check **SOST**: 3~4 emails đã gửi trong quá trình đổi trạng thái.

### Workflow 02: Config Bug (Tester Self-Fix)

1. Tester Create Bug: Type=F (Config).
2. Bug tự động chuyển STATUS=2, DEV_ID = Tên Tester.
3. Tester tự sửa → Đẩy trạng thái 2 → 3 → 5 → 6.
4. Manager close it.

### Workflow 03: Reject + Reassign Path

1. Tester tạo Code Bug → STATUS=1 (New).
2. Auto-assign → STATUS=2, DEV_ID = Dev1.
3. Dev1 reject → STATUS=R (Rejected).
4. Manager reassign sang Dev2 → STATUS=2, DEV_ID = Dev2.
5. Dev2 bắt đầu → STATUS=3 (InProgress).
6. Dev2 fix xong → STATUS=5 (Fixed), upload TESTCASE.
7. Tester verify pass → STATUS=6 (Resolved), upload CONFIRM.
8. Manager close → STATUS=7 (Closed).
9. Mở **History Tab**: Phải có log CR, AS, RJ, RS (Reassign), IP, FX, RS (Resolved), CL.

### Workflow 04: Pending Path

1. Bug đang ở STATUS=3 (InProgress).
2. Dev set Pending (chờ thông tin thêm) → STATUS=4 (Pending).
3. Dev resume khi có thông tin → STATUS=3 (InProgress).
4. Dev fix → STATUS=5 → Tester verify → STATUS=6 → Manager close → STATUS=7.
5. Mở **History Tab**: Phải có log chuyển 3→4, 4→3.

> ✅ **Checkpoint:** Cả 4 luồng đều hoàn tất End-to-end không phát sinh ABAP Dump.

---

## Bước E4: Permission Matrix Test

**Mục tiêu:** Áp đặt đúng quyền cho từng Role.

| Action | Tester (T) | Developer (D) | Manager (M) |
| :--- | :--- | :--- | :--- |
| **CREATE Bug** | ✅ | ❌ | ✅ |
| **UPDATE_STATUS**| ✅ (*1) | ✅ (*2) | ✅ |
| **DELETE Bug** | ❌ | ❌ | ✅ |
| **UPLOAD_REPORT**| ✅ (*3) | ❌ | ✅ |
| **UPLOAD_FIX** | ✅ (*4) | ✅ (*2) | ✅ |
| **CREATE/CHANGE PRJ**| ❌ | ❌ | ✅ |

*Chú thích:*

- (*1): Mới tạo Status=1 hoặc Config bug do mình giữ.
- (*2): Chỉ bug đang được giao (DEV_ID).
- (*3): Chỉ bug do chính Tester tạo ra.
- (*4): Config bug do chính Tester giữ.

> ✅ **Checkpoint:** Thử nghiệm sai Role → Lỗi "Not authorized to update this bug" (s006).

---

## Bước E5: Feature-Specific Tests

### E5.1: GOS File Upload
Upload 1 excel + 1 pdf. Chuyển sang Evidence Tab (0350) hoặc GOS Component phải liệt kê đủ 2 file.

### E5.2: SmartForm Email
Nội dung mail phải ở dạng HTML (không phải Plain Text thô bạo), đầy đủ field. Check **SOST** để xác nhận.

### E5.3: Đa Ngôn Ngữ
Logout SAP, login lại Language = *VI*. Click các component, xem message pop-up phải ra Tiếng Việt.

### E5.4: Long Text (Dev Note / Tester Note / Root Cause)

1. Mở Bug Detail → Tab **Developer Note** (0320).
2. Nhập text dài (nhiều dòng, có ký tự đặc biệt).
3. **Save** → Đóng Bug Detail → Mở lại.
4. Text phải persist đúng nguyên vẹn (qua `READ_TEXT`).
5. Check **SE75** → Text Object `ZBUG` → Text ID `Z001` → nhập Bug ID → xem text đã lưu.
6. Lặp lại cho Tab **Tester Note** (0330, Text ID `Z002`) và **Root Cause** (0340, Text ID `Z003`).

> ✅ **Checkpoint:** Long Text lưu và đọc lại chính xác, không mất dữ liệu.

### E5.5: Status Migration Verification

**Mục tiêu:** Xác nhận report `Z_BUG_MIGRATE_STATUS` (Phase A, Bước A8) đã chạy đúng.

1. **SE16** → `ZBUG_TRACKER`:
   - Không còn record nào có `STATUS = '4'` mà KHÔNG phải Pending (kiểm tra các bug cũ đã migrate từ Fixed→5).
   - Không còn record nào có `STATUS = '6'` theo nghĩa cũ (Deleted) — tất cả đã có `IS_DEL = 'X'`.
   - Tất cả bug cũ có `STATUS = '5'` (old Closed) giờ hiện `STATUS = '7'`.
2. **SE16** → `ZBUG_HISTORY`:
   - Kiểm tra old_value/new_value đã được remap tương ứng (4→5, 5→7).

> ✅ **Checkpoint:** Không còn status code cũ nào conflict với 9-state model mới.

---

## Bước E6: Clean Test Data + Demo Day Rehearsal

**Step 1: Clean test data (`SE38`)**

```abap
DELETE FROM zbug_tracker WHERE bug_id LIKE 'BUG9%'.
DELETE FROM zbug_project WHERE project_id LIKE 'TEST%'.
DELETE FROM zbug_history WHERE bug_id LIKE 'BUG9%'.
DELETE FROM zbug_user_projec WHERE project_id LIKE 'TEST%'.
COMMIT WORK.
```

**Step 2: Demo Day Script (03/04/2026)**

- (2 phút) Giới thiệu hệ thống, tổng quan kiến trúc Module Pool.
- (3 phút) Login Manager → Tạo project, Import Users.
- (3 phút) Login Tester → Tạo Code Bug → Mở form validation.
- (2 phút) Auto-assign chạy → Check mail SOST cho Demo.
- (3 phút) Developer fix bug, upload file đính kèm BDS (Evidence Tab).
- (1 phút) Show Reject + Reassign flow (Dev reject → Manager reassign).
- (1 phút) Show Long Text notes (Dev Note, Tester Note tabs).
- (1 phút) Show UI Tab Strip 6 tabs, History logging tự động.
- (1 phút) Show Excel Upload & Validation (Project Upload).
- (1 phút) Show Pending flow (3→4→3).

**Step 3: Transport Request**

1. Gộp toàn bộ object vào 1 Transport Request (TR).
2. Object list: Tables, Domains, DEs, Programs, Includes, FMs, SmartForms, Texts...
3. Release TR (SE10).

> 🎯 **ĐÍCH ĐẾN CUỐI CÙNG: 03/04/2026 GO-LIVE THÀNH CÔNG.**
