import 'package:flutter/material.dart';
import 'package:gst_calculator/screens/gst_result_screen.dart';

class CalculatorHome extends StatefulWidget {
  @override
  _CalculatorHomeState createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _display = '',
      _resultDisplay = '',
      _input = '',
      _error = '',
      _netprice = '';
  double _gstPercentage = 0.0;

  List<String> _expression = [];
  late TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController(text: _display);
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  void _appendNumber(String number) {
    if (number == '.' && _input.contains('.')) return;
    setState(() {
      _input += number;
      _display += number;
      _displayController.text = _display;
      _updateLiveResult();
    });
  }

  void _handleOperation(String operation) {
    if (_display.isEmpty) return;
    setState(() {
      if (isLastCharAnOperation()) {
        var displayParts = _display.trim().split(' ');
        displayParts.removeLast();
        _display = displayParts.join(' ') + ' $operation ';
        _expression.removeLast();
      } else {
        if (_input.isEmpty && _expression.isEmpty) {
          // This means we've just removed an operation and are now adding another
          _expression.add(_display);
        } else if (_input.isNotEmpty) {
          _expression.add(_input);
        }
        _display += ' $operation ';
        _input = '';
      }
      _expression.add(operation);
      _displayController.text = _display;
    });
  }

  bool _isOperation(String char) => ['+', '-', 'X', '/', '%'].contains(char);

  bool isLastCharAnOperation() => _isOperation(_display.trim().split(" ").last);

  void _updateLiveResult() {
    if (_expression.length < 2) return;
    var evalExpression = List.from(_expression);
    if (_input.isNotEmpty) evalExpression.add(_input);
    double? result = _evaluateExpression(evalExpression);
    if (result == result!.floor()) {
      // checks if result is a whole number
      _resultDisplay =
          result.toStringAsFixed(0); // Display .00 for whole numbers
    } else {
      _resultDisplay = result.toStringAsFixed(
          2); // Display exact value up to two decimal places for non-whole numbers
    }
  }

  double? _evaluateExpression(List<dynamic> expression) {
    if (expression.isEmpty) return null;

    // Stack to hold values and operators
    List<double> values = [];
    List<String> ops = [];

    for (var item in expression) {
      if (item == ' ') continue;

      if (_isOperation(item)) {
        while (ops.isNotEmpty && _hasPrecedence(item, ops.last)) {
          values.add(_applyOp(
              ops.removeLast(), values.removeLast(), values.removeLast()));
        }
        ops.add(item);
      } else if (item == '%') {
        double value = values.removeLast() / 100;
        values.add(value);
      } else {
        values.add(double.parse(item));
      }
    }

    while (ops.isNotEmpty) {
      values.add(
          _applyOp(ops.removeLast(), values.removeLast(), values.removeLast()));
    }

    return values.isEmpty ? null : values.last;
  }

  bool _hasPrecedence(String op1, String op2) {
    if ((op1 == 'X' || op1 == '/') && (op2 == '+' || op2 == '-')) {
      return false;
    }
    return true;
  }

