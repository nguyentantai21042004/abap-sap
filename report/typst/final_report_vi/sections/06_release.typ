// ============================================================
// 06_release.typ — VI. Gói Phát hành & Hướng dẫn Sử dụng
// ============================================================
#import "../template.typ": placeholder, hline, field, diagram-placeholder

= VI. Gói Phát hành & Hướng dẫn Sử dụng

== 1. Gói Sản phẩm Bàn giao

Tất cả sản phẩm bàn giao dưới đây thuộc phiên bản v5.0 của Hệ thống Quản lý Theo dõi Lỗi SAP (`ZBUG_WS`), được triển khai dưới dạng chương trình Module Pool `Z_BUG_WORKSPACE_MP` trong gói SAP `ZBUGTRACK`.

#table(
  columns: (auto, 3.5cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*STT*], [*Sản phẩm Bàn giao*], [*Mô tả*], [*Phiên bản*],
  [1], [ABAP Include `Z_BUG_WS_TOP`], [Khai báo toàn cục, kiểu dữ liệu, hằng số cho vòng đời 10 trạng thái (`gc_st_new` đến `gc_st_resolved`), toàn bộ đối tượng ALV/GUI container, biến số liệu dashboard, biến trường màn hình 0370/0410/0210/0220], [v5.0],
  [2], [ABAP Include `Z_BUG_WS_F00`], [Định nghĩa field catalog ALV cho 5 lưới ALV; lớp `LCL_EVENT_HANDLER` cài đặt sự kiện hotspot-click và double-click cho Danh sách Lỗi và Danh sách Dự án], [v5.0],
  [3], [ABAP Include `Z_BUG_WS_PBO`], [Module Process Before Output cho tất cả 9 màn hình; lệnh gọi tính toán dashboard trong `status_0200`; logic nhóm màn hình qua `LOOP AT SCREEN` để kiểm soát trường theo vai trò], [v5.0],
  [4], [ABAP Include `Z_BUG_WS_PAI`], [Module Process After Input; toàn bộ bộ xử lý fcode; lệnh gọi popup chuyển trạng thái (`CALL SCREEN 0370`); kích hoạt công cụ tìm kiếm lỗi (`CALL SCREEN 0210`)], [v5.0],
  [5], [ABAP Include `Z_BUG_WS_F01`], [FORM nghiệp vụ: `save_bug_detail`, `save_project_detail`, `change_bug_status`, `auto_assign_developer` (Giai đoạn A), `auto_assign_tester` (Giai đoạn B), `upload_evidence_file`, `send_email_bcs`, `log_history`, `calculate_dashboard`], [v5.0],
  [6], [ABAP Include `Z_BUG_WS_F02`], [FORM hỗ trợ: 10 hàm F4 tra cứu, `load_long_text` / `save_long_text` (API văn bản dài), bao ngoài `download_smw0_template`, bộ phân tích `upload_excel_projects`], [v5.0],
  [7], [Bảng DB `ZBUG_TRACKER`], [Bảng theo dõi lỗi chính --- 29 trường. Domain `zde_bug_status` là CHAR 20 (không phải CHAR 1); trường STATUS lưu mã vòng đời 10 trạng thái (1, 2, 3, 4, 5, 6, 7, R, V, W)], [v5.0],
  [8], [Bảng DB `ZBUG_PROJECT`], [Dữ liệu chủ dự án --- 16 trường bao gồm cờ xóa mềm `IS_DEL` và dấu vết kiểm toán đầy đủ (ERNAM, ERDAT, AENAM, AEDAT)], [v5.0],
  [9], [Bảng DB `ZBUG_USERS`], [Danh mục người dùng --- 12 trường bao gồm `ROLE` (M/D/T), `SAP_MODULE`, `IS_ACTIVE`, `IS_DEL`, và `EMAIL` để gửi thông báo], [v5.0],
  [10], [Bảng DB `ZBUG_USER_PROJEC`], [Phân công người dùng vào dự án theo quan hệ M:N --- 10 trường; cột `ROLE` theo dự án; cơ sở cho lọc tự động phân công và hiển thị dự án theo vai trò], [v5.0],
  [11], [Bảng DB `ZBUG_HISTORY`], [Nhật ký thay đổi --- 10 trường; ghi lại toàn bộ chuyển đổi trạng thái và cập nhật trường với `OLD_STATUS`, `NEW_STATUS`, `ACTION` (ST/CR/UP), `REASON` (STRING), và dấu thời gian], [v5.0],
  [12], [Bảng DB `ZBUG_EVIDENCE`], [Lưu trữ tệp nhị phân --- 11 trường; `CONTENT` kiểu RAWSTRING; `MIME_TYPE` (CHAR 100), `FILE_SIZE` (INT4), `FILE_NAME` (CHAR 255)], [v5.0],
  [13], [Hướng dẫn Màn hình (8 màn hình)], [Tài liệu bố cục SE51 trong thư mục `screens/` cho các màn hình 0200, 0210, 0220, 0300 (+ 6 màn hình phụ 0310--0360), 0370, 0400, 0410, 0500 --- danh sách trường, tên Custom Control, luồng logic], [v5.0],
  [14], [Kế hoạch Kiểm thử QC + Kịch bản UAT], [Kế hoạch Kiểm thử QC: 20 bộ (TC-01 đến TC-20), khoảng 210 trường hợp kiểm thử bao gồm tất cả màn hình, chuyển đổi, trường hợp biên và RBAC. Kịch bản Happy Case UAT: 64 trường hợp thuộc 14 danh mục quy trình (A--N) cho vai trò Manager, Developer và Tester], [v5.0],
  [15], [Tài liệu Báo cáo Cuối kỳ], [Tài liệu này (Báo cáo Capstone FPT) --- bao gồm các phần Giới thiệu, Quản lý Dự án, Yêu cầu, Thiết kế, Kiểm thử và Phát hành], [v5.0],
  [16], [Mẫu SMW0 (3 tệp)], [`ZBT_TMPL_01` → `Bug_report.xlsx` (mẫu báo cáo lỗi của Tester); `ZBT_TMPL_02` → `fix_report.xlsx` (bằng chứng sửa lỗi của Developer); `ZBT_TMPL_03` → `confirm_report.xlsx` (xác nhận cuối cùng của Tester)], [v5.0],
  [17], [Báo cáo Dữ liệu Kiểm thử], [`Z_BUG_POPULATE_TESTDATA` --- báo cáo thực thi SE38 tạo 20 Developer mô phỏng + 10 Tester mô phỏng trong các module FI/MM/SD/ABAP với phân công dự án để kiểm thử thuật toán tự động phân công], [v5.0],
  [18], [Script Di chuyển Trạng thái], [ABAP di chuyển một lần: cập nhật tất cả bản ghi có `STATUS = '6'` (Đã giải quyết trong v4.x) thành `STATUS = 'V'` (Đã giải quyết trong v5.0) bằng `UPDATE zbug_tracker SET status = 'V' WHERE status = '6' AND is_del <> 'X'` rồi `COMMIT WORK`], [v5.0],
)

