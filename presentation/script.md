# Script Trình Bày — SAP Bug Tracking Management System

**Tổng thời gian:** ~20 phút | **Phân bổ:** 12 phút slides + 5 phút demo + 3 phút Q&A

---

## Ký hiệu trong script

| Ký hiệu | Ý nghĩa |
|---------|---------|
| **NÓI** | Đọc to khi trình bày |
| **NOTE** | Đọc để hiểu khái niệm — *không* nói ra |
| *nghiêng* | Hành động / cử chỉ (chỉ làm, không đọc) |

---

## Thuật ngữ ABAP/SAP (tham khảo khi cần)

| Thuật ngữ | Giải thích |
|-----------|------------|
| **3-tier** | Kiến trúc 3 tầng: Giao diện (SAP GUI) → Logic (ABAP, FM) → Database (bảng) |
| **ABAP** | Ngôn ngữ lập trình của SAP |
| **ALV** | Công cụ hiển thị bảng trong SAP (sort, filter, export Excel). Màn hình ZBUG_REPORT dùng ALV |
| **SmartForms** | Công cụ thiết kế mẫu in, xuất PDF. Đồ án dùng ZBUG_FORM |
| **SAPconnect** | Cơ chế gửi email từ SAP qua SMTP |
| **T-code** | Mã lệnh mở màn hình (vd: ZBUG_CREATE, SE11). Gõ vào ô command rồi Enter |
| **Function Module (FM)** | Chương trình con ABAP, giống API. Đồ án có 10 FM |
| **Domain / Data Element** | Định nghĩa kiểu dữ liệu cho các cột bảng |
| **GOS** | Dịch vụ đính kèm file (ảnh, Excel) vào Bug |
| **On-stack** | Chạy hoàn toàn trong SAP, không dùng Jira/Redmine bên ngoài |

---

## SLIDE 1 — Trang bìa

**NÓI:**
> "Xin chào mọi người. Hôm nay mình sẽ trình bày về hệ thống mà mình đã xây dựng trong 6 tuần vừa rồi — đó là **Hệ Thống Quản Lý Lỗi** chạy hoàn toàn trên nền tảng SAP ERP, lập trình bằng ngôn ngữ ABAP."
>
> "Mình sẽ đi từ lý do tại sao cần làm hệ thống này, đến những gì mình đã xây dựng, rồi demo trực tiếp cho mọi người xem. Tổng cộng khoảng 20 phút."

*Chờ mọi người ổn định, nhìn lên màn hình.*

---

## SLIDE 2 — Yêu cầu đề án

**NOTE:** *On-stack* = chạy trong SAP, không dùng Jira. *3-tier* = Giao diện → Logic → DB. *ALV* = bảng dữ liệu, *SmartForms* = mẫu in PDF.

**NÓI:**
> "Đề án môn học yêu cầu xây dựng một hệ thống quản lý lỗi chạy trên SAP ERP. Cụ thể là mô phỏng quy trình: Tester ghi nhận lỗi, phân công cho Developer, Developer sửa, Tester verify, rồi đóng bug."
>
> "Yêu cầu kỹ thuật là giải pháp phải **on-stack** — tức là chạy hoàn toàn trong SAP, không dùng Jira hay Redmine bên ngoài. Phải tuân thủ kiến trúc 3-tier của SAP và dùng công nghệ chuẩn như ALV, SmartForms."
>
> "Phạm vi mình đã thực hiện gồm: database, business logic, 6 T-codes giao diện, email tự động, và phân quyền theo 3 vai trò."

---

## SLIDE 3 — Hệ thống làm được gì

**NOTE:** *Number range (SNRO)* sinh BUG0000001, BUG0000002... *SAPconnect* = gửi email qua SMTP. *Auto-assign* = thuật toán chọn Dev ít bug nhất. *GOS* = upload file đính kèm.

**NÓI:**
> "Hệ thống mình xây có 6 chức năng chính."
>
> "**Một:** Ghi nhận lỗi — có form nhập liệu, tự động sinh mã Bug theo thứ tự BUG0000001, BUG0000002..."
>
> "**Hai:** Thông báo tự động — ngay khi có Bug mới, hệ thống tự gửi email cho Developer liên quan. Không cần ai nhớ thông báo."
>
> "**Ba:** Phân công tự động — hệ thống tự tìm Developer cùng module, xem ai đang ít việc nhất, rồi phân công luôn."
>
> "**Bốn:** Báo cáo và Dashboard — danh sách Bug phân màu theo trạng thái, có bộ lọc, và màn hình tổng quan cho Manager."
>
> "**Năm:** In biên bản — xuất file PDF theo mẫu chuẩn khi cần lưu hồ sơ."
>
> "**Sáu:** Đính kèm file — Tester có thể upload ảnh chụp màn hình, Developer upload bằng chứng đã sửa, tất cả gắn liền với từng Bug."

