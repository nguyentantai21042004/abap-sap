# 📌 BUSINESS REQUIREMENTS — Module Pool Integration

> **Version:** 2.0 — Ngày: 24/03/2026  
> **Bối cảnh:** Yêu cầu bổ sung từ khách hàng sau khi hoàn thành MVP Big Update  
> **Deadline:** 03/04/2026 (Demo Day)

---

## 1. Yêu cầu gốc từ khách hàng

### REQ-01: Tích hợp Module Pool ở tầng trên cùng

- **Mô tả:** Chuyển toàn bộ UI từ SE38 Selection Screen sang Module Pool (Type M) với Dynpro screens
- **Lý do:** Module Pool là chuẩn enterprise SAP, hỗ trợ dynamic screen control, tab strips, table controls
- **Tham chiếu:** `ZPG_BUGTRACKING_MAIN` + `ZPG_BUGTRACKING_DETAIL`
- **Yêu cầu con:**
  - Phải sở hữu hoàn hảo logic của 2 programs mẫu
  - Phải giữ nguyên các cải tiến đã có (Auto-Assign, Permission FM, History, Email, SmartForm, Config Bug workflow)

### REQ-02: Thêm thực thể Project ở trên Bug

- **Mô tả:** Bug phải thuộc về một Project cụ thể (quan hệ 1:N)
- **Dữ liệu Project:**
  - Project ID, Project Name, Description
  - Start Date, End Date
  - Project Manager
  - Project Status (Opening/In Process/Done/Cancel)
  - Note (Long Text)
- **Quan hệ:** User ↔ Project là Many-to-Many (bảng trung gian)
- **Business rule:** Chỉ tạo Bug trong Project có status "In Process"
- **Tham chiếu (ZPG):** Bảng `ZTB_PROJECT`, `ZTB_USER_PROJECT`

### REQ-03: Bảng phân quyền chi tiết cho Bug và Project

- **Mô tả:** Cần hệ thống phân quyền rõ ràng, tập trung, theo từng action
- **Yêu cầu:**
  - Permission check cho cả Bug actions VÀ Project actions
  - User chỉ thao tác được trên Project mà mình thuộc về
  - Role-based screen control (ẩn/hiện/lock fields theo role + mode)
- **Tham chiếu (ZPG):** Check `user_id IN ztb_user_project`, role '1'/'2'/'3' control screen fields
- **Cải tiến ZBUG:** Giữ FM `Z_BUG_CHECK_PERMISSION` nhưng mở rộng thêm Project permissions

### REQ-04: Clear lại Status states

- **Mô tả:** Hệ thống status hiện tại cần được chuẩn hóa, kết hợp cả 2 hệ thống
- **Status đề xuất (hợp nhất):**

| Code | Status | Mô tả | Từ ZBUG | Từ ZPG |
|------|--------|-------|---------|--------|
| 1 | New/Opening | Bug mới tạo | 1(New) | 1(Opening) |
| 2 | Assigned | Đã gán cho Dev | 2(Assigned) | — |
| 3 | In Progress | Dev đang fix | 3(InProgress) | 2(In Process ABAP) |
| 4 | Pending | Chờ phản hồi | — | 4/5(Pending) |
| 5 | Fixed | Dev fix xong, chờ verify | 4(Fixed) | 6(Fixed) |
| 6 | Resolved | Tester verify pass | — | 7(Resolve) |
| 7 | Closed | Đóng hoàn tất | 5(Closed) | — |
| W | Waiting | Chờ Manager assign | W(Waiting) | — |
| R | Rejected | Dev từ chối | 6(Rejected) | — |

### REQ-05: Server-side file storage (GOS)

- **Mô tả:** File phải được upload lên SAP server, không lưu đường dẫn local PC
- **Giải pháp (đã confirm):** Dùng **GOS** (Generic Object Services)
- **Chi tiết kỹ thuật:**
  - Sử dụng `CL_GOS_DOCUMENT_SERVICE` hoặc BDS (`BDS_BUSINESSDOCUMENT_CREA_TAB`)
  - File lưu trong SAP DB, truy cập qua object key (BUG_ID)
  - Không cần cấu hình DMS/Content Server riêng

### REQ-06: Validate user khi create Bug

- **Mô tả:** Khi tạo bug, kiểm tra user hiện tại có tồn tại trong hệ thống không
- **Tham chiếu (ZPG):**

  ```abap
  SELECT SINGLE user_id, role FROM ztb_user_info
    WHERE user_id = @sy-uname.
  IF sy-subrc <> 0. MESSAGE 'User not found'. RETURN. ENDIF.
  ```

- **Cải tiến:** Đã có trong `Z_BUG_CHECK_PERMISSION`, bổ sung validate user thuộc project

### REQ-07: Nút Refresh trên UI

- **Mô tả:** Phải có nút Refresh trên toolbar để reload dữ liệu ALV
- **Cải tiến:** Thêm REFRESH vào GUI Status + gọi `ALV->refresh_table_display()`

### REQ-08: Email bắt buộc + SmartForms

