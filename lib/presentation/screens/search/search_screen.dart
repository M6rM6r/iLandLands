import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';
import 'package:gulflands/presentation/screens/detail/land_detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Country? _selectedCountry;
  SortOption? _selectedSort;

  static const List<_SortOption> _sortOptions = [
    _SortOption('Newest', SortOption.newest),
    _SortOption('Price ↑', SortOption.priceAsc),
    _SortOption('Price ↓', SortOption.priceDesc),
    _SortOption('Area ↑', SortOption.areaAsc),
    _SortOption('Area ↓', SortOption.areaDesc),
  ];

  static const List<_CountryOption> _countries = [
    _CountryOption('All', null, '🌍'),
    _CountryOption('UAE', Country.uae, '🇦🇪'),
    _CountryOption('KSA', Country.saudiArabia, '🇸🇦'),
    _CountryOption('Qatar', Country.qatar, '🇶🇦'),
    _CountryOption('Kuwait', Country.kuwait, '🇰🇼'),
    _CountryOption('Bahrain', Country.bahrain, '🇧🇭'),
    _CountryOption('Oman', Country.oman, '🇴🇲'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      context.read<LandBloc>().add(const LoadLandListings());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    context.read<LandBloc>().add(
      LoadLandListings(
        country: _selectedCountry,
        sortBy: _selectedSort,
        searchQuery: query.trim(),
      ),
    );
  }

  void _onCountryChanged(Country? c) {
    setState(() => _selectedCountry = c);
    context.read<LandBloc>().add(
      LoadLandListings(
        country: c,
        sortBy: _selectedSort,
        searchQuery: _searchCtrl.text.trim(),
      ),
    );
  }

  void _onSortChanged(SortOption? s) {
    setState(() => _selectedSort = s);
    context.read<LandBloc>().add(
      LoadLandListings(
        country: _selectedCountry,
        sortBy: s,
        searchQuery: _searchCtrl.text.trim(),
      ),
    );
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
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.search,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _focusNode,
                                onChanged: _onSearch,
                                onSubmitted: _onSearch,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search by title, location…',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_searchCtrl.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  _onSearch('');
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Filters ──────────────────────────────────────────────────
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _countries.length,
                  itemBuilder: (_, i) {
                    final opt = _countries[i];
                    final sel = _selectedCountry == opt.country;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _onCountryChanged(opt.country);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.gold.withValues(alpha: 0.15)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                sel ? AppColors.gold : AppColors.dividerColor,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          '${opt.flag} ${opt.label}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel
                                ? AppColors.gold
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ── Sort row ─────────────────────────────────────────────────
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sortOptions.length,
                  itemBuilder: (_, i) {
                    final opt = _sortOptions[i];
                    final sel = _selectedSort == opt.value;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _onSortChanged(sel ? null : opt.value);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.gold.withValues(alpha: 0.1)
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                sel ? AppColors.gold : AppColors.dividerColor,
                          ),
                        ),
                        child: Text(
                          opt.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel
                                ? AppColors.gold
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ── Divider ──────────────────────────────────────────────────
              const Divider(height: 1, color: AppColors.dividerColor),

              // ── Results ──────────────────────────────────────────────────
              Expanded(
                child: BlocBuilder<LandBloc, LandState>(
                  builder: (context, state) {
                    if (state is LandStateLoading ||
                        state is LandStateInitial) {
                      return _SearchShimmer();
                    }
                    if (state is LandStateLoaded) {
                      if (state.listings.isEmpty) {
                        return _NoResults(query: _searchCtrl.text);
                      }
                      return _ResultsList(listings: state.listings);
                    }
                    if (state is LandStateError) {
                      return Center(
                        child: Text(
                          state.message,
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                          ),
                        ),
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.listings});
  final List<LandPlot> listings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: listings.length,
      itemBuilder: (_, i) => _SearchResultCard(plot: listings[i]),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LandDetailScreen(plot: plot)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 80,
                child: plot.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: plot.imageUrls.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.cardBgLight,
                          child: const Icon(
                            Icons.landscape,
                            color: AppColors.textMuted,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.cardBgLight,
                        child: const Icon(
                          Icons.landscape,
                          color: AppColors.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          plot.location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'AED ${plot.formattedPrice}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      Text(
                        plot.formattedArea,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.cardBg,
        highlightColor: AppColors.cardBgLight,
        child: Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 60,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'Start searching…' : 'No results for "$query"',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SortOption {
  const _SortOption(this.label, this.value);
  final String label;
  final SortOption value;
}

class _CountryOption {
  const _CountryOption(this.label, this.country, this.flag);
  final String label;
  final Country? country;
  final String flag;
}
