# 📋 PROJECT OVERVIEW — SAP Bug Tracking Management System

> **Dự án:** SAP Bug Tracking Management System  
> **Loại:** Custom SAP Add-on (Z-Solution)  
> **Hệ thống:** S40 (FU), Client 324, SAP 770  
> **Package:** ZBUGTRACK  
> **Timeline:** 01/02/2026 – 03/04/2026 (9 tuần)  
> **Go-live:** 03/04/2026 (Demo Day)

---

## 1. Bối cảnh dự án

Xây dựng hệ thống quản lý lỗi tập trung (Bug Tracking) chạy hoàn toàn trên SAP ERP, sử dụng ABAP. Mục tiêu là thay thế các công cụ ngoài (Jira/Redmine) bằng giải pháp On-Stack trong SAP.

### 1.1 Giai đoạn 1: MVP ban đầu (ZBUG_*)

Hệ thống đầu tiên được xây dựng theo kiến trúc **SE38 Executable Programs + Function Modules**:

| Thành phần | Chi tiết |
|---|---|
| **Tables** | 3 bảng: `ZBUG_TRACKER`, `ZBUG_USERS`, `ZBUG_HISTORY` |
| **Function Modules** | 8 FMs trong Function Group `ZBUG_FG` |
| **Programs** | 7 executable programs (SE38) |
| **T-codes** | 7 T-codes riêng biệt |
| **Roles** | T(Tester), D(Developer), M(Manager) |
| **Status Flow** | 1(New) → W(Waiting) → 2(Assigned) → 3(InProgress) → 4(Fixed) → 5(Closed) |

**Điểm mạnh:** FM architecture (reusable/testable), Auto-Assign, Centralized Permissions, History Logging, Email (CL_BCS), SmartForm, Config Bug workflow branching.

### 1.2 Giai đoạn 2: Big Update (Centralized Workspace)

Dựa trên `update-guidance.md`, đã thực hiện nâng cấp lớn qua 5 phases:

1. **Database Layer:** Thêm `BUG_TYPE`, `REASONS`, 3 evidence paths (`ATT_REPORT/FIX/VERIFY`)
2. **Business Logic:** State tree mới cho Config Bug (Tester tự fix), mở rộng permission
3. **Presentation:** Xây dựng `Z_BUG_WORKSPACE` (ZBUG_HOME) = Centralized Workspace với ALV docking container
4. **UX Enhancements:** Popup Create/Update, Bug Type dropdown, Dynamic UI
5. **Testing & UAT**

### 1.3 Giai đoạn 3: Yêu cầu mới từ khách hàng (HIỆN TẠI)

Khách hàng đưa thêm yêu cầu mới **sau khi Big Update đã xong**:

> **Yêu cầu chính:** Phải tích hợp **Module Pool** ở trên cùng, sở hữu hoàn hảo logic của 2 chương trình mẫu (`ZPG_BUGTRACKING_MAIN` + `ZPG_BUGTRACKING_DETAIL`), đồng thời giữ nguyên các cải tiến độc quyền của ZBUG_*.

**Yêu cầu chi tiết (12 REQs — tất cả đã confirm):**

- Thêm thực thể **Project** ở trên Bug (REQ-02)
- Bảng **phân quyền chi tiết** cho Bug và Project (REQ-03)
- **Clear lại** Status states — 9 trạng thái hợp nhất (REQ-04)
- **GOS file storage** — không dùng đường dẫn local (REQ-05)
- **Validate user** khi create bug + check project membership (REQ-06)
- Nút **Refresh** trên UI (REQ-07)
- **Email bắt buộc** + SmartForms email body (REQ-08)
- **Severity + Bug Type** — dual classification (REQ-09)
- **Đa ngôn ngữ** EN/VI qua Message Class (REQ-10)
- **Upload Project từ Excel** với template chuẩn (REQ-11)
- **History Tab** + filter/search trên Bug Detail (REQ-12)

---

## 2. Hệ thống tham chiếu: ZPG_BUGTRACKING_*

Hai chương trình mẫu được cung cấp bởi khách hàng:

### ZPG_BUGTRACKING_MAIN (Module Pool)

