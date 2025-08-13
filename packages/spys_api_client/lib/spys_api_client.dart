import 'dart:async';

class SpysApiClient {
  final String baseUrl;
  const SpysApiClient({required this.baseUrl});

  Future<String> getServerStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 'OK from $baseUrl';
  }
}
