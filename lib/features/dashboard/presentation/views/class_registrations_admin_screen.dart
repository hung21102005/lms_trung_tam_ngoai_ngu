import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';

class ClassRegistrationsAdminScreen extends StatefulWidget {
  const ClassRegistrationsAdminScreen({super.key, this.apiClient});
  final ApiClient? apiClient;

  @override
  State<ClassRegistrationsAdminScreen> createState() =>
      _ClassRegistrationsAdminScreenState();
}

class _ClassRegistrationsAdminScreenState
    extends State<ClassRegistrationsAdminScreen> {
  late final ApiClient _api = widget.apiClient ?? getIt<ApiClient>();
  Future<List<Map<String, dynamic>>>? _requests;
  String _filter = 'ALL';
  String? _busyId;

  String _formatFriendlyError(Object error, {required String fallback}) {
    debugPrint('[ClassRegistrationsAdminScreen] API Error: $error');
    if (error is ApiException) {
      final raw = error.message.trim();
      final isRawRouteError = RegExp(
        r'^Cannot\s+(GET|POST|PUT|PATCH|DELETE)\s+/',
        caseSensitive: false,
      ).hasMatch(raw);
      if (isRawRouteError) {
        return 'Chức năng đang được đồng bộ với máy chủ. Vui lòng thử lại sau giây lát.';
      }
      final code = error.statusCode ?? 0;
      if (code == 400 || code == 409) {
        return raw.isNotEmpty ? raw : fallback;
      }
      if (code == 401 || code == 403) {
        return raw.isNotEmpty
            ? raw
            : 'Bạn không có quyền thực hiện thao tác này.';
      }
      if (code == 404) {
        return raw.isNotEmpty
            ? raw
            : 'Không tìm thấy đơn đăng ký trên máy chủ.';
      }
      if (code >= 500) {
        return 'Hệ thống đang bận hoặc gặp sự cố tạm thời. Vui lòng thử lại sau.';
      }
      if (raw.isNotEmpty) return raw;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _requests = _load();
    });
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final response = await _api.get('/admissions/registrations');
    final data = response is Map && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! List) {
      throw const FormatException('Danh sách đăng ký không hợp lệ');
    }
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> _act(
    Map<String, dynamic> request, {
    String? reviewStatus,
  }) async {
    final id = '${request['id']}';
    final title = reviewStatus == 'REJECTED'
        ? 'Từ chối đăng ký này?'
        : reviewStatus == 'REOPEN'
        ? 'Mở lại đơn đăng ký?'
        : reviewStatus == 'CONTACTED'
        ? 'Đánh dấu đã liên hệ?'
        : 'Xác nhận nhập học?';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(
          reviewStatus == null
              ? 'Hệ thống sẽ kiểm tra tài khoản, sĩ số và tạo ghi danh cùng hóa đơn học phí. Chưa ghi nhận khoản thanh toán nào.'
              : reviewStatus == 'REJECTED'
              ? 'Đơn đăng ký sẽ chuyển sang trạng thái TỪ CHỐI, không giữ chỗ trong lớp và được lưu vào lịch sử.'
              : reviewStatus == 'REOPEN'
              ? 'Đơn đăng ký sẽ được mở lại về trạng thái Đã liên hệ để tiếp tục tư vấn.'
              : 'Trạng thái đơn sẽ được cập nhật trong CRM.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busyId != null) return;
    setState(() => _busyId = id);
    try {
      if (reviewStatus == null) {
        await _api.post(
          '/admissions/registrations/$id/approve',
          data: <String, dynamic>{},
        );
      } else {
        await _api.patch(
          '/admissions/registrations/$id/review',
          data: {'status': reviewStatus},
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewStatus == null
                ? 'Đã xác nhận nhập học.'
                : 'Đã cập nhật đơn đăng ký.',
          ),
        ),
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                error,
                fallback: 'Không thể cập nhật đơn đăng ký lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _deleteRegistration(Map<String, dynamic> request) async {
    final id = '${request['id']}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đơn đăng ký thử nghiệm?'),
        content: Text(
          'Xóa vĩnh viễn đơn đăng ký đã từ chối/đã hủy của "${request['fullName'] ?? ''}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _busyId != null) return;
    setState(() => _busyId = id);
    try {
      await _api.delete('/admissions/registrations/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa đơn đăng ký thử nghiệm.')),
      );
      _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _formatFriendlyError(
                error,
                fallback: 'Không thể xóa đơn đăng ký thử nghiệm lúc này.',
              ),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundLight,
    appBar: AppBar(
      title: const Text('Đơn đăng ký lớp'),
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Làm mới',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _requests,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.error,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không tải được đơn: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: _refresh, child: const Text('Thử lại')),
              ],
            ),
          );
        }
        final all = snapshot.data ?? [];
        final filtered = _filter == 'ALL'
            ? all
            : all.where((item) => item['status'] == _filter).toList();
        return LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Theo dõi và xác nhận yêu cầu đăng ký lớp',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chỉ duyệt sau khi đã xác minh tài khoản học viên. Đơn mới chưa giữ chỗ và chưa phát sinh thanh toán.',
                      style: TextStyle(color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in const <String, String>{
                            'ALL': 'Tất cả',
                            'PENDING': 'Chờ xử lý',
                            'CONTACTED': 'Đã liên hệ',
                            'APPROVED': 'Đã nhập học',
                            'REJECTED': 'Từ chối',
                            'CANCELLED': 'Đã hủy',
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(entry.value),
                                selected: _filter == entry.key,
                                onSelected: (_) =>
                                    setState(() => _filter = entry.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Chưa có đơn đăng ký trong bộ lọc này.',
                            ),
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final item in filtered)
                            SizedBox(
                              width: constraints.maxWidth >= 850
                                  ? 520
                                  : double.infinity,
                              child: _requestCard(item),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _requestCard(Map<String, dynamic> item) {
    final classInfo = item['class'] as Map?;
    final status = '${item['status']}';
    final id = '${item['id']}';
    final pending = status == 'PENDING' || status == 'CONTACTED';
    final terminal = status == 'REJECTED' || status == 'CANCELLED';
    final canDelete = terminal && item['canDelete'] != false;
    final guest = item['studentId'] == null;
    final lead = item['lead'] as Map?;
    final hasVerifiedStudent = !guest || lead?['convertedUserId'] != null;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item['fullName']}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(label: Text(_statusLabel(status))),
              ],
            ),
            const SizedBox(height: 6),
            Text('${classInfo?['name'] ?? ''} · ${classInfo?['code'] ?? ''}'),
            const SizedBox(height: 4),
            Text(
              '${item['phone']}${item['email'] == null ? '' : ' · ${item['email']}'}',
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
            if (guest && pending) ...[
              const SizedBox(height: 8),
              const Text(
                'Khách mới: chuyển Lead thành học viên hoặc xác minh tài khoản trùng số điện thoại trước khi duyệt.',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ],
            if (terminal) ...[
              const SizedBox(height: 8),
              const Text(
                'Hồ sơ lịch sử • Không giữ chỗ trong lớp.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'PENDING')
                    OutlinedButton(
                      onPressed: _busyId == null
                          ? () => _act(item, reviewStatus: 'CONTACTED')
                          : null,
                      child: const Text('Đã liên hệ'),
                    ),
                  OutlinedButton(
                    onPressed: _busyId == null
                        ? () => _act(item, reviewStatus: 'REJECTED')
                        : null,
                    child: const Text('Từ chối'),
                  ),
                  if (guest)
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, '${item['phone']}'),
                      child: const Text('Tìm Lead trong CRM'),
                    ),
                  FilledButton(
                    onPressed: _busyId == null && hasVerifiedStudent
                        ? () => _act(item)
                        : null,
                    child: Text(
                      _busyId == id ? 'Đang xử lý...' : 'Xác nhận nhập học',
                    ),
                  ),
                ],
              ),
            ] else if (terminal) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busyId == null
                        ? () => _act(item, reviewStatus: 'REOPEN')
                        : null,
                    child: const Text('Mở lại đơn'),
                  ),
                  if (canDelete)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: _busyId == null
                          ? () => _deleteRegistration(item)
                          : null,
                      child: const Text('Xóa đơn thử nghiệm'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'PENDING' => 'Chờ xử lý',
    'CONTACTED' => 'Đã liên hệ',
    'APPROVED' => 'Đã nhập học',
    'REJECTED' => 'Từ chối',
    'CANCELLED' => 'Đã hủy',
    _ => status,
  };
}
