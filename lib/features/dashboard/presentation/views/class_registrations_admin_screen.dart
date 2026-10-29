import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không xử lý được đơn: $error')));
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
    final guest = item['studentId'] == null;
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
                    onPressed: _busyId == null ? () => _act(item) : null,
                    child: Text(
                      _busyId == id ? 'Đang xử lý...' : 'Xác nhận nhập học',
                    ),
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
