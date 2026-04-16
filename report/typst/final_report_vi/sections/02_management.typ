// ============================================================
// 02_management.typ — II. Kế hoạch Quản lý Dự án
// ============================================================
#import "../template.typ": placeholder, hline, field

= II. Kế hoạch Quản lý Dự án

== 1. Tổng quan

=== 1.1 Phạm vi & Ước tính

Bảng dưới đây phân loại từng chức năng phần mềm chính theo độ phức tạp và ước tính nỗ lực phát triển tính bằng ngày-người.

#table(
  columns: (auto, 3cm, 1fr, 2cm, 2cm, 2cm, 2.5cm),
  align: (center, left, left, center, center, center, center),
  [*STT*], [*Tính năng*], [*Mô tả*], [*Đơn giản*], [*Trung bình*], [*Phức tạp*], [*Tổng (Ngày-người)*],
  [1],  [Cơ sở CSDL],           [Miền, phần tử dữ liệu, bảng (5 bảng, 77 trường), dải số],  [],   [],   [1], [3],
  [2],  [Function Module],       [`Z_BUG_CREATE`, `Z_BUG_AUTO_ASSIGN`, `Z_BUG_CHECK_PERMISSION`, `Z_BUG_LOG_HISTORY`, `Z_BUG_SEND_EMAIL`], [], [], [1], [5],
  [3],  [Giao diện Module Pool], [Chương trình `Z_BUG_WORKSPACE_MP` + 6 include, 12 màn hình, GUI Status], [],   [1],  [],  [4],
  [4],  [Danh sách Lỗi (Màn hình 0200)], [ALV Grid, toolbar, bộ lọc theo vai trò, Dashboard Header (v5.0)], [],   [1],  [],  [3],
  [5],  [Chi tiết Lỗi (Màn hình 0300)],[Tab Strip (6 tab), trình soạn thảo long text, ALV bằng chứng, ALV lịch sử], [],   [],   [1], [4],
  [6],  [Popup Chuyển trạng thái],[Màn hình 0370, vòng đời 10 trạng thái, ma trận trường theo vai trò], [],   [],   [1], [3],
  [7],  [Quản lý Dự án],         [Màn hình 0400/0410/0500, CRUD dự án, phân công người dùng vào dự án], [],   [1],  [],  [3],
  [8],  [Engine Tự động Phân công], [Giai đoạn A (Mới→Đã phân công) + Giai đoạn B (Đã sửa→Kiểm tra cuối), tính toán khối lượng], [],   [],   [1], [3],
  [9],  [Engine Tìm kiếm Lỗi],   [Màn hình 0210/0220, bộ lọc đa trường, kết quả ALV],   [],   [1],  [],  [2],
  [10], [Email & Bằng chứng],    [Email CL\_BCS, tải lên/tải xuống `ZBUG_EVIDENCE`, mẫu (SMW0)],      [],   [1],  [],  [2],
  [11], [Kiểm thử & Sửa lỗi],   [QC Test Plan (140 ca), UAT (43 ca), 11 lỗi UAT sửa (v5.0)],    [1],  [],   [],  [3],
  [],   [*TỔNG CỘNG*],           [],                                                     [*1*],[*5*],[*5*],[*35 Ngày-người*],
)

=== 1.2 Mục tiêu Dự án

*Mục tiêu tổng thể:* Xây dựng một hệ thống theo dõi lỗi theo vai trò sẵn sàng sản xuất, chạy nguyên bản trên SAP, vượt trội hơn hệ thống tham chiếu (`ZPG_BUGTRACKING_*`) trên tất cả các khía cạnh.

