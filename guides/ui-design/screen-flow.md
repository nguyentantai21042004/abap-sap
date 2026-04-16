# UI Screen Flow — Z_BUG_WORKSPACE_MP (New Project-First Navigation)

> **Cập nhật:** 09/04/2026 (session 4)
> **Thay thế:** Flow cũ dùng Screen 0100 (Hub) làm initial screen
> **Lý do:** Project là thực thể cha — bug bắt buộc thuộc 1 project

---

## 1. NAVIGATION DIAGRAM

```
T-code ZBUG_WS
    │
    ▼
Screen 0400 — PROJECT LIST (initial screen)
    │
    ├── [Click Project row / hotspot] ──► Screen 0200 — BUG LIST (project context)
    │       │                                │ gv_current_project_id = selected
    │       │                                │ gv_bug_filter_mode = 'P' (Project)
    │       │                                │ Shows ALL bugs of that project (no role filter)
    │       │                                │
    │       │   ┌─ [Create] ────────────────► Screen 0300 — BUG DETAIL (Create)
    │       │   │                                │ project_id pre-filled + locked
    │       │   │                                │ gv_mode = 'X'
    │       │   │                                │
    │       │   ├─ [Change] ────────────────► Screen 0300 — BUG DETAIL (Change)
    │       │   │                                │ gv_mode = 'C'
    │       │   │                                │
    │       │   ├─ [Display / hotspot] ─────► Screen 0300 — BUG DETAIL (Display)
    │       │   │                                │ gv_mode = 'D'
    │       │   │                                │
    │       │   ├─ [Delete] ────────────────► Soft delete + refresh ALV
    │       │   │
    │       │   └─ [Back] ─────────────────► Screen 0400 (Project List)
    │       │
    │       └── Screen 0300 — BUG DETAIL
    │               │ Tab Strip: 0310 / 0320 / 0330 / 0340 / 0350 / 0360
    │               │
    │               └─ [Back] ─────────────► Screen 0200 (Bug List)
    │
    ├── [My Bugs] ──────────────────────────► Screen 0200 — BUG LIST (my bugs mode)
    │       │                                    │ gv_current_project_id = CLEAR
    │       │                                    │ gv_bug_filter_mode = 'M' (My Bugs)
    │       │                                    │ Filters by role (cross-project)
    │       │                                    │ CREATE button HIDDEN
    │       │                                    │
    │       │   ├─ [Change] ────────────────► Screen 0300
    │       │   ├─ [Display / hotspot] ─────► Screen 0300
    │       │   └─ [Back] ─────────────────► Screen 0400
    │       │
    │       └── Screen 0300 — BUG DETAIL
    │               └─ [Back] ─────────────► Screen 0200 (My Bugs)
    │
    ├── [Create Project] ───────────────────► Screen 0500 — PROJECT DETAIL (Create)
    │       │                                    │ gv_mode = 'X'
    │       │                                    └─ [Back] → Screen 0400
    │
    ├── [Change Project] ───────────────────► Screen 0500 — PROJECT DETAIL (Change)
    │       │                                    │ gv_mode = 'C'
    │       │                                    └─ [Back] → Screen 0400
    │
    ├── [Display Project / hotspot] ────────► Screen 0500 — PROJECT DETAIL (Display)
    │       │                                    │ gv_mode = 'D'
    │       │                                    └─ [Back] → Screen 0400
    │
    └── [Back / Exit] ─────────────────────► LEAVE PROGRAM
```

---

## 2. SCREEN INVENTORY

| Screen | Type | Role | Initial? | Modules PBO | Modules PAI |
|--------|------|------|----------|-------------|-------------|
| 0100 | Normal | ~~Hub~~ **DEPRECATED** | ~~Yes~~ No | status_0100, init_user_role | user_command_0100 |
| 0200 | Normal | Bug List (ALV) | No | status_0200, init_bug_list | user_command_0200 |
| 0300 | Normal | Bug Detail (Tab Strip host) | No | status_0300, load_bug_detail, modify_screen_0300 | user_command_0300 |
| 0310 | Subscreen | Tab: Bug Info | — | *(none — fields bound to gs_bug_detail)* | *(none)* |
| 0320 | Subscreen | Tab: Description (Long Text) | — | init_desc_editor | *(none)* |
| 0330 | Subscreen | Tab: Dev Note (Long Text) | — | init_devnote_editor | *(none)* |
| 0340 | Subscreen | Tab: Tester Note (Long Text) | — | init_tstnote_editor | *(none)* |
| 0350 | Subscreen | Tab: Evidence (GOS) | — | init_evidence | *(none)* |
| 0360 | Subscreen | Tab: History (ALV) | — | *(history loaded via PAI)* | *(none)* |
| **0400** | **Normal** | **Project List (ALV)** | **Yes** | init_user_role, status_0400, init_project_list | user_command_0400 |
| 0500 | Normal | Project Detail + Table Control | No | status_0500, init_project_detail, modify_screen_0500 | user_command_0500, tc_users_modify |

