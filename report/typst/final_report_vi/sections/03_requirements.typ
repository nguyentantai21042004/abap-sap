// ============================================================
// 03_requirements.typ — III. Đặc tả Yêu cầu Phần mềm
// ============================================================
#import "../template.typ": placeholder, hline, field, diagram-placeholder

= III. Đặc tả Yêu cầu Phần mềm

== 1. Tổng quan Yêu cầu

=== 1.1 Sơ đồ Ngữ cảnh

`ZBUG_WS` là một ứng dụng SAP nội bộ khép kín. Tất cả tác nhân tương tác qua SAP GUI sử dụng một điểm vào T-code duy nhất. Không có tích hợp bên ngoài nào ở tầng trình bày; email là kênh ra duy nhất, được định tuyến qua cơ sở hạ tầng SCOT/SMTP nội bộ của SAP.

#diagram-placeholder("Sơ đồ Ngữ cảnh Hệ thống", "docs/diagrams/context-diagram.mmd")

Các tác nhân:
- *Manager (`DEV-089`):* Toàn quyền truy cập — tạo/xóa dự án, quản lý người dùng, phê duyệt phân công, xem dashboard
- *Developer (`DEV-061`):* Nhận lỗi được phân công, cập nhật trạng thái (Đang xử lý / Đã sửa / Tạm dừng / Từ chối), tải lên bằng chứng sửa lỗi
- *Tester (`DEV-118`):* Tạo lỗi, tải lên bằng chứng báo cáo lỗi, xác minh sửa lỗi, xác nhận giải quyết

=== 1.2 Yêu cầu Người dùng

*Sơ đồ Ca Sử dụng (dạng văn bản):*

#table(
  columns: (2cm, 1fr, 1fr),
  align: (center, left, left),
  [*Mã UC*], [*Tên Ca Sử dụng*], [*Tác nhân*],
  [UC-01], [Tìm kiếm và xem danh sách dự án],               [Manager, Developer, Tester],
  [UC-02], [Tạo / Sửa / Xóa dự án],                         [Manager],
  [UC-03], [Quản lý thành viên dự án (phân công vai trò)],   [Manager],
  [UC-04], [Xem danh sách lỗi cho một dự án],                [Manager, Developer, Tester],
  [UC-05], [Tạo báo cáo lỗi],                                [Tester, Manager],
  [UC-06], [Xem chi tiết lỗi],                               [Manager, Developer, Tester],
  [UC-07], [Sửa thông tin lỗi],                              [Manager, Developer (giới hạn), Tester (giới hạn)],
  [UC-08], [Thay đổi trạng thái lỗi qua popup chuyển đổi],  [Manager, Developer, Tester (theo ma trận chuyển đổi)],
  [UC-09], [Xóa lỗi (xóa mềm)],                             [Manager],
  [UC-10], [Tải lên file bằng chứng],                        [Manager, Developer, Tester (theo loại bằng chứng)],
  [UC-11], [Tải xuống mẫu bằng chứng],                      [Manager, Tester],
  [UC-12], [Tìm kiếm lỗi theo nhiều tiêu chí],              [Manager, Developer, Tester],
  [UC-13], [Xem số liệu dashboard],                          [Manager],
  [UC-14], [Gửi thông báo email],                            [Hệ thống (tự động) + Manager, Developer, Tester (thủ công)],
  [UC-15], [Xem nhật ký lịch sử thay đổi],                  [Manager, Developer, Tester],
)

=== 1.3 Chức năng Hệ thống

*Luồng màn hình (v5.0):*

#diagram-placeholder("Luồng Điều hướng Màn hình (v5.0)", "docs/diagrams/screen-flow.mmd")

*Vai trò hệ thống và phân quyền màn hình:*

