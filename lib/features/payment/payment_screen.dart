import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/features/cart/logic/cart_controller.dart';
import 'package:pos_inventory/features/payment/logic/payment_controller.dart';
import 'package:pos_inventory/features/post_transaction/logic/thermal_printer_service.dart';
import 'package:pos_inventory/features/post_transaction/post_transaction_screen.dart';
import 'package:pos_inventory/models/pending_transaction.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.transaction,
    required this.cartController,
  });

  final PendingTransaction transaction;
  final CartController cartController;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  static const Color _lightBlue = Color(0xFF3A7CF5);
  static const Color _deepBlue = Color(0xFF164CB7);

  final PaymentController _controller = PaymentController();
  final TextEditingController _manualMoneyController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _receivedMoney = 0;
  bool _isLoading = false;

  int get _effectiveTotal => widget.cartController.total;
  int get _change => _receivedMoney - _effectiveTotal;
  bool get _isEnough => _change >= 0;

  void _addMoney(int amount) {
    setState(() {
      _receivedMoney += amount;
    });
  }

  void _applyManualMoney() {
    final raw = _manualMoneyController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return;

    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) return;

    setState(() {
      _receivedMoney += amount;
      _manualMoneyController.clear();
    });
  }

  Future<void> _processPayment() async {
    if (!_isEnough || _isLoading) return;

    setState(() => _isLoading = true);
    final trx = PendingTransaction(
      trxCode: widget.transaction.trxCode,
      cashierId: widget.transaction.cashierId,
      cashierName: widget.transaction.cashierName,
      createdAt: widget.transaction.createdAt,
      items: widget.transaction.items,
      totalAmount: _effectiveTotal,
    );
    final success = await _controller.prosesPembayaran(
      trx,
      _receivedMoney,
      subtotal: widget.cartController.subtotal,
      discountAmount: widget.cartController.discount,
      taxAmount: widget.cartController.tax,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      showDialog(
        context: context,
        builder: (_) =>
            const AlertDialog(content: Text('Gagal memproses pembayaran')),
      );
      return;
    }

    try {
      final printerService = ThermalPrinterService();
      final db = DatabaseHelper.instance;
      final trxFinal = await db.getTransactionDetail(
        widget.transaction.trxCode,
      );
      if (trxFinal != null) {
        await printerService.autoPrint58mm(trxFinal);
      }
    } catch (e, st) {
      debugPrint('Gagal memuat detail transaksi setelah pembayaran: $e');
      debugPrintStack(stackTrace: st);
    }

    if (!mounted) return;
    widget.cartController.clearCart();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PostTransactionScreen(
          trxCode: widget.transaction.trxCode,
          cartController: widget.cartController,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _manualMoneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trx = widget.transaction;
    final quickAmounts = <int>[10000, 20000, 50000, _effectiveTotal];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  _PaymentHeaderCard(
                    trxCode: trx.trxCode,
                    cashierName: trx.cashierName,
                    itemCount: trx.items.length,
                  ),
                  const SizedBox(height: 12),
                  _BillCard(
                    totalAmount: _currencyFormatter.format(_effectiveTotal),
                  ),
                  const SizedBox(height: 12),
                  _ReceivedCard(
                    receivedAmount: _currencyFormatter.format(_receivedMoney),
                    onReset: () {
                      setState(() {
                        _receivedMoney = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickAmounts.map((amount) {
                      return _QuickAmountChip(
                        amount: amount == trx.totalAmount
                            ? 'Uang Pas'
                            : _currencyFormatter.format(amount),
                        onTap: () => _addMoney(amount),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _ManualMoneyField(
                    controller: _manualMoneyController,
                    onSubmit: _applyManualMoney,
                  ),
                  const SizedBox(height: 12),
                  _ChangeCard(
                    changeAmount: _currencyFormatter.format(
                      _change < 0 ? 0 : _change,
                    ),
                    isEnough: _isEnough,
                    lackAmount: _currencyFormatter.format(
                      _isEnough ? 0 : -_change,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFF16A34A,
                    ).withValues(alpha: 0.45),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.85,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isEnough && !_isLoading ? _processPayment : null,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: Text(
                    _isLoading ? 'Memproses...' : 'PROSES PEMBAYARAN',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentHeaderCard extends StatelessWidget {
  const _PaymentHeaderCard({
    required this.trxCode,
    required this.cashierName,
    required this.itemCount,
  });

  final String trxCode;
  final String cashierName;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _PaymentScreenState._lightBlue,
            _PaymentScreenState._primaryBlue,
            _PaymentScreenState._deepBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _PaymentScreenState._primaryBlue.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Detail Pembayaran',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$itemCount item',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            trxCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kasir: $cashierName',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.totalAmount});

  final String totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF1D61E7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Color(0xFF1D61E7),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Total Tagihan',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            totalAmount,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivedCard extends StatelessWidget {
  const _ReceivedCard({required this.receivedAmount, required this.onReset});

  final String receivedAmount;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Uang Diterima',
              style: TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            receivedAmount,
            style: const TextStyle(
              color: Color(0xFF1D61E7),
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onReset,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1D61E7)),
            tooltip: 'Reset',
          ),
        ],
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.amount, required this.onTap});

  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF1FF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            '+ $amount',
            style: const TextStyle(
              color: Color(0xFF1D61E7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualMoneyField extends StatelessWidget {
  const _ManualMoneyField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: 'Input nominal manual...',
        prefixIcon: const Icon(Icons.edit_note_rounded),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D61E7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onSubmit,
            child: const Text(
              'Tambah',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8E3FB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD8E3FB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1D61E7), width: 1.4),
        ),
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  const _ChangeCard({
    required this.changeAmount,
    required this.isEnough,
    required this.lackAmount,
  });

  final String changeAmount;
  final bool isEnough;
  final String lackAmount;

  @override
  Widget build(BuildContext context) {
    final toneColor = isEnough
        ? const Color(0xFF059669)
        : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: toneColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isEnough ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: toneColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnough ? 'Kembalian' : 'Uang Kurang',
                  style: TextStyle(
                    color: toneColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnough ? changeAmount : lackAmount,
                  style: TextStyle(
                    color: toneColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
