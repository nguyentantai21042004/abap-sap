# UI Guide: Screen 0300 — Bug Detail + 6 Subscreens (0310-0360)

> **Program:** `Z_BUG_WORKSPACE_MP` | **Version:** v4.0
> **Screen phức tạp nhất — Tab Strip với 6 tabs, Subscreen Area, fields + editors**
>
> v4.0 changes:
> - Subscreen 0310: BUG_TYPE/PRIORITY/SEVERITY → screen group FNC (Dev cannot edit)
> - Subscreen 0350: Real Evidence ALV (no longer placeholder)
> - STATUS_0300: +SENDMAIL, +DL_EVD buttons

---

## TỔNG QUAN

Screen 0300 là host screen chứa:
- **Tab Strip** `TS_DETAIL` (6 tabs)
- **Subscreen Area** `SS_TAB` (hiển thị 1 trong 6 subscreens tại 1 thời điểm)

| Tab | FCode | Subscreen | Nội dung |
|-----|-------|-----------|----------|
| Bug Info | `TAB_INFO` | **0310** | Input fields + Description mini editor |
| Description | `TAB_DESC` | **0320** | Long text editor (Text ID Z001) |
| Dev Note | `TAB_DEVNOTE` | **0330** | Long text editor (Text ID Z002) |
| Tester Note | `TAB_TSTR_NOTE` | **0340** | Long text editor (Text ID Z003) |
| Evidence | `TAB_EVIDENCE` | **0350** | **v4.0** Evidence ALV (upload/download/delete files) |
| History | `TAB_HISTORY` | **0360** | History ALV (readonly) |

---

# PHẦN 1: SCREEN 0300 (Host Screen)

## 1.1 Tạo Screen

1. **SE80** → Right-click program → **Create** → **Screen**
2. Screen Number: **`0300`**
3. Short Description: `Bug Detail`
4. Tab **Attributes**:
   - Screen Type: **Normal**
   - Next Screen: **`0300`**
5. **Save**

## 1.2 Flow Logic

> ⚠️ **CRITICAL v3.0 CHANGE:** Flow logic có thêm module `compute_bug_display_texts` so với v2.0!

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0300.
  MODULE load_bug_detail.
  MODULE compute_bug_display_texts.
  MODULE modify_screen_0300.
  CALL SUBSCREEN ss_tab INCLUDING sy-repid gv_active_subscreen.

PROCESS AFTER INPUT.
  CALL SUBSCREEN ss_tab.
  MODULE user_command_0300.
