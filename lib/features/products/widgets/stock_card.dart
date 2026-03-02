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
  final ProductService _service = ProductService();
  bool _loading = true;
  List<StockMovement> _movements = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final productId = widget.product.id;
    if (productId == null) return;

    final data = await _service.getStockMovement(productId);
    setState(() {
      _movements = data;
      _loading = false;
    });
  }

  String _keterangan(StockMovement m) {
    if (m.type == 'RESTOCK') {
      return 'Pembelian';
    }
    if (m.source == 'SALE') {
      return 'Penjualan #${m.reference ?? '-'}';
    }
    if (m.source == 'ADJUSMENT') {
      return 'Adjustment';
    }
    return m.source;
  }

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd/MM HH:mm');
    final netMovement = _movements.fold(
      0,(sum, m) => sum + (m.type == 'IN' ? m.qty : -m.qty),
    );
    int openingStock = widget.product.stock - netMovement;
    int runningStock = openingStock;

    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Stok')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama Barang : ${widget.product.name}'),
                  Text('Stok saat ini : ${widget.product.stock}'),
                  Text('Kategori : ${widget.product.category}'),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Tanggal')),
                          DataColumn(label: Text('Keterangan')),
                          DataColumn(label: Text('IN')),
                          DataColumn(label: Text('OUT')),
                          DataColumn(label: Text('SISA')),
                        ],
                        rows: _movements.map((m) {
                          final inQty = m.type == 'IN' ? m.qty : 0;
                          final outQty = m.type == 'OUT' ? m.qty : 0;
                          runningStock += (m.type == 'IN' ? m.qty : -m.qty);
                          return DataRow(cells: [
                            DataCell(Text(fmtDate.format(m.createdAt))),
                            DataCell(Text(_keterangan(m))),
                            DataCell(Text(inQty?.toString() ?? '-')),
                            DataCell(Text(outQty?.toString() ?? '-')),
                            DataCell(Text(runningStock.toString())),
                          ]); 
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
