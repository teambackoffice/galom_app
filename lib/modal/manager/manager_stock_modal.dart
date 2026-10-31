import 'package:location_tracker_app/modal/manager/json_utils.dart';

/// One item's quantity in one warehouse (a raw `get_all_items_stock` row).
class WarehouseStock {
  final String warehouse;
  final double qty;

  const WarehouseStock(this.warehouse, this.qty);
}

/// An item with its stock summed across warehouses.
class StockItem {
  final String itemCode;
  final String itemName;
  final String uom;
  final String? itemGroup;
  final List<WarehouseStock> warehouses;

  const StockItem({
    required this.itemCode,
    required this.itemName,
    required this.uom,
    required this.itemGroup,
    required this.warehouses,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  double get totalQty => warehouses.fold(0, (sum, w) => sum + w.qty);

  bool get isOutOfStock => totalQty <= 0;

  /// Low stock: some left, but at or below [threshold].
  bool isLow(double threshold) => !isOutOfStock && totalQty <= threshold;

  /// Groups raw rows (one per item + warehouse) into items.
  static List<StockItem> fromRows(List<Map<String, dynamic>> rows) {
    final byCode = <String, _Builder>{};
    for (final r in rows) {
      final code = asString(r['item_code']).trim();
      if (code.isEmpty) continue;
      final b = byCode.putIfAbsent(
        code,
        () => _Builder(
          code,
          asString(r['item_name']).trim(),
          asString(r['stock_uom']).trim(),
          asStringOrNull(r['item_group']),
        ),
      );
      b.warehouses.add(
        WarehouseStock(
          asStringOrNull(r['warehouse']) ?? 'Unspecified warehouse',
          asDouble(r['actual_qty']),
        ),
      );
    }
    return byCode.values.map((b) => b.build()).toList();
  }
}

class _Builder {
  _Builder(this.code, this.name, this.uom, this.group);
  final String code;
  final String name;
  final String uom;
  final String? group;
  final List<WarehouseStock> warehouses = [];

  StockItem build() {
    warehouses.sort((a, b) => b.qty.compareTo(a.qty));
    return StockItem(
      itemCode: code,
      itemName: name,
      uom: uom,
      itemGroup: group,
      warehouses: List.unmodifiable(warehouses),
    );
  }
}
