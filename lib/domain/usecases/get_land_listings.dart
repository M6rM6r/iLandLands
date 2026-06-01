import 'package:gulflands/domain/entities/land_plot.dart';
import 'package:gulflands/domain/repositories/land_repository.dart';

class GetLandListings {

  GetLandListings(this.repository);
  final LandRepository repository;

  Future<List<LandPlot>> call() async {
    return repository.getLandListings();
  }
}