---

## SLIDE 4 — 3 vai trò người dùng

**NOTE:** Phân quyền qua bảng ZBUG_USERS + FM `Z_BUG_CHECK_PERMISSION`. Tester=Role T, Dev=D, Manager=M. Manager có full access.

**NÓI:**
> "Hệ thống có 3 loại người dùng với quyền hạn khác nhau."
>
> "**Tester** — người phát hiện và ghi nhận lỗi. Tester tạo Bug, upload ảnh chứng minh, và sau khi Developer sửa xong thì Tester vào xác nhận."
>
> "**Developer** — người sửa lỗi. Developer nhận Bug được phân công, sửa, rồi upload bằng chứng. Nếu thấy Bug không đúng module mình phụ trách, Developer có thể từ chối và hệ thống sẽ phân công lại."
>
> "**Manager** — quản lý toàn bộ. Manager có thể xem tất cả, phân công thủ công nếu muốn, và xem dashboard tổng hợp."
>
> "Quan trọng là: **mỗi người chỉ làm được đúng việc của mình**. Ví dụ Developer không thể tự đóng Bug, Tester không thể tự phân công. Hệ thống tự chặn."

---

## SLIDE 5 — Vòng đời của một lỗi

**NOTE:** Status 1=New, W=Waiting, 2=Assigned, 3=In Progress, 4=Fixed, 5=Closed. Self-fix = lỗi cấu hình Tester tự sửa. Auto-assign dùng `Z_BUG_AUTO_ASSIGN`.

**NÓI:**
> "Đây là vòng đời của một Bug trong hệ thống."
>
> *Chỉ vào sơ đồ.*
>
> "Tester tạo Bug → trạng thái là **New**. Nếu là lỗi cấu hình đơn giản, Tester tự sửa được luôn và đóng Bug."
>
> "Nếu là lỗi code phức tạp, hệ thống **tự động tìm Developer** phù hợp và chuyển sang **Assigned**. Developer nhận việc → **In Progress** → sửa xong → **Fixed**. Tester vào kiểm tra → **Closed**."
>
> "Trường hợp đặc biệt: nếu không có Developer nào rảnh, Bug vào trạng thái **Waiting**, và Manager sẽ vào phân công thủ công."
>
> "Mọi thay đổi trạng thái đều được **ghi lại tự động** — ai thay đổi, lúc nào, lý do gì."

---

## SLIDE 6 — Những gì đã xây dựng

**NOTE:** 3 bảng: ZBUG_TRACKER, ZBUG_USERS, ZBUG_HISTORY. FG ZBUG_FG có 10 FM: CREATE, UPDATE_STATUS, GET, DELETE, SEND_EMAIL, AUTO_ASSIGN, CHECK_PERMISSION, LOG_HISTORY, UPLOAD_ATTACHMENT, REASSIGN. 6 T-codes: ZBUG_CREATE, ZBUG_UPDATE, ZBUG_REPORT, ZBUG_MANAGER, ZBUG_PRINT, ZBUG_USERS.

**NÓI:**
> "Bây giờ mình sẽ nói nhanh về mặt kỹ thuật — những thứ mình thực sự đã tạo trong SAP."
>
> "Về **database**: mình tạo 3 bảng chính — bảng lưu Bug, bảng lưu danh sách nhân viên, và bảng lưu lịch sử thay đổi. Cộng thêm các cấu trúc dữ liệu đi kèm."
>
> "Về **business logic**: mình viết 10 Function Modules — đây là đơn vị code cơ bản trong ABAP, giống như API vậy. Gồm các hàm tạo Bug, cập nhật, đọc, xóa, gửi email, phân công tự động, kiểm tra phân quyền, ghi lịch sử, upload file, và re-assign."
>
> "Về **giao diện**: 6 T-codes — tức là 6 màn hình khác nhau mà người dùng có thể gõ vào ô lệnh SAP để mở."
>
> "Nếu thầy cô hỏi về số lượng đối tượng kỹ thuật: tổng cộng có 3 bảng, 10 function modules, 6 transaction codes, 1 SmartForm."

---

## SLIDE 7 — Giới thiệu Demo