#table(
  columns: (3cm, 1.5cm, 1.5cm, 1.5cm),
  align: (left, center, center, center),
  [*Khả năng*], [*M*], [*D*], [*T*],
  [Truy cập tất cả dự án], [✓], [riêng], [riêng],
  [Tạo / Xóa dự án], [✓], [—], [—],
  [Thêm / Xóa người dùng dự án], [✓], [—], [—],
  [Tạo lỗi], [✓], [—], [✓],
  [Xóa lỗi], [✓], [—], [—],
  [Thay đổi trường thông tin lỗi (nhóm FNC: loại/ưu tiên/mức độ)], [✓], [—], [✓],
  [Thay đổi trường thông tin lỗi (nhóm DEV: ghi chú dev)], [✓], [✓], [—],
  [Thay đổi trạng thái (qua popup 0370)], [ma trận], [ma trận], [ma trận],
  [Tải lên bằng chứng báo cáo lỗi], [✓], [—], [✓ (người báo cáo)],
  [Tải lên bằng chứng sửa lỗi], [✓], [✓ (được phân công)], [✓ (lỗi cấu hình)],
  [Tải xuống mẫu từ SMW0], [✓], [—], [✓],
  [Xem header dashboard], [✓], [✓], [✓],
  [Gửi email thủ công], [✓], [✓], [✓],
)

== 2. Đặc tả Chức năng

=== 2.1 Quản lý Lỗi

==== 2.1.1 UC-05 — Tạo Lỗi

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Mã UC*],        [UC-05],
  [*Tên*],          [Tạo Lỗi],
  [*Tác nhân*],     [Tester, Manager],
  [*Mô tả*],        [Người dùng tạo một bản ghi lỗi mới liên kết với ngữ cảnh dự án hiện tại],
  [*Điều kiện trước*], [Người dùng đã đăng nhập; một dự án đã được chọn trong Màn hình 0400; người dùng có vai trò Tester hoặc Manager],
  [*Điều kiện sau*],  [Bản ghi mới trong `ZBUG_TRACKER` với STATUS='1' (Mới); tự động phân công kích hoạt; email được gửi],
  [*Luồng bình thường*], [1. Người dùng nhấn "Tạo" trên Màn hình 0200 \n 2. Màn hình 0300 mở ở chế độ Tạo \n 3. Người dùng điền TITLE, SAP\_MODULE, BUG\_TYPE, PRIORITY, SEVERITY \n 4. Người dùng viết mô tả (Tab 0320) và ghi chú kiểm thử viên tùy chọn (Tab 0340) \n 5. Người dùng nhấn "Lưu" \n 6. BUG\_ID được tự tạo (định dạng BUG0000001 qua ZNRO\_BUG) \n 7. Tự động phân công giai đoạn A chạy (Mới → Đã phân công hoặc Waiting) \n 8. Email được gửi đến lập trình viên được phân công và manager],
  [*Luồng ngoại lệ*], [Thiếu trường bắt buộc → thông báo lỗi, không lưu \n Tự động phân công không tìm thấy dev đủ điều kiện → STATUS = 'W' (Waiting)],
)

==== 2.1.2 UC-08 — Thay đổi Trạng thái Lỗi

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Mã UC*],        [UC-08],
  [*Tên*],          [Thay đổi Trạng thái Lỗi qua Popup],
  [*Tác nhân*],     [Manager, Developer, Tester (theo ma trận chuyển đổi)],
  [*Mô tả*],        [Người dùng thay đổi trạng thái lỗi thông qua Màn hình popup 0370 chuyên dụng, thực thi quy tắc chuyển đổi theo vai trò],
  [*Điều kiện trước*], [Lỗi được tải trong Màn hình 0300 chế độ Change; người dùng có vai trò đúng cho trạng thái hiện tại],
  [*Điều kiện sau*],  [STATUS được cập nhật trong `ZBUG_TRACKER`; bản ghi lịch sử trong `ZBUG_HISTORY`; email được gửi; tự động phân công Giai đoạn B có thể kích hoạt],
  [*Luồng bình thường*], [1. Người dùng nhấn "Thay đổi Trạng thái" trên Màn hình 0300 \n 2. Màn hình popup 0370 mở với thông tin lỗi hiện tại ở chế độ đọc \n 3. Người dùng chọn trạng thái mới từ dropdown (tùy chọn theo vai trò) \n 4. Người dùng điền các trường bắt buộc (DEVELOPER\_ID, TRANS\_NOTE, hoặc tải lên bằng chứng theo ma trận) \n 5. Người dùng nhấn "Xác nhận" \n 6. Chuyển đổi được xác thực; STATUS được cập nhật; lịch sử được ghi \n 7. Nếu Fixed (5): tự động phân công Giai đoạn B chạy (→ Final Testing 6 hoặc Waiting W)],
  [*Luồng ngoại lệ*], [Thiếu trường bắt buộc (ví dụ: bằng chứng cho Fixed, TRANS\_NOTE cho Resolved) → thông báo lỗi \n Chuyển đổi không được phép cho vai trò → trường popup bị khóa, xác nhận bị chặn],
)

