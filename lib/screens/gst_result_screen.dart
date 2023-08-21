import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GstResultScreen extends StatefulWidget {
  final String netPrice;
  final double cgst, sgst, igst, appliedPercentage;

  GstResultScreen({
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.appliedPercentage,
    required this.netPrice,
  });

  @override
  _GstResultScreenState createState() => _GstResultScreenState();
}

class _GstResultScreenState extends State<GstResultScreen> {
  String dropdownValue = 'All';

  String formatNumber(double num) {
    var format = NumberFormat('#,##,###0.00',
        'en_IN'); // Indian locale for comma separated number style
    return format.format(num);
  }

  double _calculateTotal() {
    return double.parse(widget.netPrice) +
        (dropdownValue == 'All' ? widget.igst : (widget.cgst + widget.sgst));
  }

  double get roundOffDifference {
    double total = _calculateTotal();
    double roundedTotal = total.roundToDouble();
    return roundedTotal - total;
  }

  double get roundedTotal => (_calculateTotal() + roundOffDifference);

  Widget _buildPriceRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label), Text("${formatNumber(value)}")],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("GST Result")),
      body: Center(
        child: Container(
          width: 450,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: dropdownValue,
                items: ['All', 'Inter-State', 'Intra-State']
                    .map((value) => DropdownMenuItem(
                          child: Text(value),
                          value: value,
                        ))
                    .toList(),
                onChanged: (newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
              ),
              _buildPriceRow("Net Price:", double.parse(widget.netPrice)),
              if (dropdownValue == 'All' || dropdownValue == 'Intra-State')
                _buildPriceRow(
                    "CGST (${formatNumber((widget.appliedPercentage / 2))}%):",
                    widget.cgst),
              if (dropdownValue == 'All' || dropdownValue == 'Intra-State')
                _buildPriceRow(
                    "SGST (${formatNumber(widget.appliedPercentage)}%):",
                    widget.sgst),
              if (dropdownValue == 'All' || dropdownValue == 'Inter-State')
                _buildPriceRow(
                    "IGST (${formatNumber(widget.appliedPercentage)}%):",
                    widget.igst),
              _buildPriceRow("Round off:", roundOffDifference),
              SizedBox(height: 10),
              _buildPriceRow("Total:", roundedTotal),
            ],
          ),
        ),
      ),
    );
  }
}
