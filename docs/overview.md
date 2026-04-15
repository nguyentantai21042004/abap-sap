# 🔍 OVERVIEW — SAP Bug Tracking System

> **Tài liệu tổng quan nhanh** — cung cấp bức tranh toàn cảnh cho reviewer / stakeholder.  
> **Deadline:** 03/04/2026 (Demo Day) — 10 ngày còn lại

---

## Dự án là gì?

Hệ thống **quản lý lỗi tập trung** (Bug Tracking) chạy hoàn toàn trên SAP ERP bằng ABAP. Thay thế các công cụ ngoài (Jira/Redmine) bằng giải pháp On-Stack trong SAP.

| Mục | Chi tiết |
|-----|---------|
| **System** | SAP S40, Client 324, ABAP 770 |
| **Package** | ZBUGTRACK |
| **Timeline** | 9 tuần (01/02–03/04/2026) |
| **Go-live** | 03/04/2026 (Demo Day) |

---

## Lịch sử phát triển

### Giai đoạn 1: MVP Core ✅

Xây dựng 3 bảng + 8 Function Modules + 7 Programs SE38 + 7 T-codes. Các tính năng độc quyền: **Auto-Assign** (gán bug tự động theo workload), **Centralized Permission**, **History Logging**, **Email (CL_BCS)**, **SmartForm**, **Config Bug workflow branching** (Code bug vs Config bug).

### Giai đoạn 2: Big Update ✅

Centralized Workspace (`ZBUG_WS`), 3 evidence paths, Bug Type (Code/Config), Dynamic UI với popup screens. Chi tiết → [update-guidance.md](update-guidance.md)

### Giai đoạn 3: Module Pool Integration 🔄 (HIỆN TẠI)

Khách yêu cầu tích hợp **Module Pool** (Dynpro screens) thay Selection Screen, thêm **Project entity**, phân quyền chi tiết, chuẩn hóa status. Tham chiếu từ 2 chương trình mẫu. Tất cả 12 requirements đã confirmed, 16/16 open questions đã resolved.

---

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---------|---------|
| `archived/` | Tài liệu planning & code từ giai đoạn 1-2 |
| `ZPG_BUGTRACKING_MAIN/` | Source code chương trình mẫu #1 (Bug List + Project List ALV) |
| `ZPG_BUGTRACKING_DETAIL/` | Source code chương trình mẫu #2 (Bug/Project Detail + Tab Strip) |
| **`analysis/`** | **📂 Tài liệu phân tích & kế hoạch đầy đủ cho Phase 3** |
| `update-guidance.md` | Hướng dẫn triển khai Big Update (5 phases chi tiết) |

---

## Tài liệu trong `analysis/`

| File | Nội dung |
|------|---------|
| [01-project-overview.md](analysis/01-project-overview.md) | Bối cảnh, 3 giai đoạn phát triển, cấu trúc repo |
| [02-business-requirements.md](analysis/02-business-requirements.md) | 12 yêu cầu (REQ-01→12) + Acceptance Criteria |
| [03-current-status.md](analysis/03-current-status.md) | Trạng thái hiện tại, GAP analysis, rủi ro |
| [04-implementation-phases.md](analysis/04-implementation-phases.md) | 5 phases: Database → Logic → Module Pool → Features → Testing |
| [05-milestones.md](analysis/05-milestones.md) | 10-day sprint, 7 milestones, daily schedule |
| [06-open-questions.md](analysis/06-open-questions.md) | 16 câu hỏi — tất cả đã resolved ✅ |
| [diff-analysis-and-upgrade-plan.md](analysis/diff-analysis-and-upgrade-plan.md) | So sánh chi tiết ZBUG vs ZPG |
| [full-requirements-module-pool.md](analysis/full-requirements-module-pool.md) | Specification đầy đủ cho Module Pool version |

---

## Kiến trúc mục tiêu

```
┌─────────────────────────────────────────────────────┐
│  PRESENTATION: Module Pool (Dynpro)                 │
│  Screen 0200: Bug List (ALV) + Project selector     │
│  Screen 0300: Bug Detail (Tab Strip + Notes)        │
│  Screen 0400: Project Management                    │
│  Screen 1000: Excel Upload                          │
│  GUI Status, F4 Help, Popup Confirm, Refresh        │
├─────────────────────────────────────────────────────┤
│  APPLICATION: Function Group ZBUG_FG (8+ FMs)       │
│  Auto-Assign │ Permission │ History │ Email(SF)     │
│  Create │ Update │ Reassign │ Upload(GOS)           │
├─────────────────────────────────────────────────────┤
│  DATABASE: 5 Tables + Message Class                 │
│  ZBUG_TRACKER │ ZBUG_USERS │ ZBUG_HISTORY           │
│  ZBUG_PROJECT │ ZBUG_USER_PROJECT (NEW)             │
│  Number Range + SAPScript + SmartForm + ZBUG_MSG    │
└─────────────────────────────────────────────────────┘
```

---

## 12 Yêu cầu (tất cả đã confirmed ✅)

| # | Yêu cầu | Giải pháp |
|---|---------|-----------|
| REQ-01 | 🏗 Module Pool UI | Dynpro screens thay Selection Screen |
| REQ-02 | 📁 Project entity | ZBUG_PROJECT + ZBUG_USER_PROJECT (M:N) |
| REQ-03 | 🔐 Phân quyền chi tiết | Mở rộng Z_BUG_CHECK_PERMISSION |
| REQ-04 | 🔄 Status chuẩn hóa | 9 states hợp nhất từ cả 2 hệ thống |
| REQ-05 | ☁️ Server-side file | **GOS** (Generic Object Services) |
| REQ-06 | ✅ Validate user | Check exists + project membership |
| REQ-07 | 🔃 Nút Refresh | GUI Status + refresh_table_display |
| REQ-08 | 📧 Email bắt buộc | **SmartForms** email body + CL_BCS |
| REQ-09 | 🏷️ Severity + Bug Type | Dual classification (workflow + priority) |
| REQ-10 | 🌐 Đa ngôn ngữ | **Message Class** ZBUG_MSG (EN/VI) |
| REQ-11 | 📊 Excel upload | Template SMW0 + TEXT_CONVERT_XLS_TO_SAP |
| REQ-12 | 📜 History Tab | ALV readonly + filter (Action Type/Date) |

> **Chi tiết đầy đủ:** Xem [analysis/02-business-requirements.md](analysis/02-business-requirements.md)
