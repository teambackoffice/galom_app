class ItemTax {
  final String name;
  final String title;
  final double gstRate;

  ItemTax({required this.name, required this.title, required this.gstRate});

  factory ItemTax.fromJson(Map<String, dynamic> json) {
    return ItemTax(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      gstRate: (json['gst_rate'] ?? 0).toDouble(),
    );
  }
}
