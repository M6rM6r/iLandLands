import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/services/land_repository.dart';
import 'package:gulflands/widgets/advanced_search_bar.dart';
import 'package:gulflands/widgets/land_plot_card.dart';
import 'package:shimmer/shimmer.dart';

// HomeScreen is the primary view for displaying and filtering land listings.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LandBloc(
        repository: context.read<LandRepository>(),
      )..add(const LoadLandListings()),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatefulWidget {
  const _HomeScreenContent();

  @override
  State<_HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<_HomeScreenContent> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _precachedImages = {};

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _precacheImages(List<LandPlot> listings) {
    for (final plot in listings) {
      final imageUrl = plot.imageUrls.first;
      if (!_precachedImages.contains(imageUrl)) {
        precacheImage(NetworkImage(imageUrl), context);
        _precachedImages.add(imageUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gulf Lands Market'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LandBloc>().add(const RefreshLandListings());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Advanced Search Bar
          BlocBuilder<LandBloc, LandState>(
            builder: (context, state) {
              return AdvancedSearchBar(
                onSearchChanged: (query) {
                  context.read<LandBloc>().add(SearchLandListings(query));
                },
                onCountryFilterChanged: (country) {
                  context.read<LandBloc>().add(FilterLandListings(country));
                },
                onSortChanged: (sortBy) {
                  context.read<LandBloc>().add(SortLandListings(sortBy));
                },
                selectedCountry: state is LandStateLoaded ? state.country : null,
                selectedSortOption: state is LandStateLoaded ? state.sortBy : null,
                searchQuery: state is LandStateLoaded ? state.searchQuery ?? '' : '',
              );
            },
          ),
          
          // Content Area
          Expanded(
            child: BlocBuilder<LandBloc, LandState>(
              builder: _buildContent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const _ShimmerLandPlotCard();
      },
    );
  }

  Widget _buildContent(BuildContext context, LandState state) {
    if (state is LandStateLoading) {
      return _buildShimmerLoading();
    }

    if (state is LandStateError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading listings',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<LandBloc>().add(const RefreshLandListings());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is LandStateLoaded) {
      final listings = state.listings;
      
      // Precache images for smooth scrolling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheImages(listings);
      });

      if (listings.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No listings found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Try adjusting your filters or search terms',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<LandBloc>().add(const RefreshLandListings());
        },
        child: Stack(
          children: [
            ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: listings.length,
              itemBuilder: (context, index) {
                return _LandPlotCardItem(plot: listings[index]);
              },
            ),
            if (state.isRefreshing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ShimmerLandPlotCard extends StatelessWidget {
  const _ShimmerLandPlotCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              color: Colors.grey[300],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 200,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 14,
                    width: 150,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 20,
                        width: 100,
                        color: Colors.grey[300],
                      ),
                      Container(
                        height: 16,
                        width: 80,
                        color: Colors.grey[300],
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

class _LandPlotCardItem extends StatelessWidget {

  const _LandPlotCardItem({required this.plot});
  final LandPlot plot;

  @override
  Widget build(BuildContext context) {
    return LandPlotCard(plot: plot);
  }
}
