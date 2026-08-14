enum ConnectivityStatus {
  wifi('Wi-Fi'),
  mobile('Mobile'),
  none('Offline');

  const ConnectivityStatus(this.label);

  final String label;

  bool get isOnline => this != ConnectivityStatus.none;

  static ConnectivityStatus? tryParse(String raw) => switch (raw) {
    'wifi' => ConnectivityStatus.wifi,
    'mobile' => ConnectivityStatus.mobile,
    'none' => ConnectivityStatus.none,
    _ => null,
  };
}
