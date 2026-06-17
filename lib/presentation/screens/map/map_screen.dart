import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/presentation/screens/detail/land_detail_screen.dart';
import 'package:maps_launcher/maps_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  LandPlot? _selected;
  Country? _filterCountry;
  late AnimationController _previewCtrl;
  late Animation<Offset> _previewSlide;
  late Animation<double> _previewFade;

  static const Map<Country, Map<String, double>> _countryCoords = {
    Country.uae: {'lat': 24.4539, 'lng': 54.3773},
    Country.saudiArabia: {'lat': 24.7136, 'lng': 46.6753},
    Country.qatar: {'lat': 25.2854, 'lng': 51.5310},
    Country.kuwait: {'lat': 29.3759, 'lng': 47.9774},
    Country.bahrain: {'lat': 26.0667, 'lng': 50.5577},
    Country.oman: {'lat': 23.5880, 'lng': 58.3829},
  };

  static const Map<Country, String> _flags = {
    Country.uae: '🇦🇪',
    Country.saudiArabia: '🇸🇦',
    Country.qatar: '🇶🇦',
    Country.kuwait: '🇰🇼',
    Country.bahrain: '🇧🇭',
    Country.oman: '🇴🇲',
  };

  @override
  void initState() {
    super.initState();
    _previewCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _previewSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _previewCtrl, curve: Curves.easeOut));
    _previewFade = CurvedAnimation(parent: _previewCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _previewCtrl.dispose();
    super.dispose();
  }

  void _selectPlot(LandPlot p) {
    setState(() => _selected = p);
    _previewCtrl.forward(from: 0);
  }

  void _dismissPreview() {
    _previewCtrl.reverse().then((_) {
      if (mounted) setState(() => _selected = null);
    });
  }

  void _openInMaps(LandPlot plot) {
    final coords = _countryCoords[plot.country];
    if (coords != null) {
      MapsLauncher.launchCoordinates(
        coords['lat']!,
        coords['lng']!,
        plot.title,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Map View',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Country filter chips ─────────────────────────────────────
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: '🌍 All',
                      selected: _filterCountry == null,
                      onTap: () => setState(() => _filterCountry = null),
                    ),
                    ...Country.values.map(
                      (c) => _FilterChip(
                        label: '${_flags[c] ?? ''} ${_countryName(c)}',
                        selected: _filterCountry == c,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _filterCountry = c);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.dividerColor),

              // ── Listing pins list ─────────────────────────────────────────
              Expanded(
                child: BlocBuilder<LandBloc, LandState>(
                  builder: (context, state) {
                    if (state is LandStateLoading ||
                        state is LandStateInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gold,
                          strokeWidth: 2,
                        ),
                      );
                    }

                    if (state is LandStateLoaded) {
                      final allPlots = _filterCountry == null
                          ? state.listings
                          : state.listings
                              .where((p) => p.country == _filterCountry)
                              .toList();

                      if (allPlots.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                color: AppColors.textMuted,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No listings in this region',
                                style: GoogleFonts.inter(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Group by country
                      final Map<Country, List<LandPlot>> grouped = {};
                      for (final p in allPlots) {
                        grouped.putIfAbsent(p.country, () => []).add(p);
                      }

                      return Stack(
                        children: [
                          ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                            itemCount: grouped.length,
                            itemBuilder: (_, i) {
                              final country = grouped.keys.elementAt(i);
                              final countryPlots = grouped[country]!;
                              return _CountrySection(
                                country: country,
                                plots: countryPlots,
                                flag: _flags[country] ?? '🌍',
                                onPlotTap: (p) {
                                  HapticFeedback.lightImpact();
                                  _selectPlot(p);
                                },
                              );
                            },
                          ),

                          // Animated selected plot preview
                          if (_selected != null)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: SlideTransition(
                                position: _previewSlide,
                                child: FadeTransition(
                                  opacity: _previewFade,
                                  child: _SelectedPreview(
                                    plot: _selected!,
                                    onClose: _dismissPreview,
                                    onOpenMap: () =>
                                        _openInMaps(_selected!),
                                    onDetail: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => LandDetailScreen(
                                            plot: _selected!,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _countryName(Country c) {
  switch (c) {
    case Country.uae: return 'UAE';
    case Country.saudiArabia: return 'KSA';
    case Country.qatar: return 'Qatar';
    case Country.kuwait: return 'Kuwait';
    case Country.bahrain: return 'Bahrain';
    case Country.oman: return 'Oman';
  }
}

// ─── Filter chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CountrySection extends StatelessWidget {
  const _CountrySection({
    required this.country,
    required this.plots,
    required this.flag,
    required this.onPlotTap,
  });
  final Country country;
  final List<LandPlot> plots;
  final String flag;
  final void Function(LandPlot) onPlotTap;

  static const Map<Country, String> _names = {
    Country.uae: 'UAE',
    Country.saudiArabia: 'Saudi Arabia',
    Country.qatar: 'Qatar',
    Country.kuwait: 'Kuwait',
    Country.bahrain: 'Bahrain',
    Country.oman: 'Oman',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                _names[country] ?? 'Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${plots.length}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...plots.map(
          (p) => GestureDetector(
            onTap: () => onPlotTap(p),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dividerColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          p.location,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p.formattedPrice,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SelectedPreview extends StatelessWidget {
  const _SelectedPreview({
    required this.plot,
    required this.onClose,
    required this.onOpenMap,
    required this.onDetail,
  });
  final LandPlot plot;
  final VoidCallback onClose;
  final VoidCallback onOpenMap;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plot.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            plot.location,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                plot.formattedPrice,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onOpenMap,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Open Map'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onDetail,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
