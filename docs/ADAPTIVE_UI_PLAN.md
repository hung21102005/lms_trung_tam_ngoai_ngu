# EduLMS Adaptive UI — audit and progress

Updated: 2026-10-28. Baseline rollback commit: `f84c81c627e05711b367248911db2f167fc71478`.

## Architecture audit

- Roles found in routes and home shells: student, teacher, parent, admin. Authentication has login, forgot password, first login setup.
- Navigation: `go_router` route table in `lib/core/router/app_router.dart`; role home shells in `lib/features/dashboard/presentation/screens/`. Student, teacher, and admin have mobile drawer/bottom navigation already. Feature screens also use direct detail routes.
- State and data: `flutter_bloc` for auth and feature screens, repositories/services and `getIt` dependency injection. Mobile UI must call the same Bloc/repository methods as desktop.
- Visual system: Material 3 `AppTheme`, `AppColors`, `AppTextStyles`, and shared widgets under `lib/shared/widgets/`. Existing shells use inconsistent 640/900 pixel width checks. New adaptive content uses available width: mobile `<600`, tablet `600–1023`, desktop `>=1024` logical pixels. Student and Teacher shells use the desktop sidebar at `>=1024`.
- Backend, API, database, upload, recording, grading, attendance and payment logic are outside this UI migration's scope.

## Classification

`A`: dedicated mobile experience already adequate. `B`: mobile experience exists but needs polish. `C`: desktop content stacked or shrunk on mobile. `D`: mobile view absent/untested. This is a source audit; visual/device verification is tracked separately.

| Role / route or embedded view | Type | Priority | Progress |
| --- | --- | --- | --- |
| Auth: splash, login, forgot password, first login | B | P2 | Audit only |
| Shared: profile, edit profile, change password | A/B | P2 | Audit only; preserve existing dedicated layout |
| Student home dashboard, navigation | B | P1 | Mobile dashboard implemented; device QA pending |
| Student courses, lesson detail, class detail | B/C | P1 | Enrolled course list/curriculum, lesson detail and class detail Mobile implemented; device QA pending |
| Student schedule, session/attendance | B/C | P1 | Shared Mobile agenda/session sheet and attendance history implemented; device QA pending |
| Student assignments list (`StudentAssignmentsView`, `/assignments`) | C → B | P0 | Mobile view implemented; device/API QA pending |
| Student assignment detail (`/assignments/:id`) | C → B | P0 | Mobile view implemented; device/API QA pending |
| Student work, voice/text/file, draft and submit (`/assignments/:id/submit`) | C → B | P0 | Mobile view implemented; device/API QA pending |
| Student submission review, score and feedback (assignment detail) | C → B | P0 | Mobile view implemented; publication/device QA pending |
| Student exams, take exam, results | B/C | P2 | Mobile exam list/taking and personal results implemented; real API/device QA pending |
| Student invoices/payment, notifications | B/C | P2 | Mobile invoice list/detail and payment control layout plus shared notification list implemented; live payment/device QA pending |
| Teacher home/dashboard, reports | B/C | P1 | Mobile live dashboard and teaching reports implemented; device/API QA pending |
| Teacher classes/list/detail/schedule | B/C | P1 | My classes list, shared class detail and schedule Mobile implemented; other class screens pending |
| Teacher attendance and class workflow | B/C | P1 | Attendance roster/logbook Mobile implemented; other class workflows pending |
| Teacher assignments/create/edit/submission list/review/gradebook | B/C | P1 | Workflow, create/edit form and submission review Mobile implemented; secondary gradebook pending |
| Teacher exams/question bank, notifications, profile | B/C | P2 | Question bank list/create Mobile implemented; exam creation/results, notifications/profile pending |
| Parent home, child summary/schedule/grades/attendance/finance | B/C | P2 | Mobile child-first home implemented; shared schedule/attendance available; grades/finance lack parent-specific flow |
| Admin home/dashboard, users, branch/rooms, admissions, settings | C | P3 | Dashboard, users, branches/rooms and admissions Mobile checkpoints complete; settings pending |
| Admin courses/classes/scheduling/attendance, reports/finance | C | P3 | Class list/create form, course list/detail/forms and debts report Mobile checkpoints complete; edit class, schedules and wider reports pending |
| Shared dialogs, forms, filters and sheets across role flows | B/C | P1–P3 | Audit during each module |

