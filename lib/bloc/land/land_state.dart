part of 'land_bloc.dart';

class LandState extends Equatable {
  const LandState();

  const factory LandState.initial() = LandStateInitial;
  const factory LandState.loading() = LandStateLoading;
  const factory LandState.loaded({
    required List<LandPlot> listings,
    List<ScoredLandPlot>? scoredListings,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
    bool isRefreshing,
  }) = LandStateLoaded;
  const factory LandState.error(String message) = LandStateError;

  @override
  List<Object?> get props => [];

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(LandStateLoaded loaded) loaded,
    required T Function(LandStateError error) error,
  }) {
    if (this is LandStateInitial) return initial();
    if (this is LandStateLoading) return loading();
    if (this is LandStateLoaded) return loaded(this as LandStateLoaded);
    if (this is LandStateError) return error(this as LandStateError);
    throw StateError('Unhandled state: $this');
  }

  T maybeWhen<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function(LandStateLoaded loaded)? loaded,
    T Function(LandStateError error)? error,
  }) {
    if (this is LandStateInitial && initial != null) return initial();
    if (this is LandStateLoading && loading != null) return loading();
    if (this is LandStateLoaded && loaded != null) {
      return loaded(this as LandStateLoaded);
    }
    if (this is LandStateError && error != null) return error(this as LandStateError);
    return orElse();
  }
}

class LandStateInitial extends LandState {
  const LandStateInitial();
}

class LandStateLoading extends LandState {
  const LandStateLoading();
}

class LandStateLoaded extends LandState {
  const LandStateLoaded({
    required this.listings,
    this.scoredListings,
    this.country,
    this.sortBy,
    this.searchQuery,
    this.isRefreshing = false,
  });

  final List<LandPlot> listings;
  final List<ScoredLandPlot>? scoredListings;
  final Country? country;
  final SortOption? sortBy;
  final String? searchQuery;
  final bool isRefreshing;

  LandStateLoaded copyWith({
    List<LandPlot>? listings,
    List<ScoredLandPlot>? scoredListings,
    Country? country,
    SortOption? sortBy,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return LandStateLoaded(
      listings: listings ?? this.listings,
      scoredListings: scoredListings ?? this.scoredListings,
      country: country ?? this.country,
      sortBy: sortBy ?? this.sortBy,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        listings,
        scoredListings,
        country,
        sortBy,
        searchQuery,
        isRefreshing,
      ];
}

class LandStateError extends LandState {
  const LandStateError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
