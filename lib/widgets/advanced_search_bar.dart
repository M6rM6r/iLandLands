import 'package:flutter/material.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/sort_option.dart';

class AdvancedSearchBar extends StatefulWidget {

  const AdvancedSearchBar({
    required this.onSearchChanged, required this.onCountryFilterChanged, required this.onSortChanged, super.key,
    this.selectedCountry,
    this.selectedSortOption,
    this.searchQuery = '',
  });
  final void Function(String query) onSearchChanged;
  final void Function(Country? country) onCountryFilterChanged;
  final void Function(SortOption? sortBy) onSortChanged;
  final Country? selectedCountry;
  final SortOption? selectedSortOption;
  final String searchQuery;

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  late TextEditingController _searchController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    widget.onSearchChanged(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Input Field
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title, location, or description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Advanced Filters (Expandable)
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advanced Filters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Country Filter
                  Row(
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Country:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButton<Country?>(
                          value: widget.selectedCountry,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (Country? newValue) {
                            widget.onCountryFilterChanged(newValue);
                          },
                          items: [
                            const DropdownMenuItem<Country?>(
                              child: Text('All Countries'),
                            ),
                            ...Country.values.map((Country country) {
                              return DropdownMenuItem<Country>(
                                value: country,
                                child: Text(country.name
                                    .split('')
                                    .map((e) => e.toUpperCase())
                                    .join()),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Sort Options
                  Row(
                    children: [
                      Icon(
                        Icons.sort,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sort by:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: DropdownButton<SortOption?>(
                          value: widget.selectedSortOption,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (SortOption? newValue) {
                            widget.onSortChanged(newValue);
                          },
                          items: [
                            const DropdownMenuItem<SortOption?>(
                              child: Text('Default Order'),
                            ),
                            ...SortOption.values.map((SortOption option) {
                              return DropdownMenuItem<SortOption>(
                                value: option,
                                child: Text(_getSortOptionText(option)),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.areaDesc:
        return 'Area: Largest to Smallest';
    }
  }
}