  double _applyOp(String op, double b, double a) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case 'X':
        return a * b;
      case '/':
        if (b != 0) {
          return a / b;
        }
        throw Exception('Cannot divide by zero');
      default:
        return 0;
    }
  }

  void _applyGST() {
    if (_resultDisplay.isNotEmpty) {
      double result = double.parse(_resultDisplay);
      double gstAmount = result * _gstPercentage / 100;
      double cgst = gstAmount / 2;
      double sgst = cgst;
      double igst = gstAmount;

      setState(() {
        _resultDisplay =
            'Inter-state: CGST: $cgst, SGST: $sgst\nIntra-state: IGST: $igst';
        _display = (result + gstAmount).toStringAsFixed(2);
        _displayController.text = _display;
      });
    }
  }

  void _performCalculation() {
    if (_input.isNotEmpty) _expression.add(_input);
    if (_expression.length < 3) return;
    double? result = _evaluateExpression(_expression);
    if (result == null) return;
    setState(() {
      _resultDisplay = result.toStringAsFixed(0);
      _display = result.toStringAsFixed(2);
      _displayController.text = _display;
      _input = '';
      _expression.clear();
    });
  }

  void _appendDecimal() {
    setState(() {
      _input += '0.00';
      _display += '0.00';
      _displayController.text = _display;
      _updateLiveResult();
    });
  }

  void _clear() {
    setState(() {
      _input = '';
      _display = '';
      _resultDisplay = '';
      _expression.clear();
      _error = '';
      _displayController.text = _display;
    });
  }

  void _removeLastCharacter() {
    if (_display.isEmpty) return;
    setState(() {
      if (isLastCharAnOperation()) {
        var displayParts = _display.trim().split(' ');
        _display = displayParts.sublist(0, displayParts.length - 1).join(' ');

        _expression.removeLast();

        if (_expression.isNotEmpty && !_isOperation(_expression.last)) {
          _input = _expression.last;
        } else {
          _input = '';
        }
      } else {
        _display = _display.substring(0, _display.length - 1);
        _input = _input.substring(0, _input.length - 1);

        if (_expression.isNotEmpty) {
          _expression[_expression.length - 1] = _input;
        }
      }
      _displayController.text = _display;
      _updateLiveResult();
    });
  }

  void _applyPercentageToResult(double percentage) {
    setState(() {
      if (_input.isNotEmpty) {
        _netprice = _input; // Store the original _input value in _netprice
        _updateInputWithPercentage(percentage);
      } else if (_resultIsAvailable()) {
        _netprice =
            _resultDisplay; // Store the original _resultDisplay value in _netprice
        _updateDisplayWithPercentage(percentage);
      } else {
        _showPercentageApplicationError();
        return;
      }
      _navigateToGstResultScreen(percentage);
    });
  }

  bool _inputIsPresentAndValid() {
    return _input.isNotEmpty &&
        (_expression.isEmpty || !_isOperation(_expression.last));
  }

  bool _resultIsAvailable() {
    return _resultDisplay.isNotEmpty;
  }

  void _updateInputWithPercentage(double percentage) {
    double currentValue = double.parse(_input);
    _netprice =
        _input; // Save the original input to netprice before any operations
    double updatedValue = currentValue + currentValue * (percentage / 100.0);
    _input = updatedValue.toStringAsFixed(2);
    _display = _input;
    _displayController.text = _display;
  }

  void _updateDisplayWithPercentage(double percentage) {
    if (_input.isNotEmpty) {
      _updateInputWithPercentage(percentage);
    } else if (_resultIsAvailable()) {
      _netprice =
          _resultDisplay; // Save the original result to netprice before any operations
      double currentResult = double.parse(_resultDisplay);
      double updatedResult =
          currentResult + currentResult * (percentage / 100.0);
      _display = updatedResult.toStringAsFixed(2);
      _displayController.text = _display;
    } else {
      _showPercentageApplicationError();
      return;
    }
  }

  void _navigateToGstResultScreen(double percentage) {
    double evaluation;
    if (_netprice.isNotEmpty) {
      evaluation = double.parse(_netprice);
    } else {
      return;
    }

    double gstAmount = evaluation * (percentage / 100.0);
    double cgst = gstAmount / 2;
    double sgst = cgst;
    double igst = gstAmount;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GstResultScreen(
          netPrice: _netprice, // Here, netPrice is always the original value
          cgst: cgst,
          sgst: sgst,
          igst: igst,
          appliedPercentage: percentage,
        ),
      ),
    );
  }

  void _showPercentageApplicationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cannot apply GST percentage right now!'),
      ),
    );
  }

  void _updateGSTPercentage(double newPercentage) {
    _applyPercentageToResult(newPercentage);
  }

  Widget _buildAddPercentageRow() {
    return Expanded(
      child: Row(
        children: [
          _buildButton("+1%", () => _updateGSTPercentage(1.0)),
          _buildButton("+5%", () => _updateGSTPercentage(5.0)),
          _buildButton("+12%", () => _updateGSTPercentage(12.0)),
          _buildButton("+18%", () => _updateGSTPercentage(18.0)),
        ],
      ),
    );
  }

  Widget _buildSubtractPercentageRow() {
    return Expanded(
      child: Row(
        children: [
          _buildButton("-1%", () => _updateGSTPercentage(-1.0)),
          _buildButton("-5%", () => _updateGSTPercentage(-5.0)),
          _buildButton("-12%", () => _updateGSTPercentage(-12.0)),
          _buildButton("-18%", () => _updateGSTPercentage(-18.0)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double maxWidth = 600;
    double mainPadding = width < maxWidth ? 8.0 : 24.0;
    return Scaffold(
      body: Center(
        child: Container(
          width: width > maxWidth ? maxWidth : null,
          padding: EdgeInsets.all(mainPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildResultDisplay(),
              _buildInputDisplay(),
              SizedBox(height: 20),
              _buildButtonGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.bottomRight,
      child: Text(
        _resultDisplay,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildInputDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.bottomRight,
      child: TextField(
        controller: _displayController,
        readOnly: true,
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        decoration: InputDecoration(border: InputBorder.none, hintText: "0"),
        cursorWidth: 2.0,
        cursorColor: Colors.black,
        cursorRadius: Radius.circular(2.0),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAddPercentageRow(),
          _buildSubtractPercentageRow(),
          _buildButtonRow(['AC', '%', '/', '←']),
          _buildButtonRow(['7', '8', '9', 'X']),
          _buildButtonRow(['4', '5', '6', '-']),
          _buildButtonRow(['1', '2', '3', '+']),
          _buildButtonRow(['0', '00', '.', '=']),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> values) {
    return Expanded(
      child: Row(
        children: values
            .map((value) => _buildButton(value, _getButtonAction(value)))
            .toList(),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(300),
            ),
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(30),
          ),
        ),
      ),
    );
  }

  VoidCallback _getButtonAction(String value) {
    switch (value) {
      case 'AC':
        return _clear;
      case '←':
        return _removeLastCharacter;
      case '=':
        return _performCalculation;
      case '+':
      case '-':
      case 'X':
      case '/':
      case '%':
        return () => _handleOperation(value);
      default:
        return () => _appendNumber(value);
    }
  }
}
