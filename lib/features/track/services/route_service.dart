import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

class RouteLocation {
  const RouteLocation({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;

  LatLng get point => LatLng(latitude, longitude);
}

class CalculatedRoute {
  const CalculatedRoute({
    required this.start,
    required this.end,
    required this.points,
    required this.rawCoordinates,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final RouteLocation start;
  final RouteLocation end;
  final List<LatLng> points;
  final List<List<double>> rawCoordinates;
  final double distanceKm;
  final int durationMinutes;
}

class RouteService {
  RouteService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {'Accept': 'application/json'},
          ),
        );

  final Dio _dio;

  Future<CalculatedRoute> calculate({
    required String startAddress,
    required String endAddress,
  }) async {
    try {
      final start = await _geocode(startAddress);
      final end = await _geocode(endAddress);
      final response = await _dio.get<Map<String, dynamic>>(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}',
        queryParameters: const {
          'overview': 'full',
          'geometries': 'geojson',
        },
      );

      final routes = response.data?['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        throw const RouteException(
          'No road route was found between these locations.',
        );
      }

      final route = Map<String, dynamic>.from(routes.first as Map);
      final geometry = route['geometry'];
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (coordinates is! List || coordinates.length < 2) {
        throw const RouteException('The routing service returned no route.');
      }

      final rawCoordinates = coordinates.map<List<double>>((coordinate) {
        final values = coordinate as List;
        return [
          (values[0] as num).toDouble(),
          (values[1] as num).toDouble(),
        ];
      }).toList();

      return CalculatedRoute(
        start: start,
        end: end,
        points: rawCoordinates
            .map((coordinate) => LatLng(coordinate[1], coordinate[0]))
            .toList(),
        rawCoordinates: rawCoordinates,
        distanceKm: ((route['distance'] as num?)?.toDouble() ?? 0) / 1000,
        durationMinutes:
            (((route['duration'] as num?)?.toDouble() ?? 0) / 60).round(),
      );
    } on RouteException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const RouteException(
          'Could not reach the map service. Check your connection and retry.',
        );
      }
      throw const RouteException(
        'The map service could not calculate this route.',
      );
    } on FormatException {
      throw const RouteException('The map service returned invalid data.');
    } on TypeError {
      throw const RouteException('The map service returned invalid data.');
    }
  }

  Future<RouteLocation> _geocode(String address) async {
    final response = await _dio.get<List<dynamic>>(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {
        'q': address.trim(),
        'format': 'jsonv2',
        'limit': 1,
      },
      options: Options(
        headers: const {
          'User-Agent': 'EcoTrack-FYP-Mobile/1.0',
          'Accept-Language': 'en',
        },
      ),
    );

    final matches = response.data;
    if (matches == null || matches.isEmpty || matches.first is! Map) {
      throw RouteException('Could not find location: $address');
    }

    final match = Map<String, dynamic>.from(matches.first as Map);
    final latitude = double.tryParse(match['lat']?.toString() ?? '');
    final longitude = double.tryParse(match['lon']?.toString() ?? '');
    if (latitude == null || longitude == null) {
      throw RouteException('Could not read location: $address');
    }

    return RouteLocation(
      latitude: latitude,
      longitude: longitude,
      displayName: match['display_name']?.toString() ?? address.trim(),
    );
  }
}

class RouteException implements Exception {
  const RouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
