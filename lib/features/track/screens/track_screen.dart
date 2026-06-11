import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/rounded_card.dart';
import '../services/route_service.dart';

class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  static const _vehicles = <String, double>{
    'Electric Car': 0.05,
    'Hybrid Car': 0.12,
    'Petrol Car': 0.21,
    'SUV': 0.28,
    'Public Bus': 0.10,
    'Train': 0.04,
    'Bicycle': 0,
    'Walking': 0,
  };

  static const _initialCenter = LatLng(33.8938, 35.5018);

  final _formKey = GlobalKey<FormState>();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _mapController = MapController();
  final _routeService = RouteService();

  String _mode = 'Petrol Car';
  CalculatedRoute? _route;
  String? _routeError;
  bool _calculating = false;
  bool _saving = false;

  double get _emissionRate => _vehicles[_mode] ?? 0.21;
  double get _carbonEstimate => (_route?.distanceKm ?? 0) * _emissionRate;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _invalidateRoute(String _) {
    if (_route == null && _routeError == null) return;
    setState(() {
      _route = null;
      _routeError = null;
    });
  }

  Future<void> _calculateRoute() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _calculating = true;
      _routeError = null;
      _route = null;
    });

    try {
      final route = await _routeService.calculate(
        startAddress: _start.text,
        endAddress: _end.text,
      );
      if (!mounted) return;
      setState(() => _route = route);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || route.points.length < 2) return;
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: route.points,
            padding: const EdgeInsets.all(38),
          ),
        );
      });
    } on RouteException catch (error) {
      if (mounted) setState(() => _routeError = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _routeError = 'Could not calculate this route.');
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  Future<void> _saveRoute() async {
    final route = _route;
    if (route == null) {
      setState(() => _routeError = 'Calculate a route before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _routeError = null;
    });
    try {
      final coordinateStep = math.max(
        1,
        (route.rawCoordinates.length / 80).ceil(),
      ).toInt();
      final limitedCoordinates = <List<double>>[
        for (var index = 0;
            index < route.rawCoordinates.length;
            index += coordinateStep)
          route.rawCoordinates[index],
      ];
      if (limitedCoordinates.last != route.rawCoordinates.last) {
        limitedCoordinates.add(route.rawCoordinates.last);
      }

      final response = await ApiClient.instance.post(
        ApiConstants.activity,
        data: {
          'category': 'transport',
          'data': {
            'tracking_type': 'route',
            'start_location': _start.text.trim(),
            'end_location': _end.text.trim(),
            'start_display_name': route.start.displayName,
            'end_display_name': route.end.displayName,
            'start_coordinates': {
              'lat': route.start.latitude,
              'lon': route.start.longitude,
            },
            'end_coordinates': {
              'lat': route.end.latitude,
              'lon': route.end.longitude,
            },
            'distance': double.parse(route.distanceKm.toStringAsFixed(2)),
            'duration_minutes': route.durationMinutes,
            'vehicle': _mode,
            'emission_rate': _emissionRate,
            'carbon_estimate': double.parse(
              _carbonEstimate.toStringAsFixed(2),
            ),
            'route_source': 'OpenStreetMap + OSRM',
            'route_coordinates': limitedCoordinates,
          },
        },
      );
      if (!mounted) return;
      final carbon = response is Map ? response['carbon'] : null;
      final savedCarbon = double.tryParse(carbon?.toString() ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedCarbon == null
                ? 'Route activity saved.'
                : 'Route saved: ${savedCarbon.toStringAsFixed(2)} kg CO2e.',
          ),
          action: SnackBarAction(
            label: 'History',
            onPressed: () => context.go('/history'),
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _routeError = ApiClient.errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text('Plan a route', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'Search two locations, calculate a road route, and save its transport impact.',
          style: TextStyle(color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        RoundedCard(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _start,
                  onChanged: _invalidateRoute,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Start location',
                    hintText: 'e.g. Beirut, Lebanon',
                    prefixIcon: Icon(Icons.trip_origin_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a start location.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _end,
                  onChanged: _invalidateRoute,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _calculateRoute(),
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g. Jounieh, Lebanon',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a destination.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Transport mode',
                    prefixIcon: Icon(Icons.directions_car_rounded),
                  ),
                  items: _vehicles.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(
                            '${entry.key} · ${entry.value.toStringAsFixed(2)} kg/km',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _mode = value ?? _mode),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Calculate route',
                  isLoading: _calculating,
                  onPressed: _calculateRoute,
                  icon: Icons.route_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _RouteMap(
          mapController: _mapController,
          route: _route,
          isLoading: _calculating,
        ),
        if (_routeError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _routeError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_route != null) ...[
          const SizedBox(height: 16),
          _RouteSummary(
            route: _route!,
            mode: _mode,
            estimate: _carbonEstimate,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Save route activity',
            isLoading: _saving,
            onPressed: _saveRoute,
            icon: Icons.save_rounded,
          ),
        ],
      ],
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({
    required this.mapController,
    required this.route,
    required this.isLoading,
  });

  final MapController mapController;
  final CalculatedRoute? route;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 270,
          child: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: const MapOptions(
                  initialCenter: _TrackScreenState._initialCenter,
                  initialZoom: 10,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ecotrack.mobile',
                    maxZoom: 19,
                  ),
                  if (route != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: route!.points,
                          color: AppColors.green,
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  if (route != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: route!.start.point,
                          width: 42,
                          height: 42,
                          child: const _MapMarker(
                            icon: Icons.trip_origin_rounded,
                            color: AppColors.greenDark,
                          ),
                        ),
                        Marker(
                          point: route!.end.point,
                          width: 42,
                          height: 42,
                          child: const _MapMarker(
                            icon: Icons.location_on_rounded,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 9, color: AppColors.navy),
                  ),
                ),
              ),
              if (route == null && !isLoading)
                const Center(
                  child: _MapHint(),
                ),
              if (isLoading)
                ColoredBox(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 8),
        ],
        border: Border.all(color: color, width: 2),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _MapHint extends StatelessWidget {
  const _MapHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(28),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x22092A2F), blurRadius: 18),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, color: AppColors.greenDark),
          SizedBox(width: 10),
          Flexible(
            child: Text(
              'Enter both locations to draw the route.',
              style: TextStyle(color: AppColors.navy),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.route,
    required this.mode,
    required this.estimate,
  });

  final CalculatedRoute route;
  final String mode;
  final double estimate;

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      color: AppColors.mint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Route summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: '${route.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  icon: Icons.schedule_rounded,
                  label: 'Drive time',
                  value: '${route.durationMinutes} min',
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.co2_rounded, color: AppColors.greenDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mode, style: Theme.of(context).textTheme.titleSmall),
                    const Text(
                      'Approximate transport estimate',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '${estimate.toStringAsFixed(2)} kg',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.greenDark,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greenDark, size: 22),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted)),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
