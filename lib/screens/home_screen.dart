import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';
import 'package:gulflands/presentation/screens/detail/land_detail_screen.dart';
import 'package:gulflands/presentation/screens/search/search_screen.dart';
import 'package:gulflands/presentation/widgets/pressable.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Country? _selectedCountry;
  SortOption? _currentSort;
  bool _isGrid = false;

  static const List<_CountryChip> _countryChips = [
    _CountryChip(label: 'All', country: null, flag: '🌍'),
    _CountryChip(label: 'UAE', country: Country.uae, flag: '🇦🇪'),
    _CountryChip(label: 'KSA', country: Country.saudiArabia, flag: '🇸🇦'),
    _CountryChip(label: 'Qatar', country: Country.qatar, flag: '🇶🇦'),
    _CountryChip(label: 'Kuwait', country: Country.kuwait, flag: '🇰🇼'),
    _CountryChip(label: 'Bahrain', country: Country.bahrain, flag: '🇧🇭'),
    _CountryChip(label: 'Oman', country: Country.oman, flag: '🇴🇲'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<LandBloc>().add(const LoadLandListings());
  }

  void _selectCountry(Country? c) {
    setState(() => _selectedCountry = c);
    HapticFeedback.selectionClick();
    context.read<LandBloc>().add(FilterLandListings(c));
  }

  void _showSortSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return _SortBottomSheet(
          current: _currentSort,
          onSelect: (SortOption? opt) {
            setState(() => _currentSort = opt);
            Navigator.pop(ctx);
            context.read<LandBloc>().add(SortLandListings(opt));
          },
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    context.read<LandBloc>().add(const RefreshLandListings());
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName?.split(' ').first ?? 'Explorer';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.darkSurface,
        body: RefreshIndicator(
          color: AppColors.gold,
          backgroundColor: AppColors.cardBg,
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──────────────────────────────────────────────────
              SliverToBoxAdapter(child: _Header(displayName: displayName)),

              // ── Search bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _SearchBar(
                  onTap: () async {
                    await Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SearchScreen(),
                      ),
                    );
                    if (mounted) {
                      context
                          .read<LandBloc>()
                          .add(FilterLandListings(_selectedCountry));
                    }
                  },
                ),
              ),

              // ── Featured carousel ────────────────────────────────────────
              const SliverToBoxAdapter(child: _FeaturedSection()),

              // ── Country chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _CountryFilter(
                  chips: _countryChips,
                  selected: _selectedCountry,
                  onSelect: _selectCountry,
                ),
              ),

              // ── Section title + controls ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                  child: Row(
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          'All Listings',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      BlocBuilder<LandBloc, LandState>(
                        builder: (_, s) {
                          final count = s is LandStateLoaded
                              ? s.listings.length
                              : 0;
                          return Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              '$count plots',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      _ControlBtn(
                        icon: Icons.sort_rounded,
                        active: _currentSort != null,
                        onTap: _showSortSheet,
                      ),
                      const SizedBox(width: 4),
                      _ControlBtn(
                        icon: _isGrid
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        active: false,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isGrid = !_isGrid);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Listings ─────────────────────────────────────────────────
              BlocBuilder<LandBloc, LandState>(
                builder: (context, state) {
                  if (state is LandStateLoading || state is LandStateInitial) {
                    return _ShimmerList();
                  }
                  if (state is LandStateLoaded) {
                    if (state.listings.isEmpty) {
                      return const SliverToBoxAdapter(child: _EmptyState());
                    }
                    if (_isGrid) {
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _GridCard(
                              plot: state.listings[index],
                              isFavorite: state.favoriteIds
                                  .contains(state.listings[index].id),
                              onFavorite: () => context
                                  .read<LandBloc>()
                                  .add(
                                    ToggleFavorite(state.listings[index].id),
                                  ),
                            ),
                            childCount: state.listings.length,
                          ),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 450),
                                child: SlideAnimation(
                                  verticalOffset: 40,
                                  child: FadeInAnimation(
                                    child: _ListingCard(
                                      plot: state.listings[index],
                                      isFavorite: state.favoriteIds
                                          .contains(state.listings[index].id),
                                      onFavorite: () => context
                                          .read<LandBloc>()
                                          .add(
                                            ToggleFavorite(
                                              state.listings[index].id,
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                          childCount: state.listings.length,
                        ),
                      ),
                    );
                  }
                  if (state is LandStateError) {
                    return SliverToBoxAdapter(
                      child: _ErrorState(message: state.message),
                    );
                  }
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.displayName});
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navyDeep, AppColors.darkSurface],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  'Welcome back,',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardBg,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.landscape,
              color: AppColors.gold,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(
                'Search plots, location, country…',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: AppColors.gold, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Featured Section ─────────────────────────────────────────────────────────
class _FeaturedSection extends StatelessWidget {
  const _FeaturedSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandBloc, LandState>(
      builder: (context, state) {
        final featured = state is LandStateLoaded
            ? state.listings.where((p) => p.isFeatured).take(5).toList()
            : <LandPlot>[];

        if (featured.isEmpty && state is! LandStateLoaded) {
          return _FeaturedShimmer();
        }
        if (featured.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'Featured Listings',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${featured.length}',
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
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 16, right: 8),
                itemCount: featured.length,
                itemBuilder: (_, i) => _FeaturedCard(plot: featured[i]),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LandDetailScreen(plot: plot),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Hero(
          tag: 'plot-image-${plot.id}',
          child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              plot.imageUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: plot.imageUrls.first,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.cardBgLight,
                      ),
                      errorWidget: (_, __, ___) => _PlaceholderImage(),
                    )
                  : _PlaceholderImage(),
              // Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.navyDeep],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              // Content
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            plot.location,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plot.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              // Featured badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '★ FEATURED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _FeaturedShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 268,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        itemCount: 3,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.cardBg,
          highlightColor: AppColors.cardBgLight,
          child: Container(
            width: 240,
            height: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Country Filter ───────────────────────────────────────────────────────────
class _CountryFilter extends StatelessWidget {
  const _CountryFilter({
    required this.chips,
    required this.selected,
    required this.onSelect,
  });
  final List<_CountryChip> chips;
  final Country? selected;
  final void Function(Country?) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final chip = chips[i];
          final isSelected = selected == chip.country;
          return GestureDetector(
            onTap: () => onSelect(chip.country),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.dividerColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(chip.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      chip.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.gold
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Listing Card ─────────────────────────────────────────────────────────────
class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.plot,
    required this.isFavorite,
    required this.onFavorite,
  });
  final LandPlot plot;
  final bool isFavorite;
  final VoidCallback onFavorite;

  static const Map<Country, String> _flags = {
    Country.uae: '🇦🇪',
    Country.saudiArabia: '🇸🇦',
    Country.qatar: '🇶🇦',
    Country.kuwait: '🇰🇼',
    Country.bahrain: '🇧🇭',
    Country.oman: '🇴🇲',
  };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LandDetailScreen(plot: plot),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 0.05);
              const end = Offset.zero;
              const curve = Curves.easeOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // ── Image ────────────────────────────────────────────────────
              Hero(
                tag: 'plot-image-${plot.id}',
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: plot.imageUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: plot.imageUrls.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: AppColors.cardBgLight,
                            highlightColor: AppColors.cardBg,
                            child: Container(color: AppColors.cardBgLight),
                          ),
                          errorWidget: (_, __, ___) => _PlaceholderImage(),
                        )
                      : _PlaceholderImage(),
                ),
              ),

              // ── Info ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _flags[plot.country] ?? '🌍',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plot.title,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              plot.location,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Stats chips
                      Row(
                        children: [
                          _Chip(label: plot.formattedArea, icon: Icons.crop),
                          const SizedBox(width: 6),
                          if (plot.isFeatured)
                            _Chip(label: '★ Featured', gold: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plot.formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Favorite btn ─────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onFavorite();
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFavorite ? Icons.bookmark : Icons.bookmark_outline,
                      key: ValueKey(isFavorite),
                      color: isFavorite ? AppColors.gold : AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer List ─────────────────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => Shimmer.fromColors(
            baseColor: AppColors.cardBg,
            highlightColor: AppColors.cardBgLight,
            child: Container(
              height: 110,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          childCount: 6,
        ),
      ),
    );
  }
}

// ─── Empty / Error States ─────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.gold.withValues(alpha: 0.1),
                          AppColors.navyDeep.withValues(alpha: 0.3),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 56,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'No listings found',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      'Try adjusting your filter',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // Reset filter would go here
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                      foregroundColor: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load listings',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBgLight,
      child: const Center(
        child: Icon(Icons.landscape, color: AppColors.textMuted, size: 32),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon, this.gold = false});
  final String label;
  final IconData? icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: gold
            ? AppColors.gold.withValues(alpha: 0.15)
            : AppColors.cardBgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: gold ? AppColors.gold.withValues(alpha: 0.3) : AppColors.dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: gold ? AppColors.gold : AppColors.textMuted),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: gold ? AppColors.gold : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryChip {
  const _CountryChip({
    required this.label,
    required this.country,
    required this.flag,
  });
  final String label;
  final Country? country;
  final String flag;
}

// ─── Control button (sort / grid toggle) ─────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.gold.withValues(alpha: 0.5)
                : AppColors.dividerColor,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: active ? AppColors.gold : AppColors.textMuted,
        ),
      ),
    );
  }
}

