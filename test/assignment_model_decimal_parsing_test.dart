import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/assignments/data/models/assignment_model.dart';

void main() {
  group('AssignmentModel Decimal parsing', () {
    test('parses a Prisma Decimal maxScore serialized as a string', () {
      final assignment = AssignmentModel.fromJson({
        'id': 'assignment-1',
        'classId': 'class-1',
        'title': 'Essay',
        'type': 'WRITING',
        'maxScore': '10',
        'createdAt': '2026-10-26T00:00:00.000Z',
      });

      expect(assignment.maxScore, 10.0);
    });

    test('parses a graded submission score serialized as a string', () {
      final submission = SubmissionModel.fromJson({
        'id': 'submission-1',
        'assignmentId': 'assignment-1',
        'studentId': 'student-1',
        'submittedAt': '2026-10-26T00:00:00.000Z',
        'score': '8.5',
        'status': 'GRADED',
      });

      expect(submission.score, 8.5);
    });

    test('ignores legacy malformed attachment entries without crashing', () {
      final assignment = AssignmentModel.fromJson({
        'id': 'assignment-2',
        'classId': 'class-1',
        'title': 'Writing Task',
        'createdAt': '2026-10-26T00:00:00.000Z',
        'attachments': [
          [],
          {'name': 'rubric.pdf', 'url': '/uploads/assignments/rubric.pdf'},
        ],
      });

      expect(assignment.attachments, hasLength(1));
      expect(assignment.attachments.single.name, 'rubric.pdf');
    });

    test('uses submittedCount in assignment detail without losing graded submissions', () {
      final assignment = AssignmentModel.fromJson({
        'id': 'assignment-3',
        'classId': 'class-1',
        'title': 'Writing Task 1',
        'stats': {'submittedCount': 4, 'gradedCount': 3},
      });

      expect(assignment.totalSubmissions, 4);
      expect(assignment.gradedCount, 3);
    });

    test('keeps totalSubmissions from the class assignment list', () {
      final assignment = AssignmentModel.fromJson({
        'id': 'assignment-4',
        'classId': 'class-1',
        'title': 'Writing Task 1',
        'stats': {'totalSubmissions': 4, 'gradedCount': 3},
      });

      expect(assignment.totalSubmissions, 4);
    });
  });
}
