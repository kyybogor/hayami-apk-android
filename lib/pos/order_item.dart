class OrderItem {
  final String productName;
  final String size;
  final int quantity;
  final double unitPrice;
  final String idTipe;

  OrderItem({
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    required this.idTipe,
  });

  double get total => unitPrice * quantity;
}
