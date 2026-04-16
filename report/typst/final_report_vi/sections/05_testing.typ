// ============================================================
// 05_testing.typ — V. Tài liệu Kiểm thử Phần mềm
// ============================================================
#import "../template.typ": placeholder, hline, field

= V. Tài liệu Kiểm thử Phần mềm

== 1. Phạm vi Kiểm thử

=== 1.1 Tính năng Mục tiêu Kiểm thử

Phạm vi kiểm thử bao gồm Hệ thống Quản lý Theo dõi Lỗi SAP (`ZBUG_WS` v5.0), triển khai dưới dạng chương trình Module Pool (`Z_BUG_WORKSPACE_MP`) trên SAP System S40, Client 324. Tất cả màn hình chức năng, quy tắc nghiệp vụ và kiểm soát truy cập theo vai trò đều nằm trong phạm vi.

*Tính năng trong phạm vi:*

#table(
  columns: (auto, 3.5cm, 1fr),
  align: (center, left, left),
  [*STT*], [*Khu vực Tính năng*], [*Mô tả*],
  [1], [Luồng Điều hướng], [Tất cả chuyển đổi màn hình-sang-màn hình qua ứng dụng 9 màn hình (0410 -- 0400 -- 0200 -- 0300 -- 0370)],
  [2], [Tìm kiếm Dự án (0410)], [Màn hình ban đầu mới: 3 trường lọc (Project ID, Manager, Status); hiển thị dự án theo vai trò],
  [3], [Danh sách Dự án (0400)], [ALV grid với thao tác CRUD; xóa mềm; tải xuống và tải lên mẫu Excel],
  [4], [Chi tiết Dự án (0500)], [Tạo/Thay đổi/Hiển thị dự án; phân công người dùng qua Table Control `TC_USERS`],
  [5], [Danh sách Lỗi + Dashboard (0200)], [ALV grid với dashboard thời gian thực; chế độ kép (Xem Dự án / Lỗi của tôi)],
  [6], [Chi tiết Lỗi (0300)], [Tab strip 6 tab (Bug Info, Description, Dev Note, Tester Note, Evidence, History); kiểm soát trường theo vai trò qua nhóm màn hình],
  [7], [Popup Chuyển trạng thái (0370)], [Vòng đời 10 trạng thái được thực thi qua popup; ma trận chuyển đổi theo vai trò; trường bắt buộc theo chuyển đổi],
  [8], [Engine Tự động Phân công], [Giai đoạn A: tự động phân công Developer khi tạo lỗi; Giai đoạn B: tự động phân công Tester khi chuyển sang Fixed],
  [9], [Tìm kiếm Lỗi (0210/0220)], [Popup nhập tìm kiếm (6 trường); kết quả toàn màn hình không có dashboard],
  [10], [Quản lý Bằng chứng], [Tải lên / Tải xuống / Xóa file bằng chứng; phát hiện MIME type; tự tăng `EVD_ID`],
  [11], [Thông báo Email], [Email BCS API đến Developer và Tester được phân công (loại trừ người dùng hiện tại)],
  [12], [Tải xuống Mẫu], [Mẫu SMW0: `Bug_report.xlsx`, `fix_report.xlsx`, `confirm_report.xlsx`],
  [13], [Kiểm soát Truy cập theo Vai trò], [3 vai trò (Manager, Developer, Tester); khả năng chỉnh sửa trường qua nhóm màn hình; hiển thị nút theo vai trò],
  [14], [Xác thực Trường và Quy tắc Nghiệp vụ], [Quy tắc nhất quán Severity/Priority; trường bắt buộc; phát hiện thay đổi chưa lưu; hành vi thông báo lỗi],
  [15], [F4 Search Help], [Trợ giúp dropdown trên tất cả trường khóa qua các màn hình 0300, 0410, 0370],
)

*Ngoài phạm vi:*

- Kiểm thử tải hiệu suất (kịch bản đồng thời nhiều người dùng)
- Kiểm thử thâm nhập bảo mật cấp mạng
- Cấu hình máy chủ SMTP bên ngoài (giả định đã cấu hình trước qua SOST)
- Đối tượng ủy quyền cấp SAP Basis (`S_TCODE`, `S_DEVELOP`)

=== 1.2 Cấp độ Kiểm thử

Kiểm thử được thực hiện ở bốn cấp độ:

+ *Kiểm thử Đơn vị* --- Các routine FORM và module PAI riêng lẻ được kiểm thử độc lập sử dụng SAP SE37 và SE38 (ví dụ: `auto_assign_developer`, `validate_status_transition`, `calculate_dashboard`).
+ *Kiểm thử Tích hợp* --- Các luồng điều hướng màn hình-sang-màn hình và tương tác đọc/ghi cơ sở dữ liệu được xác minh (ví dụ: vòng đời Custom Control: tạo trong PBO, giải phóng khi Back; refresh ALV sau thay đổi trạng thái).
+ *Kiểm thử Hệ thống* --- Các luồng làm việc đầu-cuối được thực thi dưới cả ba vai trò người dùng trên SAP client thực tế (QC test plan 20 suite).
+ *Kiểm thử Chấp thuận* --- Các kịch bản UAT happy-case hướng đến nghiệp vụ được xác thực bởi cả ba thành viên dự án.

=== 1.3 Ràng buộc và Giả định

- Tất cả kiểm thử thực thi trên SAP System S40, Client 324 (môi trường không phải sản xuất).
- Các tài khoản kiểm thử `DEV-089`, `DEV-061`, `DEV-118` phải có phân công vai trò đúng trong `ZBUG_USERS` trước khi kiểm thử (đã xác minh 11/04/2026).
- Kiểm thử tự động phân công (TC-09) yêu cầu thêm người dùng giả được tạo bởi report `Z_BUG_POPULATE_TESTDATA` (20 Developer + 10 Tester qua các module FI/MM/SD/ABAP).
- Script migration trạng thái (cũ `status = '6'` Resolved → mới `status = 'V'` Resolved) phải được thực thi trước khi kiểm thử hồi quy vòng đời v5.0 (TC-19.20).
- Triển khai v5.0 (màn hình, GUI Status, code ABAP đã cập nhật) phải hoàn tất trước khi chạy QC test đầy đủ.

== 2. Chiến lược Kiểm thử

=== 2.1 Các loại Kiểm thử

#table(
  columns: (auto, 3cm, 1fr, 2.5cm, 2.5cm),
  align: (center, left, left, left, left),
  [*STT*], [*Loại*], [*Mục tiêu*], [*Kỹ thuật*], [*Tiêu chí Hoàn thành*],
  [1], [Kiểm thử Chức năng], [Xác minh từng màn hình, nút và quy tắc nghiệp vụ hoạt động theo đặc tả yêu cầu], [Black-box: cung cấp đầu vào, xác minh đầu ra mong đợi; chuyển đổi giữa 3 tài khoản vai trò để kiểm thử RBAC], [Tất cả ca kiểm thử qua 20 TC suite đạt với không có lỗi nghiêm trọng (chặn)],
  [2], [Kiểm thử Hồi quy], [Xác nhận các tính năng v5.0 không gây tái phát các lỗi đã giải quyết trước đó], [Thực thi TC-19 (19 ca hồi quy) sau triển khai], [Tất cả 19 ca hồi quy đạt; không có lỗi nào tái xuất trong bản dựng v5.0],
  [3], [Kiểm thử Chấp thuận (UAT)], [Xác thực hệ thống triển khai đáp ứng yêu cầu luồng làm việc nghiệp vụ từ góc độ người dùng cuối], [Walkthrough happy-case bởi cả 3 vai trò theo script UAT (64 ca qua 14 danh mục)], [Tất cả 64 ca UAT đạt; không còn chặn nghiêm trọng; cả 3 thành viên vai trò ký xác nhận],
)

=== 2.2 Cấp độ Kiểm thử

#table(
  columns: (auto, 2.5cm, 1fr, 3cm),
  align: (center, left, left, left),
  [*STT*], [*Cấp độ*], [*Mô tả*], [*Loại Kiểm thử Áp dụng*],
  [1], [Đơn vị], [Các routine FORM riêng lẻ được kiểm thử độc lập --- `auto_assign_developer`, `validate_status_transition`, `calculate_dashboard`, `f4_trans_status`; thao tác đọc/ghi DB xác minh qua SE16N], [Chức năng],
  [2], [Tích hợp], [Luồng điều hướng màn hình xác minh đầu-cuối; vòng đời Custom Control (tạo/giải phóng); refresh ALV sau thay đổi dữ liệu; tính nhất quán DB sau chuyển đổi trạng thái], [Chức năng, Hồi quy],
  [3], [Hệ thống], [Các kịch bản đầu-cuối đầy đủ dưới cả 3 vai trò trên SAP S40/324; QC Test Plan 20 suite được thực thi có hệ thống bởi QC lead], [Chức năng, Hồi quy],
  [4], [Chấp thuận], [Kịch bản happy-case hướng nghiệp vụ: vòng đời dự án (Manager), báo cáo lỗi (Tester), giải quyết lỗi (Developer), chuyển đổi trạng thái qua vòng đời 10 trạng thái đầy đủ], [Chấp thuận (UAT)],
)

