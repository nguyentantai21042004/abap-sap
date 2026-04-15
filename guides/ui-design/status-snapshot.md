# UI Status — Current State (as-is)

> Ghi nhận từ ảnh chụp thực tế ngày 09/04/2026  
> System: S40 | Client: 324 | ABAP 7.70 | Package: ZBUGTRACK  
> **KHÔNG chỉnh sửa file này** — đây là bản snapshot trạng thái ban đầu để so sánh sau refactor

---

## Screen 0100 — Homepage

**Title:** "Bug Tracking Workspace"

**Toolbar (Application Toolbar):**
| Nút | Tác dụng |
|-----|---------|
| Bug List | Chuyển sang Screen 0200 |
| Project List | Chuyển sang Screen 0400 |
| More ▼ | SAP standard menu |

**Content area:** Hoàn toàn **trống** — không có dashboard, welcome message, stats, hay thông tin gì.

**Vấn đề ghi nhận:**
- [ ] Vùng content lãng phí 100% — không có giá trị UX
- [ ] User không biết mình đang ở đâu / dùng để làm gì nếu lần đầu vào
- [ ] Không có quick navigation sau khi login

---

## Screen 0200 — Bug List

**Toolbar (Application Toolbar):**
| Nút | Ghi chú |
|-----|---------|
| Create Bug | Mở Screen 0300 (Create mode) |
| Change | Mở Screen 0300 (Change mode) — cần chọn row trước |
| Display | Mở Screen 0300 (Display mode) |
| Delete | Xóa bug đã chọn |
| Refresh | Reload ALV |
| Print | In danh sách |
| More ▼ | SAP standard menu |

**ALV Grid — Columns:**
| Column | Field DB | Ghi chú |
|--------|---------|---------|
| Checkbox | — | Multi-select |
| Bug ID | BUG_ID | CHAR 10 |
| Title | TITLE | Bị truncate do width nhỏ |
| Project | PROJECT_ID | Hầu hết rows bị **trống** |
| Status | STATUS | Có color coding ✅ |
| Priority | PRIORITY | Hiển thị raw code (H/M/L) |
| Severity | SEVERITY | Hiển thị raw code |
| Type | BUG_TYPE | Cột **trống** trong dữ liệu thực |
| Module | SAP_MODULE | |
| Tester | TESTER_ID | |
| Verify Tester | VERIFY_TESTER_ID | Hầu hết **trống** |
| Developer | DEV_ID | |
| Created | CREATED_AT | |

**Color coding Status (đang hoạt động):**
- New = Gray
- Assigned = Orange
- In Progress = Pink/Red
- Fixed = Green

**Vấn đề ghi nhận:**
- [ ] Cột `Project` trống trên hầu hết records
- [ ] Cột `Type` trống trong dữ liệu thực
- [ ] Cột `Verify Tester` trống hầu hết
- [ ] PRIORITY hiển thị raw code (`H`, `M`, `L`) thay vì label (`High`, `Medium`, `Low`)
- [ ] SEVERITY hiển thị raw code thay vì label
- [ ] Title bị truncate — column quá hẹp
- [ ] Không có filter/search nhanh trên screen (phải dùng ALV standard filter)
- [ ] Không có total count hiển thị số bugs

---

## Screen 0300 — Create Bug

**Toolbar (Application Toolbar) — Create mode:**
| Nút | Ghi chú |
|-----|---------|
| Save | Lưu bug mới |
| Upload Report | **Logic chưa work** |
| Upload Fix | **Logic chưa work** |
| More ▼ | SAP standard menu |

> **NOTE**: `Print Bug` và `Upload Evidence` **KHÔNG xuất hiện** trong Create mode toolbar

**Tabstrip — 6 tabs:**
1. **Bug Info** (active khi mở)
2. Dev Note
3. Func Note
4. Root Cause
5. Evidence
6. History

