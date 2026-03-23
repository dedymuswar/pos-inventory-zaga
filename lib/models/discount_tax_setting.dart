class DiscountTaxSetting {
  final int id;
  final String discountType; // 'percent' or 'fixed'
  final double discountValue;
  final String taxType; // 'percent' or 'fixed'
  final double taxValue;
  final int updatedAt;

  DiscountTaxSetting({
    required this.id,
    required this.discountType,
    required this.discountValue,
    required this.taxType,
    required this.taxValue,
    required this.updatedAt,
  });

  DiscountTaxSetting copyWith({
    int? id,
    String? discountType,
    double? discountValue,
    String? taxType,
    double? taxValue,
    int? updatedAt,
  }) {
    return DiscountTaxSetting(
      id: id ?? this.id,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      taxType: taxType ?? this.taxType,
      taxValue: taxValue ?? this.taxValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );  
  }

  factory DiscountTaxSetting.fromMap(Map<String, dynamic> map) {
    return DiscountTaxSetting(
      id: map['id'] as int,
      discountType: map['discount_type'] as String,
      discountValue: (map['discount_value'] as num).toDouble(),
      taxType: map['tax_type'] as String,
      taxValue: (map['tax_value'] as num).toDouble(),
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'discount_type': discountType,
      'discount_value': discountValue,
      'tax_type': taxType,
      'tax_value': taxValue,
      'updated_at': updatedAt,
    };
  }

}