
## PHẦN 1: THIẾT KẾ MÀN HÌNH TÌM KIẾM DỰ ÁN (SCREEN 0410)

Để tăng trải nghiệm, chúng ta sẽ thêm một màn hình chặn trước khi vào danh sách dự án.
Màn hình này giúp lọc dữ liệu ngay từ đầu, tránh việc load quá nhiều dữ liệu không cần thiết.

- Các trường dữ liệu (Search Fields):
  - Mã Dự án (S_PRJ_ID): Kiểu ZBT_DE_PRJ_ID, hỗ trợ tìm kiếm theo khoảng hoặc một mã cụ thể.
  - Người Quản lý (S_PRJ_MN): Kiểu UNAME, tự động gợi ý danh sách Manager.
  - Trạng thái Dự án (S_PRJ_ST): Một Dropdown list đa chọn hoặc danh sách 4 trạng thái (Opening, In Process, Done, Cancel).
- Đặc điểm kỹ thuật:
  - Search Help (F4): Tất cả các trường đều được gắn Search Help từ bảng Master dữ liệu (ZBT_PROJECT).

- Logic "Chạy tất cả": Nếu người dùng để trống toàn bộ các ô lọc và nhấn "Execute":
 	- Hệ thống sẽ lấy toàn bộ danh sách dự án.
 	- Ràng buộc bảo mật: Dù lọc thế nào, SQL sẽ luôn có điều kiện INNER JOIN với bảng ZBT_USER_PRJ để đảm bảo User chỉ thấy dự án mình tham gia (trừ Manager hệ thống thấy hết).
- Giao diện: Thiết kế dưới dạng một Popup hoặc Subscreen nằm gọn trong màn hình chính.

## PHẦN 2: THIẾT KẾ BẢNG ĐIỀU KHIỂN BUG (DASHBOARD HEADER)

Tại màn hình Danh sách Bug (Screen 0200), chúng ta sẽ chia màn hình làm 2 phần: Phần trên (Header Dashboard) và Phần dưới (ALV Grid).

- Tiêu đề: "Bug Tracking Dashboard" (Font chữ đậm, cỡ lớn).
- Các khối thông số (Metrics Containers):
  Chúng ta sử dụng các ô văn bản (Text Fields) có màu sắc tương ứng với trạng thái để hiển thị số liệu thực tế:
  - Khối 1: Tổng quan số lượng
    - Tổng số Bug hiện tại: [Total_Count]
  - Khối 2: Thống kê theo Trạng thái (Status)
    - New: [Count], Assigned: [Count], In Progress: [Count], Fixed: [Count], Resolved: [Count], Closed: [Count], Rejected: [Count].
  - Khối 3: Thống kê theo Độ ưu tiên (Priority)
    - High: [Count], Medium: [Count], Low: [Count].
  - Khối 4: Thống kê theo Module SAP
    - FI: [Count], MM: [Count], SD: [Count], ABAP: [Count], Basis: [Count].

- Cơ chế cập nhật:
  - Mỗi khi dữ liệu ALV Grid bên dưới được lọc (Filter), các con số trên Dashboard sẽ tự động tính toán lại và cập nhật theo (Real-time update).
  - Sử dụng lệnh SELECT COUNT(*) kết hợp với GROUP BY trong ABAP để tối ưu tốc độ xử lý.

## PHẦN 3: ĐỔI TÊN VÀ QUẢN LÝ BIỂU MẪU (TEMPLATES)

Để đồng bộ với quy trình nghiệp vụ và giúp người dùng dễ nhận diện file khi tải xuống, hệ thống sẽ quản lý 3 loại Template chính trong SMW0 (SAP Web Repository):

| Tên cũ (Hệ thống) | Tên hiển thị mới (Download Name) | Mục đích sử dụng                   |
|-------------------|----------------------------------|------------------------------------|
| ZBT_TMPL_01       | Bug_report.xlsx                  | Dùng để báo cáo lỗi mới (cho Tester)|
| ZBT_TMPL_02       | fix_report.xlsx                  | Dành cho Developer upload bằng chứng đã sửa xong lỗi.|
| ZBT_TMPL_03       | confirm_report.xlsx              | Dành cho Final Tester xác nhận kết quả kiểm thử cuối.|

