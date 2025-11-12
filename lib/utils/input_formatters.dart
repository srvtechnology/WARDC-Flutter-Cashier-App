// lib/utils/input_formatters.dart

import 'package:flutter/services.dart';

/// Formatter for phone numbers (Sierra Leone format)
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    // Allow backspace
    if (text.length < oldValue.text.length) {
      return newValue;
    }

    // Remove all non-digit characters except +
    final digitsOnly = text.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If starts with +, allow +232 format
    if (digitsOnly.startsWith('+')) {
      if (digitsOnly.length > 13) {
        return oldValue; // Max length for +232XXXXXXXXX
      }
      // Ensure it starts with +232
      if (digitsOnly.length > 1 && !digitsOnly.startsWith('+232')) {
        if (digitsOnly.startsWith('+2')) {
          return oldValue; // Wait for more digits
        }
        // If it's just +, allow it
        if (digitsOnly == '+') {
          return TextEditingValue(
            text: digitsOnly,
            selection: TextSelection.collapsed(offset: digitsOnly.length),
          );
        }
        // If it doesn't start with +232, format as 0XXXXXXXXX
        final digits = digitsOnly.replaceAll('+', '');
        if (digits.isEmpty) return oldValue;
        if (digits.length > 10) return oldValue;
        return TextEditingValue(
          text: digits.startsWith('0') ? digits : '0$digits',
          selection: TextSelection.collapsed(offset: digits.startsWith('0') ? digits.length : digits.length + 1),
        );
      }
      return TextEditingValue(
        text: digitsOnly,
        selection: TextSelection.collapsed(offset: digitsOnly.length),
      );
    }

    // Format as 0XXXXXXXXX (max 10 digits)
    if (digitsOnly.length > 10) {
      return oldValue;
    }
    
    final formatted = digitsOnly.isEmpty ? '' : (digitsOnly.startsWith('0') ? digitsOnly : '0$digitsOnly');
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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

