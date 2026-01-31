# SAP Bug Tracking Management System

> **Custom Add-on for SAP ERP**

Một giải pháp quản lý lỗi tập trung (Centralized Bug Tracking Tool) được xây dựng trực tiếp trên nền tảng SAP ERP, giúp doanh nghiệp ghi nhận, theo dõi và xử lý lỗi phần mềm nội bộ mà không cần sử dụng phần mềm bên thứ ba.

---

## 📖 Mục Lục

- [Tổng quan dự án](#-tổng-quan-dự-án)
- [Tính năng chính](#-tính-năng-chính)
- [Kiến trúc hệ thống](#-kiến-trúc-hệ-thống)
- [Tài liệu tham khảo](#-tài-liệu-tham-khảo)

---

## 🚀 Tổng quan dự án

Hệ thống Bug Tracking này là một giải pháp **On-Stack Custom Solution** (Z-Solution) tuân thủ kiến trúc 3-tier của SAP. Mục tiêu là cung cấp quy trình khép kín từ lúc người dùng báo lỗi đến khi developer xử lý và đóng ticket, đảm bảo toàn vẹn dữ liệu và tích hợp sâu với quy trình vận hành SAP hiện tại.

**Điểm nổi bật:**

- **Centralized:** Mọi dữ liệu nằm trong SAP, không phân tán.
- **Automation:** Tự động gửi email thông báo cho team phát triển.
- **User-friendly:** Giao diện nhập liệu và báo cáo quen thuộc (SAP GUI Standard).
- **Compliance:** Tuân thủ triết lý "Clean Core" và bảo mật dữ liệu.

---

## 🌟 Tính năng chính

| Chức năng                 | Mô tả                                                            | Công nghệ                           |
| :------------------------ | :--------------------------------------------------------------- | :---------------------------------- |
| **Ghi nhận lỗi**          | Giao diện nhập liệu thông minh, validate dữ liệu đầu vào.        | T-code `ZBUG_CREATE`, Module Pool   |
| **Quản lý file đính kèm** | Cho phép đính kèm hình ảnh minh chứng (Screenshot, Log).         | GOS (Generic Object Services)       |
| **Thông báo tự động**     | Gửi email alert cho Developer ngay khi có lỗi mới.               | SAPconnect (SMTP), Class `CL_BCS`   |
| **Báo cáo & Thống kê**    | Danh sách lỗi trực quan, hỗ trợ lọc, sắp xếp, xuất Excel.        | ALV Grid (`REUSE_ALV_GRID_DISPLAY`) |
| **Dashboard**             | Thống kê nhanh tình trạng lỗi (New, Processing, Fixed).          | SQL Aggregation                     |
| **In ấn biên bản**        | Xuất biên bản ghi nhận lỗi ra định dạng PDF để lưu trữ/ký duyệt. | SmartForms                          |

---

## 🏗 Kiến trúc hệ thống

Dự án được xây dựng dựa trên mô hình **3-Tier Architecture** chuẩn của SAP NetWeaver:

1.  **Presentation Layer (SAP GUI)**:
    - Màn hình nhập liệu (Screen Painter).
    - Báo cáo danh sách (ALV Grid).
    - Biểu mẫu in ấn (SmartForms).

2.  **Application Layer (ABAP)**:
    - Logic nghiệp vụ (Validation, Workflow).
    - Xử lý gửi mail và quản lý file đính kèm.

3.  **Database Layer (Data Dictionary)**:
    - Bảng dữ liệu tùy chỉnh: `ZBUG_TRACKER`.
    - Lưu trữ metadata và trạng thái của ticket.

---

## 📚 Tài liệu tham khảo

Để hiểu rõ hơn về yêu cầu và thiết kế kỹ thuật, vui lòng tham khảo các tài liệu chi tiết sau:

- 📄 **[Phân tích yêu cầu (Requirements)](./requirements.md)**: Chi tiết các yêu cầu nghiệp vụ và giải pháp kỹ thuật cho từng chức năng.
- 🛠 **[Đề xuất kỹ thuật (Technical Proposal)](./techical-proposal.md)**: Thiết kế chi tiết về Database, Luồng xử lý (Flowchart), và Kế hoạch triển khai.
- 🌍 **[Tổng quan về SAP (SAP Overview)](./sap-overview.md)**: Kiến thức nền tảng về ERP, SAP architecture và ngôn ngữ ABAP.
- 📝 **[Lịch sử thay đổi (Changelog)](./CHANGELOG.md)**: Theo dõi các cập nhật mới nhất của dự án.
