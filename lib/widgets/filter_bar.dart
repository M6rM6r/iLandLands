import 'package:flutter/material.dart';
import 'package:gulflands/models/land_plot.dart';

// Enum to define the available sorting options.
enum SortOption { priceAsc, priceDesc, areaAsc, areaDesc }

// A callback type for when a filter or sort option changes.
typedef OnFilterChanged =
    void Function({Country? country, SortOption? sortOption});

// FilterBar provides the UI for filtering and sorting land listings.
class FilterBar extends StatelessWidget {
  const FilterBar({
    required this.onFilterChanged,
    super.key,
    this.selectedCountry,
    this.selectedSortOption,
  });
  final OnFilterChanged onFilterChanged;
  final Country? selectedCountry;
  final SortOption? selectedSortOption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          // Country Filter Dropdown
          DropdownButton<Country?>(
            value: selectedCountry,
            hint: const Text('Filter by Country'),
            onChanged: (Country? newValue) {
              onFilterChanged(country: newValue);
            },
            items: <DropdownMenuItem<Country?>>[
              const DropdownMenuItem<Country?>(child: Text('All Countries')),
              ...Country.values.map<DropdownMenuItem<Country>>((
                Country country,
              ) {
                return DropdownMenuItem<Country>(
                  value: country,
                  child: Text(country.toString().split('.').last),
                );
              }),
            ],
          ),
          // Sort By Dropdown
          DropdownButton<SortOption?>(
            value: selectedSortOption,
            hint: const Text('Sort by'),
            onChanged: (SortOption? newValue) {
              onFilterChanged(sortOption: newValue);
            },
            items: <DropdownMenuItem<SortOption?>>[
              const DropdownMenuItem<SortOption?>(child: Text('Default Order')),
              ...SortOption.values.map<DropdownMenuItem<SortOption>>((
                SortOption option,
              ) {
                return DropdownMenuItem<SortOption>(
                  value: option,
                  child: Text(_getSortOptionText(option)),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortOptionText(SortOption option) {
    switch (option) {
      case SortOption.priceAsc:
        return 'Price: Low to High';
      case SortOption.priceDesc:
        return 'Price: High to Low';
      case SortOption.areaAsc:
        return 'Area: Smallest to Largest';
      case SortOption.areaDesc:
        return 'Area: Largest to Smallest';
    }
  }
}
