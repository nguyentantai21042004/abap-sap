# ❓ OPEN QUESTIONS — Câu hỏi cần confirm

> **Nguyên tắc:** Ưu tiên tìm câu trả lời từ 2 chương trình mẫu (`ZPG_BUGTRACKING_MAIN` + `ZPG_BUGTRACKING_DETAIL`) trước khi escalate lên client.

---

## ✅ Đã trả lời được (từ source code mẫu)

### Q1: Bug ID generation — dùng Number Range hay Counter?

- **Câu trả lời (từ ZPG):** ZPG dùng **counter** (`SELECT COUNT(*) + 1`) với format `{PROJECT_ID}_{N}`

  ```abap
  " ZPG_BUGTRACKING_DETAIL_F01 → FORM create_bug_id
  SELECT COUNT(*) FROM ztb_buginfo WHERE project_id = @w_project_id INTO @lv_num.
  lv_num = lv_num + 1.
  lv_bugid = |{ w_project_id }_{ lv_num }|.
  ```

- **ZBUG hiện tại:** Dùng Number Range (`ZNRO_BUG`) → format `BUG0000001`
- **Quyết định:** **Giữ Number Range** (đã có, professional hơn, không bị trùng khi concurrent). Nhưng thêm PROJECT_ID vào bug record.

### Q2: Project Status values — dùng text hay code?

- **Câu trả lời (từ ZPG):** Dùng **numeric code** trong DB, convert sang text khi hiển thị

  ```abap
  " ZPG_BUGTRACKING_MAIN_F01 → FORM select_data2
  CASE ls_project-project_status.
    WHEN '1'. ls_project-project_status = 'Opening'.
    WHEN '2'. ls_project-project_status = 'In process'.
    WHEN '3'. ls_project-project_status = 'Done'.
    WHEN '4'. ls_project-project_status = 'Cancel'.
  ENDCASE.
  ```

- **Quyết định:** Dùng numeric code (1/2/3/4) trong DB, map text trong ALV display.

### Q3: Role system — dùng CHAR(1) letter hay number?

- **Câu trả lời (từ ZPG):** Dùng **number** (1=Developer, 2=Functional, 3=PM)

  ```abap
  " ZPG_BUGTRACKING_MAIN_PAI
  IF ls_user_info-role <> '2'. " Role Functional (Tester)
    MESSAGE s056(zmsg_sap09_bugtrack) DISPLAY LIKE 'E'.
  ENDIF.
  ```

- **ZBUG hiện tại:** Dùng letter (T/D/M)
- **Quyết định:** **Giữ letter (T/D/M)** — đã implement trong tất cả FMs, readable hơn. Mapping khi cần tương thích.

### Q4: User-Project membership check — ở đâu?

- **Câu trả lời (từ ZPG):** Check ở **PAI trước khi thực hiện action**

  ```abap
  " ZPG_BUGTRACKING_MAIN_PAI → WHEN 'CREATE'
  SELECT COUNT(*) UP TO 1 ROWS FROM ztb_user_project
    WHERE user_id = sy-uname.
  IF sy-subrc <> 0.
    MESSAGE s065 DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  ```

- **Quyết định:** Tích hợp vào `Z_BUG_CHECK_PERMISSION` (centralized) thay vì rải rác trong PAI.

### Q5: Soft Delete — chỉ Bug hay cả Project?

- **Câu trả lời (từ ZPG):** **Cả hai** — bug và project đều có `IS_DEL` flag

  ```abap
  " Bug delete:
  UPDATE ztb_buginfo SET is_del = 'X' WHERE bug_id = ls_bug-bug_id.
  " Project delete:
  UPDATE ztb_project SET is_del = 'X' WHERE project_id = ls_project-project_id.
  " Select filter:
  SELECT * FROM ztb_project WHERE is_del IS INITIAL.
  ```

- **Quyết định:** Implement IS_DEL cho ZBUG_TRACKER, ZBUG_USERS, ZBUG_PROJECT.

### Q6: Ai được quyền xóa Project?

- **Câu trả lời (từ ZPG):** Chỉ **PM (role=3)** và project phải ở status **Done(3) hoặc Cancel(4)**

  ```abap
  " ZPG_BUGTRACKING_MAIN_PAI → WHEN 'DELETE_PRO'
  IF lv_username1-role <> '3'.
    MESSAGE s068 DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF ls_project3-project_status = TEXT-t03 OR ls_project3-project_status = TEXT-t04.
    ls_project3-is_del = 'X'.
  ELSE.
    MESSAGE s061(zmsg_sap09_bugtrack) DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  ```

