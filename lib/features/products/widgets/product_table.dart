import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../models/product_model.dart';

class ProductDataSource extends DataGridSource {
  ProductDataSource(
    List<Product> products, {
    required this.onRestock,
    required this.onStockCard,
  }) : _rows = products.map((p) {
         final formatter = NumberFormat.currency(
           locale: 'id_ID',
           symbol: '',
           decimalDigits: 0,
         );

         return DataGridRow(
           cells: [
             DataGridCell<String>(columnName: 'name', value: p.name),
             DataGridCell<String>(
               columnName: 'price',
               value: formatter.format(p.price),
             ),
             DataGridCell<String>(
               columnName: 'stock',
               value: p.stock.toString(),
             ),
             DataGridCell<Product>(columnName: 'action', value: p),
           ],
         );
       }).toList();

  final void Function(Product product) onRestock;
  final void Function(Product product) onStockCard;
  final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'action') {
          final product = cell.value as Product;
          return Align(
            alignment: Alignment.center,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'restock') {
                  onRestock(product);
                  return;
                }
                if (value == 'stock_card') {
                  onStockCard(product);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(value: 'restock', child: Text('Restock')),
                PopupMenuItem<String>(
                  value: 'stock_card',
                  child: Text('Kartu Stok'),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(cell.value.toString()),
        );
      }).toList(),
    );
  }
}

class ProductTable extends StatelessWidget {
  const ProductTable({
    super.key,
    required this.products,
    required this.onRestock,
    required this.onStockCard,
  });

  final List<Product> products;
  final void Function(Product product) onRestock;
  final void Function(Product product) onStockCard;

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      source: ProductDataSource(
        products,
        onRestock: onRestock,
        onStockCard: onStockCard,
      ),
      allowSorting: true,
      columnWidthMode: ColumnWidthMode.auto,
      columns: [
        GridColumn(
          columnName: 'name',
          label: const Center(child: Text('Nama')),
        ),
        GridColumn(
          columnName: 'price',
          label: const Center(child: Text('Harga')),
        ),
        GridColumn(
          columnName: 'stock',
          label: const Center(child: Text('Stok')),
        ),
        GridColumn(
          columnName: 'action',
          width: 70,
          label: const Center(child: Text('Aksi')),
        ),
      ],
    );
  }
}
