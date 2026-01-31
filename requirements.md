# Phân Tích Yêu Cầu: SAP BUG TRACKING MANAGEMENT

## 1. Tổng quan yêu cầu

Xây dựng một Phân hệ quản lý lỗi tùy chỉnh (Custom Add-on) nằm trong hệ thống SAP ERP. Mục tiêu là cung cấp một công cụ tập trung (Centralized Tool) để người dùng nội bộ ghi nhận, theo dõi và báo cáo lỗi phần mềm mà không cần sử dụng phần mềm bên thứ 3.

Giải pháp phải tuân thủ kiến trúc 3-tier của SAP và sử dụng các công nghệ hiển thị tiêu chuẩn (ALV, SmartForms).

## 2. Phân tích yêu cầu chi tiết

### Chức năng 1: Allow user log bug in SAP System (Ghi nhận lỗi)

**Phân tích nghiệp vụ:** Người dùng cần một giao diện nhập liệu (Input Screen) để khai báo các thông tin chi tiết về lỗi.

**Giải pháp kỹ thuật:**

- Tạo **Transaction Code (T-code)** riêng (ví dụ: `ZBUG_CREATE`) để mở màn hình này.
- Sử dụng **Selection Screen** hoặc **Module Pool (Screen Painter)** để vẽ form nhập liệu.
- Cơ chế Validation: Kiểm tra tính hợp lệ của dữ liệu (ví dụ: `User ID` có tồn tại không, `Module` có đúng danh mục không) trước khi lưu vào Database.

### Chức năng 2: Send Email to Developer team (Tự động thông báo)

**Phân tích nghiệp vụ:** Ngay sau khi lỗi được lưu (Saved), hệ thống phải tự động gửi email thông báo đến nhóm phát triển để xử lý kịp thời.

**Giải pháp kỹ thuật:**

- Sử dụng Business Logic kích hoạt tại sự kiện `AFTER SAVE`.
- Gọi thư viện SAPconnect (Class `CL_BCS` hoặc Function `SO_NEW_DOCUMENT_ATT_SEND_API1`) để gửi email qua SMTP Server đã cấu hình trong SAP (`T-code SCOT`).
- Nội dung email: Tự động lấy từ dữ liệu vừa nhập (`Bug ID`, `Title`, `Description`).

### Chức năng 3: Show list bug in ALV and SmartForm (Báo cáo & In ấn)

**Đây là yêu cầu kép, cần tách thành 2 phần riêng biệt:**

- **A. Hiển thị danh sách (ALV Grid):**
  - Mục đích: Xem nhanh, thao tác trên màn hình, xuất Excel.
  - Kỹ thuật: Sử dụng `REUSE_ALV_GRID_DISPLAY`. Đây là công cụ mạnh nhất của SAP GUI để hiển thị bảng dữ liệu với các tính năng có sẵn: Sort (Sắp xếp), Filter (Lọc theo Status/Priority), Sum (Tính tổng).
- **B. Biểu mẫu in ấn (SmartForms):**
  - Mục đích: Tạo văn bản pháp lý hoặc biên bản bàn giao lỗi (Hard-copy).
  - Kỹ thuật: Sử dụng `T-code SMARTFORMS` để vẽ mẫu in (Logo công ty, Khung viền, Chữ ký). Chương trình sẽ đẩy dữ liệu lỗi vào form này để xuất ra PDF hoặc in giấy.

### Chức năng 4: Statistics of bugs (Dashboard thống kê)

**Phân tích nghiệp vụ:** Người quản lý cần cái nhìn tổng quan về tình hình lỗi (Bao nhiêu lỗi đã sửa, bao nhiêu đang chờ).

**Giải pháp kỹ thuật:**

- Thực hiện các câu lệnh SQL Aggregation (COUNT, GROUP BY Status) trên bảng dữ liệu Z.
- Hiển thị kết quả dưới dạng một bảng nhỏ (Summary Table) ngay trên đầu màn hình ALV báo cáo.

