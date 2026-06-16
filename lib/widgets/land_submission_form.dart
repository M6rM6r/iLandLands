import 'package:flutter/material.dart';
import '../../../core/design_system.dart';
import '../../../core/validator.dart';
import '../../../core/haptic_engine.dart';

class LandSubmissionForm extends StatefulWidget {
  const LandSubmissionForm({super.key});

  @override
  State<LandSubmissionForm> createState() => _LandSubmissionFormState();
}

class _LandSubmissionFormState extends State<LandSubmissionForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _priceController = TextEditingController();

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await HapticEngine.triggerSuccess();
      // Execute API call via PHP backend
    } else {
      await HapticEngine.triggerError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Contact Email'),
            validator: AppValidators.combine([
              AppValidators.required,
              AppValidators.email,
            ]),
          ),
          SizedBox(height: tokens.spacingUnit * 2),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Listing Price (USD)'),
            keyboardType: TextInputType.number,
            validator: AppValidators.combine([
              AppValidators.required,
              AppValidators.numeric,
            ]),
          ),
          SizedBox(height: tokens.spacingUnit * 4),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: tokens.brandPrimary,
              padding: EdgeInsets.symmetric(
                vertical: tokens.spacingUnit * 2,
                horizontal: tokens.spacingUnit * 4,
              ),
            ),
            child: const Text('Submit Listing'),
          ),
        ],
      ),
    );
  }
}