- **Quyết định:** Áp dụng tương tự: Manager xóa project, phải Done/Cancel.

### Q7: Close Project — cần check tất cả bug resolved chưa?

- **Câu trả lời (từ ZPG):** **Có** — project chỉ chuyển sang Done khi tất cả bug đã Resolve

  ```abap
  " ZPG_BUGTRACKING_DETAIL_F01 → FORM save_prj
  PERFORM get_resolve_bug.
  IF gt_resolve_bug IS NOT INITIAL AND gs_project-project_status = 3.
    MESSAGE s000 WITH 'This project still has unresolved issues.' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  ```

- **Quyết định:** Implement check tương tự trước khi cho phép project status → Done.

### Q8: Nhân viên có thể thuộc nhiều project InProcess cùng lúc?

- **Câu trả lời (từ ZPG):** **Không** — validate khi chuyển project sang InProcess

  ```abap
  " ZPG_BUGTRACKING_DETAIL_F01 → FORM save_prj
  SELECT a~project_id, ... FROM ztb_project AS a
    INNER JOIN ztb_user_project AS b ON ...
    WHERE a~project_status = '2' " InProcess
      AND EXISTS (SELECT 1 FROM ztb_user_project WHERE ...).
  IF lt_result IS NOT INITIAL AND gs_project-project_status = 2.
    MESSAGE s000 WITH 'Employee cannot do many project at same time'.
    RETURN.
  ENDIF.
  ```

- **Quyết định:** Implement validation tương tự.

### Q9: Upload Evidence — phải upload trước khi save?

- **Câu trả lời (từ ZPG):** **Có** — ZPG bắt buộc upload BUGPROOF trước create, TESTCASE trước Fixed, CONFIRM trước Resolve

  ```abap
  " ZPG_BUGTRACKING_DETAIL_F01 → FORM save_bug
  " Create mode:
  SELECT SINGLE file_name FROM ztb_evd WHERE bug_id = @gs_bug_row-bug_id
    AND file_name LIKE '%BUGPROOF%'.
  IF lv_file IS INITIAL.
    MESSAGE 'Upload your BUGPROOF_ file before create, please !!'
  ENDIF.
  
  " Fixed by Dev:
  SELECT SINGLE file_name FROM ztb_evd WHERE bug_id = @gs_bug_row-bug_id
    AND file_name LIKE '%TESTCASE%'.
  
  " Resolve by Func:
  SELECT SINGLE file_name FROM ztb_evd WHERE file_name LIKE '%CONFIRM%'.
  ```

- **Quyết định:** Bắt buộc evidence upload trước status change (BUGPROOF/TESTCASE/CONFIRM).

### Q10: Validation khi create bug — check Bug Type vs Priority?

- **Câu trả lời (từ ZPG):** **Có** — Dump/VeryHigh/High → Priority phải High

  ```abap
  " ZPG_BUGTRACKING_DETAIL_F01 → FORM save_bug
  IF ( gs_bug_row-bug_type = '1' OR gs_bug_row-bug_type = '2'
    OR gs_bug_row-bug_type = '3' ) AND ( gs_bug_row-priority = '2' OR gs_bug_row-priority = '3' ).
    MESSAGE s047(zmsg_sap09_bugtrack) DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  ```

- **Quyết định:** Đánh giá thêm — ZBUG dùng Bug Type khác (C/F vs severity). Có thể bỏ qua hoặc adapt.

---

## ✅ Đã confirm từ khách hàng (24/03/2026)

### Q11: Bug Type classification — giữ ZBUG (Code/Config) hay dùng ZPG (Severity)?

- **Context:** ZBUG phân loại C(Code)/F(Config) phục vụ workflow branching. ZPG phân loại theo severity (Dump/VeryHigh/High/Normal/Minor).
- **✅ Confirmed:** Giữ **cả hai** — Bug Type (C/F) cho workflow branching + Severity (Dump/VeryHigh/High/Normal/Minor) cho priority enforcement.
- **Impact:** Cần thêm field `SEVERITY` (CHAR 1) vào `ZBUG_TRACKER`. Bug Type quyết định workflow (Code → Dev fix, Config → Tester self-fix), Severity quyết định priority + SLA.

