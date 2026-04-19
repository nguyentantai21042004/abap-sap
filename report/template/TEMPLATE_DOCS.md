# SAP Project Template Documentation

This document describes the purpose, structure, and usage of each Excel template file in this directory.

---

## 1. Configuration_Note.xlsx

**Purpose:** Documents SAP system configuration (customizing) settings applied during the project. Used by functional consultants to record SPRO configuration steps per module.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header — project name, module, version, created/revised/reviewed by |
| Record of change | Version history table: No, Effective Date, Version, Change Description, Reason, Reviewer, Approver |
| Checklist | Master checklist of all configuration items: Module, Sequence, Sheet name, Configuration Items, T-Code, Status, Comments |
| 4 (Customizing Guide) | Step-by-step customizing guide for Sales Document Types (e.g. Z_Credit Memo Request). Fields: Menu Path, T-Code, configuration screenshots/values |
| 5 (Customizing Guide) | Step-by-step customizing guide for Billing Types (e.g. Z_Credit Memo). Same structure as Sheet 4 |

**How to fill:**
1. Fill the **Cover** with project metadata and responsible persons.
2. Log every change in **Record of change** before modifying configuration.
3. Mark each item in **Checklist** with Status (`Done` / `In Progress` / `Pending`) after completing configuration.
4. For each configuration object, add a dedicated sheet following the Customizing Guide format (Menu Path → T-Code → screenshots/values).

---

## 2. Functional_Specification.xlsx

**Purpose:** Captures the functional specification of a single SAP development object (report, enhancement, form, interface, etc.). Written by functional consultants and reviewed by technical leads.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header — function ID, project, author, version, date |
| Histories | Change log: No, Version, Description, Sheet affected, Modified date, Modified by |
| Function Overview | High-level summary: Function ID, Processing Time (Online/Batch), Processing Type (Multilingual/Single), functional description |
| Process Flow | Screen flow diagram and business flow walkthrough |
| Screen Layout | Wireframe/layout mockup of each screen |
| Screen Definition | Field-level screen definition: Field No, Name, Type (Input/Output/Label), mandatory, validation rules |
| Smart Form Structure | Structure of any SAP Smart Form output (sections, windows, fields) |
| Message Definition | List of system messages: Message ID, Language, Message text |
| Processing Description | Step-by-step logic description: each processing step, conditions, and expected outcomes |

**How to fill:**
1. Assign a unique **Function ID** (e.g. `SD_REP_001`) on the Cover and carry it across all sheets.
2. Describe the high-level function in **Function Overview**.
3. Draw or paste the screen/process flow in **Process Flow**.
4. Define every screen field in **Screen Definition** with type and validation.
5. Document all messages in **Message Definition**.
6. Write the detailed processing logic (pseudo-code level) in **Processing Description**.

---

## 3. Technical_Specification.xlsx

**Purpose:** Provides the technical design and implementation plan for a SAP ABAP development object. Written by ABAP developers based on the Functional Specification.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header — function ID, project, developer, version, date |
| Histories | Change log: No, Version, Description, Sheet, Modified date, Modified by |
| Introduction | Function ID, Processing Time, Processing Type (Multilingual), technical overview |
| Scope | Defines what is in/out of scope for this development object |
| Assumptions | Lists assumptions and constraints known at design time |
| Functional Requirements | Maps functional requirements to technical components |
| Technical Design | Business Process mapping, WBS & Timeline, Data Dictionary objects (Package, Tables, Domain), technical architecture |
| Development Standards | Naming conventions for programs, classes, function modules, variables, etc. |
| Screen Layout | Technical screen layout details (Dynpro/Fiori screen IDs) |
| Screen Definition | Element-level screen field definitions with technical properties |
| Message Definition | Message class, ID, type, and text for all messages |
| Technical Implementation | Implementation notes, development standards applied, code structure |

**How to fill:**
1. Reference the Functional Specification **Function ID** on the Cover.
2. Complete **Scope** and **Assumptions** before design.
3. List all Data Dictionary objects (tables, structures, domains) in **Technical Design**.
4. Follow the **Development Standards** sheet for naming — do not deviate.
5. Document every screen element in **Screen Definition** with its Dynpro field name and type.
6. Record all ABAP message class entries in **Message Definition**.
7. Summarise implementation notes in **Technical Implementation** after coding.

---

## 4. Functional_Test.xlsx

**Purpose:** Records functional test cases and their execution results for a specific SAP function/process. Used during the System Integration Test (SIT) phase.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header — function/business flow name, version, author |
| Histories | Change log |
| Test Cases | Hierarchical test case list: Business Flow → NO. (1, 2, 2.1, 2.2 ...) → Test Contents / Test Cases |
| Test Result | Execution results per test case: evidence (screenshots), step-by-step results |
| Test Data Description | Description of test data sets used for each test case |

**How to fill:**
1. Group test cases by **Business Flow** at the top.
2. Use a hierarchical numbering scheme (1, 2, 2.1, 2.2, 3, 3.1 ...) to reflect main flows and sub-flows.
3. For each test case: write the test step, expected result, and actual result in **Test Cases**.
4. Paste evidence (screenshots) into **Test Result** referencing the test case number.
5. List test data (transaction data, master data) used in **Test Data Description**.