// ─── Grid card ────────────────────────────────────────────────────────────────
class _GridCard extends StatelessWidget {
  const _GridCard({
    required this.plot,
    required this.isFavorite,
    required this.onFavorite,
  });
  final LandPlot plot;
  final bool isFavorite;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => LandDetailScreen(plot: plot),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    plot.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: plot.imageUrls.first,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _PlaceholderImage(),
                          )
                        : _PlaceholderImage(),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, AppColors.navyDeep],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                    // Price chip bottom-left
                    Positioned(
                      bottom: 6,
                      left: 8,
                      child: Text(
                        plot.formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                    // Bookmark icon top-right
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onFavorite();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            size: 14,
                            color: isFavorite
                                ? AppColors.gold
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (plot.isFeatured)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '★',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.crop,
                          size: 10,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          plot.formattedArea,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sort bottom sheet ────────────────────────────────────────────────────────
class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet({required this.current, required this.onSelect});
  final SortOption? current;
  final void Function(SortOption?) onSelect;

  static const List<(SortOption?, String, IconData)> _options = [
    (null, 'Default', Icons.auto_awesome_outlined),
    (SortOption.newest, 'Newest First', Icons.schedule_outlined),
    (SortOption.priceAsc, 'Price: Low → High', Icons.arrow_upward),
    (SortOption.priceDesc, 'Price: High → Low', Icons.arrow_downward),
    (SortOption.areaAsc, 'Area: Small → Large', Icons.straighten),
    (SortOption.areaDesc, 'Area: Large → Small', Icons.straighten),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Sort By',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ..._options.map((opt) {
            final isSelected = current == opt.$1;
            return InkWell(
              onTap: () => onSelect(opt.$1),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        opt.$3,
                        size: 18,
                        color:
                            isSelected ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt.$2,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: AppColors.gold,
                        size: 18,
                      ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }
}
