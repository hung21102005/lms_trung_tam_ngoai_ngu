import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusFilters = [
    'ALL',
    'PENDING',
    'PARTIALLY_PAID',
    'PAID',
    'OVERDUE',
  ];
  final List<String> _tabLabels = [
    'Tất cả',
    'Chờ nộp',
    'Một phần',
    'Đã xong',
    'Quá hạn',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadInvoices() {
    final status = _statusFilters[_tabController.index];
    context.read<FinanceBloc>().add(FetchInvoicesEvent(
          status: status == 'ALL' ? null : status,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Học phí & Hóa đơn'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
          onTap: (_) => _loadInvoices(),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm mã HĐ, tên HV, số điện thoại...',
                prefixIcon: const Icon(Icons.search, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadInvoices();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: AppColors.neutral100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _loadInvoices(),
            ),
          ),

          // Invoices Content
          Expanded(
            child: BlocBuilder<FinanceBloc, FinanceState>(
              builder: (context, state) {
                if (state is FinanceLoadingState) {
                  return const LoadingWidget();
                }

                if (state is FinanceErrorState) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text('Lỗi: ${state.message}', style: AppTextStyles.bodyMedium(context)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadInvoices,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is InvoicesLoadedState) {
                  final resp = state.response;

                  return RefreshIndicator(
                    onRefresh: () async => _loadInvoices(),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        // Revenue Summary Cards
                        _buildSummaryHeader(resp.summary),
                        const SizedBox(height: 16),

                        if (resp.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: EmptyStateWidget(
                              icon: Icons.receipt_long_outlined,
                              title: 'Không tìm thấy hóa đơn nào',
                              description: 'Chưa có hóa đơn học phí nào phù hợp với bộ lọc hiện tại.',
                            ),
                          )
                        else
                          ...resp.items.map((inv) => _buildInvoiceCard(inv)),
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

  Widget _buildSummaryHeader(InvoicesSummaryModel summary) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Tổng hóa đơn',
            value: _formatCurrency(summary.totalRevenue),
            color: AppColors.primary,
            icon: Icons.receipt_outlined,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Đã thu',
            value: _formatCurrency(summary.paidRevenue),
            color: AppColors.success,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            title: 'Còn nợ',
            value: _formatCurrency(summary.outstandingRevenue),
            color: AppColors.error,
            icon: Icons.pending_actions_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel inv) {
    final statusConfig = _getStatusConfig(inv.status);
    final studentName = inv.student?['fullName'] as String? ?? 'N/A';
    final studentCode = inv.student?['userCode'] as String? ?? '';
    final className = inv.classInfo?['name'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Code + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    inv.code,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusConfig.color.withAlpha(80)),
                  ),
                  child: Text(
                    statusConfig.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusConfig.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title & Student
            Text(
              inv.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  '$studentName ($studentCode)',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
            if (className.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.class_outlined, size: 16, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    className,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ],
            const Divider(height: 20),

            // Amount Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                    Text(
                      _formatCurrency(inv.totalAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Đã nộp', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                    Text(
                      _formatCurrency(inv.paidAmount),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Còn lại', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                    Text(
                      _formatCurrency(inv.balance),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: inv.balance > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/invoices/${inv.id}');
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Chi tiết'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                if (inv.balance > 0 && inv.status != 'CANCELLED') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/invoices/${inv.id}/record-payment');
                      },
                      icon: const Icon(Icons.point_of_sale_outlined, size: 16),
                      label: const Text('Thu tiền'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PAID':
        return _StatusConfig(label: 'ĐÃ THANH TOÁN', color: AppColors.success);
      case 'PARTIALLY_PAID':
        return _StatusConfig(label: 'TRẢ MỘT PHẦN', color: const Color(0xFF0284C7));
      case 'OVERDUE':
        return _StatusConfig(label: 'QUÁ HẠN', color: AppColors.error);
      case 'CANCELLED':
        return _StatusConfig(label: 'ĐÃ HỦY', color: Colors.grey);
      case 'REFUNDED':
        return _StatusConfig(label: 'ĐÃ HOÀN TIỀN', color: Colors.purple);
      default:
        return _StatusConfig(label: 'CHỜ THANH TOÁN', color: const Color(0xFFD97706));
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} đ';
  }
}

class _StatusConfig {
  final String label;
  final Color color;

  _StatusConfig({required this.label, required this.color});
}
