import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_inventory/features/products/logic/product_controller.dart';
import 'package:pos_inventory/models/product_model.dart';
import 'package:pos_inventory/models/stock_movement.dart';

class StockCard extends StatefulWidget {
  const StockCard({super.key, required this.product});
  final Product product;

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  static const Color _primaryBlue = Color(0xFF1D61E7);
  static const Color _lightBlue = Color(0xFF3A7CF5);
  static const Color _deepBlue = Color(0xFF164CB7);

  final ProductService _service = ProductService();
  bool _loading = true;
  List<StockMovement> _movements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final productId = widget.product.id;
    if (productId == null) {
      setState(() {
        _movements = [];
        _loading = false;
      });
      return;
    }

    final data = await _service.getStockMovement(productId);
    if (!mounted) return;
    setState(() {
      _movements = data;
      _loading = false;
    });
  }

  String _keterangan(StockMovement m) {
    if (m.source == 'RESTOCK') {
      return 'Pembelian';
    }
    if (m.source == 'SALE') {
      return 'Penjualan #${m.reference ?? '-'}';
    }
    if (m.source == 'ADJUSMENT' || m.source == 'ADJUSTMENT') {
      return 'Adjustment';
    }
    return m.source.trim().isEmpty ? '-' : m.source;
  }

  @override
  Widget build(BuildContext context) {
    final numberFmt = NumberFormat('#,##0', 'id_ID');
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final totalIn = _movements.fold<int>(
      0,
      (sum, m) => sum + (m.type == 'IN' ? m.qty : 0),
    );
    final totalOut = _movements.fold<int>(
      0,
      (sum, m) => sum + (m.type == 'OUT' ? m.qty : 0),
    );
    final netMovement = totalIn - totalOut;
    final openingStock = widget.product.stock - netMovement;
    int runningStock = openingStock;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Kartu Stok'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: _primaryBlue,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _SummaryHeader(
                    productName: widget.product.name,
                    category: widget.product.category,
                    currentStock: numberFmt.format(widget.product.stock),
                    openingStock: numberFmt.format(openingStock),
                    totalIn: numberFmt.format(totalIn),
                    totalOut: numberFmt.format(totalOut),
                  ),
                  const SizedBox(height: 16),
                  if (_movements.isEmpty)
                    const _EmptyTimeline()
                  else
                    ..._movements.asMap().entries.map((entry) {
                      final index = entry.key;
                      final movement = entry.value;
                      runningStock += movement.type == 'IN'
                          ? movement.qty
                          : -movement.qty;
                      return _TimelineCard(
                        movement: movement,
                        description: _keterangan(movement),
                        timestamp: dateFmt.format(movement.createdAt),
                        runningStock: numberFmt.format(runningStock),
                        isFirst: index == 0,
                        isLast: index == _movements.length - 1,
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.productName,
    required this.category,
    required this.currentStock,
    required this.openingStock,
    required this.totalIn,
    required this.totalOut,
  });

  final String productName;
  final String category;
  final String currentStock;
  final String openingStock;
  final String totalIn;
  final String totalOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _StockCardState._lightBlue,
            _StockCardState._primaryBlue,
            _StockCardState._deepBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _StockCardState._primaryBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                  category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Stok Saat Ini',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            '$currentStock pcs',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 27,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryChip(
                  label: 'Awal',
                  value: openingStock,
                  icon: Icons.history,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'Masuk',
                  value: totalIn,
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryChip(
                  label: 'Keluar',
                  value: totalOut,
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.movement,
    required this.description,
    required this.timestamp,
    required this.runningStock,
    required this.isFirst,
    required this.isLast,
  });

  final StockMovement movement;
  final String description;
  final String timestamp;
  final String runningStock;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final bool isIn = movement.type == 'IN';
    final Color accent = isIn
        ? const Color(0xFF0D9488)
        : const Color(0xFFDC2626);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: const Color(0xFFD9E3FB),
                  )
                else
                  const SizedBox(height: 12),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 56,
                    color: const Color(0xFFD9E3FB),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${isIn ? '+' : '-'}${movement.qty}',
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (movement.actorName != null &&
                      movement.actorName!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF4FF),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD8E3FB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 13,
                            color: Color(0xFF1D61E7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            movement.actorName!,
                            style: const TextStyle(
                              color: Color(0xFF1D61E7),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    timestamp,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Stok: $runningStock',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

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
          Icon(Icons.timeline_outlined, size: 34, color: Color(0xFF94A3B8)),
          SizedBox(height: 8),
          Text(
            'Belum ada histori pergerakan stok',
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