---

## 5. Test_Scenario.xlsx

**Purpose:** Defines end-to-end test scenarios that span multiple functions or steps. Used to validate complete business processes before UAT.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header |
| Histories | Change log |
| Test Scenario | Scenario matrix: No, Step Name, then columns per test case number (1, 2.1, 2.2 ...) — marks which steps are covered by which test case |
| Test Cases | Detailed test cases per business flow (same structure as Functional_Test.xlsx) |

**How to fill:**
1. List all business process steps (rows) in **Test Scenario**.
2. Map each step to the relevant test case number (columns) with a tick or reference.
3. Fill **Test Cases** with the detailed steps, expected results, and test data for each numbered test case.

---

## 6. UAT.xlsx

**Purpose:** User Acceptance Test documentation. Executed by the business/client team to formally accept the system before go-live.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header |
| Histories | Change log |
| Test Scenario | UAT scenario matrix: No, Step Name, Menu Path, T-Code, Scenario description |
| Test Cases | Detailed UAT test cases: Business Flow, NO., Test Contents/Test Cases |
| Test Result | UAT execution results: Test Case, Test Data, Evidence (screenshots), Created/Updated By, Created Date |

**How to fill:**
1. Fill **Test Scenario** with every UAT step, including the exact SAP menu path and T-Code.
2. Each scenario row maps to one or more test cases in **Test Cases**.
3. Business users execute tests and record Pass/Fail + evidence in **Test Result**.
4. The **Created/Updated By** and **Created Date** columns in Test Result serve as the sign-off record.

---

## 7. Unit_Test.xlsx

**Purpose:** Unit test documentation for individual ABAP development objects. Executed by the developer before handing off to functional testing.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Cover | Document header |
| Histories | Change log |
| UT | Unit test cases: Function ID, Function Name, NO. (1, 1.1, 1.2, 1.2.1 ...), Test Contents / Test Cases |
| Evidence | Screenshots/evidence of test execution |

**How to fill:**
1. One UT sheet per **Function ID**.
2. Use a deep hierarchical numbering (1.2.2.1, 1.2.2.2 ...) to cover all code branches and conditions.
3. For each test case, document: input values, expected output, actual output, Pass/Fail.
4. Paste screenshots into the **Evidence** sheet and reference them from the UT sheet.

---

## 8. Test_And_Fix_Bug.xlsx

**Purpose:** Bug and issue tracker used during testing phases (SIT, UAT). Each bug has a description, expected vs actual result, fix applied, and evidence.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Fix and bugs | Main tracker: No, Bug (title), Details, Expected result, Fix description, Evidence |
| Issue 2 | Overflow sheet for additional issues (same format) |
| Issue 4 | Overflow sheet for additional issues (same format) |

**How to fill:**
1. Log every bug found with a sequential **No.** in **Fix and bugs**.
2. Fill **Bug** (short title), **Details** (reproduction steps), and **Expected result**.
3. Once fixed, document the **Fix** applied.
4. Attach screenshots in the **Evidence** column/area of the same row.
5. Use Issue 2 / Issue 4 sheets when the main sheet exceeds capacity or to categorise by sprint/module.

---

## 9. TR_Management.xlsx

**Purpose:** Tracks SAP Transport Requests (TR) through environments (UAT → PRD). Ensures all changes are transported in the correct order and by the correct person.

**Sheets:**

| Sheet | Description |
|-------|-------------|
| Sheet1 | TR log: No., Owner, Account, Type, TR (number), Prerequisite TR, Description, Import By (UAT), Release Date (UAT), Import By (PRD), Release Date (PRD) |

**Columns explained:**

| Column | Description |
|--------|-------------|
| No. | Sequential number |
| Owner | Consultant who created the TR |
| Account | SAP user account used |
| Type | TR type (Workbench / Customizing) |
| TR | Transport Request number (e.g. `DEVK900123`) |
| Prerequisite TR | Any TR that must be imported before this one |
| Description | Brief description of what the TR contains |
| Import By (UAT) | Person responsible for importing into UAT |
| Release Date (UAT) | Date TR was released/imported to UAT |
| Import By (PRD) | Person responsible for importing into PRD |
| Release Date (PRD) | Date TR was released/imported to PRD |

**How to fill:**
1. Add a row for every new TR as soon as it is created.
2. Always check **Prerequisite TR** — import dependent TRs in order to avoid errors.
3. Fill UAT import details when the TR is transported to UAT.
4. Fill PRD import details only after UAT sign-off is obtained.

---

## Document Naming Convention

| Template File | Phase | Owner |
|---------------|-------|-------|
| Configuration_Note.xlsx | Blueprint / Realization | Functional Consultant |
| Functional_Specification.xlsx | Realization | Functional Consultant |
| Technical_Specification.xlsx | Realization | ABAP Developer |
| Unit_Test.xlsx | Realization | ABAP Developer |
| Functional_Test.xlsx | SIT | Functional Consultant |
| Test_Scenario.xlsx | SIT | Functional Consultant |
| Test_And_Fix_Bug.xlsx | SIT / UAT | Functional Consultant |
| UAT.xlsx | UAT | Business / Key User |
| TR_Management.xlsx | SIT / UAT / Go-Live | Basis / Team Lead |
