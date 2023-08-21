import 'package:flutter/material.dart';

class GSTPercentageButtons extends StatelessWidget {
  final double selectedPercentage;
  final List<double> percentages;
  final Function(double) onPressed;

  const GSTPercentageButtons({
    super.key,
    required this.selectedPercentage,
    required this.percentages,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: percentages.map((percentage) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ElevatedButton(
            onPressed: () => onPressed(percentage),
            style: ElevatedButton.styleFrom(
              foregroundColor:
                  selectedPercentage == percentage ? Colors.blue : Colors.grey,
            ),
            child: Text('$percentage%'),
          ),
        );
      }).toList(),
    );
  }
}