Route inventory source: `lib/core/router/route_names.dart`; screen inventory: `lib/features/**/presentation/screens/` and `lib/features/dashboard/presentation/views/`. Nested home tabs and dialogs are included in each module above, rather than counted as standalone routes. Reclassify after visual QA.

### Source screen checklist

Each entry is a screen or embedded view found in Flutter source. Current classification is preliminary from layout code; pending entries still require device review. `student_assignments_view`, `assignment_detail_screen` (student), and `submit_assignment_screen` (student) have a new mobile branch in this checkpoint, but complete workflow signoff remains pending.

| Feature | Screens / views (filenames without `.dart`) | Type | State |
| --- | --- | --- | --- |
| Authentication | `splash_screen`, `login_screen`, `forgot_password_screen`, `first_login_screen` | B | Pending |
| Role shells | `student_home_screen`, `teacher_home_screen`, `parent_home_screen`, `admin_home_screen` | B | Student/Teacher/Admin breakpoint aligned; Parent Mobile home implemented; device QA pending |
| Profile | `profile_screen`, `edit_profile_screen`, `change_password_screen` | A/B | Pending verification |
| Student courses | `student_courses_screen`, `lesson_detail_screen` | B/C | Course/curriculum and lesson detail Mobile views implemented; device QA pending |
| Course management | `course_list_screen`, `course_detail_screen` | C → B | Admin course list/detail and create/add-level Mobile forms implemented; live API/device QA pending |
| Classes | `class_list_screen`, `class_detail_screen`, `class_create_screen`, `schedule_screen`, `teacher_my_classes_screen` | B/C | Admin class list/create form, shared Mobile schedule/class detail and Teacher my-classes list implemented; edit and secondary management pending |
| Attendance | `my_attendance_screen`, `attendance_mark_screen` | B/C | Student history and embedded Teacher attendance Mobile implemented; standalone marking pending |
| Student assignments | `student_assignments_view`, `assignment_list_screen`, `assignment_detail_screen`, `submit_assignment_screen` | C → B | Mobile UI implemented for list/detail/work; verification in progress |
| Teacher assignments | `create_assignment_screen`, `grade_submission_screen`, `submission_review_screen`, `teacher_grading_view`, `teacher_gradebook_view`, `teacher_class_workflow_view` | B/C | Embedded workflow and review Mobile implemented; remaining screens pending |
| Teacher workflows | `teacher_attendance_view`, `teacher_dashboard_screen`, `teacher_dashboard_live_screen`, `teacher_reports_screen` | B/C | Live dashboard, embedded attendance and teaching reports Mobile implemented; legacy dashboard pending |
| Notifications | `notification_list_screen` | B/C | Shared Mobile list implemented; device QA pending |
| Exams | `exam_list_screen`, `create_exam_screen`, `take_exam_screen`, `exam_result_screen`, `question_bank_list_screen`, `my_exam_results_screen` | B/C | Student Mobile list/take/personal results and Teacher question bank list/create implemented; exam creation/results pending |
| Finance | `invoice_list_screen`, `invoice_detail_screen`, `my_invoices_screen`, `record_payment_screen`, `pay_online_screen` | C | Student invoice list/detail Mobile implemented; payment controls adjusted for Mobile; admin screens and live payment QA pending |
| Reports | `admin_dashboard_screen`, `reports_overview_screen`, `debts_report_screen` | C | Admin dashboard Mobile implemented; other reports pending |
| Admin embedded views | `users_management_view`, `branches_rooms_view`, `admissions_crm_view`, `system_settings_view` | B/C | Users, branches/rooms and admissions Mobile checkpoints complete; settings pending |

Also inspect private builders, dialogs, bottom sheets, and tab content in each listed file during that feature's phase; they are not separate Dart screen files. There is no separate reset-password route or standalone parent child screen in the current route table, so no new business module is assumed.

## Implementation checkpoints

1. **Audit and foundation:** add width classification and reusable mobile surfaces/status tokens. Keep business logic shared. Do not silently switch existing desktop navigation.
2. **P0 Student Assignments:** dedicated mobile list, search/filter/sort, detail/results, and work screen with existing recorder/upload/draft/submit/resubmit behavior. Test 320, 375, 393, 430; tablet and desktop regression.
3. **Student remaining:** home, schedule, courses, classes, finance, exams, notifications.
4. **Teacher:** home, class/schedule, attendance, assignments/grading, report and secondary screens.
5. **Parent:** child-first overview, schedule/results/attendance, finance and notifications.
6. **Admin:** convert wide management tables to mobile list/detail and usable forms.
7. **Regression:** all roles, navigation, keyboard/safe area, overflow, API state and desktop comparison.

