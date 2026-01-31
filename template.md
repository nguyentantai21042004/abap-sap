PROJECT OVERVIEW - BUG TRACKING MANAGEMENT SYSTEM (ABAP)

- **Tổng quan đề tài (Overview)**

- Bug Tracking Management System là chương trình được xây dựng bằng ABAP nhằm hỗ trợ quản lý lỗi trong hệ thống SAP
- Hệ thống cho phép người dùng ghi nhận bug, theo dõi quá trình xử lý giữa User, Developer và Leader
- Hỗ trợ thống kê, báo cáo và gửi email phục vụ quản lý
- Mục tiêu của đề tài là mô phỏng hệ thống quản lý lỗi nội bộ trong SAP, không sử dụng công cụ bên ngoài như Jira hay Redmine
- Giúp sinh viên hiểu rõ quy trình xử lý lỗi trong môi trường doanh nghiệp

**2\. Phạm vi chức năng (Functional Scope)**

**2.1. Ghi nhận lỗi (Create Bug)**

\- Người dùng có thể tạo mới bug với các thông tin

- Bug ID (tự động sinh)
- Tiêu đề lỗi
- Mô tả chi tiết
- Module liên quan (MM, SD, FI, ABAP…)
- Loại lỗi (Functional, Technical, Enhancement)
- Độ ưu tiên (Low, Medium, High, Critical)
- Người tạo và ngày tạo
- Trạng thái mặc định: NEW
- Kỹ thuật sử dụng
- Screen 0100
- Lưu dữ liệu vào Z-table
- Sinh Bug ID bằng Number Range

**2.2. Gửi Email cho Developer**

\- Sau khi tạo bug, hệ thống tự động gửi email cho

- Developer phụ trách module
- Hoặc nhóm phát triển
- Nội dung email gồm:
- Bug ID
- Tiêu đề
- Mức độ ưu tiên
- Link transaction xem bug
- Kỹ thuật sử dụng
- Class CL_BCS (khuyến nghị)
- Hoặc SO_NEW_DOCUMENT_SEND_API1

**2.3.1 Hiển thị danh sách Bug bằng ALV**

\- Hiển thị danh sách bug bằng ALV OOP (CL_GUI_ALV_GRID)

\- Các cột hiển thị:

- Bug ID
- Title
- Status
- Type
- Priority
- Assigned Developer
- Created Date
- Cho phép lọc theo:
- Status
- Type
- Priority
- Developer
- Kỹ thuật sử dụng:
- Selection Screen
- Dynamic WHERE
- Layout Variant

**2.3.2 In báo cáo bằng SmartForm**

**\-** Cho phép in danh sách bug theo bộ lọc

\- Nội dung báo cáo gồm:

- Header: thời gian in, người in
- Footer: tổng số bug
- Kỹ thuật sử dụng:
- SmartForm
- Gọi từ toolbar của ALV

**2.4. Thống kê lỗi (Dashboard)**

\- Hệ thống thống kê

- Tổng số bug
- Bug đã sửa
- Bug đang xử lý
- Bug chờ duyệt
- Cách thực hiện:
- SELECT COUNT(\*) GROUP BY status
- Hình thức hiển thị:
- ALV
- Danh sách đơn giản

**2.5. Đính kèm bằng chứng (Attachment)**

\- Cho phép upload:

- Screenshot lỗi
- Log file
- Tài liệu liên quan
- Kỹ thuật sử dụng:

CL_GUI_FRONTEND_SERVICES=>FILE_OPEN_DIALOG

- Lưu file bằng:
- GOS Attachment

**Program Structure (Include-based)**

ZBUG_TRACKING_MGMT

── TOP (Global data, types, constants)

── SEL (Selection screen)

── F00 (Create / Save / Update logic)

── F01 (ALV display)

── F02 (Email logic)

── F03 (Statistics)

── O01 (PBO modules)

── I01 (PAI modules)

**Thiết kế dữ liệu (Database Design)**

ZBUG_TRACKER

#### **Cấu Trúc Bảng**

