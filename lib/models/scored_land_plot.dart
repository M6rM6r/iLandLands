import 'package:equatable/equatable.dart';
import 'package:gulflands/models/land_plot.dart';

class ScoredLandPlot extends Equatable {

  const ScoredLandPlot({
    required this.plot,
    required this.score,
    required this.searchRelevance,
    this.matchReasons = const [],
  });
  final LandPlot plot;
  final double score;
  final double searchRelevance;
  final List<String> matchReasons;

  ScoredLandPlot copyWith({
    LandPlot? plot,
    double? score,
    double? searchRelevance,
    List<String>? matchReasons,
  }) {
    return ScoredLandPlot(
      plot: plot ?? this.plot,
      score: score ?? this.score,
      searchRelevance: searchRelevance ?? this.searchRelevance,
      matchReasons: matchReasons ?? this.matchReasons,
    );
  }

  @override
  List<Object?> get props => [plot.id, score, searchRelevance];

  @override
  String toString() {
    return 'ScoredLandPlot(plot: ${plot.id}, score: $score, searchRelevance: $searchRelevance)';
  }
}