## Verification log

### Checkpoint 2026-10-27 — adaptive foundation and P0 Student Assignments UI

- Added `AdaptiveBreakpoints`/`AdaptiveLayout` and shared mobile surface/status/spacing tokens. The student assignment list chooses its layout from available content width; Desktop list stays on its existing branch.
- Student assignments Mobile now has a dedicated progress header, horizontal summary, search, status chips, class/sort bottom sheet, and compact cards. All data and filtering still come from the existing classes Bloc and assignments repository.
- Student detail Mobile has its own one-column reading flow with instructions, linked files, submission content, pending state, published grade/feedback, and available edit action.
- Student work Mobile has dedicated sections for assignment instructions, audio, text, and attachments plus a SafeArea action bar. The existing recorder, file upload, draft, submission and resubmission methods are reused. No backend or database changes.
- Focused analyzer on changed code/tests: **0 issues**. Full `flutter analyze`: **155 existing info-level lints** in other files, no errors reported; follow up separately.
- Focused widget suite: **25/25 pass** across 320, 375, 393, 430, tablet 800, desktop 1200. Includes mobile search/filter, draft and text submit repository calls, submission confirmation, graded detail, and withholding unpublished grade.
- `flutter build web`: **pass**. `git diff --check`: **pass**.

**P0 remains in progress:** run real Android and Mobile Web visual checks, exercise actual microphone recording/playback and native file picker/upload, test resubmission and grade refresh against a running backend, and inspect keyboard/safe-area behavior on devices. The student module is not marked complete until those checks pass. Desktop visual comparison and all other roles/modules remain pending.

Next work order: finish P0 end-to-end device/API checks, then student dashboard/schedule/courses, teacher class/attendance/assignments, parent, admin, and cross-role regression. Update this log after each module.

### Checkpoint 2026-10-27 — Student home, courses, schedule, gradebook

- Extended assignment widget coverage: in-memory audio bytes and TXT/ZIP/RAR files reach upload and submit repositories; resubmission, text draft/submit, unpublished grade hiding, and a simulated 300 px keyboard inset pass. Native microphone recording/playback and operating-system file picker behavior remain **unverified** without a device. Backend on port 3000 was not running; real API persistence remains **unverified**.
- Student home has a separate Mobile dashboard with upcoming class, touch-friendly shortcuts and profile entry. The shell uses the desktop sidebar at `>=1024` logical pixels and the compact navigation below that width. The schedule no longer shrinks mobile text to 80%.
- Enrolled courses use a Mobile list → curriculum detail flow with progress and materials. The existing repository and API calls remain shared with Desktop.
- Shared schedule (student, teacher, parent) now has a Mobile agenda, period/day controls, filters, and a session detail sheet. It keeps the existing Bloc and role-aware attendance action; Desktop calendar/list rendering is untouched.
- Removed the Student gradebook's hardcoded GPA, class score, attendance, and comment. A new view displays only published assignment and graded exam results from existing repositories, and labels the normalized average as the mean of graded work rather than a course GPA. It has Mobile and Desktop layouts.
- Changed files: scoped `flutter analyze` **0 issues**; combined Student widget suite **56/56 pass** across 320, 375, 393, 430, tablet 800, and Desktop 1200. `flutter build web` **pass**.

**Still pending in Student Portal:** attendance history, invoices/payment detail, notifications, exams/take exam, standalone class/lesson detail, profile/auth verification, real-device visual QA, and backend/device end-to-end tests. Continue with these before marking the Student phase complete. Teacher, Parent, and Admin remain pending outside the shared schedule.

### Checkpoint 2026-10-27 — Student attendance, invoice list, shared notifications