```

### Giải thích modules:

| Module | Include | Chức năng |
|--------|---------|-----------|
| `status_0300` | PBO | SET PF-STATUS, exclude buttons theo mode/role |
| `load_bug_detail` | PBO | Load bug data từ DB (1 lần duy nhất nhờ `gv_detail_loaded` flag) |
| `compute_bug_display_texts` | PBO | **v3.0 NEW** — Map status/priority/severity/bug_type codes → display text |
| `modify_screen_0300` | PBO | Enable/disable fields theo mode (Display/Change/Create) + role |
| `CALL SUBSCREEN ss_tab` | PBO | Load active subscreen vào Subscreen Area |
| `CALL SUBSCREEN ss_tab` | PAI | Process PAI of active subscreen |
| `user_command_0300` | PAI | Handle: SAVE, STATUS_CHG, UP_FILE, UP_REP, UP_FIX, tab switch, BACK/EXIT |

### Tại sao cần `compute_bug_display_texts` riêng?

Trong v2.0, display texts được compute trong `load_bug_detail`. Nhưng khi user thay đổi status (STATUS_CHG), data trong `gs_bug_detail` thay đổi mà **không reload từ DB** (flag prevents reload). Module riêng này luôn chạy mỗi PBO, đảm bảo display texts luôn đúng.

## 1.3 Layout — Tab Strip + Subscreen Area

Click **Layout** → Screen Painter mở ra.

### Bước 1: Vẽ Tab Strip

1. Menu → Edit → Create Element → **Tab Strip**
   (hoặc click icon Tab Strip trên toolbar)
2. Vẽ hình chữ nhật **phủ ~85% screen** (để chừa toolbar area phía trên)
   - Suggested: Row 2, Col 2 → Row 22, Col 130
3. Name: **`TS_DETAIL`**
   - ⚠️ Phải khớp với `CONTROLS: ts_detail TYPE TABSTRIP` trong CODE_TOP.md line 141
4. SAP hỏi số tabs → nhập **6**
5. SAP tự tạo 6 tab buttons. **Double-click từng tab button** để set:

| Tab # | Button Name | Text (trên tab) | Function Code |
|-------|------------|-----------------|---------------|
| 1 | `TAB_INFO` | `Bug Info` | `TAB_INFO` |
| 2 | `TAB_DESC` | `Description` | `TAB_DESC` |
| 3 | `TAB_DEVNOTE` | `Dev Note` | `TAB_DEVNOTE` |
| 4 | `TAB_TSTR_NOTE` | `Tester Note` | `TAB_TSTR_NOTE` |
| 5 | `TAB_EVIDENCE` | `Evidence` | `TAB_EVIDENCE` |
| 6 | `TAB_HISTORY` | `History` | `TAB_HISTORY` |

> **Cách set FCode cho tab button:** Double-click tab button → Attributes panel hiện ra → Field "FctCode" → nhập function code. Mỗi tab button **BẮT BUỘC** có FCode — nếu thiếu, tab switch sẽ không work.

### Bước 2: Vẽ Subscreen Area bên trong Tab Strip

1. Click vào **vùng trống bên trong tab strip body** (phần dưới tab buttons)
2. Menu → Edit → Create Element → **Subscreen Area**
3. Vẽ hình chữ nhật **lấp đầy** phần body của tab strip
   - Subscreen area phải nằm **BÊN TRONG** tab strip
4. Name: **`SS_TAB`**
   - ⚠️ Phải khớp với `CALL SUBSCREEN ss_tab` trong flow logic

### Bước 3: Verify Tab Strip Attributes

1. Double-click tab strip `TS_DETAIL` → check Attributes:
   - **Reference Field:** `TS_DETAIL` (ánh xạ tới CONTROLS declaration)
2. Double-click mỗi tab button → confirm FCode đã set đúng

### Layout Preview:

```
┌─────────────────────────────────────────────────────────────────┐
│ [Toolbar: Save | Change Status | Upload Evidence/Report/Fix]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─── TS_DETAIL ────────────────────────────────────────────┐   │
│  │ [Bug Info] [Description] [Dev Note] [Tester] [Evid] [His]│  │
│  │ ┌─── SS_TAB ──────────────────────────────────────────┐  │   │
│  │ │                                                     │  │   │
│  │ │  (Active subscreen hiển thị ở đây)                  │  │   │
│  │ │  Subscreen 0310/0320/0330/0340/0350/0360            │  │   │
│  │ │                                                     │  │   │
│  │ │                                                     │  │   │
│  │ └─────────────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 1.4 Save + Activate Screen 0300

---

# PHẦN 2: SUBSCREEN 0310 — Bug Info (Fields + Description Mini Editor)

> **Đây là subscreen phức tạp nhất** — nhiều input fields, display fields, screen groups, custom control.

## 2.1 Tạo Screen

1. SE80 → Create Screen → **`0310`**
2. Short Description: `Bug Info`
3. Screen Type: **Subscreen** ← QUAN TRỌNG, không phải Normal!
4. **Save**

## 2.2 Flow Logic

> ⚠️ **v4.1 BUGFIX #5 CHANGE:** Added `PROCESS ON VALUE-REQUEST` section for F4 help dropdowns!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_desc_mini.

PROCESS AFTER INPUT.

