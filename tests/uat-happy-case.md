# UAT Happy Case Test — Z_BUG_WORKSPACE_MP v5.0

> **Mục đích:** Test nghiệm thu cơ bản cho user thường — chỉ các happy case chính.
> Không yêu cầu kiểm tra edge case, negative case, hay boundary.
>
> **T-code:** `ZBUG_WS` | **SAP System:** S40 | **Client:** 324
> **Version:** v5.0 | **Updated:** 14/04/2026
>
> **Tài khoản test:**
>
> | Tài khoản | Vai trò | Mật khẩu |
> |-----------|---------|----------|
> | `DEV-089` | Manager (M) | `@Anhtuoi123` |
> | `DEV-061` | Developer (D) | `@57Dt766` |
> | `DEV-118` | Tester (T) | `Qwer123@` |
>
> **v5.0 thay đổi chính:**
> - Màn hình đầu tiên là **Project Search (0410)** — lọc project trước khi vào danh sách
> - **Dashboard** hiển thị số liệu tổng hợp trên màn hình Bug List
> - **Tìm kiếm Bug** qua popup riêng (nút SEARCH)
> - **Chuyển trạng thái** qua popup 0370 (không sửa trực tiếp trên form)
> - **10 trạng thái bug** (thêm Final Testing, Waiting; Resolved giờ là `V`)
> - **Tự động phân công** Developer/Tester dựa trên module + workload

---

## Ký hiệu

| Ký hiệu | Ý nghĩa |
|---------|---------|
| **P** | Pass |
| **F** | Fail — ghi chú lý do |
| `[M]` | Login bằng Manager |
| `[D]` | Login bằng Developer |
| `[T]` | Login bằng Tester |

---

## A. Truy cập & Di chuyển (7 trường hợp)

> Đăng nhập: **DEV-089 (Manager)**

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|---------------------|-------------------------------|---------------------------------------------|----------|----------|
| A1 | Vào chương trình | Gõ `/nZBUG_WS` → Enter | Màn hình **Project Search (0410)** hiển thị — 3 ô tìm kiếm | | |
| A2 | Từ Project Search → Project List | Bấm `Execute` (F8) — để trống hết | Màn hình Project List (0400) hiển thị tất cả dự án | | |
| A3 | Từ Project List → Bug List | Double-click vào 1 project | Màn hình Bug List (0200) hiển thị, tiêu đề có tên project, có Dashboard ở trên | | |
| A4 | Từ Bug List → Bug Detail | Chọn 1 bug → bấm `Display` | Màn hình Bug Detail (0300) hiển thị, dữ liệu đúng | | |
| A5 | Quay lại từng bước | Bấm `Back` (F3) liên tục | 0300 → 0200 → 0400 → 0410 (về Project Search) | | |
| A6 | Thoát chương trình | Ở màn hình 0410 → bấm `Back` (F3) | Thoát về SAP Menu | | |
| A7 | Exit nhanh | Ở bất kỳ màn hình nào → bấm `Exit` (Shift+F3) | Thoát về SAP Menu | | |

---

## B. Tìm kiếm Project — Screen 0410 (5 trường hợp)

> Đăng nhập: **DEV-089 (Manager)**

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|---------------------|-------------------------------|---------------------------------------------|----------|----------|
| B1 | Tìm theo Project ID | Nhập Project ID → bấm Execute | Chỉ hiện đúng project đó trong danh sách | | |
| B2 | Tìm theo Manager | Nhập Manager ID → Execute | Chỉ hiện projects của manager đó | | |
| B3 | Tìm theo Status | Nhập Status = 2 (In Process) → Execute | Chỉ hiện projects đang In Process | | |
| B4 | F4 chọn giá trị | Bấm F4 trên ô Project ID | Popup hiện danh sách projects, chọn được → điền vào ô | | |
| B5 | Không nhập gì → xem tất cả | Để trống 3 ô → Execute | Hiện tất cả projects user có quyền xem | | |

---

## C. Quản lý Project (6 trường hợp)