*Các mục tiêu cụ thể:*

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Chất lượng*],           [Tất cả 140+ ca kiểm thử QC được thực hiện; tỷ lệ đạt ≥ 90% tại UAT Vòng 2],
  [*Chức năng*],     [Vòng đời 10 trạng thái được thực thi theo vai trò; tỷ lệ thành công tự động phân công 100% khi có lập trình viên/kiểm thử viên đủ điều kiện],
  [*Hiệu suất*],       [Màn hình ALV tải trong vòng 3 giây trên S40; không timeout khi tải bằng chứng ≤ 10 MB],
  [*Phân bổ nỗ lực*],[Yêu cầu 10% \| Thiết kế 15% \| Lập trình 45% \| Kiểm thử 20% \| Quản lý dự án 10%],
)

=== 1.3 Rủi ro Dự án

#table(
  columns: (auto, 2.5cm, 1fr, 2cm, 2cm, 3cm),
  align: (center, left, left, center, center, left),
  [*STT*], [*Rủi ro*], [*Mô tả*], [*Xác suất*], [*Tác động*], [*Giảm thiểu*],
  [1], [Hệ thống SAP ngừng hoạt động], [S40 không khả dụng trong các khung thời gian phát triển/kiểm thử], [Thấp], [Cao],   [Lên lịch công việc quan trọng vào giờ thấp điểm; dùng SE38 chỉnh sửa offline],
  [2], [Thay đổi phá vỡ: trạng thái `6`],[v5.0 định nghĩa lại trạng thái `6` từ Resolved → Final Testing; cần migration], [Cao], [Cao], [Viết script migration; chỉ chạy sau khi v5.0 triển khai hoàn toàn],
  [3], [`ZBUG_EVIDENCE` chưa tạo], [Bảng có thể chưa tồn tại trong SAP DB; chặn tính năng tải lên bằng chứng], [Trung bình], [Cao], [Tạo bảng trong SE11 trước khi chạy ca kiểm thử TC-12],
  [4], [SCOT email chưa cấu hình], [Gửi email CL\_BCS thất bại im lặng nếu SMTP chưa thiết lập trong SCOT], [Trung bình], [Trung bình], [Kiểm tra SOST sau mỗi kiểm thử kích hoạt email; ghi nhận là hạn chế đã biết],
  [5], [Tự động phân công: không có dev đủ điều kiện],[Nếu không có Developer có workload < 5 trong module đúng, lỗi → Waiting], [Thấp], [Trung bình], [Chèn 30 người dùng giả vào `ZBUG_USERS` / `ZBUG_USER_PROJEC` để kiểm thử],
  [6], [Triển khai Giai đoạn F chưa hoàn tất], [Màn hình mới (0410/0370/0210/0220) và GUI Status chưa tạo trong SAP], [Cao], [Cao], [Làm theo Hướng dẫn Nâng cao Giai đoạn F từng bước (F11--F17)],
)

== 2. Phương pháp Quản lý

=== 2.1 Quy trình Dự án

Dự án tuân theo mô hình *incremental waterfall* chia thành sáu giai đoạn, mỗi giai đoạn xây dựng dựa trên giai đoạn trước:

#table(
  columns: (1.5cm, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*Giai đoạn*], [*Tên*], [*Kết quả*], [*Trạng thái*],
  [A], [Cơ sở CSDL],              [5 bảng tùy chỉnh, miền, phần tử dữ liệu, dải số (`ZNRO_BUG`)], [Hoàn thành],
  [B], [Logic nghiệp vụ (FM)],    [6 Function Module: Create, AutoAssign, Permission, History, Email, Evidence], [Hoàn thành],
  [C], [Giao diện Module Pool],   [Chương trình `Z_BUG_WORKSPACE_MP`, 8 màn hình, GUI Status, ALV grids, tab strips], [Hoàn thành],
  [D], [Tính năng nâng cao],      [SmartForms, tải lên/xuống Excel, lớp message, F4 helpers, phát hiện thay đổi chưa lưu], [Hoàn thành],
  [E], [Kiểm thử],                [QC Test Plan (140 ca), UAT (43 ca), kết quả UAT Vòng 1 (11 lỗi tìm thấy)], [Hoàn thành],
  [F], [Nâng cao v5.0],           [Vòng đời 10 trạng thái, Màn hình 0370/0410/0210/0220, tự động phân công nâng cao, tìm kiếm lỗi, dashboard], [CODE xong; triển khai chờ],
)