- Student invoices now use a dedicated Mobile summary, horizontal status chips, and touch-friendly invoice cards. Existing FinanceBloc, repository calls, invoice detail and payment routes are reused. Tablet and Desktop retain their original tab/list layout.
- Student attendance history now has a Mobile progress summary, wrapped status counts, and one-column session cards. The same AttendanceBloc data supplies both layouts. The existing makeup-request button on the Desktop branch still shows a local success notice without a request; this is a **pre-existing functional gap**, not verified as completed.
- The shared notifications screen now uses a Mobile unread summary, filter chips, compact metadata and an icon action for marking all read. The same NotificationBloc and notification navigation are used for all roles. A 320 px overflow in the original notification card metadata was found and corrected on the Mobile branch.
- Widget tests with repository fakes: **18/18 pass** across 320, 375, 393, 430, tablet 800 and Desktop 1200. Invoice filtering and notification mark-all were exercised. These tests do not prove live payment, attendance API persistence or push delivery.
- Scoped static analysis: **0 issues**. Combined Student regression suite: **74/74 pass**. `flutter build web`: **pass**.

**Still pending at this checkpoint:** student invoice detail/payment, exams, standalone class/lesson detail, profile/auth review; Teacher/Parent/Admin Mobile conversions; real Android/Mobile Web visual QA; backend/device end-to-end checks. The Backend was not started for this UI checkpoint. Do not mark these phases complete.

### Checkpoint 2026-10-27 — Student lesson detail

- Added a dedicated Mobile lesson reading screen with separate content, audio and document sections, sharing the existing `LessonModel`, audio player and document viewer.
- Removed generated `example.com` audio/PDF placeholders from the Desktop and Mobile lesson when the API has no materials; both layouts now show an honest empty state. Desktop layout otherwise remains on its prior branch.
- Scoped analyzer: **0 issues**; lesson widget tests: **6/6 pass** at 320, 375, 393, 430, 800 and 1200 px; `flutter build web`: **pass**. Actual audio playback/document downloads and device visual QA remain **unverified**.

**Next:** finish Student class detail, invoice detail/payment and exams, then Teacher, Parent, Admin; run device/API regression before marking any portal complete.

### Checkpoint 2026-10-28 — Class detail Mobile

- Added a dedicated Mobile class overview and session cards. Role-aware sections keep the student view focused on sessions and curriculum, while teacher/admin retain roster and attendance/edit actions. The existing `ClassesBloc`, class detail repository, curriculum API and action handlers remain shared. Desktop retains its previous nested tab layout.
- Curriculum is requested only when its Mobile section opens. The screen no longer resolves `ApiClient` before it is needed.
- Widget tests: **6/6 pass** at 320, 375, 393, 430, 800 and 1200 px. Student role tests cover hidden roster/attendance actions and opening the curriculum section with an empty response. Scoped `flutter analyze`: **0 issues**.
- `flutter build web`: **pass** (204 seconds). Real-device/API checks remain **unverified**. Do not mark the entire class workflow complete from widget tests alone.

### Checkpoint 2026-10-28 — Student invoice detail and payment layout

- Added a dedicated Mobile invoice detail with balance summary, due date, class, payment history and a bottom online-payment action. The existing FinanceBloc and invoice/payment routes are reused. Desktop keeps its existing detail layout. Cash collection and cancellation controls are now visible only to system/branch admin or academic staff; student users no longer see those actions on Desktop or Mobile.
- The payment screen has a horizontally scrollable Mobile method selector and stacked copyable transfer details to avoid small-width overflow; the same existing payment Bloc actions remain in use. This is a Mobile layout adjustment, not a payment integration rewrite.
- Widget tests with repository fakes: **12/12 pass** across 320, 375, 393, 430, tablet 800 and Desktop 1200. Tests cover student action visibility, payment history, and switching to VNPay. Scoped analyzer: **0 issues**.
- **Payment integration remains unverified.** The existing VietQR branch contains a hardcoded bank/account in `pay_online_screen.dart`; no backend-managed bank account was found during this source check. Do not use the displayed QR for real money transfers until the account details are verified and moved to trusted configuration. VNPay gateway return/callback and real payment state were not exercised because the Backend was not running.
- `flutter build web`: **pass** (275 seconds). Combined focused Student Adaptive regression: **98/98 pass**. Real payment, native device rendering and API persistence remain **unverified**.

### Checkpoint 2026-10-28 — Student exams and personal results

