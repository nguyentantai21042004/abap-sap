// ============================================================
// 01_overview.typ — TỔNG QUAN
// ============================================================
#import "../template.typ": placeholder, hline

= TỔNG QUAN

== Bảng Thuật ngữ

#table(
  columns: (3.5cm, 1fr, 3cm),
  align: (left, left, left),
  [*Thuật ngữ*], [*Định nghĩa*], [*Ghi chú*],
  [ABAP],         [Advanced Business Application Programming — ngôn ngữ lập trình riêng của SAP], [],
  [ALV],          [ABAP List Viewer — thành phần hiển thị lưới/danh sách tiêu chuẩn của SAP], [],
  [BCS],          [Business Communication Services — API SAP để gửi email], [],
  [Bug],          [Lỗi hoặc sự cố được phát hiện trong quá trình kiểm thử phần mềm], [],
  [BUG_ID],       [Mã định danh duy nhất cho bản ghi lỗi, định dạng: BUG0000001 (tự động tạo)], [],
  [Custom Control],[Vùng trên màn hình Dynpro dành riêng cho các điều khiển GUI (ALV, TextEdit)], [],
  [DEV],          [Developer (Nhà phát triển) — vai trò chịu trách nhiệm sửa lỗi], [],
  [Dynpro],       [Dynamic Program — công nghệ màn hình SAP (còn gọi là Dynscreen)], [],
  [Evidence],     [Tệp bằng chứng (Excel .xlsx) tải lên để xác nhận báo cáo lỗi, bản vá, hoặc xác minh], [],
  [F4 Help],      [Tra cứu SAP — dropdown/popup để chọn giá trị trường], [],
  [Final Testing],[Trạng thái `6` — lỗi đã được sửa, Final Tester đang xác minh], [],
  [GOS],          [Generic Object Services — khung SAP để đính kèm tệp vào bản ghi], [],
  [GUI Status],   [Định nghĩa thanh công cụ/menu SAP cho một màn hình (tạo trong SE41)], [],
  [In Progress],  [Trạng thái `3` — Developer đang tích cực xử lý lỗi], [],
  [MGR],          [Manager (Quản lý) — vai trò có quyền truy cập toàn hệ thống], [],
  [Module Pool],  [Chương trình ABAP loại M — nền tảng của ứng dụng màn hình SAP phức tạp], [],
  [New],          [Trạng thái `1` — lỗi vừa được tạo, chưa được phân công], [],
  [Package],      [`ZBUGTRACK` — gói phát triển SAP nhóm tất cả các đối tượng], [],
  [PAI],          [Process After Input — sự kiện màn hình được kích hoạt sau thao tác người dùng], [],
  [PBO],          [Process Before Output — sự kiện màn hình được kích hoạt trước khi hiển thị], [],
  [Pending],      [Trạng thái `4` — tạm thời bị chặn, đang chờ thông tin], [],
  [Project],      [Dự án phát triển nhóm các lỗi liên quan (bảng: ZBUG_PROJECT)], [],
  [Rejected],     [Trạng thái `R` — Developer từ chối phân công lỗi], [],
  [Resolved],     [Trạng thái `V` — Final Tester xác nhận bản vá; trạng thái kết thúc], [],
  [SE11],         [Data Dictionary SAP — công cụ tạo bảng, domain, data element], [],
  [SE38/SE80],    [ABAP Workbench SAP — trình soạn thảo code], [],
  [SE41],         [Menu Painter SAP — công cụ tạo GUI Status và Title Bar], [],
  [SE51],         [Screen Painter SAP — công cụ tạo màn hình Dynpro], [],
  [SE93],         [Transaction Maintenance SAP — để tạo/sửa T-code], [],
  [SmartForm],    [Công cụ in biểu mẫu SAP — dùng cho báo cáo PDF và nội dung email], [],
  [T-Code],       [Transaction Code — phím tắt SAP để khởi chạy chương trình (ví dụ: ZBUG_WS)], [],
  [Tester],       [Vai trò chịu trách nhiệm báo cáo lỗi và xác minh bản vá], [],
  [Waiting],      [Trạng thái `W` — không tìm thấy Dev/Tester phù hợp; đang chờ Manager phân công], [],
  [Workload],     [Số lỗi đang hoạt động (trạng thái 2/3/4/6) được phân công cho người dùng], [],
  [ZBUG_WS],      [T-Code điểm vào của hệ thống Bug Tracking], [],
)

== Quy ước Ký hiệu Lưu đồ

#table(
  columns: (4cm, 1fr),
  align: (center, left),
  [*Hình dạng*], [*Ý nghĩa / Cách dùng*],
  [Hình chữ nhật (đường viền liền)],  [Bước xử lý / Hành động hệ thống (ví dụ: Tự động phân công, Lưu bản ghi)],
  [Hình thoi],                        [Quyết định / Nhánh điều kiện (ví dụ: Bug Type = Code hay Config?)],
  [Hình chữ nhật bo tròn (oval)],     [Trạng thái bắt đầu / kết thúc],
  [Hình bình hành],                   [Đầu vào từ người dùng / Đầu ra cho người dùng],
  [Mũi tên đứt nét],                  [Luồng có điều kiện (chỉ trong điều kiện nhất định)],
  [Mũi tên liền],                     [Luồng tuần tự bình thường],
  [Hình chữ nhật viền đậm],           [Bước tự động hóa hệ thống (không cần tương tác người dùng)],
)
