// ============================================================
// 04_reports.typ — BÁO CÁO
// ============================================================
#import "../template.typ": placeholder, hline

= BÁO CÁO

Dựa trên yêu cầu hệ thống, các báo cáo và đầu ra sau đây có sẵn trong Hệ thống Quản lý Theo dõi Lỗi SAP.

#table(
  columns: (1cm, 4cm, 1fr, 3cm),
  align: (center, left, left, center),
  [*STT*], [*Mô tả*], [*Chi tiết*], [*T-Code / Truy cập*],
  [1],
    [Báo cáo ALV Danh sách Lỗi],
    [Danh sách đầy đủ lỗi theo dự án với trạng thái, ưu tiên, module, tester, developer được tô màu. Hỗ trợ lọc, sắp xếp, xuất ra Excel. Theo vai trò: Tester xem lỗi của mình, Developer xem lỗi được phân công, Manager xem tất cả.],
    [ZBUG_WS → Màn hình 0200],
  [2],
    [SmartForm Chi tiết Lỗi (PDF)],
    [Báo cáo PDF in được cho một lỗi được chọn. Bao gồm: Bug ID, Tiêu đề, Module, Ưu tiên, Trạng thái, Mức độ nghiêm trọng, Loại, Tester, Developer, ngày Tạo/Đóng, nhật ký lịch sử, ghi chú. Được kích hoạt bởi nút PRINT trên Màn hình 0200.],
    [ZBUG_WS → Màn hình 0200 → PRINT],
  [3],
    [Báo cáo ALV Danh sách Dự án],
    [Danh sách tất cả dự án mà người dùng hiện tại có thể truy cập. Hiển thị Project ID, Tên, Trạng thái, Manager, ngày Bắt đầu/Kết thúc, số lượng người dùng. Được lọc từ Màn hình 0410 (Tìm kiếm Dự án).],
    [ZBUG_WS → Màn hình 0400],
  [4],
    [Nhật ký Lịch sử Lỗi],
    [Dấu vết kiểm toán đầy đủ cho một lỗi. Hiển thị tất cả thay đổi trạng thái, phân công, tải lên, chỉnh sửa trường với dấu thời gian, người dùng, giá trị cũ, giá trị mới và lý do. ALV chỉ đọc trên Tab 0360 của Chi tiết Lỗi.],
    [ZBUG_WS → Màn hình 0300 → Tab Lịch sử],
  [5],
    [Kết quả Tìm kiếm Lỗi],
    [Báo cáo tìm kiếm đặc biệt trên tất cả lỗi trong một dự án. Hỗ trợ lọc đa trường (Bug ID, Tiêu đề, Trạng thái, Ưu tiên, Module, Tester, Developer). Đầu ra trên Màn hình 0220.],
    [ZBUG_WS → Màn hình 0200 → SEARCH],
  [6],
    [Thống kê Dashboard (chỉ Manager)],
    [Tiêu đề tóm tắt thời gian thực trên Màn hình 0200 hiển thị: Tổng lỗi, theo Trạng thái (New/Assigned/InProgress/Fixed/FinalTesting/Waiting/Resolved/Rejected), theo Ưu tiên (H/M/L), theo Module.],
    [ZBUG_WS → Màn hình 0200 (Manager)],
  [7],
    [Nhật ký Thông báo Email],
    [Email tự động gửi khi xảy ra sự kiện quan trọng: Tạo Lỗi, Phân công, Thay đổi Trạng thái, Từ chối, Đã giải quyết. Gửi qua API BCS SAP (CL_BCS). Xem được trong SOST.],
    [SOST (SAP chuẩn)],
  [8],
    [Tệp Bằng chứng (ZBUG_EVIDENCE)],
    [Tệp bằng chứng nhị phân được lưu trong bảng tùy chỉnh ZBUG_EVIDENCE. Ba loại theo lỗi: Bug_report.xlsx (Tester), fix_report.xlsx (Developer), confirm_report.xlsx (Final Tester). Có thể tải xuống từ tab Bằng chứng trên Màn hình 0300.],
    [ZBUG_WS → Màn hình 0300 → Tab Bằng chứng],
)