PROCESS ON VALUE-REQUEST.
  FIELD gs_bug_detail-status             MODULE f4_bug_status.
  FIELD gs_bug_detail-priority           MODULE f4_bug_priority.
  FIELD gs_bug_detail-severity           MODULE f4_bug_severity.
  FIELD gs_bug_detail-bug_type           MODULE f4_bug_type.
  FIELD gs_bug_detail-project_id         MODULE f4_bug_project.
  FIELD gs_bug_detail-tester_id          MODULE f4_bug_tester.
  FIELD gs_bug_detail-dev_id             MODULE f4_bug_dev.
  FIELD gs_bug_detail-verify_tester_id   MODULE f4_bug_verify.
```

> **v3.0:** Module `init_desc_mini` tạo mini editor lazily + chỉ load text lần đầu (preserves user edits khi switch tab).
>
> **v4.1 BUGFIX #5 — PROCESS ON VALUE-REQUEST (POV):**
> POV block enables F4 dropdown help for all key fields on Bug Info tab.
> When user presses F4 on any of these fields, SAP calls the corresponding module
> which shows a value list popup (`F4IF_INT_TABLE_VALUE_REQUEST` FM) and assigns
> the selected value back to the screen field.
>
> POV modules are defined in `CODE_PAI.md` (v4.1). They call PERFORM f4_* in `CODE_F02.md`.
>
> | Field | Module | FORM called |
> |-------|--------|-------------|
> | STATUS | `f4_bug_status` | `f4_status` |
> | PRIORITY | `f4_bug_priority` | `f4_priority` |
> | SEVERITY | `f4_bug_severity` | `f4_severity` |
> | BUG_TYPE | `f4_bug_type` | `f4_bug_type` |
> | PROJECT_ID | `f4_bug_project` | `f4_project_id` |
> | TESTER_ID | `f4_bug_tester` | `f4_user_id` |
> | DEV_ID | `f4_bug_dev` | `f4_user_id` |
> | VERIFY_TESTER_ID | `f4_bug_verify` | `f4_user_id` |

## 2.3 Layout — Fields

### Bước 1: Thêm fields từ work area GS_BUG_DETAIL

1. Trong Layout Editor → click **Dict/Program Fields** (icon hình quyển sách trên toolbar)
2. Table/Field Name: `GS_BUG_DETAIL` → click **Get from Program**
3. SAP liệt kê tất cả fields. **Tick chọn** các fields sau:

| # | Field Name | Label | Type (SE11) |
|---|-----------|-------|-------------|
| 1 | `GS_BUG_DETAIL-BUG_ID` | Bug ID | CHAR 10 |
| 2 | `GS_BUG_DETAIL-TITLE` | Title | CHAR 100 |
| 3 | `GS_BUG_DETAIL-PROJECT_ID` | Project ID | CHAR 20 |
| 4 | `GS_BUG_DETAIL-STATUS` | Status | CHAR 20 |
| 5 | `GS_BUG_DETAIL-PRIORITY` | Priority | CHAR 1 |
| 6 | `GS_BUG_DETAIL-SEVERITY` | Severity | CHAR 1 |
| 7 | `GS_BUG_DETAIL-BUG_TYPE` | Bug Type | CHAR 1 |
| 8 | `GS_BUG_DETAIL-SAP_MODULE` | SAP Module | CHAR 20 |
| 9 | `GS_BUG_DETAIL-TESTER_ID` | Tester | CHAR 12 |
| 10 | `GS_BUG_DETAIL-DEV_ID` | Developer | CHAR 12 |
| 11 | `GS_BUG_DETAIL-VERIFY_TESTER_ID` | Verify Tester | CHAR 12 |
| 12 | `GS_BUG_DETAIL-CREATED_AT` | Created Date | DATS 8 |

4. Click **Enter** → SAP tạo label + input field cho mỗi field
5. Kéo thả sắp xếp theo layout preview bên dưới

### Bước 2: Thêm Display Text fields

1. Dict/Program Fields → Variable: `GV_STATUS_DISP` → **Get from Program**
2. Đặt field cạnh STATUS field → **Set Input = OFF** (display-only, không sửa được)
3. Lặp lại cho:

| Variable | Đặt cạnh | Purpose |
|----------|---------|---------|
| `GV_STATUS_DISP` | `GS_BUG_DETAIL-STATUS` | Hiện text "New"/"Assigned"/... thay vì code "1"/"2" |
| `GV_PRIORITY_DISP` | `GS_BUG_DETAIL-PRIORITY` | Hiện "High"/"Medium"/"Low" thay vì "H"/"M"/"L" |
| `GV_SEVERITY_DISP` | `GS_BUG_DETAIL-SEVERITY` | Hiện "Dump/Critical"/"Normal"/... thay vì "1"/"4" |
| `GV_BUG_TYPE_DISP` | `GS_BUG_DETAIL-BUG_TYPE` | Hiện "Functional"/"Performance"/... thay vì "1"/"2" |

> **Cách set Input = OFF:** Double-click field → Attributes tab → "Input" checkbox → **uncheck**.

### Bước 3: Set Screen Groups (Group1)

Double-click từng field → tab **Attributes** → field **Group1** → nhập:

| Field | Group1 | Purpose |
|-------|--------|---------|
| `GS_BUG_DETAIL-BUG_ID` | **`BID`** | **v4.1:** ALWAYS display-only (auto-generated, shows "(Auto)" in Create) |
| `GS_BUG_DETAIL-PROJECT_ID` | **`PRJ`** | Locked khi tạo bug từ project context |
| `GS_BUG_DETAIL-TITLE` | **`EDT`** | Editable (disabled khi Display mode) |
| `GS_BUG_DETAIL-STATUS` | **`EDT`** | Editable |
| `GS_BUG_DETAIL-PRIORITY` | **`FNC`** | **v4.0** — Dev cannot edit (Tester/Manager only) |
| `GS_BUG_DETAIL-SEVERITY` | **`FNC`** | **v4.0** — Dev cannot edit (Tester/Manager only) |
| `GS_BUG_DETAIL-BUG_TYPE` | **`FNC`** | **v4.0** — Dev cannot edit (Tester/Manager only) |
| `GS_BUG_DETAIL-SAP_MODULE` | **`EDT`** | Editable |
| `GS_BUG_DETAIL-TESTER_ID` | **`TST`** | Chỉ Tester/Manager sửa được |
| `GS_BUG_DETAIL-VERIFY_TESTER_ID` | **`TST`** | Chỉ Tester/Manager sửa được |
| `GS_BUG_DETAIL-DEV_ID` | **`DEV`** | Chỉ Developer/Manager sửa được |
| `GS_BUG_DETAIL-CREATED_AT` | *(none)* | Always display-only → **Set Input = OFF** |
| `GV_STATUS_DISP` | *(none)* | Always display-only (Input = OFF) |
| `GV_PRIORITY_DISP` | *(none)* | Always display-only |
| `GV_SEVERITY_DISP` | *(none)* | Always display-only |
| `GV_BUG_TYPE_DISP` | *(none)* | Always display-only |

### Screen Group Logic (reference — CODE_PBO.md line 234-288):

| Group | Behavior |
|-------|----------|
| `EDT` | Disabled khi `gv_mode = 'D'` (Display) hoặc `status = Closed` |
| `BID` | **v4.1 CHANGED:** ALWAYS `screen-input = 0` (auto-generated, never editable) |
| `PRJ` | Disabled khi Create mode + `gv_current_project_id` đã set (pre-filled, locked) |
| `TST` | Disabled khi `gv_role = 'D'` (Dev không sửa Tester fields) |
| `DEV` | Disabled khi `gv_role = 'T'` (Tester không sửa Dev fields) |
| `FNC` | **v4.0 NEW** — Disabled khi `gv_role = 'D'` (Dev không sửa), hoặc Display mode, hoặc Closed |

> **⚠️ v4.0 CHANGE:** BUG_TYPE, PRIORITY, SEVERITY chuyển từ Group `EDT` sang Group `FNC`. Developer chỉ đọc các trường này — chỉ Tester/Manager mới sửa được.

### Bước 4: Thêm Group Boxes (optional — tăng UX)

1. Menu → Edit → Create Element → **Box**
2. Vẽ box quanh nhóm fields → set Text:

| Box Text | Fields bên trong |
|----------|-----------------|
| `Bug Information` | BUG_ID, TITLE, PROJECT_ID, STATUS + status_disp, PRIORITY + priority_disp |
| `Classification` | SEVERITY + severity_disp, BUG_TYPE + bug_type_disp, SAP_MODULE |
| `Assignment` | TESTER_ID, DEV_ID, VERIFY_TESTER_ID, CREATED_AT |
| `Description` | CC_DESC_MINI (custom control) |

### Bước 5: Thêm Description Mini Editor (Custom Control)

1. Menu → Edit → Create Element → **Custom Control**
2. Vẽ hình chữ nhật ở **phần dưới** screen (~60 chars wide x 4 lines high)
3. Name: **`CC_DESC_MINI`**
   - ⚠️ Khớp code: `container_name = 'CC_DESC_MINI'` (CODE_PBO.md line 267)

### Bước 6: Đổi Label Text (optional — cho đẹp)

Double-click label → sửa text:
- BUG_ID → `Bug ID`
- TITLE → `Title *` (dấu * = required)
- PROJECT_ID → `Project *`
- STATUS → `Status`
- PRIORITY → `Priority`
- SEVERITY → `Severity`
- BUG_TYPE → `Bug Type`
- SAP_MODULE → `SAP Module`
- TESTER_ID → `Tester`
- DEV_ID → `Developer`
- VERIFY_TESTER_ID → `Verify Tester`
- CREATED_AT → `Created Date`

### Layout Preview:

```
┌─ Bug Information ──────────────────────────────────────────────┐
│ Bug ID:        [__________]                                    │
│ Title *:       [____________________________________________]  │
│ Project *:     [____________________]                          │
│ Status:        [____________________] → [New          ] (disp) │
│ Priority:      [_] → [Medium      ] (disp)                    │
└────────────────────────────────────────────────────────────────┘
┌─ Classification ──────────────────────────────────────────────┐
│ Severity:      [_] → [Normal      ] (disp)                    │
│ Bug Type:      [_] → [Functional  ] (disp)                    │
│ SAP Module:    [____________________]                          │
└────────────────────────────────────────────────────────────────┘
┌─ Assignment ──────────────────────────────────────────────────┐
│ Tester:        [____________]                                  │
│ Developer:     [____________]                                  │
│ Verify Tester: [____________]                                  │
│ Created Date:  [__________] (display-only)                     │
└────────────────────────────────────────────────────────────────┘
┌─ Description ─────────────────────────────────────────────────┐
│ ┌──────────────────────────────────────────────────────────┐  │
│ │ CC_DESC_MINI — cl_gui_textedit, 3-4 dòng               │  │
│ │ (Mini editor cho quick description)                      │  │
│ └──────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## 2.4 Save + Activate Screen 0310