=== 2.2 Quản lý Chất lượng

- *Review code:* Mỗi include (`Z_BUG_WS_TOP`, `_F00`, `_PBO`, `_PAI`, `_F01`, `_F02`) được review theo hướng dẫn layout màn hình trong `screens/` trước khi kích hoạt trong SAP
- *Phân tích tĩnh:* Kiểm tra cú pháp SAP (SE38 Activate) và kiểm tra chương trình mở rộng (Program → Check → Extended) chạy trên mọi thay đổi code
- *Kiểm thử theo hướng xác minh:* Tất cả 140 ca kiểm thử QC trong QC Test Plan được thực hiện trước mỗi vòng UAT
- *Tính nhất quán kiểm toán:* `ZBUG_HISTORY` được kiểm tra sau mỗi kiểm thử thay đổi trạng thái để xác minh mục log
- *Kiểm tra thay đổi phá vỡ:* Tham chiếu hằng số trạng thái (`gc_st_resolved = 'V'`, `gc_st_finaltesting = '6'`) được xác minh theo Đặc tả Vòng đời Trạng thái sau thay đổi code v5.0

=== 2.3 Kế hoạch Đào tạo

Không cần đào tạo chính thức — tất cả thành viên đã có kiến thức SAP ABAP trước đó. Các khoảng cách kiến thức cụ thể được giải quyết như sau:

#table(
  columns: (3.5cm, 1fr, 2cm),
  align: (left, left, center),
  [*Chủ đề*], [*Tài nguyên*], [*Thành viên*],
  [ALV Grid / Custom Container],    [SAP Help + chương trình tham chiếu `ZPG_BUGTRACKING_MAIN`],    [`DEV-061`],
  [SmartForms / CL\_BCS],           [SAP Help + hướng dẫn cấu hình SCOT],                          [`DEV-118`],
  [Module Pool / Screen Painter],   [Trợ giúp tích hợp SE51 + hướng dẫn layout màn hình dự án],   [Tất cả],
  [Vòng đời 10 trạng thái (v5.0)], [Đặc tả Vòng đời Trạng thái --- state machine v5.0, ma trận chuyển đổi, quy tắc tự động phân công], [Tất cả],
  [Thiết kế thuật toán tự động phân công], [Đặc tả Vòng đời Trạng thái --- Phần 2.5 (logic tự động phân công Giai đoạn A + B)], [`DEV-237`],
  [Tải lên bằng chứng (RAWSTRING)], [SAP Help cho `CL_GUI_FRONTEND_SERVICES` + hướng dẫn bảng `ZBUG_EVIDENCE`], [`DEV-118`],
  [Long Text API (READ\_TEXT / SAVE\_TEXT)], [SAP Help + hướng dẫn thiết lập text object ZBUG\_NOTE], [`DEV-242`],
)

== 3. Sản phẩm Dự án

*Tài liệu phát triển nội bộ:*

