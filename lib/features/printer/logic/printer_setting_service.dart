
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingService {
  static const _macKey = 'printer_mac';
  static const _autoKey = 'auto_print';

  static Future<void> savePrinter(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_macKey, mac);
  }

  static Future<String?> getPrinter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_macKey);
  }

  static Future<bool> setAutoPrint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_autoKey, value);
  }

  static Future<bool> getAutoPrint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoKey) ?? false;
  }
  
}