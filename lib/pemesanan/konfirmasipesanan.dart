import 'package:flutter/material.dart';
import 'package:hayami_app/pemesanan/tambahpesanan.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class KonfirmasiPesanan extends StatefulWidget {
  final List<Produk> cartItems;
  final String selectedCustomer;

  const KonfirmasiPesanan({
    super.key,
    required this.cartItems,
    required this.selectedCustomer,
  });

  @override
  State<KonfirmasiPesanan> createState() => _KonfirmasiPesananState();
}

class _KonfirmasiPesananState extends State<KonfirmasiPesanan> {
  double discountPercent = 0.0;
  double discountNominal = 0.0;

  final _percentController = TextEditingController();
  final _nominalController = TextEditingController();

  bool _updatingFromPercent = false;
  bool _updatingFromNominal = false;

  String _selectedPaymentMethod = 'Cash';
  int? _selectedTOP;

  final currencyFormat = NumberFormat("#,##0", "id_ID");

  double get totalLusin =>
      widget.cartItems.fold(0, (sum, item) => sum + item.orderQty);

  double get subtotal =>
      widget.cartItems.fold(0, (sum, item) => sum + item.totalHarga);

  double get totalAfterDiscount {
  return subtotal - discountNominal;
}



  double get totalDiskonOtomatis {
    return widget.cartItems.fold(0, (sum, item) {
      int lusin = item.orderQty.floor();
      double sisa = item.orderQty - lusin;
      double setengahLusinDiskon = item.diskonPerLusin / 2;

      double diskonItem = lusin * item.diskonPerLusin;
      if (sisa >= 0.5) {
        diskonItem += setengahLusinDiskon;
      }
      return sum + diskonItem;
    });
  }

  @override
  void initState() {
    super.initState();
    _percentController.text = discountPercent.toStringAsFixed(1);
    _nominalController.text = discountNominal.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _percentController.dispose();
    _nominalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Konfirmasi Pesanan",
            style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "🧑 Customer: ${widget.selectedCustomer}",
              style: theme.textTheme.titleMedium!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Daftar Produk
            Text("Daftar Produk", style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            SizedBox(
              height: 240,
              child: ListView.separated(
                itemCount: widget.cartItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon Produk (Placeholder)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.sku,
                                  style: theme.textTheme.titleMedium!
                                      .copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${item.orderQty.toStringAsFixed(1)} lusin x Rp ${currencyFormat.format(item.harga)}",
                                  style: theme.textTheme.bodySmall,
                                ),
                                if (item.diskonPerLusin > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      "Diskon Customer: Rp ${currencyFormat.format(item.diskonPerLusin)} / lusin",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            "Rp ${currencyFormat.format(item.totalHarga)}",
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),
            Text("Diskon", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildDiscountInput(),
            const SizedBox(height: 24),
            Text("Metode Pembayaran", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildPaymentMethodDropdown(),
            if (_selectedPaymentMethod == 'Kredit') _buildTOPDropdown(),

            const SizedBox(height: 24),
            const Divider(thickness: 1),

            const SizedBox(height: 16),
            Text("Ringkasan", style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildSummaryRow("Total Lusin", "${totalLusin.toStringAsFixed(1)}"),
            _buildSummaryRow(
                "Subtotal", "Rp ${currencyFormat.format(subtotal)}"),
            _buildSummaryRow(
                "Diskon Customer", "Rp ${currencyFormat.format(totalDiskonOtomatis)}"),
            _buildSummaryRow("Diskon Produk", "Rp ${currencyFormat.format(discountNominal)}"),

            _buildSummaryRow("Total Setelah Diskon",
                "Rp ${currencyFormat.format(totalAfterDiscount)}"),

            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                "Konfirmasi Pesanan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
  if (_selectedPaymentMethod == 'Kredit' && _selectedTOP == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pilih durasi TOP untuk Kredit')),
    );
    return;
  }

  final url = Uri.parse("https://hayami.id/apps/erp/api-android/api/inputpenjualan.php"); // Ganti sesuai path file PHP

final Map<String, dynamic> payload = {
  "id_cust": widget.selectedCustomer ?? "C123",
  "tierlist": "Tier A", // bisa diganti variabel juga
  "sku": widget.cartItems.isNotEmpty ? widget.cartItems.first.sku : "SKU001", // ambil sku pertama sebagai contoh
  "total_qty": (totalLusin * 12).toInt(),// ambil variabel totalQty atau default 10
  "subtotal": subtotal ?? 0,
  "diskon": totalDiskonOtomatis,         // diskon otomatis dari produk
"diskon_persen": discountPercent,      // input manual persen dari user
"diskon_baru": discountNominal, 
  "top": (_selectedTOP ?? 30).toString(), // pastikan string sesuai contoh
  "tax": 0,
  "ppn": 0,
  "remark": "Catatan",
  "payment": _selectedPaymentMethod ?? "Cash",
  "dibuat_oleh": "Admin",
  "orders": widget.cartItems.map((item) {
  return {
    "sku": item.sku,
    "qty_order": item.orderQty.toInt(),
    "price": item.harga.toDouble(),
  };
}).toList(),
};

print("PAYLOAD YANG DIKIRIM:");
  print(json.encode(payload));

  try {
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(payload),
  );

  print('RESPONSE RAW:\n${response.body}');

  final result = json.decode(response.body);

  if (response.statusCode == 200) {
    if (result['pesan'] == 'Sukses') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pesanan berhasil dikirim.")),
      );
      Navigator.pop(context);
    } else {
      // Tampilkan pesan error dari server
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim pesanan: ${result['pesan']} ${result['error'] ?? ''}")),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Server error: ${response.statusCode}")),
    );
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Error: $e")),
  );
}

},

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                shadowColor: Colors.blueAccent.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDiscountInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _percentController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Diskon (%)',
              prefixIcon: const Icon(Icons.percent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            onChanged: (val) {
              if (_updatingFromNominal) return;
              _updatingFromPercent = true;

              final percent = double.tryParse(val) ?? 0.0;
              setState(() {
                discountPercent = percent;
                discountNominal = subtotal * (percent / 100);
                _nominalController.text = discountNominal.toStringAsFixed(0);
              });

              _updatingFromPercent = false;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _nominalController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Diskon (Rp)',
              prefixIcon: const Icon(Icons.money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
            onChanged: (val) {
              if (_updatingFromPercent) return;
              _updatingFromNominal = true;

              final nominal = double.tryParse(val) ?? 0.0;
              setState(() {
                discountNominal = nominal;
                discountPercent = subtotal > 0 ? (nominal / subtotal) * 100 : 0.0;
                _percentController.text = discountPercent.toStringAsFixed(1);
              });

              _updatingFromNominal = false;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        labelText: 'Metode Pembayaran',
        prefixIcon: const Icon(Icons.payment),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      items: const [
        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
        DropdownMenuItem(value: 'Kredit', child: Text('Kredit')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value!;
          _selectedTOP = null;
        });
      },
    );
  }

  Widget _buildTOPDropdown() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DropdownButtonFormField<int>(
        value: _selectedTOP,
        decoration: InputDecoration(
          labelText: 'Durasi TOP (hari)',
          prefixIcon: const Icon(Icons.timer),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        items: const [
          DropdownMenuItem(value: 30, child: Text('30 Hari')),
          DropdownMenuItem(value: 60, child: Text('60 Hari')),
          DropdownMenuItem(value: 90, child: Text('90 Hari')),
          DropdownMenuItem(value: 120, child: Text('120 Hari')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedTOP = value;
          });
        },
      ),
    );
  }
}