> Đăng nhập: **DEV-089 (Manager)**

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|------------------------|--------------------------------------|-----------------------------------------|----------|----------|
| C1 | Tạo project mới | Project List → `Create Project` → điền Project Name → `Save` | Project ID tự động sinh (vd `PRJ0000001`), thông báo thành công | | |
| C2 | Xem project | Chọn project → `Display` | Màn hình Project Detail, tất cả fields chỉ đọc | | |
| C3 | Sửa project | Chọn project → `Change` → sửa tên → `Save` | Tên được cập nhật, thông báo thành công | | |
| C4 | Thêm user vào project | Trong Project Detail → `Add User` → nhập User ID + Role (M/D/T) | User hiển trong bảng, lưu thành công | | |
| C5 | Xóa user khỏi project | Chọn dòng user → `Remove User` → Confirm | User biến mất khỏi bảng | | |
| C6 | Xóa project | Project List → chọn project → `Delete` → Confirm | Project biến mất khỏi danh sách | | |

---

## D. Quản lý Bug — Tạo & Sửa (7 trường hợp)

> Đăng nhập: **DEV-118 (Tester)** để tạo bug, **DEV-089 (Manager)** để sửa

| # | Mô tả | Cách làm | Kết quả đúng | Đăng nhập | Trạng thái | Ghi chú |
|----|------------------------------|-------------------------------------|--------------------------------------|----------|---------|---------|
| D1 | Tạo bug mới | Bug List → `Create` → điền Title → `Save` | Bug ID tự động sinh, trạng thái = New hoặc Assigned (auto-assign) | `[T]` | | |
| D2 | PROJECT_ID tự động điền | Khi tạo bug từ project context | PROJECT_ID đã có sẵn, không cho sửa | `[T]` | | |
| D3 | F4 chọn Priority | Bấm F4 trên field Priority | Popup hiện: High / Medium / Low → chọn được | `[T]` | | |
| D4 | F4 chọn Severity | Bấm F4 trên field Severity | Popup hiện: Dump, Very High, High, Normal, Minor | `[T]` | | |
| D5 | Sửa bug | Bug List → chọn bug → `Change` → sửa Title → `Save` | Title cập nhật, thông báo thành công | `[M]` | | |
| D6 | Xem bug chỉ đọc | Chọn bug → `Display` | Tất cả fields disable, không gõ được | `[M]` | | |
| D7 | Xóa bug | Chọn bug → `Delete` → Confirm | Bug biến mất khỏi danh sách | `[M]` | | |

---

## E. Tab Strip — 6 Tab (6 trường hợp)

> Đăng nhập: **DEV-089 (Manager)** — mở 1 bug ở chế độ Change

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|-------------------------|------------------------------|------------------------------|----------|-----------|
| E1 | Tab Bug Info | Click tab "Bug Info" | Hiện input fields + mini editor mô tả | | |
| E2 | Tab Description | Click tab "Description" | Hiện text editor lớn | | |
| E3 | Tab Dev Note | Click tab "Dev Note" | Hiện text editor | | |
| E4 | Tab Tester Note | Click tab "Tester Note" | Hiện text editor | | |
| E5 | Tab Evidence | Click tab "Evidence" | Hiện bảng Evidence (có thể trống) | | |
| E6 | Tab History | Click tab "History" | Hiện bảng lịch sử thao tác | | |

---

## F. Chuyển trạng thái Bug — qua Popup 0370 (7 trường hợp)

> **Luồng chính v5.0:** New → Assigned → In Progress → Fixed → [Tự động] Final Testing → Resolved
>
> **Quan trọng:** Trạng thái KHÔNG sửa trực tiếp — phải bấm nút **Change Status** để mở popup.
>
> Cần đổi account theo vai trò:

