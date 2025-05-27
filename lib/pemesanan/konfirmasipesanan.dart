import 'package:flutter/material.dart';
import 'package:hayami_app/pemesanan/tambahpesanan.dart';
import 'package:intl/intl.dart';

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
    final percentDiscount = subtotal * (discountPercent / 100);
    final totalDisc = percentDiscount + discountNominal;
    return subtotal - totalDisc;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("🧑 Customer: ${widget.selectedCustomer}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  return ListTile(
                    title: Text(item.sku),
                    subtitle: Text(
                        "${item.orderQty.toStringAsFixed(1)} lusin x Rp ${currencyFormat.format(item.harga)}"),
                    trailing: Text(
                      "Rp ${currencyFormat.format(item.totalHarga)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            _buildDiscountInput(),
            const SizedBox(height: 12),
            _buildPaymentMethodDropdown(),
            if (_selectedPaymentMethod == 'Kredit') _buildTOPDropdown(),

            const Divider(height: 24, thickness: 1),

            _buildSummaryRow("Total Lusin", "${totalLusin.toStringAsFixed(1)}"),
            _buildSummaryRow("Subtotal", "Rp ${currencyFormat.format(subtotal)}"),
            _buildSummaryRow("Total Setelah Diskon",
                "Rp ${currencyFormat.format(totalAfterDiscount)}"),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("Konfirmasi Pesanan"),
              onPressed: () {
                if (_selectedPaymentMethod == 'Kredit' && _selectedTOP == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pilih durasi TOP untuk Kredit')),
                  );
                  return;
                }

                // TODO: Handle submit logic here
                // print('Customer: ${widget.selectedCustomer}');
                // print('Metode: $_selectedPaymentMethod, TOP: $_selectedTOP');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Diskon (%)',
              prefixIcon: Icon(Icons.percent),
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
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _nominalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Diskon (Rp)',
              prefixIcon: Icon(Icons.money),
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
      decoration: const InputDecoration(
        labelText: 'Metode Pembayaran',
        prefixIcon: Icon(Icons.payment),
        border: OutlineInputBorder(),
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
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int>(
        value: _selectedTOP,
        decoration: const InputDecoration(
          labelText: 'Durasi TOP (hari)',
          prefixIcon: Icon(Icons.timer),
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: 30, child: Text('30 Hari')),
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
