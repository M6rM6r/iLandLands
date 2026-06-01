import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/core/config/app_config.dart';

class AdvancedLandPlotCard extends StatefulWidget {

  const AdvancedLandPlotCard({
    required this.plot, super.key,
    this.onTap,
    this.onFavorite,
    this.onShare,
    this.onContact,
    this.showFavoriteButton = true,
    this.showShareButton = true,
    this.showContactButton = true,
    this.animation,
    this.index = 0,
  });
  final LandPlot plot;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onContact;
  final bool showFavoriteButton;
  final bool showShareButton;
  final bool showContactButton;
  final Animation<double>? animation;
  final int index;

  @override
  State<AdvancedLandPlotCard> createState() => _AdvancedLandPlotCardState();
}

class _AdvancedLandPlotCardState extends State<AdvancedLandPlotCard>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _favoriteController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _favoriteAnimation;
  late ConfettiController _confettiControllerInstance;
  
  bool _isFavorited = false;
  final bool _isLoading = false;
  bool _isHovered = false;
  double _imageOpacity = 0;

  @override
  void initState() {
    super.initState();
    
    _shimmerController = AnimationController(
      duration: AppConfig.defaultAnimationDuration,
      vsync: this,
    );
    
    _favoriteController = AnimationController(
      duration: AppConfig.fastAnimationDuration,
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: AppConfig.slowAnimationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.elasticOut,
    ));
    
    _favoriteAnimation = Tween<double>(
      begin: 1,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _favoriteController,
      curve: Curves.elasticOut,
    ));
    
    _confettiControllerInstance = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    
    _shimmerController.forward();
    
    // Simulate image loading
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _imageOpacity = 1.0);
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _favoriteController.dispose();
    _confettiController.dispose();
    _confettiControllerInstance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.staggeredList(
      position: widget.index,
      duration: AppConfig.defaultAnimationDuration,
      delay: Duration(milliseconds: widget.index * 100),
      child: SlideAnimation(
        verticalOffset: 50,
        child: FadeInAnimation(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppConfig.defaultPadding.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConfig.cardRadius.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                            blurRadius: _isHovered ? 20 : 10,
                            offset: Offset(0, _isHovered ? 8 : 4),
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface.withOpacity(0.95),
                          ],
                        ),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConfig.cardRadius.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImageSection(),
                            _buildContentSection(),
                            _buildActionSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main Image
        SizedBox(
          height: AppConfig.imageHeight.h,
          width: double.infinity,
          child: AnimatedOpacity(
            opacity: _imageOpacity,
            duration: AppConfig.defaultAnimationDuration,
            child: CachedNetworkImage(
              imageUrl: widget.plot.imageUrls.first,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 48.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Image not available',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              memCacheHeight: (AppConfig.imageHeight.h * 2).round(),
              memCacheWidth: (MediaQuery.of(context).size.width * 2).round(),
            ),
          ),
        ),
        
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
        ),
        
        // Featured Badge
        if (widget.plot.isFeatured)
          Positioned(
            top: 12.h,
            right: 12.w,
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16.sp,
                        color: Colors.white,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'FEATURED',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        // Price Badge
        Positioned(
          bottom: 12.h,
          left: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              widget.plot.formattedPrice,
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        // Loading Overlay
        if (_isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/animations/loading.json',
                  width: 80.w,
                  height: 80.h,
                ),
              ),
            ),
          ),
        
        // Confetti
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _confettiControllerInstance,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.1,
            colors: const [
              Colors.amber,
              Colors.blue,
              Colors.green,
              Colors.purple,
              Colors.red,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(AppConfig.defaultPadding.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.plot.title,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 8.h),
          
          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  '${widget.plot.location}, ${widget.plot.countryDisplay}',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.h),
          
          // Description
          Text(
            widget.plot.description,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 16.h),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                icon: Icons.square_foot,
                label: 'Area',
                value: widget.plot.formattedArea,
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.trending_up,
                label: 'Price/m²',
                value: 'SAR ${widget.plot.pricePerSquareMeter.toStringAsFixed(0)}',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.visibility,
                label: 'Views',
                value: '1.2k',
                color: Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: color,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConfig.defaultPadding.w,
        vertical: 12.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.showFavoriteButton)
            _buildActionButton(
              icon: _isFavorited ? Icons.favorite : Icons.favorite_border,
              label: 'Favorite',
              onTap: _handleFavorite,
              isActive: _isFavorited,
              color: Colors.red,
            ),
          
          if (widget.showShareButton)
            _buildActionButton(
              icon: Icons.share,
              label: 'Share',
              onTap: widget.onShare,
              color: Colors.blue,
            ),
          
          if (widget.showContactButton)
            _buildActionButton(
              icon: Icons.phone,
              label: 'Contact',
              onTap: widget.onContact,
              color: Colors.green,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required Color color, bool isActive = false,
  }) {
    return AnimatedBuilder(
      animation: isActive ? _favoriteAnimation : const AlwaysStoppedAnimation(1),
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _favoriteAnimation.value : 1.0,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isActive ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isActive ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 20.sp,
                    color: isActive ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: isActive ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Future<void> _handleFavorite() async {
    if (widget.onFavorite != null) {
      setState(() => _isFavorited = !_isFavorited);
      
      if (_isFavorited) {
        _favoriteController.forward();
        _confettiControllerInstance.play();
      } else {
        _favoriteController.reverse();
      }
      
      widget.onFavorite!();
      
      // Reset animation
      if (_isFavorited) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        _favoriteController.reverse();
      }
    }
  }
}
