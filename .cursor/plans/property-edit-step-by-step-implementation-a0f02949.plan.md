<!-- a0f02949-f6bb-4553-b818-459861ac12e9 92a1dce4-79a6-48d4-b0a4-c5ab9ab17ca8 -->
# Property Forms Validation and Loading State Centralization

## Overview

Enhance all property forms (create wizard + 5 edit views) with comprehensive validation, proper input field types/formatters, and centralized loading state management.

## Files to Modify

### 1. Create Centralized Loading Service

- **File**: `lib/services/loading_service.dart` (new)
- Create a centralized loading service similar to `ToastService` that:
  - Shows/hides loading overlay using GetX overlay
  - Provides methods: `showLoading()`, `hideLoading()`, `isLoading`
  - Uses a consistent loading widget with optional message
  - Prevents multiple loading dialogs

### 2. Create Validation Utilities

- **File**: `lib/utils/validation_utils.dart` (new)
- Create reusable validation functions:
  - `validateRequired()` - Required field validation
  - `validateEmail()` - Email format validation
  - `validatePhone()` - Phone number validation (Sierra Leone format)
  - `validateLatLong()` - Coordinate validation
  - `validateNumber()` - Number validation with min/max
  - `validateDecimal()` - Decimal number validation
  - `validateLength()` - String length validation
  - `validateLengthGreaterThanBreadth()` - Business logic: length > breadth

### 3. Create Input Formatters

- **File**: `lib/utils/input_formatters.dart` (new)
- Create custom input formatters:
  - `PhoneNumberFormatter` - Format phone numbers as user types
  - `DecimalInputFormatter` - Limit decimal places
  - `IntegerInputFormatter` - Only allow integers
  - `CoordinateFormatter` - Format lat,long coordinates

### 4. Update Property Wizard View

- **File**: `lib/views/property/property_wizard_view.dart`
- Replace inline validation functions with `ValidationUtils`
- Add proper `keyboardType` and `inputFormatters` to all text fields
- Replace individual loading states with `LoadingService`
- Add business logic validation (e.g., length > breadth in assessment step)
- Ensure all required fields have validators
- Add `autovalidateMode: AutovalidateMode.onUserInteraction` consistently

### 5. Update Edit Landlord View

- **File**: `lib/views/property/edit_landlord_view.dart`
- Replace inline validators with `ValidationUtils`
- Add input formatters for phone numbers
- Replace `_isLoading` with `LoadingService`
- Add validation for organization fields when organization is selected
- Ensure consistent validation across all fields

### 6. Update Edit Property View

- **File**: `lib/views/property/edit_property_view.dart`
- Replace inline validators with `ValidationUtils`
- Add input formatters where appropriate
- Replace `_isLoading` with `LoadingService`
- Add validation for administrative fields (ward, constituency, etc.)

### 7. Update Edit Occupancy View

- **File**: `lib/views/property/edit_occupancy_view.dart`
- Replace inline validators with `ValidationUtils`
- Add phone number formatters
- Replace `_isLoading` with `LoadingService`
- Ensure occupancy type selection validation

### 8. Update Edit Geo View

- **File**: `lib/views/property/edit_geo_view.dart`
- Replace `_validateLatLong` with `ValidationUtils.validateLatLong`
- Add coordinate formatters
- Replace `_isLoading` with `LoadingService`
- Add validation for meter numbers
- Validate digital address format

### 9. Update Edit Assessment View

- **File**: `lib/views/property/edit_assessment_view.dart`
- Replace inline validators with `ValidationUtils`
- Add decimal formatters for length/breadth
- Add integer formatters for counts (mast, shop, compound house)
- Replace `_isLoading` with `LoadingService`
- Add business logic validation: length > breadth
- Validate that at least one category/type is selected

### 10. Update Property Controller

- **File**: `lib/controllers/property_controller.dart`
- Replace `isSubmitting` usage with `LoadingService` where appropriate
- Ensure consistent loading state during submission

## Implementation Details

### Loading Service Pattern

```dart
class LoadingService {
  static void showLoading({String? message});
  static void hideLoading();
  static bool get isLoading;
}
```

### Validation Utils Pattern

```dart
class ValidationUtils {
  static String? validateRequired(String? value, {String? fieldName});
  static String? validateEmail(String? value);
  static String? validatePhone(String? value);
  static String? validateLatLong(String? value);
  static String? validateNumber(String? value, {double? min, double? max});
  static String? validateDecimal(String? value, {int? decimalPlaces});
  static String? validateLengthGreaterThanBreadth(String? length, String? breadth);
}
```

### Input Formatters Pattern

```dart
class PhoneNumberFormatter extends TextInputFormatter { ... }
class DecimalInputFormatter extends TextInputFormatter { ... }
class IntegerInputFormatter extends TextInputFormatter { ... }
class CoordinateFormatter extends TextInputFormatter { ... }
```

## Validation Requirements by View

### Create Wizard & Edit Views:

1. **Landlord**: Required fields (name, mobile_1), email format, phone format
2. **Property**: Required category type, administrative fields validation
3. **Occupancy**: Required tenant name, phone format, at least one occupancy type
4. **Geo Registry**: Valid coordinates, meter number validation
5. **Assessment**: Required materials, length > breadth, at least one category/type, valid numbers

## Testing Checklist

- All required fields show validation errors
- Email/phone formats validated correctly
- Loading overlay appears during submission
- Input formatters work correctly
- Business logic validations (length > breadth) work
- Loading state doesn't block UI unnecessarily

### To-dos

- [ ] Create LoadingService in lib/services/loading_service.dart with showLoading, hideLoading, and isLoading methods using GetX overlay
- [ ] Create ValidationUtils in lib/utils/validation_utils.dart with all validation functions (required, email, phone, latLong, number, decimal, business logic)
- [ ] Create input formatters in lib/utils/input_formatters.dart (PhoneNumberFormatter, DecimalInputFormatter, IntegerInputFormatter, CoordinateFormatter)
- [ ] Update property_wizard_view.dart to use ValidationUtils, input formatters, and LoadingService
- [ ] Update edit_landlord_view.dart to use ValidationUtils, phone formatters, and LoadingService
- [ ] Update edit_property_view.dart to use ValidationUtils, input formatters, and LoadingService
- [ ] Update edit_occupancy_view.dart to use ValidationUtils, phone formatters, and LoadingService
- [ ] Update edit_geo_view.dart to use ValidationUtils, coordinate formatters, and LoadingService
- [ ] Update edit_assessment_view.dart to use ValidationUtils, decimal/integer formatters, business logic validation (length > breadth), and LoadingService
- [ ] Update property_controller.dart to use LoadingService for submission loading state