import '../../../core/network/api_exception.dart';

String courseDeletionMessage(Object error) {
  if (error is ApiException &&
      (error.statusCode == 400 || error.statusCode == 409) &&
      error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is ApiException && error.statusCode == 403) {
    return 'Bạn không có quyền xóa khóa học này.';
  }
  return 'Không thể xóa khóa học này. Vui lòng kiểm tra trạng thái và các lớp liên kết.';
}
