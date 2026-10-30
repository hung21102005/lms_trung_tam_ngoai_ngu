import '../../../core/network/api_exception.dart';

String classDeletionMessage(Object error) {
  if (error is ApiException &&
      (error.statusCode == 400 || error.statusCode == 409) &&
      error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is ApiException && error.statusCode == 403) {
    return 'Bạn không có quyền xóa lớp học này.';
  }
  return 'Không thể xóa lớp này. Vui lòng kiểm tra trạng thái và các dữ liệu liên quan.';
}
