import 'package:flutter/material.dart';

class NumberButton extends StatelessWidget {
  final int number;
  final Function(int) onPressed;

  const NumberButton(
      {super.key, required this.number, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(number),
      child: Text('$number'),
    );
  }
}

class OperationButton extends StatelessWidget {
  final String operation;
  final Function(String) onPressed;

  const OperationButton(
      {super.key, required this.operation, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onPressed(operation),
      child: Text(operation),
    );
  }
}
