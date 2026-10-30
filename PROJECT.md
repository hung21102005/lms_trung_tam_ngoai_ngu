# Project: LMS Foreign Language Center

## Architecture
- **Frontend**: Flutter multiplatform (Web Desktop & Android Mobile)
  - State Management: `flutter_bloc`
  - Navigation & Routing: `go_router` with `RouteNames`
  - Dependency Injection: `get_it`
  - Network: Dio via `ApiClient` with `AuthInterceptor` (JWT Bearer token)
  - Responsive Shell: Desktop `width > 900` (persistent 260px sidebar + header + content canvas) vs Mobile `width <= 900` (AppBar + Drawer + BottomNavigationBar)
- **Backend**: NestJS modular application (`backend/`)
  - Global API Prefix: `/api/v1/` with automatic rewrite middleware for `/api/...`
  - ORM: Prisma with 33 models across PostgreSQL schema
  - Cache: Redis
  - Authentication: Passport JWT Bearer tokens with Role guards (`super_admin`, `teacher`, `student`, `academic_staff`, `parent`)
  - Ports: Windows host PostgreSQL on port 5432, project container on port 5433 (`POSTGRES_PORT=5433`), NestJS on port 3000

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Flutter Static Analysis Cleanliness | Fix 7 compile errors and warnings so `flutter analyze` runs with 0 errors | M1 | Survey (O1) |
| 2 | Network Response Unboxing Fix | Eliminate fatal `response.data` runtime crashes across 6 remote datasources | M1 | Survey (O3) |
| 3 | API Endpoint Alignment | Correct `/classes/sessions/:id` to `/sessions/:id` for session updates | M1 | Survey (O4) |
| 4 | Web Desktop Layout Parity (Admin, Teacher, Student) | Persistent 260px left sidebar, top header (search, term, notification, avatar), adaptive canvas | M2 | R1, Survey |
| 5 | Android Mobile UX Parity (Admin, Teacher, Student) | AppBar, slide-out Drawer, BottomNavigationBar for high frequency actions | M2 | R1, Survey |
| 6 | Role-Based Routing & Authentication | JWT Bearer token authentication, routing for admin, teacher, student | M2 | R2 |
| 7 | Teacher Teaching Schedule | View weekly teaching schedule from `/classes/my/schedule` | M3 | R3 |
| 8 | Teacher 4-Status Attendance | Mark attendance (Có mặt, Đi trễ, Phép, Không phép) via live API `/sessions/:id/attendance` | M3 | R3, Survey (O2) |
| 9 | Teacher Digital Lesson Logbook (Sổ đầu bài) | Log lesson topic and homework into live session `/sessions/:id` | M3 | R3, Survey (O2) |
| 10 | Teacher Rubric Grading for Speaking & Writing | Grade audio submissions & essays with criteria rubrics via `/submissions/:id/grade` | M3 | R3, Survey (O2) |
| 11 | Teacher Gradebook Updates | View and update student class gradebook scores via live API | M3 | R3, Survey (O2) |
| 12 | Student Personal Timetable | View personal class timetable via `/classes/my/schedule` | M4 | R3 |
| 13 | Student Assignment Submission | Submit audio recordings and text assignments via live API | M4 | R3 |
| 14 | Student Digital Report Card & GPA Ranking | View academic report, GPA ranking, and progress from `/reports/academic` | M4 | R3, Survey (O5) |
| 15 | Student Tuition & VNPay QR Payment | View tuition invoices and simulate VNPay QR payment via `/finance/invoices` | M4 | R3 |
| 16 | Admin Core Management Views | Users (`/users`), Branches (`/branches`), Admissions CRM (`/admissions/leads`), Courses (`/courses`) | M2 | R2 |
| 17 | E2E Testing Suite (Tiers 1-4) | Comprehensive opaque-box test suite covering all features with `TEST_READY.md` | E2E Track | R4 |
| 18 | Adversarial Coverage Hardening (Tier 5) | White-box stress testing, edge cases, and forensic integrity verification | M5 | R4 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Static Analysis, Core Network Parsing & API Alignment | Fix 7 compile errors, fix `response.data` crash in 6 datasources, fix session endpoint | none | DONE |
| M2 | Cross-Platform UI/UX Parity & Shell Navigation | Implement Web 260px sidebar + mobile Drawer for Student, add search to Admin header, verify auth routing, 0 RenderFlex overflows | M1 | DONE |
| M3 | Teacher Core Workflows Live Integration | Replace mock views with live BLoC/API calls for Attendance (4 statuses), Sổ đầu bài, Rubrics grading, Gradebook | M1, M2 | IN_PROGRESS |
| M4 | Student Core Workflows & Digital Report Card | Build digital report card & GPA ranking view, connect timetable, assignments submission, and VNPay QR | M1, M2 | PLANNED |
| M5 | Full Stack Integration, E2E Testing & Hardening | Pass 100% of E2E tests, Tier 5 adversarial tests, verify build and analyze guardrails | M1, M2, M3, M4 | PLANNED |

## Interface Contracts
### Flutter Frontend ↔ NestJS Backend
- Base URL: `http://localhost:3000/api/v1`
- Auth: `Authorization: Bearer <jwt_token>`
- Attendance: `POST /sessions/:sessionId/attendance` with `{ records: [{ studentId, status, note }] }` where status in `['present', 'late', 'excused', 'unexcused']`
- Session Logbook: `PATCH /sessions/:sessionId` with `{ topic, homework, notes }`
- Grading: `POST /classes/:classId/assignments/:assignmentId/submissions/:submissionId/grade` (or `/submissions/:id/grade`) with `{ score, feedback, rubricScores }`
- Academic Report: `GET /reports/academic?studentId=:id` or `GET /reports/academic?classId=:id`
- VNPay Payment: `POST /finance/invoices/:id/pay-online` returning `{ paymentUrl, qrCodeData }`

## Code Layout
- `lib/core/`: network (`api_client.dart`), router (`app_router.dart`, `route_names.dart`), constants (`api_endpoints.dart`)
- `lib/features/`:
  - `auth/`: presentation, domain, data
  - `dashboard/`: `admin_home_screen.dart`, `teacher_home_screen.dart`, `student_home_screen.dart`, views/
  - `attendance/`: presentation, domain, data
  - `assignments/`: presentation, domain, data
  - `reports/`: presentation, domain, data
  - `finance/`: presentation, domain, data
- `backend/src/modules/`: auth, users, branches, admissions, courses, classes, attendance, assignments, exams, finance, reports
