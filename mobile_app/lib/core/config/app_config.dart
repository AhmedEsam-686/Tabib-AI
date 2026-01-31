class AppConfig {
  const AppConfig._();

  // Toggle between mock and real gRPC service.
  static const bool useMockService = false;

  // gRPC host/port. For Android emulator use 10.0.2.2 to reach host machine.
  static const String grpcHost = '192.168.1.110';
  static const int grpcPort = 50052;
}
