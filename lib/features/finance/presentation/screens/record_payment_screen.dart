import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/invoice_model.dart';
import '../bloc/finance_bloc.dart';

class RecordPaymentScreen extends StatefulWidget {
  final String invoiceId;

  const RecordPaymentScreen({super.key, required this.invoiceId});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'CASH';
  InvoiceModel? _invoice;

  @override
  void initState() {
    super.initState();
    context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi nhận thanh toán'),
      ),
      body: BlocConsumer<FinanceBloc, FinanceState>(
        listener: (context, state) {
          if (state is InvoiceDetailLoadedState) {
            setState(() {
              _invoice = state.invoice;
              if (_amountController.text.isEmpty) {
                _amountController.text = state.invoice.balance.toInt().toString();
              }
            });
          }
          if (state is PaymentRecordedSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ghi nhận thanh toán thành công!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          }
          if (state is FinanceErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (_invoice == null && state is FinanceLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_invoice == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  context.read<FinanceBloc>().add(FetchInvoiceDetailEvent(widget.invoiceId));
                },
                child: const Text('Tải lại hóa đơn'),
              ),
            );
          }

          final inv = _invoice!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice summary banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: AppColors.primary, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${inv.code} • ${inv.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Số dư còn nợ: ${_formatCurrency(inv.balance)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick fill buttons
                  Text('Chọn nhanh số tiền nộp:', style: AppTextStyles.bodySmall(context)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Toàn bộ dư nợ'),
                        onPressed: () {
                          _amountController.text = inv.balance.toInt().toString();
                        },
                      ),
                      if (inv.balance > 1000000)
                        ActionChip(
                          label: const Text('50%'),
                          onPressed: () {
                            _amountController.text = (inv.balance / 2).toInt().toString();
                          },
                        ),
                      if (inv.balance >= 1000000)
                        ActionChip(
                          label: const Text('1,000,000 đ'),
                          onPressed: () {
                            _amountController.text = '1000000';
                          },
                        ),
                      if (inv.balance >= 2000000)
                        ActionChip(
                          label: const Text('2,000,000 đ'),
                          onPressed: () {
                            _amountController.text = '2000000';
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Số tiền thu (VNĐ) *',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập số tiền thu';
                      }
                      final numVal = double.tryParse(val.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'Số tiền phải lớn hơn 0';
                      }
                      if (numVal > inv.balance) {
                        return 'Số tiền vượt quá số dư còn nợ (${_formatCurrency(inv.balance)})';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Payment method dropdown
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Phương thức thanh toán *',
                      prefixIcon: Icon(Icons.payment),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CASH', child: Text('Tiền mặt tại quầy')),
                      DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản ngân hàng')),
                      DropdownMenuItem(value: 'MOMO', child: Text('Ví điện tử MoMo')),
                      DropdownMenuItem(value: 'VNPAY', child: Text('Cổng thanh toán VNPay')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedMethod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Transaction ID
                  TextFormField(
                    controller: _transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Mã bút toán / Mã giao dịch ngân hàng (nếu có)',
                      prefixIcon: Icon(Icons.numbers),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Ghi chú thu ngân',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: state is FinanceLoadingState ? null : _submitPayment,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: state is FinanceLoadingState
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Xác nhận Thu tiền & Xuất biên lai',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      final amount = double.parse(_amountController.text.trim());
      context.read<FinanceBloc>().add(
            RecordPaymentEvent(
              invoiceId: widget.invoiceId,
              amount: amount,
              method: _selectedMethod,
              transactionId: _transactionIdController.text.trim().isEmpty
                  ? null
                  : _transactionIdController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )} đ';
  }
}
