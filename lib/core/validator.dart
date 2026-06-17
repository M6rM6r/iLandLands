typedef FieldValidator = String? Function(String?);

class AppValidators {
  AppValidators._();

  static FieldValidator combine(List<FieldValidator> validators) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) return 'Field is mandatory';
    return null;
  }

  static FieldValidator minLength(int min) {
    return (String? value) {
      if (value != null && value.length < min) {
        return 'Minimum $min characters required';
      }
      return null;
    };
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(value);
    if (!emailValid) return 'Enter a valid email address';
    return null;
  }

  static String? numeric(String? value) {
    if (value == null || value.isEmpty) return null;
    final bool isNumeric = double.tryParse(value) != null;
    if (!isNumeric) {
      return 'Value must be a number';
    }
    return null;
  }
}
