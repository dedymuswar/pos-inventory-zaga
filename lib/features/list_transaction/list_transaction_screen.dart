import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/features/list_transaction/logic/list_transaction_controller.dart';
import 'package:pos_inventory/features/post_transaction/post_transaction_screen.dart';
import 'package:pos_inventory/models/transaction_model.dart';

class ListTransactionScreen extends StatefulWidget {
  const ListTransactionScreen({super.key});

  @override
  State<ListTransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<ListTransactionScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);

  final ListTransactionController _controller = ListTransactionController();
  late Future<List<TransactionModel>> _transactionsFuture;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _controller.getTransactions();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Future<void> _reload() async {
    setState(() {
      _transactionsFuture = _controller.getTransactions();
    });
    await _transactionsFuture;
  }

  Future<void> _openTransactionDetail(String trxCode) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostTransactionScreen(trxCode: trxCode),
      ),
    );
  }

  DateTime? _tryParseDate(String raw) {
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String rawDate) {
    final parsed = _tryParseDate(rawDate);
    if (parsed == null) return rawDate.isEmpty ? '-' : rawDate;
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(parsed);
  }

  DateTime _monthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _monthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Pilih Tanggal Mulai',
    );
    if (picked == null) return;

    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
      if (_endDate.year != _startDate.year || _endDate.month != _startDate.month) {
        _endDate = _monthEnd(_startDate);
      }
      if (_endDate.isBefore(_startDate)) {
        _endDate = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          23,
          59,
          59,
        );
      }
    });
  }

  Future<void> _pickEndDate() async {
    final first = _monthStart(_startDate);
    final last = _monthEnd(_startDate);
    final initial = _endDate.isBefore(first) || _endDate.isAfter(last)
        ? _startDate
        : _endDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pilih Tanggal Akhir',
    );
    if (picked == null) return;

    setState(() {
      final selected = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      _endDate = selected.isBefore(_startDate)
          ? DateTime(
              _startDate.year,
              _startDate.month,
              _startDate.day,
              23,
              59,
              59,
            )
          : selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Gagal memuat transaksi: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final transactions = snapshot.data ?? [];
          final startDateLabel = DateFormat(
            'dd MMM yyyy',
            'id_ID',
          ).format(_startDate);
          final endDateLabel = DateFormat('dd MMM yyyy', 'id_ID').format(
            _endDate,
          );
          final filteredTransactions = transactions.where((trx) {
            final trxDate = _tryParseDate(trx.date);
            if (trxDate == null) return false;
            return !trxDate.isBefore(_startDate) && !trxDate.isAfter(_endDate);
          }).toList()
            ..sort((a, b) {
              final aDate = _tryParseDate(a.date) ?? DateTime(1970);
              final bDate = _tryParseDate(b.date) ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });

          return RefreshIndicator(
            onRefresh: _reload,
            color: _primaryBlue,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _DateFilterHeader(
                  startDateLabel: startDateLabel,
                  endDateLabel: endDateLabel,
                  onTapStartDate: _pickStartDate,
                  onTapEndDate: _pickEndDate,
                  resultCount: filteredTransactions.length,
                ),
                const SizedBox(height: 16),
                if (filteredTransactions.isEmpty)
                  const _EmptyState()
                else
                  ...filteredTransactions.map((trx) {
                    return _TransactionCard(
                      code: trx.trxCode,
                      date: _formatDate(trx.date),
                      total: _currencyFormat.format(trx.total_amount),
                      onTap: () => _openTransactionDetail(trx.trxCode),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateFilterHeader extends StatelessWidget {
  const _DateFilterHeader({
    required this.startDateLabel,
    required this.endDateLabel,
    required this.onTapStartDate,
    required this.onTapEndDate,
    required this.resultCount,
  });

  final String startDateLabel;
  final String endDateLabel;
  final VoidCallback onTapStartDate;
  final VoidCallback onTapEndDate;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE6FA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D61E7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF1D61E7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Filter Tanggal',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$resultCount data',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FilterField(
                  label: 'Dari Tanggal',
                  value: startDateLabel,
                  onTap: onTapStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilterField(
                  label: 'Sampai Tanggal',
                  value: endDateLabel,
                  onTap: onTapEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Rentang tanggal hanya dalam bulan yang sama.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD8E3FA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, color: Color(0xFF1D61E7), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.code,
    required this.date,
    required this.total,
    required this.onTap,
  });

  final String code;
  final String date;
  final String total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
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
                child: const Icon(Icons.point_of_sale, color: Color(0xFF1D61E7)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                total,
                style: const TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F7)),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 34, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'Belum ada transaksi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
