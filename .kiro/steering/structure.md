---
inclusion: always
---

# Project Structure

## Architecture Pattern

**Controller-Service-Model** with GetX for state management and routing.

```
lib/
├── bindings/          # GetX dependency injection bindings
├── controllers/       # Business logic and state management
├── models/           # Data models and entities
├── routes/           # Navigation routes and route definitions
├── services/         # API calls and external integrations
├── theme/            # App theming and styling
├── utils/            # Helpers, constants, validators, formatters
├── views/            # UI screens and widgets
│   ├── auth/         # Authentication screens
│   ├── dashboard/    # Role-specific dashboards
│   ├── home/         # Home screen
│   ├── onboarding/   # Initial onboarding flow
│   ├── profile/      # User profile management
│   └── property/     # Property management screens
└── widgets/          # Reusable UI components
```

## Key Conventions

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Private members: prefix with `_`
- Constants: `camelCase` or `SCREAMING_SNAKE_CASE` for static const

### Controllers
- Extend `GetxController`
- Named `*Controller` (e.g., `PropertyController`)
- Use `.obs` for reactive state
- Initialize in `onInit()`, cleanup in `onDispose()`
- Access via `Get.find<ControllerName>()` or `Get.put()`

### Services
- Singleton pattern with factory constructor
- Named `*Service` (e.g., `AuthService`, `PropertyService`)
- Handle all API communication
- Return `Map<String, dynamic>` or throw exceptions
- Use Dio for HTTP requests with Bearer token authentication

### Views
- Stateless widgets when possible
- Named `*View` (e.g., `PropertyListView`)
- Use `GetView<Controller>` for controller access
- Keep UI logic minimal - delegate to controllers

### Routes
- Defined in `lib/routes/app_routes.dart`
- Registered in `lib/routes/app_pages.dart`
- Navigate with `Get.toNamed()`, `Get.offNamed()`, `Get.offAllNamed()`
- Pass arguments via `Get.arguments`

### Models
- Plain Dart classes with `fromJson()` and `toJson()` methods
- Named descriptively (e.g., `PropertyModel`, `LandlordInfo`)
- Immutable when possible

### API Integration
- Base URL configured in `lib/utils/api_config.dart`
- Environment switching: `ApiConfig.setEnvironment(Environment.production)`
- Token stored securely via `flutter_secure_storage`
- All requests include `Authorization: Bearer <token>` header
- Handle `DioException` for network errors

### Offline Support
- Use Hive for local caching
- Cache API responses with TTL (typically 1 hour)
- Box names defined in constants (e.g., `HiveBoxes.variablesCache`)
- Initialize Hive in controller `onInit()`

### Form Handling
- Use `GlobalKey<FormState>` for validation
- Validators in `lib/utils/validation_utils.dart`
- Input formatters in `lib/utils/input_formatters.dart`
- Store form data in controller's reactive map

### Multi-step Wizards
- Track step with `RxInt step`
- Separate `GlobalKey<FormState>` per step
- Validate current step before advancing
- Merge all step data before submission

### Error Handling
- Use `ToastService` for user-facing messages
- Log errors with `Get.log()` or `print()` for debugging
- Throw custom exceptions (e.g., `AuthException`)
- Display loading states with `RxBool isLoading`

### Assets
- Images: `assets/images/`
- Icons: `assets/icons/`
- Reference in code: `'assets/images/logo_clear.png'`
- Declared in `pubspec.yaml` under `flutter.assets`

## File Organization Rules

- One class per file (except for small helper classes)
- Group related functionality in subdirectories
- Private widgets can be in same file as parent view (prefix with `_`)
- Keep files under 500 lines when possible
- Extract reusable widgets to `lib/widgets/`
