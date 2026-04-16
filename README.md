# Z_BUG_WORKSPACE_MP — ABAP Bug Tracking System

**SAP System:** S40 | **Client:** 324 | **ABAP 7.70**
**Package:** `ZBUGTRACK` | **T-code:** `ZBUG_WS` | **Program:** `Z_BUG_WORKSPACE_MP`

Hệ thống Bug Tracking tập trung chạy trên SAP ERP bằng ABAP thuần túy (Module Pool).

---

## Status: Phase F — v5.0 Enhancement (IN PROGRESS)

Documentation hoàn thành. Bước tiếp theo: **viết CODE v5.0** (6 files trong `src/`).

---

## Repo Structure

```
abap-sap/
├── src/                           ← ABAP source code (copy vào SE80)
│   ├── CODE_TOP.md                → Z_BUG_WS_TOP  (global vars, types)           [v4.0]
│   ├── CODE_F00.md                → Z_BUG_WS_F00  (ALV field catalog, event handler)  [v4.0]
│   ├── CODE_F01.md                → Z_BUG_WS_F01  (business logic FORMs)         [v4.2]
│   ├── CODE_F02.md                → Z_BUG_WS_F02  (F4, long text, popup, download)   [v4.1]
│   ├── CODE_PBO.md                → Z_BUG_WS_PBO  (Process Before Output)        [v4.1]
│   └── CODE_PAI.md                → Z_BUG_WS_PAI  (Process After Input)          [v4.1]
│
├── screens/                       ← SE51 screen layout guides
│   ├── screen-0200-bug-list.md
│   ├── screen-0210-bug-search.md          ← v5.0 NEW (popup)
│   ├── screen-0220-search-results.md      ← v5.0 NEW (full screen)
│   ├── screen-0300-bug-detail.md
│   ├── screen-0370-status-transition.md   ← v5.0 NEW (popup)
│   ├── screen-0400-project-list.md
│   ├── screen-0410-project-search.md      ← v5.0 NEW (initial screen)
│   └── screen-0500-project-detail.md
│
├── database/                      ← DB table schemas
│   ├── table-fields.md            ← Source of truth cho tất cả DB fields
│   └── zbug-evidence.md           ← ZBUG_EVIDENCE guide (⚠️ chưa tạo trong SAP!)
│
├── deploy/
│   └── final-steps.md             ← Deployment checklist
│
├── docs/                          ← Project documentation
│   ├── CONTEXT.md                 ← START HERE — master context cho mọi session
│   ├── status-lifecycle.md        ← v5.0 bug lifecycle + role matrix (source of truth)
│   ├── status-lifecycle.pdf
│   ├── requirements.md            ← Feature requirements spec
│   ├── legacy-removal-guide.md    ← Danh sách legacy code cần exclude
│   ├── v5-bug-analysis.md         ← 11 bugs từ UAT với fix proposals
│   └── phase-f-v5-enhancement.md  ← Phase F implementation guide (v5.0)
│
├── tests/                         ← Test plans
│   ├── qc-test-plan.md            ← ~140 QC test cases
│   └── uat-happy-case.md          ← 43 UAT happy-path cases
│
└── verification/
    └── screenshots/               ← Proof of current SAP system state
```

---

## Navigation Flow (v5.0)

```
ZBUG_WS → Screen 0410 (Project Search)
  └── Execute → Screen 0400 (Project List)
        ├── Click Project → Screen 0200 (Bug List + Dashboard)
        │     ├── Create/Change/Display → Screen 0300 (Bug Detail)
        │     │     └── Change Status → Screen 0370 (Status Transition popup)
        │     ├── Search → Screen 0210 (Search popup)
        │     │     └── Execute → Screen 0220 (Search Results)
        │     └── Back → Screen 0400
        ├── Create/Change/Display Project → Screen 0500
        └── Back → Screen 0410 → Back → EXIT
```

---

## Next Steps

1. **Write CODE v5.0** — rewrite all 6 files in `src/` incorporating:
   - 11 bug fixes (`docs/v5-bug-analysis.md`)
   - 10-state lifecycle (`docs/status-lifecycle.md`)
   - 8 new features (`docs/phase-f-v5-enhancement.md`)

2. **Create new UI in SAP** (SE51/SE41):
   - 4 new screens: 0410, 0370, 0210, 0220
   - 4 new GUI Statuses + Title Bars
   - Update STATUS_0200 (+SEARCH button)

3. **Deploy + Test**:
   - Copy CODE v5.0 into SAP
   - Update SE93 (initial screen 0400 → 0410)
   - Run status migration script (`6` → `V`)
   - Full regression + UAT round 2

---

## Key Accounts

| Account | Role in ZBUG_USERS | SAP Access |
|---------|-------------------|------------|
| `DEV-089` | Manager (M) | SE11, SE38, SE80, SE93 — main account |
| `DEV-061` | Developer (D) | ALV Grid & SmartForms |
| `DEV-118` | Tester (T) | Bug management, Testing |

> Always read `docs/CONTEXT.md` before starting any work session.
