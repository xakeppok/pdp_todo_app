enum ConnectivityStatus {
  wifi('Wi-Fi'),
  mobile('Mobile'),
  none('Offline');

  const ConnectivityStatus(this.label);

  final String label;
}
