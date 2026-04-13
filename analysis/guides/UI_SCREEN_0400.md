# UI Guide: Screen 0400 — Project List (INITIAL SCREEN)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v3.0
> **Đây là screen đầu tiên user thấy khi gõ ZBUG_WS**

---

## 1. Tạo Screen

1. **SE80** → mở `Z_BUG_WORKSPACE_MP`
2. Right-click program → **Create** → **Screen**
3. Nhập:
   - Screen Number: **`0400`**
   - Short Description: `Project List`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0400`** (loop — navigation handled bởi PAI code)
5. **Save**

---

## 2. Flow Logic

Chuyển sang tab **Flow Logic**. Xóa code mặc định, paste:

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_user_role.
  MODULE status_0400.
  MODULE init_project_list.

PROCESS AFTER INPUT.
  MODULE user_command_0400.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `init_user_role` | PBO | Load role từ ZBUG_USERS 1 lần duy nhất (CHECK gv_role IS INITIAL) |
| `status_0400` | PBO | SET PF-STATUS, exclude buttons theo role, SET TITLEBAR |
| `init_project_list` | PBO | SELECT project data + create/refresh ALV grid |
| `user_command_0400` | PAI | Handle: MY_BUGS, CREA_PRJ, CHNG_PRJ, DISP_PRJ, DEL_PRJ, UPLOAD, DN_TMPL, REFRESH, BACK/EXIT/CANC |

> **QUAN TRỌNG:** `init_user_role` PHẢI ở đây vì Screen 0400 là initial screen — nếu user chưa có role sẽ báo lỗi + LEAVE PROGRAM.

---

## 3. Layout (Screen Painter)

Click nút **Layout** (hoặc Ctrl+F7) → Screen Painter mở ra.

### Bước 1: Vẽ Custom Control cho ALV

1. **Cách 1:** Menu → Edit → Create Element → **Custom Control**
   **Cách 2:** Click icon Custom Control trên toolbar (icon hình ô vuông có chữ CC) → kéo vẽ
2. Vẽ hình chữ nhật **phủ gần toàn bộ screen** (~90% diện tích)
   - Để lại chút margin trên (cho toolbar) và dưới
   - Suggested position: Row 2, Col 2 → Row 20, Col 120 (tuỳ chỉnh)
3. **Name:** `CC_PROJECT_LIST`
   - ⚠️ Phải khớp **CHÍNH XÁC** với code: `container_name = 'CC_PROJECT_LIST'` (CODE_PBO.md line 380)

### Bước 2: Không cần thêm gì khác

- Tất cả buttons (MY_BUGS, CREA_PRJ, CHNG_PRJ, ...) nằm trên **GUI Status toolbar** — không cần vẽ pushbutton trên layout
- Không cần input fields — Project ALV hiển thị toàn bộ data

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: My Bugs | Create | Change | Display | Delete | ...]  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── CC_PROJECT_LIST ───────────────────────────────────────┐  │
│  │                                                           │  │
│  │   (ALV Grid sẽ hiện ở đây — auto-created bởi PBO code)   │  │
│  │                                                           │  │
│  │   PROJECT_ID | Project Name | Status | Start | End | Mgr  │  │
│  │   ──────────────────────────────────────────────────────   │  │
│  │   PRJ001     | Bug Track    | Open   | 01.04 | 30.06 | .. │  │
│  │   PRJ002     | SAP Upgrade  | InProc | 15.03 | 30.09 | .. │  │
│  │                                                           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Save + Activate

1. **Save** layout (Ctrl+S)
2. Quay lại SE51 main → **Activate** screen (Ctrl+F3)

---

## 5. Verify

### Element List Check:
SE80 → double-click Screen 0400 → tab **Element List** → phải thấy:

| Element | Type | Name |
|---------|------|------|
| Custom Control | CUSTOM CONTROL | `CC_PROJECT_LIST` |
| OK Code | OK | `GV_OK_CODE` |

> OK Code field: Nếu chưa có, vào tab **Attributes** → Element List → thêm OK Code field name = `GV_OK_CODE`. Hoặc Screen Painter tự thêm khi bạn set flow logic có MODULE ... INPUT.

### Quick Test:
Sau khi activate, thử:
1. SE93 → ZBUG_WS → kiểm tra initial screen = 0400
2. Chạy ZBUG_WS → phải thấy Project ALV (nếu có data trong ZBUG_PROJECT)
3. Toolbar phải hiện đúng buttons theo role

---

## 6. GUI Status Reference

Screen này dùng **STATUS_0400**. Xem `UI_FINAL_STEPS.md` để tạo.

### Buttons trên STATUS_0400:

| # | FCode | Text | Icon | Visible |
|---|-------|------|------|---------|
| 1 | `MY_BUGS` | My Bugs | `ICON_BIW_REPORT` | All roles |
| 2 | *(separator)* | | | |
| 3 | `CREA_PRJ` | Create Project | `ICON_CREATE` | Manager only |
| 4 | `CHNG_PRJ` | Change | `ICON_CHANGE` | Manager only |
| 5 | `DISP_PRJ` | Display | `ICON_DISPLAY` | All |
| 6 | `DEL_PRJ` | Delete | `ICON_DELETE` | Manager only |
| 7 | *(separator)* | | | |
| 8 | `UPLOAD` | Upload Excel | `ICON_IMPORT` | Manager only |
| 9 | `DN_TMPL` | Download Template | `ICON_EXPORT` | Manager only |
| 10 | `REFRESH` | Refresh | `ICON_REFRESH` | All |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

### Title Bar:

Screen này dùng **TITLE_PROJLIST** — text = `&1` (nhận param "Project List" từ code).

---

## 7. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| ALV không hiện | Container name sai | Layout phải có `CC_PROJECT_LIST` (viết hoa, khớp code) |
| "Module init_user_role not found" | Code chưa activate | Activate tất cả includes trước (TOP → F00 → PBO → PAI → F01 → F02) |
| Toolbar không hiện buttons | GUI Status chưa tạo | Tạo STATUS_0400 trong SE41 trước |
| BACK không thoát program | OK Code chưa set | Screen Attributes → Element List → thêm GV_OK_CODE |