---

# PHẦN 3: SUBSCREEN 0320 — Description (Long Text Z001)

## 3.1 Tạo Screen

1. SE80 → Create Screen → **`0320`**
2. Short Description: `Description Long Text`
3. Screen Type: **Subscreen**

## 3.2 Flow Logic

> ⚠️ **v3.0 CHANGE:** Không còn empty — có PBO module!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_long_text_desc.

PROCESS AFTER INPUT.
```

> Module `init_long_text_desc` (CODE_PBO.md line 293) tạo editor lazily + load text từ DB lần đầu.

## 3.3 Layout

1. Vẽ **Custom Control** chiếm **toàn bộ** subscreen area
2. Name: **`CC_DESC`**
   - ⚠️ Khớp code: `container_name = 'CC_DESC'` (CODE_PBO.md line 295)

### Layout Preview:

```
┌──────────────────────────────────────────────────────────────┐
│ ┌─── CC_DESC ──────────────────────────────────────────────┐ │
│ │                                                          │ │
│ │  (cl_gui_textedit — full description editor)             │ │
│ │  Text ID Z001 — Object ZBUG                              │ │
│ │                                                          │ │
│ │                                                          │ │
│ │                                                          │ │
│ └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

## 3.4 Save + Activate

---

# PHẦN 4: SUBSCREEN 0330 — Dev Note (Long Text Z002)

