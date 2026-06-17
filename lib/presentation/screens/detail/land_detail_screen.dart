import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/presentation/screens/detail/inquiry_bottom_sheet.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:share_plus/share_plus.dart';

class LandDetailScreen extends StatefulWidget {
  const LandDetailScreen({super.key, required this.plot});
  final LandPlot plot;

  @override
  State<LandDetailScreen> createState() => _LandDetailScreenState();
}

class _LandDetailScreenState extends State<LandDetailScreen> {
  int _imageIndex = 0;
  bool _descExpanded = false;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  static const Map<Country, String> _flags = {
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

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text:
            '${widget.plot.title}\n${widget.plot.location}\n${widget.plot.formattedPrice}\n\nVia Gulf Lands app',
      ),
    );
  }

  void _showInquiry() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InquiryBottomSheet(plot: widget.plot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plot = widget.plot;
    final hasImages = plot.imageUrls.isNotEmpty;
    final imageHeight = MediaQuery.of(context).size.height * 0.42;

    return BlocBuilder<LandBloc, LandState>(
      builder: (context, state) {
        final isFavorite = state is LandStateLoaded &&
            state.favoriteIds.contains(plot.id);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.darkSurface,
            body: Stack(
              children: [
                // ── Scrollable content ────────────────────────────────────
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Hero image area ──────────────────────────────────
                    SliverToBoxAdapter(
                      child: Hero(
                        tag: 'plot-image-${plot.id}',
                        child: SizedBox(
                        height: imageHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Image / gallery
                            hasImages
                                ? PageView.builder(
                                    controller: _pageController,
                                    itemCount: plot.imageUrls.length,
                                    onPageChanged: (i) =>
                                        setState(() => _imageIndex = i),
                                    itemBuilder: (_, i) =>
                                        InteractiveViewer(
                                          minScale: 1.0,
                                          maxScale: 4.0,
                                          child: CachedNetworkImage(
                                            imageUrl: plot.imageUrls[i],
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.cardBgLight,
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                _PlaceholderHero(),
                                          ),
                                        ),
                                  )
                                : _PlaceholderHero(),
                            // Gradient overlay bottom
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.darkSurface,
                                  ],
                                  stops: [0.55, 1.0],
                                ),
                              ),
                            ),
                            // Gradient overlay top (for buttons)
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.5),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.3],
                                ),
                              ),
                            ),
                            // Top buttons
                            SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _CircleBtn(
                                      icon: Icons.arrow_back,
                                      onTap: () => Navigator.pop(context),
                                    ),
                                    Row(
                                      children: [
                                        _CircleBtn(
                                          icon: Icons.share_outlined,
                                          onTap: _share,
                                        ),
                                        const SizedBox(width: 10),
                                        _CircleBtn(
                                          icon: isFavorite
                                              ? Icons.bookmark
                                              : Icons.bookmark_outline,
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            context.read<LandBloc>().add(
                                              ToggleFavorite(plot.id),
                                            );
                                          },
                                          iconColor: isFavorite
                                              ? AppColors.gold
                                              : Colors.white,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Dot indicator
                            if (hasImages && plot.imageUrls.length > 1)
                              Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    plot.imageUrls.length,
                                    (i) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      width: i == _imageIndex ? 20 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: i == _imageIndex
                                            ? AppColors.gold
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                        borderRadius: BorderRadius.circular(3),
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

                    // ── Detail content ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Featured badge
                            if (plot.isFeatured)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        AppColors.gold.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  '★ FEATURED LISTING',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.gold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),

                            // Title
                            Text(
                              plot.title,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Location + map button
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: AppColors.gold,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    plot.location,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    MapsLauncher.launchQuery(
                                      '${plot.location} ${plot.countryDisplay}',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.gold.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.gold
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.map_outlined,
                                          size: 13,
                                          color: AppColors.gold,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Map',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Price
                            Text(
                              plot.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.gold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plot.formattedPricePerSqm,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Stats row
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.dividerColor,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _StatItem(
                                    icon: Icons.crop,
                                    label: 'Area',
                                    value: plot.formattedArea,
                                  ),
                                  _Divider(),
                                  _StatItem(
                                    icon: Icons.public,
                                    label: 'Country',
                                    value:
                                        '${_flags[plot.country] ?? ''} ${_countryNames[plot.country] ?? ''}',
                                  ),
                                  _Divider(),
                                  _StatItem(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Listed',
                                    value: _formatDate(plot.createdAt),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Text(
                              'About this listing',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 300),
                              crossFadeState: _descExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: Text(
                                plot.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.65,
                                ),
                              ),
                              secondChild: Text(
                                plot.description,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.65,
                                ),
                              ),
                            ),
                            if (plot.description.length > 120)
                              GestureDetector(
                                onTap: () => setState(
                                  () => _descExpanded = !_descExpanded,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    _descExpanded
                                        ? 'Show less'
                                        : 'Read more',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Key highlights
                            Text(
                              'Key Highlights',
                              style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _HighlightsList(plot: plot),
                            const SizedBox(height: 28),

                            // ── Similar listings ─────────────────────────
                            if (state is LandStateLoaded) ...[
                              Builder(
                                builder: (_) {
                                  final similar = state.listings
                                      .where((p) =>
                                          p.id != plot.id &&
                                          p.country == plot.country)
                                      .take(6)
                                      .toList();
                                  if (similar.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Similar Listings',
                                        style: GoogleFonts.poppins(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        height: 196,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          physics:
                                              const BouncingScrollPhysics(),
                                          itemCount: similar.length,
                                          itemBuilder: (_, i) =>
                                              _SimilarCard(
                                                plot: similar[i],
                                              ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Sticky bottom action bar ───────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      border: const Border(
                        top: BorderSide(color: AppColors.dividerColor),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Save button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context
                                .read<LandBloc>()
                                .add(ToggleFavorite(plot.id));
                          },
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: isFavorite
                                  ? AppColors.gold.withValues(alpha: 0.15)
                                  : AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isFavorite
                                    ? AppColors.gold
                                    : AppColors.dividerColor,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_outline,
                              color: isFavorite
                                  ? AppColors.gold
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Inquire button
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _showInquiry,
                              icon: const Icon(Icons.message_outlined, size: 18),
                              label: Text(
                                'Inquire Now',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _PlaceholderHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBgLight,
      child: const Center(
        child: Icon(Icons.landscape, size: 80, color: AppColors.textMuted),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.white,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.dividerColor,
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => LandDetailScreen(plot: plot),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dividerColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 110,
                width: double.infinity,
                child: plot.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: plot.imageUrls.first,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.cardBgLight,
                          child: const Icon(
                            Icons.landscape,
                            color: AppColors.textMuted,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.cardBgLight,
                        child: const Icon(
                          Icons.landscape,
                          color: AppColors.textMuted,
                          size: 32,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plot.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plot.formattedPrice,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightsList extends StatelessWidget {
  const _HighlightsList({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.straighten, 'Plot area: ${plot.formattedArea}'),
      (Icons.attach_money, 'Price/sqm: ${plot.formattedPricePerSqm}'),
      (Icons.location_city, 'Location: ${plot.location}'),
      if (plot.isFeatured) (Icons.star, 'Premium featured listing'),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.$1, color: AppColors.gold, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
