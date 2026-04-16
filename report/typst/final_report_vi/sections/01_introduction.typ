// ============================================================
// 01_introduction.typ — I. Giới thiệu Dự án
// ============================================================
#import "../template.typ": placeholder, hline, field

= I. Giới thiệu Dự án

== 1. Tổng quan

=== 1.1 Thông tin Dự án

#table(
  columns: (4cm, 1fr),
  align: (right, left),
  [*Tên dự án*],   [SAP Bug Tracking Management System],
  [*Mã dự án*],    [`ZBUG_WS`],
  [*Chương trình*],[`Z_BUG_WORKSPACE_MP` (Module Pool, Type M)],
  [*Gói SAP*],     [`ZBUGTRACK`],
  [*Hệ thống SAP*],[S40 \| Client 324 \| ABAP 7.70],
  [*T-code*],      [`ZBUG_WS`],
  [*Nhóm*],        [Nhóm ZBUG],
  [*Phiên bản*],   [v5.0 (Giai đoạn F — Nâng cao)],
  [*Ngày báo cáo*],[Tháng 4 năm 2026],
)

=== 1.2 Nhóm Dự án

#table(
  columns: (2.5cm, 3cm, 2cm, 1fr),
  align: (center, left, center, left),
  [*Tài khoản*], [*Họ tên*], [*Vai trò SAP*], [*Trách nhiệm Dự án*],
  [`DEV-089`], [Hoàng Anh], [Manager],   [Thiết kế CSDL, logic ABAP lõi (Z\_BUG\_WS\_F01), tài liệu và triển khai],
  [`DEV-242`], [Linh],      [Developer], [Màn hình Bug Detail (0300), FM Z\_BUG\_CREATE / Z\_BUG\_LOG\_HISTORY, các routine hỗ trợ (Z\_BUG\_WS\_F02)],
  [`DEV-061`], [Hiếu],      [Developer], [Bug List + Dashboard (Màn hình 0200), Bug Search (0210/0220), ALV infrastructure, include PAI],
  [`DEV-118`], [Ka],        [Tester],    [Email (Z\_BUG\_SEND\_EMAIL), upload bằng chứng, SmartForms, QC Test Plan, thực thi UAT],
  [`DEV-237`], [Đức],       [Developer], [Vòng đời trạng thái + Popup (0370), Auto-Assign engine, màn hình Quản lý Dự án (0400/0410/0500)],
)

== 2. Bối cảnh Sản phẩm

Việc triển khai SAP ERP liên quan đến phát triển đồng thời trên nhiều module (MM, SD, FI, CO, v.v.). Khi không có công cụ theo dõi tập trung và có cấu trúc, các báo cáo lỗi bị phân tán qua bảng tính, email và tin nhắn tức thời. Điều này gây khó khăn trong việc đảm bảo trách nhiệm, theo dõi phân công khối lượng công việc hoặc duy trì lịch sử thay đổi có thể kiểm toán.

Dự án này được Đại học FPT khởi xướng nhằm xây dựng một *hệ thống theo dõi lỗi tập trung* chạy ngay bên trong SAP, truy cập qua một T-code duy nhất (`ZBUG_WS`). Hệ thống được phát triển trên hệ thống SAP S40 (Client 324) sử dụng ABAP 7.70, từ tháng 3 đến tháng 4 năm 2026, qua sáu giai đoạn có cấu trúc (A đến F).

Phiên bản v5.0 (Giai đoạn F) đã giới thiệu các cải tiến lớn so với phiên bản v4.2 ban đầu:
- Vòng đời lỗi 10 trạng thái thay thế mô hình 9 trạng thái trước đó
- Popup chuyển đổi trạng thái chuyên dụng (Màn hình 0370) thực thi quy tắc chuyển đổi theo vai trò
- Engine tự động phân công cho cả lập trình viên và kiểm thử viên (dựa trên khối lượng công việc và module SAP)
- Engine tìm kiếm lỗi với bộ lọc đa trường (Màn hình 0210/0220)
- Header dashboard theo thời gian thực trên màn hình danh sách lỗi

