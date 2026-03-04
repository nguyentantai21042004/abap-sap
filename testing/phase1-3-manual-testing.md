# Hướng dẫn Manual Testing (Phase 1, 2, 3)

Tài liệu này cung cấp các kịch bản kiểm thử (Test Cases) có thể thực hiện thủ công ngay sau khi hoàn thành Phase 3 nhằm đảm bảo các tính năng ở tầng Database (Phase 1), Business Logic (Phase 2), và Presentation (Phase 3) hoạt động trơn tru cùng nhau.

---

## 🟢 Test Case 01: Tạo Bug mới (Create a Bug)

**Mục đích:** Kiểm tra luồng Tạo Bug từ UI thông qua ZBUG_CREATE, ghi nhận vào Database và sinh ID tự động.

1. **Khởi chạy:** Nhập T-code **`ZBUG_CREATE`** và Enter.
2. **Hành động (Input Data):**
   * **P_TITLE:** `Lỗi không thể đăng nhập trên màn hình chính`
   * **P_MODULE:** `FI`
   * **P_PRIOR:** `H` (High)
   * **P_DEVID:** (Bỏ trống)
   * **P_DESC:** `Người dùng báo cáo không thể đăng nhập, hệ thống báo lỗi 500.`
3. **Thực thi:** Nhấn nút **Execute** (hoặc F8).
4. **Expected Behavior (Kết quả mong đợi):**
   * Thanh Status bar xuất hiện thông báo xanh (Success) có dạng: `Bug created successfully with ID: BUG0000001` (hoặc số ID tiếp theo).
   * Không bị dump lỗi (short dump), chứng tỏ code tương tác tốt với Data Elements và Domain cấu hình.

---

## 🟢 Test Case 02: Xác minh Email thông báo (SOST)

**Mục đích:** Đảm bảo khi một Bug được tạo ra, hệ thống tự động sinh một Email (chức năng Z_BUG_SEND_EMAIL ở Phase 2).

1. **Khởi chạy:** Nhập T-code **`SOST`** hoặc **`SO01`**.
2. **Hành động:**
   * Tại màn hình danh sách Email (Send Requests), lọc theo ngày hôm nay.
3. **Expected Behavior (Kết quả mong đợi):**
   * Có một email mới với trạng thái Waiting (hoặc Sent nếu background job đang chạy).
   * Người nhận (Recipient) là "<developer@company.com>" (hoặc email cấu hình trong `Z_BUG_CREATE_SCREEN`).
   * **Nội dung Email (Preview):** Phải chứa chuỗi `New Bug Assigned: Lỗi không thể đăng nhập trên màn hình chính` và `Priority: H`.

---

## 🟢 Test Case 03: Xác minh dữ liệu trong Database (SE16N)

**Mục đích:** Kiểm tra bảng vật lý (ZBUG_TRACKER) ở Phase 1 có được ghi đúng định dạng và lưu trữ thành công hay không.

1. **Khởi chạy:** Nhập T-code **`SE16N`**.
2. **Hành động:**
   * **Table:** `ZBUG_TRACKER` -> Nhấn Enter.
   * Tại trường `BUG_ID`, nhập ID Bug vừa được hệ thống thông báo ở TC01 (VD: `BUG0000001`).
   * Nhấn **Execute** (F8).
3. **Expected Behavior (Kết quả mong đợi):**
   * Màn hình ALV hiển thị đúng 1 dòng dữ liệu.
   * `STATUS` = `1` (New).
   * `REPORTER` = Chứa User ID của bạn (ví dụ DEV-061).
   * `CREATED_AT` và `CREATED_TIME` = Có thời gian thực tế hiện tại.
   * `DESC_TEXT` = `Người dùng báo cáo không thể đăng nhập...` (Đoạn text char255 đã được map đúng sang kiểu STRING của DB).

---

## 🟢 Test Case 04: Cập nhật Trạng thái Bug (ZBUG_UPDATE)

**Mục đích:** Kiểm tra tính năng Cập nhật thông tin và Trạng thái của Bug.

1. **Khởi chạy:** Nhập T-code **`ZBUG_UPDATE`** và Enter.
2. **Hành động (Input Data):**
   * **P_BUGID:** `BUG...` (Mã Bug đã lấy ở TC01).
   * **P_STATUS:** `3` (In Progress).
   * **P_DEVID:** `DEV-118`.
   * **P_REASON:** `Bắt đầu điều tra lỗi backend hệ thống xác thực.`
3. **Thực thi:** Nhấn nút **Execute** (hoặc F8).
4. **Expected Behavior (Kết quả mong đợi):**
   * Thanh Status bar xuất hiện thông báo: `Status updated successfully`.

---

## 🟢 Test Case 05: Xác minh Nhật ký thao tác (Audit History)

**Mục đích:** Đảm bảo tính năng theo dõi lịch sử lỗi (`Z_BUG_LOG_HISTORY`) đã được kích hoạt ngầm khi có thao tác Update.

1. **Khởi chạy:** Nhập T-code **`SE16N`**.
2. **Hành động:**
   * **Table:** `ZBUG_HISTORY` -> Nhấn Enter.
   * Nhập vào cột `BUG_ID` mã Bug ở trên.
   * Nhấn **Execute** (F8).
3. **Expected Behavior (Kết quả mong đợi):**
   * Tìm thấy một bản ghi mới.
   * Cột `ACTION_TYPE` = `ST` (Status Update).
   * `OLD_VALUE` = `1` (New)
   * `NEW_VALUE` = `3` (In Progress).
   * `REASON` = `Bắt đầu điều tra lỗi...`
   * `CHANGED_BY` = User ID của bạn.

---

## 🔴 Test Case 06: Kiểm thử Ngoại lệ (Negative Test - Create Bug)

**Mục đích:** Thử cố tình làm sai để kiểm tra Validation logic.

1. **Khởi chạy:** Nhập T-code **`ZBUG_CREATE`** và Enter.
2. **Hành động:**
   * Để trống trường **P_TITLE** hoặc **P_DESC**.
   * Nhấn **Execute**.
3. **Expected Behavior (Kết quả mong đợi):**
   * SAP sẽ từ chối thực thi do các trường này được đánh dấu `OBLIGATORY` trên Screen, hiển thị thông báo yêu cầu điền vào trường bắt buộc (Fill in all required entry fields).
   * Hoặc, nếu nhập Title ngắn hơn 10 ký tự, khi gọi FM `Z_BUG_CREATE` sẽ trả về lỗi: `Title must be at least 10 characters` hiển thị màu đỏ ở Status bar.

---

> ✅ **Tip cho Tester:** Bạn có thể tự mình thực hiện 6 Test Cases này trên màn hình SAP GUI. Nếu tất cả các Expected Behavior đều khớp thực tế, chứng tỏ nền móng của hệ thống (Phase 1, 2, 3) đã hoàn toàn hoàn hảo!
