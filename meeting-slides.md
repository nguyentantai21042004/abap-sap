---
marp: true
title: Bug Tracking trên SAP
paginate: true
style: |
  img[alt~="center"] {
    display: block;
    margin: 0 auto;
  }
---

# BUG TRACKING TRÊN SAP

## Đề xuất hướng triển khai

---

## Agenda

- Mô tả đề bài & mục tiêu
- Hai hướng triển khai (2 offers)
- So sánh/trade-off nhanh
- Câu hỏi cần xác nhận để chốt phương án
- Next step

---

## Mô tả đề bài (ánh xạ yêu cầu)

**Đề tài:** Xây dựng **Custom Add-on (Z\*)** trong SAP ERP cho phân hệ Bug Tracking.

Xây dựng hệ thống Bug Tracking với các chức năng bắt buộc:

- **Ghi nhận lỗi trong SAP:** T-code riêng (VD: `ZBUG_CREATE`), form nhập liệu + validation
- **Thông báo tự động:** Gửi email sau khi lưu (SAPconnect/SCOT)
- **Báo cáo danh sách:** ALV Grid (lọc/sắp xếp/drill-down)
- **In ấn:** SmartForms (xuất PDF/in giấy)
- **Thống kê:** Summary trên đầu màn hình ALV (COUNT/GROUP BY Status)
- **Đính kèm:** GOS (ảnh/log đính kèm theo Bug ID)

---

## ERP Context

![w:700 center](./images/erp-example.png)

---

## SAP Modules Cơ Bản

![w:800 center](./images/sap-modules.png)

---

## Offer A – On-Stack (ABAP trong SAP GUI)

**Tóm tắt:**  
Xây trực tiếp trong SAP bằng ABAP. SAP GUI + ALV Grid + SmartForms.

**Ngôn ngữ:** ABAP (SE38/SE80)

**Scope chính:**

- T-code nhập liệu (ZBUG_CREATE)
- ALV báo cáo (ZBUG_REPORT)
- SmartForms in ấn (ZBUG_FORM)
- Email qua SCOT
- GOS đính kèm

---

## Offer A – Ví dụ code ABAP

```abap
" Validate và lưu bug
IF lv_title IS INITIAL.
  MESSAGE 'Title is required' TYPE 'E'.
ENDIF.

INSERT zbug_tracker FROM ls_bug.
COMMIT WORK.

" Gửi email thông báo (CL_BCS)
```

---

## Offer A – Sơ đồ kiến trúc

![w:800 center](./images/onstack.png)

---

## Offer A – Ưu/Nhược

**Điểm mạnh**

- Tích hợp sâu (native SAP)
- Không cần hệ thống ngoài SAP
- Phù hợp yêu cầu “đúng chuẩn SAP”

**Cân nhắc**

- UX truyền thống (SAP GUI)
- Phụ thuộc quyền dev trên SAP

---

## Offer A – Kế hoạch triển khai (Plan)

![w:900 center](./images/plan-onstack.png)

---

## Offer B – Side-by-Side (Web App + SAP Integration)

**Tóm tắt:**  
Web app chạy song song SAP. Backend **Golang hoặc Node.js** + Frontend React, kết nối SAP qua RFC/OData.

**Ngôn ngữ:** Golang / Node.js (Express/Nest)

**Scope chính:**

- Web Dashboard (Grid/Kanban)
- Form nhập lỗi hiện đại
- Export PDF thay SmartForms
- Notification (Email/Webhook)
- SAP Connector (RFC/OData/BAPI)

---

## Offer B – Ví dụ code (Golang / Node.js)

```go
// Golang: ghi bug qua SAP RFC/OData
router.POST("/bugs", func(c *gin.Context) {
  // validate input, call SAP connector, save
})
```

```js
// Node.js: REST API + SAP connector
app.post("/bugs", async (req, res) => {
  // validate input, call SAP connector, save
});
```

---

## Offer B – Sơ đồ kiến trúc

![w:650 center](./images/side-by-side.png)

---

## Offer B – Ưu/Nhược

**Điểm mạnh**

- UX hiện đại, đa thiết bị
- Dễ mở rộng tính năng
- Tách rời SAP core (an toàn upgrade)

**Cân nhắc**

- Cần mở kết nối API vào SAP
- Vận hành thêm hạ tầng web (Docker/VM)

---

## Offer B – Kế hoạch triển khai (Plan)

![w:800 center](./images/plan-side-by-side.png)

---

## So sánh nhanh (Trade-off)

| Tiêu chí               | On-Stack (SAP GUI)  | Side-by-Side (Web App) |
| ---------------------- | ------------------- | ---------------------- |
| Trải nghiệm người dùng | Truyền thống        | Hiện đại, đa thiết bị  |
| Tích hợp SAP           | Native, sâu         | Qua RFC/OData          |
| Hạ tầng                | Không cần ngoài SAP | Cần Docker/VM          |
| Mở rộng tương lai      | Hạn chế             | Linh hoạt              |
| Quyền dev              | Cao                 | Trung bình             |

---

## Quy trình nghiệp vụ (sequence)

![Sequence center](./images/sequence.png)

---

## Câu hỏi cần xác nhận (để chốt)

1. **Hướng triển khai:** SAP GUI/ALV/SmartForms hay Web hiện đại?
2. **Quyền SAP Dev:** đã cấp đủ quyền chưa?
   - **Nếu có:** xin cấp account + quyền dev để triển khai on‑stack.
   - **Nếu không:** đề xuất bên mình tự dựng container, pull image, dựng SAP riêng để dev.
3. **RFC/OData:** có cho phép gọi từ ngoài vào SAP không?
4. **Báo cáo/In ấn:** SmartForms hay PDF?
5. **Email:** SCOT đã cấu hình chưa?

---

## Quyền SAP Dev tối thiểu (On-Stack)

- Developer Key
- SE11, SE38/SE80, SE93
- SE24 hoặc SE37
- SE51/SE41 (nếu làm màn hình)
- SMARTFORMS (in ấn)
- SCOT/SOST (email)
- SE09/SE10 (transport)

---

## Quy tắc chốt phương án

**Chọn On‑Stack** khi:

- Bắt buộc SAP GUI/ALV/SmartForms
- Có quyền dev đầy đủ

**Chọn Side‑by‑Side** khi:

- Muốn web UX tốt
- Có RFC/OData mở kết nối
- Chấp nhận PDF thay SmartForms

---

## Next Step

- Chốt hướng triển khai (Offer A / Offer B)
- Chốt scope chi tiết (field dữ liệu, flow trạng thái, phân quyền)
- Xác định timeline và tài nguyên cung cấp
- Chuẩn bị Tech Specs theo hướng đã chốt
