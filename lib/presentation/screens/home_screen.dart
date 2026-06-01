import 'package:flutter/material.dart';
import 'package:gulflands/presentation/providers/land_provider.dart';
import 'package:gulflands/presentation/widgets/filter_bar.dart';
import 'package:gulflands/presentation/widgets/land_plot_card.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LandProvider>().loadListings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LandProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gulf Lands Market'),
      ),
      body: Column(
        children: [
          FilterBar(
            onFilterChanged: (country, sortOption) {
              provider.setFilter(country: country, sortOption: sortOption);
            },
            selectedCountry: provider.selectedCountry,
            selectedSortOption: provider.selectedSortOption,
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.error != null
                    ? Center(child: Text('Error: ${provider.error}'))
                    : provider.filteredPlots.isEmpty
                        ? const Center(child: Text('No land listings found.'))
                        : ListView.builder(
                            itemCount: provider.filteredPlots.length,
                            itemBuilder: (context, index) {
                              final plot = provider.filteredPlots[index];
                              return LandPlotCard(
                                plot: plot,
                                isFavorite: provider.isFavorite(plot.id),
                                onFavoriteToggle: () => provider.toggleFavoriteForPlot(plot.id),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}