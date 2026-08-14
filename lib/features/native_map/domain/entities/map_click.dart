import 'package:equatable/equatable.dart';

class MapClick extends Equatable {
  const MapClick({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  String get label =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  @override
  List<Object?> get props => [latitude, longitude];
}
