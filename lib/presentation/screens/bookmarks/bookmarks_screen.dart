import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/core/design_system.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/presentation/screens/detail/land_detail_screen.dart';
import 'package:gulflands/presentation/widgets/pressable.dart';

enum _BookmarkSort { dateAdded, priceAsc, priceDesc, areaAsc }

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  _BookmarkSort _sort = _BookmarkSort.dateAdded;

  List<LandPlot> _sorted(List<LandPlot> plots) {
    final list = List<LandPlot>.from(plots);
    switch (_sort) {
      case _BookmarkSort.dateAdded:
        return list;
      case _BookmarkSort.priceAsc:
        return list..sort((a, b) => a.price.compareTo(b.price));
      case _BookmarkSort.priceDesc:
        return list..sort((a, b) => b.price.compareTo(a.price));
      case _BookmarkSort.areaAsc:
        return list..sort((a, b) => a.area.compareTo(b.area));
    }
  }

  void _showSortSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortSheet(
        current: _sort,
        onSelect: (s) {
          setState(() => _sort = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Listings',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Plots you have bookmarked',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showSortSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.sort_rounded,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Sort',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.dividerColor),

            // ── List ──────────────────────────────────────────────────────
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
                    final raw = state.listings
                        .where((p) => state.favoriteIds.contains(p.id))
                        .toList();
                    final saved = _sorted(raw);

                    if (saved.isEmpty) {
                      return _EmptyBookmarks(
                        onBrowse: () {
                          // Pop back to Home tab via the Navigator
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          );
                        },
                      );
                    }

                    return AnimationLimiter(
                      child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: saved.length,
                      itemBuilder: (_, i) {
                        final plot = saved[i];
                        return AnimationConfiguration.staggeredList(
                          position: i,
                          duration: const Duration(milliseconds: 420),
                          child: SlideAnimation(
                            verticalOffset: 36,
                            child: FadeInAnimation(
                              child: Dismissible(
                          key: ValueKey<String>(plot.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  color: AppColors.error,
                                  size: 26,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Remove',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (_) async => true,
                          onDismissed: (_) {
                            HapticFeedback.mediumImpact();
                            context
                                .read<LandBloc>()
                                .add(ToggleFavorite(plot.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Removed from saved'),
                                backgroundColor: AppColors.cardBg,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: AppColors.gold,
                                  onPressed: () => context
                                      .read<LandBloc>()
                                      .add(ToggleFavorite(plot.id)),
                                ),
                              ),
                            );
                          },
                          child: _BookmarkCard(
                            plot: plot,
                            onRemove: () {
                              HapticFeedback.lightImpact();
                              context
                                  .read<LandBloc>()
                                  .add(ToggleFavorite(plot.id));
                            },
                          ),
                        ),
                            ),
                          ),
                        );
                      },
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
    );
  }
}

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({required this.plot, required this.onRemove});
  final LandPlot plot;
  final VoidCallback onRemove;

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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    plot.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: plot.imageUrls.first,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.cardBgLight,
                              child: const Icon(
                                Icons.landscape,
                                color: AppColors.textMuted,
                                size: 48,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.cardBgLight,
                            child: const Icon(
                              Icons.landscape,
                              color: AppColors.textMuted,
                              size: 48,
                            ),
                          ),
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
                    // Remove button
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: AppColors.gold,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    if (plot.isFeatured)
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
                            borderRadius: BorderRadius.circular(6),
                          ),
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
                  ],
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plot.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
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
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        plot.formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: AppColors.dividerColor),
                        ),
                        child: Text(
                          plot.formattedArea,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatefulWidget {
  const _EmptyBookmarks({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  State<_EmptyBookmarks> createState() => _EmptyBookmarksState();
}

class _EmptyBookmarksState extends State<_EmptyBookmarks>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5));
    _slide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.dividerColor),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.06),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bookmark_outline,
                  size: 48,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                children: [
                  Text(
                    'No saved listings yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bookmark plots you love to find them here',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: widget.onBrowse,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(
                        'Browse Listings',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

// ─── Sort sheet ───────────────────────────────────────────────────────────────
class _SortSheet extends StatelessWidget {
  const _SortSheet({required this.current, required this.onSelect});
  final _BookmarkSort current;
  final void Function(_BookmarkSort) onSelect;

  static const List<(_BookmarkSort, String, IconData)> _opts = [
    (_BookmarkSort.dateAdded, 'Date Saved', Icons.schedule_outlined),
    (_BookmarkSort.priceAsc, 'Price: Low → High', Icons.arrow_upward),
    (_BookmarkSort.priceDesc, 'Price: High → Low', Icons.arrow_downward),
    (_BookmarkSort.areaAsc, 'Area: Small → Large', Icons.straighten),
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
            child: Text(
              'Sort By',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._opts.map((opt) {
            final sel = current == opt.$1;
            return InkWell(
              onTap: () => onSelect(opt.$1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.gold.withValues(alpha: 0.15)
                            : AppColors.cardBgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        opt.$3,
                        size: 18,
                        color: sel ? AppColors.gold : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        opt.$2,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight:
                              sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check, color: AppColors.gold, size: 18),
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
