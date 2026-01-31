# XÂY DỰNG PHÂN HỆ QUẢN LÝ LỖI (BUG TRACKING) – GIẢI PHÁP SIDE-BY-SIDE

## 1. TỔNG QUAN DỰ ÁN

Phát triển hệ thống **Bug Tracking** chạy song song với SAP (Side-by-Side Extension) trên nền tảng Web hiện đại. Giải pháp triển khai trên hạ tầng On-Premise, sử dụng **Golang**, **Docker**, **ReactJS**, kết nối với SAP ERP qua OData/RFC, đảm bảo trải nghiệm người dùng (UX) vượt trội so với giao diện SAP GUI truyền thống (ALV/SmartForms) mà không phụ thuộc License SAP BTP hay Cloud.

## 2. KIẾN TRÚC KỸ THUẬT

Giải pháp được triển khai theo mô hình **On-Premise Side-by-Side**:

- **Lớp Trình diễn (Presentation Layer – Web):** Giao diện người dùng **Web Dashboard** (ReactJS/VueJS), Responsive (tương thích Mobile/Tablet), không cần cài đặt SAP Logon.
- **Lớp Ứng dụng (Application Layer – Golang):** Backend **RESTful API** xử lý logic nghiệp vụ, xác thực dữ liệu; **SAP Connector** (go-rfc / REST Client) giao tiếp hai chiều với SAP Server qua cổng nội bộ (Port 3300/8000).
- **Lớp Dữ liệu (Data Layer):** Dữ liệu chính lưu trên SAP (bảng Z-Table); **PostgreSQL (Optional)** dùng để cache hoặc lưu cấu hình giao diện nhằm giảm tải SAP DB.
- **Hạ tầng (Infrastructure):** **Docker Compose** quản lý container (BE, FE, DB); **Nginx** Reverse Proxy điều hướng traffic nội bộ; cơ chế Auto-restart đảm bảo High Availability.

## 3. PHẠM VI CÔNG VIỆC CHI TIẾT

Hệ thống bao gồm các hạng mục chính sau:

### 3.1. Hạ tầng & DevOps (Infrastructure)

- **Thiết lập Docker:** Cài đặt Docker Engine trên máy chủ ảo (Linux VM), cấu hình Docker Compose để chạy Backend, Frontend, Database (nếu dùng).
- **Cấu hình Nginx:** Reverse Proxy điều hướng traffic nội bộ, không đi qua Internet.
- **Auto-restart:** Thiết lập cơ chế tự khởi động lại khi service lỗi, đảm bảo tính sẵn sàng cao.

### 3.2. Backend Development (Golang)

- **RESTful API:** Phát triển API phục vụ Frontend (CRUD Bug Ticket, Auth, Permission).
- **SAP Connector:**
  - _Read:_ Lấy danh sách User, Project từ SAP (RFC/OData).
  - _Write:_ Ghi log bug vào bảng Z-Table trong SAP.
- **Module Notification:** Tích hợp gửi email SMTP hoặc Webhook (Slack/Telegram/Teams) khi lỗi được tạo hoặc thay đổi trạng thái.
- **PDF Generation Engine:** Render HTML-to-PDF thay cho SmartForms; mẫu in hỗ trợ màu sắc, biểu đồ.

### 3.3. Frontend Development (Web App)

- **Dashboard:** Hiển thị biểu đồ thống kê lỗi (Pie Chart, Bar Chart) với Chart.js/Recharts; tổng hợp theo Trạng thái (Open vs Closed) và Mức độ ưu tiên.
- **Ticket Management:** Giao diện **Interactive Data Grid** hoặc **Kanban Board**; tính năng Sắp xếp, Lọc, Tìm kiếm tức thì, kéo thả cột (UX vượt trội so với ALV).
- **Smart Web Form (Ghi nhận lỗi):** Hỗ trợ Drag & Drop ảnh, Paste ảnh từ Clipboard, Rich Text Editor (soạn thảo mô tả có định dạng).
- **Detail View:** Xem chi tiết lỗi, lịch sử thay đổi (Audit Log), bình luận trao đổi.

### 3.4. Tích hợp SAP

- **Mở cổng dữ liệu:** Phát triển RFC/BAPI hoặc OData Service trên SAP (trong không gian Z\*) để Backend Golang đọc/ghi dữ liệu.
- **Bảng Z-Table:** Thiết kế hoặc tái sử dụng bảng lưu Bug (VD: ZBUG_TRACKER) trên SAP, đảm bảo không can thiệp dữ liệu chuẩn.

## 4. CHUYỂN ĐỔI YÊU CẦU (SO VỚI GIẢI PHÁP ON-STACK)

