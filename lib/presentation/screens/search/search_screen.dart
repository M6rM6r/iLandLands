import 'dart:async';

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
import 'package:gulflands/presentation/widgets/pressable.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _debounce;
  List<String> _recentSearches = [];

  static const String _prefsKey = 'recent_searches';
  static const int _maxRecent = 8;

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
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      context.read<LandBloc>().add(const LoadLandListings());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = prefs.getStringList(_prefsKey) ?? [];
    });
  }

  Future<void> _saveSearch(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    list.remove(query.trim());
    list.insert(0, query.trim());
    if (list.length > _maxRecent) list.removeLast();
    await prefs.setStringList(_prefsKey, list);
    setState(() => _recentSearches = list);
  }

  Future<void> _clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    setState(() => _recentSearches = []);
  }

  void _onSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), () {
      context.read<LandBloc>().add(
        LoadLandListings(
          country: _selectedCountry,
          sortBy: _selectedSort,
          searchQuery: query.trim(),
        ),
      );
    });
  }

  void _submitSearch(String query) {
    _debounce?.cancel();
    final q = query.trim();
    if (q.isNotEmpty) _saveSearch(q);
    context.read<LandBloc>().add(
      LoadLandListings(
        country: _selectedCountry,
        sortBy: _selectedSort,
        searchQuery: q,
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
                                onSubmitted: _submitSearch,
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
                    if (state is LandStateLoading) {
                      return _SearchShimmer();
                    }
                    if (state is LandStateInitial &&
                        _searchCtrl.text.isEmpty &&
                        _recentSearches.isNotEmpty) {
                      return _RecentSearches(
                        searches: _recentSearches,
                        onSelect: (q) {
                          _searchCtrl.text = q;
                          _submitSearch(q);
                        },
                        onClear: _clearRecent,
                      );
                    }
                    if (state is LandStateLoaded) {
                      if (_searchCtrl.text.isEmpty &&
                          _recentSearches.isNotEmpty) {
                        return _RecentSearches(
                          searches: _recentSearches,
                          onSelect: (q) {
                            _searchCtrl.text = q;
                            _submitSearch(q);
                          },
                          onClear: _clearRecent,
                        );
                      }
                      if (state.listings.isEmpty) {
                        return _NoResults(
                          query: _searchCtrl.text,
                          onClear: () {
                            _searchCtrl.clear();
                            _submitSearch('');
                          },
                        );
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
                    if (_recentSearches.isNotEmpty) {
                      return _RecentSearches(
                        searches: _recentSearches,
                        onSelect: (q) {
                          _searchCtrl.text = q;
                          _submitSearch(q);
                        },
                        onClear: _clearRecent,
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
      itemBuilder: (_, i) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: 260 + i * 50),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - v)),
            child: child,
          ),
        ),
        child: _SearchResultCard(plot: listings[i]),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => LandDetailScreen(plot: plot)),
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
                        plot.formattedPrice,
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
  const _NoResults({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 38,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            query.isEmpty ? 'Start searching…' : 'No results for "$query"',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or filters',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Clear search'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Recent searches panel ────────────────────────────────────────────────────
class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.searches,
    required this.onSelect,
    required this.onClear,
  });
  final List<String> searches;
  final void Function(String) onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Recent Searches',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClear,
                child: Text(
                  'Clear all',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: searches.length,
            itemBuilder: (_, i) => InkWell(
              onTap: () => onSelect(searches[i]),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        searches[i],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.north_west,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
