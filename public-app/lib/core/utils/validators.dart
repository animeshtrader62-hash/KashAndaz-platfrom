/// Input validation utilities
class Validators {
  /// Validate email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }

  /// Validate password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  /// Validate name
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    return null;
  }

  /// Validate phone number (Indian format)
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^[6-9]\d{9}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    
    return null;
  }

  /// Required field validation
  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