#table(
  columns: (auto, 3cm, 1fr),
  align: (center, left, left),
  [*STT*], [*Sản phẩm*], [*Mô tả*],
  [1], [Mã nguồn (6 include)],       [Các include ABAP `Z_BUG_WS_TOP`, `_F00`, `_PBO`, `_PAI`, `_F01`, `_F02` --- v5.0 hoàn chỉnh],
  [2], [Hướng dẫn Layout Màn hình (8 màn hình)], [Hướng dẫn layout SE51 cho Màn hình 0200/0210/0220/0300/0370/0400/0410/0500 --- danh sách trường, tên Custom Control, flow logic],
  [3], [Sơ đồ CSDL],                [Định nghĩa bảng cho 6 bảng tùy chỉnh (88 trường) --- tên trường, kiểu dữ liệu, trường khóa, mô tả],
  [4], [QC Test Plan],              [140 ca kiểm thử tổ chức trong 20 test suite bao phủ tất cả màn hình, chuyển đổi và trường hợp biên],
  [5], [UAT Happy Case Script],     [64 kịch bản kiểm thử luồng người dùng qua 14 danh mục quy trình (A--N) bao phủ cả 3 vai trò],
  [6], [Đặc tả Vòng đời Trạng thái], [State machine v5.0, ma trận chuyển đổi theo vai trò, điều kiện kích hoạt tự động phân công],
  [7], [Hướng dẫn Nâng cao Giai đoạn F], [Hướng dẫn triển khai từng bước F11--F17 cho tất cả các bổ sung v5.0],
)

*Tài liệu nộp cho Đại học FPT:*

#table(
  columns: (auto, 3cm, 1fr),
  align: (center, left, left),
  [*STT*], [*Sản phẩm*], [*Mô tả*],
  [1], [Business Blueprint],     [Tài liệu Business Blueprint SAP --- PDF Typst đã biên dịch],
  [2], [Báo cáo Cuối kỳ],       [Tài liệu này --- Báo cáo Cuối kỳ FPT Capstone, PDF Typst đã biên dịch],
  [3], [Bằng chứng Kiểm thử],   [Ảnh chụp màn hình kết quả UAT Vòng 1 và kiểm thử hồi quy v5.0],
  [4], [Slide Trình bày],        [Bộ slide demo dự án],
)

== 4. Phân công Trách nhiệm

