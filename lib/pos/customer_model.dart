class Customer {
  final String id;
  final String nmCustomer;
  final String name;
  final String address;
  final String telp;
  final String storeType;
  final double diskonLusin;
  final String kota;
  final String email;
  final String sourceCustomer;
  final String noNpwp;
  final String namaNpwp;
  final String alamatNpwp;
  final String idLogin;
  final String passLogin;
  final String idCabang;
  final String sts;

  Customer({
    required this.id,
    required this.nmCustomer,
    required this.name,
    required this.address,
    required this.telp,
    required this.storeType,
    required this.diskonLusin,
    required this.kota,
    required this.email,
    required this.sourceCustomer,
    required this.noNpwp,
    required this.namaNpwp,
    required this.alamatNpwp,
    required this.idLogin,
    required this.passLogin,
    required this.idCabang,
    required this.sts,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id_customer']?.toString() ?? '',
      nmCustomer: json['nama_customer']?.toString() ?? '',
      name: json['nama_customer']?.toString() ?? '',
      address: json['alamat_lengkap']?.toString() ?? '',
      telp: json['no_telp']?.toString() ?? '',
      storeType: json['id_cabang']?.toString() ?? '',
      diskonLusin: double.tryParse('${json['diskon_lusin']}') ?? 0.0,
      kota: json['kota']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      sourceCustomer: json['source_customer']?.toString() ?? '',
      noNpwp: json['no_npwp']?.toString() ?? '',
      namaNpwp: json['nama_npwp']?.toString() ?? '',
      alamatNpwp: json['alamat_npwp']?.toString() ?? '',
      idLogin: json['id_login']?.toString() ?? '',
      passLogin: json['pass_login']?.toString() ?? '',
      idCabang: json['id_cabang']?.toString() ?? '',
      sts: json['sts']?.toString() ?? '',
    );
  }

factory Customer.fromMap(Map<String, dynamic> map) {
  return Customer(
    id: map['id_customer']?.toString() ?? '',
    nmCustomer: map['nama_customer']?.toString() ?? '',
    name: map['nama_customer']?.toString() ?? '',
    address: map['alamat_lengkap']?.toString() ?? '',
    telp: map['no_telp']?.toString() ?? '',
    storeType: map['id_cabang']?.toString() ?? '',
    diskonLusin: double.tryParse('${map['diskon_lusin']}') ?? 0.0,
    kota: map['kota']?.toString() ?? '',
    email: map['email']?.toString() ?? '',
    sourceCustomer: map['source_customer']?.toString() ?? '',
    noNpwp: map['no_npwp']?.toString() ?? '',
    namaNpwp: map['nama_npwp']?.toString() ?? '',
    alamatNpwp: map['alamat_npwp']?.toString() ?? '',
    idLogin: map['id_login']?.toString() ?? '',
    passLogin: map['pass_login']?.toString() ?? '',
    idCabang: map['id_cabang']?.toString() ?? '',
    sts: map['sts']?.toString() ?? '',
  );
}

  Map<String, dynamic> toMap() {
    return {
      'id_customer': id,
      'nama_customer': nmCustomer,
      'alamat_lengkap': address,
      'no_telp': telp,
      'id_cabang': storeType, // Simpan storeType (bisa juga idCabang kalau kamu mau konsisten)
      'diskon_lusin': diskonLusin,
      'kota': kota,
      'email': email,
      'source_customer': sourceCustomer,
      'no_npwp': noNpwp,
      'nama_npwp': namaNpwp,
      'alamat_npwp': alamatNpwp,
      'id_login': idLogin,
      'pass_login': passLogin,
      'sts': sts,
    };
  }
}
