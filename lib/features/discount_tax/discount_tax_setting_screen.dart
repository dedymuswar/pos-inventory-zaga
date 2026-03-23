import 'package:flutter/material.dart';
import 'package:pos_inventory/core/database/database_helper.dart';
import 'package:pos_inventory/models/discount_tax_setting.dart';
import 'package:pos_inventory/repository/discount_tax_repository.dart';

class DiscountTaxSettingScreen extends StatefulWidget {
  const DiscountTaxSettingScreen({super.key});

  @override
  State<DiscountTaxSettingScreen> createState() => _DiscountTaxSettingScreenState();
}

class _DiscountTaxSettingScreenState extends State<DiscountTaxSettingScreen> {
  static const Color _primaryBlue = Color(0xFF1D61E7);

  final DiscountTaxRepository _repo =
      DiscountTaxRepository(DatabaseHelper.instance);

  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();

  String _discountType = 'percent';
  String _taxType = 'percent';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSetting();
  }

  Future<void> _loadSetting() async {
    try {
      final setting = await _repo.getSettings();
      if (setting != null) {
        _discountType = setting.discountType;
        _taxType = setting.taxType;
        _discountController.text = _formatNumber(setting.discountValue);
        _taxController.text = _formatNumber(setting.taxValue);
      }
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6D84B3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD0DEFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue),
      ),
    );
  }

  Future<void> _saveSetting() async {
    final discountValue = double.tryParse(_discountController.text.trim());
    final taxValue = double.tryParse(_taxController.text.trim());

    if (discountValue == null || taxValue == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai diskon/pajak tidak valid')),
      );
      return;
    }

    final setting = DiscountTaxSetting(
      id: 1,
      discountType: _discountType,
      discountValue: discountValue,
      taxType: _taxType,
      taxValue: taxValue,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _repo.saveSettings(setting);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengaturan berhasil disimpan')),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Diskon & Pajak'),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_loadError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Text(
                        'Gagal memuat data: $_loadError',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFEAF1FF), Color(0xFFDDE9FF)],
                      ),
                      border: Border.all(color: const Color(0xFFBBD0FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diskon',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Tipe Diskon'),
                          value: _discountType,
                          items: const [
                            DropdownMenuItem(
                              value: 'percent',
                              child: Text('Persen (%)'),
                            ),
                            DropdownMenuItem(
                              value: 'fixed',
                              child: Text('Nominal (Rp)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _discountType = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _discountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration('Nilai Diskon'),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Pajak',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _inputDecoration('Tipe Pajak'),
                          value: _taxType,
                          items: const [
                            DropdownMenuItem(
                              value: 'percent',
                              child: Text('Persen (%)'),
                            ),
                            DropdownMenuItem(
                              value: 'fixed',
                              child: Text('Nominal (Rp)'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _taxType = value);
                          },
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: _inputDecoration('Nilai Pajak'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: _saveSetting,
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
