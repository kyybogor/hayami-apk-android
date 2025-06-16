class Customer {
  final String id;
  final String nmCustomer;
  final String name;
  final String address;
  final String telp;
  final String telp2;
  final String salesman;
  final String city;
  final String percentage; // <--- Tambahan ini

  Customer({
    required this.id,
    required this.nmCustomer,
    required this.name,
    required this.address,
    required this.telp,
    required this.telp2,
    required this.salesman,
    required this.city,
    required this.percentage, // <--- Tambahan ini
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id_customer'],
      nmCustomer: json['nm_customer'],
      name: json['name'],
      address: json['address'],
      telp: json['telp'],
      telp2: json['telp2'],
      salesman: json['salesman'],
      city: json['city'],
      percentage: json['percentage'] ?? '100', // <--- Pastikan default jika null
    );
  }
}