| Field Name       | Data Element     | Domain        | Type   | Length | Key | Description          | Validation Rules                                    |
| ---------------- | ---------------- | ------------- | ------ | ------ | --- | -------------------- | --------------------------------------------------- |
| **MANDT**        | MANDT            | MANDT         | CLNT   | 3      | ✓   | Client ID            | Tự động từ hệ thống                                 |
| **BUG_ID**       | ZDE_BUG_ID       | ZDOM_BUG_ID   | CHAR   | 10     | ✓   | Mã lỗi (Primary Key) | Format: BUG + 7 digits (e.g., BUG0000001)           |
| **TITLE**        | ZDE_BUG_TITLE    | ZDOM_TITLE    | CHAR   | 100    |     | Tiêu đề lỗi          | Mandatory, min 10 chars                             |
| **DESC_TEXT**    | ZDE_BUG_DESC     | ZDOM_LONGTEXT | STRING |        |     | Mô tả chi tiết       | Mandatory, min 20 chars                             |
| **MODULE**       | ZDE_SAP_MODULE   | ZDOM_MODULE   | CHAR   | 20     |     | Phân hệ SAP          | Values: MM, SD, FI, CO, PP, etc.                    |
| **PRIORITY**     | ZDE_PRIORITY     | ZDOM_PRIORITY | CHAR   | 1      |     | Độ ưu tiên           | H=High, M=Medium, L=Low                             |
| **STATUS**       | ZDE_BUG_STATUS   | ZDOM_STATUS   | CHAR   | 1      |     | Trạng thái           | 1=New, 2=Assigned, 3=In Progress, 4=Fixed, 5=Closed |
| **REPORTER**     | ZDE_USERNAME     | ZDOM_USER     | CHAR   | 12     |     | Người báo lỗi        | Tự động từ SY-UNAME                                 |
| **DEV_ID**       | ZDE_USERNAME     | ZDOM_USER     | CHAR   | 12     |     | Developer xử lý      | Lookup từ user master                               |
| **CREATED_AT**   | ZDE_CREATED_DATE | ZDOM_DATE     | DATS   | 8      |     | Ngày tạo             | Tự động từ SY-DATUM                                 |
| **CREATED_TIME** | ZDE_CREATED_TIME | ZDOM_TIME     | TIMS   | 6      |     | Giờ tạo              | Tự động từ SY-UZEIT                                 |
| **CLOSED_AT**    | ZDE_CLOSED_DATE  | ZDOM_DATE     | DATS   | 8      |     | Ngày đóng            | Tự động khi STATUS = 5                              |

#### **Giải Thích Chi Tiết Các Field**

**1\. MANDT (Client ID)**

- **Mục đích**: Phân biệt dữ liệu giữa các client trong SAP
- **Bắt buộc**: Có (SAP standard requirement)
- **Tự động**: Hệ thống tự điền

**2\. BUG_ID (Mã Lỗi)**

- **Mục đích**: Primary key duy nhất cho mỗi bug
- **Format**: BUG + 7 số (VD: BUG0000001, BUG0000123)
- **Auto-generate**: Yes (dùng Number Range Object)

**3\. TITLE (Tiêu Đề)**

- **Mục đích**: Mô tả ngắn gọn vấn đề
- **Validation**: Minimum 10 ký tự, maximum 100 ký tự
- **UI**: Input field, mandatory

**4\. DESC_TEXT (Mô Tả Chi Tiết)**

- **Mục đích**: Mô tả đầy đủ bug, steps to reproduce, expected vs actual
- **Type**: STRING (unlimited length)
- **UI**: Text Editor (multi-line)

**5\. MODULE (Phân Hệ SAP)**

- **Mục đích**: Phân loại bug theo module SAP
- **Values**: MM, SD, FI, CO, PP, QM, PM, WM, HR
- **UI**: Dropdown (F4 help)

**6\. PRIORITY (Độ Ưu Tiên)**

- **Mục đích**: Phân loại mức độ quan trọng
- **Values**:
  - H = High (Ưu tiên cao, cần xử lý gấp)
  - M = Medium (Ưu tiên trung bình)
  - L = Low (Ưu tiên thấp, có thể xử lý sau)
- **UI**: Radio button hoặc dropdown

**7\. STATUS (Trạng Thái)**

- **Mục đích**: Theo dõi vòng đời xử lý lỗi
- **Values**:
  - 1 = New (Mới tạo, chưa assign)
  - 2 = Assigned (Đã giao cho developer)
  - 3 = In Progress (Đang xử lý)
  - 4 = Fixed (Đã sửa, chờ verify)
  - 5 = Closed (Đã đóng, hoàn tất)
- **Default**: 1
- **Workflow**: 1 → 2 → 3 → 4 → 5

**8\. REPORTER (Người Báo Lỗi)**

- **Mục đích**: Ghi nhận ai là người phát hiện lỗi
- **Auto-fill**: Từ SY-UNAME (user đang login)
- **Read-only**: Yes (không cho sửa)

**9\. DEV_ID (Developer Xử Lý)**

- **Mục đích**: Assign bug cho developer cụ thể
- **UI**: F4 help lookup từ user master
- **Optional**: Yes (có thể để trống khi STATUS = 1)

**10\. CREATED_AT & CREATED_TIME (Ngày Giờ Tạo)**

- **Mục đích**: Audit trail, tracking timeline
- **Auto-fill**: Từ SY-DATUM và SY-UZEIT
- **Read-only**: Yes

**11\. CLOSED_AT (Ngày Đóng)**

- **Mục đích**: Tính toán thời gian xử lý (SLA)
- **Auto-fill**: Khi STATUS chuyển sang 5 (Closed)
- **Calculation**: CLOSED_AT - CREATED_AT = Resolution time
