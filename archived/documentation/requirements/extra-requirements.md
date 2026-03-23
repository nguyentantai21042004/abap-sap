BỔ SUNG YÊU CẦU NGHIỆP VỤ VÀ CHỨC NĂNG HỆ THỐNG BUG TRACKING

1.  Phân loại và xử lý lỗi

- Lỗi trong hệ thống có thể phát sinh do:
  - Lỗi lập trình (code)

  - Lỗi cấu hình hệ thống (configuration)

- Đối với lỗi cấu hình, tester có quyền tự xử lý và khắc phục mà không cần chuyển cho developer

- User cuối không trực tiếp tham gia hệ thống

- User chỉ có nhiệm vụ thông báo lỗi cho tester

- Tester là người tiếp nhận và ghi nhận bug vào hệ thống

2.  Vai trò và phân quyền người dùng

Hệ thống có ba nhóm người dùng chính:

- Tester
  - Ghi nhận bug

  - Tự sửa lỗi cấu hình

  - Có thể tự xử lý bug và đóng bug nếu đã fix xong

  - Có thể chuyển bug cho developer nhưng phải được duyệt bởi manager.

  - Có thể đính kèm bằng chứng trước và sau khi sửa lỗi

- Developer
  - Nhận bug được phân công

  - Sửa lỗi liên quan đến code

  - Có thể từ chối xử lý và yêu cầu re-assign

  - Sau khi sửa xong, có thể chuyển lại cho tester ban đầu hoặc tester khác để kiểm tra lại

- Manager
  - Quản lý toàn bộ hệ thống

  - Phân công bug cho developer thủ công

  - Thiết lập chế độ auto assign bug

  - Có quyền thay đổi lại việc phân công khi cần thiết

  - Theo dõi hiệu suất và tiến độ xử lý lỗi

3.  Cơ chế phân công và xử lý bug

- Bug có thể được tạo bởi tester

- Tester có thể:
  - Tự sửa bug và hoàn tất (done by tester)

  - Chuyển bug cho developer

- Khi bug đã được assign cho developer:
  - Tester không được phép chỉnh sửa trạng thái xử lý

  - Chỉ có developer đang được phân công và manager có thể chuyển trạng thái xử lý

- Developer có thể:
  - Xử lý bug

  - Yêu cầu chuyển lại cho người khác nếu không phù hợp

- Sau khi fix xong:
  - Bug được assign lại cho tester để verify

  - Có thể assign cho tester khác nếu cần

4.  Quản lý file đính kèm và bằng chứng (Evidence)

- Mỗi bug có thể đính kèm tối đa:
  - 1 file report lỗi do tester ghi nhận

  - 1 file bằng chứng đã fix lỗi do developer ghi nhận

  - 1 file bằng chứng đã text lại lỗi fix do tester.

  - Trong trường hợp dev up file bằng chứng đã fix nhưng tester bảo rằng lỗi vẫn chưa đc fix hết và kèm bằng chứng thì file thứ 2 và 3 có thể thay đổi. File thứ 1 có thể được update bởi duy nhất chính tester đã khai báo lỗi

- File đính kèm chỉ gồm 1 file excel duy nhất, trong file excel có thể chứa:
  - Screenshot

  - Document

  - Log file

- File sau khi sửa lỗi được xem là bằng chứng quan trọng

- Khi bug đã hoàn tất, không được phép xóa các file bằng chứng fix

- File được lưu trữ sao cho có thể mở trực tiếp từ dashboard

5.  Mô tả lỗi và thông tin mở rộng

- Trường mô tả lỗi (Bug Description):
  - Không giới hạn số lượng ký tự

  - Hỗ trợ nhập nội dung chi tiết

- Bổ sung thêm trường Reasons trong bảng ZBUG để:
  - Ghi nhận nguyên nhân phát sinh lỗi

- Thêm 1 Ztable log để ghi nhận sự thay đổi của từng bug như việc đc reassign cho ai và đã đổi cho ai, với lý do gì. Đổi vào ngày nào.

6.  Giao diện và màn hình xử lý

- Hệ thống sử dụng chung một màn hình xử lý cho:
  - Tester

  - Developer

- Không cần tách giao diện riêng cho từng vai trò

- ALV chỉ dùng để hiển thị danh sách bug

- Chức năng create bug hay chỉnh sửa bug nên có 1 screen riêng đễ dễ dàng nhập liệu thay vì chỉnh sửa ngay trên alv.

- Với các chức năng đơn giản như update trạng thái bug, assign thủ công thì có thể thực hiện ngay trên alv.

- Việc hiển thị thông tin tổng hợp được thực hiện trên dashboard

7.  Dashboard và báo cáo

- Dashboard hiển thị các thông số tổng hợp:
  - Tổng số bug

  - Bug theo trạng thái

  - Bug theo người xử lý

  - Bug theo module

  - Bug đang chờ xử lý

- Cho phép mở nhanh file đính kèm từ dashboard

- Có thể hiện thị dưới dạng chart / biểu đồ (optional).

- Hỗ trợ theo dõi hiệu suất của tester và developer

8.  Quản lý tài khoản người dùng

- Xây dựng bảng riêng để quản lý account:
  - Tester

  - Developer

  - Manager

- Mỗi tài khoản có các thông tin:
  - User ID

  - Role

  - Module phụ trách

  - Trạng thái hoạt động

- Developer có thêm trường:
  - Available Status (rảnh, đang bận, nghỉ phép, đang xử lý bug khác...)

  - Available Status sẽ tự động đổi sang Assigned (đang xử lý bug) khi đã đc assigned, và lúc này hệ thống auto assign không thể assign dev này cho bug mới

9.  Cơ chế phân công tự động (Auto Assign)

- Hệ thống hỗ trợ:
  - Assign thủ công bởi manager

  - Assign tự động theo rule

- auto assign có thể dựa trên:
  - Module

  - Workload

  - Available status

- Khi auto assign:
  - Manager vẫn có quyền chỉnh sửa lại phân công

  - Cho phép re-assign khi cần thiết

10. Quản lý Bug ID

- Hệ thống tự động sinh Bug ID bằng Number Range

- Không cần ghi nhận mã lỗi hệ thống phát sinh