- Added dedicated Mobile exam list and exam-taking layouts. The Mobile exam flow uses the existing `ExamsBloc`, question widgets, timer, autosave and submit actions. The list hides draft exams from students and keeps teacher controls role-aware. The Desktop exam list and taking layout remain on their existing branches.
- Fixed a broken student result route: the old student “Xem lại bài làm” action and post-submit redirect opened the all-student results API, which is restricted to staff/teachers. Students now open a registered `/my-exam-results` route using the existing personal-results API. The new screen shows only each student's attempts, grades when available, and pending state. The label is “Xem kết quả” because that API does not provide a full answer review.
- Fixed 320 px overflow in the essay question header and question-grid bottom-sheet title. Mobile tests exercise answer selection, moving to an essay, entering text with a simulated 300 px keyboard inset, and opening the question grid.
- Focused widget tests: **18/18 pass** across 320, 375, 393, 430, tablet 800 and Desktop 1200, including the bottom-sheet assertion; focused analyzer: **0 issues**. Combined Student Adaptive regression: **116/116 pass**. `flutter build web --no-wasm-dry-run`: **pass** (184.8 seconds).
- Real countdown expiry, autosave persistence, exam submission, grading publication and device keyboard behavior against a running Backend remain **unverified**. Teacher exam management/results and role-specific device QA remain pending.

### Checkpoint 2026-10-28 — Teacher dashboard and my classes Mobile

- Teacher shell now uses the Desktop sidebar from 1024 logical pixels. The shared schedule keeps normal text scale on Mobile. Teacher's live dashboard has a separate Mobile flow: today's teaching and grading work, quick actions, upcoming sessions, pending submissions, attendance alerts and assigned classes. It reads the existing `/reports/teacher/dashboard` response; Desktop retains its prior dashboard branch.
- “Lớp học của tôi” now has a separate Mobile summary, search, horizontal status filters and touch-sized class cards/actions. It reuses `ClassesRepository.getMyClasses()` and the existing detail/assignment routes. Desktop retains its previous list.
- Widget tests for these two screens: **12/12 pass** at 320, 375, 393, 430, 800 and 1200 px. Tests cover a populated dashboard, class status filter and no reported widget exceptions. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass** (179.2 seconds). `git diff --check`: **pass**.
- Real API/session navigation, physical Android/Mobile Web visuals, screen-reader semantics and Desktop screenshot comparison remain **unverified**. Teacher attendance, assignments/grading, reports and exam management remain pending. Next priority: Teacher attendance Mobile, including roster controls and logbook forms.

### Checkpoint 2026-10-28 — Teacher attendance Mobile

- The embedded Teacher attendance view now has a Mobile screen with class/session selectors sized to the phone, horizontally scrollable summary and roster filters, and separate Học viên / Sổ đầu bài sections. The same attendance statuses, mark-all, save-and-lock, notes, attachment and logbook methods serve both layouts. Desktop retains its prior two-column arrangement.
- Existing functional test still verifies marking all present, locking attendance and saving the logbook through repository fakes. Added responsive coverage at 320, 375, 393, 430, 800 and 1200 px, including opening the Mobile logbook. **8/8 tests pass** in the focused attendance file. Scoped analyzer: **0 issues**; `git diff --check`: **pass**; `flutter build web --no-wasm-dry-run`: **pass** (69.8 seconds).
- Physical device interaction, real file picker/upload, API persistence and visual screenshots remain **unverified**. Standalone attendance-mark route and other Teacher class workflows are not covered by this checkpoint. Next priority: Teacher assignment/grading Mobile screens.

### Checkpoint 2026-10-28 — Teacher assignment workflow and submission review Mobile

- The embedded Teacher assignment workflow now uses dedicated Mobile cards for assigned work, graded results and session attendance; class selection and action placement are sized for touch. It keeps the same repositories, counts, routes and Desktop list branch. The existing grade-submission student list already has compact status/action cards and was preserved.
- The submission review screen now switches between “Bài làm” and “Chấm điểm” on Mobile. The grading form and actions scroll together at short heights. The previous 320×600 layout overflowed by 128 px with a simulated 300 px keyboard; the new layout passes that case. Desktop keeps its fixed two-column work/grading layout. Grading, publishing and redo operations still use the existing Bloc/repository methods.
- Focused workflow and review suite: **15/15 pass**, including Mobile grade save, the short-height keyboard case and Desktop grading regression. Scoped analyzer: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass** (41.9 seconds).
- Assignment create/edit, other embedded grading/gradebook views, real recorder/file upload, Backend persistence, physical device visual QA and Desktop screenshot comparison remain **unverified or pending**. The Teacher assignment module is not marked complete.

### Checkpoint 2026-10-28 — Teacher create/edit assignment form widths