### Q12: Server-side file storage — dùng cơ chế nào?

- **Context:** REQ-05 yêu cầu không dùng đường dẫn local. Có 3 options.
- **✅ Confirmed:** Dùng **GOS** (Generic Object Services).
- **Impact:** Sử dụng `CL_GOS_DOCUMENT_SERVICE` hoặc BDS (`BDS_BUSINESSDOCUMENT_CREA_TAB`) để attach file vào business object. Không cần cấu hình DMS/Content Server riêng. File lưu trong SAP DB, truy cập qua object key (BUG_ID).

### Q13: Email template — plain text hay HTML?

- **Context:** ZBUG hiện dùng CL_BCS gửi plain text. ZPG dùng SmartForms submit.
- **✅ Confirmed:** Dùng **SmartForms** để generate email body (HTML/PDF format).
- **Impact:** Tạo SmartForm `ZBUG_EMAIL_FORM` cho email notification. Gọi SmartForm → generate HTML → gửi qua CL_BCS. Professional hơn plain text.

### Q14: Đa ngôn ngữ — Message class hay hardcode text?

- **Context:** ZPG dùng Message Class `zmsg_sap09_bugtrack` đúng chuẩn SAP. ZBUG hardcode text.
- **✅ Confirmed:** **Có** — hỗ trợ đa ngôn ngữ (EN/VI), dùng Message Class.
- **Impact:** Tạo Message Class `ZBUG_MSG`. Migrate tất cả hardcoded messages sang Message Class. **Đây là điểm mạnh** khi demo — thể hiện tuân thủ chuẩn SAP enterprise, dễ mở rộng thêm ngôn ngữ khác (JP, KR...) mà không cần sửa code.

> [!TIP]
> **Điểm mạnh khi demo:** Đa ngôn ngữ qua Message Class là feature chuẩn SAP enterprise mà nhiều dự án bỏ qua. Highlight điểm này khi presentation — chỉ cần maintain translations trong SE91, không cần deploy code mới.

### Q15: Project Upload từ Excel — cần feature này không?

- **Context:** ZPG có upload project từ Excel (`TEXT_CONVERT_XLS_TO_SAP`). Feature này tạo ấn tượng tốt.
- **✅ Confirmed:** **Có** — cần feature upload project từ Excel.
- **Impact:**
  1. Tạo **Excel template chuẩn** trên MIME Repository (SMW0) với tên `ZTEMPLATE_PROJECT`
  2. Template bao gồm các cột: Project ID, Name, Description, Start Date, End Date, PM, Status, User ID, User Name, Email, Role
  3. User download template → điền data đúng format → upload lên
  4. Hệ thống dùng `TEXT_CONVERT_XLS_TO_SAP` parse data → validate (check trùng, check format date, check mandatory) → insert vào `ZBUG_PROJECT` + `ZBUG_USER_PROJECT`
  5. Nút **Download Template** trên GUI Status để user lấy template nhanh

### Q16: History Log — hiển thị ở đâu trên Module Pool UI?

- **Context:** ZBUG có ZBUG_HISTORY table (ưu điểm lớn). Cần quyết định cách hiển thị.
- **✅ Confirmed:** **Tab riêng** trên Bug Detail screen + có **filter/search cơ bản**.
- **Impact:**
  1. Tab "History" (SubScreen 0260) trên Bug Detail Tab Strip
  2. ALV Grid readonly hiển thị `ZBUG_HISTORY WHERE BUG_ID = current`
  3. Columns: Date, Time, User, Action Type (text mapped), Old Value, New Value, Reason
  4. Filter cơ bản: theo Action Type (dropdown), theo Date range
  5. Nếu đủ thời gian: thêm nút Export to Excel trên ALV toolbar (built-in)

---

## 📊 Summary

| Category | Status | Questions |
|----------|--------|-----------|
| Database design | ✅ All resolved | Q1, Q2, Q5 |
| Role & Permission | ✅ All resolved | Q3, Q4, Q6, Q11 |
| Business rules | ✅ All resolved | Q7, Q8, Q9, Q10, Q12, Q15 |
| UI/UX | ✅ All resolved | Q13, Q14, Q16 |
| **Tổng** | **✅ 16/16 đã giải quyết** | **0 câu hỏi mở** |
