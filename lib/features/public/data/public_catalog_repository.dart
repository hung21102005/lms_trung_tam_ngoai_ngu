import '../../../core/network/api_client.dart';

class PublicCatalogRepository {
  const PublicCatalogRepository(this.apiClient);

  final ApiClient apiClient;

  dynamic _data(dynamic response) =>
      response is Map && response.containsKey('data')
      ? response['data']
      : response;

  List<Map<String, dynamic>> _records(dynamic response) {
    final data = _data(response);
    if (data is! List) {
      throw const FormatException('Danh sách công khai không hợp lệ');
    }
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> programs() async =>
      _records(await apiClient.get('/public/programs'));

  Future<List<Map<String, dynamic>>> courses() async =>
      _records(await apiClient.get('/public/courses'));

  Future<Map<String, dynamic>> course(String slug) async {
    final data = _data(
      await apiClient.get('/public/courses/${Uri.encodeComponent(slug)}'),
    );
    if (data is! Map) throw const FormatException('Khóa học không hợp lệ');
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> classes({String? courseId, int page = 1}) async {
    final data = _data(
      await apiClient.get(
        '/public/classes',
        queryParameters: {'page': page, 'limit': 12, 'courseId': ?courseId},
      ),
    );
    if (data is! Map || data['items'] is! List) {
      throw const FormatException('Danh sách lớp công khai không hợp lệ');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> classDetail(String id) async {
    final data = _data(
      await apiClient.get('/public/classes/${Uri.encodeComponent(id)}'),
    );
    if (data is! Map) throw const FormatException('Thông tin lớp không hợp lệ');
    return Map<String, dynamic>.from(data);
  }

  Future<void> registerGuest({
    required String classId,
    required String fullName,
    required String phone,
    String? email,
    String? notes,
  }) async {
    await apiClient.post(
      '/public/registrations',
      data: {
        'classId': classId,
        'fullName': fullName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> registerStudent({required String classId, String? notes}) async {
    await apiClient.post(
      '/my/registrations',
      data: {
        'classId': classId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> sendConsultation({
    required String fullName,
    required String phone,
    String? email,
    String? targetCourse,
    String? notes,
  }) async {
    await apiClient.post(
      '/admissions/leads',
      data: {
        'fullName': fullName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (targetCourse != null && targetCourse.isNotEmpty)
          'targetCourse': targetCourse,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'source': 'WEBSITE',
      },
    );
  }
}