== 2. Hướng dẫn Cài đặt

=== 2.1 Yêu cầu Hệ thống

#table(
  columns: (auto, 3cm, 1fr, 2.5cm),
  align: (center, left, left, center),
  [*STT*], [*Thành phần*], [*Yêu cầu*], [*Phiên bản / Giá trị*],
  [1], [Hệ thống SAP], [SAP ERP với đầy đủ ABAP Workbench (SE11, SE38/SE80, SE51, SE41, SE93, SE37, SM30)], [S40],
  [2], [SAP Basis], [SAP_BASIS 770 trở lên --- yêu cầu cho cú pháp ABAP 7.70 (inline `DATA`, `SWITCH`, `CONV`, biến host `@`, chuỗi mẫu `|...|`)], [770+],
  [3], [SAP Client], [Client phát triển/kiểm thử riêng biệt với Table Maintenance Generator có thể truy cập `ZBUG_USERS` qua SM30], [Client 324],
  [4], [Email (SOST)], [SOST / API BCS được cấu hình với profile SMTP hợp lệ để gửi email thông báo đến Developer và Tester], [Đã cấu hình],
  [5], [Kho Web (SMW0)], [Kho SMW0 có thể truy cập; đối tượng `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03` đã được tạo và tệp Excel đã được tải lên], [Hoạt động],
  [6], [Đối tượng Dải số], [`ZNR_BUGS` (Bug ID 10 chữ số, định dạng `BUG0000001`) và `ZNR_PROJECTS` (Project ID 10 chữ số, định dạng `PRJ0000001`) phải tồn tại trong `SNRO`], [Đã cấu hình],
  [7], [Đối tượng Văn bản], [Đối tượng văn bản `ZBUG` đã đăng ký trong `SE75` để lưu văn bản dài qua `READ_TEXT`/`SAVE_TEXT` (Mô tả, Ghi chú Dev, Ghi chú Tester)], [Đã cấu hình],
  [8], [Gói Phát triển], [Gói `ZBUGTRACK` phải tồn tại trong SE80; tất cả đối tượng chương trình được gán vào gói này], [Hoạt động],
)

