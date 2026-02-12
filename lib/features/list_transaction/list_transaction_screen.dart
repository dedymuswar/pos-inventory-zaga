import 'package:flutter/material.dart';
import 'package:pos_inventory/features/list_transaction/logic/list_transaction_controller.dart';
import 'package:pos_inventory/models/transaction_model.dart';

class ListTransactionScreen extends StatefulWidget {
  const ListTransactionScreen({super.key});

  @override
  State<ListTransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<ListTransactionScreen> {
  final ListTransactionController _controller = ListTransactionController();
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _controller.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: FutureBuilder<List<TransactionModel>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada transaksi"));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final trx = transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    trx.trxCode,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(trx.date),
                  trailing: Text(
                    "Rp ${trx.total_amount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