---

## 3. KEY GLOBAL VARIABLES FOR NAVIGATION

| Variable | Type | Purpose |
|----------|------|---------|
| `gv_mode` | `CHAR1` | `D` = Display, `C` = Change, `X` = Create |
| `gv_role` | `ZDE_BUG_ROLE` | `T` = Tester, `D` = Developer, `M` = Manager |
| `gv_current_bug_id` | `ZDE_BUG_ID` | Currently selected bug |
| `gv_current_project_id` | `ZDE_PROJECT_ID` | Currently selected project |
| `gv_bug_filter_mode` | `CHAR1` | **NEW** — `P` = Project bugs, `M` = My Bugs |
| `gv_active_tab` | `CHAR20` | Active tab on Screen 0300 |
| `gv_active_subscreen` | `SY-DYNNR` | Active subscreen number (0310-0360) |

---

## 4. SCREEN 0100 — DEPRECATED

Screen 0100 (Homepage/Hub) **không được sử dụng** trong flow mới:
- Code PBO/PAI vẫn giữ nguyên (không xóa, tránh dump nếu ai đó call)
- T-code `ZBUG_WS` trỏ tới Screen **0400** thay vì 0100
- Không có navigation nào dẫn tới Screen 0100 nữa

---

## 5. SCREEN 0400 — PROJECT LIST (NEW INITIAL SCREEN)

### Vai trò:
- **Entry point** khi user mở T-code `ZBUG_WS`
- Hiển thị danh sách projects user có quyền xem
- Manager thấy ALL projects; Tester/Dev chỉ thấy projects được assign

### GUI Status: `STATUS_0400`

| Fcode | Text | Icon | Visible | Notes |
|-------|------|------|---------|-------|
| `BACK` | Back | ICON_SYSTEM_BACK | All | LEAVE PROGRAM (vì đây là initial screen) |
| `EXIT` | Exit | ICON_SYSTEM_END | All | LEAVE PROGRAM |
| `CANC` | Cancel | ICON_SYSTEM_CANCEL | All | LEAVE PROGRAM |
| `CREA_PRJ` | Create Project | ICON_CREATE | Manager only | CALL SCREEN 0500, mode X |
| `CHNG_PRJ` | Change Project | ICON_CHANGE | Manager only | CALL SCREEN 0500, mode C |
| `DISP_PRJ` | Display Project | ICON_DISPLAY | All | CALL SCREEN 0500, mode D |
| `DEL_PRJ` | Delete Project | ICON_DELETE | Manager only | Soft delete |
| `MY_BUGS` | My Bugs | ICON_BIW_REPORT | All | **NEW** — CALL SCREEN 0200, filter mode M |
| `REFRESH` | Refresh | ICON_REFRESH | All | Reload project data |
| `DN_TMPL` | Download Template | ICON_EXPORT | Manager only | Phase D |
| `UPLOAD` | Upload Excel | ICON_IMPORT | Manager only | Phase D |

### Hotspot:
- Click `PROJECT_ID` → **CALL SCREEN 0200** (Bug List, filter mode P, project context)

---

## 6. SCREEN 0200 — BUG LIST (DUAL MODE)

### Mode P — Project Bugs:
- `gv_bug_filter_mode = 'P'`
- `gv_current_project_id` is set
- Shows ALL bugs of that project (no role filter)
- Title: `"Bugs — <project_name>"`
- CREATE button visible (project context available)

### Mode M — My Bugs:
- `gv_bug_filter_mode = 'M'`
- `gv_current_project_id` is CLEAR
- Filters by role (same as old `select_bug_data` logic)
- Title: `"My Bugs — <username>"`
- CREATE button **HIDDEN** (no project context)