=== 2.2 Các bước Cài đặt

Các bước sau đây triển khai `Z_BUG_WORKSPACE_MP` v5.0 vào hệ thống SAP. Thực hiện theo thứ tự liệt kê. Các bước F11--F17 tương ứng với nhiệm vụ triển khai Giai đoạn F.

*Bước F11 --- Tạo 4 Màn hình Mới trong SE51:*

+ Mở transaction *SE51*. Đặt Program = `Z_BUG_WORKSPACE_MP`.
+ *Màn hình 0410* (Normal screen): Tạo màn hình, đặt mô tả ngắn "Project Search". Trong layout, thêm 3 trường nhập liệu: `S_PRJ_ID` (nhãn "Project ID"), `S_PRJ_MN` (nhãn "Manager"), `S_PRJ_ST` (nhãn "Status"). Trong Flow Logic, thêm: PBO → `MODULE status_0410 OUTPUT`; PAI → `MODULE user_command_0410 INPUT`; POV → module F4 cho cả 3 trường. Kích hoạt.
+ *Màn hình 0370* (Modal Dialog Box, ~80 cột × 20 dòng): Thêm trường chỉ đọc cho `gv_trans_bug_id`, `gv_trans_title`, `gv_trans_reporter`, `gv_trans_cur_st_text`. Thêm trường nhập: `gv_trans_new_status` (nhãn "New Status"), `gv_trans_dev_id` (nhãn "Developer"), `gv_trans_ftester_id` (nhãn "Final Tester"). Thêm Custom Control tên `CC_TRANS_NOTE`. Flow Logic: PBO → `status_0370`, `init_trans_popup`; PAI → `user_command_0370`; POV → module F4. Kích hoạt.
+ *Màn hình 0210* (Modal Dialog Box, ~70 cột × 15 dòng): Thêm 7 trường nhập liệu: `s_bug_id`, `s_title`, `s_status`, `s_prio`, `s_mod`, `s_reporter`, `s_dev`. Flow Logic: PBO → `status_0210`; PAI → `user_command_0210`; POV → module F4. Kích hoạt.
+ *Màn hình 0220* (Normal screen): Thêm Custom Control tên `CC_SEARCH_RESULTS`. Flow Logic: PBO → `status_0220 OUTPUT`, `display_search_alv OUTPUT`; PAI → `user_command_0220 INPUT`. Kích hoạt.

*Bước F12 --- Tạo GUI Status và Title Bar trong SE41:*

+ Mở transaction *SE41*. Đặt Program = `Z_BUG_WORKSPACE_MP`.
+ Tạo GUI Status `STATUS_0410`: Application Toolbar với nút Execute (fcode `EXECUTE`, F8), Back (fcode `BACK`, F3), Exit (fcode `EXIT`, Shift+F3), Cancel (fcode `CANCEL`, F12). Tạo Title Bar `T_0410` với văn bản "Project Search". Kích hoạt cả hai.
+ Tạo GUI Status `STATUS_0370`: Application Toolbar với Confirm (fcode `CONFIRM`), Upload Evidence (fcode `UP_TRANS`), Cancel (fcode `CANCEL`, F12). Tạo Title Bar `T_0370` với văn bản "Change Bug Status". Kích hoạt.
+ Tạo GUI Status `STATUS_0210`: Application Toolbar với Execute (fcode `EXECUTE`, F8) và Cancel (fcode `CANCEL`, F12). Tạo Title Bar `T_0210` với văn bản "Bug Search". Kích hoạt.
+ Tạo GUI Status `STATUS_0220`: Application Toolbar với Back (fcode `BACK`, F3), Exit (fcode `EXIT`, Shift+F3), Cancel (fcode `CANCEL`, F12). Tạo Title Bar `T_0220` với văn bản "Search Results". Kích hoạt.
+ Cập nhật GUI Status hiện có `STATUS_0200`: thêm nút Search (fcode `SEARCH`) vào Application Toolbar. Kích hoạt lại.

