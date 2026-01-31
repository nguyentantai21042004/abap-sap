---
marp: true
theme: default
paginate: true
header: "SAP Bug Tracking Management System"
footer: "Báo Cáo Đồ Án | 31/01/2026"
---

<!-- _class: lead -->

# HỆ THỐNG QUẢN LÝ LỖI SAP

**Bug Tracking Management System**

Báo Cáo Đồ Án
31/01/2026

---

## 1. Tổng Quan Đề Tài

**Mục tiêu:**

- Xây dựng hệ thống quản lý lỗi nội bộ trong SAP bằng ABAP
- Không sử dụng công cụ bên ngoài (Jira, Redmine)
- Mô phỏng quy trình xử lý bug trong môi trường doanh nghiệp

**Phạm vi:**

- Quản lý vòng đời lỗi (tạo → theo dõi → xử lý → đóng)
- Dữ liệu tập trung, truy xuất nhanh
- Tích hợp sâu với SAP ERP

**Người dùng:** User, Developer, Leader

---

## 2. Phạm Vi Chức Năng (Overview)

| #         | Chức năng     | Công nghệ                          |
| --------- | ------------- | ---------------------------------- |
| **2.1**   | Ghi nhận lỗi  | Screen 0100, Z-table, Number Range |
| **2.2**   | Gửi Email     | CL_BCS, SAPconnect                 |
| **2.3.1** | Hiển thị ALV  | CL_GUI_ALV_GRID                    |
| **2.3.2** | In SmartForm  | SmartForms                         |
| **2.4**   | Thống kê      | SQL Aggregation                    |
| **2.5**   | Đính kèm file | GOS (Generic Object Services)      |

---

## 2.1. Ghi Nhận Lỗi

**Chức năng:**

- Form nhập liệu với các trường: Title, Description, Module, Priority
- Bug ID tự động sinh (BUG + 7 số)
- Trạng thái mặc định: NEW

**Kỹ thuật:**

- **Screen 0100**: PBO/PAI modules
- **Z-table**: `ZBUG_TRACKER`
- **Number Range**: `ZNRO_BUG`
- **Validation**: Title ≥ 10 chars, mandatory fields

**Skeleton structure:**

```abap
" Skeleton structure:
FORM create_bug.
  " Generate Bug ID (ZNRO_BUG)
  " Validate fields
  " Save to ZBUG_TRACKER
ENDFORM.
```

---

## 2.2. Gửi Email cho Developer

**Chức năng:**

- Tự động gửi email sau khi tạo bug
- Thông báo cho Developer phụ trách module

**Nội dung email:**

- Bug ID, Title, Priority
- Người báo lỗi, Link transaction

**Skeleton structure:**

```abap
" Skeleton structure:
FORM send_email.
  " lo_send_request = cl_bcs=>create_persistent()
  " lo_document = cl_document_bcs=>create_document()
  " Add recipient and send
ENDFORM.
```

---

## 2.3.1. Hiển Thị Danh Sách Bug (ALV)

**Chức năng:**

- Hiển thị danh sách bugs với ALV Grid
- Filter: Status, Type, Priority, Developer
- Sort, Export Excel

**Các cột:**
Bug ID | Title | Status | Priority | Developer | Created Date

**Skeleton structure:**

```abap
" Skeleton structure:
FORM display_alv.
  " SELECT with dynamic WHERE
  " Build fieldcat
  " REUSE_ALV_GRID_DISPLAY
ENDFORM.
```

---

## 2.3.2. In Báo Cáo (SmartForm)

**Chức năng:**

- In danh sách bugs theo bộ lọc
- Xuất PDF hoặc in giấy

**Nội dung báo cáo:**

- **Header**: Logo, tiêu đề, thời gian in
- **Body**: Bảng bugs (ID, Title, Status, Priority...)
- **Footer**: Tổng số bug, page number

**Kỹ thuật:**

- SmartForm Designer: `ZBUG_FORM`
- Gọi từ toolbar ALV
- `SSF_FUNCTION_MODULE_NAME`

---

## 2.4. Thống Kê Lỗi (Dashboard)

**Các chỉ số:**

