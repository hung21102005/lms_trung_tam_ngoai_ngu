import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class MyInvoicesScreen extends StatefulWidget {
  const MyInvoicesScreen({super.key});

  @override
  State<MyInvoicesScreen> createState() => _MyInvoicesScreenState();
}

class _MyInvoicesScreenState extends State<MyInvoicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filters = ['Tất cả', 'Chưa thanh toán', 'Đã thanh toán'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    context.read<FinanceBloc>().add(FetchMyInvoicesEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học phí của tôi'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: BlocBuilder<FinanceBloc, FinanceState>(
        builder: (context, state) {
          if (state is FinanceLoadingState) {
            return const Center(child: CircularProgressIndicator());
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
                    onPressed: () {
                      context.read<FinanceBloc>().add(FetchMyInvoicesEvent());
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state is MyInvoicesLoadedState) {
            final invoices = _filterInvoices(state.invoices, _filters[_tabController.index]);

            if (invoices.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<FinanceBloc>().add(FetchMyInvoicesEvent());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                    const EmptyStateWidget(
                      icon: Icons.receipt_long_outlined,
                      title: 'Không có hóa đơn học phí',
                      description: 'Bạn không có khoản học phí nào trong danh mục này.',
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<FinanceBloc>().add(FetchMyInvoicesEvent());
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: invoices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = invoices[index];
                  return _buildInvoiceCard(inv);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  List<InvoiceModel> _filterInvoices(List<InvoiceModel> list, String filter) {
    if (filter == 'Chưa thanh toán') {
      return list.where((i) => i.balance > 0 && i.status != 'CANCELLED').toList();
    } else if (filter == 'Đã thanh toán') {
      return list.where((i) => i.status == 'PAID').toList();
    }
    return list;
  }

  Widget _buildInvoiceCard(InvoiceModel inv) {
    final statusConfig = _getStatusConfig(inv.status);
    final className = inv.classInfo?['name'] as String? ?? 'Ngoại khóa / Khác';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                inv.code,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusConfig.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusConfig.color.withAlpha(70)),
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
          Text(
            inv.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Lớp: $className',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
          ),
          if (inv.dueDate != null) ...[
            const SizedBox(height: 2),
            Text(
              'Hạn nộp: ${_formatDate(inv.dueDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: inv.status == 'OVERDUE' ? AppColors.error : AppColors.textMutedLight,
                fontWeight: inv.status == 'OVERDUE' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng học phí', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                  Text(_formatCurrency(inv.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Còn lại phải nộp', style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                  Text(
                    _formatCurrency(inv.balance),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: inv.balance > 0 ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.push('/invoices/${inv.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Xem chi tiết'),
                ),
              ),
              if (inv.balance > 0 && inv.status != 'CANCELLED') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/invoices/${inv.id}/pay-online');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Thanh toán ngay'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'PAID':
        return _StatusConfig(label: 'ĐÃ NỘP ĐỦ', color: AppColors.success);
      case 'PARTIALLY_PAID':
        return _StatusConfig(label: 'ĐÃ NỘP 1 PHẦN', color: const Color(0xFF0284C7));
      case 'OVERDUE':
        return _StatusConfig(label: 'QUÁ HẠN', color: AppColors.error);
      case 'CANCELLED':
        return _StatusConfig(label: 'ĐÃ HỦY', color: Colors.grey);
      case 'REFUNDED':
        return _StatusConfig(label: 'ĐÃ HOÀN TIỀN', color: Colors.purple);
      default:
        return _StatusConfig(label: 'CHƯA NỘP', color: const Color(0xFFD97706));
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
