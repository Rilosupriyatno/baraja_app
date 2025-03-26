import 'package:flutter/material.dart';

class VoucherPage extends StatefulWidget {
  final String selectedVoucher;
  final Function(String) onSelectedVoucher;

  const VoucherPage({
    super.key,
    required this.selectedVoucher,
    required this.onSelectedVoucher,
  });

  @override
  VoucherPageState createState() => VoucherPageState();
}

class VoucherPageState extends State<VoucherPage> {
  final List<String> _voucherList = [
    'Tidak ada voucher',
    'Diskon 10%',
    'Gratis Ongkir',
    'Potongan Rp 5.000',
  ];

  late String _selectedVoucher;

  @override
  void initState() {
    super.initState();
    _selectedVoucher = widget.selectedVoucher;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Voucher'),
      ),
      body: ListView.builder(
        itemCount: _voucherList.length,
        itemBuilder: (context, index) {
          return RadioListTile<String>(
            title: Text(_voucherList[index]),
            value: _voucherList[index],
            groupValue: _selectedVoucher,
            onChanged: (value) {
              setState(() {
                _selectedVoucher = value!;
              });
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              widget.onSelectedVoucher(_selectedVoucher);
              Navigator.pop(context);
            },
            child: Text('Gunakan Voucher'),
          ),
        ),
      ),
    );
  }
}