## 4.1 Tạo Screen

1. SE80 → Create Screen → **`0330`**
2. Short Description: `Dev Note Long Text`
3. Screen Type: **Subscreen**

## 4.2 Flow Logic

> ⚠️ **v3.0 CHANGE:** Không còn empty — có PBO module!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_long_text_devnote.

PROCESS AFTER INPUT.
```

> Module `init_long_text_devnote` (CODE_PBO.md line 313) tạo editor lazily. Testers get readonly.

## 4.3 Layout

1. Vẽ **Custom Control** chiếm **toàn bộ** subscreen area
2. Name: **`CC_DEVNOTE`**
   - ⚠️ **CRITICAL:** Tên là `CC_DEVNOTE` (KHÔNG CÓ underscore giữa DEV và NOTE)
   - ⚠️ Khớp code: `container_name = 'CC_DEVNOTE'` (CODE_PBO.md line 315)
   - ❌ Old v2.0 guide nói `CC_DEV_NOTE` — **SAI**, đã sửa trong v3.0

## 4.4 Save + Activate

---

# PHẦN 5: SUBSCREEN 0340 — Tester Note (Long Text Z003)

## 5.1 Tạo Screen

1. SE80 → Create Screen → **`0340`**
2. Short Description: `Tester Note Long Text`
3. Screen Type: **Subscreen**

## 5.2 Flow Logic

> ⚠️ **v3.0 CHANGE:** Không còn empty — có PBO module!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_long_text_tstrnote.

PROCESS AFTER INPUT.
```

