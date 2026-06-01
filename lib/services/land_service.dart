import 'package:gulflands/models/land_plot.dart';

// LandService is responsible for fetching land plot data.
// Currently, it uses a mock implementation with a delay to simulate a network call.
class LandService {

  // A static list of sample land plots for development purposes.
  static final List<LandPlot> _samplePlots = [
    LandPlot(
      id: '1',
      title: 'Prime Coastal Land in Jeddah',
      description: 'A stunning piece of land with direct access to the Red Sea. Perfect for a luxury villa or a private resort.',
      price: 5000000,
      area: 10000,
      country: Country.saudiArabia,
      location: 'Jeddah, Obhur',
      imageUrls: const ['https://via.placeholder.com/400x300.png/009688/FFFFFF?Text=Jeddah+Land+1'],
      createdAt: DateTime(2023),
    ),
    LandPlot(
      id: '2',
      title: 'Exclusive Plot in Dubai Hills Estate',
      description: 'Located in one of the most prestigious communities in Dubai, offering stunning views of the golf course.',
      price: 12000000,
      area: 15000,
      country: Country.uae,
      location: 'Dubai, Dubai Hills Estate',
      imageUrls: const ['https://via.placeholder.com/400x300.png/FFC107/000000?Text=Dubai+Land+1'],
      createdAt: DateTime(2023, 1, 2),
    ),
    LandPlot(
      id: '3',
      title: 'Sea View Land in The Pearl, Qatar',
      description: 'An exceptional opportunity to build your dream home in one of the most sought-after locations in Doha.',
      price: 9500000,
      area: 8000,
      country: Country.qatar,
      location: 'Doha, The Pearl-Qatar',
      imageUrls: const ['https://via.placeholder.com/400x300.png/795548/FFFFFF?Text=Qatar+Land+1'],
      createdAt: DateTime(2023, 1, 3),
    ),
    LandPlot(
      id: '4',
      title: 'Large Agricultural Land in Al-Ahsa',
      description: 'A vast expanse of fertile land, perfect for agricultural projects. Comes with water access.',
      price: 2500000,
      area: 50000, // 5 hectares
      country: Country.saudiArabia,
      location: 'Al-Ahsa',
      imageUrls: const ['https://via.placeholder.com/400x300.png/4CAF50/FFFFFF?Text=Al-Ahsa+Land+1'],
      createdAt: DateTime(2023, 1, 4)
    ),
  ];

  // Fetches the list of land plots.
  // This method simulates a network delay of 1.5 seconds.
  Future<List<LandPlot>> getLandListings() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    return _samplePlots;
  }
}