**NÓI:**
> "Bây giờ mình sẽ demo trực tiếp. Mình sẽ cho mọi người thấy 4 bước cơ bản của hệ thống."
>
> "Mình đang đăng nhập vào hệ thống SAP S40, client 324 — đây là môi trường thực tế mình dùng để phát triển."

*Mở SAP GUI, đăng nhập.*

---

## DEMO — Bước 1: Tạo Bug mới (~2 phút)

**NOTE:** SD = Sales & Distribution. Bug Type C=Code, F=Configuration. Priority H/M/L. Sau Create gọi `Z_BUG_SEND_EMAIL` qua SAPconnect (CL_BCS).

**NÓI:**
> "Mình gõ T-code ZBUG_CREATE. Đây là màn hình tạo Bug mới."
>
> "Mình điền tiêu đề, mô tả chi tiết, chọn module là SD — Sales & Distribution, loại lỗi là Code, độ ưu tiên High."
>
> *Nhấn F8.*
>
> "Nhấn chạy. Hệ thống tự sinh mã BUG0000001, lưu vào database... và **tự động gửi email** thông báo cho Developer module SD."
>
> "Người dùng không cần làm thêm gì — thông báo đi tự động."

*Điền: Title: Lỗi không load SO01 | Desc: Khi mở SO01 báo dump ABAP | Module: SD | Type: C | Priority: H*

---

## DEMO — Bước 2: Xem báo cáo ALV (~1.5 phút)

**NOTE:** ALV = ABAP List Viewer. Row color theo ROW_COLOR field (C100, C310...). Toolbar dùng GUI Status ZBUG_STATUS, function codes ZUPD (Update), ZASGN (Auto Assign). Gọi `Z_BUG_AUTO_ASSIGN`.

**NÓI:**
> "Bây giờ mình mở ZBUG_REPORT — đây là màn hình danh sách Bug."
>
> "Mọi người thấy các dòng có màu khác nhau — đây là mình cài để phân biệt trạng thái một cách trực quan. Xanh nhạt là New, cam là Assigned, đỏ là Fixed chờ verify, xanh lá là Closed."
>
> "Trên toolbar có 2 nút tùy chỉnh mình thêm vào: **Update Bug** để mở màn hình cập nhật, và **Auto Assign** để tự động phân công Developer."
>
> "Khi nhấn Auto Assign, hệ thống chạy thuật toán: quét tất cả Developer module SD, đếm xem ai đang có bao nhiêu Bug đang xử lý, rồi phân công cho người ít việc nhất."

*Gõ ZBUG_REPORT → Execute → Click Auto Assign*

---

## DEMO — Bước 3: Cập nhật Bug (~1.5 phút)

**NOTE:** Pre-fill qua `Z_BUG_GET`. Update qua `Z_BUG_UPDATE_STATUS`. Log qua `Z_BUG_LOG_HISTORY`. Permission check qua `Z_BUG_CHECK_PERMISSION` — Tester không được set Fixed.

**NÓI:**
> "Màn hình cập nhật — mình nhập Bug ID vừa tạo."
>
> "Hệ thống tự điền toàn bộ thông tin của Bug đó. Bây giờ mình có thể thay đổi trạng thái."
>
> "Lưu ý: nếu mình đăng nhập bằng tài khoản Tester mà cố thay đổi trạng thái sang Fixed — hệ thống sẽ báo lỗi, vì chỉ Developer mới được làm điều đó. **Phân quyền hoạt động tự động.**"
>
> "Sau khi lưu, hệ thống tự ghi vào bảng lịch sử: ai thay đổi, lúc mấy giờ, từ trạng thái nào sang trạng thái nào."

*ZBUG_UPDATE → Nhập Bug ID → Đổi status → Nhập lý do → Lưu*

---

## DEMO — Bước 4: Manager Dashboard (~1 phút)

**NOTE:** Program Z_BUG_MANAGER_DASHBOARD. SQL aggregation GROUP BY status. Hiển thị tổng, theo status, theo module.

**NÓI:**
> "Cuối cùng, màn hình dành cho Manager. Nhìn vào đây là biết ngay tổng quan: bao nhiêu Bug đang New, bao nhiêu đang xử lý, bao nhiêu chờ verify."
>
> "Manager không cần hỏi từng người — mở màn hình này là thấy hết."

*Gõ ZBUG_MANAGER*

---

## SLIDE 8 — Kết quả đạt được