> Module `init_long_text_tstrnote` (CODE_PBO.md line 334) tạo editor lazily. Devs get readonly.

## 5.3 Layout

1. Vẽ **Custom Control** chiếm **toàn bộ** subscreen area
2. Name: **`CC_TSTRNOTE`**
   - ⚠️ **CRITICAL:** Tên là `CC_TSTRNOTE` (KHÔNG CÓ underscore giữa TSTR và NOTE)
   - ⚠️ Khớp code: `container_name = 'CC_TSTRNOTE'` (CODE_PBO.md line 336)
   - ❌ Old v2.0 guide nói `CC_TSTR_NOTE` — **SAI**, đã sửa trong v3.0

## 5.4 Save + Activate

---

# PHẦN 6: SUBSCREEN 0350 — Evidence (ALV — v4.0 Real Implementation)

> **v4.0:** Không còn placeholder — Evidence ALV hiện danh sách files đã upload (metadata only, không load binary content).

## 6.1 Tạo Screen

1. SE80 → Create Screen → **`0350`**
2. Short Description: `Evidence / Attachments`
3. Screen Type: **Subscreen**

## 6.2 Flow Logic

> ⚠️ **v4.0 CHANGE:** Không còn empty — có PBO module!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_evidence_alv.

PROCESS AFTER INPUT.
```

> Module `init_evidence_alv` (CODE_PBO.md line 384) loads evidence metadata from `ZBUG_EVIDENCE` table → creates/refreshes ALV grid in `CC_EVIDENCE` container.

## 6.3 Layout

1. Vẽ **Custom Control** chiếm **toàn bộ** subscreen area
2. Name: **`CC_EVIDENCE`**
   - ⚠️ Khớp code: `container_name = 'CC_EVIDENCE'` (CODE_PBO.md line 389)

### Layout Preview:

```
┌──────────────────────────────────────────────────────────────┐
│ ┌─── CC_EVIDENCE ────────────────────────────────────────┐   │
│ │                                                        │   │
│ │  (ALV Grid — Evidence file list)                       │   │
│ │                                                        │   │
│ │  EVD_ID  | File Name       | Type  | Size  | By  | On │   │
│ │  ────────────────────────────────────────────────────── │   │
│ │  0001    | BUGPROOF_01.xlsx| xlsx  | 25KB  | DEV | .. │   │
│ │  0002    | TESTCASE_01.doc | doc   | 12KB  | DEV | .. │   │
│ │                                                        │   │
│ └────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### ALV Columns (handled by code — `build_evidence_fieldcat` in CODE_F00.md):