== 3. Giải pháp Hiện có

Hệ thống tham chiếu `ZPG_BUGTRACKING_MAIN` / `ZPG_BUGTRACKING_DETAIL` cung cấp danh sách lỗi và màn hình chi tiết cơ bản sử dụng chương trình ABAP dạng executable. Mặc dù minh họa được khái niệm cốt lõi, nhưng nó có những khoảng cách đáng kể so với `ZBUG_WS`:

#table(
  columns: (1fr, 2.5cm, 2cm),
  align: (left, center, center),
  [*Tính năng*], [*ZPG Tham chiếu*], [*ZBUG\_WS*],
  [Kiến trúc Module Pool (Type M)], [Không],  [Có],
  [Tự động phân công dev theo module/khối lượng], [Không],  [Có],
  [Hệ thống phân quyền tập trung (dạng FM)], [Không],  [Có],
  [Lịch sử kiểm toán đầy đủ (`ZBUG_HISTORY`)],  [Không],  [Có],
  [Thông báo email qua CL\_BCS],           [Không],  [Có],
  [Xuất PDF SmartForm],               [Không],  [Có],
  [Module quản lý dự án],                [Không],  [Có],
  [Vòng đời 10 trạng thái với popup chuyển đổi], [Không],  [Có (v5.0)],
  [Header dashboard (Màn hình 0200)],   [Không],  [Có (v5.0)],
  [Engine tìm kiếm lỗi (Màn hình 0210/0220)],     [Không],  [Có (v5.0)],
)

== 4. Cơ hội Kinh doanh

Các nhóm phát triển SAP trong các tổ chức lớn đang đối mặt với một khoảng trống nghiêm trọng: không có công cụ tích hợp nào để theo dõi lỗi được phân công cho từng lập trình viên, với khả năng hiển thị theo vai trò và thực thi quy trình làm việc. Sự thiếu hụt này dẫn đến:

- Lỗi bị bỏ sót, trùng lặp hoặc theo dõi không chính thức bên ngoài hệ thống
- Lập trình viên nhận phân công không rõ ràng về mức độ ưu tiên hay ngữ cảnh module
- Quản lý không thể xem phân phối khối lượng công việc theo thời gian thực hay tình trạng dự án
- Không có bằng chứng có cấu trúc về báo cáo lỗi, xác nhận sửa lỗi hay kiểm chứng kiểm thử

`ZBUG_WS` giải quyết tất cả những vấn đề này bằng cách cung cấp hệ thống *không phụ thuộc ngoài* được nhúng trực tiếp vào SAP. Tất cả dữ liệu được lưu trong bảng ABAP (`ZBUG_TRACKER`, `ZBUG_PROJECT`, v.v.), tất cả thông báo sử dụng email tích hợp SAP (SCOT / CL\_BCS), và tất cả UI là SAP GUI nguyên bản (Module Pool). Không cần giấy phép, cơ sở hạ tầng hay tích hợp bổ sung.

Điều này giúp hệ thống có thể triển khai ngay lập tức trên bất kỳ môi trường SAP ECC hay S/4HANA nào hỗ trợ ABAP 7.70+.

== 5. Tầm nhìn Sản phẩm Phần mềm

_Dành cho các nhóm phát triển SAP cần quản lý lỗi có cấu trúc, `ZBUG_WS` là ứng dụng Module Pool cung cấp theo dõi lỗi đầu-cuối với kiểm soát truy cập theo vai trò, phân công tự động và nhật ký kiểm toán bất biến. Không giống như công cụ dạng bảng tính hay hệ thống bên ngoài, `ZBUG_WS` chạy nguyên bản trên nền tảng SAP, không cần giấy phép bổ sung, và thực thi quy tắc quy trình làm việc mà không vai trò nào có thể bỏ qua._