#table(
  columns: (auto, 3.5cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*STT*], [*Hoạt động*], [*Mô tả*], [*Trách nhiệm*],

  [1],  [Thiết kế CSDL],
        [Sơ đồ bảng cho tất cả 6 bảng tùy chỉnh (77+ trường); miền và phần tử dữ liệu (`ZDE_*`); dải số `ZNRO_BUG`; triển khai qua SE11],
        [`DEV-089`],
  [2],  [Logic lõi ABAP (Z\_BUG\_WS\_F01)],
        [FORM logic nghiệp vụ: `save_bug_detail`, `save_project_detail`, `change_bug_status`, `calculate_dashboard`; wrapper API long text],
        [`DEV-089`],
  [3],  [Tài liệu],
        [Business Blueprint, Báo cáo Cuối kỳ, Đặc tả Vòng đời Trạng thái, Hướng dẫn Nâng cao Giai đoạn F (bước triển khai F11--F17)],
        [`DEV-089`],

  [4],  [Bug Detail (Màn hình 0300)],
        [Tab strip 6 tab (Bug Info, Description, Dev Note, Tester Note, Evidence, History); chế độ Create / Change / Display; trình soạn thảo long text; History ALV],
        [`DEV-242`],
  [5],  [FM: tạo & ghi log],
        [FM `Z_BUG_CREATE` (dải số, tự điền, phân nhánh BUG\_TYPE); FM `Z_BUG_LOG_HISTORY`; bảng `ZBUG_HISTORY`; text object `ZBUG_NOTE` (Z001/Z002/Z003)],
        [`DEV-242`],
  [6],  [Routine hỗ trợ (Z\_BUG\_WS\_F02)],
        [10 routine F4 search help; API `load_long_text` / `save_long_text`; quản lý popup; wrapper `download_smw0_template`; parser `upload_excel_projects`],
        [`DEV-242`],

  [7],  [Bug List + Dashboard (Màn hình 0200)],
        [ALV grid với bộ lọc theo vai trò; Dashboard Header thời gian thực (tổng theo trạng thái / ưu tiên / module); class `LCL_EVENT_HANDLER`; field catalog ALV (`Z_BUG_WS_F00`)],
        [`DEV-061`],
  [8],  [Engine Tìm kiếm Lỗi (Màn hình 0210/0220)],
        [Popup tìm kiếm (Màn hình 0210) + ALV kết quả toàn màn hình (Màn hình 0220) --- mới v5.0; FM `Z_BUG_GET_STATISTICS`],
        [`DEV-061`],
  [9],  [Include ABAP PAI (Z\_BUG\_WS\_PAI)],
        [Tất cả fcode handler qua 9 màn hình; gọi popup trạng thái (`CALL SCREEN 0370`); kích hoạt tìm kiếm lỗi (`CALL SCREEN 0210`); hộp thoại xác nhận],
        [`DEV-061`],

  [10], [Thông báo Email (Tính năng 2)],
        [FM `Z_BUG_SEND_EMAIL` dùng API `CL_BCS`; SmartForm `ZBUG_EMAIL_FORM` (nội dung email HTML); tích hợp SCOT / SMTP; tất cả loại sự kiện thông báo (CREATE, ASSIGN, STATUS\_CHANGE, REJECT)],
        [`DEV-118`],
  [11], [Bằng chứng & Biểu mẫu (Tính năng 5)],
        [FM `Z_BUG_UPLOAD_ATTACHMENT`; bảng `ZBUG_EVIDENCE` (nội dung RAWSTRING); SmartForm `ZBUG_FORM` (PDF chi tiết lỗi); mẫu SMW0 `ZBT_TMPL_01/02/03`; lớp message `ZBUG_MSG`],
        [`DEV-118`],
  [12], [Kiểm thử & Đảm bảo chất lượng],
        [QC Test Plan (140 ca, 20 suite); UAT Happy Case Script (43 ca, 14 danh mục); dữ liệu kiểm thử (`Z_BUG_POPULATE_TESTDATA`); xác minh sửa 11 lỗi UAT],
        [`DEV-118`],

  [13], [Vòng đời trạng thái + popup (v5.0)],
        [Thiết kế vòng đời 10 trạng thái; Màn hình 0370 (Popup Chuyển trạng thái --- Modal Dialog); FM `Z_BUG_UPDATE_STATUS`; ma trận chuyển đổi theo vai trò; include `Z_BUG_WS_TOP` (hằng số `gc_st_*`)],
        [`DEV-237`],
  [14], [Engine tự động phân công (v5.0)],
        [FM `Z_BUG_AUTO_ASSIGN` (Giai đoạn A: Mới→Đã phân công; Giai đoạn B: Đã sửa→Kiểm tra cuối); FM `Z_BUG_REASSIGN`; tính toán khối lượng công việc (COUNT lỗi trong trạng thái đang hoạt động); fallback Waiting],
        [`DEV-237`],
  [15], [Module quản lý dự án],
        [Màn hình 0400 (ALV Danh sách Dự án), 0410 (Tìm kiếm Dự án --- màn hình ban đầu v5.0), 0500 (Chi tiết Dự án + TC phân công người dùng); FM `Z_BUG_CHECK_PERMISSION`; include `Z_BUG_WS_PBO` (tất cả module PBO + `LOOP AT SCREEN` kiểm soát vai trò)],
        [`DEV-237`],
)

== 5. Truyền thông Dự án

#table(
  columns: (2cm, 3cm, 1fr, 2cm),
  align: (center, left, left, center),
  [*Kênh*], [*Công cụ*], [*Nội dung*], [*Tần suất*],
  [Chat nhóm],       [Messenger / Zalo],    [Cập nhật tiến độ hàng ngày, vướng mắc, quyết định nhanh], [Hàng ngày],
  [Báo cáo trạng thái], [FPT LMS / email], [Tóm tắt tiến độ hàng tuần nộp cho giảng viên hướng dẫn], [Hàng tuần],
  [Demo / đánh giá], [Chia sẻ màn hình SAP GUI], [Demo trực tiếp tính năng trên hệ thống S40], [Theo mốc],
  [Tài liệu],        [Tài liệu chia sẻ],  [Hướng dẫn màn hình, kế hoạch kiểm thử, tài liệu thiết kế --- cập nhật theo thay đổi], [Theo thay đổi],
)

