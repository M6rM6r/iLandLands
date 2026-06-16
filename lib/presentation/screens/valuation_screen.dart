import 'package:flutter/material.dart';
import 'package:gulflands/core/services/valuation_service.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:intl/intl.dart';

class ValuationScreen extends StatefulWidget {
  const ValuationScreen({super.key});

  @override
  State<ValuationScreen> createState() => _ValuationScreenState();
}

class _ValuationScreenState extends State<ValuationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ValuationService _valuationService = ValuationService();

  Country _country = Country.saudiArabia;
  String _zoning = 'residential';
  String _city = 'Riyadh';
  final TextEditingController _areaController = TextEditingController(
    text: '10000',
  );
  final TextEditingController _coastalController = TextEditingController(
    text: '5',
  );

  ValuationResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _areaController.dispose();
    _coastalController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final ValuationResult result = await _valuationService.estimate(
      country: _country,
      areaSqm: double.parse(_areaController.text),
      coastalDistanceKm: double.parse(_coastalController.text),
      zoning: _zoning,
      city: _city,
    );

    if (mounted) {
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final NumberFormat currency = NumberFormat.currency(symbol: '');

    return Scaffold(
      appBar: AppBar(title: const Text('Land Valuation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<Country>(
                initialValue: _country,
                decoration: const InputDecoration(labelText: 'Country'),
                items: Country.values
                    .map(
                      (Country c) =>
                          DropdownMenuItem(value: c, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (Country? v) => setState(() => _country = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _zoning,
                decoration: const InputDecoration(labelText: 'Zoning'),
                items:
                    const <String>[
                          'residential',
                          'commercial',
                          'mixed-use',
                          'tourism',
                          'industrial',
                          'agricultural',
                        ]
                        .map(
                          (String z) =>
                              DropdownMenuItem(value: z, child: Text(z)),
                        )
                        .toList(),
                onChanged: (String? v) => setState(() => _zoning = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'City'),
                onChanged: (String v) => _city = v.isEmpty ? 'default' : v,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area (sqm)',
                  suffixText: 'm²',
                ),
                keyboardType: TextInputType.number,
                validator: (String? v) =>
                    v == null || double.tryParse(v) == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _coastalController,
                decoration: const InputDecoration(
                  labelText: 'Coastal distance',
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                validator: (String? v) =>
                    v == null || double.tryParse(v) == null ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _estimate,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Calculate'),
              ),
              if (_result != null) ...<Widget>[
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Estimated Value',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_result!.currency} ${currency.format(_result!.estimatedValue)}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Source: ${_result!.source}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (_result!.formula != null)
                          Text(
                            _result!.formula!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
