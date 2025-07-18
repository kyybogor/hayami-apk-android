import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Returbarang extends StatefulWidget {
  const Returbarang({super.key});

  @override
  State<Returbarang> createState() => _ReturbarangState();
}

class _ReturbarangState extends State<Returbarang> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> items = [];
  bool isPoTransaksi = false;
  bool isLoading = false;
  bool soCustomerSet = false;
  List<Customer> customers = [];
  String? selectedCustomerId;
  bool isCustomerLoading = false;
  TextEditingController _customerController = TextEditingController();

  Future<void> fetchItems(String idTransaksi) async {
    setState(() {
      isLoading = true;
    });

    final keluarUrl =
        'http://192.168.1.11/pos/detail_keluar.php?id_transaksi=$idTransaksi';
    final masukUrl =
        'http://192.168.1.11/pos/detail_masuk.php?id_transaksi=$idTransaksi';

    try {
      final keluarResponse = await http.get(Uri.parse(keluarUrl));
      final masukResponse = await http.get(Uri.parse(masukUrl));

      List<Item> combinedItems = [];

      if (keluarResponse.statusCode == 200) {
        final data = json.decode(keluarResponse.body);
        if (data['status'] == 'success' && data['data'].isNotEmpty) {
          final parent = data['data'][0];
          final idTransaksiKeluar = parent['id_transaksi'] ?? '';
          final itemsJson = parent['items'] as List;

          combinedItems.addAll(itemsJson.map((itemData) {
            final itemMap = Map<String, dynamic>.from(itemData);
            itemMap['id_transaksi'] = idTransaksiKeluar;
            return Item.fromJson(itemMap);
          }));
        }
      }

      if (masukResponse.statusCode == 200) {
        
        final data = json.decode(masukResponse.body);
        if (data['status'] == 'success' && data['data'].isNotEmpty) {
          final parent = data['data'][0];
          final idTransaksiMasuk = parent['id_transaksi'] ?? '';
          final itemsJson = parent['items'] as List;

          combinedItems.addAll(itemsJson.map((itemData) {
            final itemMap = Map<String, dynamic>.from(itemData);
            itemMap['id_transaksi'] = idTransaksiMasuk;
            return Item.fromJson(itemMap);
          }));
        }
      }

      setState(() {
        items = combinedItems
            .where((item) => int.tryParse(item.qtyRetur) != 0)
            .toList();
      });
    } catch (e) {
      setState(() {
        items = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isCustomerLoading = true;
    });

    final url = Uri.parse('http://192.168.1.11/hayami/customer.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> customerData = data['data'];
          setState(() {
            customers =
                customerData.map((json) => Customer.fromJson(json)).toList();

            final defaultCustomer = customers.firstWhere(
              (c) => c.namaCustomer.toUpperCase() == 'CASH',
              orElse: () => customers.isNotEmpty
                  ? customers[0]
                  : Customer(idCustomer: 'CASH', namaCustomer: 'CASH'),
            );

            selectedCustomerId = defaultCustomer.idCustomer;
            _customerController.text =
                '${defaultCustomer.idCustomer} | ${defaultCustomer.namaCustomer}';
          });
        }
      }
    } catch (e) {
      setState(() {
        customers = [];
      });
    } finally {
      setState(() {
        isCustomerLoading = false;
      });
    }
  }

  String formatRupiah(String amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(int.tryParse(amount) ?? 0)}';
  }

  Future<Map<String, String>> getUserAndCabang() async {
    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_user') ?? '';
    final idCabang = prefs.getString('id_cabang') ?? '';
    return {'user': idUser, 'id_cabang': idCabang};
  }

  List<ReturItem> returList = [];
  bool isReturLoading = false;

  Future<void> fetchReturList() async {
    setState(() {
      isReturLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final idUser = prefs.getString('id_user') ?? 'admin';
    final url = 'http://192.168.1.11/pos/list_retur.php?id_transaksi=$idUser';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          returList = data.map((item) => ReturItem.fromJson(item)).toList();
        });
      }
    } catch (e) {
      setState(() {
        returList = [];
      });
    } finally {
      setState(() {
        isReturLoading = false;
      });
    }
  }

  void _showSyncDialog() {
    String? selectedSales = 'Sales 1';
    TextEditingController keteranganController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Sinkronasi Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedSales,
                        decoration: const InputDecoration(
                          labelText: 'Sales',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Sales 1', 'Sales 2', 'Sales 3']
                            .map((sales) => DropdownMenuItem(
                                  value: sales,
                                  child: Text(sales),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedSales = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        minLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (selectedCustomerId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Pilih customer terlebih dahulu')),
                                );
                                return;
                              }

                              Navigator.of(context).pop();

                              bool success = await syncRetur(
                                sales: selectedSales ?? '',
                                keterangan: keteranganController.text.trim(),
                                idCustomer: selectedCustomerId!,
                                custInvoice: selectedCustomerId!,
                                returItems: returList,
                              );

                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Sinkronasi berhasil\nSales: $selectedSales\nKeterangan: ${keteranganController.text}'),
                                  ),
                                );
                                await fetchItems(_searchController.text);
                                await fetchReturList();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Sinkronasi gagal, coba lagi')),
                                );
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> syncRetur({
    required String sales,
    required String keterangan,
    required String idCustomer,
    required String custInvoice,
    required List<ReturItem> returItems,
  }) async {
    final url = Uri.parse('http://192.168.1.11/pos/sinkronasi_retur.php');

    final body = jsonEncode({
      'sales': sales,
      'keterangan': keterangan,
      'id_customer': idCustomer,
      'cust_invoice': custInvoice,
      'retur_items': returItems
          .map((r) => {
                'no_id': r.noId,
                'total': r.total,
                'id_bahan': r.idBahan,
                'model': r.model,
                'ukuran': r.ukuran,
              })
          .toList(),
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return true;
        } else {
          print('Sinkronasi gagal: ${data['error']}');
          return false;
        }
      } else {
        print('Response error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error saat sinkronasi: $e');
      return false;
    }
  }

  Future<void> postReturBarang({
    required String idCustomer,
    required String idBahan,
    required String model,
    required String ukuran,
    required double qty,
    required String harga,
    required String idCabang,
    required String user,
    required String idTransaksi,
  }) async {
    final url = Uri.parse('http://192.168.1.11/pos/retur.php');

    final response = await http.post(url, body: {
      'id_customer': idCustomer,
      'id_bahan': idBahan,
      'model': model,
      'ukuran': ukuran,
      'qty': qty.toString(),
      'harga': harga,
      'id_cabang': idCabang,
      'user': user,
      'id_transaksi': idTransaksi,
    });

    final body = json.decode(response.body);
    if (body['status'] != 'success') {
      throw Exception('Gagal: ${body['message']}');
    }
  }

  Future<void> deleteRetur(String noId) async {
    final url = Uri.parse('http://192.168.1.11/pos/delete_retur.php');

    try {
      final response = await http.post(url, body: {'no_id': noId});
      final result = json.decode(response.body);

      if (result['status'] == 'success') {
        fetchReturList();
        await fetchItems(_searchController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retur berhasil dihapus'),
            duration: Duration(milliseconds: 500),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Gagal menghapus data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat menghapus: $e')),
      );
    }
  }

  void _showItemDetails(Item item) {
    int qty = int.parse(item.qtyRetur);
    final TextEditingController qtyController =
        TextEditingController(text: qty.toString());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.idBahan,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        controller: TextEditingController(text: item.model),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Ukuran',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        controller: TextEditingController(text: item.ukuran),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        ),
                        controller:
                            TextEditingController(text: item.harga.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: TextField(
                        readOnly: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          labelStyle: TextStyle(fontSize: 12),
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        color: Colors.white,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        onPressed: () {
                          if (qty > 1) {
                            setState(() {
                              qty--;
                              qtyController.text = qty.toString();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 100,
                      height: 40,
                      child: TextField(
                        controller: qtyController,
                        textAlign: TextAlign.center,
                        readOnly: true,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.zero,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            if (qty < int.parse(item.qtyRetur)) {
                              setState(() {
                                qty++;
                                qtyController.text = qty.toString();
                              });
                            }
                          }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final userData = await getUserAndCabang();
                        try {
                          await postReturBarang(
                            idCustomer: selectedCustomerId ?? 'CUST001',
                            idBahan: item.idBahan,
                            model: item.model,
                            ukuran: item.ukuran,
                            qty: double.parse(qtyController.text),
                            harga: item.harga,
                            idCabang: userData['id_cabang']!,
                            user: userData['user']!,
                            idTransaksi: item.idTransaksi,
                          );
                          Navigator.of(context).pop();
                          fetchItems(_searchController.text);
                          fetchReturList();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Retur berhasil disimpan'),
                              duration: Duration(milliseconds: 500),
                            ),
                          );
                        } catch (e) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Gagal: $e')),
                          );
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchReturList();
    fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retur Barang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'ID Transaksi',
                border: OutlineInputBorder(),
suffixIcon: IconButton(
  icon: const Icon(Icons.search),
  onPressed: () {
    final id = _searchController.text.trim().toUpperCase();
    if (id.isNotEmpty) {
      setState(() {
        isPoTransaksi = id.startsWith('PO');
      });

      if (id.startsWith('PO')) {
        // Reset flag soCustomerSet karena sekarang PO
        soCustomerSet = false;

        final hayamiCustomer = customers.firstWhere(
          (c) => c.idCustomer.toUpperCase().contains('HAYAMI'),
          orElse: () => Customer(idCustomer: 'HAYAMI', namaCustomer: 'HAYAMI'),
        );

        selectedCustomerId = hayamiCustomer.idCustomer;
        _customerController.text =
            '${hayamiCustomer.idCustomer} | ${hayamiCustomer.namaCustomer}';

      } else if (id.startsWith('SO')) {
        // Kalau customer SO belum pernah diset, set ke CASH
        if (!soCustomerSet) {
          final cashCustomer = customers.firstWhere(
            (c) => c.idCustomer.toUpperCase() == 'CASH',
            orElse: () => Customer(idCustomer: 'CASH', namaCustomer: 'CASH'),
          );

          selectedCustomerId = cashCustomer.idCustomer;
          _customerController.text =
              '${cashCustomer.idCustomer} | ${cashCustomer.namaCustomer}';

          soCustomerSet = true; // tandai sudah set customer SO
        }
        // kalau sudah diset sebelumnya, customer gak diubah
      } else {
        // Reset flag kalau bukan PO atau SO
        soCustomerSet = false;

        selectedCustomerId = null;
        _customerController.clear();
      }

      fetchItems(id);
    }
  },
),              ),
            ),
            const SizedBox(height: 12),
Autocomplete<Customer>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text == '') {
      return const Iterable<Customer>.empty();
    }

    return customers.where((Customer customer) {
      final name = customer.namaCustomer.toLowerCase();
      final id = customer.idCustomer.toLowerCase();

      if (isPoTransaksi) {
        // Kalau PO, tidak perlu pilih, karena otomatis HAYAMI
        return false;
      } else {
        // Kalau SO, sembunyikan HAYAMI dari daftar
        return !id.contains('hayami') &&
               name.contains(textEditingValue.text.toLowerCase());
      }
    });
  },
  displayStringForOption: (Customer option) =>
      '${option.idCustomer} | ${option.namaCustomer}',
  fieldViewBuilder: (BuildContext context,
      TextEditingController fieldTextEditingController,
      FocusNode fieldFocusNode,
      VoidCallback onFieldSubmitted) {
    fieldTextEditingController.text = _customerController.text;

    return TextField(
      controller: fieldTextEditingController,
      focusNode: fieldFocusNode,
      enabled: !isPoTransaksi, // Disable input jika PO
      decoration: const InputDecoration(
        labelText: 'Cari Customer',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        _customerController.text = value;
      },
    );
  },
  onSelected: (Customer selection) {
    setState(() {
      selectedCustomerId = selection.idCustomer;
      _customerController.text =
          '${selection.idCustomer} | ${selection.namaCustomer}';
    });
  },
),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (items.isEmpty)
                    const Center(child: Text("Tidak ada data"))
                  else
                    ...items.map((item) => Card(
                          child: ListTile(
                            title: Text(item.idBahan),
                            subtitle: Text(
                                'Model: ${item.model}\nUkuran: ${item.ukuran}\nQty: ${item.qtyRetur}'),
                            trailing: Text(formatRupiah(item.total)),
                            onTap: () => _showItemDetails(item),
                          ),
                        )),
                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const Text(
                    'Daftar yang dipilih',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (isReturLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (returList.isEmpty)
                    const Center(child: Text("Belum ada daftar yang dipilih"))
                  else
                    ...returList.map((r) => Card(
                          child: ListTile(
                            title: Text(r.idBahan),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Model: ${r.model}'),
                                Text('Ukuran: ${r.ukuran}'),
                                Text('Qty: ${r.qty} ${r.uom}'),
                                Text('Harga: ${formatRupiah(r.harga)}'),
                                Text('Total: ${formatRupiah(r.total)}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Konfirmasi Hapus'),
                                    content: const Text(
                                        'Yakin ingin menghapus retur ini?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Batal'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          fetchItems(_searchController.text);
                                          fetchReturList();
                                          Navigator.of(context).pop();
                                          deleteRetur(r.noId);
                                        },
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                  if (returList.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _showSyncDialog,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sinkronasi'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Item {
  final String idBahan;
  final String model;
  final String ukuran;
  final String qtyRetur;
  final String harga;
  final String total;
  final String idTransaksi;

  Item({
    required this.idBahan,
    required this.model,
    required this.ukuran,
    required this.qtyRetur,
    required this.harga,
    required this.total,
    required this.idTransaksi,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      idBahan: json['id_bahan'],
      model: json['model'],
      ukuran: json['ukuran'],
      qtyRetur: json['qty_retur'].toString(),
      harga: json['harga'],
      total: json['total'],
      idTransaksi: json['id_transaksi'],
    );
  }
}

class ReturItem {
  final String noId;
  final String idBahan;
  final String model;
  final String ukuran;
  final String uom;
  final String harga;
  final String total;
  final String qty;

  ReturItem({
    required this.noId,
    required this.idBahan,
    required this.model,
    required this.ukuran,
    required this.uom,
    required this.harga,
    required this.total,
    required this.qty,
  });

  factory ReturItem.fromJson(Map<String, dynamic> json) {
    return ReturItem(
      noId: json['no_id'],
      idBahan: json['id_bahan'],
      model: json['model'],
      ukuran: json['ukuran'],
      uom: json['uom'],
      harga: json['harga'],
      total: json['total'],
      qty: json['qty'],
    );
  }
}

class Customer {
  final String idCustomer;
  final String namaCustomer;

  Customer({
    required this.idCustomer,
    required this.namaCustomer,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      idCustomer: json['id_customer'],
      namaCustomer: json['nama_customer'],
    );
  }
}
