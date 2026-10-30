# Repository Guidelines

## Project Structure & Module Organization

This repository contains a Flutter client and a NestJS backend. Flutter application code is under `lib/`, organized by feature (`lib/features/`) plus shared infrastructure in `lib/core/` and reusable widgets in `lib/shared/`. Flutter tests are in `test/`; platform wrappers live in `android/`, `ios/`, `web/`, `linux/`, `macos/`, and `windows/`. Backend source is under `backend/src/`, grouped into NestJS modules, with Prisma schema, migrations, and seed data in `backend/prisma/`; backend unit and E2E tests are in `backend/src/**/*.spec.ts` and `backend/test/`. Use `docs/` for architecture and project documentation.

## Build, Test, and Development Commands

From the repository root:

- `flutter pub get` installs Flutter dependencies.
- `flutter run -d chrome` runs the web client locally; use `flutter devices` to select another target.
- `flutter analyze` runs Dart static analysis; `dart format lib test` formats Dart code.
- `flutter test` runs Flutter tests; `flutter test --coverage` also writes coverage output.
- `docker compose up -d` starts PostgreSQL, Redis, and Adminer.

From `backend/`:

- `npm install` installs backend dependencies; `npm run start:dev` starts NestJS with watch mode.
- `npm run build` compiles the backend, `npm run lint` runs Oxlint, and `npm run format` runs Prettier.
- `npm run test`, `npm run test:e2e`, and `npm run test:cov` run unit, E2E, and coverage tests respectively.

## Coding Style & Naming Conventions

Follow the configured `flutter_lints` rules: two-space indentation, single-quoted Dart strings, `snake_case.dart` filenames, `PascalCase` types, and `camelCase` members. Prefer `const` constructors and package imports. TypeScript uses Prettier formatting, `PascalCase` classes, `camelCase` methods/variables, and descriptive NestJS module names. Keep feature code within its feature/module boundary.

## Testing Guidelines

Name Dart tests descriptively with `_test.dart`; name backend specs with `.spec.ts` or `.e2e-spec.ts`. Add regression coverage for changed behavior. The project’s test plan targets at least 75 cases across feature, interaction, and realistic workflow scenarios.

## Commit & Pull Request Guidelines

Use imperative Conventional Commit prefixes such as `feat:`, `fix:`, and `docs:` (as shown in recent history), with a concise scope when useful. Pull requests should explain the behavior changed, identify tests run, link related issues or checklist items, and include screenshots or recordings for UI changes. Do not commit secrets; configure local services and credentials through `.env` based on `.env.example`.
