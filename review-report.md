# BÁO CÁO DỰ ÁN: HỆ THỐNG QUẢN LÝ LỖI SAP

**Dự án:** SAP Bug Tracking Management System  
**Loại:** Báo Cáo Đồ Án (Technical Report)  
**Ngày:** 31/01/2026

---

## 1. TỔNG QUAN ĐỀ TÀI

Bug Tracking Management System là chương trình được xây dựng bằng ABAP nhằm hỗ trợ quản lý lỗi trong hệ thống SAP. Hệ thống cho phép người dùng ghi nhận bug, theo dõi quá trình xử lý giữa User, Developer và Leader, đồng thời hỗ trợ thống kê, báo cáo và gửi email phục vụ quản lý.

**Mục tiêu của đề tài:**

- Mô phỏng hệ thống quản lý lỗi nội bộ trong SAP
- Không sử dụng công cụ bên ngoài như Jira hay Redmine
- Giúp sinh viên hiểu rõ quy trình xử lý lỗi trong môi trường doanh nghiệp
- Áp dụng kiến thức ABAP vào bài toán thực tế

**Phạm vi:**

- Quản lý vòng đời lỗi (tạo, theo dõi, xử lý, đóng)
- Dữ liệu tập trung, truy xuất nhanh
- Tích hợp với SAP ERP, bảo mật cao

---

## 2. PHẠM VI CHỨC NĂNG

### 2.1. Ghi nhận lỗi (Create Bug)

**Mô tả:**
Người dùng có thể tạo mới bug với các thông tin đầy đủ để phục vụ quá trình xử lý.

**Thông tin cần nhập:**

- Bug ID (tự động sinh)
- Tiêu đề lỗi
- Mô tả chi tiết
- Module liên quan (MM, SD, FI, ABAP…)
- Loại lỗi (Functional, Technical, Enhancement)
- Độ ưu tiên (Low, Medium, High, Critical)
- Người tạo và ngày tạo
- Trạng thái mặc định: NEW

**Kỹ thuật sử dụng:**

- **Screen 0100**: Màn hình nhập liệu với PBO/PAI modules
- **Z-table**: Lưu dữ liệu vào bảng `ZBUG_TRACKER`
- **Number Range**: Sinh Bug ID tự động bằng Number Range Object `ZNRO_BUG`
- **Validation**: Kiểm tra mandatory fields, độ dài tối thiểu (title ≥ 10 chars)

**Skeleton structure:**

```abap
FORM create_bug.
  " Generate Bug ID using Number Range
  " Validate mandatory fields
  " Save to ZBUG_TRACKER table
ENDFORM.
```

---

### 2.2. Gửi Email cho Developer

**Mô tả:**
Sau khi tạo bug, hệ thống tự động gửi email thông báo cho Developer phụ trách module hoặc nhóm phát triển.

**Nội dung email:**

- Bug ID
- Tiêu đề bug
- Mức độ ưu tiên
- Link transaction xem bug (T-code)
- Thông tin người báo lỗi

**Kỹ thuật sử dụng:**

- **Class CL_BCS**: Business Communication Services
- **SMTP**: SAPconnect

**Skeleton structure:**

```abap
FORM send_email USING p_bug_id TYPE zde_bug_id.
  " Create send request using CL_BCS
  " Create email document
  " Add recipient
  " Send email
ENDFORM.
```

---

### 2.3.1. Hiển thị danh sách Bug bằng ALV

**Mô tả:**
Hiển thị danh sách bug bằng ALV OOP (`CL_GUI_ALV_GRID`) với các tính năng lọc, sắp xếp và xuất Excel.

**Các cột hiển thị:**

- Bug ID
- Title
- Status (New, Assigned, In Progress, Fixed, Closed)
- Type (Functional, Technical, Enhancement)
- Priority (Low, Medium, High, Critical)
- Assigned Developer
- Created Date

**Tính năng lọc:**
Cho phép lọc theo:

- Status
- Type
- Priority
- Developer
- Date range

**Kỹ thuật sử dụng:**

- **ALV Grid**: Hiển thị danh sách với filter, sort
- **Export Excel**: Built-in functionality

**Skeleton structure:**

```abap
FORM display_alv.
  " Fetch data with dynamic WHERE clause
  " Build field catalog
  " Display ALV Grid
ENDFORM.
```

---

### 2.3.2. In báo cáo bằng SmartForm

**Mô tả:**
Cho phép in danh sách bug theo bộ lọc, xuất ra PDF hoặc in giấy.

