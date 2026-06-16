import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gulflands/bloc/land/land_bloc.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';
import 'package:gulflands/presentation/widgets/filter_bar.dart';
import 'package:gulflands/presentation/widgets/land_plot_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LandBloc>().add(const LoadLandListings());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LandBloc, LandState>(
      builder: (BuildContext context, LandState state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Gulf Lands Market')),
          body: Column(
            children: <Widget>[
              FilterBar(
                onFilterChanged: (Country? country, SortOption? sortOption) {
                  context.read<LandBloc>().add(FilterLandListings(country));
                  if (sortOption != null) {
                    context.read<LandBloc>().add(SortLandListings(sortOption));
                  }
                },
                selectedCountry: state is LandStateLoaded
                    ? state.country
                    : null,
                selectedSortOption: state is LandStateLoaded
                    ? state.sortBy
                    : null,
              ),
              Expanded(
                child: state.when(
                  initial: () =>
                      const Center(child: CircularProgressIndicator()),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  loaded: (LandStateLoaded loaded) => loaded.listings.isEmpty
                      ? const Center(child: Text('No land listings found.'))
                      : ListView.builder(
                          itemCount: loaded.listings.length,
                          itemBuilder: (BuildContext context, int index) {
                            final LandPlot plot = loaded.listings[index];
                            return LandPlotCard(
                              plot: plot,
                              isFavorite: false,
                              onFavoriteToggle: () {},
                            );
                          },
                        ),
                  error: (LandStateError err) =>
                      Center(child: Text('Error: ${err.message}')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
