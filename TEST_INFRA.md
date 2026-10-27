# E2E Test Infra: LMS Foreign Language Center

## Test Philosophy
- Opaque-box, requirement-driven. No dependency on implementation design.
- Methodology: Category-Partition + BVA + Pairwise + Workload Testing.

## Feature Inventory
| # | Feature | Source (requirement) | Tier 1 | Tier 2 | Tier 3 |
|---|---------|---------------------|:------:|:------:|:------:|
| 1 | Cross-Platform Shell & Responsive Layout | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ |
| 2 | Role-Based Auth & JWT Routing | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 3 | Core Modules & Live API Data Flow | ORIGINAL_REQUEST §R2 | 5 | 5 | ✓ |
| 4 | Teacher Workflows (Attendance, Logbook, Rubrics, Gradebook) | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 5 | Student Workflows (Timetable, Submissions, Report Card, VNPay QR) | ORIGINAL_REQUEST §R3 | 5 | 5 | ✓ |
| 6 | Build & Static Analysis Guardrails | ORIGINAL_REQUEST §R4 | 5 | 5 | ✓ |

## Test Architecture
- Test runner: `flutter test test/e2e/` and backend E2E runner
- Test case format: Dart component and integration test specs verifying end-user contracts
- Directory layout: `test/e2e/` (Flutter), `backend/test/` (NestJS)

## Real-World Application Scenarios (Tier 4)
| # | Scenario | Features Exercised | Complexity |
|---|----------|--------------------|------------|
| 1 | Super Admin configures branch, room, course, and views users list | F1, F2, F3 | High |
| 2 | Teacher logs into portal, views weekly schedule, takes 4-status attendance, saves logbook | F1, F2, F4 | High |
| 3 | Teacher evaluates student Speaking audio and Writing essay with criteria rubrics | F2, F4 | High |
| 4 | Student views personal timetable, submits audio & text assignments | F1, F2, F5 | High |
| 5 | Student checks digital report card & GPA ranking, reviews tuition invoice and simulates VNPay QR | F1, F2, F5 | High |

## Coverage Thresholds
- Tier 1: >=5 per feature (>=30 tests)
- Tier 2: >=5 per feature (>=30 tests)
- Tier 3: pairwise coverage of major feature interactions (>=10 tests)
- Tier 4: >=5 realistic application scenarios (>=5 tests)
- Total minimum: >=75 test cases
