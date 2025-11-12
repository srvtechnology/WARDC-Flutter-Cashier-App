// lib/utils/validation_utils.dart

class ValidationUtils {
  ValidationUtils._();

  /// Validate required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'Required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email is optional, only validate format if provided
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validate phone number (Sierra Leone format: +232XXXXXXXXX or 0XXXXXXXXX)
  static String? validatePhone(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final phoneRegex = RegExp(r'^(\+232|0)[0-9]{8,9}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number (e.g., +232XXXXXXXXX or 0XXXXXXXXX)';
    }
    return null;
  }

  /// Validate latitude and longitude coordinates
  static String? validateLatLong(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final String trimmed = value.trim();
    final List<String> parts = trimmed.split(',');
    if (parts.length != 2) {
      return 'Format: lat,long';
    }
    final double? lat = double.tryParse(parts[0].trim());
    final double? lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) {
      return 'Invalid coordinates';
    }
    if (lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }
    if (lng < -180 || lng > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }

  /// Validate number with optional min/max
  static String? validateNumber(String? value, {double? min, double? max, bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final double? number = double.tryParse(value.trim());
    if (number == null) {
      return 'Enter a valid number';
    }
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    if (max != null && number > max) {
      return 'Value must be at most $max';
    }
    return null;
  }

  /// Validate decimal number
  static String? validateDecimal(String? value, {int? decimalPlaces, bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final double? number = double.tryParse(value.trim());
    if (number == null) {
      return 'Enter a valid number';
    }
    if (decimalPlaces != null) {
      final parts = value.trim().split('.');
      if (parts.length == 2 && parts[1].length > decimalPlaces) {
        return 'Maximum $decimalPlaces decimal places allowed';
      }
    }
    return null;
  }

  /// Validate string length
  static String? validateLength(String? value, {int? minLength, int? maxLength, bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final length = value.trim().length;
    if (minLength != null && length < minLength) {
      return 'Minimum $minLength characters required';
    }
    if (maxLength != null && length > maxLength) {
      return 'Maximum $maxLength characters allowed';
    }
    return null;
  }

  /// Business logic: Validate that length is greater than breadth
  static String? validateLengthGreaterThanBreadth(String? length, String? breadth) {
    if (length == null || length.trim().isEmpty || breadth == null || breadth.trim().isEmpty) {
      return null; // Let required validation handle empty fields
    }
    final double? lengthValue = double.tryParse(length.trim());
    final double? breadthValue = double.tryParse(breadth.trim());
    if (lengthValue == null || breadthValue == null) {
      return null; // Let number validation handle invalid numbers
    }
    if (lengthValue <= breadthValue) {
      return 'Length must be greater than breadth';
    }
    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, {int? min, int? max, bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Required' : null;
    }
    final int? number = int.tryParse(value.trim());
    if (number == null) {
      return 'Enter a valid whole number';
    }
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    if (max != null && number > max) {
      return 'Value must be at most $max';
    }
    return null;
  }
}