=== 2.2 Quản lý Dự án

==== 2.2.1 UC-02 — Tạo / Sửa Dự án

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Mã UC*],        [UC-02],
  [*Tên*],          [Tạo / Sửa Dự án],
  [*Tác nhân*],     [Manager],
  [*Mô tả*],        [Manager tạo hoặc sửa dự án với tên, ngày, trạng thái và ghi chú],
  [*Điều kiện trước*], [Người dùng có vai trò Manager trong `ZBUG_USERS`],
  [*Điều kiện sau*],  [Bản ghi mới/cập nhật trong `ZBUG_PROJECT`; PROJECT\_ID được tự tạo khi tạo mới (định dạng PRJ0000001)],
  [*Luồng bình thường*], [1. Manager nhấn "Tạo Dự án" trên Màn hình 0400 \n 2. Màn hình 0500 mở ở chế độ Tạo \n 3. Manager điền PROJECT\_NAME, START\_DATE, END\_DATE, PROJECT\_MANAGER, PROJECT\_STATUS, NOTE \n 4. Manager nhấn "Lưu" \n 5. PROJECT\_ID được tự tạo; bản ghi được lưu; chế độ chuyển sang Change],
  [*Luồng ngoại lệ*], [PROJECT\_NAME trống → lỗi "Tên Dự án là bắt buộc." \n Đặt trạng thái = 3 (Done) khi còn lỗi chưa đóng → lỗi "Không thể đặt dự án sang Done. N lỗi chưa Resolved/Closed."],
)

==== 2.2.2 UC-03 — Quản lý Thành viên Dự án

#table(
  columns: (3cm, 1fr),
  align: (left, left),
  [*Mã UC*],        [UC-03],
  [*Tên*],          [Quản lý Thành viên Dự án],
  [*Tác nhân*],     [Manager],
  [*Mô tả*],        [Manager thêm hoặc xóa người dùng khỏi dự án với vai trò cụ thể (M/D/T)],
  [*Điều kiện trước*], [Dự án đã được lưu trong `ZBUG_PROJECT`; người dùng đích tồn tại trong `ZBUG_USERS`],
  [*Điều kiện sau*],  [Bản ghi trong `ZBUG_USER_PROJEC` được tạo hoặc xóa],
  [*Luồng ngoại lệ*], [Không tìm thấy người dùng trong `ZBUG_USERS` → lỗi \n Người dùng trùng lặp → lỗi \n Vai trò không hợp lệ → lỗi],
)

== 3. Yêu cầu Giao diện

=== 3.1 Tìm kiếm Dự án (Màn hình 0410 — Màn hình ban đầu)

Màn hình ban đầu hiển thị khi người dùng chạy T-code `ZBUG_WS`. Lọc danh sách dự án trước khi hiển thị.

*Yêu cầu giao diện:*

#table(
  columns: (auto, 3cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*STT*], [*Trường*], [*Mô tả*], [*Bắt buộc*],
  [1], [`S_PRJ_ID` (Project ID)],         [Select-options: lọc theo project ID, F4 từ `ZBUG_PROJECT`], [Không],
  [2], [`S_PRJ_MN` (Project Manager)],    [Select-options: lọc theo user ID manager, F4 từ `ZBUG_USERS`], [Không],
  [3], [`S_PRJ_ST` (Project Status)],     [Select-options: lọc theo trạng thái (1/2/3/4), F4 giá trị domain], [Không],
)

