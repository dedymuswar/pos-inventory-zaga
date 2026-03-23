import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/discount_tax_setting.dart';

class DiscountTaxRepository {
  final DatabaseHelper _dbHelper;

  DiscountTaxRepository(this._dbHelper);

  Future<DiscountTaxSetting?> getSettings() async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'discount_tax_settings',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return DiscountTaxSetting.fromMap(result.first);
    }

    // jika belum ada data create default
    final defaultSetting = DiscountTaxSetting(
      id: 1,
      discountType: 'percent',
      discountValue: 0,
      taxType: 'percent',
      taxValue: 0,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await db.insert('discount_tax_settings', defaultSetting.toMap());

    return defaultSetting;
  }

  Future<void> saveSettings(DiscountTaxSetting setting) async {
    final db = await _dbHelper.database;
    await db.update(
      'discount_tax_settings',
      setting.toMap(),
      where: 'id = ?',
      whereArgs: [setting.id],
    );
  }
}