## PHẦN 4: THIẾT KẾ MÀN HÌNH CHUYỂN TRẠNG THÁI (POPUP SCREEN 0350)

Tại màn hình chi tiết Bug (Screen 0300), trường STATUS sẽ bị khóa hoàn toàn (INPUT = 0). Một nút bấm có nhãn "Thay đổi trạng thái" sẽ được đặt cạnh đó. Khi nhấn, một cửa sổ Popup (Screen 0350) hiện ra với các thành phần sau:

- Nhóm Thông tin hiển thị (Read-only):
 	- BUG_ID & TITLE: Để User biết đang thao tác đúng Bug.
 	- REPORTER: Hiển thị ID người đã báo lỗi.
 	- CURRENT_STATUS: Trạng thái hiện tại của Bug.
- Nhóm Thông tin điều khiển (Input/Action):
 	- NEW_STATUS: Một Dropdown List (chỉ chứa các trạng thái hợp lệ để chuyển tới).
 	- DEVELOPER_ID: Ô nhập ID người xử lý (kèm F4 Help).
 	- FINAL_TESTER_ID: Ô nhập ID người kiểm thử cuối (kèm F4 Help).
 	- TRANS_NOTE: Một vùng soạn thảo văn bản (Text Edit Control) để ghi chú cho bước chuyển này.
 	- BTN_UPLOAD: Nút tải lên bằng chứng (Evidence).

## PHẦN 5: CHI TIẾT LOGIC CHO TỪNG GIAI ĐOẠN (MATRIX LOGIC)

Dưới đây là bảng phân tích chi tiết "Tình thái" của màn hình Popup dựa trên trạng thái hiện tại của Bug:

- Khi Bug đang ở trạng thái: 1 - NEW (Mới tạo)
 	- Quyền thực hiện: Chỉ MANAGER.
 	- Trạng thái có thể chuyển tới: 2 - Assigned, W - Waiting.
 	- Mở/Khóa Field:
  		- DEVELOPER_ID: MỞ (Bắt buộc phải nhập nếu chọn chuyển sang Assigned).
  		- FINAL_TESTER_ID: KHÓA.
  		- TRANS_NOTE: KHÓA.
  		- BTN_UPLOAD: KHÓA.
 	- Ràng buộc: Nếu Manager nhấn lưu sang Assigned mà ô DEVELOPER_ID trống -> Báo lỗi đỏ.
- Khi Bug đang ở trạng thái: W - WAITING (Chờ gán thủ công)
 	- Quyền thực hiện: Chỉ MANAGER.
 	- Trạng thái có thể chuyển tới: 2 - Assigned, 6 - Final Testing.
 	- Mở/Khóa Field:
  		- DEVELOPER_ID: MỞ (Bắt buộc nếu sang Assigned hoặc Final Testing).
  		- FINAL_TESTER_ID: MỞ (Bắt buộc nếu sang Final Testing).
  		- TRANS_NOTE: KHÓA.
  		- BTN_UPLOAD: KHÓA.
 	- Ràng buộc: Để chuyển sang Final Testing, hệ thống kiểm tra phải có đủ cả ID Dev và ID Final Tester.

- Khi Bug đang ở trạng thái: 2 - ASSIGNED (Đã gán cho Dev)
 	- Quyền thực hiện: Chỉ DEVELOPER (người được gán) hoặc MANAGER.
 	- Trạng thái có thể chuyển tới: 3 - In Progress, R - Rejected.
 	- Mở/Khóa Field:
  		- DEVELOPER_ID: KHÓA.
  		- FINAL_TESTER_ID: KHÓA.
  		- TRANS_NOTE: MỞ (Bắt buộc nhập nếu chọn Rejected để ghi lý do từ chối).
  		- BTN_UPLOAD: KHÓA.
 	- Ghi chú: Nội dung trong TRANS_NOTE sẽ được lưu tự động vào Developer Note (Z002).