- Selection Screen: 2 radio buttons (Project mode / Bug mode) + Upload mode
- 2 ALV Grids: Bug List (`GRID01`) + Project List (`GRID02`)
- Excel Upload/Download (4 templates từ MIME Repository)
- F4 Search Help: Project, Reporter, Developer
- 3 GUI Statuses, 3 Screens (0100, 0200, 1000)
- Validation: project/bug/manager/reporter/developer existence checks

### ZPG_BUGTRACKING_DETAIL (Module Pool)

- Multi-mode screen (Display/Change/Create) via `w_ok` flag
- Tab Strip: DEV note, FUNC note, CONFIRM note, Project note
- Long Text (SAPScript): READ_TEXT/SAVE_TEXT
- Table Control: User list in project
- DMS Integration: `ZFM_BUGTRACKING_MAINTENANCE`
- Email via SmartForms: `zpg_bugtracking_smartforms`
- Dynamic screen control: role-based field enable/disable

### Tables trong hệ thống mẫu

| Bảng | Mô tả | Key Fields |
|---|---|---|
| `ZTB_BUGINFO` | Thông tin Bug (21 fields) | project_id, bug_id |
| `ZTB_PROJECT` | Thông tin Project (16 fields) | project_id |
| `ZTB_USER_INFO` | User accounts (14 fields) | user_id |
| `ZTB_USER_PROJECT` | User-Project (M:N) (11 fields) | user_id, project_id |
| `ZTB_EVD` | Evidence/DMS | project_id, bug_id, docno |

### Status trong hệ thống mẫu

| Code | Status | Mô tả |
|---|---|---|
| 1 | Opening | Bug mới tạo |
| 2 | In Process by ABAP | Dev đang xử lý |
| 3 | In Process by Functional | Tester đang xử lý |
| 4 | Pending by ABAP | Chờ Dev |
| 5 | Pending by Functional | Chờ Tester |
| 6 | Fixed | Đã sửa xong |
| 7 | Resolve | Đã confirm hoàn tất |

### Roles trong hệ thống mẫu

| Code | Role |
|---|---|
| 1 | Developer |
| 2 | Functional (Tester) |
| 3 | Project Manager |

---

## 3. Thư mục dự án

```
abap-sap/
├── README.md                    ← File giới thiệu dự án (bạn đang đọc)
├── OVERVIEW.md                  ← Tổng quan nhanh cho reviewer
├── update-guidance.md           ← Hướng dẫn triển khai Big Update (5 phases)
├── ZPG_BUGTRACKING_MAIN/        ← Source code chương trình mẫu MAIN
│   ├── Includes/                ← TOP, PBO, PAI, F00, F01
│   ├── Screens/                 ← Screen definitions
│   ├── GUI Status/              ← Status screenshots
│   ├── Dictionary Structures/   ← Table/Structure definitions
│   └── Classes/                 ← Event handler class
├── ZPG_BUGTRACKING_DETAIL/      ← Source code chương trình mẫu DETAIL
│   ├── Includes/                ← TOP, PBO, PAI, F01
│   ├── Screens/                 ← Screen definitions  
│   └── GUI Status/              ← Status screenshots
├── analysis/                    ← 📂 TÀI LIỆU PHÂN TÍCH & KẾ HOẠCH
│   ├── 01-project-overview.md       ← Tổng quan dự án (file này)
│   ├── 02-business-requirements.md  ← Yêu cầu nghiệp vụ chi tiết
│   ├── 03-current-status.md         ← Trạng thái hiện tại
│   ├── 04-implementation-phases.md  ← Kế hoạch thực hiện theo phase
│   ├── 05-milestones.md             ← Milestones & Timeline
│   ├── 06-open-questions.md         ← 16 câu hỏi (tất cả đã resolved)
│   ├── diff-analysis-and-upgrade-plan.md  ← So sánh ZBUG vs ZPG
│   └── full-requirements-module-pool.md   ← Spec đầy đủ Module Pool
└── archived/                    ← Tài liệu giai đoạn planning + code trước đó
    ├── documentation/           ← Guides, requirements, proposals
    ├── images/                  ← Screenshots, diagrams
    ├── testing/                 ← Test cases & evidence
    ├── reports/                 ← Client/review reports
    ├── presentation/            ← Slides
    ├── CHANGELOG.md             ← Lịch sử thay đổi
    └── PROJECT_CHECKLIST.md     ← Checklist phases trước đó
```