*Bước F13 --- Sao chép Mã ABAP v5.0 vào SAP:*

+ Mở transaction *SE80* hoặc *SE38*.
+ Với mỗi trong số 6 include dưới đây, mở chương trình include trong SE38, dán mã nguồn v5.0, sau đó kiểm tra (Ctrl+F2) và kích hoạt (Ctrl+F3):

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  [*Chương trình Include SAP*], [*Tóm tắt Nội dung*],
  [`Z_BUG_WS_TOP`], [Khai báo toàn cục, kiểu dữ liệu, hằng số, đối tượng ALV],
  [`Z_BUG_WS_F00`], [Field catalog ALV, lớp `LCL_EVENT_HANDLER`],
  [`Z_BUG_WS_PBO`], [Module Process Before Output (tất cả 9 màn hình)],
  [`Z_BUG_WS_PAI`], [Module Process After Input, toàn bộ bộ xử lý fcode],
  [`Z_BUG_WS_F01`], [FORM nghiệp vụ: lưu, chuyển trạng thái, tự động phân công, email],
  [`Z_BUG_WS_F02`], [FORM hỗ trợ: F4, API văn bản dài, popup, tải mẫu],
)

+ Sau khi sao chép xong cả 6 include, mở chương trình chính `Z_BUG_WORKSPACE_MP` trong SE80 và thực hiện kích hoạt hàng loạt (chọn tất cả đối tượng → Activate). Giải quyết mọi lỗi cú pháp trước khi tiếp tục.

*Bước F14 --- Cập nhật Màn hình Khởi đầu T-code trong SE93:*

+ Mở transaction *SE93*. Nhập `ZBUG_WS` → Thay đổi.
+ Dưới "Default values", thay đổi trường "Screen number" từ `0400` thành `0410`.
+ Lưu và kích hoạt. Chạy `/nZBUG_WS` để xác nhận Màn hình 0410 xuất hiện là màn hình đầu tiên.

*Bước F15 --- Tạo Bảng `ZBUG_EVIDENCE` (nếu chưa có):*

+ Mở transaction *SE11*. Tạo bảng cơ sở dữ liệu `ZBUG_EVIDENCE` với 11 trường như liệt kê dưới đây. Trường khóa: `CLIENT` (MANDT, CLNT 3, Khóa), `EVD_ID` (CHAR 10, Khóa). Trường `CONTENT` phải dùng kiểu `RAWSTRING` (binary blob). Các trường bổ sung: `BUG_ID` (CHAR 10), `FILE_NAME` (CHAR 255), `MIME_TYPE` (CHAR 100), `FILE_SIZE` (INT4), `ERNAM` (CHAR 12), `ERDAT` (DATS 8), `ERZET` (TIMS 6), `EVD_TYPE` (CHAR 1 --- R=Báo cáo, F=Sửa, V=Xác minh). Kích hoạt bảng và tạo Table Maintenance Generator nếu cần.

*Bước F16 --- Chạy Script Di chuyển Trạng thái:*

+ Mở *SE38*. Tạo báo cáo tạm thời và chạy đoạn ABAP sau:

```abap
UPDATE zbug_tracker SET status = 'V'
  WHERE status = '6' AND is_del <> 'X'.
COMMIT WORK.
WRITE: / 'Migrated', sy-dbcnt, 'records from status 6 to V.'.
```

+ Xác minh qua *SE16N* trên `ZBUG_TRACKER` rằng không còn bản ghi nào có `STATUS = '6'`. Sau khi xác minh, xóa báo cáo tạm thời.

*Bước F17 --- Tải lên Mẫu SMW0:*

+ Mở transaction *SMW0*. Điều hướng đến "Binary data for WebRFC applications".
+ Tải lên 3 tệp mẫu Excel vào các đối tượng tương ứng:
  - Đối tượng `ZBT_TMPL_01` ← `Bug_report.xlsx` (mẫu báo cáo lỗi của Tester)
  - Đối tượng `ZBT_TMPL_02` ← `fix_report.xlsx` (mẫu bằng chứng sửa lỗi của Developer)
  - Đối tượng `ZBT_TMPL_03` ← `confirm_report.xlsx` (mẫu xác nhận cuối của Tester)
