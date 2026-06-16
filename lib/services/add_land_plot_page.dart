import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/services/land_service.dart';
import 'package:uuid/uuid.dart';

class AddLandPlotPage extends StatefulWidget {
  const AddLandPlotPage({super.key});

  @override
  State<AddLandPlotPage> createState() => _AddLandPlotPageState();
}

class _AddLandPlotPageState extends State<AddLandPlotPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LandService _landService = LandService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Country _selectedCountry = Country.saudiArabia;
  bool _isFeatured = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final LandPlot newPlot = LandPlot(
      id: const Uuid().v4(),
      title: _titleController.text,
      description: _descriptionController.text,
      price: double.parse(_priceController.text),
      area: double.parse(_areaController.text),
      country: _selectedCountry,
      location: _locationController.text,
      imageUrls: const <String>[
        'https://via.placeholder.com/400x300.png?text=New+Listing',
      ],
      isFeatured: _isFeatured,
      createdAt: DateTime.now(),
    );

    try {
      await _landService.addLandPlot(newPlot);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Listing added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Land Plot',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildTextField(
                      _titleController,
                      'Title',
                      'Enter listing title',
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      _descriptionController,
                      'Description',
                      'Enter details',
                      maxLines: 4,
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildTextField(
                            _priceController,
                            'Price (SAR)',
                            '0.00',
                            isNumber: true,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _buildTextField(
                            _areaController,
                            'Area (m²)',
                            '0.00',
                            isNumber: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _buildTextField(
                      _locationController,
                      'Location',
                      'City, District',
                    ),
                    SizedBox(height: 16.h),
                    DropdownButtonFormField<Country>(
                      initialValue: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                      ),
                      items: Country.values
                          .map(
                            (Country c) =>
                                DropdownMenuItem(value: c, child: Text(c.name)),
                          )
                          .toList(),
                      onChanged: (Country? val) =>
                          setState(() => _selectedCountry = val!),
                    ),
                    SizedBox(height: 16.h),
                    SwitchListTile(
                      title: const Text('Featured Listing'),
                      subtitle: const Text(
                        'Increase visibility on the home screen',
                      ),
                      value: _isFeatured,
                      onChanged: (bool val) =>
                          setState(() => _isFeatured = val),
                    ),
                    SizedBox(height: 32.h),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Publish Listing',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      validator: (String? value) {
        if (value == null || value.isEmpty) return 'This field is required';
        if (isNumber && double.tryParse(value) == null)
          return 'Please enter a valid number';
        return null;
      },
    );
  }
}