GUI Status `STATUS_0410`: Execute (F8), Back (F3), Exit (Shift+F3), Cancel (F12).

=== 3.2 Danh sách Lỗi (Màn hình 0200)

Hiển thị tất cả lỗi cho dự án đã chọn (hoặc "Lỗi của tôi" được lọc theo vai trò). Hiển thị Dashboard Header phía trên ALV grid.

*Các trường Dashboard Header:* Tổng lỗi, theo trạng thái (Mới/Đã phân công/Đang xử lý/Đã sửa/Kiểm tra cuối/Đã giải quyết/Waiting/Tạm dừng/Từ chối), theo ưu tiên (C/T/R), theo module.

*Các cột ALV:* BUG\_ID (hotspot), TITLE, SAP\_MODULE, PRIORITY, STATUS\_TEXT, BUG\_TYPE, TESTER\_ID, DEV\_ID, CREATED\_AT, ATT\_REPORT (hotspot), ATT\_FIX (hotspot), ATT\_VERIFY (hotspot).

*Mã màu:* Trường Status được tô màu theo mã màu SAP (Mới = xanh dương C510, Đã phân công = cam C710, Đang xử lý = tím C610, Đã sửa = xanh lá C510, v.v.).

=== 3.3 Chi tiết Lỗi (Màn hình 0300 — Tab Strip)

Tab strip với 6 màn hình con. Trường STATUS luôn bị khóa (nhóm màn hình `STS`); thay đổi chỉ qua Màn hình 0370.

#table(
  columns: (1.5cm, 2.5cm, 1fr, 2cm),
  align: (center, left, left, center),
  [*Tab*], [*Màn hình con*], [*Nội dung*], [*Trình soạn thảo*],
  [1], [0310 Bug Info],      [Tất cả trường lỗi + mô tả mini (`CC_DESC_MINI`)],            [Chuẩn],
  [2], [0320 Mô tả],         [Mô tả đầy đủ (Long Text Z001, `CC_DESC`)],                  [`cl_gui_textedit`],
  [3], [0330 Ghi chú Dev],   [Ghi chú sửa lỗi của Developer (Long Text Z002, `CC_DEVNOTE`)], [`cl_gui_textedit`],
  [4], [0340 Ghi chú Tester],[Ghi chú xác minh của Tester (Long Text Z003, `CC_TSTRNOTE`)], [`cl_gui_textedit`],
  [5], [0350 Bằng chứng],    [ALV tải lên / tải xuống bằng chứng (`CC_EVIDENCE`)],         [ALV Grid],
  [6], [0360 Lịch sử],       [Nhật ký thay đổi từ `ZBUG_HISTORY` (`CC_HISTORY`, chỉ đọc)],[ALV Grid chỉ đọc],
)

=== 3.4 Popup Chuyển trạng thái (Màn hình 0370 — Mới v5.0)

Hộp thoại modal popup được kích hoạt bởi nút "Thay đổi Trạng thái" trên Màn hình 0300.

*Trường chỉ đọc:* BUG\_ID, TITLE, REPORTER, CURRENT\_STATUS.

*Trường nhập liệu (bật/khóa theo trạng thái hiện tại):*

#table(
  columns: (2.5cm, 2cm, 2cm, 3.5cm, 2.5cm, 1.5cm),
  align: (left, center, center, center, center, center),
  [*Trạng thái hiện tại*], [*NEW\_STATUS*], [*DEV\_ID*], [*FINAL\_TESTER\_ID*], [*TRANS\_NOTE*], [*Tải lên*],
  [1 — Mới],             [2, W],    [Mở (→2)],   [Khóa],         [Khóa],         [Khóa],
  [W — Waiting],         [2, 6],    [Mở],        [Mở (→6)],      [Khóa],         [Khóa],
  [2 — Đã phân công],    [3, R],    [Khóa],      [Khóa],         [Mở (→R)],      [Khóa],
  [3 — Đang xử lý],      [5, 4, R], [Khóa],      [Khóa],         [Mở],           [Mở (→5)],
  [4 — Tạm dừng],        [2],       [Mở],        [Khóa],         [Khóa],         [Khóa],
  [6 — Kiểm tra cuối],   [V, 3],    [Khóa],      [Khóa],         [Mở (→V)],      [Khóa],
)