+ Lưu và kích hoạt cả 3 đối tượng.

*Xác minh Triển khai:* Sau khi hoàn thành tất cả các bước, chạy `/nZBUG_WS`. Xác nhận Màn hình 0410 (Project Search) xuất hiện đầu tiên. Nhấn Execute → Màn hình 0400 hiển thị danh sách dự án đã lọc. Nhấp vào một dự án → Màn hình 0200 hiển thị danh sách lỗi với tiêu đề Dashboard. Chọn một lỗi ở chế độ Change → nhấp "Change Status" → Popup Màn hình 0370 mở với thông tin lỗi đúng và dropdown trạng thái.

== 3. Hướng dẫn Sử dụng

=== 3.1 Tổng quan

Hệ thống Quản lý Theo dõi Lỗi SAP (`ZBUG_WS`) là ứng dụng theo dõi lỗi tập trung được xây dựng natively trên SAP ERP sử dụng lập trình ABAP Module Pool. Hệ thống hỗ trợ ba vai trò người dùng --- *Manager*, *Developer* và *Tester* --- mỗi vai trò có quyền hạn riêng biệt được kiểm soát ở cấp screen group và fcode.

*Điểm vào hệ thống:* Transaction code `ZBUG_WS` → Màn hình 0410 (Tìm kiếm Dự án)

*Bản đồ màn hình:*

#table(
  columns: (1.5cm, 2.5cm, 1fr),
  align: (center, left, left),
  [*Màn hình*], [*Tên*], [*Mục đích*],
  [0410], [Tìm kiếm Dự án], [Màn hình khởi đầu: lọc dự án có thể truy cập trước khi vào danh sách (Mới trong v5.0)],
  [0400], [Danh sách Dự án], [Lưới ALV các dự án; tạo/sửa/xóa dự án; khởi chạy My Bugs],
  [0200], [Danh sách Lỗi + Dashboard], [Danh sách lỗi của dự án được chọn với số liệu trạng thái/ưu tiên/module thời gian thực],
  [0300], [Chi tiết Lỗi], [Tạo/xem/sửa lỗi; dải 6 tab: Bug Info, Mô tả, Ghi chú Dev, Ghi chú Tester, Bằng chứng, Lịch sử],
  [0370], [Popup Chuyển Trạng thái], [Thay đổi trạng thái lỗi qua ma trận 10 trạng thái; kiểm tra vai trò và các trường bắt buộc (Mới trong v5.0)],
  [0500], [Chi tiết Dự án], [Quản lý metadata dự án và phân công/xóa người dùng khỏi dự án (chỉ Manager)],
  [0210/0220], [Tìm kiếm Lỗi], [Tìm kiếm lỗi theo từ khóa, trạng thái, ưu tiên, module hoặc người báo cáo trong dự án hiện tại],
)

*Vòng đời Lỗi 10 Trạng thái (v5.0):*

#diagram-placeholder("Vòng đời Lỗi 10 Trạng thái (v5.0)", "docs/diagrams/bug-lifecycle.mmd")

Lưu ý: `Closed (7)` là trạng thái kết thúc kế thừa được giữ lại để tương thích ngược.

=== 3.2 Quy trình 1 --- Báo cáo Lỗi (Vai trò Tester)

*Mục đích:* Tester phát hiện lỗi trong quá trình kiểm thử hệ thống SAP, ghi nhận vào hệ thống và đính kèm bằng chứng hỗ trợ.

*Điều kiện tiên quyết:* Đã đăng nhập bằng tài khoản Tester (vai trò `T` trong `ZBUG_USERS`); có ít nhất một dự án tồn tại với Tester này được phân công.

*Các bước:*