Các kết quả chính đạt được:
- Mỗi lỗi tuân theo vòng đời 10 trạng thái được định nghĩa; chuyển đổi được thực thi theo vai trò qua popup (Màn hình 0370)
- Engine tự động phân công chọn lập trình viên có khối lượng công việc thấp nhất trong module SAP đúng
- Tất cả thay đổi trạng thái, phân công và tải lên bằng chứng được ghi vào `ZBUG_HISTORY`
- Quản lý thấy số liệu thời gian thực (theo trạng thái, ưu tiên, module) trên mọi màn hình danh sách lỗi
- Ba mẫu bằng chứng (Báo cáo Lỗi, Báo cáo Sửa lỗi, Báo cáo Xác nhận) có thể tải từ SMW0 và tải lên trực tiếp từ màn hình chi tiết lỗi

== 6. Phạm vi & Giới hạn Dự án

=== Trong phạm vi

- *Quản lý vòng đời lỗi:* Vòng đời 10 trạng thái (Mới, Chờ, Đã phân công, Đang xử lý, Tạm dừng, Đã sửa, Kiểm tra cuối, Đã giải quyết, Từ chối, Đóng-legacy) với quy tắc chuyển đổi theo vai trò
- *Quản lý dự án:* Tạo / Sửa / Xóa dự án, phân công người dùng vào dự án với vai trò theo dự án
- *Kiểm soát truy cập theo vai trò:* Manager / Developer / Tester, thực thi qua nhóm màn hình SAP (`EDT`, `FNC`, `TST`, `DEV`, `STS`, `BID`, `PRJ`)
- *Hệ thống tự động phân công:* phân công lập trình viên khi tạo lỗi (Giai đoạn A), phân công kiểm thử viên khi hoàn thành sửa lỗi (Giai đoạn B)
- *Quản lý bằng chứng:* tải lên / tải xuống ba file dựa trên mẫu cho mỗi lỗi (bảng `ZBUG_EVIDENCE`)
- *Thông báo email:* gửi tự động qua CL\_BCS khi tạo, phân công, thay đổi trạng thái và từ chối
- *Tìm kiếm lỗi:* bộ lọc đa trường theo Bug ID, Tiêu đề, Trạng thái, Ưu tiên, Module, Khoảng ngày (Màn hình 0210/0220)
- *Header dashboard:* số liệu đếm theo thời gian thực trên Màn hình 0200 nhóm theo trạng thái, ưu tiên, module
- *Nhật ký kiểm toán:* tất cả thay đổi được ghi vào `ZBUG_HISTORY` với giá trị cũ/mới và ghi chú lý do bắt buộc

=== Ngoài phạm vi

- Tích hợp với công cụ bên ngoài (Jira, ServiceNow, Bugzilla, v.v.)
- Giao diện web hoặc mobile — chỉ SAP GUI (Dynpro)
- Framework thực thi kiểm thử tự động
- Đồng bộ hóa đa client hoặc đa hệ thống
- Báo cáo BI/phân tích (BW, Fiori, v.v.)

=== Ràng buộc & Hạn chế

  - Phát triển và kiểm thử giới hạn trong hệ thống SAP S40, Client 324
  - Cú pháp ABAP 7.70 bắt buộc (khai báo inline, biểu thức `SWITCH`, chuỗi mẫu, biến host `@`)
  - Ba tài khoản demo SAP dùng để kiểm thử hệ thống: `DEV-089` (vai trò Manager), `DEV-061` (vai trò Developer), `DEV-118` (vai trò Tester)
  - File bằng chứng phải ở định dạng `.xlsx`, tối đa 10 MB mỗi file
  - Màn hình 0100 đã bị loại bỏ (v5.0); điểm vào là Màn hình 0410 (Tìm kiếm Dự án)