- Khi Bug đang ở trạng thái: 3 - IN PROGRESS (Đang sửa)
 	- Quyền thực hiện: Chỉ DEVELOPER (người được gán). MANAGER có quyền can thiệp nếu cần Reject.
 	- Trạng thái có thể chuyển tới: 5 - Fixed, 4 - Pending, R - Rejected.
 	- Mở/Khóa Field:
  		- DEVELOPER_ID: KHÓA.
  		- FINAL_TESTER_ID: KHÓA.
  		- TRANS_NOTE: MỞ (Dùng để ghi chú giải pháp sửa lỗi).
  		- BTN_UPLOAD: MỞ (Bắt buộc nếu muốn sang Fixed hoặc Pending).
 	- Ràng buộc tối quan trọng: Khi nhấn chuyển sang Fixed, hệ thống kiểm tra bảng Attachment. Nếu chưa có file nào được upload cho Bug này ở giai đoạn hiện tại -> Chặn lại và yêu cầu: "Cần file bằng chứng (Evidence) để xác nhận đã sửa lỗi".

- Khi Bug đang ở trạng thái: 4 - PENDING (Tạm dừng)
 	- Quyền thực hiện: Chỉ MANAGER.
 	- Trạng thái có thể chuyển tới: 2 - Assigned.
 	- Mở/Khóa Field:
  		- DEVELOPER_ID: MỞ (Manager có thể chọn Dev cũ hoặc đổi Dev mới).
  		- FINAL_TESTER_ID: KHÓA.
  		- TRANS_NOTE: KHÓA.
  		- BTN_UPLOAD: KHÓA.
 	- Ràng buộc: Bắt buộc có chọn 1 Dev mới được nhấn Lưu.

- Khi Bug đang ở trạng thái: 6 - FINAL TESTING (Kiểm thử cuối)
 	- Quyền thực hiện: Chỉ FINAL TESTER (người được gán).
 	- Trạng thái có thể chuyển tới: V - Resolved (nếu đạt), 3 - In Progress (nếu lỗi vẫn còn).
 	- Mở/Khóa Field:
  		- TRANS_NOTE: MỞ (Ghi kết quả kiểm thử).
  		- Các field khác: KHÓA.

## PHẦN 6: HỆ THỐNG AUTO-ASSIGNED (CƠ CHẾ TỰ ĐỘNG)

Đây là hàm chạy ngầm (Background logic) được gọi khi Bug đổi trạng thái.

Giai đoạn A: Bug mới tạo (1 -> 2)

- Trigger: Khi Bug được tạo thành công ở trạng thái New.
- Tìm kiếm:
 	- Lấy danh sách User có USER_ROLE = 3 (Developer) từ dự án hiện tại.
 	- Lọc những người có cùng Module với Bug.
- Tính Workload: Với mỗi người tìm thấy, đếm số lượng Bug họ đang xử lý (Status IN (2, 3, 4, 6))
- Điều kiện chọn: Người có số lượng Bug ít nhất và số lượng đó phải < 5.
- Kết quả:
 	- Có người: Tự động điền DEV_ID, chuyển Status sang 2 - Assigned, gửi Email cho Dev.
 	- Không có ai: Chuyển Status sang W - Waiting, gửi Email cho Manager báo cáo.

Giai đoạn B: Bug đã sửa xong (5 -> 6)

- Trigger: Ngay khi Developer nhấn Lưu trạng thái 5 - Fixed.
- Tìm kiếm:
 	- Lấy danh sách User có USER_ROLE = 2 (Tester) từ dự án hiện tại.
 	- Lọc theo Module của Bug.
- Tính Workload: Đếm số Bug mà các Tester đang phải kiểm thử (Status = 6).
- Điều kiện chọn: Người ít việc nhất và < 5 Bug.
- Kết quả:
 	- Có người: Tự động điền FINAL_TESTER_ID, chuyển Status sang 6 - Final Testing, gửi Email cho Tester đó.
 	- Không có ai: Chuyển Status sang W - Waiting, báo cho Manager gán tay.

