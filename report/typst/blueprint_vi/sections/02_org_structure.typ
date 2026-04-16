// ============================================================
// 02_org_structure.typ — CƠ CẤU TỔ CHỨC
// ============================================================
#import "../template.typ": placeholder, hline

= CƠ CẤU TỔ CHỨC

Hệ thống vận hành trong *SAP System S40, Client 324* và được truy cập qua T-Code *ZBUG_WS*. Ba vai trò khác nhau tồn tại trong hệ thống, mỗi vai trò được ánh xạ tới một bản ghi trong bảng *ZBUG_USERS* (trường `ROLE`, CHAR 1).

== Vai trò Hệ thống

#table(
  columns: (2cm, 3cm, 1fr, 4cm),
  align: (center, left, left, left),
  [*Mã*], [*Vai trò*], [*Mô tả*], [*Tài khoản SAP (Demo)*],
  [`M`], [*Manager*],   [Quyền truy cập toàn hệ thống. Quản lý dự án, phân công lỗi, đóng lỗi, xem thống kê dashboard, quản lý tài khoản người dùng.], [`DEV-089`],
  [`D`], [*Developer*], [Nhận lỗi được phân công. Cập nhật trạng thái lỗi (InProgress, Fixed, Pending, Rejected). Tải lên bằng chứng sửa lỗi. Chỉ có thể thao tác trên lỗi có `DEV_ID = SY-UNAME`.], [`DEV-061`],
  [`T`], [*Tester*],    [Tạo lỗi, tải lên bằng chứng báo cáo lỗi. Xác minh lỗi đã được sửa (giai đoạn Final Testing). Cũng có thể tự sửa lỗi loại Config với vai trò vừa là Developer vừa là Tester.], [`DEV-118`],
)

== Xác định Vai trò tại Thời gian Chạy

Vai trò được xác định từ bảng `ZBUG_USERS` khi đăng nhập:

```abap
SELECT SINGLE role FROM zbug_users INTO @gv_role
  WHERE user_id = @sy-uname
    AND is_del  <> 'X'
    AND is_active = 'X'.
```

== Phân công Vai trò theo Dự án

Mỗi người dùng có thể giữ vai trò khác nhau theo từng dự án, được lưu trong `ZBUG_USER_PROJEC` (Khóa: MANDT + USER_ID + PROJECT_ID, trường `ROLE`). Điều này cho phép linh hoạt giữa các dự án (ví dụ: người dùng có thể là Manager trong Dự án A và Developer trong Dự án B).

== Tóm tắt Ma trận Quyền hạn

#table(
  columns: (1fr, 1.5cm, 1.5cm, 1.5cm),
  align: (left, center, center, center),
  [*Hành động*], [*M*], [*D*], [*T*],
  [Tạo Lỗi],                        [✓], [—], [✓],
  [Xóa Lỗi],                        [✓], [—], [—],
  [Thay đổi Trạng thái (qua Popup 0370)], [✓], [✓], [✓],
  [Phân công / Tái phân công Lỗi],   [✓], [—], [—],
  [Tải lên Bằng chứng Sửa lỗi],     [✓], [✓], [—],
  [Tải lên Bằng chứng Báo cáo],     [✓], [—], [✓],
  [Tải lên Bằng chứng Xác minh],    [✓], [—], [✓],
  [Xem Tất cả Lỗi],                 [✓], [—], [—],
  [Tạo / Sửa Dự án],                [✓], [—], [—],
  [Thêm / Xóa Người dùng Dự án],    [✓], [—], [—],
  [Xem Thống kê Dashboard],         [✓], [—], [—],
  [Tải xuống Mẫu],                  [✓], [—], [✓],
  [In SmartForm],                   [✓], [✓], [✓],
  [Gửi Email],                      [✓], [✓], [✓],
)
