# EduLMS Adaptive UI — audit and progress

Updated: 2026-10-27. Baseline rollback commit: `f84c81c627e05711b367248911db2f167fc71478`.

## Architecture audit

- Roles found in routes and home shells: student, teacher, parent, admin. Authentication has login, forgot password, first login setup.
- Navigation: `go_router` route table in `lib/core/router/app_router.dart`; role home shells in `lib/features/dashboard/presentation/screens/`. Student, teacher, and admin have mobile drawer/bottom navigation already. Feature screens also use direct detail routes.
- State and data: `flutter_bloc` for auth and feature screens, repositories/services and `getIt` dependency injection. Mobile UI must call the same Bloc/repository methods as desktop.
- Visual system: Material 3 `AppTheme`, `AppColors`, `AppTextStyles`, and shared widgets under `lib/shared/widgets/`. Existing shells use inconsistent 640/900 pixel width checks. New adaptive content uses available width: mobile `<600`, tablet `600–1023`, desktop `>=1024` logical pixels. The existing desktop shell threshold remains unchanged for this checkpoint.
- Backend, API, database, upload, recording, grading, attendance and payment logic are outside this UI migration's scope.

## Classification

`A`: dedicated mobile experience already adequate. `B`: mobile experience exists but needs polish. `C`: desktop content stacked or shrunk on mobile. `D`: mobile view absent/untested. This is a source audit; visual/device verification is tracked separately.

| Role / route or embedded view | Type | Priority | Progress |
| --- | --- | --- | --- |
| Auth: splash, login, forgot password, first login | B | P2 | Audit only |
| Shared: profile, edit profile, change password | A/B | P2 | Audit only; preserve existing dedicated layout |
| Student home dashboard, navigation | B | P1 | Mobile dashboard implemented; device QA pending |
| Student courses, lesson detail, class detail | B/C | P1 | Enrolled course list/curriculum and lesson detail Mobile implemented; class detail pending |
| Student schedule, session/attendance | B/C | P1 | Shared Mobile agenda/session sheet and attendance history implemented; device QA pending |
| Student assignments list (`StudentAssignmentsView`, `/assignments`) | C | P0 | Mobile view in progress |
| Student assignment detail (`/assignments/:id`) | C | P0 | Mobile view pending |
| Student work, voice/text/file, draft and submit (`/assignments/:id/submit`) | C | P0 | Mobile view pending |
| Student submission review, score and feedback (assignment detail) | C | P0 | Mobile view pending |
| Student exams, take exam, results | B/C | P2 | Gradebook now reads published assignment/exam results; exam UI pending |
| Student invoices/payment, notifications | B/C | P2 | Mobile invoice list and shared notification list implemented; payment/detail pending |
| Teacher home/dashboard, reports | B/C | P1 | Audit only |
| Teacher classes/list/detail/schedule | B/C | P1 | Audit only |
| Teacher attendance and class workflow | B/C | P1 | Audit only |
| Teacher assignments/create/edit/submission list/review/gradebook | B/C | P1 | Audit only |
| Teacher exams/question bank, notifications, profile | B/C | P2 | Audit only |
| Parent home, child summary/schedule/grades/attendance/finance | B/C | P2 | Audit only; embedded home tabs require screen-by-screen audit |
| Admin home/dashboard, users, branch/rooms, admissions, settings | C | P3 | Audit only |
| Admin courses/classes/scheduling/attendance, reports/finance | C | P3 | Audit only |
| Shared dialogs, forms, filters and sheets across role flows | B/C | P1–P3 | Audit during each module |

Route inventory source: `lib/core/router/route_names.dart`; screen inventory: `lib/features/**/presentation/screens/` and `lib/features/dashboard/presentation/views/`. Nested home tabs and dialogs are included in each module above, rather than counted as standalone routes. Reclassify after visual QA.

### Source screen checklist

Each entry is a screen or embedded view found in Flutter source. Current classification is preliminary from layout code; pending entries still require device review. `student_assignments_view`, `assignment_detail_screen` (student), and `submit_assignment_screen` (student) have a new mobile branch in this checkpoint, but complete workflow signoff remains pending.

| Feature | Screens / views (filenames without `.dart`) | Type | State |
| --- | --- | --- | --- |
| Authentication | `splash_screen`, `login_screen`, `forgot_password_screen`, `first_login_screen` | B | Pending |
| Role shells | `student_home_screen`, `teacher_home_screen`, `parent_home_screen`, `admin_home_screen` | B | Pending |
| Profile | `profile_screen`, `edit_profile_screen`, `change_password_screen` | A/B | Pending verification |
| Student courses | `student_courses_screen`, `lesson_detail_screen` | B/C | Course/curriculum and lesson detail Mobile views implemented; device QA pending |
| Course management | `course_list_screen`, `course_detail_screen` | C | Pending |
| Classes | `class_list_screen`, `class_detail_screen`, `class_create_screen`, `schedule_screen`, `teacher_my_classes_screen` | B/C | Shared Mobile schedule implemented; other screens pending |
| Attendance | `my_attendance_screen`, `attendance_mark_screen` | B/C | Student history Mobile implemented; teacher marking pending |
| Student assignments | `student_assignments_view`, `assignment_list_screen`, `assignment_detail_screen`, `submit_assignment_screen` | C → B | Mobile UI implemented for list/detail/work; verification in progress |
| Teacher assignments | `create_assignment_screen`, `grade_submission_screen`, `submission_review_screen`, `teacher_grading_view`, `teacher_gradebook_view`, `teacher_class_workflow_view` | B/C | Pending |
| Teacher workflows | `teacher_attendance_view`, `teacher_dashboard_screen`, `teacher_dashboard_live_screen`, `teacher_reports_screen` | B/C | Pending |
| Notifications | `notification_list_screen` | B/C | Shared Mobile list implemented; device QA pending |
| Exams | `exam_list_screen`, `create_exam_screen`, `take_exam_screen`, `exam_result_screen`, `question_bank_list_screen` | B/C | Pending |
| Finance | `invoice_list_screen`, `invoice_detail_screen`, `my_invoices_screen`, `record_payment_screen`, `pay_online_screen` | C | Student invoice list Mobile implemented; detail/payment and admin screens pending |
| Reports | `admin_dashboard_screen`, `reports_overview_screen`, `debts_report_screen` | C | Pending |
| Admin embedded views | `users_management_view`, `branches_rooms_view`, `admissions_crm_view`, `system_settings_view` | C | Pending |

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
