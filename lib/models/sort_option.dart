enum SortOption {
  priceAsc('price_asc', 'Price: Low to High'),
  priceDesc('price_desc', 'Price: High to Low'),
  areaAsc('area_asc', 'Area: Small to Large'),
  areaDesc('area_desc', 'Area: Large to Small'),
  newest('newest', 'Newest First'),
  oldest('oldest', 'Oldest First'),
  relevance('relevance', 'Relevance');

  const SortOption(this.value, this.label);

  final String value;
  final String label;

  static SortOption fromString(String value) {
    return SortOption.values.firstWhere(
      (option) => option.value == value,
      orElse: () => SortOption.relevance,
    );
  }
}
