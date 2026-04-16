// ============================================================
// 04_design.typ — IV. Mô tả Thiết kế Phần mềm
// ============================================================
#import "../template.typ": placeholder, hline, field, diagram-placeholder

= IV. Mô tả Thiết kế Phần mềm

== 1. Thiết kế Hệ thống

=== 1.1 Kiến trúc Hệ thống

`ZBUG_WS` sử dụng kiến trúc ba tầng chạy hoàn toàn trong SAP:

#diagram-placeholder("Kiến trúc Hệ thống (3 tầng)", "docs/diagrams/system-architecture.mmd")

Module Pool gọi Function Module cho tất cả logic nghiệp vụ — không có logic ABAP nào được code trực tiếp trong module PBO/PAI ngoài điều hướng màn hình và gọi FM.

=== 1.2 Sơ đồ Gói

Tất cả đối tượng thuộc gói phát triển SAP `ZBUGTRACK`:

#diagram-placeholder("Sơ đồ Gói: ZBUGTRACK", "docs/diagrams/package-diagram.mmd")

== 2. Thiết kế Cơ sở Dữ liệu

Quan hệ thực thể: `ZBUG_TRACKER` (1:N với `ZBUG_HISTORY`, 1:N với `ZBUG_EVIDENCE`) thuộc về `ZBUG_PROJECT` (M:N với `ZBUG_USERS` qua `ZBUG_USER_PROJEC`).

=== Bảng: ZBUG\_TRACKER — 29 trường

#table(
  columns: (auto, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Trường*], [*Kiểu*], [*Độ dài*], [*Mô tả*],
  [1],  [`MANDT`],            [CLNT], [3],  [Client (Khóa)],
  [2],  [`BUG_ID`],           [CHAR], [10], [Bug ID — Khóa, tự tạo (`BUG0000001`)],
  [3],  [`TITLE`],            [CHAR], [100],[Tiêu đề lỗi — bắt buộc],
  [4],  [`DESC_TEXT`],        [STRING],[0], [Mô tả đầy đủ — lưu dạng long text Z001],
  [5],  [`SAP_MODULE`],       [CHAR], [20], [Module SAP (MM, SD, FI, CO, v.v.)],
  [6],  [`PRIORITY`],         [CHAR], [1],  [H=Cao, M=Trung bình, L=Thấp],
  [7],  [`STATUS`],           [CHAR], [20], [Trạng thái lỗi — vòng đời 10 trạng thái (CHAR 20, KHÔNG phải CHAR 1)],
  [8],  [`BUG_TYPE`],         [CHAR], [1],  [C=Lỗi code (Dev sửa), F=Lỗi cấu hình (Tester tự sửa)],
  [9],  [`REASONS`],          [STRING],[0], [Nguyên nhân gốc / ghi chú chuyển đổi — kiểu STRING],
  [10], [`TESTER_ID`],        [CHAR], [12], [Người báo cáo — tự điền SY-UNAME khi tạo],
  [11], [`VERIFY_TESTER_ID`], [CHAR], [12], [Tester cuối được phân công cho giai đoạn kiểm tra (tự động phân công Giai đoạn B)],
  [12], [`DEV_ID`],           [CHAR], [12], [Developer được phân công — tự động phân công Giai đoạn A],
  [13], [`APPROVED_BY`],      [CHAR], [12], [Manager phê duyệt (đặt khi đóng)],
  [14], [`APPROVED_AT`],      [DATS], [8],  [Ngày phê duyệt],
  [15], [`CREATED_AT`],       [DATS], [8],  [Ngày tạo — tự SY-DATUM],
  [16], [`CREATED_TIME`],     [TIMS], [6],  [Giờ tạo — tự SY-UZEIT],
  [17], [`CLOSED_AT`],        [DATS], [8],  [Ngày đóng (đặt khi trạng thái → Resolved/Closed)],
  [18], [`ATT_REPORT`],       [CHAR], [100],[Đường dẫn/tên file bằng chứng báo cáo lỗi],
  [19], [`ATT_FIX`],          [CHAR], [100],[Đường dẫn/tên file bằng chứng xác nhận sửa lỗi],
  [20], [`ATT_VERIFY`],       [CHAR], [100],[Đường dẫn/tên file bằng chứng xác nhận kiểm tra cuối],
  [21], [`PROJECT_ID`],       [CHAR], [20], [FK → ZBUG\_PROJECT; khóa sau khi tạo],
  [22], [`SEVERITY`],         [CHAR], [1],  [1=Dump, 2=Rất cao, 3=Cao, 4=Bình thường, 5=Nhỏ],
  [23], [`ERNAM`],            [CHAR], [12], [Tạo bởi — tự SY-UNAME],
  [24], [`ERDAT`],            [DATS], [8],  [Ngày tạo],
  [25], [`ERZET`],            [TIMS], [6],  [Giờ tạo],
  [26], [`AENAM`],            [CHAR], [12], [Người thay đổi cuối],
  [27], [`AEDAT`],            [DATS], [8],  [Ngày thay đổi cuối],
  [28], [`AEZET`],            [TIMS], [6],  [Giờ thay đổi cuối],
  [29], [`IS_DEL`],           [CHAR], [1],  [Cờ xóa mềm — 'X' = đã xóa],
)

