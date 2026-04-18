# Analysis v4

### CODE_F01.md — modified

`+7 / -6 lines`

```diff
--- previous/CODE_F01.md
+++ current/CODE_F01.md
@@ -585,12 +585,13 @@
   ls_field-fieldtext = 'SAP Username (USER_ID)'.
   APPEND ls_field TO lt_fields.
 
-  " v4.1 BUGFIX #2: Use empty tabname to avoid DDIC search help crash
-  " (ZBUG_USER_PROJEC-ROLE triggers internal error on F4 → use plain field)
+  " v4.2 BUGFIX #2: Use SVAL-VALUE (generic CHAR 40, no search help)
+  " to avoid DDIC search help crash on ZBUG_USER_PROJEC-ROLE
+  " and avoid "Field P_ROLE does not belong to table" error
   CLEAR ls_field.
-  ls_field-tabname   = space.
-  ls_field-fieldname = 'P_ROLE'.
-  ls_field-fieldtext = 'Role (M/D/T)'.
+  ls_field-tabname   = 'SVAL'.
+  ls_field-fieldname = 'VALUE'.
+  ls_field-fieldtext = 'Role (M=Manager / D=Developer / T=Tester)'.
   ls_field-value     = 'D'.   " Default = Developer
   APPEND ls_field TO lt_fields.
 
@@ -606,7 +607,7 @@
         lv_role  TYPE zde_bug_role.
   READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'USER_ID'.
   lv_uid  = ls_field-value.
-  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'P_ROLE'.
+  READ TABLE lt_fields INTO ls_field WITH KEY fieldname = 'VALUE'.
   lv_role = ls_field-value.
 
   IF lv_uid IS INITIAL.
```

## Files in this version

- `CODE_F00.md` — present
- `CODE_F01.md` — present
- `CODE_F02.md` — present
- `CODE_PAI.md` — present
- `CODE_PBO.md` — present
- `CODE_TOP.md` — present
