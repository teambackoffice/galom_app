class ItemUomDetails {
  final String itemId;
  final String stockUom;
  final String? salesUom;
  final List<UomConversion> uoms;

  ItemUomDetails({
    required this.itemId,
    required this.stockUom,
    required this.salesUom,
    required this.uoms,
  });

  /// Sales UOM if configured, otherwise the stock UOM.
  String get defaultUom => salesUom ?? stockUom;

  factory ItemUomDetails.fromJson(Map<String, dynamic> json) {
    return ItemUomDetails(
      itemId: json['item_id'] ?? '',
      stockUom: json['stock_uom'] ?? '',
      salesUom: json['sales_uom'],
      uoms: (json['uoms'] as List? ?? [])
          .map((e) => UomConversion.fromJson(e))
          .toList(),
    );
  }
}

class UomConversion {
  final String uom;
  final double conversionFactor;

  UomConversion({required this.uom, required this.conversionFactor});

  factory UomConversion.fromJson(Map<String, dynamic> json) {
    return UomConversion(
      uom: json['uom'] ?? '',
      conversionFactor: (json['conversion_factor'] ?? 1).toDouble(),
    );
  }
}