=== 2.3 Công cụ Hỗ trợ

#table(
  columns: (auto, 3.5cm, 1fr),
  align: (center, left, left),
  [*STT*], [*Công cụ*], [*Mục đích*],
  [1], [SAP SE38 / SE80], [Chỉnh sửa code ABAP, kiểm tra cú pháp và kích hoạt tất cả 6 include chương trình],
  [2], [SAP SE37], [Kiểm thử đơn vị các Function Module riêng lẻ: `READ_TEXT`, `SAVE_TEXT`, `F4IF_INT_TABLE_VALUE_REQUEST`, BCS email API],
  [3], [SAP SE16N], [Kiểm tra bảng cơ sở dữ liệu trực tiếp --- xác minh trạng thái DB sau mỗi thao tác Create/Update/Delete trên `ZBUG_TRACKER`, `ZBUG_HISTORY`, `ZBUG_EVIDENCE`],
  [4], [SAP SOST], [Xác minh hàng đợi email đi; xác nhận giao hàng email BCS API được xếp hàng cho người dùng được phân công],
  [5], [SAP SE51], [Xác minh layout màn hình; vị trí Custom Control; kiểm tra cú pháp flow logic cho tất cả 9 màn hình],
  [6], [SAP SE41], [Kiểm tra GUI Status và Title Bar; phân công fcode; xác thực hiển thị nút],
  [7], [SAP SE93], [Xác minh T-code `ZBUG_WS` màn hình ban đầu được đặt thành 0410 (yêu cầu v5.0)],
  [8], [SAP SM50 / SM04], [Giám sát phiên và tiến trình trong kiểm thử stress chuyển tab nhiều lần (TC-07.15, TC-20.07)],
)

== 3. Kế hoạch Kiểm thử

=== 3.1 Nhân lực

#table(
  columns: (auto, 2cm, 2.5cm, 1fr),
  align: (center, left, left, left),
  [*STT*], [*Tài khoản*], [*Vai trò*], [*Trách nhiệm Kiểm thử*],
  [1], [`DEV-118`], [QC Lead / Tester], [Người thực hiện kiểm thử chính cho tất cả 20 TC suite; báo cáo lỗi kèm ảnh chụp màn hình; xác thực hành vi v5.0 với vai trò Tester (tạo lỗi, tải lên bằng chứng, chuyển đổi Final Testing)],
  [2], [`DEV-089`], [Manager], [Đồng kiểm thử cho ca kiểm thử vai trò Manager: TC-02 (Tìm kiếm Dự án), TC-03/04 (Project CRUD), TC-08 chuyển đổi Manager, TC-15 RBAC; xác thực quy tắc hoàn thành vòng đời dự án],
  [3], [`DEV-061`], [Developer], [Đồng kiểm thử cho ca kiểm thử vai trò Developer: TC-08 chuyển đổi Dev (Assigned → In Progress → Fixed), TC-09 Auto-Assign, TC-12 Evidence (Upload Fix, Download)],
)

=== 3.2 Môi trường Kiểm thử

#table(
  columns: (auto, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*STT*], [*Thành phần*], [*Chi tiết*], [*Trạng thái*],
  [1], [Hệ thống SAP], [S40 --- hệ thống phát triển và kiểm thử nội bộ chuyên dụng], [Sẵn sàng],
  [2], [SAP Client], [324 (test client; Table Maintenance Generator khả dụng qua SM30)], [Sẵn sàng],
  [3], [Phiên bản ABAP], [7.70 (SAP_BASIS 770) --- hỗ trợ khai báo inline, biểu thức SWITCH, biến host @, chuỗi mẫu], [Đã xác minh],
  [4], [Gói Phát triển], [`ZBUGTRACK` --- chứa tất cả đối tượng chương trình (màn hình, include, GUI Status)], [Đang hoạt động],
  [5], [Mạng], [Mạng nội bộ EBS_SAP], [Sẵn sàng],
  [6], [Tài khoản Kiểm thử], [`DEV-089` (Manager), `DEV-061` (Developer), `DEV-118` (Tester) --- vai trò đã xác minh trong `ZBUG_USERS` ngày 11/04/2026], [Đã xác minh],
  [7], [Dữ liệu kiểm thử Auto-Assign], [20 Developer giả + 10 Tester giả qua các module FI/MM/SD/ABAP; tạo bởi report `Z_BUG_POPULATE_TESTDATA`; phân công vào dự án kiểm thử qua `ZBUG_USER_PROJEC`], [Chờ xử lý],
  [8], [Mẫu SMW0], [3 mẫu Excel đã tải lên: `ZBT_TMPL_01` (Bug_report.xlsx), `ZBT_TMPL_02` (fix_report.xlsx), `ZBT_TMPL_03` (confirm_report.xlsx)], [Chờ xử lý],
)

