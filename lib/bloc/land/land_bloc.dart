import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gulflands/core/services/ranking_service.dart';
import 'package:gulflands/domain/usecases/search_and_rank_listings.dart';
import 'package:gulflands/models/land_plot.dart';
import 'package:gulflands/models/scored_land_plot.dart';
import 'package:gulflands/models/sort_option.dart';
import 'package:gulflands/services/land_repository.dart';

part 'land_event.dart';
part 'land_state.dart';

class LandBloc extends Bloc<LandEvent, LandState> {

  LandBloc({
    required LandRepository repository,
    RankingService? rankingService,
  }) : _repository = repository,
       _rankingService = rankingService ?? RankingService(),
       super(const LandState.initial()) {
    _searchAndRankListings = SearchAndRankListings(_repository, _rankingService);
    on<LandEvent>(_onLandEvent);
  }
  final LandRepository _repository;
  final RankingService _rankingService;
  late final SearchAndRankListings _searchAndRankListings;

  Future<void> _onLandEvent(LandEvent event, Emitter<LandState> emit) async {
    switch (event) {
      case LoadLandListings():
        await _onLoadLandListings(event, emit);
      case RefreshLandListings():
        await _onRefreshLandListings(event, emit);
      case FilterLandListings():
        await _onFilterLandListings(event, emit);
      case SortLandListings():
        await _onSortLandListings(event, emit);
      case SearchLandListings():
        await _onSearchLandListings(event, emit);
    }
  }

  Future<void> _onLoadLandListings(
    LoadLandListings event,
    Emitter<LandState> emit,
  ) async {
    emit(const LandState.loading());

    try {
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        // Use search and rank for search queries
        final favoriteIds = await _repository.getFavoriteIds();
        final scoredListings = await _searchAndRankListings.call(
          event.searchQuery!,
          country: event.country,
          favoriteIds: favoriteIds,
        );
        final listings = scoredListings.map((scored) => scored.plot).toList();

        emit(LandState.loaded(
          listings: listings,
          scoredListings: scoredListings,
          country: event.country,
          searchQuery: event.searchQuery,
        ));
      } else {
        // Use regular repository for non-search listings
        final listings = await _repository.getLandListings(
          country: event.country,
          sortBy: event.sortBy,
          searchQuery: event.searchQuery,
        );

        emit(LandState.loaded(
          listings: listings,
          country: event.country,
          sortBy: event.sortBy,
          searchQuery: event.searchQuery,
        ));
      }
    } catch (e) {
      emit(LandState.error(e.toString()));
    }
  }

  Future<void> _onRefreshLandListings(
    RefreshLandListings event,
    Emitter<LandState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is LandStateLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else {
      emit(const LandState.loading());
    }
    
    try {
      final listings = await _repository.getLandListings(
        forceRefresh: true,
        country: currentState.maybeWhen(
          loaded: (s) => s.country,
          orElse: () => null,
        ),
        sortBy: currentState.maybeWhen(
          loaded: (s) => s.sortBy,
          orElse: () => null,
        ),
        searchQuery: currentState.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      );
      
      emit(LandState.loaded(
        listings: listings,
        country: currentState.maybeWhen(
          loaded: (s) => s.country,
          orElse: () => null,
        ),
        sortBy: currentState.maybeWhen(
          loaded: (s) => s.sortBy,
          orElse: () => null,
        ),
        searchQuery: currentState.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      ));
    } catch (e) {
      emit(LandState.error(e.toString()));
    }
  }

  Future<void> _onFilterLandListings(
    FilterLandListings event,
    Emitter<LandState> emit,
  ) async {
    emit(const LandState.loading());
    
    try {
      final listings = await _repository.getLandListings(
        country: event.country,
        sortBy: state.maybeWhen(
          loaded: (s) => s.sortBy,
          orElse: () => null,
        ),
        searchQuery: state.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      );

      emit(LandState.loaded(
        listings: listings,
        country: event.country,
        sortBy: state.maybeWhen(
          loaded: (s) => s.sortBy,
          orElse: () => null,
        ),
        searchQuery: state.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      ));
    } catch (e) {
      emit(LandState.error(e.toString()));
    }
  }

  Future<void> _onSortLandListings(
    SortLandListings event,
    Emitter<LandState> emit,
  ) async {
    emit(const LandState.loading());
    
    try {
      final listings = await _repository.getLandListings(
        country: state.maybeWhen(
          loaded: (s) => s.country,
          orElse: () => null,
        ),
        sortBy: event.sortBy,
        searchQuery: state.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      );

      emit(LandState.loaded(
        listings: listings,
        country: state.maybeWhen(
          loaded: (s) => s.country,
          orElse: () => null,
        ),
        sortBy: event.sortBy,
        searchQuery: state.maybeWhen(
          loaded: (s) => s.searchQuery,
          orElse: () => null,
        ),
      ));
    } catch (e) {
      emit(LandState.error(e.toString()));
    }
  }

  Future<void> _onSearchLandListings(
    SearchLandListings event,
    Emitter<LandState> emit,
  ) async {
    emit(const LandState.loading());

    try {
      final country = state.maybeWhen(
        loaded: (s) => s.country,
        orElse: () => null,
      );

      final favoriteIds = await _repository.getFavoriteIds();

      final scoredListings = await _searchAndRankListings.call(
        event.query,
        country: country,
        favoriteIds: favoriteIds,
      );

      // Extract the plots from scored listings for backward compatibility
      final listings = scoredListings.map((scored) => scored.plot).toList();

      emit(LandState.loaded(
        listings: listings,
        scoredListings: scoredListings,
        country: country,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(LandState.error(e.toString()));
    }
  }
}
