import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/core/network/api_exception.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/classes/presentation/class_deletion_message.dart';

void main() {
  test('shows verified business reason for 400 and 409', () {
    for (final status in [400, 409]) {
      expect(
        classDeletionMessage(
          ApiException(message: 'Lớp đã có đơn đăng ký', statusCode: status),
        ),
        'Lớp đã có đơn đăng ký',
      );
    }
  });

  test('does not expose route or server errors', () {
    for (final status in [404, 405, 500]) {
      expect(
        classDeletionMessage(
          ApiException(
            message: 'Cannot DELETE /api/v1/classes/class-1',
            statusCode: status,
          ),
        ),
        'Không thể xóa lớp này. Vui lòng kiểm tra trạng thái và các dữ liệu liên quan.',
      );
    }
  });

  test('shows permission error for 403', () {
    expect(
      classDeletionMessage(
        const ApiException(message: 'Forbidden', statusCode: 403),
      ),
      'Bạn không có quyền xóa lớp học này.',
    );
  });
}
