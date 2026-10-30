import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/entities/user_entity.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/domain/repositories/auth_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_event.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/auth/presentation/bloc/auth_state.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/reports/presentation/screens/teacher_dashboard_live_screen.dart';

class _AuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserEntity> getMe() async => const UserEntity(
    id: 'teacher-1',
    userCode: 'GV-0001',
    fullName: 'Nguyễn Văn Dũng',
    status: 'ACTIVE',
    isFirstLogin: false,
    roles: ['teacher'],
    permissions: [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('teacher dashboard thích ứng ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authBloc = AuthBloc(authRepository: _AuthRepository());
      addTearDown(authBloc.close);
      authBloc.add(CheckAuthStatusEvent());
      await authBloc.stream.firstWhere((state) => state is AuthenticatedState);
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            home: TeacherDashboardLiveScreen(
              loadDashboard: () async => {
                'data': {
                  'sessionsToday': 2,
                  'pendingAssignments': 3,
                  'activeClasses': 2,
                  'totalStudents': 20,
                  'sessions': [
                    {
                      'id': 'session-1',
                      'title': 'Speaking practice',
                      'date': '2026-10-28',
                      'startTime': '18:00',
                      'endTime': '19:30',
                      'class': {'name': 'IELTS Foundation'},
                    },
                  ],
                  'pendingSubmissions': [
                    {
                      'assignmentId': 'assignment-1',
                      'student': {
                        'id': 'student-1',
                        'fullName': 'Nguyễn Minh Anh',
                      },
                      'assignment': {'title': 'Writing Task 1'},
                    },
                  ],
                  'classes': [
                    {
                      'id': 'class-1',
                      'name': 'IELTS Foundation',
                      'studentsCount': 12,
                    },
                  ],
                  'attendanceAlerts': [],
                },
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Nguyễn Văn Dũng'), findsOneWidget);
      expect(find.textContaining('IELTS Foundation'), findsWidgets);
      if (width < 600) {
        expect(
          find.byKey(const ValueKey('teacher-dashboard-mobile')),
          findsOneWidget,
        );
        expect(find.text('2 buổi dạy'), findsOneWidget);
        expect(find.text('3 bài tập chờ chấm'), findsOneWidget);
      } else {
        expect(
          find.byKey(const ValueKey('teacher-dashboard-mobile')),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
