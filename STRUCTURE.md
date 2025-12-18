# Project Structure

```
fetch/
├── lib/
│   ├── fetch.dart                    # Main library entry point
│   └── src/
│       ├── core/                     # Core HTTP functionality
│       │   ├── helpers.dart          # Utility methods
│       │   ├── logger.dart           # Logging functionality
│       │   ├── payload.dart          # Request payload
│       │   └── response.dart         # Response wrapper
│       ├── features/                 # Feature modules
│       │   ├── cache.dart            # Caching system
│       │   ├── cancel.dart           # Request cancellation
│       │   ├── debounce.dart         # Request debouncing
│       │   ├── interceptor.dart      # Interceptor system
│       │   └── retry.dart            # Retry mechanism
│       └── utils/                    # Utilities
│           └── exception.dart        # Exception types
├── example/
│   ├── main.dart                     # Example usage
│   ├── pubspec.yaml                  # Example dependencies
│   └── README.md                     # Example documentation
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## Structure Benefits

### `/lib/src/core/` - Core HTTP Functionality
Core components that handle basic HTTP operations:
- **helpers.dart**: Header merging, type conversions
- **logger.dart**: Request/response logging
- **payload.dart**: Request configuration
- **response.dart**: Response wrapper with JSON parsing

### `/lib/src/features/` - Feature Modules
Modular features that can be independently used:
- **cache.dart**: Response caching with TTL
- **cancel.dart**: Request cancellation tokens
- **debounce.dart**: Prevent duplicate rapid requests
- **interceptor.dart**: Request/response middleware
- **retry.dart**: Automatic retry with backoff

### `/lib/src/utils/` - Shared Utilities
- **exception.dart**: Typed exception handling

### `/example/` - Standalone Examples
Separate example package demonstrating all features:
- Independent pubspec.yaml
- Can be run with `dart run example/main.dart`
- Clear, focused examples for each feature

## Import Usage

Users only need to import the main library:
```dart
import 'package:fetch/fetch.dart';
```

All internal files are private (in `src/`) and use `part`/`part of` directives.