### Chức năng 5: Attach evidence (Quản lý đính kèm)

**Phân tích nghiệp vụ:** Lỗi phần mềm cần bằng chứng (Screenshot, Log file).

**Giải pháp kỹ thuật:**

- Sử dụng dịch vụ GOS (Generic Object Services) của SAP.
- Cho phép upload file từ PC local và lưu trữ liên kết với Bug ID trong Database.

## 3. Kiến trúc hệ thống

### 3.1. Kiến trúc 3-tier

- **Tier 1: User Interface (GUI):**
  - Sử dụng SAP GUI (SAP Screen Painter) để vẽ giao diện nhập liệu.
  - Sử dụng ALV Grid để hiển thị danh sách lỗi.
  - Sử dụng SmartForms để vẽ mẫu in ấn.

- **Tier 2: Business Logic (ABAP):**
  - Sử dụng Business Logic kích hoạt tại sự kiện `AFTER SAVE`.
  - Sử dụng dịch vụ GOS (Generic Object Services) của SAP.

- **Tier 3: Database:**
  - Sử dụng bảng dữ liệu Z (ZBUG_TRACKER) để lưu trữ dữ liệu lỗi.

### 3.2. Kiến trúc dữ liệu

Để hiện thực hóa các chức năng trên, chúng ta cần thiết kế một bảng dữ liệu tùy chỉnh (Z-Table) trong ABAP Dictionary (SE11). Cấu trúc dự kiến như sau:

Tên bảng: ZBUG_TRACKER (Bảng chứa thông tin lỗi)

| Tên trường (Field) | Kiểu dữ liệu | Mô tả (Description) | Ghi chú                           |
| ------------------ | ------------ | ------------------- | --------------------------------- |
| MANDT              | CLNT (3)     | Client ID           | Bắt buộc trong SAP                |
| BUG_ID             | CHAR (10)    | Mã lỗi              | Khóa chính (Primary Key)          |
| TITLE              | CHAR (100)   | Tiêu đề lỗi         |                                   |
| DESC_TEXT          | STRING       | Mô tả chi tiết      |                                   |
| MODULE             | CHAR (20)    | Phân hệ (MM, SD...) |                                   |
| PRIORITY           | CHAR (1)     | Độ ưu tiên          | (H)igh, (M)edium, (L)ow           |
| STATUS             | CHAR (1)     | Trạng thái          | (1)New, (2)Assigned, (3)Fixed     |
| REPORTER           | CHAR (12)    | Người báo lỗi       | Tự động lấy User Login (sy-uname) |
| DEV_ID             | CHAR (12)    | Developer xử lý     |                                   |
| CREATED_AT         | DATS         | Ngày tạo            |                                   |

## 4. LUỒNG NGHIỆP VỤ (PROCESS FLOW)

Quy trình hoạt động của hệ thống từ góc nhìn người dùng:

1. **Nhập dữ liệu**
   - Người dùng nhập `T-code ZBUG_CREATE`.
   - Hệ thống mở giao diện nhập liệu.
   - Người dùng điền thông tin lỗi và đính kèm hình ảnh, sau đó nhấn "Save".

2. **Xử lý**
   - Dữ liệu lỗi được lưu vào bảng `ZBUG_TRACKER`.
   - Hệ thống tự động gửi email thông báo cho lập trình viên xử lý.

3. **Quản lý/Xem báo cáo**
   - Quản lý nhập `T-code ZBUG_REPORT`.
   - Hệ thống hiển thị thống kê lỗi dưới dạng bảng ALV Grid.

4. **Tác vụ trên báo cáo**
   - Quản lý có thể lọc lỗi theo trạng thái "Pending".
   - Sử dụng nút "Print" để xuất báo cáo dưới dạng SmartForm.
   - Nhấn vào mã lỗi để cập nhật trạng thái (ví dụ: từ New → Fixed).
