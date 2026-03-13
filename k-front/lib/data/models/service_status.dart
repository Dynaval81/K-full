class ServiceStatus {
  final String name;
  final bool isOnline;
  final String status;
  final String? message;

  ServiceStatus({
    required this.name,
    required this.isOnline,
    required this.status,
    this.message,
  });
}
