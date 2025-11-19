// lib/utils/input_formatters.dart

import 'package:flutter/services.dart';

/// Formatter for phone numbers (allows international format with country codes)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow backspace/deletion
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Remove all non-digit characters except + and spaces
    final cleaned = text.replaceAll(RegExp(r'[^\d+\s]'), '');

    // Max length: +XXX XXXXXXXXXX (15 digits + country code)
    if (cleaned.replaceAll(RegExp(r'[\s+]'), '').length > 15) {
      return oldValue;
    }

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

/// Formatter for decimal numbers with limited decimal places
class DecimalInputFormatter extends TextInputFormatter {
  final int decimalPlaces;

  DecimalInputFormatter({this.decimalPlaces = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) {
      return newValue;
    }

    // Allow backspace
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Check if it's a valid decimal number
    final regex = RegExp(r'^\d*\.?\d*$');
    if (!regex.hasMatch(text)) {
      return oldValue;
    }

    // Limit decimal places
    if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length == 2 && parts[1].length > decimalPlaces) {
        return oldValue;
      }
    }

    return newValue;
  }
}

/// Formatter for integers only
class IntegerInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) {
      return newValue;
    }

    // Allow backspace
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Only allow digits
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return newValue;
    }

    return oldValue;
  }
}

/// Formatter for latitude,longitude coordinates
class CoordinateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Allow empty
    if (text.isEmpty) {
      return newValue;
    }

    // Allow backspace
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Allow digits, negative sign, decimal point, and comma
    final regex = RegExp(r'^-?\d*\.?\d*,-?\d*\.?\d*$');
    if (!regex.hasMatch(text)) {
      return oldValue;
    }

    // Only allow one comma
    final commaCount = ','.allMatches(text).length;
    if (commaCount > 1) {
      return oldValue;
    }

    return newValue;
  }
}
