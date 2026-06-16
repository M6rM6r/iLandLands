import 'package:flutter/material.dart';
import '../core/design_system.dart';
import '../core/responsive_layout.dart';
import '../widgets/land_plot_card.dart';
import '../models/land_plot.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Gulflands Discovery', style: tokens.headingStyle),
        elevation: 0,
        backgroundColor: tokens.surfaceElevated,
      ),
      body: ResponsiveLayout(
        mobile: _LandGrid(crossAxisCount: 1),
        tablet: _LandGrid(crossAxisCount: 2),
        desktop: _LandGrid(crossAxisCount: 3),
      ),
    );
  }
}

class _LandGrid extends StatelessWidget {
  final int crossAxisCount;

  const _LandGrid({required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    // Temporary static data for architectural verification
    final List<LandPlot> mockData = List.generate(
      12,
      (index) => LandPlot(
        id: 'ID-$index',
        title: 'Premium Plot #$index',
        description: 'Luxury plot located in the heart of the city.',
        location: 'Riyadh, KSA',
        price: 50000.0 + (index * 1000),
        area: 500.0 + (index * 50),
        country: Country.saudiArabia,
        imageUrls: const [],
        createdAt: DateTime.now(),
      ),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(tokens.spacingUnit * 2),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: tokens.spacingUnit * 2,
              crossAxisSpacing: tokens.spacingUnit * 2,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => LandPlotCard(plot: mockData[index]),
              childCount: mockData.length,
            ),
          ),
        ),
      ],
    );
  }
}
