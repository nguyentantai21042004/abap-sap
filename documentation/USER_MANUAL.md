# SAP Bug Tracking Management System - User Manual

**Ngày báo cáo:** 11/03/2026
**Dành cho:** End-Users (Tester, Developer, Manager)

---

## 1. TỔNG QUAN HỆ THỐNG

Hệ thống SAP Bug Tracking (SAP-BTMS) cung cấp 6 phân hệ (T-Code) chính để quản lý toàn bộ vòng đời của một lỗi phần mềm (Bug) từ lúc sinh ra đến lúc đóng lại. 

| T-Code | Tên chức năng | Phân quyền truy cập |
| :--- | :--- | :--- |
| **ZBUG_CREATE** | Tạo Bug Mới | Tester |
| **ZBUG_UPDATE** | Cập nhật & Xử lý Bug | Tester, Developer, Manager |
| **ZBUG_REPORT** | Báo cáo ALV & Tương tác | Tất cả |
| **ZBUG_MANAGER**| Dashboard Thống Kê | Manager |
| **ZBUG_PRINT**  | In ấn Biên Bản (PDF) | Tất cả |
| **ZBUG_USERS**  | Quản trị Danh sách User | Manager |

---

## 2. HƯỚNG DẪN THEO VAI TRÒ (ROLES)

Hệ thống phân quyền nghiêm ngặt dựa trên Role của bạn (T, D, M). Dưới đây là luồng quy trình chuẩn (Standard Workflow) cho từng vị trí:

### 2.1. Dành cho TESTER (Người kiểm thử)

**Mục tiêu:** Báo cáo lỗi mới, đính kèm tài liệu lỗi, và nghiệm thu lỗi sau khi Dev đã sửa.

**Bước 1: Tạo Bug Mới**
1. Mở T-code **`ZBUG_CREATE`**.
2. Điền đầy đủ thông tin: Tiêu đề (Title), Mô tả chi tiết (Description), Module SAP đang lỗi, và Độ ưu tiên (High/Medium/Low).
3. Bấm **F8 (Execute)** hoặc nút Đồng hồ để lưu. Hệ thống tự sinh Bug ID và gửi Email thông báo tự động.

**Bước 2: Tải lên Tài liệu Chứng minh (GOS)**
1. Mở T-code **`ZBUG_REPORT`** để xem danh sách Bug.
2. Tại màn hình Report, click đúp vào Bug bạn vừa tạo, chọn **Update Bug** (Icon bút chì).
3. Dùng nút **GOS (Dấu đính kèm góc trái trên cùng)** -> *Create* -> *Create Attachment* để tải file log/hình ảnh lỗi lên.
4. Hành động này tự động trigger chức năng cập nhật File Path vào hệ thống báo cáo `ATT_REPORT`.

**Bước 3: Nghiệm thu (Verify)**
1. Khi Dev đã đổi status thành `Fixed` (Đã sửa).
2. Tester vào lại **`ZBUG_UPDATE`**, test lại hệ thống.
3. Nếu OK, đổi Status thành `Closed`. Nếu Failed, đổi Status về lại `In Progress`. Cập nhật Reason (Lý do).

---

### 2.2. Dành cho DEVELOPER (Lập trình viên)

**Mục tiêu:** Tiếp nhận Bug được giao, tải lên bản vá (Fix), và cập nhật tiến độ xử lý.

**Bước 1: Kiểm tra Workload (Bugs được gán)**
1. Truy cập **`ZBUG_REPORT`**.
2. Màn hình ALV sẽ báo màu sắc sinh động (Cam: Vừa được gán, Tím: Đang xử lý, Xanh lá: Đã sửa). 

**Bước 2: Cập nhật Tiến độ làm việc**
1. Chọn Bug đang gán cho mình -> Bấm nút **Update Bug**.
2. Đổi trạng thái từ `Assigned` -> `In Progress` để hệ thống biết bạn đã bắt tay vào làm.
3. Khi sửa code xong, tiếp tục đổi Status sang `Fixed`.

**Bước 3: Tải lên Transport/Fix Document (GOS)**
1. Tương tự Tester, Developer dùng công cụ đính kèm (GOS) trên thanh tiêu đề của màn hình **`ZBUG_UPDATE`**.
2. Tải lên file chứa danh sách Transport Request hoặc tài liệu thiết kế kỹ thuật. Chức năng `UPLOAD_FIX` sẽ tự động ghi nhận đường dẫn cho Dev.

**Lưu ý:** Bạn có quyền "Từ chối / Re-assign" Bug nếu thấy không phù hợp bằng cách báo cho Manager. Bạn KHÔNG có quyền tự tạo Bug.

---

### 2.3. Dành cho MANAGER (Quản lý dự án)

**Mục tiêu:** Giám sát tổng thể sức khỏe dự án, điều phối nhân sự rảnh rỗi và in ấn báo cáo cuối tháng.

**Bước 1: Giám sát Dashboard Tổng Thể**
1. Truy cập T-code **`ZBUG_MANAGER`**.
2. Bạn sẽ thấy Top-of-page hiển thị tổng Bug, số Bug mới hoàn toàn, và danh sách các Developer đang rảnh rỗi (`Available = A`).

**Bước 2: Tự Động Phân Công Việc (Auto-Assign)**
1. Mở **`ZBUG_REPORT`**, chọn các Bug đang ở màu Xanh Dương (New).
2. Bấm nút **Auto Assign (Biểu tượng Robot/Người)** trên Toolbar ALV.
3. Hệ thống sẽ quét Module của Bug đó, tìm toàn bộ Dev thuộc Module này, đếm số lượng Bug họ đang gánh, và tự động gán thẳng Bug này cho Dev đang ít việc nhất.

**Bước 3: Tra Cứu Lịch Sự & Nhân Sự**
- Dùng **`ZBUG_USERS`** để biết hệ thống đang có bao nhiêu nhân sự, Role nào, Module nào.
- Mọi thao tác sửa đổi của Dev/Tester đều được hệ thống lẳng lặng ghi log vào DB `ZBUG_HISTORY` chống gian lận.

**Bước 4: In Báo Cáo Định Kỳ (SmartForms)**
1. Mở **`ZBUG_PRINT`**.
2. Gõ Bug ID cần xuất biên bản.
3. Nhấp Print Preview để xem định dạng Header/Footer chuyên nghiệp, hoặc bấm **Print** để kết xuất ra máy in nội bộ / PDF file.