GUI Status `STATUS_0370`: CONFIRM, UP\_TRANS (tải lên bằng chứng), CANCEL (F12).

== 4. Yêu cầu Phi chức năng

=== 4.1 Giao diện Ngoài

- *Giao diện người dùng:* Chỉ SAP GUI (Dynpro) — Màn hình Module Pool truy cập qua T-code `ZBUG_WS`
- *Email:* SAP CL\_BCS API với SMTP relay qua SCOT. Người nhận xác định theo loại sự kiện (tạo, phân công, thay đổi trạng thái, từ chối)
- *Lưu trữ file:* File bằng chứng lưu trong bảng tùy chỉnh `ZBUG_EVIDENCE` (trường nội dung RAWSTRING). Mẫu trong SMW0 (đối tượng `ZBT_TMPL_01`, `ZBT_TMPL_02`, `ZBT_TMPL_03`)
- *In:* SmartForms `ZBUG_FORM` (PDF chi tiết lỗi) và `ZBUG_EMAIL_FORM` (nội dung email HTML)

=== 4.2 Thuộc tính Chất lượng

#table(
  columns: (auto, 2cm, 1fr, 1.5cm),
  align: (center, left, left, center),
  [*STT*], [*Thuộc tính*], [*Yêu cầu*], [*Ưu tiên*],
  [1], [Hiệu suất],    [Màn hình ALV tải ≤ 3 giây trên S40 với ≤ 1000 bản ghi lỗi], [Cao],
  [2], [Bảo mật],      [Thực thi vai trò qua kiểm tra bảng `ZBUG_USERS` trên mọi màn hình/hành động; không thể bypass vai trò], [Quan trọng],
  [3], [Kiểm toán],    [Mọi thay đổi trạng thái, phân công và tải lên bằng chứng đều tạo bản ghi trong `ZBUG_HISTORY`], [Cao],
  [4], [Độ tin cậy],   [COMMIT WORK / ROLLBACK WORK được dùng trong tất cả thao tác lưu; không lưu một phần], [Cao],
  [5], [Khả năng sử dụng], [Trường bắt buộc được làm nổi bật; popup xác nhận khi xóa/quay lại mà chưa lưu; F4 help trên tất cả trường FK], [Trung bình],
  [6], [Tương thích],  [Chạy trên SAP ABAP 7.70 (SAP\_BASIS 770); SAP GUI 7.50+], [Cao],
)

== 5. Phụ lục Yêu cầu

=== 5.1 Quy tắc Nghiệp vụ