=== Bảng: ZBUG\_USERS — 12 trường

#table(
  columns: (auto, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Trường*], [*Kiểu*], [*Độ dài*], [*Mô tả*],
  [1], [`MANDT`],             [CLNT], [3],  [Client (Khóa)],
  [2], [`USER_ID`],           [CHAR], [12], [Tên người dùng SAP (Khóa)],
  [3], [`ROLE`],              [CHAR], [1],  [M=Manager, D=Developer, T=Tester],
  [4], [`FULL_NAME`],         [CHAR], [50], [Họ tên đầy đủ],
  [5], [`SAP_MODULE`],        [CHAR], [20], [Module SAP người dùng chuyên về (để khớp tự động phân công)],
  [6], [`AVAILABLE_STATUS`],  [CHAR], [1],  [A=Sẵn sàng, B=Bận, L=Nghỉ, W=Đang làm],
  [7], [`IS_ACTIVE`],         [CHAR], [1],  [X=Đang hoạt động; dùng để lọc trong F4 và tự động phân công],
  [8], [`EMAIL`],             [CHAR], [100],[Địa chỉ email cho thông báo CL\_BCS],
  [9], [`AENAM`],             [CHAR], [12], [Người thay đổi cuối],
  [10],[`AEDAT`],             [DATS], [8],  [Ngày thay đổi cuối],
  [11],[`AEZET`],             [TIMS], [6],  [Giờ thay đổi cuối],
  [12],[`IS_DEL`],            [CHAR], [1],  [Cờ xóa mềm],
)

=== Bảng: ZBUG\_PROJECT — 16 trường

#table(
  columns: (auto, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Trường*], [*Kiểu*], [*Độ dài*], [*Mô tả*],
  [1], [`MANDT`],           [CLNT], [3],   [Client (Khóa)],
  [2], [`PROJECT_ID`],      [CHAR], [20],  [Project ID (Khóa) — tự tạo (`PRJ0000001`)],
  [3], [`PROJECT_NAME`],    [CHAR], [100], [Tên dự án — bắt buộc],
  [4], [`DESCRIPTION`],     [CHAR], [255], [Mô tả dự án],
  [5], [`START_DATE`],      [DATS], [8],   [Ngày bắt đầu dự án],
  [6], [`END_DATE`],        [DATS], [8],   [Ngày kết thúc dự án],
  [7], [`PROJECT_MANAGER`], [CHAR], [12],  [User ID Manager (FK → ZBUG\_USERS)],
  [8], [`PROJECT_STATUS`],  [CHAR], [1],   [1=Mở, 2=Đang xử lý, 3=Hoàn thành, 4=Đã hủy],
  [9], [`NOTE`],            [CHAR], [255], [Ghi chú tự do],
  [10],[`ERNAM`],           [CHAR], [12],  [Tạo bởi],
  [11],[`ERDAT`],           [DATS], [8],   [Ngày tạo],
  [12],[`ERZET`],           [TIMS], [6],   [Giờ tạo],
  [13],[`AENAM`],           [CHAR], [12],  [Người thay đổi cuối],
  [14],[`AEDAT`],           [DATS], [8],   [Ngày thay đổi cuối],
  [15],[`AEZET`],           [TIMS], [6],   [Giờ thay đổi cuối],
  [16],[`IS_DEL`],          [CHAR], [1],   [Cờ xóa mềm],
)