=== 3.3 Các Mốc Kiểm thử

#table(
  columns: (auto, 3.5cm, 2cm, 2cm, 1fr),
  align: (center, left, center, center, left),
  [*STT*], [*Mốc*], [*Ngày bắt đầu*], [*Ngày kết thúc*], [*Kết quả*],
  [1], [Thiết lập Môi trường Kiểm thử], [01/04/2026], [11/04/2026], [Phân công vai trò `ZBUG_USERS` đã xác minh; tài khoản kiểm thử đã xác nhận; ảnh chụp màn hình SE16N đã chụp],
  [2], [UAT Vòng 1], [11/04/2026], [13/04/2026], [64 ca UAT happy case đã thực thi; 11 lỗi được xác định và ghi lại],
  [3], [Phân tích & Thiết kế Lỗi v5.0], [13/04/2026], [14/04/2026], [Phân tích nguyên nhân gốc và đề xuất sửa lỗi cho tất cả 11 lỗi UAT; kiến trúc v5.0 Giai đoạn F đã hoàn thiện],
  [4], [Phát triển Code v5.0 (F10)], [14/04/2026], [16/04/2026], [Tất cả 6 include ABAP (`Z_BUG_WS_TOP` đến `Z_BUG_WS_F02`) đã cập nhật lên v5.0; xác minh hoàn tất ngày 16/04/2026],
  [5], [Triển khai v5.0 lên SAP (F11--F17)], [Sau 16/04/2026], [TBD], [4 màn hình mới (SE51), 4 GUI Status + 4 Title Bar (SE41), cập nhật màn hình ban đầu SE93, bảng `ZBUG_EVIDENCE`, script migration, mẫu SMW0],
  [6], [Chạy QC Test Đầy đủ --- 20 Suite], [Sau triển khai], [TBD], [Khoảng 210 ca kiểm thử được thực thi; báo cáo lỗi; thống kê đạt/thất bại theo suite],
  [7], [UAT Vòng 2 (bản dựng v5.0)], [Sau QC Run], [TBD], [64 ca UAT happy case thực thi lại trên hệ thống v5.0 đã triển khai; cả 3 thành viên ký xác nhận; chấp thuận cuối cùng],
)

== 4. Ca Kiểm thử

Ca kiểm thử được tổ chức thành 20 suite (TC-01 đến TC-20), tổng cộng khoảng 210 ca riêng lẻ. Các bước ca kiểm thử chi tiết và kết quả mong đợi được duy trì trong tài liệu QC Test Plan. Các ca UAT happy case (64 ca qua 14 danh mục luồng làm việc, A--N) được ghi lại trong UAT Happy Case Script.

*Tóm tắt Suite Kiểm thử:*