**NÓI:**
> "Tóm lại, sau 6 tuần phát triển, hệ thống đã hoàn thành đầy đủ phần core:"
>
> "3 bảng database, 10 function modules, 6 T-codes hoạt động, 1 SmartForm để in PDF. Phân quyền 3 vai trò, audit trail 100% các thao tác."
>
> "Hiện tại đang trong giai đoạn testing và chuẩn bị tài liệu bàn giao."

*Quay lại slides.*

---

## SLIDE 8b — Trạng thái & Bước tiếp theo

**NOTE:** Phase 6 = SCI, Unit test, Performance test (<3s ALV), Integration test, UAT prep, Documentation. Phase 7 = Transport, Training. Phase 8 = Demo Day 29/03.

**NÓI:**
> "Hiện tại đã xong Phase 0 đến 5 — tức là phần phát triển core. Đang ở **Phase 6 — Testing & Optimization**."
>
> "Phase 6 gồm: kiểm tra code chuẩn SAP, test các chức năng như tạo bug, auto-assign, phân quyền, email; test hiệu năng để ALV chạy dưới 3 giây; và chuẩn bị tài liệu hướng dẫn người dùng."
>
> "Sau đó sẽ sang Phase 7 — triển khai và training, rồi Phase 8 — báo cáo cuối cùng ngày 29/03."

---

## SLIDE 9 — Kết thúc

**NÓI:**
> "Đó là toàn bộ hệ thống mình đã xây dựng. Điểm mình muốn nhấn mạnh là: đây là một giải pháp **hoàn chỉnh, chạy được thực tế**, không phải prototype — từ database, business logic, giao diện, đến email, file attachment, phân quyền đều hoạt động đồng bộ."
>
> "Cảm ơn mọi người đã theo dõi. Mình xin nhường thời gian cho phần câu hỏi."

---

## PHẦN Q&A — Câu hỏi thường gặp

**NOTE:** Đọc câu trả lời khi bị hỏi. Có thể paraphrase cho tự nhiên.

---

**Q: Tại sao không dùng Jira hay Redmine?**

**NÓI:** "Yêu cầu của đề tài là xây dựng giải pháp On-Stack — tức là chạy hoàn toàn trong SAP, không phụ thuộc phần mềm ngoài. Điều này đảm bảo bảo mật dữ liệu và tích hợp trực tiếp với dữ liệu SAP hiện có của doanh nghiệp."

---

**Q: Mất bao lâu để học ABAP và xây hệ thống này?**

**NÓI:** "ABAP là ngôn ngữ đặc thù của SAP, khá khác so với các ngôn ngữ thông thường. Mất khoảng 1-2 tuần đầu để làm quen, sau đó mới bắt đầu code được. Tổng cộng 6 tuần để hoàn thành phần phát triển."

---

**Q: Hệ thống có thể xử lý được bao nhiêu Bug cùng lúc?**

**NÓI:** "Về lý thuyết, giới hạn là capacity của SAP database — có thể handle hàng chục nghìn records mà không vấn đề gì. ALV report cũng hỗ trợ phân trang tự động."

---

**Q: Auto-assign hoạt động thế nào nếu tất cả Dev đều bận?**

**NÓI:** "Trường hợp không có Developer nào rảnh — Bug sẽ chuyển sang trạng thái Waiting. Manager sẽ nhận thấy trên Dashboard và có thể phân công thủ công, hoặc chờ Developer nào xong việc thì hệ thống sẽ tự assign lại."

---

**Q: Làm sao biết ai đã thay đổi Bug, lúc nào?**

**NÓI:** "Mình có bảng ZBUG_HISTORY ghi lại toàn bộ: mỗi lần ai thay đổi trạng thái Bug, hệ thống tự insert một dòng — gồm User ID, thời gian, trạng thái cũ, trạng thái mới, và lý do. Không ai có thể xóa lịch sử này."

---

**Q: Email có thực sự gửi được không?**

**NÓI:** "Có. Mình cấu hình SMTP qua T-code SCOT của SAP, kết nối với Gmail SMTP server. Đã test gửi thành công. Trong môi trường production thực tế, sẽ dùng SMTP server của doanh nghiệp."

---

**Q: Nếu Developer từ chối Bug thì sao?**

**NÓI:** "Có chức năng Re-assign. Developer nhập lý do từ chối, hệ thống cập nhật Developer cũ thành Available, gọi lại thuật toán Auto-assign để tìm người mới, và ghi lịch sử toàn bộ quá trình."

---

*Hết script. Chúc trình bày suôn sẻ!*
