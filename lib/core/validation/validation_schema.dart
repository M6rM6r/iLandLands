import 'package:flutter/material.dart';

/// Validation result
class ValidationResult {
  const ValidationResult({
    this.isValid = true,
    this.error,
  });

  final bool isValid;
  final String? error;

  factory ValidationResult.error(String message) {
    return ValidationResult(
      isValid: false,
      error: message,
    );
  }

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }
}

/// Field validator function type
typedef FieldValidator<T> = ValidationResult? Function(T? value);

/// Validation schema inspired by Zod
class ValidationSchema<T> {
  ValidationSchema({
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.customValidator,
    this.errorMessage,
  });

  final bool required;
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final FieldValidator<T>? customValidator;
  final String? errorMessage;

  ValidationResult validate(T? value) {
    // Check required
    if (required) {
      if (value == null || (value is String && value.isEmpty)) {
        return ValidationResult.error(errorMessage ?? 'This field is required');
      }
    }

    if (value == null) {
      return ValidationResult.success();
    }

    // Check min length
    if (minLength != null && value is String) {
      if (value.length < minLength!) {
        return ValidationResult.error(
          errorMessage ?? 'Must be at least $minLength characters',
        );
      }
    }

    // Check max length
    if (maxLength != null && value is String) {
      if (value.length > maxLength!) {
        return ValidationResult.error(
          errorMessage ?? 'Must be at most $maxLength characters',
        );
      }
    }

    // Check pattern
    if (pattern != null && value is String) {
      if (!pattern!.hasMatch(value)) {
        return ValidationResult.error(errorMessage ?? 'Invalid format');
      }
    }

    // Custom validator
    if (customValidator != null) {
      final result = customValidator!(value);
      if (result != null && !result.isValid) {
        return result;
      }
    }

    return ValidationResult.success();
  }
}

/// Common validators
class Validators {
  static final ValidationSchema<String> email = ValidationSchema<String>(
    required: true,
    pattern: RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
    errorMessage: 'Please enter a valid email',
  );

  static final ValidationSchema<String> password = ValidationSchema<String>(
    required: true,
    minLength: 8,
    errorMessage: 'Password must be at least 8 characters',
  );

  static final ValidationSchema<String> name = ValidationSchema<String>(
    required: true,
    minLength: 2,
    errorMessage: 'Name must be at least 2 characters',
  );

  static final ValidationSchema<String> phone = ValidationSchema<String>(
    pattern: RegExp(r'^\+?[0-9]{10,15}$'),
    errorMessage: 'Please enter a valid phone number',
  );

  static ValidationSchema<String> confirmPassword(String password) {
    return ValidationSchema<String>(
      required: true,
      customValidator: (value) {
        if (value != password) {
          return ValidationResult.error('Passwords do not match');
        }
        return null;
      },
    );
  }

  static ValidationSchema<String> price() {
    return ValidationSchema<String>(
      pattern: RegExp(r'^\d+(\.\d{1,2})?$'),
      errorMessage: 'Please enter a valid price',
    );
  }

  static ValidationSchema<String> url() {
    return ValidationSchema<String>(
      pattern: RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      ),
      errorMessage: 'Please enter a valid URL',
    );
  }
}

/// Form field with validation
class ValidatedFormField extends StatefulWidget {
  const ValidatedFormField({
    super.key,
    required this.schema,
    required this.label,
    required this.onChanged,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.initialValue,
  });

  final ValidationSchema<String> schema;
  final String label;
  final void Function(String value) onChanged;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final String? initialValue;

  @override
  State<ValidatedFormField> createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField> {
  late final TextEditingController _controller;
  ValidationResult? _validationResult;
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_validate);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _validate() {
    if (!_touched) return;
    
    final result = widget.schema.validate(_controller.text);
    setState(() {
      _validationResult = result;
    });
    
    widget.onChanged(_controller.text);
  }

  void _onChanged(String value) {
    setState(() {
      _touched = true;
    });
    _validate();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _validationResult != null && !_validationResult!.isValid;

    return TextField(
      controller: _controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      onChanged: _onChanged,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(
          color: hasError ? Colors.red.shade400 : Colors.grey.shade400,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: widget.suffixIcon!,
                onPressed: widget.onSuffixIconPressed,
              )
            : null,
        errorText: hasError ? _validationResult?.error : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade400 : Colors.grey.shade700,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade400 : Colors.grey.shade700,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: hasError ? Colors.red.shade400 : const Color(0xFFFFD700),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
      ),
    );
  }
}