- The existing create/edit form already used one scrollable column and real repository/Bloc submit actions, so it was preserved. On Mobile, maximum score and deadline now stack vertically; Tablet/Desktop keep the prior side-by-side fields. File selection/upload and description link preview were not rewritten.
- Form and upload/link tests: **9/9 pass** across 320, 375, 393, 430, 800 and 1200 px, including a simulated 300 px keyboard inset at 320 px. Existing edit workflow: **pass** (included in a prior 4/4 focused run). Scoped analyzer: **0 issues**; `flutter build web --no-wasm-dry-run`: **pass** (39.9 seconds).
- Native file picker, upload against a running Backend and actual keyboard/device behavior remain **unverified**. Source audit found `teacher_gradebook_view.dart` still contains hardcoded student/score data; the current Teacher shell instead routes “Kết quả bài tập” to the API-backed `TeacherClassWorkflowView`. Do not treat the old gradebook view as verified or expose it as live data without replacing the mock source. Teacher reports/exams and Parent/Admin phases remain pending.

### Checkpoint 2026-10-28 — Teacher teaching reports Mobile

- Added a dedicated Mobile reports layout with a prominent attendance summary, horizontal academic metrics, class attendance cards and graded student cards. The existing `ReportsRepository` attendance/academic calls and class filter supply both layouts; Desktop retains its existing report content.
- Existing class-filter test plus six width tests: **7/7 pass** at 320, 375, 393, 430, 800 and 1200 px. Scoped analyzer: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass** (40.5 seconds).
- Report values against a running Backend, physical device presentation and Desktop screenshot comparison remain **unverified**. Teacher exam management/secondary views and Parent/Admin phases remain pending.

### Checkpoint 2026-10-28 — Parent child-first Mobile home

- Added a dedicated Mobile home that lists linked children and their classes from the existing parent-scoped `ClassesRepository.getMyClasses()` response. It exposes working schedule, attendance history per child, notifications, profile and logout actions. Desktop home remains on its previous branch. The Mobile view omits the Desktop's grade and fee tiles because those tiles had no action or parent-specific data flow.
- Six widget tests with two linked children: **6/6 pass** at 320, 375, 393, 430, 800 and 1200 px. Scoped analyzer: **0 issues**; `flutter build web --no-wasm-dry-run`: **pass** (40.2 seconds).
- Parent-specific grade and finance views remain a **functional gap**, not an Adaptive UI completion. Parent timetable/attendance use shared Mobile screens but have not been verified against a live parent account. Device visuals and Backend persistence remain **unverified**. Admin Mobile is next.

### Checkpoint 2026-10-28 — Admin dashboard and shell Mobile

- Admin shell now uses the Desktop sidebar from 1024 logical pixels; smaller widths use its existing drawer/bottom navigation. Corrected the bottom navigation's selected item mapping for Classes, Courses and Reports. The Mobile dashboard has its own hierarchy for active students, operating classes, revenue/debt, upcoming classes and debtors, using the existing `ReportsBloc` data. Desktop charts and tables remain on the old branch.
- Dashboard widget tests: **7/7 pass** at 320, 375, 393, 430, 800 and 1200 px, including the existing Desktop KPI/chart/table regression. Scoped analyzer: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass** (40.5 seconds).
- Shell navigation taps and live Backend values remain **unverified**. Source audit shows `UsersManagementView` already switches to Mobile cards below its threshold, so preserve and verify it instead of duplicating that UI. Admin management views/reports/forms, physical device visuals and Desktop screenshots remain pending.

### Checkpoint 2026-10-28 — Admin user list responsive repair

- Kept the existing API-backed user list and Mobile cards. Six-width widget audit uncovered actual RenderFlex overflows in the Mobile security badge and branch/status dropdowns, plus the Desktop status/action cells. Replaced the cramped badge content, constrained dropdown selection text, and gave Desktop actions adequate width. The existing search, filters and API call path remain in place.
- Widget tests: **6/6 pass** at 320, 375, 393, 430, 800 and 1200 px, including Mobile search filtering. New test analyzer: **0 issues**; the large existing `users_management_view.dart` still has **18 info-level lint notices** unrelated to this layout repair, with no analyzer errors. `git diff --check`: **pass**. `flutter build web --no-wasm-dry-run`: **pass** (49.6 seconds).
- Add/edit user dialogs, role/branch filters with real data, import/export, permission enforcement and device visuals remain **unverified**. The rest of Admin management views are pending.

### Checkpoint 2026-10-28 — Admin branches and rooms Mobile overflow repair

