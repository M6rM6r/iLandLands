import 'package:flutter/material.dart';
import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/usecases/filter_listings.dart';

typedef OnFilterChanged = void Function(Country? country, SortOption? sortOption);

class FilterBar extends StatelessWidget {

  const FilterBar({
    required this.onFilterChanged, super.key,
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
        children: [
          DropdownButton<Country?>(
            value: selectedCountry,
            hint: const Text('Filter by Country'),
            onChanged: (Country? newValue) {
              onFilterChanged(newValue, null);
            },
            items: [
              const DropdownMenuItem<Country?>(
                child: Text('All Countries'),
              ),
              ...Country.values.map<DropdownMenuItem<Country>>((Country country) {
                return DropdownMenuItem<Country>(
                  value: country,
                  child: Text(country.toString().split('.').last),
                );
              }),
            ],
          ),
          DropdownButton<SortOption?>(
            value: selectedSortOption,
            hint: const Text('Sort by'),
            onChanged: (SortOption? newValue) {
              onFilterChanged(null, newValue);
            },
            items: [
              const DropdownMenuItem<SortOption?>(
                child: Text('Default Order'),
              ),
              ...SortOption.values.map<DropdownMenuItem<SortOption>>((SortOption option) {
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
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
    }
  }
}