+ Chạy transaction `/nZBUG_WS`. Màn hình 0410 (Tìm kiếm Dự án) xuất hiện với ba trường lọc.
+ Nhấn *Execute* (F8) để liệt kê tất cả dự án có thể truy cập (hoặc nhập bộ lọc Project ID trước). Màn hình 0400 hiển thị danh sách dự án.
+ Double-click vào dòng dự án mục tiêu. Màn hình 0200 mở ra, hiển thị tất cả lỗi của dự án đó và tiêu đề Dashboard thời gian thực.
+ Nhấp nút *Create* trong thanh công cụ. Màn hình 0300 mở ra ở chế độ Create.
+ Trên tab *Bug Info*, điền các trường bắt buộc:
  - *Title*: mô tả ngắn gọn về lỗi (bắt buộc, tối đa 100 ký tự)
  - *SAP Module*: nhấn F4 để chọn từ FI / MM / SD / ABAP / Basis / PP / HR / QM
  - *Priority*: nhấn F4 để chọn H (Cao) / M (Trung bình) / L (Thấp)
  - *Severity*: nhấn F4 để chọn 1 (Crash/Nghiêm trọng) đến 5 (Nhỏ)
  - *Bug Type*: nhấn F4 để chọn 1 (Chức năng) đến 5 (Bảo mật)
  - *Project ID*: được điền sẵn và khóa từ ngữ cảnh dự án (không thể thay đổi)
+ Chuyển sang tab *Description*: nhập mô tả đầy đủ về lỗi bằng trình soạn thảo văn bản.
+ Chuyển sang tab *Evidence*: nhấp *Upload Evidence* → chọn ảnh chụp màn hình hoặc tệp nhật ký từ máy tính. Tệp được lưu trong `ZBUG_EVIDENCE` và xuất hiện dưới dạng dòng mới trong bảng Bằng chứng.
+ Nhấp *Save*. Hệ thống tự động tạo `BUG_ID` (định dạng `BUG0000001`) và ngay lập tức chạy công cụ tự động phân công:
  - *Nếu tìm thấy Developer phù hợp* (cùng SAP Module, đang hoạt động trong dự án, tải công việc < 5 lỗi): `DEV_ID` được điền, trạng thái chuyển thành *Assigned (2)*.
  - *Nếu không có Developer phù hợp*: trạng thái chuyển thành *Waiting (W)* và hiển thị thông báo.
+ Lỗi xuất hiện trong Danh sách Lỗi trên Màn hình 0200. Bộ đếm Dashboard cập nhật tương ứng.

=== 3.3 Quy trình 2 --- Giải quyết Lỗi (Vai trò Developer)

*Mục đích:* Developer nhận lỗi được phân công, điều tra, áp dụng bản vá, tải lên bằng chứng sửa lỗi và đánh dấu lỗi là Fixed.

*Điều kiện tiên quyết:* Đã đăng nhập bằng tài khoản Developer (vai trò `D` trong `ZBUG_USERS`); có ít nhất một lỗi được phân công với `DEV_ID` trùng với người dùng hiện tại.

*Các bước:*

+ Chạy `/nZBUG_WS` → Execute → nhấp vào dự án liên quan. Trên Màn hình 0200, tìm lỗi được phân công (trạng thái = Assigned).
  - Hoặc nhấp *My Bugs* trên thanh công cụ Màn hình 0400 để chỉ xem lỗi có `DEV_ID = người dùng hiện tại`.
+ Chọn lỗi → nhấp *Change*. Màn hình 0300 mở ra ở chế độ Change.
+ Nhấp nút *Change Status*. Popup Màn hình 0370 mở ra hiển thị thông tin lỗi hiện tại:
  - Trường chỉ đọc: Bug ID, Title, Reporter, Current Status ("Assigned")
  - Dropdown: *New Status* --- nhấn F4, chọn "In Progress (3)"
  - Nhấp *Confirm*. Trạng thái chuyển thành In Progress.
+ Điều tra lỗi. Ghi lại kết quả phân tích và cách tiếp cận sửa lỗi trong tab *Dev Note* (trình soạn thảo văn bản).
+ Chuyển sang tab *Evidence* và nhấp *Upload Fix* → chọn tệp bằng chứng sửa lỗi (ví dụ: `fix_report.xlsx`). Phải có ít nhất một tệp bằng chứng trước khi chuyển sang Fixed.
+ Nhấp *Change Status* lần nữa. Trong popup 0370:
  - Nhấn F4 trên New Status → chọn "Fixed (5)"
  - Nhấp *Confirm*. Hệ thống kiểm tra rằng có ít nhất một tệp bằng chứng trong `ZBUG_EVIDENCE`. Nếu thành công:
    - Trạng thái chuyển thành Fixed (5).
    - Tự động Phân công Giai đoạn B kích hoạt ngay: hệ thống tìm kiếm Tester có cùng `SAP_MODULE` trong dự án với tải công việc < 5 lỗi Final Testing đang hoạt động.
    - *Nếu tìm thấy Tester*: `VERIFY_TESTER_ID` được thiết lập, trạng thái tiến thành *Final Testing (6)*.
    - *Nếu không có Tester*: trạng thái chuyển thành *Waiting (W)*.