- Preserved the existing API-backed branches, rooms, equipment and maintenance tabs. A six-width widget audit found actual 320 px overflow in the page heading, branch/floor/status filters and room cards. The Mobile filters now occupy the available width; room metadata, capacity and actions wrap within the card. Branch contact details and badges also wrap, and the maintenance status heading no longer forces a horizontal row. The same actions, data source and Desktop page structure remain in use.
- Widget tests with an API fake: **9/9 pass**. The rooms tab passes at 320, 375, 393, 430, 800 and 1200 px; the branches, equipment and maintenance tabs pass at 320 px. Scoped `flutter analyze`: **0 issues**. `git diff --check`: **pass**. `flutter build web --no-wasm-dry-run`: **pass**.
- This checkpoint verifies responsive rendering, not create/edit, room schedule, maintenance persistence, permission enforcement or real Backend behavior. Physical Android/Mobile Web visual QA and Desktop screenshot comparison remain **unverified**. Next Admin priority: admissions/CRM and other management views with Desktop-heavy tables/forms.

### Checkpoint 2026-10-28 — Admin admissions CRM Mobile list

- Replaced the Mobile admissions board/table presentation with a dedicated lead card list and horizontal stage chips. Search, branch/source filters, lead detail and status advancement reuse the existing API and handlers. The Desktop Kanban/table switch remains on its existing branch. Mobile dropdowns now fit narrow screens; existing Desktop Kanban card text wraps correctly, and the hardcoded counselor name was replaced with `assignedStaff` from the API or an unassigned state.
- Widget tests with API fakes: **7/7 pass** at 320, 375, 393, 430, 800 and 1200 px, plus a 320 px stage/search interaction. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Creating/converting a lead, server persistence, role enforcement, real device appearance and Desktop screenshot comparison remain **unverified** without a running Backend/device. The rest of Admin management screens, Parent grade/finance gaps, Teacher secondary screens and full cross-role regression remain pending.

### Checkpoint 2026-10-28 — Admin debts report Mobile

- Added a dedicated Mobile debt invoice card with the outstanding balance first, followed by total/paid amounts, due date and contact. The report still uses `ReportsBloc` and the existing report API; the Desktop debt card remains on its prior branch.
- Replaced the export button's placeholder success notice with a download from the existing `/reports/export/debts` endpoint and a local save action. Download and file picker behavior against a running Backend/device remain **unverified**.
- Existing report test plus six width tests: **7/7 pass** at 320, 375, 393, 430, 800 and 1200 px. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Admin settings, courses/classes, finance forms and wider reports are still pending, as are Parent-specific grades/finance, Teacher secondary screens and live API/device/Desktop visual regression.

### Checkpoint 2026-10-28 — Admin class management Mobile list

- Replaced the Admin class list's 1050 px horizontally scrolling table on Mobile/Tablet with a dedicated card list. It displays live class status, course, teacher, schedule, room/branch and enrollment progress from the existing `ClassesBloc`. Search, status and branch filters work on the loaded classes; create and class-detail actions use the existing routes. Shared `MobileSectionCard`, `MobileStatusPill` and spacing tokens keep it consistent with the mobile design system. Desktop retains its original table/calendar structure, with a small header/action-width repair found during regression.
- Widget tests with a repository fake: **12/12 pass** at 320, 375, 393, 430, 800 and 1200 px, including Mobile search with a simulated 300 px keyboard inset, status filter, loading, empty/error states and create/detail navigation. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- The Desktop list still contains pre-existing static fallback labels and a placeholder teacher-assignment panel. Class creation/edit, actual scheduling, API persistence and authorization were not exercised against a running Backend. Physical Android/Mobile Web visual QA and Desktop screenshot comparison remain **unverified**. Next Admin priorities: class create/edit forms, course management and `system_settings_view` (which currently initializes several settings tabs with local defaults rather than server values).

### Checkpoint 2026-10-28 — Admin class create Mobile form and shared entity picker

