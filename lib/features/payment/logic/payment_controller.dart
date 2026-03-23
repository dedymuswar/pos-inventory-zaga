import 'package:flutter/material.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/pending_transaction.dart';

class PaymentController extends ChangeNotifier {
  int _terimaUang = 0;

  void tambahUang(int amount) {
    _terimaUang += amount;
    notifyListeners();
  }

  int hitungKembalian(int totalAmount) {
    return _terimaUang - totalAmount;
  }

  bool isUangCukup(int totalAmount) {
    return _terimaUang >= totalAmount;
  }

  Future<bool> prosesPembayaran(
    PendingTransaction trx,
    int receivedMoney, {
    required int subtotal,
    required int discountAmount,
    required int taxAmount,
  }) async {
    // validasi uang
    if (receivedMoney < trx.totalAmount) {
      return false;
    }

    try {
      // simpan ke db
      await DatabaseHelper.instance.saveTransaction(
        trx: trx,
        receivedMoney: receivedMoney,
        change: receivedMoney - trx.totalAmount,
        paymentMethod: 'Cash',
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
      );
      return true;
    } catch (e) {
      print('Error saat proses pembayaran: $e');
      return false;
    }
  }
}