#table(
  columns: (auto, 2cm, 3.5cm, 1fr, 1.5cm),
  align: (center, center, left, left, center),
  [*STT*], [*TC ID*], [*Tên Suite*], [*Phạm vi*], [*Số ca*],
  [1], [TC-01], [Luồng Điều hướng], [Tất cả chuyển đổi màn hình: 0410→0400→0200→0300→0370; Back/Exit/Cancel từ mọi màn hình], [20],
  [2], [TC-02], [Màn hình 0410 -- Tìm kiếm Dự án], [Lọc theo Project ID / Manager / Status; hiển thị dự án theo vai trò; F4 help trên 3 trường], [14],
  [3], [TC-03], [Màn hình 0400 -- Danh sách Dự án], [Hiển thị ALV; Project CRUD; xóa mềm; Refresh; hạn chế non-Manager], [12],
  [4], [TC-04], [Màn hình 0500 -- Chi tiết Dự án], [Tạo/Thay đổi/Hiển thị; Table Control phân công người dùng; F4 lịch; chặn non-Manager], [25],
  [5], [TC-05], [Màn hình 0200 -- Danh sách Lỗi + Dashboard], [Chế độ kép (Dự án / Lỗi của tôi); độ chính xác dashboard; Bug CRUD; tô màu hàng ALV], [18],
  [6], [TC-06], [Màn hình 0300 -- Chi tiết Lỗi], [Tạo/Thay đổi/Hiển thị; STATUS luôn khóa; ánh xạ text hiển thị cho tất cả 10 trạng thái], [18],
  [7], [TC-07], [Tab Strip và Màn hình con], [Tất cả 6 tab; duy trì dữ liệu khi chuyển tab; trình soạn thảo chỉ đọc theo vai trò; ngăn crash], [15],
  [8], [TC-08], [Chuyển trạng thái (10 Trạng thái + Popup 0370)], [Tất cả chuyển đổi hợp lệ; chuyển đổi bị chặn/không hợp lệ; trường bắt buộc theo chuyển đổi; ghi log lịch sử], [30],
  [9], [TC-09], [Hệ thống Tự động Phân công], [Giai đoạn A (Developer): khớp module + workload < 5; Giai đoạn B (Tester): cùng logic khi chuyển sang Fixed], [9],
  [10], [TC-10], [Tìm kiếm Lỗi (Màn hình 0210/0220)], [Tất cả 6 trường tìm kiếm; wildcard tiêu đề; bộ lọc kết hợp; ALV kết quả; điều hướng back], [15],
  [11], [TC-11], [Dashboard Metrics], [Độ chính xác đếm theo trạng thái / ưu tiên; xác thực tổng (tổng trạng thái = Tổng); refresh thời gian thực], [12],
  [12], [TC-12], [Quản lý Bằng chứng], [Tải lên (chung / báo cáo / sửa lỗi); tải xuống; xóa; phát hiện MIME; tự tăng `EVD_ID`; popup tải lên], [12],
  [13], [TC-13], [Thông báo Email], [Gửi BCS API; xử lý không có người nhận; loại trừ người dùng hiện tại khỏi danh sách nhận; xác minh SOST], [4],
  [14], [TC-14], [Tải xuống và Tải lên Mẫu], [3 lượt tải mẫu SMW0; tải lên dự án Excel; xử lý bản ghi trùng/không hợp lệ], [11],
  [15], [TC-15], [Kiểm soát Truy cập theo Vai trò], [Khả năng chỉnh sửa trường theo vai trò (nhóm FNC/DEV/TST); hiển thị nút theo vai trò (Create/Delete/Upload)], [16],
  [16], [TC-16], [Xác thực Trường và Quy tắc Nghiệp vụ], [Quy tắc nhất quán Severity/Priority; trường bắt buộc; duy trì long text; thông báo lỗi không khóa trường], [9],
  [17], [TC-17], [Phát hiện Thay đổi Chưa lưu], [Popup Lưu/Hủy/Cancel; so sánh snapshot; đồng bộ văn bản trình soạn thảo mini trước khi so sánh], [9],
  [18], [TC-18], [F4 Search Help], [Tất cả F4 helper trên màn hình 0300 (9 trường), 0410 (3 trường), 0370 (3 trường); điền lại giá trị], [16],
  [19], [TC-19], [Hồi quy -- Xác minh không tái phát], [19 ca kiểm thử hồi quy: xác minh không tái xuất sau triển khai v5.0], [19],
  [20], [TC-20], [Trường hợp Biên và Kiểm thử Ranh giới], [DB trống; trường độ dài tối đa; tải lên file lớn; memory leak khi Back; xử lý người dùng chưa đăng ký], [20],
  [], [], [*Tổng cộng (ước tính)*], [], [*~210*],
)

== 5. Báo cáo Kiểm thử

=== 5.1 UAT Vòng 1 --- Kết quả Giai đoạn E (11--13 tháng 4 năm 2026)

UAT Vòng 1 được thực hiện trong Giai đoạn E trên SAP System S40, Client 324. Cả ba thành viên dự án tham gia theo vai trò được chỉ định của mình, theo script UAT happy-case (64 ca qua 14 danh mục).

*Tóm tắt:*

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr),
  align: center,
  [*Tổng ca*], [*Đạt*], [*Thất bại*], [*Bị chặn*], [*Lỗi tìm thấy*],
  [64], [53], [11], [0], [11],
)

