// ============================================================
// 02_org_structure.typ — ORGANIZATIONAL STRUCTURE
// ============================================================
#import "../template.typ": placeholder, hline

= ORGANIZATIONAL STRUCTURE

The system operates within *SAP System S40, Client 324* and is accessed through T-Code *ZBUG_WS*. Three distinct roles exist within the system, each mapped to a record in table *ZBUG_USERS* (field `ROLE`, CHAR 1).

== System Roles

#table(
  columns: (2cm, 3cm, 1fr, 4cm),
  align: (center, left, left, left),
  [*Code*], [*Role*], [*Description*], [*SAP Account (Demo)*],
  [`M`], [*Manager*],   [Full system access. Manages projects, assigns bugs, closes bugs, views dashboard statistics, manages user accounts.], [`DEV-089`],
  [`D`], [*Developer*], [Receives assigned bugs. Updates bug status (InProgress, Fixed, Pending, Rejected). Uploads fix evidence. Can only act on bugs where `DEV_ID = SY-UNAME`.], [`DEV-061`],
  [`T`], [*Tester*],    [Creates bugs, uploads bug report evidence. Verifies fixed bugs (Final Testing phase). Can also self-fix Config-type bugs as both Developer and Tester.], [`DEV-118`],
)

== Role Determination at Runtime

Role is resolved from table `ZBUG_USERS` on login:

```abap
SELECT SINGLE role FROM zbug_users INTO @gv_role
  WHERE user_id = @sy-uname
    AND is_del  <> 'X'
    AND is_active = 'X'.
```

== Project-Level Role Assignment

Each user can hold a different role per project, stored in `ZBUG_USER_PROJEC` (Key: MANDT + USER_ID + PROJECT_ID, field `ROLE`). This allows cross-project flexibility (e.g., a user may be Manager in Project A and Developer in Project B).

== Permission Matrix Summary

#table(
  columns: (1fr, 1.5cm, 1.5cm, 1.5cm),
  align: (left, center, center, center),
  [*Action*], [*M*], [*D*], [*T*],
  [Create Bug],                     [✓], [—], [✓],
  [Delete Bug],                     [✓], [—], [—],
  [Change Status (via Popup 0370)], [✓], [✓], [✓],
  [Assign / Reassign Bug],          [✓], [—], [—],
  [Upload Fix Evidence],            [✓], [✓], [—],
  [Upload Report Evidence],         [✓], [—], [✓],
  [Upload Verify Evidence],         [✓], [—], [✓],
  [View All Bugs],                  [✓], [—], [—],
  [Create / Edit Project],          [✓], [—], [—],
  [Add / Remove Project Users],     [✓], [—], [—],
  [View Dashboard Statistics],      [✓], [—], [—],
  [Download Templates],             [✓], [—], [✓],
  [Print SmartForm],                [✓], [✓], [✓],
  [Send Email],                     [✓], [✓], [✓],
)