- The existing class creation form now uses one-column Mobile sections for course/level, branch/room, time and capacity fields, with a fixed SafeArea submit action and a short form introduction. Desktop keeps its paired fields and submit placement. Lookup loading, validation, date/time selection, course/branch dependencies and `ClassesBloc` create logic are reused.
- `SearchableEntityField` now opens a searchable Mobile bottom sheet when the user taps the field or its label. It filters existing records by name/code and returns their IDs; the Desktop dropdown remains unchanged. Tests cover selection, empty options, long selected labels and a 320×600 screen with a simulated 300 px keyboard inset.
- Form tests: **10/10 pass** (320, 375, 393, 430, 800, 1200 px, keyboard, Mobile course/level selection, validation and repository ID submit). Shared picker tests: **5/5 pass**. Combined class list/form/picker regression: **27/27 pass**. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Real class creation and scheduling persistence, native date/time/file interactions, screen-reader/device visual QA and Desktop screenshot comparison remain **unverified** without a running Backend/device. The class edit route and secondary Admin class panels still need a separate audit.

### Checkpoint 2026-10-28 — Admin course list Mobile

- Added a dedicated Mobile/Tablet course list below 1024 px. Its summary, search, status chips and course cards use only loaded `CourseModel` fields; cards open the existing course detail route. Loading, empty, API error and retry states have dedicated presentations. Desktop keeps its existing layout.
- Widget tests with a repository fake: **10/10 pass** at 320, 375, 393, 430, 800 and 1200 px, including a simulated 300 px keyboard inset, search/status filtering, loading, empty/error and detail navigation. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Existing Desktop curriculum cards include inferred/static tuition, capacity, duration and student-count values, and its export button only displays a notice. These are **not completed** by this Mobile list checkpoint. API-backed creation/detail, Excel export, physical device QA and Desktop screenshot comparison remain **unverified**.

### Checkpoint 2026-10-28 — Admin course detail Mobile

- Added a separate Mobile/Tablet course detail layout with real course summary, level cards, modules and expandable lessons from the existing `CoursesBloc`. Lesson taps keep the existing lesson-detail route. Desktop retains its original content. A Desktop widget test exposed an existing ListTile ink warning inside a decorated module; wrapping that tile with Material resolves it without changing the layout. The 320 px API-error state now uses a compact Mobile retry card instead of the overflowing shared error button.
- Widget tests with a repository fake: **8/8 pass** at 320, 375, 393, 430, 800 and 1200 px, including long titles, expandable modules, empty data and API error. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Create-course and add-level forms receive a separate Mobile pass in the next checkpoint. Live API persistence, physical device visuals and Desktop screenshot comparison remain **unverified**.

### Checkpoint 2026-10-28 — Admin course create and add-level Mobile forms

- Mobile/Tablet now opens a scrollable bottom sheet for course creation and level creation. Required fields and numeric values are validated; sheet padding follows the keyboard. Both forms submit their existing `CreateCourseEvent` / `CreateCourseLevelEvent` through `CoursesBloc`, while Desktop keeps its prior dialogs. The course form exposes only fields actually supported by the create API, avoiding the Desktop dialog's fee/duration inputs that are not sent to the server.
- Combined course list/detail/form widget suite: **20/20 pass** across 320, 375, 393, 430, 800 and 1200 px. Tests verify validation and repository event calls for course and level creation, including a 320×600 screen with 300 px keyboard inset. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- Actual persistence against a running Backend, duplicate-code errors, device keyboard/file behavior, permissions, and Desktop screenshot comparison remain **unverified**. Desktop export is still a placeholder, and Desktop curriculum cards contain inferred/static business values. The Admin course area is not marked fully complete.

### Checkpoint 2026-10-28 — Teacher question bank Mobile

- Added a dedicated Mobile/Tablet question bank card layout and a create bottom sheet with required-name validation. It continues using the existing `ExamsBloc` and repository. The previous create dialog dispatched `CreateQuestionBankEvent` and immediately dispatched a reload, allowing concurrent handlers to race. The screen now reloads only after `ExamActionSuccessState`, so the newly created bank appears after a successful save. Desktop list/dialog layout remains in place.
- Widget tests with a repository fake: **9/9 pass** at 320, 375, 393, 430, 800 and 1200 px, including long title, creation and post-save reload, empty/error states, and a 320×600 keyboard inset without overflow. Combined regression with Admin course screens: **29/29 pass**. Scoped `flutter analyze`: **0 issues**. `flutter build web --no-wasm-dry-run`: **pass**. `git diff --check`: **pass**.
- The keyboard test only checks layout and does not prove that the save button is reachable with a real device keyboard. Backend persistence, role permissions, Desktop screenshot comparison and physical device visuals remain **unverified**. Teacher exam creation/results and question management beyond this list/create screen remain pending.
