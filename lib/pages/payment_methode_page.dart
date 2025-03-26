import 'package:flutter/material.dart';

class PaymentMethodePage extends StatefulWidget {
  final String selectedMethode;
  final Function(String) onSelectedMethode;

  const PaymentMethodePage({
    super.key,
    required this.selectedMethode,
    required this.onSelectedMethode,
  });

  @override
  PaymentMethodePageState createState() => PaymentMethodePageState();
}

class PaymentMethodePageState extends State<PaymentMethodePage> {
  late String _selectedMethode;

  @override
  void initState() {
    super.initState();
    _selectedMethode = widget.selectedMethode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Metode Pembayaran'),
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: Text('Gopay'),
            value: 'Gopay',
            groupValue: _selectedMethode,
            onChanged: (value) {
              setState(() {
                _selectedMethode = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('Dana'),
            value: 'Dana',
            groupValue: _selectedMethode,
            onChanged: (value) {
              setState(() {
                _selectedMethode = value!;
              });
            },
          ),
          RadioListTile<String>(
            title: Text('OVO'),
            value: 'OVO',
            groupValue: _selectedMethode,
            onChanged: (value) {
              setState(() {
                _selectedMethode = value!;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              widget.onSelectedMethode(_selectedMethode);
              Navigator.pop(context);
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }
}