*Các Lỗi Tìm thấy trong UAT Vòng 1:*

#table(
  columns: (auto, auto, 1fr, 2.5cm),
  align: (center, center, left, center),
  [*STT*], [*Bug ID*], [*Mô tả Lỗi*], [*Mức độ nghiêm trọng*],
  [1], [UAT-01], [Chuyển tab giữa các tab Description/Dev Note/Tester Note kích hoạt short dump `CALL_FUNCTION_CONFLICT_TYPE` (Custom Control không được giải phóng trước khi tái tạo)], [Nghiêm trọng],
  [2], [UAT-02], [`DESC_TEXT` (kiểu STRING) đặt trên layout màn hình 0310 gây lỗi render màn hình -- Trường STRING không được hỗ trợ trên layout Dynpro], [Cao],
  [3], [UAT-03], [Tab Bug Info (0310) thiếu các trường: `SAP_MODULE`, `DEV_ID`, `VERIFY_TESTER_ID`, `ATT_REPORT`, `ATT_FIX` -- chưa đặt trên layout màn hình], [Cao],
  [4], [UAT-04], [Nút Remove User xóa mà không kiểm tra hàng hiện được chọn trong Table Control `TC_USERS` -- xóa sai hàng hoặc không xóa hàng nào], [Trung bình],
  [5], [UAT-05], [Tạo Lỗi: giá trị mặc định không đúng; F4 help trên trường `SAP_MODULE` chưa đăng ký; mô tả bị mất sau khi lưu và mở lại], [Cao],
  [6], [UAT-06], [F4 help trên trường `SAP_MODULE` không hiển thị popup -- thiếu entry flow logic POV cho trường đó trên màn hình 0310], [Trung bình],
  [7], [UAT-07], [Thông báo lỗi validation sử dụng `TYPE 'E'` khóa tất cả trường màn hình -- người dùng không thể sửa đầu vào mà không điều hướng đi], [Cao],
  [8], [UAT-08], [Văn bản mô tả biến mất sau khi mở lại lỗi đã lưu -- long text không được tải lại đúng trong PBO khi lỗi được mở lại], [Cao],
  [9], [UAT-09], [Cho phép chuyển đổi trạng thái ngược (ví dụ: Fixed → In Progress) -- không có ma trận chuyển đổi được thực thi], [Nghiêm trọng],
  [10], [UAT-10], [Không kiểm tra file bằng chứng trước khi đánh dấu lỗi là Fixed -- chuyển đổi tiến hành ngay cả khi `ZBUG_EVIDENCE` trống], [Cao],
  [11], [UAT-11], [Manager có thể bypass ma trận chuyển đổi -- gán trạng thái trực tiếp trong `save_bug_detail` ghi đè bất kỳ trạng thái nào mà không cần xác thực], [Nghiêm trọng],
)

*Giải quyết:* Tất cả 11 lỗi được phân tích nguyên nhân gốc và giải quyết trong Giai đoạn F v5.0. Các bản sửa được tích hợp vào 6 include ABAP (`Z_BUG_WS_TOP` đến `Z_BUG_WS_F02`), tất cả đã cập nhật lên v5.0 (F10 HOÀN TẤT ngày 16/04/2026). Xác minh UAT Vòng 2 được lên lịch sau khi triển khai Giai đoạn F (Bước F11--F17).

=== 5.2 Chạy QC Test Đầy đủ --- Giai đoạn F (Đã lên kế hoạch)

QC test plan đầy đủ 20 suite (~210 ca) được lên lịch cho Giai đoạn F, Bước F14, sau khi triển khai thành công tất cả các thành phần v5.0 lên SAP System S40. Thứ tự thực thi ưu tiên: TC-19 (Hồi quy) → TC-01 (Điều hướng) → TC-08 (Chuyển trạng thái) → TC-09 (Auto-Assign) → TC-06 (Chi tiết Lỗi) → TC-15 (RBAC) → TC-11 (Dashboard) → TC-10 (Tìm kiếm Lỗi) → TC-02 (Tìm kiếm Dự án) → các suite còn lại.

*Số liệu mục tiêu để hoàn thành QC:*

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr),
  align: center,
  [*Tổng TC*], [*Mục tiêu Đạt*], [*Thất bại Tối đa*], [*Bị chặn*], [*Tỷ lệ Đạt Mục tiêu*],
  [~210], [>= 200], [< 10], [0], [>= 95%],
)
