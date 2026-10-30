# P0 incident recovery checkpoint (2026-10-29)

## Source preservation

Work started from `develop` at `bf7ffb3` with 42 already-modified tracked files and multiple untracked documents, images, tests and scratch files. No reset, clean, database migration, seed edit, or operational DELETE was performed. The pre-existing work remains in the working tree. This document records only the P0 recovery work; it does not certify unrelated modules.

Isolated checkpoints created during recovery: `a60f3d4` (Mobile Profile), `8e368a3` (Course backend), `7494a5d` (Class backend), `4129ee5` (Course client/state), `c3a8b5e` (Class client/actions), and `6a550fe` (Desktop Profile width fixes). These checkpoints include relevant pre-existing uncommitted edits in the same Course/Class files; other pre-existing files remain unstaged and untouched. In particular, the large uncommitted `course_detail_screen.dart` change was not included in the Course client checkpoint.

## Confirmed causes and repairs

| Area | Evidence | Repair |
| --- | --- | --- |
| Mobile Profile | An uncommitted change used `kIsWeb || ...` to choose the desktop view. On Flutter Web, that expression is true even at 393 logical pixels. | Restored width-based selection (`width > 900`). Kept the existing mobile view. Its identity card header, footer and summary counts now wrap/fit narrow widths. |
| Course DELETE | The newly present Nest route matches the Flutter repository URL, but the service referred to nonexistent Prisma `courseModule`; the backend could not build. | Uses the schema's `module` model. Permanent deletion remains limited to a DRAFT course with no classes; a conditional final delete rejects a publication-state race. No live records were deleted. |
| Course list after DELETE failure | The Bloc emitted `CoursesError` on a mutation failure, replacing the loaded list. | Emits a loaded-list-compatible failure state with the cached courses and filters. The UI shows a business-facing error and retains the list. Duplicate DELETE requests for the same course are ignored while one is in flight. |
| Class DELETE | The route existed in uncommitted source, but the service allowed deletion of non-planning classes. | Permanent deletion is limited to `PLANNING`, with a conditional final delete. List and detail views hide the delete action for cancelled/non-planning classes; the error dialog shows a business-facing reason. Cancel remains a separate status operation. No live records were deleted. |

## Verification performed

- NestJS build: passed.
- NestJS unit suite: 195/195 passed. Course/Class focused suite: 73/73 passed, including new rejection cases.
- Flutter Course Bloc focused tests: 10/10 passed, including 403/404/405/409/500 failure handling and duplicate submission.
- Flutter Class deletion message tests: 3/3 passed. New Class list action-visibility tests: 2/2 passed.
- Mobile Profile widget checks at 320, 375, 393, 430 and 800 logical pixels: passed. The 393 px edit-route interaction passed.
- Desktop Profile overflows identified at 1200 and 1440 px were repaired in six constrained rows without changing the two-column layout. The complete seven-width Profile widget suite now passes 7/7.
- Focused Course Bloc + Class deletion-message rerun after final formatting: 13/13 passed. Focused Flutter analysis of 12 P0 files: no issues found.
- `flutter build web --debug`: passed before and after the final Profile width repair (final build: 107.1 s). `flutter run -d chrome --web-port 58080` started and rendered the public home page in Chrome, including iPhone 16 emulation at 393 px. The debug browser window was closed after inspection.

## Unresolved verification and observed failures

- The reported `dependents.isEmpty` assertion has **not** been reproduced and no project widget can yet be identified from a stack trace. A direct unauthenticated request to `/profile` redirected to the public home page; an authenticated Profile → edit → save → dashboard flow was not verified in the browser. Do not mark this assertion fixed without a trace and reproduction.
- Chrome debug emulation produced a **different** Flutter engine assertion, `_viewInsets.isNonNegative`, during a direct URL reload. Its stack is in `lib/_engine/engine/window.dart` and contains no EduLMS widget. The same run reported an unrelated 38 px public AppBar overflow at `lib/features/public/presentation/public_site_screen.dart:133`. These observations must not be conflated with `dependents.isEmpty`.
- The seven-width Profile widget suite is clean, but authenticated browser use of Profile, editing, save with keyboard open, and SafeArea interaction still require live verification.
- Existing Admin Course adaptive tests still fail at 320 and 1200 px plus stale UI expectations. Existing Admin Class adaptive tests still fail at 1200 px plus a stale label expectation. New P0 behavior tests pass, but the broader adaptive suites do not.
- No HTTP DELETE was sent to an operational database. Backend route integration with a running isolated test database, browser refresh after a real deletion, and the authenticated mutation/navigation flow remain unverified.
- Full `flutter analyze --no-pub` after the final lint fixes reports 104 repository issues (0 errors, 15 warnings, 89 infos; exit code 1). It does not pass cleanly. The focused 12-file P0 analysis reports no issues.

## Next safe steps

1. Reproduce `dependents.isEmpty` with an authenticated test account and capture the complete debug stack, route and preceding action. Fix only the confirmed lifecycle cause.
2. Visually inspect authenticated Mobile/Profile edit with the keyboard and SafeArea; the seven-width widget suite is already green.
3. Run Course/Class DELETE integration tests against an isolated test database created for the tests; verify list refresh and persisted results after browser reload.
4. Resolve the existing Course/Class adaptive suite failures without weakening test assertions, then run full Flutter analysis and related suites again.
5. Reconcile the remaining pre-existing working-tree edits with their owners before any broader checkpoint. Do not include diagrams, scratch assets or unrelated module edits in a P0 commit.
