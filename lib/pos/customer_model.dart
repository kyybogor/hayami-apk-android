class Customer {
  final String id;
  final String nmCustomer;
  final String name;
  final String address;
  final String telp;
  final String storeType;
  final double diskonLusin;

  Customer({
    required this.id,
    required this.nmCustomer,
    required this.name,
    required this.address,
    required this.telp,
    required this.storeType,
    required this.diskonLusin,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id_customer'] ?? '',
      nmCustomer: json['nama_customer'] ?? '',
      name: json['nama_customer'] ?? '',
      address: json['alamat_lengkap'] ?? '',
      telp: json['no_telp'] ?? '',
      storeType: json['id_cabang'] ?? '',
      diskonLusin: double.tryParse(json['diskon_lusin'] ?? '0.0') ?? 0.0,
    );
  }
}
