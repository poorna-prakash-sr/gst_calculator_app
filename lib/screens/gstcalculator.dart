import 'package:flutter/material.dart';

class GSTCalculator extends StatefulWidget {
  @override
  _GSTCalculatorState createState() => _GSTCalculatorState();
}

class _GSTCalculatorState extends State<GSTCalculator> {
  double? _gstPercentage;
  double? _amount;
  double? _cgst;
  double? _sgst;
  double? _igst;

  double getResponsiveTextSize(double screenWidth) {
    if (screenWidth < 360) {
      return 14;
    } else if (screenWidth < 415) {
      return 16;
    } else {
      return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              labelStyle:
                  TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            ),
            style: TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            onChanged: (value) {
              _amount = double.tryParse(value);
              _calculateGST();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Enter GST Percentage',
              labelStyle:
                  TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            ),
            style: TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            onChanged: (value) {
              _gstPercentage = double.tryParse(value);
              _calculateGST();
            },
          ),
        ),
        if (_cgst != null && _sgst != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Inter-state:\nCGST: $_cgst\nSGST: $_sgst',
              style: TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            ),
          ),
        if (_igst != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Intra-state:\nIGST: $_igst',
              style: TextStyle(fontSize: getResponsiveTextSize(screenWidth)),
            ),
          ),
      ],
    );
  }

  void _calculateGST() {
    if (_gstPercentage != null && _amount != null) {
      setState(() {
        _cgst = (_amount! * _gstPercentage! / 100) / 2;
        _sgst = _cgst;
        _igst = _amount! * _gstPercentage! / 100;
      });
    }
  }
}
