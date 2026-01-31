# XÂY DỰNG PHÂN HỆ QUẢN LÝ LỖI (BUG TRACKING MANAGEMENT)

## 1. TỔNG QUAN DỰ ÁN

Phát triển một **Custom Solution (Z-Solution)** chuyên biệt cho nghiệp vụ Bug Tracking. Giải pháp tuân thủ kiến trúc kỹ thuật chuẩn của SAP, đảm bảo tính bảo mật, toàn vẹn dữ liệu và khả năng tích hợp sâu (Deep Integration) với quy trình vận hành hiện tại.

## 2. KIẾN TRÚC KỸ THUẬT

Giải pháp được xây dựng dựa trên mô hình 3 lớp (3-Tier Architecture) của SAP NetWeaver:

- **Lớp Dữ liệu (Data Layer - SE11):** Sử dụng các bảng trong suốt tùy chỉnh (**Transparent Table**) nằm trong không gian tên khách hàng (`Z*`), đảm bảo không can thiệp vào dữ liệu chuẩn (Standard Data) của SAP.
- **Lớp Ứng dụng (Application Layer - ABAP):** Sử dụng ngôn ngữ **ABAP** để xử lý logic nghiệp vụ, xác thực dữ liệu và điều phối luồng quy trình (Workflow).
- **Lớp Trình diễn (Presentation Layer - SAP GUI):** Giao diện người dùng được thiết kế chuẩn hóa theo **SAP GUI Guidelines**, sử dụng công nghệ **ALV Grid** cho báo cáo và **SmartForms** cho in ấn.

## 3. PHẠM VI CÔNG VIỆC CHI TIẾT

Hệ thống bao gồm 05 module chức năng chính:

### 3.1. Module Quản trị Dữ liệu

- **Thiết kế Bảng `ZBUG_TRACKER`:** Lưu trữ toàn bộ thông tin vòng đời của lỗi.
- _Các trường chính:_ Ticket ID (Key), Title, Description, Module (MM/SD/FI...), Priority, Status, Reporter, Assignee, Created Date, Closed Date.

- **Định nghĩa Data Element & Domain:** Chuẩn hóa các giá trị nhập liệu (VD: Status chỉ được phép là New/Processing/Fixed).

### 3.2. Module Ghi nhận lỗi

- **Giao diện nhập liệu (T-code `ZBUG_CREATE`):**
- Màn hình Selection Screen thân thiện.
- Tự động lấy thông tin người dùng đăng nhập (`SY-UNAME`) và ngày giờ hệ thống.
- Cơ chế **Validation**: Kiểm tra tính hợp lệ của dữ liệu trước khi lưu.

- **Quản lý đính kèm (Attachment Service):**
- Tích hợp **Generic Object Services (GOS)** cho phép đính kèm file ảnh/log lỗi trực tiếp vào Ticket.

- **Tự động hóa (Automation):**
- Tích hợp **SAPconnect (SMTP)**: Hệ thống tự động kích hoạt gửi email thông báo đến nhóm Developer ngay khi lỗi được tạo hoặc thay đổi trạng thái.

### 3.3. Module Báo cáo & Theo dõi

- **Báo cáo Danh sách (T-code `ZBUG_REPORT`):**
- Sử dụng công nghệ **ALV Grid (SAP List Viewer)**.
- Tính năng chuẩn: Sắp xếp (Sort), Lọc (Filter), Tính tổng (Aggregation), Xuất khẩu ra Excel.
- Tính năng tương tác (Drill-down): Click vào mã lỗi để xem chi tiết hoặc cập nhật trạng thái.

- **Dashboard Thống kê:**
- Hiển thị bảng tổng hợp nhanh số lượng lỗi theo Trạng thái (Open vs Closed) và Mức độ ưu tiên ngay trên màn hình báo cáo.

### 3.4. Module In ấn

- **Biểu mẫu `ZBUG_FORM`:**
- Thiết kế mẫu in "Phiếu Yêu Cầu Xử Lý Lỗi" sử dụng công nghệ **SmartForms**.
- Bao gồm: Logo công ty, Thông tin chi tiết lỗi, Khu vực ký duyệt.
- Hỗ trợ xuất ra định dạng PDF hoặc in trực tiếp qua máy in SAP.

## 4. KẾ HOẠCH TRIỂN KHAI

**Tổng thời gian thực hiện:** 08 Tuần.
**Phương pháp:** Waterfall (Phân tích -> Thiết kế -> Lập trình -> Kiểm thử).

| Giai đoạn               | Tuần    | Hạng mục công việc (Work Item)                                                                                       | Kết quả bàn giao (Deliverables)                                  |
| ----------------------- | ------- | -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| P1. Khởi tạo            | 01      | - Thiết lập môi trường Development.- Phân tích đặc tả kỹ thuật (Tech Specs).- Thiết kế Database Schema (SE11).       | - Tài liệu thiết kế kỹ thuật.- Cấu trúc bảng (Table Definition). |
| P2. Phát triển Core     | 02 - 03 | - Lập trình màn hình nhập liệu (Input Program).- Lập trình logic CRUD & Validation.- Cấu hình & Lập trình gửi Email. | - T-code nhập liệu hoạt động.- Demo luồng gửi mail tự động.      |
| P3. Báo cáo & In ấn     | 04 - 05 | - Lập trình báo cáo ALV Grid.- Thiết kế biểu mẫu SmartForms.- Lập trình Dashboard thống kê.                          | - T-code báo cáo hoàn chỉnh.- Mẫu in PDF đúng chuẩn.             |
| P4. Đóng gói            | 06      | - Rà soát mã nguồn (Code Inspector).- Tối ưu hóa hiệu năng (Performance Tuning).- Đóng gói Transport Request.        | - Source Code đã tối ưu.- Gói cài đặt hoàn chỉnh.                |
| P5. Kiểm thử & Bàn giao | 07 - 08 | - Hỗ trợ UAT (User Acceptance Test).- Khắc phục lỗi (Bug Fixing).- Bàn giao tài liệu & Source code.                  | - Biên bản nghiệm thu UAT.- Tài liệu HDSD (User Manual).         |

---

## 5. YÊU CẦU TÀI NGUYÊN

Để đảm bảo tiến độ dự án, Đội dự án cần được cung cấp:

1. **Hệ thống:** Tài khoản truy cập SAP Development Server với quyền **Developer Access Key**.
2. **Cấu hình:** Thông tin SMTP Server (IP, Port) để cấu hình chức năng gửi mail.
3. **Nghiệp vụ:** Quy trình phê duyệt lỗi và mẫu biểu in ấn (nếu có).

---

## 6. CAM KẾT CHẤT LƯỢNG & BẢO HÀNH

- **Tuân thủ Clean Core:** Mã nguồn được phát triển tách biệt, không sửa đổi mã nguồn chuẩn (No Modification on Standard), đảm bảo an toàn khi hệ thống nâng cấp.
- **Tiêu chuẩn lập trình:** Mã nguồn tuân thủ quy chuẩn đặt tên của SAP, có chú thích (Comment) rõ ràng, dễ dàng bảo trì.
- **Hỗ trợ sau triển khai:** Hỗ trợ xử lý các lỗi kỹ thuật phát sinh trong vòng [Số] tuần sau khi Golive.