- Tổng số bug
- Bug đã sửa (Fixed/Closed)
- Bug đang xử lý (In Progress)
- Bug mới (New)
- Phân bổ theo Priority, Module

**Skeleton structure:**

```abap
" Skeleton structure:
FORM display_statistics.
  " SELECT COUNT(*) GROUP BY status
  " SELECT COUNT(*) GROUP BY priority
  " Display in ALV
ENDFORM.
```

---

## 2.5. Đính Kèm Bằng Chứng

**Chức năng:**

- Upload file: Screenshot, Log file, Documents
- Hỗ trợ: PNG, JPG, PDF, TXT, LOG

**Skeleton structure:**

```abap
" Skeleton structure:
FORM upload_attachment.
  " file_open_dialog()
  " gui_upload()
  " Save via GOS
ENDFORM.
```

**Lưu trữ:** GOS (Generic Object Services)

---

## 3. Cấu Trúc Chương Trình

**Include-based Structure:**

```
ZBUG_TRACKING_MGMT
├── TOP  (Global data, types, constants)
├── SEL  (Selection screen)
├── F00  (Create/Save/Update logic)
├── F01  (ALV display)
├── F02  (Email logic)
├── F03  (Statistics)
├── O01  (PBO modules)
└── I01  (PAI modules)
```

---

## 4. Thiết Kế Database - Bảng ZBUG_TRACKER

| Field     | Type   | Length | Key | Description                                         |
| --------- | ------ | ------ | --- | --------------------------------------------------- |
| MANDT     | CLNT   | 3      | ✓   | Client ID                                           |
| BUG_ID    | CHAR   | 10     | ✓   | Bug ID (BUG0000001)                                 |
| TITLE     | CHAR   | 100    |     | Tiêu đề lỗi                                         |
| DESC_TEXT | STRING | -      |     | Mô tả chi tiết                                      |
| MODULE    | CHAR   | 20     |     | Phân hệ SAP                                         |
| PRIORITY  | CHAR   | 1      |     | H/M/L                                               |
| STATUS    | CHAR   | 1      |     | 1=New, 2=Assigned, 3=In Progress, 4=Fixed, 5=Closed |

---

## 4. Database Fields (continued)

| Field        | Type | Length | Description                    |
| ------------ | ---- | ------ | ------------------------------ |
| REPORTER     | CHAR | 12     | Người báo lỗi (SY-UNAME)       |
| DEV_ID       | CHAR | 12     | Developer xử lý                |
| CREATED_AT   | DATS | 8      | Ngày tạo (SY-DATUM)            |
| CREATED_TIME | TIMS | 6      | Giờ tạo (SY-UZEIT)             |
| CLOSED_AT    | DATS | 8      | Ngày đóng (auto when STATUS=5) |

**Total: 11 fields**

---

## 4. Status Workflow

```
[NEW] ──────────────────────────────────────────────────────
  │ (1)                                                     │
  ├─→ [ASSIGNED] (2)                                        │
  │      │                                                  │
  │      ├─→ [IN PROGRESS] (3)                              │
  │      │      │                                           │
  │      │      ├─→ [FIXED] (4)                             │
  │      │      │      │                                    │
  │      │      │      └─→ [CLOSED] (5) ←──────────────────┘
  │      │      │
  │      │      └─→ [CLOSED] (5)
  │      │
  │      └─→ [CLOSED] (5)
  │
  └─→ [CLOSED] (5)
```

**Default**: STATUS = 1 (NEW)

---

## Kết Luận

**Hệ thống bao gồm:**

- ✅ 5 chức năng chính (Create, Email, ALV, SmartForm, Stats, Attach)
- ✅ Cấu trúc chương trình rõ ràng (include-based)
- ✅ Database thiết kế đầy đủ (11 fields)
- ✅ Sử dụng công nghệ SAP chuẩn (ABAP, ALV, SmartForms, GOS)

**Deliverables:**

- Source code ABAP
- Database objects (Table, Domains, Data Elements)
- Documentation

---

<!-- _class: lead -->

# Q&A

**Cảm ơn thầy đã lắng nghe!**

---