- **Mô tả:** Email phải là trường bắt buộc khi tạo/quản lý user. Mọi notification phải gửi email
- **Giải pháp (đã confirm):** Dùng **SmartForms** để generate email body (HTML/PDF format)
- **Chi tiết:**
  - Field EMAIL trong ZBUG_USERS → OBLIGATORY
  - Validate email format trước khi save
  - Tạo SmartForm `ZBUG_EMAIL_FORM` cho email notification
  - Gọi SmartForm → generate HTML → gửi qua CL_BCS

### REQ-09: Bug Type + Severity (dual classification)

- **Mô tả:** Giữ cả hai hệ thống phân loại bug
- **Bug Type:** C(Code) / F(Config) → quyết định **workflow branching** (Code → Dev fix, Config → Tester self-fix)
- **Severity:** 1(Dump) / 2(Very High) / 3(High) / 4(Normal) / 5(Minor) → quyết định **priority + SLA**
- **Impact:** Thêm field `SEVERITY` (CHAR 1) vào `ZBUG_TRACKER`

### REQ-10: Đa ngôn ngữ (Message Class)

- **Mô tả:** Hỗ trợ đa ngôn ngữ (EN/VI) qua Message Class chuẩn SAP
- **Giải pháp:** Tạo Message Class `ZBUG_MSG` (SE91)
- **Impact:** Migrate tất cả hardcoded messages sang Message Class
- **Lợi ích:** Tuân thủ chuẩn SAP enterprise, dễ mở rộng (JP, KR...) mà không sửa code

> [!TIP]
> **Điểm mạnh khi demo:** Đa ngôn ngữ qua Message Class là feature chuẩn SAP enterprise. Chỉ cần maintain translations trong SE91.

### REQ-11: Upload Project từ Excel

- **Mô tả:** Import project data từ file Excel có format chuẩn
- **Chi tiết:**
  1. Tạo Excel template trên MIME Repository (SMW0): `ZTEMPLATE_PROJECT`
  2. Template columns: Project ID, Name, Description, Start Date, End Date, PM, Status, User ID, User Name, Email, Role
  3. Dùng `TEXT_CONVERT_XLS_TO_SAP` parse data
  4. Validation: check trùng, format date, mandatory fields
  5. Insert vào `ZBUG_PROJECT` + `ZBUG_USER_PROJECT`
  6. Nút Download Template trên GUI Status

### REQ-12: History Log Tab

- **Mô tả:** Hiển thị lịch sử thay đổi bug trên tab riêng trong Bug Detail
- **Chi tiết:**
  1. Tab "History" (SubScreen 0260) trên Bug Detail Tab Strip
  2. ALV Grid readonly: `ZBUG_HISTORY WHERE BUG_ID = current`
  3. Columns: Date, Time, User, Action Type (text mapped), Old Value, New Value, Reason
  4. Filter cơ bản: Action Type (dropdown), Date range
  5. Export to Excel (built-in ALV toolbar)

---

## 2. Yêu cầu phi chức năng

| # | Yêu cầu | Chi tiết |
|---|---------|---------|
| NFR-01 | Kiến trúc | Module Pool (Type M) thay SE38 |
| NFR-02 | Screen technology | Dynpro + Screen Painter |
| NFR-03 | Reusability | Giữ FM architecture cho business logic |
| NFR-04 | UI/UX | Dynamic screen control, F4 help, Tab strip, Table control |
| NFR-05 | Data integrity | Soft delete (IS_DEL), Full audit fields (6 fields) |
| NFR-06 | SAP Standard | Message Class (ZBUG_MSG), SAPScript Long Text, naming convention Z* |
| NFR-07 | Security | Role-based access, User-Project membership validation |
| NFR-08 | Internationalization | Đa ngôn ngữ EN/VI qua Message Class (SE91) |
| NFR-09 | File storage | GOS — không dependency local path |

---

## 3. Acceptance Criteria

| REQ | Acceptance Criteria |
|-----|---------------------|
| REQ-01 | Chạy T-code ZBUG_HOME → hiển thị Module Pool screen, không phải Selection Screen |
| REQ-02 | Tạo Project → Tạo Bug trong Project → Bug hiển thị Project ID |
| REQ-03 | User role 'T' không thấy nút Delete. Dev chỉ sửa được bug assigned cho mình |
| REQ-04 | Bug status transition theo đúng state diagram mới |
| REQ-05 | File upload qua GOS, không lưu local path, view được từ GOS toolbar |
| REQ-06 | Tạo bug bằng user không tồn tại → nhận error message |
| REQ-07 | Bấm Refresh → ALV grid reload dữ liệu mới nhất |
| REQ-08 | Email sent qua SmartForm, check SOST. Tạo user không có email → error |
| REQ-09 | Bug có cả Bug Type (C/F) và Severity (1-5). Workflow rẽ nhánh đúng |
| REQ-10 | Chuyển ngôn ngữ logon (EN/VI) → messages hiển thị đúng ngôn ngữ |
| REQ-11 | Download template → điền data → upload → project tạo thành công |
| REQ-12 | Tab History hiện log, filter theo Action Type hoạt động |