**Tab "Bug Info" — Fields:**
| Label | Field DB | Type | Vấn đề |
|-------|---------|------|--------|
| PROJECT ID | PROJECT_ID | CHAR 20 | Trống — user phải nhập tay |
| BUG ID | BUG_ID | CHAR 10 | **Manual entry** — phải nhập tay |
| TITLE | TITLE | CHAR 100 | OK |
| DESCRIPTION | DESC_TEXT | STRING | Hiển thị là **single-line** input |
| SAP MODULE | SAP_MODULE | CHAR 20 | OK |
| PRIORITY | PRIORITY | CHAR 1 | Hiển thị raw code `M` |
| STATUS | STATUS | CHAR 20 | **Trống** khi tạo mới — không default |
| BUG TYPE | BUG_TYPE | CHAR 1 | OK |
| SEVERITY | SEVERITY | CHAR 1 | Hiển thị raw code |
| TESTER ID | TESTER_ID | CHAR 12 | OK |
| DEV ID | DEV_ID | CHAR 12 | OK |

**Vấn đề ghi nhận:**
- [ ] BUG ID phải nhập tay — không có auto-generate
- [ ] STATUS trống khi tạo mới (nên default = `New`)
- [ ] PRIORITY hiển thị raw code `M` thay vì `Medium`
- [ ] DESCRIPTION là single-line input — không phù hợp với STRING field dài
- [ ] Không có required field indicator (`*`) cho các field bắt buộc
- [ ] Layout phẳng — không có grouping (Basic Info / Assignment / Metadata)
- [ ] Vùng trắng lớn phía dưới form — lãng phí không gian
- [ ] `Upload Report` và `Upload Fix` trên toolbar chưa hoạt động

---

## Screen 0300 — Change/Display Bug

**Toolbar (Application Toolbar) — Change/Display mode:**
| Nút | Ghi chú |
|-----|---------|
| Change Status | Thay đổi trạng thái bug |
| Upload Evidence | **Logic chưa work** |
| Upload Report | **Logic chưa work** |
| Upload Fix | **Logic chưa work** |
| More ▼ | SAP standard menu |

> **CRITICAL**: **KHÔNG có nút Save** trong Change mode toolbar  
> → User không biết làm thế nào để lưu sau khi edit

**Tab "Bug Info" — Observations:**
| Vấn đề | Chi tiết |
|--------|---------|
| STATUS = `1` | Hiển thị raw code `1` thay vì `New` |
| PRIORITY = `M` | Hiển thị raw code `M` thay vì `Medium` |
| DESCRIPTION bị truncate | Hiển thị `Kiểm tra chức năng nhập li...` — cắt giữa chừng |
| PROJECT ID trống | BUG0000004 không có project |
| BUG ID có dotted border | Focus state — có thể edit được (nhưng không nên) |

**Vấn đề ghi nhận:**
- [ ] **Không có nút Save** — UX critical
- [ ] STATUS hiển thị raw code `1`
- [ ] PRIORITY hiển thị raw code `M`
- [ ] DESCRIPTION bị cắt — single-line không hiển thị đủ nội dung
- [ ] BUG ID có thể bị edit (nên là display-only sau khi tạo)
- [ ] `Upload Evidence`, `Upload Report`, `Upload Fix` trên toolbar chưa hoạt động

---

## Screen 0400 — Project List

**Toolbar (Application Toolbar):**
| Nút | Ghi chú |
|-----|---------|
| [Dropdown] | Search/filter field — không rõ filter theo gì |
| Create Project | Mở màn hình Project Detail |
| Change | Sửa project đã chọn |
| Display | Xem project |
| Delete | Xóa project |
| Upload Excel | Import nhiều projects từ file Excel |
| Download Template | Tải file Excel mẫu |
| Refresh | Reload ALV |
| More ▼ | SAP standard menu |

**ALV Grid — Columns:**
| Column | Field DB | Ghi chú |
|--------|---------|---------|
| Checkbox | — | |
| Project ID | PROJECT_ID | CHAR 20 |
| Project Na... | PROJECT_NAME | **Bị truncate** |
| Status | PROJECT_STATUS | CHAR 1 |
| Start Dat... | START_DATE | **Bị truncate** |
| End Date | END_DATE | |
| Manag... | PROJECT_MANAGER | **Bị truncate** |
| Note | NOTE | CHAR 255 |