| # | Mô tả | Cách làm | Kết quả đúng | Đăng nhập | Trạng thái | Ghi chú |
|----|----------------------------------|-----------------------------------------------------------|-------------------------------------|----------|--------|---------|
| F1 | New → Assigned | Mở bug (New) → `Change Status` → popup hiện → chọn "Assigned" → nhập DEV_ID → Confirm | Status đổi thành Assigned, DEV_ID được gán | `[M]` | | |
| F2 | Assigned → In Progress | Mở bug (Assigned) → `Change Status` → chọn "In Progress" → Confirm | Status đổi thành In Progress | `[D]` | | |
| F3 | In Progress → Fixed | Mở bug → upload evidence trước (tab Evidence) → `Change Status` → chọn "Fixed" → Confirm | Status đổi thành Fixed *(cần có evidence)* | `[D]` | | |
| F4 | Fixed → Final Testing (tự động) | Sau khi chuyển sang Fixed | Hệ thống tự động tìm Tester → gán VERIFY_TESTER_ID → chuyển sang Final Testing | `[D]` | | |
| F5 | Final Testing → Resolved | Mở bug (Final Testing) → `Change Status` → chọn "Resolved" → nhập ghi chú → Confirm | Status đổi thành Resolved (V) — trạng thái kết thúc | `[T]` | | |
| F6 | Popup hiện đúng thông tin | Mở popup Change Status | Thấy: Bug ID, Title, Reporter, Status hiện tại (chỉ đọc) + dropdown chọn status mới | `[M]` | | |
| F7 | Hủy popup | Popup → bấm Cancel (F12) | Popup đóng, status không đổi | `[M]` | | |

> **Lưu ý F3:** Trước khi chuyển Fixed, phải upload ít nhất 1 file evidence ở tab Evidence.
>
> **Lưu ý F4:** Nếu không tìm được Tester phù hợp (cùng module, workload < 5), bug sẽ chuyển sang Waiting (W) thay vì Final Testing.

---

## G. Evidence — Upload & Download (4 trường hợp)

> Đăng nhập: **DEV-089 (Manager)** — mở bug ở chế độ Change

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|------------------|--------------------------------------|--------------------------------------------------|----------|---------|
| G1 | Upload evidence | Tab Evidence → `Upload Evidence` → chọn file | File hiện trong bảng Evidence, EVD_ID tự động tăng | | |
| G2 | Download evidence | Chọn 1 dòng → `Download Evidence` | Popup lưu file → file download thành công | | |
| G3 | Upload Report | Bấm `Upload Report` → chọn file | File lưu vào evidence, field ATT_REPORT cập nhật | | |
| G4 | Upload Fix | Bấm `Upload Fix` → chọn file | File lưu vào evidence, field ATT_FIX cập nhật | | |

---

## H. Dashboard — Số liệu tổng hợp (4 trường hợp)

> Đăng nhập: **DEV-089 (Manager)** — vào Bug List từ 1 project

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|------------------|--------------------------------------|--------------------------------------------------|----------|---------|
| H1 | Dashboard hiển thị | Vào Bug List (0200) | Phía trên bảng bug có Dashboard: Total, By Status, By Priority, By Module | | |
| H2 | Tổng số đúng | Đếm bugs trong bảng | Số "Total" trên dashboard = số dòng trong bảng | | |
| H3 | Theo trạng thái đúng | Đếm bugs theo từng status | Số New + Assigned + ... = Total | | |
| H4 | Cập nhật sau thay đổi | Đổi status 1 bug → Refresh | Dashboard cập nhật số liệu mới | | |

---

## I. Tìm kiếm Bug (5 trường hợp)

> Đăng nhập: **DEV-089 (Manager)** — ở Bug List (0200)

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|---------------------|-------------------------------------|----------------------------------------------|----------|---------|
| I1 | Mở popup tìm kiếm | Bấm nút `Search` | Popup tìm kiếm hiện ra — 6 ô nhập (Bug ID, Title, Status, Priority, Module, Reporter) | | |
| I2 | Tìm theo Bug ID | Nhập Bug ID → Execute | Màn hình kết quả hiện đúng bug đó | | |
| I3 | Tìm theo từ khóa Title | Nhập keyword (vd "login") → Execute | Kết quả hiện các bug có title chứa "login" | | |
| I4 | Tìm theo Status | Chọn Status = In Progress → Execute | Kết quả chỉ hiện bugs đang In Progress | | |
| I5 | Xem bug từ kết quả | Chọn bug → `Display` | Mở Bug Detail — dữ liệu đúng | | |

---

## J. Tự động phân công (3 trường hợp)

> **v5.0:** Hệ thống tự tìm Developer/Tester phù hợp dựa trên module + số bug đang xử lý.

