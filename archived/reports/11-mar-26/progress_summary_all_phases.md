# SAP Bug Tracking Management System - Báo Cáo Tổng Quan Tiến Độ Dự Án (All Phases)

**Ngày báo cáo:** 11/03/2026
**Trạng thái Dự án:** Hoàn thành Giai đoạn Phát triển (Phase 0 - Phase 5) | Đang thực thi Phase 6 (Testing & Optimization)

---

## 1. MỤC ĐÍCH BÁO CÁO

Báo cáo này tóm tắt siêu chi tiết toàn bộ bức tranh dự án qua 6 giai đoạn phát triển chính thức. Tài liệu này đóng vai trò như một bảng tổng sắp công việc (Summary Guide), giúp tất cả các thành viên nắm rõ hạ tầng kỹ thuật đã xây dựng, cũng như đối chiếu cụ thể **Tài khoản (Account DEV)** nào đã phụ trách triển khai tính năng gì trong hệ thống SAP.

## 2. CHI TIẾT CÔNG VIỆC THEO TỪNG GIAI ĐOẠN (PHASES)

### PHASE 0: CHUẨN BỊ MÔI TRƯỜNG & HẠ TẦNG

*Setup tài nguyên ban đầu và kiểm thử phân quyền Developer.*

- **Account sử dụng:** Hệ thống tài khoản Local (DEV-089, DEV-061, DEV-242, DEV-237).
- **Chi tiết công việc:**
  1. Cài đặt thành công SAP GUI và SAP Logon S40 System.
  2. Test connection các tài khoản với Developer Key tích hợp.
  3. Khởi tạo **Package gốc `ZBUGTRACK`** thông qua giao diện SE80.

---

### PHASE 1: DATABASE LAYER (TẦNG DỮ LIỆU)

*Xây dựng bộ xương sống lưu trữ dữ liệu bền vững (Persistence Layer).*

- **Account sử dụng:** **`DEV-089`** (Account chuyên gia Tầng CSDL & Backend).
- **Chi tiết công việc (SE11):**
  1. Tạo thành công **14 Domains** (Chứa fixed values cho Trạng thái, Priority, Module...)
  2. Tạo thành công **19 Data Elements** cho các mô tả tiếng Anh.
  3. Tạo bảng chính **`ZBUG_TRACKER`** (20 fields - lưu thông পুরা Bug).
  4. Tạo bảng tham chiếu **`ZBUG_USERS`** (8 fields - lưu danh sách nhân sự).
  5. Tạo bảng lưu vết **`ZBUG_HISTORY`** (10 fields - lưu Audit Trail).
  6. Khởi tạo Object sinh dãy số tự động (SNRO) `ZNRO_BUG`.

---

### PHASE 2: BUSINESS LOGIC LAYER (TẦNG NGHIỆP VỤ)

*Gói gọn các thao tác cơ sở dữ liệu vào Function Modules.*

- **Account sử dụng:**
  - **`DEV-061`** (Lập trình CRUD / API).
  - **`DEV-242`** (Chuyên gia Cấu hình Máy chủ Mạng).
- **Chi tiết công việc:**
  1. Khởi tạo Function Group **`ZBUG_FG`**.
  2. Viết 4 Core FMs: `Z_BUG_CREATE` (Tạo bug), `Z_BUG_UPDATE_STATUS` (Cập nhật bug), `Z_BUG_GET` (Đọc tin), `Z_BUG_DELETE` (Xóa).
  3. Mở SCOT bằng account **`DEV-242`**, thiết lập máy chủ hòm thư `smtp.gmail.com:587` cho node `ZBUG_M`.
  4. Viết FM `Z_BUG_SEND_EMAIL` để nã thông báo khi Bug được tạo.

---

### PHASE 3: PRESENTATION LAYER (TẦNG GIAO DIỆN)

*Tạo màn hình thao tác trực quan (Screen/Transaction) cho người dùng cuối.*

- **Account sử dụng:** **`DEV-061`** (Chuyên gia Màn hình & UI).
- **Chi tiết công việc:**
  1. Xây dựng Program **`Z_BUG_CREATE_SCREEN`** (Nhập liệu Bug mới) → Cấu hình vào T-code **`ZBUG_CREATE`**.
  2. Xây dựng Program **`Z_BUG_UPDATE_SCREEN`** (Gọi API Get/Update, Validate phân quyền) → Cấu hình vào T-code **`ZBUG_UPDATE`**.
  3. Liên kết luồng: Sau khi Create thành công, gọi tự động FM gửi Email (Z_BUG_SEND_EMAIL).

---

### PHASE 4: REPORTING & PRINTING (BÁO CÁO & IN ẤN)

*Thống kê, hiển thị ALV và xuất bản file cứng.*

- **Account sử dụng:** **`DEV-061`** (Chuyên gia ABAP GUI/ALV & SmartForms).
- **Chi tiết công việc:**
  1. Xây dựng ALV Tương Tác: T-code **`ZBUG_REPORT`** (Có Custom Toolbar chứa nút Update Bug qua ZBUG_UPDATE và nút Assign).
  2. Thống kê Manager: T-code **`ZBUG_MANAGER`** (Gom nhóm số lượng bug theo Text Tiếng Việt dễ hiểu).
  3. In ấn PDF: T-code **`ZBUG_PRINT`** và Form In **`ZBUG_FORM`**. (Xử lý dứt điểm rào cản tương thích SmartForms trên đồ họa Mac bằng cách fallback về Line Editor).
  4. Quản trị NS: T-code **`ZBUG_USERS`** (Lọc ALV danh sách nhân sự theo Role).

---

### PHASE 5: ADVANCED FMs & ATTACHMENTS (MODULE NÂNG CAO)

*Biến app thành sản phẩm hoàn thiện với các tính năng đắt giá.*

- **Account sử dụng:**
  - **`DEV-089`** (Lập trình thuật toán nâng cao).
  - **`DEV-237`** (Chuyên gia tài liệu SAP GOS).
  - **`DEV-061`** (Trang trí lại UI).
- **Chi tiết công việc:**
  1. **History Logging (DEV-089):** Tạo `Z_BUG_LOG_HISTORY` tự ghi lại dòng chảy trạng thái (Old vs New value).
  2. **Auto-Assign (DEV-089):** Xây thuật toán quét `ZBUG_TRACKER` đếm số lượng việc của các Dev, từ đó gán rớt Bug vào đầu Dev rảnh nhất (`Z_BUG_AUTO_ASSIGN`).
  3. **Role Checker (DEV-089):** Thiết lập rào chắn `Z_BUG_CHECK_PERMISSION` giới hạn thao tác của Tester và Developer. Chặn việc sửa Bug chéo.
  4. **ALV Coloring (DEV-061):** Tái lập trình `ZBUG_REPORT` để ép màu Grid Row (Status 1: Xanh nhạt, Status 2: Cam...).
  5. **File GOS Upload (DEV-237):** Cắm API `Z_BUG_UPLOAD_ATTACHMENT` nối với SAP Generic Object Services để tải hình ảnh Screenshot đính kèm Bug.
  6. **Reassign Logic (DEV-089):** Chức năng nhả Bug đang bận bằng `Z_BUG_REASSIGN`.

---

## 3. THÔNG CÁO HIỆN TẠI (MARCH 11, 2026)

Hệ thống Core **ĐÃ CODE XONG 100%**.

> **Giai đoạn hiện tại dự án đang hướng tới: PHASE 6 - TESTING & OPTIMIZATION**