**Vấn đề ghi nhận:**
- [ ] Grid hoàn toàn **trống** (không có dữ liệu test)
- [ ] Nhiều column header bị truncate: "Project Na...", "Start Dat...", "Manag..."
- [ ] PROJECT_STATUS hiển thị raw code thay vì label
- [ ] Dropdown search ở đầu toolbar — không rõ mục đích / field nào được filter

---

## Screen — Project Detail (Create / Change)

**Title:** "Project Detail"

**Toolbar (Application Toolbar):**
| Nút | Ghi chú |
|-----|---------|
| [Dropdown] | |
| Save | Lưu project |
| Add User | Thêm user vào project |
| Remove User | Xóa user khỏi project |
| More ▼ | SAP standard menu |

**Header navigation:** Back button (`<`) + SAP logo + App icon

**Fields:**
| Label | Field DB | Ghi chú |
|-------|---------|---------|
| Project ID: | PROJECT_ID | Manual entry, short input |
| Project Name | PROJECT_NAME | Wide input — **không có colon** |
| Description | DESCRIPTION | Wide input — **không có colon**, single-line |
| Start Date: | START_DATE | Short date field — không có date picker |
| End Date: | END_DATE | Short date field — không có date picker |
| Username: | PROJECT_MANAGER | Pre-filled `DEV-089` (current user) ✅ |
| Status | PROJECT_STATUS | Hiển thị raw `1` — **không có colon** |

**Sub-table (Team Members):**
| Column | Ghi chú |
|--------|---------|
| Username | USER_ID từ ZBUG_USER_PROJEC |
| Project ID | PROJECT_ID |

**Vấn đề ghi nhận:**
- [ ] PROJECT_STATUS hiển thị raw `1` thay vì `Active`
- [ ] Description là single-line — ZBUG_PROJECT.DESCRIPTION là CHAR 255, nên multiline
- [ ] Inconsistent label style: một số có colon (`Project ID:`, `Start Date:`), một số không (`Project Name`, `Description`, `Status`)
- [ ] Không có date picker cho Start/End Date
- [ ] Sub-table chỉ có 2 cột (Username + Project ID) — thiếu thông tin ROLE
- [ ] Project ID manual entry — nên xem xét pattern tự sinh
- [ ] Không có required field indicator

---

## Tổng hợp — Issues theo mức độ ưu tiên

### 🔴 Critical (ảnh hưởng functionality)
1. **Screen 0300 Change mode**: Không có nút Save
2. **Screen 0300**: BUG ID phải nhập tay — dễ trùng lặp / sai format

### 🟠 High (ảnh hưởng UX trực tiếp)
3. **Mọi màn hình**: Raw code hiển thị thay vì labels (STATUS = `1`, PRIORITY = `M`)
4. **Screen 0300**: DESCRIPTION single-line — mất nội dung dài
5. **Screen 0300**: STATUS không default khi tạo mới
6. **Screen — Project Detail**: DESCRIPTION single-line
7. **Screen — Project Detail**: Không có date picker

### 🟡 Medium (cải thiện UX)
8. **Screen 0100**: Homepage hoàn toàn trống
9. **Screen 0200 / 0400**: Column headers bị truncate
10. **Screen 0300**: Không có required field indicators
11. **Screen 0300**: Layout phẳng không có grouping
12. **Screen — Project Detail**: Inconsistent label style
13. **Screen 0400**: Dropdown search không rõ mục đích

### ⚪ Low (nice-to-have)
14. **Screen 0200**: PRIORITY / SEVERITY hiển thị raw code trong list
15. **Screen 0300**: Cần indicator rõ ràng khi ở Create vs Change vs Display mode
16. **Screen — Project Detail**: Sub-table thiếu cột ROLE
