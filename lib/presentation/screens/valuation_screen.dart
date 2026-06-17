import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/core/services/valuation_service.dart';
import 'package:gulflands/models/land_plot.dart';

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

  static const Map<Country, String> _countryFlags = {
    Country.uae: '🇦🇪',
    Country.saudiArabia: '🇸🇦',
    Country.qatar: '🇶🇦',
    Country.kuwait: '🇰🇼',
    Country.bahrain: '🇧🇭',
    Country.oman: '🇴🇲',
  };

  static const Map<Country, String> _countryNames = {
    Country.uae: 'UAE',
    Country.saudiArabia: 'Saudi Arabia',
    Country.qatar: 'Qatar',
    Country.kuwait: 'Kuwait',
    Country.bahrain: 'Bahrain',
    Country.oman: 'Oman',
  };

  static const Map<String, String> _zoningLabels = {
    'residential': 'Residential',
    'commercial': 'Commercial',
    'mixed-use': 'Mixed Use',
    'tourism': 'Tourism',
    'industrial': 'Industrial',
    'agricultural': 'Agricultural',
  };

  @override
  void dispose() {
    _areaController.dispose();
    _coastalController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
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
      HapticFeedback.mediumImpact();
      setState(() {
        _result = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 16,
                  20,
                  24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navyDeep, AppColors.darkSurface],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.calculate_outlined,
                            color: AppColors.gold,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Land Valuation',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              'Instant AI-powered estimates',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Form ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Country
                      _SectionLabel('Country'),
                      DropdownButtonFormField<Country>(
                        value: _country,
                        dropdownColor: AppColors.cardBg,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        items: Country.values.map((Country c) {
                          return DropdownMenuItem<Country>(
                            value: c,
                            child: Text(
                              '${_countryFlags[c]} ${_countryNames[c]}',
                            ),
                          );
                        }).toList(),
                        onChanged: (Country? v) =>
                            setState(() => _country = v!),
                      ),
                      const SizedBox(height: 16),

                      // Zoning
                      _SectionLabel('Zoning Type'),
                      DropdownButtonFormField<String>(
                        value: _zoning,
                        dropdownColor: AppColors.cardBg,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        items: _zoningLabels.entries.map((MapEntry<String, String> e) {
                          return DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value),
                          );
                        }).toList(),
                        onChanged: (String? v) => setState(() => _zoning = v!),
                      ),
                      const SizedBox(height: 16),

                      // City
                      _SectionLabel('City'),
                      TextFormField(
                        initialValue: _city,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'City / District',
                          prefixIcon: const Icon(
                            Icons.location_city_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        onChanged: (String v) =>
                            _city = v.isEmpty ? 'default' : v,
                      ),
                      const SizedBox(height: 16),

                      // Area
                      _SectionLabel('Plot Area'),
                      TextFormField(
                        controller: _areaController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Area',
                          suffixText: 'm²',
                          prefixIcon: const Icon(
                            Icons.crop_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        validator: (String? v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Enter a valid number'
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Coastal distance
                      _SectionLabel('Coastal Distance'),
                      TextFormField(
                        controller: _coastalController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Distance from coast',
                          suffixText: 'km',
                          prefixIcon: const Icon(
                            Icons.water_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                        ),
                        validator: (String? v) =>
                            v == null || double.tryParse(v) == null
                                ? 'Enter a valid number'
                                : null,
                      ),
                      const SizedBox(height: 28),

                      // Calculate button
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _estimate,
                          icon: _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navy,
                                  ),
                                )
                              : const Icon(Icons.auto_graph, size: 20),
                          label: Text(
                            _loading ? 'Calculating…' : 'Calculate Value',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // ── Result card ────────────────────────────────────────
                      if (_result != null) ...[
                        const SizedBox(height: 28),
                        _ResultCard(
                          result: _result!,
                          areaSqm:
                              double.tryParse(_areaController.text) ?? 1,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting Widgets ──────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.areaSqm});
  final ValuationResult result;
  final double areaSqm;

  String _formatValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(2)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: result.estimatedValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOut,
      builder: (BuildContext context, double value, Widget? child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.12),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '★ ESTIMATED VALUE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${result.currency} ${_formatValue(value)}',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.gold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                areaSqm > 0 ? '${result.currency} ${(value / areaSqm).toStringAsFixed(0)}/sqm est.' : '',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: AppColors.dividerColor),
              ),
              _InfoRow(
                icon: Icons.source_outlined,
                label: 'Source',
                value: result.source == 'local-engine'
                    ? 'Local Engine'
                    : 'Live Backend',
              ),
              if (result.formula != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.functions,
                  label: 'Formula',
                  value: result.formula!,
                  mono: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: mono
                ? GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  )
                : GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ),
      ],
    );
  }
}