| # | Mô tả | Cách làm | Kết quả đúng | Đăng nhập | Trạng thái | Ghi chú |
|----|------------------------------------|---------------------------------|-----------------------------------------------|----------|----------|---------|
| J1 | Tạo bug → tự gán Developer | Tạo bug có SAP Module = FI → Save | DEV_ID tự điền dev FI có ít bug nhất, status = Assigned | `[T]` | | |
| J2 | Fixed → tự gán Tester | Bug chuyển sang Fixed | VERIFY_TESTER_ID tự điền tester cùng module, status = Final Testing | `[D]` | | |
| J3 | Không có người phù hợp → Waiting | Tạo bug module không có Dev nào | Status = Waiting (W), DEV_ID trống | `[T]` | | |

---

## K. Email (1 trường hợp)

> Đăng nhập: **DEV-089 (Manager)** — mở bug có Developer và Tester được assign

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|--------------------|-----------------------------|-----------------------------------------------|----------|---------|
| K1 | Gửi email thông báo | Bấm `SENDMAIL` | Message "Email sent", kiểm tra SOST thấy email | | |

---

## L. Template Download (3 trường hợp)

> Đăng nhập: **DEV-089 (Manager)**

| # | Mô tả | Cách làm | Kết quả đúng | Trạng thái | Ghi chú |
|----|------------------------------|---------------------------------------|-----------------------------|----------|---------|
| L1 | Download Project Template | Screen 0400 → `Download Template` | File Excel download từ SMW0 | | |
| L2 | Download Bug Report Template | Screen 0200 → `Download Testcase` | File `Bug_report.xlsx` download | | |
| L3 | Upload Excel tạo projects | Screen 0400 → `Upload` → chọn file Excel hợp lệ | Projects được tạo, danh sách refresh | | |

---

## M. Phân quyền cơ bản (4 trường hợp)

| # | Mô tả | Cách làm | Kết quả đúng | Đăng nhập | Trạng thái | Ghi chú |
|----|-----------------------------------------------|--------------------------------------|------------------------------------|----------|----------|-------|
| M1 | Developer KHÔNG tạo bug được | Login Dev → Bug List → `Create` | Message từ chối hoặc nút không hiện | `[D]` | | |
| M2 | Developer KHÔNG xóa bug được | Login Dev → chọn bug → `Delete` | Message từ chối hoặc nút không hiện | `[D]` | | |
| M3 | Dev/Tester KHÔNG tạo project | Login Dev hoặc Tester → `Create Project` | Message từ chối | `[D]` | | |
| M4 | Manager làm được tất cả | Login Manager → thử tạo/sửa/xóa project và bug | Tất cả thao tác thành công | `[M]` | | |

---

## N. My Bugs (2 trường hợp)

| # | Mô tả | Cách làm | Kết quả đúng | Đăng nhập | Trạng thái | Ghi chú |
|----|---------------------------|-------------------------------------|--------------------------------------------------------|----------|----------|-------|
| N1 | My Bugs — Developer | Screen 0400 → `My Bugs` | Chỉ hiển bugs có Developer = tài khoản đang login | `[D]` | | |
| N2 | My Bugs — Tester | Screen 0400 → `My Bugs` | Chỉ hiển bugs mình là Tester hoặc Verify Tester | `[T]` | | |

---

## Tổng kết

| Mục | Số trường hợp |
|-----|:-------------:|
| A. Truy cập & Di chuyển | 7 |
| B. Tìm kiếm Project | 5 |
| C. Quản lý Project | 6 |
| D. Quản lý Bug | 7 |
| E. Tab Strip | 6 |
| F. Chuyển trạng thái | 7 |
| G. Evidence | 4 |
| H. Dashboard | 4 |
| I. Tìm kiếm Bug | 5 |
| J. Tự động phân công | 3 |
| K. Email | 1 |
| L. Template Download | 3 |
| M. Phân quyền | 4 |
| N. My Bugs | 2 |
| **Tổng** | **64** |

> **Lưu ý:** Đây chỉ là happy case — các trường hợp lỗi, edge case, và boundary test nằm trong **QC Test Plan** (`tests/qc-test-plan.md`).

---

*Generated by OpenCode agent — 14/04/2026*