## PHẦN 7: CHUẨN BỊ DỮ LIỆU NGƯỜI DÙNG (DATA POPULATION)

Để kiểm tra thuật toán "Người ít việc nhất" và "Chung Module", chúng ta cần một lực lượng nhân sự ảo hùng hậu trong bảng ZBT_USER_PRJ (hoặc bảng User Master).

- Danh sách Module giả định:
  - Chúng ta sẽ thực hiện trên 4 Module chính: FI (Tài chính), MM (Kho), SD (Bán hàng), ABAP (Kỹ thuật).
- Lực lượng Developer (20 người):
 	- Module FI: DEV_FI_01 đến DEV_FI_05.
 	- Module MM: DEV_MM_01 đến DEV_MM_05.
 	- Module SD: DEV_SD_01 đến DEV_SD_05.
 	- Module ABAP: DEV_ABAP_01 đến DEV_ABAP_05.

- Lực lượng Tester (10 người):
 	- Module FI: TST_FI_01, TST_FI_02.
 	- Module MM: TST_MM_01, TST_MM_02.
 	- Module SD: TST_SD_01, TST_SD_02.
 	- Module ABAP: TST_ABAP_01, TST_ABAP_02.
 	- (Và 2 Tester dự phòng cho các Module khác).
- Kịch bản Test Workload:
  - Để thuật toán chạy đúng, chúng ta sẽ gán thủ công một số Bug cho các User này trong bảng ZBT_TRACKER:
    - DEV_FI_01: Gán 6 Bug (Hệ thống sẽ bỏ qua người này vì Workload > 5).
    - DEV_FI_02: Gán 2 Bug (Hệ thống sẽ chọn người này vì Workload thấp nhất).
    - DEV_FI_03: Gán 4 Bug.

## PHẦN 8: HỆ THỐNG TÌM KIẾM BUG NÂNG CAO (SEARCH ENGINE)

Quy trình tìm kiếm sẽ được chia làm 3 bước để đảm bảo tính chuyên nghiệp và tách biệt dữ liệu.

Bước 1: Màn hình Tổng quan (Screen 0200)
Sau khi người dùng chọn Project ID từ màn hình trước, hệ thống hiển thị:
 - Header: Dashboard thống kê con số (như đã thiết kế ở phần trước).
 - Body: Toàn bộ Bug của dự án đó.
 - Action: Thêm một nút "SEARCH BUG".

Bước 2: Màn hình Nhập liệu Tìm kiếm (Screen 0210 - Popup)
Khi nhấn nút "Search Bug", một màn hình Popup hiện ra cho phép người dùng lọc chi tiết:
 - Mã lỗi (S_BUG_ID): Tìm theo ID.
 - Tiêu đề (S_TITLE): Tìm kiếm theo từ khóa (Ví dụ: *lỗi*).
 - Trạng thái (S_STATUS): Chọn từ 9 trạng thái.
 - Độ ưu tiên (S_PRIO): High, Medium, Low.
 - Module (S_MOD): FI, MM, SD, ABAP...
 - Người báo cáo/Người xử lý: REPORTER_ID, DEV_ID.

Bước 3: Màn hình Kết quả Tìm kiếm (Screen 0220)
Sau khi nhấn "Execute" (F8) từ màn hình lọc, hệ thống sẽ mở ra một cửa sổ hoàn toàn mới (Full screen):
 - Đặc điểm: Trang này KHÔNG CÓ DASHBOARD phía trên.
 - Nội dung: Một ALV Grid chiếm toàn bộ diện tích màn hình, chỉ hiển thị những Bug thỏa mãn điều kiện lọc ở Bước 2.
 - Điều hướng: Khi nhấn "Back", hệ thống sẽ đóng màn hình kết quả và quay về màn hình Tổng quan (Screen 0200) có Dashboard.