| Column | Field | Type | Notes |
|--------|-------|------|-------|
| Evidence ID | `EVD_ID` | NUMC 10 | Auto-increment |
| File Name | `FILE_NAME` | CHAR 255 | Full filename |
| MIME Type | `MIME_TYPE` | CHAR 128 | e.g. application/pdf |
| File Size | `FILE_SIZE` | INT4 | Bytes |
| Created By | `ERNAM` | CHAR 12 | User who uploaded |
| Created On | `ERDAT` | DATS 8 | Upload date |

> **Performance:** Evidence ALV loads metadata only (no CONTENT field) — `SELECT evd_id file_name mime_type file_size ernam erdat FROM zbug_evidence WHERE bug_id = ...`

## 6.4 Save + Activate

---

# PHẦN 7: SUBSCREEN 0360 — History (ALV Readonly)

## 7.1 Tạo Screen

1. SE80 → Create Screen → **`0360`**
2. Short Description: `Change History`
3. Screen Type: **Subscreen**

## 7.2 Flow Logic

> ⚠️ **v3.0 CHANGE:** Không còn empty — có PBO module!

```abap
PROCESS BEFORE OUTPUT.
  MODULE init_history_alv.

PROCESS AFTER INPUT.
```

> Module `init_history_alv` (CODE_PBO.md line 355) delegates to `PERFORM load_history_data` (CODE_F01.md line 582) — creates/refreshes ALV.

## 7.3 Layout

1. Vẽ **Custom Control** chiếm **toàn bộ** subscreen area
2. Name: **`CC_HISTORY`**
   - ⚠️ Khớp code: `container_name = 'CC_HISTORY'` (CODE_F01.md line 602)

## 7.4 Save + Activate

---

# PHẦN 8: TỔNG KẾT — Container Names (v3.0 VERIFIED)

> **Bảng tham chiếu nhanh** — sử dụng bảng này để verify sau khi tạo screens.

| Screen | Type | Container Name | Code Reference | Flow Logic PBO |
|--------|------|---------------|----------------|----------------|
| 0300 | Normal | *(Tab Strip + Subscreen Area)* | — | 4 modules + CALL SUBSCREEN |
| 0310 | Subscreen | `CC_DESC_MINI` | CODE_PBO.md:267 | `MODULE init_desc_mini.` |
| 0320 | Subscreen | `CC_DESC` | CODE_PBO.md:295 | `MODULE init_long_text_desc.` |
| 0330 | Subscreen | **`CC_DEVNOTE`** ⚠️ | CODE_PBO.md:315 | `MODULE init_long_text_devnote.` |
| 0340 | Subscreen | **`CC_TSTRNOTE`** ⚠️ | CODE_PBO.md:336 | `MODULE init_long_text_tstrnote.` |
| 0350 | Subscreen | `CC_EVIDENCE` | CODE_PBO.md:389 | `MODULE init_evidence_alv.` |
| 0360 | Subscreen | `CC_HISTORY` | CODE_F01.md:602 | `MODULE init_history_alv.` |

