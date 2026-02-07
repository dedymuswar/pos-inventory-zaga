import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/features/transaction/model/transaction_model.dart';


class TransactionController {
  Future<List<TransactionModel>> getTransactions() async {
    final db = await DatabaseHelper.instance.getAllTransactions();
    return db.map((e) => TransactionModel.fromMap(e)).toList();
  }
}