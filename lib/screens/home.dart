import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gst_calculator/db/db.dart';
import 'package:gst_calculator/model/CalculationHistory.dart';
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
  bool _isDarkMode = false;
  int? _cursorPosition;
  bool _manuallySetCursor = false;
  List<String> _originalExpression = [];
  bool _percentageApplied = false;

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

  double getResponsiveTextSize(double screenWidth) {
    if (screenWidth < 360) {
      return 14;
    } else if (screenWidth < 415) {
      return 16;
    } else {
      return 18;
    }
  }

  double getResponsiveButtonPadding(double screenWidth) {
    if (screenWidth < 360) {
      return 20;
    } else if (screenWidth < 415) {
      return 25;
    } else {
      return 30;
    }
  }

  void _appendNumber(String number) {
    if (number == '.' && _input.contains('.')) return;

    setState(() {
      if (_manuallySetCursor &&
          _cursorPosition != null &&
          _cursorPosition! <= _display.length) {
        // Update _display and adjust the cursor position
        _display = _display.substring(0, _cursorPosition!) +
            number +
            _display.substring(_cursorPosition!);
        _cursorPosition = _cursorPosition! + number.length;

        // Update _input correctly with cursor position
        if (_input.isEmpty &&
            _expression.isNotEmpty &&
            !_isOperation(_expression.last)) {
          _expression[_expression.length - 1] += number;
        } else {
          _input = _input.substring(0, min(_input.length, _cursorPosition!)) +
              number +
              _input.substring(min(_input.length, _cursorPosition!));
        }

        // Update the TextEditingController value with new cursor position
        _displayController.value = _displayController.value.copyWith(
          text: _display,
          selection: TextSelection.collapsed(offset: _cursorPosition!),
        );
      } else {
        _input += number;
        _display += number;
        _displayController.text = _display;
      }

      if (_originalExpression.isNotEmpty &&
          !_isOperation(_originalExpression.last)) {
        _originalExpression[_originalExpression.length - 1] += number;
      } else {
        _originalExpression.add(number);
      }

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
        _display = _display.substring(0, _display.length - 2) + operation + ' ';
        _originalExpression[_originalExpression.length - 1] = operation;
      } else {
        if (_input.isEmpty && _expression.isEmpty) {
          _expression.add(_display);
        } else if (_input.isNotEmpty) {
          _expression.add(_input);
        }
        _display += ' $operation ';
        _input = '';
      }
      _expression.add(operation);
      _displayController.text = _display;

      // Adjust the cursor position to the end after an operation
      _cursorPosition = _display.length;
      _manuallySetCursor =
          false; // Reset manual cursor positioning after an operation
    });
    _originalExpression.add(operation);
  }

  bool _isOperation(String char) => ['+', '-', 'X', '/', '%'].contains(char);

  bool isLastCharAnOperation() => _isOperation(_display.trim().split(" ").last);

  void _updateLiveResult() {
    if (_expression.length < 2) return;
    var evalExpression = List.from(_expression);

    if (_input.isNotEmpty) evalExpression.add(_input);

    double? result = _evaluateExpression(evalExpression);
    if (result == null) return;
    if (result == result.floor()) {
      _resultDisplay = result.toStringAsFixed(0);
    } else {
      _resultDisplay = result.toStringAsFixed(2);
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

  void _saveCalculation() async {
    String fullExpression;

    if (_originalExpression.isNotEmpty) {
      fullExpression = _originalExpression.join(' ');
    } else if (_input.isNotEmpty) {
      fullExpression = _input;
    } else {
      return; // Nothing to save
    }

    CalculationHistory calculation = CalculationHistory(
      id: 1,
      expression: fullExpression,
      result: _resultDisplay.isNotEmpty ? _resultDisplay : _input,
      date: DateTime.now(),
    );

    await DatabaseHelper.instance.insert(calculation);
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

  void _clear() {
    setState(() {
      _input = '';
      _display = '';
      _resultDisplay = '';
      _expression.clear();
      _error = '';
      _originalExpression.clear();
      _displayController.text = _display;
      _manuallySetCursor = false;
      _cursorPosition = null;
    });
  }

  void _removeLastCharacter() {
    if (_display.isEmpty) return;

    setState(() {
      if (_manuallySetCursor &&
          _cursorPosition != null &&
          _cursorPosition! > 0) {
        // Remove character at cursor position and adjust cursor
        _display = _display.substring(0, _cursorPosition! - 1) +
            _display.substring(_cursorPosition!);

        if (_cursorPosition! <= _input.length) {
          _input = _input.substring(0, _cursorPosition! - 1) +
              (_cursorPosition! < _input.length
                  ? _input.substring(_cursorPosition!)
                  : "");
        }

        _cursorPosition = _cursorPosition! - 1;
        _displayController.value = _displayController.value.copyWith(
          text: _display,
          selection: TextSelection.collapsed(offset: _cursorPosition!),
        );
      } else if (isLastCharAnOperation()) {
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

        if (_expression.isNotEmpty && !_isOperation(_expression.last)) {
          _expression[_expression.length - 1] = _input;
        }
      }
      _updateLiveResult();
      if (!_manuallySetCursor) {
        _displayController.text = _display;
      }
    });
  }

  void _applyPercentageToResult(double percentage) {
    if (_resultIsAvailable()) {
      double currentResult = double.parse(_resultDisplay);
      _netprice = currentResult.toStringAsFixed(2); // Capture the exact value

      double gstAmount = currentResult * (percentage / 100.0);
      double updatedResult;

      if (percentage > 0) {
        _originalExpression = [_netprice, "+", percentage.toString() + "%"];
        updatedResult = currentResult + gstAmount;
      } else {
        _originalExpression = [_netprice, "-", (-percentage).toString() + "%"];
        updatedResult = currentResult - gstAmount;
      }

      _resultDisplay = updatedResult.toStringAsFixed(2);
      _display = _resultDisplay;
      _displayController.text = _display;
      _percentageApplied = true;

      _saveCalculation(); // Save to database
      _navigateToGstResultScreen(percentage);
    } else if (_inputIsPresentAndValid()) {
      double currentValue = double.parse(_input);
      _netprice = currentValue.toStringAsFixed(2); // Capture the exact value

      double gstAmount = currentValue * (percentage / 100.0);
      double updatedValue;

      if (percentage > 0) {
        _originalExpression = [_netprice, "+", percentage.toString() + "%"];
        updatedValue = currentValue + gstAmount;
      } else {
        _originalExpression = [_netprice, "-", (-percentage).toString() + "%"];
        updatedValue = currentValue - gstAmount;
      }

      _input = updatedValue.toStringAsFixed(2);
      _display = _input;
      _displayController.text = _display;
      _percentageApplied = true;

      _saveCalculation(); // Save to database
      _navigateToGstResultScreen(percentage);
    } else {
      _showPercentageApplicationError();
    }
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

    print(_netprice);

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
    _originalExpression = List.from(_expression);
    if (_input.isNotEmpty) _originalExpression.add(_input);
    _performCalculation(); // Evaluate the current expression first
    _applyPercentageToResult(newPercentage);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double maxWidth = 600;
    double mainPadding = width < maxWidth ? 8.0 : 24.0;

    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[200],
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: _isDarkMode ? Colors.grey[900] : Colors.grey[200],
        title: Text(
          "GST Calculator",
          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
        ),
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
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
          ],
        ),
      ),
    );
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

  Widget _buildDarkModeToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_isDarkMode ? Icons.brightness_2 : Icons.brightness_7),
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay() {
    double screenWidth = MediaQuery.of(context).size.width * 1.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.bottomRight,
      child: Text(
        _resultDisplay,
        style: TextStyle(
          fontSize: getResponsiveTextSize(screenWidth),
          fontWeight: FontWeight.w400,
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildInputDisplay() {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      alignment: Alignment.bottomRight,
      child: TextField(
        showCursor: true,
        controller: _displayController,
        readOnly: true,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: getResponsiveTextSize(screenWidth),
          fontWeight: FontWeight.w500,
          color: _isDarkMode ? Colors.white : Colors.black,
        ),
        decoration: InputDecoration(border: InputBorder.none, hintText: "0"),
        cursorWidth: 2.0,
        cursorColor: const Color.fromARGB(255, 204, 9, 9),
        cursorRadius: Radius.circular(2.0),
        onTap: () {
          setState(() {
            _cursorPosition = _displayController.selection.start;
            _manuallySetCursor = true;
          });
        },
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
    double screenWidth = MediaQuery.of(context).size.width * 0.1;

    // Button colors for Dark Mode
    Color darkBackgroundColor = Colors.grey[800]!;
    Color darkForegroundColor = Colors.grey[300]!;

    // Button colors for Light Mode
    Color lightBackgroundColor = Colors.grey[200]!;
    Color lightForegroundColor = Colors.black;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(
              fontSize: getResponsiveTextSize(screenWidth),
              color: _isDarkMode ? darkForegroundColor : lightForegroundColor,
            ),
          ),
          style: ElevatedButton.styleFrom(
            side: BorderSide(
              color: _isDarkMode ? darkForegroundColor : Colors.grey[400]!,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(200),
            ),
            backgroundColor:
                _isDarkMode ? darkBackgroundColor : lightBackgroundColor,
            foregroundColor:
                _isDarkMode ? darkForegroundColor : lightForegroundColor,
            padding: EdgeInsets.all(
              getResponsiveButtonPadding(screenWidth),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Settings'),
          ),
          ListTile(
            title: Text('Dark Mode'),
            leading:
                Icon(_isDarkMode ? Icons.brightness_2 : Icons.brightness_7),
            trailing: Switch(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
          ),
          ListTile(
            title: Text('+1%'),
            onTap: () => _updateGSTPercentage(1.0),
          ),
          ListTile(
            title: Text('+5%'),
            onTap: () => _updateGSTPercentage(5.0),
          ),
          ListTile(
            title: Text('+12%'),
            onTap: () => _updateGSTPercentage(12.0),
          ),
          ListTile(
            title: Text('+18%'),
            onTap: () => _updateGSTPercentage(18.0),
          ),
        ],
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