> ⚠️ = Tên khác với v2.0 guide! Dùng tên KHÔNG CÓ underscore: `CC_DEVNOTE`, `CC_TSTRNOTE`.

---

# PHẦN 9: GUI Status Reference

Screen 0300 dùng **STATUS_0300**. Xem `UI_FINAL_STEPS.md` để tạo.

### Buttons trên STATUS_0300:

| # | FCode | Text | Icon | Notes |
|---|-------|------|------|-------|
| 1 | `SAVE` | Save | `ICON_SYSTEM_SAVE` | Hidden: Display mode |
| 2 | `STATUS_CHG` | Change Status | `ICON_CHANGE` | Hidden: Create mode |
| 3 | *(separator)* | | | |
| 4 | `UP_FILE` | Upload Evidence | `ICON_IMPORT` | Hidden: Create mode |
| 5 | `UP_REP` | Upload Report | `ICON_IMPORT` | Hidden: Dev role + Create mode |
| 6 | `UP_FIX` | Upload Fix | `ICON_IMPORT` | Hidden: Tester role + Create mode |
| 7 | *(separator)* | | | |
| 8 | `DL_EVD` | Download Evidence | `ICON_EXPORT` | **v4.0** — Download selected evidence file |
| 9 | `SENDMAIL` | Send Email | `ICON_MAIL` | **v4.0** — Send bug info via BCS API |

Standard: `BACK` (F3), `EXIT` (Shift+F3), `CANC` (F12)

> **v4.0 NOTE:** `DL_EVD` downloads the currently selected row from Evidence ALV (0350). `SENDMAIL` sends bug summary email via `cl_bcs`.

### Title Bar:

Screen này dùng **TITLE_BUGDETAIL** — text = `&1` (nhận "Create Bug" / "Change Bug: BUG0001" / "Display Bug: BUG0001").

---

# PHẦN 10: Activation Order

**Activate subscreens TRƯỚC, host screen SAU:**

1. Screen 0310 ← Activate
2. Screen 0320 ← Activate
3. Screen 0330 ← Activate
4. Screen 0340 ← Activate
5. Screen 0350 ← Activate
6. Screen 0360 ← Activate
7. **Screen 0300** ← Activate **SAU CÙNG**

> Nếu activate 0300 trước khi subscreens tồn tại, SAP sẽ warning (không block, nhưng runtime sẽ dump khi call subscreen).

---

# PHẦN 11: Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| Tab strip không switch | Tab button thiếu FCode | Double-click tab → set FctCode = TAB_INFO / TAB_DESC / etc. |
| Subscreen không hiện | SS_TAB name sai hoặc nằm ngoài tab strip | Verify Subscreen Area tên `SS_TAB`, nằm **BÊN TRONG** tab strip body |
| "Module init_long_text_desc not found" | Flow logic v3.0 nhưng code v2.0 | Re-copy CODE_PBO.md v3.0 vào Z_BUG_WS_PBO |
| Editor không hiện trên 0320/0330/0340 | Container name sai | Verify: CC_DESC / **CC_DEVNOTE** / **CC_TSTRNOTE** (no underscore!) |
| Fields không disable ở Display mode | Group1 chưa set | Double-click field → Attributes → Group1 = EDT/BID/PRJ/TST/DEV |
| Description mini editor trống | gs_bug_detail chưa load | Verify `load_bug_detail` chạy TRƯỚC `init_desc_mini` (đúng: nằm ở host 0300 PBO) |
| Tab highlight sai sau switch | `ts_detail-activetab` chưa sync | v3.0 code đã fix: set `ts_detail-activetab = gv_active_tab` mỗi PBO |
| User edits bị mất khi switch tab | PBO reload data từ DB | v3.0 code đã fix: `gv_detail_loaded` flag prevents re-read |
| Stale data từ bug trước hiện lên | Editors không freed khi BACK | v3.0 code đã fix: `cleanup_detail_editors` called on BACK/CANC/EXIT |
