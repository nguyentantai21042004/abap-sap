# HƯỚNG DẪN TRIỂN KHAI CHI TIẾT — PHASE E: TESTING & GO-LIVE

**Dự án:** SAP Bug Tracking Management System  
**Ngày:** 24/03/2026 | **Phiên bản:** 5.0 (Module Pool Integration)  
**Thời gian ước tính:** 2 ngày (02-03/04)  
**Yêu cầu:** Hoàn thành Phase A + B + C + D trước  

---

## MỤC LỤC

1. [Bước E1: Cập nhật T-Code ZBUG_HOME](#bước-e1-cập-nhật-t-code-zbug_home)
2. [Bước E2: Unit Test — Function Modules (SE37)](#bước-e2-unit-test--function-modules)
3. [Bước E3: Integration Test — Full Workflow](#bước-e3-integration-test--full-workflow)
4. [Bước E4: Permission Matrix Test](#bước-e4-permission-matrix-test)
5. [Bước E5: Feature-Specific Tests](#bước-e5-feature-specific-tests)
6. [Bước E6: Clean Test Data + Demo Day Rehearsal](#bước-e6-clean-test-data--demo-day)

---

## Bước E1: Cập nhật T-Code ZBUG_HOME

**Mục tiêu:** Chuyển T-code `ZBUG_HOME` từ `Z_BUG_WORKSPACE` (SE38) sang `Z_BUG_WORKSPACE_MP` (Module Pool).

Vào **SE93** → nhập `ZBUG_HOME` → **Change** (hoặc Delete/Create mới).

1. Tạo `ZBUG_HOME`
2. Chọn **Dialog transaction**
3. **Program:** `Z_BUG_WORKSPACE_MP`
4. **Screen number:** `0100` (main hub)
5. Lựa chọn **GUI support** (Windows/Web GUI)
6. **Save**

> ✅ **Checkpoint:** Gõ `/nZBUG_HOME` → mở ngay cửa sổ Bug Tracking Workspace (Module Pool).

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

> ✅ **Checkpoint:** Cả 2 luồng đều hoàn tất End-to-end không phát sinh ABAP Dump.

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

- **GOS File Upload:** Upload 1 excel + 1 pdf. Chuyển sang History Tab hoặc GOS Component phải liệt kê đủ 2 file.
- **SmartForm Email:** Nội dung mail phải ở dạng HTML (không phải Plain Text thô bạo), đầy đủ field.
- **Đa Ngôn Ngữ:** Logout SAP, login lại Language = *VI*. Click các component, xem message pop-up phải ra Tiếng Việt.

---

## Bước E6: Clean Test Data + Demo Day Rehearsal

**Step 1: Clean test data (`SE38`)**

```abap
DELETE FROM zbug_tracker WHERE bug_id LIKE 'BUG9%'.
DELETE FROM zbug_project WHERE project_id LIKE 'TEST%'.
DELETE FROM zbug_history WHERE bug_id LIKE 'BUG9%'.
DELETE FROM zbug_user_project WHERE project_id LIKE 'TEST%'.
COMMIT WORK.
```

**Step 2: Demo Day Script (03/04/2026)**

- (2 phút) Giới thiệu hệ thống.
- (3 phút) Login Manager → Tạo project, Import Users.
- (3 phút) Login Tester → Tạo Code Bug → Mở form validation.
- (2 phút) Auto-assign chạy → Check mail SOST cho Demo.
- (3 phút) Developer fix bug, upload file đính kèm BDS.
- (1 phút) Show UI Tab Strip, History logging tự động.
- (1 phút) Show Excel Upload & Validation.

**Step 3: Transport Request**

1. Gộp toàn bộ object vào 1 Transport Request (TR).
2. Object list: Tables, Domains, DEs, Programs, Includes, FMs, SmartForms, Texts...
3. Release TR (SE10).

> 🎯 **ĐÍCH ĐẾN CUỐI CÙNG: 03/04/2026 GO-LIVE THÀNH CÔNG.**
