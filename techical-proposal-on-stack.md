# XÂY DỰNG PHÂN HỆ QUẢN LÝ LỖI (BUG TRACKING) – GIẢI PHÁP ON-STACK

Tham chiếu phần chung và so sánh: `techical-proposal-main.md`.

## 1. TỔNG QUAN DỰ ÁN

Phát triển một **Custom Solution (Z-Solution)** chạy trực tiếp trên SAP ERP. Giải pháp tuân thủ kiến trúc kỹ thuật chuẩn của SAP, đảm bảo tính bảo mật, toàn vẹn dữ liệu và khả năng tích hợp sâu (Deep Integration) với quy trình vận hành hiện tại.

## 2. KIẾN TRÚC KỸ THUẬT

Giải pháp được xây dựng theo mô hình 3 lớp (3-Tier Architecture) của SAP NetWeaver:

- **Lớp Dữ liệu (Data Layer - SE11):** Sử dụng bảng trong suốt tùy chỉnh (**Transparent Table**) nằm trong không gian tên khách hàng (`Z*`), không can thiệp dữ liệu chuẩn (Standard Data).
- **Lớp Ứng dụng (Application Layer - ABAP):** Xử lý logic nghiệp vụ, xác thực dữ liệu và điều phối luồng (Workflow) bằng **ABAP**.
- **Lớp Trình diễn (Presentation Layer - SAP GUI):** Giao diện theo **SAP GUI Guidelines**, dùng **ALV Grid** cho báo cáo và **SmartForms** cho in ấn.

```mermaid
graph TD
    style Client_PC fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    subgraph Client_PC [Client UI, PC/Mobile]
        GUI[SAP GUI / SAP Logon]
    end

    subgraph SAP_Server [SAP ERP]
        style SAP_Server fill:#e1f5fe,stroke:#01579b,stroke-width:2px

        subgraph Presentation_Layer [SAP GUI]
            style Presentation_Layer fill:#bbdefb,stroke:#0d47a1,stroke-width:2px
            Screen[Màn hình nhập liệu T-code]
            ALV[Báo cáo ALV Grid]
            Form[In ấn SmartForms]
        end

        subgraph Application_Layer [Application Layer - ABAP]
            style Application_Layer fill:#fff9c4,stroke:#fbc02d,stroke-width:2px
            Logic[Z_BUG_PROGRAM]
            Mail[SAPconnect, sử dụng SMTP]
        end

        subgraph Database_Layer [Data Layer]
            style Database_Layer fill:#ffe0b2,stroke:#e65100,stroke-width:2px
            DB[Bảng ZBUG_TRACKER]
            GOS[Attachments]
        end
    end

    GUI <==>|Tương tác trực tiếp| Screen
    GUI <==>|Xem báo cáo| ALV
    Screen -->|Lưu dữ liệu| Logic
    Logic -->|CRUD| DB
    Logic -->|Trigger| Mail
    Logic -->|Lưu file| GOS
    ALV -->|Lấy dữ liệu| DB
```

## 3. PHẠM VI CÔNG VIỆC CHI TIẾT

Hệ thống bao gồm các module chức năng chính:

### 3.1. Module Quản trị Dữ liệu

- **Thiết kế bảng `ZBUG_TRACKER`:** Lưu trữ toàn bộ thông tin vòng đời của lỗi.
- _Trường chính:_ Ticket ID (Key), Title, Description, Module (MM/SD/FI...), Priority, Status, Reporter, Assignee, Created Date, Closed Date.
- **Định nghĩa Data Element & Domain:** Chuẩn hóa các giá trị nhập liệu (VD: Status chỉ được phép New/Processing/Fixed).

### 3.2. Module Ghi nhận lỗi

