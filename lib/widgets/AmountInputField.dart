import 'package:flutter/material.dart';

class AmountInputField extends StatelessWidget {
  final Function(double) onChanged;
  const AmountInputField({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Enter Amount',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        onChanged(double.tryParse(value) ?? 0);
      },
    );
  }
}