+ Bản ghi lịch sử được ghi vào `ZBUG_HISTORY` cho chuyển đổi Fixed. Trách nhiệm lỗi chuyển sang Tester được phân công.

=== 3.4 Quy trình 3 --- Quản lý Dự án (Vai trò Manager)

*Mục đích:* Manager tạo dự án mới, phân công nhóm phát triển, theo dõi tiến trình lỗi bằng Dashboard và đóng dự án khi tất cả lỗi được giải quyết.

*Các bước --- Tạo Dự án và Phân công Nhóm:*

+ Chạy `/nZBUG_WS` → Execute (F8) trên Màn hình 0410 để xem tất cả dự án. Màn hình 0400 mở ra.
+ Nhấp *Create Project* trong thanh công cụ. Màn hình 0500 mở ra ở chế độ Create.
+ Điền các trường dự án:
  - *Project Name*: bắt buộc
  - *Start Date* / *End Date*: nhấn F4 để chọn từ lịch
  - *Project Status*: mặc định là "1 --- Opening"
  - *Project Manager*: được điền sẵn bằng ID người dùng hiện tại
+ Nhấp *Save*. `PROJECT_ID` được tự động tạo (định dạng `PRJ0000001`). Chế độ chuyển sang Change.
+ Trong *User Assignment* Table Control ở cuối Màn hình 0500:
  - Nhấp *Add User* → nhập User ID (nhấn F4 để duyệt `ZBUG_USERS`) và Vai trò (M/D/T)
  - Lặp lại cho từng thành viên nhóm (Developer, Tester, đồng-Manager nếu cần)
  - Lưu sau mỗi lần thêm
+ Nhấp *Back* để quay lại Màn hình 0400. Dự án mới xuất hiện trong danh sách.

*Các bước --- Theo dõi Tiến trình Lỗi:*

+ Trên Màn hình 0400, nhấp vào dòng dự án để mở Màn hình 0200 (Danh sách Lỗi + Dashboard).
+ Tiêu đề Dashboard ở đầu Màn hình 0200 hiển thị số liệu thời gian thực:
  - *Tổng Lỗi*: tổng số lỗi trong dự án
  - *Theo Trạng thái*: số lượng theo từng trạng thái vòng đời (New / Assigned / In Progress / Fixed / Final Testing / Resolved / Waiting / Rejected)
  - *Theo Ưu tiên*: số lượng Cao / Trung bình / Thấp
  - *Theo Module*: số lượng FI / MM / SD / ABAP / Basis
+ Nhấp *Refresh* trong thanh công cụ bất cứ lúc nào để tải lại dữ liệu lỗi và tính toán lại Dashboard.
+ Nhấp *Search* để mở popup Tìm kiếm Lỗi (Màn hình 0210): nhập tối đa 6 tiêu chí tìm kiếm (Bug ID, từ khóa tiêu đề, trạng thái, ưu tiên, module, người báo cáo). Màn hình 0220 hiển thị kết quả đã lọc mà không có dashboard.
+ Manager có thể thực hiện chuyển đổi trạng thái thủ công trên bất kỳ lỗi nào: chọn lỗi → Change → *Change Status* → Popup Màn hình 0370 → chọn chuyển đổi hợp lệ theo ma trận → Confirm.

*Các bước --- Đóng Dự án:*

+ Trên Màn hình 0400, chọn dự án → *Change*. Màn hình 0500 mở ra.
+ Trong trường *Project Status*, chọn "3 --- Done".
+ Nhấp *Save*. Hệ thống kiểm tra rằng tất cả lỗi trong dự án đang ở trạng thái kết thúc (Resolved V, Rejected R, hoặc Closed 7).
  - *Nếu còn lỗi chưa giải quyết*: thông báo "Cannot set project to Done. N bug(s) not yet Resolved/Closed." Lưu bị từ chối.
  - *Nếu tất cả lỗi ở trạng thái kết thúc*: trạng thái dự án chuyển sang Done; lưu thành công.
+ Quay lại Màn hình 0410 và lọc theo Status = "3 --- Done" để xác nhận dự án đã được đóng.
