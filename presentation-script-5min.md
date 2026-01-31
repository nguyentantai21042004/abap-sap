# Script trình bày (5 phút) – Bug Tracking trên SAP

## Slide 1 – Title

**Lời thoại:**  
"Chào anh/chị, em xin trình bày nhanh đề xuất triển khai hệ thống Bug Tracking trên SAP. Mục tiêu là thống nhất hướng làm trong khoảng 5 phút, sau đó chốt câu hỏi để chọn phương án."

---

## Slide 2 – Agenda

**Lời thoại:**  
"Agenda gồm 5 phần: mô tả đề bài, 2 hướng triển khai, trade‑off nhanh, câu hỏi cần xác nhận và next step."

---

## Slide 3 – Mô tả đề bài (theo yêu cầu)

**Lời thoại:**  
"Đề tài yêu cầu build **Custom Add‑on Z\*** trong SAP ERP cho Bug Tracking. Các chức năng bắt buộc gồm:

1. T‑code nhập lỗi `ZBUG_CREATE`, có validation.
2. Gửi email tự động sau khi lưu qua SCOT.
3. Báo cáo ALV Grid, filter, drill‑down.
4. In ấn SmartForms, xuất PDF.
5. Thống kê summary trên đầu ALV.
6. GOS đính kèm ảnh/log theo Bug ID."

---

## Slide 4 – ERP Context

**Lời thoại:**  
"Slide này để nhắc lại bối cảnh: hệ thống chạy trong SAP ERP, quy trình nghiệp vụ bám SAP."

---

## Slide 5 – SAP Modules liên quan

**Lời thoại:**  
"Hệ thống có thể liên quan các phân hệ như MM/SD/FI tùy nghiệp vụ, nhưng phần bug tracking là custom Z‑solution tách riêng."

---

## Slide 6 – Offer A (On‑Stack)

**Lời thoại:**  
"Offer A: làm **On‑Stack** bằng ABAP trong SAP GUI. Người dùng thao tác SAP GUI, báo cáo ALV, in SmartForms.  
Ngôn ngữ chính là **ABAP**, phát triển qua SE38/SE80.  
Các T‑code chính: `ZBUG_CREATE` cho nhập liệu và `ZBUG_REPORT` cho báo cáo."

---

## Slide 7 – Offer A (Ví dụ code)

**Lời thoại:**  
"Đây là ví dụ ABAP: validate dữ liệu, insert vào Z‑table, commit, và gửi mail qua CL_BCS. Code bám chuẩn SAP."

---

## Slide 8 – Offer A (Sơ đồ kiến trúc)

**Lời thoại:**  
"Kiến trúc on‑stack nằm hoàn toàn trong SAP: Presentation (GUI), Application (ABAP), Database (Z‑table). Không có hệ thống ngoài."

---

## Slide 9 – Offer A (Ưu/Nhược)

**Lời thoại:**  
"Ưu điểm: tích hợp sâu, không cần hạ tầng ngoài, đúng chuẩn SAP.  
Hạn chế: UX truyền thống và phụ thuộc quyền dev đầy đủ."

---

## Slide 10 – Offer A (Kế hoạch triển khai)

**Lời thoại:**  
"Timeline 8 tuần cho On‑Stack: Tuần 1 thiết lập môi trường và database schema. Tuần 2-3 phát triển core (nhập liệu, CRUD, email). Tuần 4-5 báo cáo ALV và SmartForms. Tuần 6 đóng gói Transport Request. Tuần 7-8 UAT và bàn giao."

---

## Slide 11 – Offer B (Side‑by‑Side)

**Lời thoại:**  
"Offer B: làm **Side‑by‑Side**. Web app chạy song song SAP, backend **Golang hoặc Node.js**, frontend React, kết nối qua RFC/OData."

---

## Slide 12 – Offer B (Ví dụ code)

**Lời thoại:**  
"Ví dụ API Golang/Node để nhận bug, validate rồi gọi SAP connector lưu dữ liệu. Mô hình này linh hoạt và dễ mở rộng."

---

## Slide 13 – Offer B (Sơ đồ kiến trúc)

**Lời thoại:**  
"Kiến trúc side‑by‑side: web app chạy trên Docker/VM, kết nối SAP qua RFC/OData. SAP vẫn là nguồn dữ liệu chính."

---

## Slide 14 – Offer B (Ưu/Nhược)

**Lời thoại:**  
"Ưu điểm: UX hiện đại, đa thiết bị, dễ mở rộng.  
Hạn chế: cần mở kết nối API vào SAP và vận hành thêm hạ tầng web."

---

## Slide 15 – Offer B (Kế hoạch triển khai)

**Lời thoại:**  
"Timeline 8 tuần cho Side‑by‑Side: Tuần 1 setup VM/Docker và test kết nối SAP. Tuần 2 viết RFC/OData và SAP Connector. Tuần 3-4 phát triển Backend API. Tuần 5-6 phát triển Frontend web. Tuần 7-8 deploy, UAT và bàn giao."

---

## Slide 16 – So sánh nhanh (Trade‑off)

**Lời thoại:**  
"So sánh nhanh: On‑stack mạnh về native SAP và hạ tầng đơn giản; Side‑by‑side mạnh về UX và mở rộng.  
Chọn hướng nào tùy ưu tiên của anh/chị."

---

## Slide 17 – Quy trình nghiệp vụ (Sequence)

**Lời thoại:**  
"Luồng chuẩn: user nhập lỗi → lưu Z‑table → gửi mail thông báo → dev xử lý → cập nhật trạng thái.  
Dù chọn hướng nào, flow nghiệp vụ vẫn giữ nguyên."

---

## Slide 18 – Câu hỏi chốt

**Lời thoại:**  
"Để chốt phương án, cần xác nhận:

1. Hướng SAP GUI hay Web?
2. Có quyền SAP Dev chưa? Nếu có thì xin cấp; nếu không thì đề xuất dựng SAP riêng bằng container.
3. Cho phép RFC/OData?
4. SmartForms hay PDF?
5. SCOT/SMTP đã có chưa?"

---

## Slide 19 – Quyền SAP Dev tối thiểu (On-Stack)

**Lời thoại:**  
"Nếu chọn On‑Stack, cần quyền dev tối thiểu gồm: Developer Key, SE11 cho table, SE38/SE80 cho ABAP, SE93 cho T-code, SE24/SE37 cho class/function, SE51/SE41 cho màn hình, SMARTFORMS cho in ấn, SCOT/SOST cho email, và SE09/SE10 cho transport."

---

## Slide 20 – Quy tắc chốt phương án

**Lời thoại:**  
"Nếu bắt buộc SAP GUI + SmartForms + có quyền dev → chọn On‑stack.  
Nếu ưu tiên web UX + có RFC/OData + chấp nhận PDF → chọn Side‑by‑side."

---

## Slide 21 – Next Step

**Lời thoại:**  
"Sau cuộc họp, chốt hướng triển khai, chốt scope chi tiết (field, flow, permission), xác định timeline và tài nguyên.  
Em sẽ dựa trên đó để viết Tech Specs chi tiết."
