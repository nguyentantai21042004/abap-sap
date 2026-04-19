// ============================================================
// acronyms.typ — Định nghĩa và Từ viết tắt
// ============================================================
#import "../template.typ": placeholder, hline, field

= Định nghĩa và Từ viết tắt

#table(
  columns: (2.5cm, 1fr),
  align: (center, left),
  [*Từ viết tắt*], [*Định nghĩa*],
  [ABAP],      [Advanced Business Application Programming — ngôn ngữ độc quyền của SAP],
  [ALV],       [ABAP List Viewer — thành phần lưới chuẩn của SAP],
  [BCS],       [Business Communication Services — API email SAP (CL_BCS)],
  [BUG_ID],    [Mã định danh lỗi duy nhất, định dạng BUG0000001, tự sinh qua ZNRO_BUG],
  [CRUD],      [Create, Read, Update, Delete — các thao tác dữ liệu cơ bản],
  [DEV],       [Developer — vai trò chịu trách nhiệm sửa lỗi],
  [ERD],       [Entity Relationship Diagram — Sơ đồ Quan hệ Thực thể],
  [GOS],       [Generic Object Services — framework đính kèm file của SAP],
  [GUI],       [Graphical User Interface — Giao diện Người dùng Đồ họa],
  [MGR],       [Manager — vai trò có toàn quyền truy cập hệ thống],
  [PAI],       [Process After Input — sự kiện màn hình sau thao tác người dùng],
  [PBO],       [Process Before Output — sự kiện màn hình trước khi hiển thị],
  [PDF],       [Portable Document Format — định dạng in SmartForm],
  [SAP],       [Systems, Applications and Products in Data Processing],
  [SDD],       [Software Design Description — Mô tả Thiết kế Phần mềm],
  [SMTP],      [Simple Mail Transfer Protocol],
  [SPMP],      [Software Project Management Plan — Kế hoạch Quản lý Dự án Phần mềm],
  [SRS],       [Software Requirement Specification — Đặc tả Yêu cầu Phần mềm],
  [SE11],      [SAP Data Dictionary — công cụ tạo bảng/miền/phần tử dữ liệu],
  [SE41],      [Menu Painter — trình chỉnh sửa GUI Status và Title Bar],
  [SE51],      [Screen Painter — trình chỉnh sửa layout màn hình Dynpro],
  [SE80],      [Object Navigator — ABAP Workbench chính],
  [SE93],      [Transaction Maintenance — trình chỉnh sửa T-code],
  [T-Code],    [Transaction Code — lệnh tắt chương trình SAP (ví dụ: ZBUG_WS)],
  [UAT],       [User Acceptance Test — Kiểm thử Chấp thuận Người dùng],
  [UC],        [Use Case — Ca Sử dụng],
  [ZBUGTRACK], [Gói Phát triển SAP chứa tất cả các đối tượng `ZBUG_*`],
  [ZBUG_WS],   [T-Code đầu vào của hệ thống Bug Tracking],
)