Do thay đổi nền tảng từ SAP GUI sang Web App, các yêu cầu kỹ thuật được ánh xạ như sau:

| Yêu cầu gốc (On-Stack) | Giải pháp Side-by-Side  | Lợi ích                                         |
| ---------------------- | ----------------------- | ----------------------------------------------- |
| Giao diện SAP GUI      | Web Dashboard (ReactJS) | Không cần cài SAP Logon; mở trên iPad/PC được.  |
| Danh sách ALV          | Interactive Data Grid   | Tìm kiếm tức thì, lọc đa chiều, UX tốt hơn.     |
| In ấn SmartForms       | PDF Generation Engine   | Mẫu in đẹp, hỗ trợ màu, biểu đồ.                |
| Form nhập liệu SAP     | Smart Web Form          | Drag & Drop ảnh, Rich Text, Paste từ Clipboard. |

## 5. KẾ HOẠCH TRIỂN KHAI

**Tổng thời gian thực hiện:** 08 Tuần.
**Phương pháp:** Waterfall (Phân tích → Thiết kế → Lập trình → Kiểm thử).

| Giai đoạn               | Tuần    | Hạng mục công việc (Work Item)                                                                                                                                | Kết quả bàn giao (Deliverables)                           |
| ----------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| P1. Khởi tạo & Infra    | 01      | Thiết lập VM, Docker, Docker Compose. Phân tích đặc tả kỹ thuật (Tech Specs). Test kết nối mạng tới SAP Server.                                               | Tài liệu thiết kế kỹ thuật. Môi trường Docker sẵn sàng.   |
| P2. Tích hợp SAP        | 02      | Viết RFC/BAPI hoặc OData trên SAP (mở cổng dữ liệu). Viết Golang SAP Connector, test đọc/ghi.                                                                 | SAP Connector hoạt động. Demo kết nối đọc/ghi.            |
| P3. Phát triển Backend  | 03 - 04 | Lập trình API CRUD, logic Auth & Permission. Implement PDF Generator. Module Notification (SMTP/Webhook).                                                     | API hoàn chỉnh. Demo gửi mail/PDF.                        |
| P4. Phát triển Frontend | 05 - 06 | Cắt giao diện (UI Slicing), tích hợp API. Dựng Dashboard thống kê, Ticket Management (Grid/Kanban), Smart Web Form, Detail View.                              | Web App hoàn chỉnh. Demo trên trình duyệt.                |
| P5. Đóng gói & Kiểm thử | 07 - 08 | Đóng gói Docker Image. Deploy lên VM nội bộ. Hỗ trợ UAT, khắc phục lỗi. Bàn giao Source Code, tài liệu HDSD và Operations Manual (restart/monitor container). | Biên bản nghiệm thu UAT. Tài liệu HDSD & Troubleshooting. |

## 6. YÊU CẦU TÀI NGUYÊN

Để đảm bảo tiến độ dự án, Đội dự án cần được cung cấp:

1. **Hệ thống:** Một máy chủ ảo (VM) nội bộ – OS: Ubuntu Server LTS hoặc CentOS 7+; cấu hình tối thiểu: 2 vCPU, 4GB RAM, 20GB SSD; thông mạng (Ping thấy) Server SAP.
2. **SAP:** Tài khoản SAP Service User có quyền gọi RFC/BAPI để Backend Golang kết nối.
3. **Cấu hình (Optional):** Tên miền nội bộ (VD: `bugtracker.internal`) để người dùng dễ truy cập; thông tin SMTP/Webhook nếu dùng thông báo.

## 7. CAM KẾT CHẤT LƯỢNG & LỢI ÍCH

- **Tuân thủ Clean Core:** Giải pháp chạy bên ngoài SAP, không sửa đổi mã nguồn chuẩn; dữ liệu đồng bộ qua API chuẩn (RFC/OData), an toàn khi nâng cấp SAP.
- **Trải nghiệm hiện đại:** Giao diện Web vượt trội so với ALV/SmartForms; tăng năng suất, truy cập mọi thiết bị không cần cài SAP Logon.
- **Vận hành đơn giản:** Hệ thống đóng gói dạng Container (Docker); việc vận hành chỉ cần `docker start/stop`; cung cấp tài liệu Troubleshooting để đội IT nội bộ dễ tiếp quản.
- **Chi phí License:** Không phát sinh phí SAP BTP hay Cloud Connector; tận dụng hạ tầng VM nội bộ có sẵn.
- **Hỗ trợ sau triển khai:** Hỗ trợ xử lý lỗi kỹ thuật phát sinh trong vòng [Số] tuần sau khi Go-live.