- **Giao diện nhập liệu (T-code `ZBUG_CREATE`):** Selection Screen thân thiện, tự động lấy `SY-UNAME` và thời gian hệ thống.
- **Validation:** Kiểm tra tính hợp lệ của dữ liệu trước khi lưu.
- **Quản lý đính kèm:** Tích hợp **Generic Object Services (GOS)** để đính kèm ảnh/log lỗi.
- **Tự động hóa:** Tích hợp **SAPconnect (SMTP)** để gửi email thông báo khi tạo/cập nhật lỗi.

### 3.3. Module Báo cáo & Theo dõi

- **Báo cáo danh sách (T-code `ZBUG_REPORT`):** **ALV Grid**, hỗ trợ Sort/Filter/Aggregation, xuất Excel.
- **Drill-down:** Click mã lỗi để xem chi tiết hoặc cập nhật trạng thái.
- **Dashboard thống kê:** Tổng hợp lỗi theo trạng thái (Open/Closed) và mức độ ưu tiên.

### 3.4. Module In ấn

- **Biểu mẫu `ZBUG_FORM`:** Thiết kế bằng **SmartForms**.
- Bao gồm: Logo công ty, thông tin lỗi, khu vực ký duyệt.
- Hỗ trợ xuất PDF hoặc in trực tiếp qua máy in SAP.

## 4. KẾ HOẠCH TRIỂN KHAI

**Tổng thời gian thực hiện:** 08 tuần.  
**Phương pháp:** Waterfall (Phân tích → Thiết kế → Lập trình → Kiểm thử).

| Giai đoạn               | Tuần    | Hạng mục công việc (Work Item)                                                                                 | Kết quả bàn giao (Deliverables)                                      |
| ----------------------- | ------- | -------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| P1. Khởi tạo            | 01      | Thiết lập môi trường Development.<br>Phân tích đặc tả kỹ thuật (Tech Specs).<br>Thiết kế Database Schema (SE11). | Tài liệu thiết kế kỹ thuật.<br>Cấu trúc bảng (Table Definition).     |
| P2. Phát triển Core     | 02 - 03 | Lập trình màn hình nhập liệu.<br>Logic CRUD & Validation.<br>Cấu hình & lập trình gửi Email.                  | T-code nhập liệu hoạt động.<br>Demo luồng gửi mail tự động.          |
| P3. Báo cáo & In ấn     | 04 - 05 | Lập trình báo cáo ALV Grid.<br>Thiết kế SmartForms.<br>Dashboard thống kê.                                   | T-code báo cáo hoàn chỉnh.<br>Mẫu in PDF đúng chuẩn.                 |
| P4. Đóng gói            | 06      | Rà soát mã nguồn (Code Inspector).<br>Tối ưu hiệu năng.<br>Đóng gói Transport Request.                       | Source code đã tối ưu.<br>Gói cài đặt hoàn chỉnh.                    |
| P5. Kiểm thử & Bàn giao | 07 - 08 | Hỗ trợ UAT.<br>Khắc phục lỗi (Bug Fixing).<br>Bàn giao tài liệu & source code.                                 | Biên bản nghiệm thu UAT.<br>Tài liệu HDSD (User Manual).             |

## 5. YÊU CẦU TÀI NGUYÊN

Để đảm bảo tiến độ dự án, Đội dự án cần được cung cấp:

1. **Hệ thống:** Tài khoản SAP Development Server với quyền **Developer Access Key**.
2. **Cấu hình:** Thông tin SMTP Server (IP, Port) để cấu hình gửi mail.
3. **Nghiệp vụ:** Quy trình phê duyệt lỗi và mẫu biểu in ấn (nếu có).

## 6. CAM KẾT CHẤT LƯỢNG & BẢO HÀNH

- **Tuân thủ Clean Core:** Không sửa đổi mã nguồn chuẩn, an toàn khi nâng cấp SAP.
- **Tiêu chuẩn lập trình:** Tuân thủ quy chuẩn đặt tên SAP, có comment rõ ràng, dễ bảo trì.
- **Hỗ trợ sau triển khai:** Hỗ trợ xử lý lỗi kỹ thuật trong vòng [Số] tuần sau Go-live.