#table(
  columns: (1.5cm, 1fr),
  align: (center, left),
  [*Mã quy tắc*], [*Mô tả*],
  [BR-01], [Mỗi lỗi phải thuộc đúng một dự án (`PROJECT_ID` là bắt buộc và bị khóa sau khi tạo)],
  [BR-02], [BUG\_ID được tự tạo qua Number Range `ZNRO_BUG` (định dạng: `BUG` + 7 chữ số NUMC); không thể nhập thủ công],
  [BR-03], [Trường STATUS luôn bị khóa trên Màn hình 0300; thay đổi trạng thái chỉ có thể qua Màn hình 0370 (popup)],
  [BR-04], [Chuyển sang "Đã sửa (5)" yêu cầu ít nhất một file bằng chứng trong `ZBUG_EVIDENCE` (COUNT > 0)],
  [BR-05], [Chuyển sang "Đã giải quyết (V)" yêu cầu `TRANS_NOTE` phải được điền (ghi chú xác nhận không trống)],
  [BR-06], [Chuyển sang "Từ chối (R)" hoặc "Đang xử lý→Tạm dừng" yêu cầu `TRANS_NOTE` (lý do từ chối/chặn)],
  [BR-07], [Tự động phân công chọn developer có khối lượng công việc đang hoạt động thấp nhất (lỗi ở trạng thái 2, 3, 4, 6) VÀ workload < 5; nếu không tìm thấy → STATUS = 'W' (Waiting)],
  [BR-08], [Đặt trạng thái dự án thành "Done (3)" bị chặn nếu có lỗi nào trong dự án có STATUS không thuộc {V, 7, R}],
  [BR-09], [File bằng chứng: định dạng phải là `.xlsx`; kích thước tối đa 10 MB; tải lên sau STATUS = 'V' (Resolved) bị chặn],
  [BR-10], [Manager tuân theo cùng ma trận chuyển đổi như các vai trò khác (không có bypass); tất cả chuyển đổi phải tuân theo Đặc tả Vòng đời Trạng thái v5.0],
)

=== 5.2 Yêu cầu Chung

- Tất cả màn hình hiển thị thanh tiêu đề xác định màn hình hiện tại và ngữ cảnh (tên dự án, bug ID)
- Nút Back (F3) kiểm tra thay đổi chưa lưu; hiển thị popup xác nhận trước khi rời đi
- Tất cả thao tác XÓA sử dụng xóa mềm (`IS_DEL = 'X'`); không xóa vật lý hàng
- ALV grid hỗ trợ: sắp xếp, lọc, xuất Excel (tích hợp), tính tổng, tìm kiếm
- Tất cả timestamp sử dụng trường hệ thống SAP: `SY-DATUM`, `SY-UZEIT`, `SY-UNAME`

=== 5.3 Danh sách Thông báo Ứng dụng

#table(
  columns: (2cm, 1fr, 1.5cm),
  align: (center, left, center),
  [*Lớp thông báo*], [*Nội dung thông báo*], [*Loại*],
  [`ZBUG_MSG`], [Đã lưu lỗi thành công.],                                       [S (thành công)],
  [`ZBUG_MSG`], [Vui lòng chọn một lỗi trước.],                                 [E (lỗi)],
  [`ZBUG_MSG`], [Chuyển đổi trạng thái không được phép cho vai trò của bạn.],   [E],
  [`ZBUG_MSG`], [Cần có bằng chứng trước khi đánh dấu là Đã sửa.],              [E],
  [`ZBUG_MSG`], [Ghi chú chuyển đổi là bắt buộc cho thay đổi trạng thái này.], [E],
  [`ZBUG_MSG`], [Không thể đặt dự án sang Done. \{N\} lỗi chưa Resolved/Closed.], [E],
  [`ZBUG_MSG`], [Không tìm thấy người dùng \{uid\} trong hệ thống.],            [E],
  [`ZBUG_MSG`], [Chỉ manager mới có thể tạo/xóa dự án.],                       [E],
  [`ZBUG_MSG`], [Đã lưu dự án thành công.],                                     [S],
  [`ZBUG_MSG`], [Đã tự động phân công cho developer \{dev\_id\}.],              [S],
  [`ZBUG_MSG`], [Không tìm thấy developer khả dụng. Đặt trạng thái sang Waiting.], [W (cảnh báo)],
  [`ZBUG_MSG`], [Đã gửi email thành công.],                                     [S],
)

=== 5.4 Yêu cầu Khác

- *Number Range:* `ZNRO_BUG` --- khoảng 01, từ 0000000001 đến 9999999999, định dạng đầu ra `BUG` + NUMC(7)
- *Long Text Object:* `ZBUG_NOTE` (tạo qua SE75) với text ID Z001 (Mô tả), Z002 (Ghi chú Dev), Z003 (Ghi chú Tester)
- *SAP Text Object:* tên text = BUG\_ID (ví dụ: `BUG0000001`); lưu qua `SAVE_TEXT` / đọc qua `READ_TEXT`