**Nội dung báo cáo:**

- **Header**: Logo công ty, tiêu đề báo cáo, thời gian in, người in
- **Body**: Danh sách bugs (table format)
  - Bug ID, Title, Status, Priority, Developer, Created Date
- **Footer**: Tổng số bug, page number, chữ ký
- **Summary section**: Thống kê tổng quan (Total bugs, Fixed, Pending)

**Kỹ thuật sử dụng:**

- **SmartForms**: Thiết kế form in ấn
- **PDF Export**: Xuất báo cáo ra file PDF

**Skeleton structure:**

```abap
FORM print_report.
  " Get selected rows from ALV
  " Get SmartForm function module name
  " Call generated function module
ENDFORM.
```

---

### 2.4. Thống kê lỗi (Dashboard)

**Mô tả:**
Hệ thống thống kê tổng quan về tình trạng bugs, giúp quản lý nắm bắt hiện trạng nhanh chóng.

**Các chỉ số thống kê:**

- Tổng số bug
- Bug đã sửa (Status = Fixed hoặc Closed)
- Bug đang xử lý (Status = In Progress)
- Bug chờ duyệt (Status = Assigned)
- Bug mới (Status = New)
- Phân bổ theo độ ưu tiên (High/Medium/Low)
- Phân bổ theo module (MM, SD, FI, CO, PP...)

**Cách thực hiện:**

- **SQL Aggregation**: `SELECT COUNT(*) GROUP BY status/priority/module`
- **Data structures**: Internal tables để lưu kết quả thống kê

**Skeleton structure:**

```abap
FORM display_statistics.
  " SELECT COUNT(*) GROUP BY status
  " SELECT COUNT(*) GROUP BY priority
  " SELECT COUNT(*) GROUP BY module
  " Display results in ALV or simple list
ENDFORM.
```

**Hình thức hiển thị:**

- **Option 1**: ALV Grid (simple table display)
- **Option 2**: Danh sách đơn giản với WRITE statement
- **Option 3**: Top-of-page header trong ALV Report
- **Enhancement**: Chart/Graph (nếu có thời gian - sử dụng Graphics Control)

---

### 2.5. Đính kèm bằng chứng (Attachment)

**Mô tả:**
Cho phép người dùng upload các file bằng chứng kèm theo bug report.

**Loại file hỗ trợ:**

- Screenshot lỗi (PNG, JPG, BMP)
- Log file (TXT, LOG)
- Tài liệu liên quan (PDF, DOC, XLS)

**Kỹ thuật sử dụng:**

- **Upload**: CL_GUI_FRONTEND_SERVICES
- **Lưu trữ**: GOS (Generic Object Services)

**Skeleton structure:**

```abap
FORM upload_attachment.
  " Open file dialog
  " Upload file from frontend
  " Save via GOS
ENDFORM.
```

---

## 3. CẤU TRÚC CHƯƠNG TRÌNH

### 3.1. Program Structure (Include-based)

**Main Program**: `ZBUG_TRACKING_MGMT`

```
ZBUG_TRACKING_MGMT
├── TOP (Global data, types, constants)
├── SEL (Selection screen)
├── F00 (Create / Save / Update logic)
├── F01 (ALV display)
├── F02 (Email logic)
├── F03 (Statistics)
├── O01 (PBO modules)
└── I01 (PAI modules)
```

---

## 4. THIẾT KẾ DỮ LIỆU

### 4.1. Bảng `ZBUG_TRACKER`

**Mục đích**: Lưu trữ toàn bộ thông tin vòng đời của bug

**Cấu trúc bảng:**

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

---

## 5. KẾT LUẬN

Hệ thống Bug Tracking Management được thiết kế với 5 chức năng chính, sử dụng công nghệ ABAP chuẩn của SAP. Cấu trúc chương trình theo mô hình include-based giúp dễ bảo trì và mở rộng. Database được thiết kế đầy đủ với 11 fields phục vụ quản lý vòng đời bug từ lúc tạo đến khi đóng.

**Công nghệ sử dụng**:

- Module Pool / Reports
- ALV Grid (CL_GUI_ALV_GRID)
- SmartForms
- Email (CL_BCS)
- GOS (Generic Object Services)
- Number Range Object

**Deliverables**:

- Source code ABAP
- Database objects (Table, Domains, Data Elements)
- Documentation

---

**Document Control:**

- **Prepared by:** Development Team
- **Date:** 31/01/2026
- **Version:** 1.0 - Review Report
