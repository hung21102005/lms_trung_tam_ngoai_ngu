import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/reports_bloc.dart';
import '../../data/models/report_model.dart';

class DebtsReportScreen extends StatefulWidget {
  const DebtsReportScreen({super.key});

  @override
  State<DebtsReportScreen> createState() => _DebtsReportScreenState();
}

class _DebtsReportScreenState extends State<DebtsReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadDebts() {
    context.read<ReportsBloc>().add(FetchDebtsReportEvent(
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo Cáo Công Nợ Học Phí'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Xuất Excel',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang xuất danh sách công nợ sang file Excel...'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc mã học viên...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadDebts();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: AppColors.neutral100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _loadDebts(),
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<ReportsBloc, ReportsState>(
              builder: (context, state) {
                if (state is ReportsLoadingState) {
                  return const LoadingWidget(message: 'Đang tải danh sách công nợ...');
                }

                if (state is ReportsErrorState) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Lỗi: ${state.message}', style: AppTextStyles.bodyMedium(context)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDebts,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is DebtsReportLoadedState) {
                  final data = state.data;

                  return RefreshIndicator(
                    onRefresh: () async => _loadDebts(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Summary Cards
                        _buildSummaryHeader(data.summary),
                        const SizedBox(height: 16),

                        if (data.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: EmptyStateWidget(
                              icon: Icons.check_circle_outline,
                              title: 'Không có công nợ nào',
                              description: 'Hiện không có hóa đơn học phí nào tồn đọng công nợ.',
                            ),
                          )
                        else
                          ...data.items.map((item) => _buildDebtItemCard(item)),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(DebtsSummaryModel summary) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng công nợ', style: TextStyle(fontSize: 11, color: AppColors.error)),
                const SizedBox(height: 4),
                Text(
                  _currencyFormat.format(summary.totalOutstanding),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quá hạn', style: TextStyle(fontSize: 11, color: AppColors.warning)),
                const SizedBox(height: 4),
                Text(
                  '${summary.overdueCount} hóa đơn',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.warning),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebtItemCard(DebtInvoiceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isOverdue ? AppColors.error.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.isOverdue ? 'Quá hạn' : 'Chờ nộp',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: item.isOverdue ? AppColors.error : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.studentCode} • ${item.className} • Mã HĐ: ${item.code}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng học phí', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                    Text(_currencyFormat.format(item.totalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Đã nộp', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
                    Text(_currencyFormat.format(item.paidAmount), style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn nợ', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                    Text(
                      _currencyFormat.format(item.balance),
                      style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            if (item.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hạn nộp: ${DateFormat('dd/MM/yyyy').format(item.dueDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: item.isOverdue ? AppColors.error : AppColors.textSecondaryLight,
                      fontWeight: item.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (item.phone != null)
                    Text('SĐT: ${item.phone}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