== 6. Quản lý Cấu hình

=== 6.1 Quản lý Tài liệu

Tất cả tài liệu dự án được duy trì qua các giai đoạn phát triển và có header phiên bản ghi ngày cập nhật cuối. Phiên bản hiện tại của toàn bộ tài liệu là `v5.0` (Giai đoạn F).

Các loại tài liệu chính được duy trì: Business Blueprint, Báo cáo Cuối kỳ, hướng dẫn layout màn hình (một file mỗi màn hình), QC Test Plan, UAT Happy Case Script, Sơ đồ CSDL, Đặc tả Vòng đời Trạng thái và Hướng dẫn Nâng cao Giai đoạn F.

=== 6.2 Cấu trúc Mã nguồn

Mã nguồn ABAP cho Module Pool `Z_BUG_WORKSPACE_MP` được tổ chức thành 6 chương trình include dưới gói SAP `ZBUGTRACK`. Triển khai lên SAP được thực hiện thủ công: mở từng include trong SE38, dán code đã cập nhật, kiểm tra (Ctrl+F2) và kích hoạt (Ctrl+F3).

#table(
  columns: (3.5cm, 1fr, 1.5cm),
  align: (left, left, center),
  [*SAP Include*], [*Nội dung*], [*Phiên bản*],
  [`Z_BUG_WS_TOP`], [Khai báo toàn cục, kiểu, hằng số cho vòng đời 10 trạng thái, đối tượng container ALV/GUI], [v5.0],
  [`Z_BUG_WS_F00`], [Định nghĩa field catalog ALV cho 5 grid; class `LCL_EVENT_HANDLER`], [v5.0],
  [`Z_BUG_WS_PBO`], [Module Process Before Output cho tất cả 9 màn hình], [v5.0],
  [`Z_BUG_WS_PAI`], [Module Process After Input; tất cả fcode handler], [v5.0],
  [`Z_BUG_WS_F01`], [FORM logic nghiệp vụ: lưu, thay đổi trạng thái, tự động phân công, email, bằng chứng, lịch sử], [v5.0],
  [`Z_BUG_WS_F02`], [FORM hỗ trợ: F4 search help, long text API, popup, tải xuống mẫu], [v5.0],
)

=== 6.3 Công cụ & Cơ sở hạ tầng

#table(
  columns: (auto, 3cm, 1.5cm, 1fr),
  align: (center, left, center, left),
  [*STT*], [*Công cụ*], [*Phiên bản*], [*Mục đích*],
  [1],  [SAP GUI],              [7.70+],      [Front-end SAP chính để phát triển và kiểm thử],
  [2],  [SE11],                 [—],          [Data Dictionary: bảng, miền, phần tử dữ liệu],
  [3],  [SE38 / SE80],          [—],          [Phát triển chương trình ABAP và quản lý code],
  [4],  [SE51],                 [—],          [Screen Painter: thiết kế layout màn hình Dynpro],
  [5],  [SE41],                 [—],          [Menu Painter: định nghĩa GUI Status và Title Bar],
  [6],  [SE93],                 [—],          [Transaction Maintenance: cấu hình T-code],
  [7],  [SMARTFORMS],           [—],          [Trình thiết kế SmartForm cho PDF và mẫu email],
  [8],  [SMW0],                 [—],          [Web Repository: lưu trữ mẫu bằng chứng `.xlsx`],
  [9],  [SCOT],                 [—],          [Cấu hình email SMTP cho thông báo CL\_BCS],
  [10], [SE16N],                [—],          [Trình duyệt dữ liệu bảng để thiết lập và xác minh dữ liệu kiểm thử],
  [11], [Typst],                [0.11+],      [Biên dịch tài liệu cho Blueprint và Báo cáo Cuối kỳ],
)
