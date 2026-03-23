# Báo Cáo Tiến Độ - Phase 5 (Advanced FMs & Attachments)

**Ngày báo cáo:** 11/03/2026
**Giai đoạn:** Phase 5 (Advanced Function Modules & Attachments)
**Trạng thái:** 100% Hoàn thành

---

## 1. Mục đích báo cáo

Báo cáo này liệt kê chi tiết quá trình hoàn thành **Phase 5 (Advanced FMs & Attachments)** của dự án SAP Bug Tracking Management System.
Phase 5 tập trung vào việc áp dụng các nghiệp vụ nâng cao (Auto-Assign, Phân quyền Role, Logging, Upload file), đồng thời là giai đoạn phối hợp linh hoạt giữa các tài khoản Developer (`DEV-089`, `DEV-237`) để vận dụng chuyên môn hóa.

## 2. Các hạng mục kỹ thuật đã hoàn thành

Tất cả các Function Modules (FMs) đều được đóng gói gọn gàng trong Function Group `ZBUG_FG`.

Dưới đây là mô tả chi tiết từng Module và cấu trúc code bên dưới nắp ca-pô:

### 2.1. Logging Lịch sử Hệ thống (`Z_BUG_LOG_HISTORY`)

- **Tài khoản Account Code:** `DEV-089` (Chuyên trách xử lý FMs và nâng cao)
- **Cơ chế thực thi:** Function Module được cấp quyền `INSERT` trực tiếp vào bảng `ZBUG_HISTORY`.
- **Cấu trúc Log ID:** ID lịch sử được sinh từ cú pháp Max ID truyền thống (`SELECT MAX(LOG_ID) + 1`), đảm bảo tính tuyến tính an toàn trên các phiên bản ABAP từ 7.40 trở xuống.
- **Tác dụng:** Mọi Action của hệ thống (Reassign, Cập nhật trạng thái) đều lẳng lặng gọi vào FM này kèm `OLD_VALUE` và `NEW_VALUE`.

### 2.2. Phân công Tự động (`Z_BUG_AUTO_ASSIGN`)

- **Tài khoản Account Code:** `DEV-089`
- **Tương thích phiên bản ABAP:** Sử dụng hoàn toàn cú pháp **Legacy ABAP** thay cho cú pháp inline `@DATA(...)` để tương thích ngược mọi hệ thống khách hàng.
- **Thuật toán Workload:**
  1. `SELECT` tìm tất cả ứng viên Developer (Role = `D`, Active = `X`, Avail = `A`).
  2. Vòng `LOOP` đếm trong bảng Bugs xem mỗi DEV rảnh kia đang giữ bao nhiêu Bug trạng thái 2 (Assigned) và 3 (In Progress).
  3. Quét tìm Dev nào có `lv_count` thấp nhất (`lv_min_load`).
  4. Assign, sau đó tự chuyển trạng thái Bug thành `2` và đánh dấu DEV là `W` (Working).

### 2.3. Phân Quyền Vai Trò (`Z_BUG_CHECK_PERMISSION`)

- **Tài khoản Account Code:** `DEV-089`
- Sử dụng **Legacy Sytax (Cấu trúc CASE-WHEN)** để che giấu các nút/hành vi trái phép thay vì `COND #(...)`.
- **Logic Authorization:**
  - Manager (`M`): Bỏ qua mọi lệnh cấm (Full Access Bypass).
  - Tester (`T`): Chỉ được Create Bug và tải file lên `UPLOAD_REPORT`, `UPLOAD_VERIFY`. Không được sửa/đóng bug của người khác.
  - Developer (`D`): Chỉ được thao tác `UPLOAD_FIX` lên Bug được Assign cho chính mình.

### 2.4. Tính năng thẩm mỹ ALV Grid (ALV Row Colors)

- **Tài khoản Account Code:** `DEV-061` (Chuyên gia Tầng UI/Presentation Phase 3-4 quay rọi lại)
- Thay vì chỉ xuất grid trắng, chương trình `Z_BUG_REPORT_ALV` được sửa lại bằng cách nhúng field tĩnh `ROW_COLOR TYPE c LENGTH 4` vào type hiển thị.
- Set parameter `ls_layout-info_fieldname = 'ROW_COLOR'`.
- Kết quả ngã màu thành công: `C100` (Xanh dương - Mới tạo), `C500` (Tím - Đang xử lý), `C200` (Xám - Đã chốt).

### 2.5. Upload File (GOS - `Z_BUG_UPLOAD_ATTACHMENT`)

- **Tài khoản Account Code:** `DEV-237` (Chuyên gia GOS / Business Workplace)
- **Cơ chế:** Giao tiếp trực tiếp với Core SAP - API `Generic Object Services`.
- Module này tiếp nhận địa chỉ PATH từ công cụ đính kèm và cập nhật vào đúng loại cột của Bug (`ATT_REPORT`, `ATT_FIX`, `ATT_VERIFY`).
- Module chặn đứng thao tác Upload file lên những Bug đã `Closed` (Status = 5).

### 2.6. Re-Assign Logic (`Z_BUG_REASSIGN`)

- **Tài khoản Account Code:** `DEV-089`
- **Sự cố cần giải quyết:** Dev hiện tại nhận Bug nhưng bận việc hoặc xin thôi việc.
- Module đổi Bug sang `NEW_DEV_ID`. Dev cũ trở về `AVAILABLE_STATUS = 'A'`. Dev mới đổi sang `W`. Sau đó Module gọi `Z_BUG_LOG_HISTORY` truyền tham số Action là `RS` (Re-Assign).

---

## 3. Tổng kết

Quy trình phát triển ở Phase 5 cực kỳ suôn sẻ do thiết kế Database ở Phase 1 cực kỳ vững chãi. Phase 5 đã hoàn thiện mảnh ghép Logic Back-end cuối cùng của dự án. **Hệ thống hiện tại đã là một phiên bản Release Candidate (RC) hoàn chỉnh sẵn sàng cho End-User UAT / Testing.**

---
**Người lập báo cáo:** Antigravity (AI Assistant)
**Dự án:** SAP Bug Tracking Management System
