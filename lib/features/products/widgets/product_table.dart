import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/product_model.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ProductDataSource extends DataGridSource {
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  final List<DataGridRow> _rows;

  ProductDataSource(List<Product> products)
      : _rows = products.map((p) {
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: '',
          decimalDigits: 0,
        );
        return DataGridRow(
          cells: [
            DataGridCell(columnName: 'barcode', value: p.barcode.length > 12
                ? "${p.barcode.substring(0, 12)}.."
                : p.barcode),
            DataGridCell(
                columnName: 'name',
                value: p.name.length > 10
                    ? "${p.name.substring(0, 10)}.."
                    : p.name),
            DataGridCell(
              columnName: 'price',
              value: formatter.format(p.price),
            ),
            DataGridCell(columnName: 'stock', value: p.stock.toString()),
          ],
        );
      }).toList();

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(cell.value.toString()),
        );
      }).toList(),
    );
  }
}

class ProductTable extends StatelessWidget {
  final List<Product> products;

  const ProductTable({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return SfDataGrid(
      allowSorting: true,
      source: ProductDataSource(products),
      columnWidthMode: ColumnWidthMode.auto,
      gridLinesVisibility: GridLinesVisibility.both,
      headerGridLinesVisibility: GridLinesVisibility.both,
      columns: [
        GridColumn(columnName: 'barcode', label: const Center(child: Text("Barcode"))),
        GridColumn(columnName: 'name', label: const Center(child: Text("Nama"))),
        GridColumn(columnName: 'price', label: const Center(child: Text("Harga"))),
        GridColumn(columnName: 'stock', label: const Center(child: Text("Stok"))),
      ],
    );
  }
}