### GUI Status: `STATUS_0200`

| Fcode | Text | Visible | Notes |
|-------|------|---------|-------|
| `BACK` | Back | All | LEAVE TO SCREEN 0400 |
| `EXIT` | Exit | All | LEAVE PROGRAM |
| `CANC` | Cancel | All | LEAVE TO SCREEN 0400 |
| `CREATE` | Create Bug | Mode P only, not Dev | Hidden in Mode M |
| `CHANGE` | Change Bug | All | Selected row → mode C |
| `DISPLAY` | Display Bug | All | Selected row → mode D |
| `DELETE` | Delete Bug | Manager + Tester (Mode P) | Hidden in Mode M |
| `REFRESH` | Refresh | All | Reload data |

### Back navigation:
- Luôn quay về Screen 0400 (Project List) — cả Mode P lẫn Mode M

---

## 7. SCREEN 0300 — BUG DETAIL (Tab Strip)

### Tab Strip: `TS_DETAIL`

| Tab Button | Fcode | Subscreen | Content |
|------------|-------|-----------|---------|
| Bug Info | `TAB_INFO` | 0310 | Main fields + Description mini editor |
| Description | `TAB_DESC` | 0320 | Full description (Long Text Z001) |
| Dev Note | `TAB_DEVNOTE` | 0330 | Developer notes (Long Text Z002) |
| Tester Note | `TAB_TSTR_NOTE` | 0340 | Tester notes (Long Text Z003) |
| Evidence | `TAB_EVIDENCE` | 0350 | GOS attachments (Phase D) |
| History | `TAB_HISTORY` | 0360 | Change history ALV (readonly) |

### Subscreen 0310 — Bug Info:
- Fields bound to `gs_bug_detail` work area
- **Description mini editor**: `cl_gui_textedit` (3-4 dòng) trong custom container `CC_DESC_MINI`
- `PROJECT_ID`: pre-filled + **display-only** khi tạo bug từ project context
- `BUG_ID`: display-only after first save (Create → Change mode)
- `STATUS` / `PRIORITY`: hiển thị text (mapped) trên screen fields

### Back navigation:
- Quay về Screen 0200 (Bug List)

---

## 8. SCREEN 0500 — PROJECT DETAIL

### Fields bound to `gs_project`:
- PROJECT_ID, PROJECT_NAME, DESCRIPTION, PROJECT_STATUS
- START_DATE, END_DATE, PROJECT_MANAGER, NOTE

### Table Control: `TC_USERS`
- Shows users assigned to this project (from `ZBUG_USER_PROJEC`)
- Columns: USER_ID, ROLE, ERNAM, ERDAT

### Back navigation:
- Quay về Screen 0400 (Project List)

---

## 9. SE93 T-CODE CHANGE

```
Before: ZBUG_WS → Z_BUG_WORKSPACE_MP, Screen 0100
After:  ZBUG_WS → Z_BUG_WORKSPACE_MP, Screen 0400
```

**Steps:**
1. SE93 → Enter `ZBUG_WS` → Change
2. Change "Initial Screen" from `0100` to `0400`
3. Save + Activate

---

## 10. WHAT CHANGED (OLD vs NEW)

| Aspect | Old Flow | New Flow |
|--------|----------|----------|
| Initial screen | 0100 (Hub) | **0400** (Project List) |
| Hub screen | Required — choose Bug List or Project List | **Eliminated** — go straight to projects |
| Bug List entry | From Hub → Bug List (role-filtered) | From Project → Bug List (project-filtered) OR My Bugs (role-filtered) |
| Create Bug | Available everywhere | Only when project context exists |
| Project hotspot | Opens Project Detail (0500) | **Opens Bug List** (0200) with project filter |
| Back from Bug List | Goes to Hub (0100) | Goes to Project List (0400) |
| Back from Project List | Goes to Hub (0100) | **LEAVE PROGRAM** (it's initial screen) |
| gv_bug_filter_mode | N/A | **NEW** — `P` or `M` |

---

*File này mô tả luồng navigation sau khi refactor. Tham khảo `UI_REFACTOR_PLAN.md` cho chi tiết implementation 16 items.*