=== Bảng: ZBUG\_USER\_PROJEC — 10 trường

Ánh xạ người dùng vào dự án với vai trò theo dự án. Khóa: MANDT + USER\_ID + PROJECT\_ID.

Lưu ý: tên bảng là `ZBUG_USER_PROJEC` (bị cắt ngắn ở 18 ký tự — không có chữ 'T' cuối).

=== Bảng: ZBUG\_HISTORY — 10 trường

#table(
  columns: (auto, 3cm, 1.5cm, 1.5cm, 1fr),
  align: (center, left, center, center, left),
  [*\#*], [*Trường*], [*Kiểu*], [*Độ dài*], [*Mô tả*],
  [1], [`MANDT`],        [CLNT], [3],  [Client (Khóa)],
  [2], [`LOG_ID`],       [NUMC], [10], [Log ID tự tạo (Khóa)],
  [3], [`BUG_ID`],       [CHAR], [10], [FK → ZBUG\_TRACKER],
  [4], [`CHANGED_BY`],   [CHAR], [12], [Người thực hiện thay đổi — SY-UNAME],
  [5], [`CHANGED_AT`],   [DATS], [8],  [Ngày thay đổi],
  [6], [`CHANGED_TIME`], [TIMS], [6],  [Giờ thay đổi],
  [7], [`ACTION_TYPE`],  [CHAR], [2],  [CR=Tạo, AS=Phân công, RS=Phân công lại, ST=Thay đổi trạng thái, UP=Cập nhật, DL=Xóa, AT=Đính kèm],
  [8], [`OLD_VALUE`],    [CHAR], [100],[Giá trị cũ],
  [9], [`NEW_VALUE`],    [CHAR], [100],[Giá trị mới],
  [10],[`REASON`],       [STRING],[0], [Lý do / ghi chú chuyển đổi — kiểu STRING],
)

== 3. Thiết kế Chi tiết

=== 3.1 Tạo Lỗi (UC-05)

Luồng tạo lỗi liên quan đến module PAI, FM `Z_BUG_CREATE` và engine tự động phân công. Trình tự là:

+ Người dùng điền các trường trên Màn hình 0300 (chế độ Tạo) và nhấn "Lưu"
+ PAI gọi `Z_BUG_CHECK_PERMISSION` — xác minh vai trò = 'T' hoặc 'M'
+ PAI gọi `Z_BUG_CREATE`:
  - Gọi `NUMBER_GET_NEXT` trên `ZNRO_BUG` → tạo BUG\_ID
  - Đặt TESTER\_ID = SY-UNAME, ERNAM, ERDAT, ERZET, STATUS = '1'
  - Nếu BUG\_TYPE = 'F' (Cấu hình): DEV\_ID = SY-UNAME, STATUS = '2'
  - Gọi `SAVE_TEXT` cho mô tả (Text ID Z001)
  - Chèn vào `ZBUG_TRACKER`
  - Gọi `Z_BUG_LOG_HISTORY` (action = 'CR')
  - Nếu BUG\_TYPE = 'C': gọi `Z_BUG_AUTO_ASSIGN` (Giai đoạn A)
  - Gọi `Z_BUG_SEND_EMAIL` (event = 'CREATE' hoặc 'ASSIGN')
  - COMMIT WORK

=== 3.2 Chuyển đổi Trạng thái (UC-08)

Luồng thay đổi trạng thái thực thi ma trận chuyển đổi theo vai trò qua Màn hình 0370:

+ Người dùng nhấn "Thay đổi Trạng thái" trên Màn hình 0300
+ PAI gọi `CALL SCREEN 0370 STARTING AT 5 5` (popup modal)
+ PBO của 0370 tải thông tin lỗi hiện tại và xác định trường nào bật/khóa dựa trên STATUS hiện tại
+ Người dùng chọn trạng thái mới, điền trường bắt buộc và nhấn "Xác nhận"
+ PAI của 0370 gọi `Z_BUG_CHECK_PERMISSION` (action = 'UPDATE\_STATUS')
+ Xác thực chuyển đổi theo ma trận chuyển đổi theo vai trò v5.0
+ Nếu STATUS → '5' (Đã sửa): xác minh bằng chứng tồn tại trong `ZBUG_EVIDENCE` (COUNT > 0)
+ Nếu STATUS → 'V' hoặc 'R': xác minh TRANS\_NOTE không trống
+ Gọi `Z_BUG_UPDATE_STATUS` → cập nhật `ZBUG_TRACKER`, gọi `Z_BUG_LOG_HISTORY` (action = 'ST')
+ Nếu STATUS → '5': gọi tự động phân công Giai đoạn B (Đã sửa → Kiểm tra cuối hoặc Waiting)
+ Gọi `Z_BUG_SEND_EMAIL` (event = 'STATUS\_CHANGE')

=== 3.3 Engine Tự động Phân công

Engine tự động phân công được triển khai trong FM `Z_BUG_AUTO_ASSIGN` và được gọi tại hai điểm:

*Giai đoạn A (khi tạo lỗi, BUG\_TYPE = 'C'):*
- SELECT Dev từ `ZBUG_USER_PROJEC` WHERE project\_id = bug.project\_id AND role = 'D'
- JOIN `ZBUG_USERS` WHERE sap\_module = bug.sap\_module AND is\_active = 'X' AND is\_del ≠ 'X'
- Với mỗi dev: COUNT lỗi WHERE dev\_id = dev AND STATUS IN ('2','3','4','6')
- Chọn dev có count thấp nhất VÀ count < 5
- Nếu tìm thấy: đặt DEV\_ID, STATUS = '2', ghi lịch sử, gửi email
- Nếu không tìm thấy: STATUS = 'W', thông báo Manager

*Giai đoạn B (khi trạng thái → Đã sửa):*
- SELECT Tester từ `ZBUG_USER_PROJEC` WHERE project\_id = bug.project\_id AND role = 'T'
- JOIN `ZBUG_USERS` WHERE sap\_module = bug.sap\_module AND is\_active = 'X'
- Với mỗi tester: COUNT lỗi WHERE verify\_tester\_id = tester AND STATUS = '6'
- Chọn tester có count thấp nhất VÀ count < 5
- Nếu tìm thấy: đặt VERIFY\_TESTER\_ID, STATUS = '6', ghi lịch sử, gửi email
- Nếu không tìm thấy: STATUS = 'W', thông báo Manager

=== 3.4 Kiểm soát Màn hình theo Vai trò (LOOP AT SCREEN)

Khóa trường động được triển khai trong MODULE `modify_screen_0300 OUTPUT` sử dụng nhóm màn hình:

#table(
  columns: (2cm, 2.5cm, 1fr),
  align: (center, left, left),
  [*Nhóm*], [*Trường*], [*Điều kiện khóa*],
  [`STS`], [STATUS],                                   [Luôn khóa — chỉ thay đổi qua popup 0370],
  [`BID`], [BUG\_ID],                                  [Luôn khóa — tự tạo],
  [`PRJ`], [PROJECT\_ID],                              [Khóa sau khi đặt từ ngữ cảnh dự án],
  [`FNC`], [BUG\_TYPE, PRIORITY, SEVERITY],            [Khóa với vai trò Developer],
  [`TST`], [TESTER\_ID],                               [Khóa với vai trò Developer],
  [`DEV`], [DEV\_ID, VERIFY\_TESTER\_ID],              [Khóa với vai trò Tester],
  [`EDT`], [Tất cả trường có thể chỉnh sửa],           [Khóa ở chế độ Display (input = 0)],
)

Module PBO đánh giá `gv_role` (tải từ `ZBUG_USERS` khi đăng nhập) và đặt `screen-input = 0` cho tất cả trường trong các nhóm bị khóa qua `LOOP AT SCREEN ... MODIFY SCREEN`.
