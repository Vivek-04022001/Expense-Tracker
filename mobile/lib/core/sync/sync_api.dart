import '../network/dio_client.dart';

/// Thin HTTP wrapper over the server's sync endpoints. Kept separate from the
/// engine so the transport is easy to mock/test.
class SyncApi {
  SyncApi(this._dio);

  final DioClient _dio;

  /// Delta pull. Passes [since] as the cursor; omitting it asks the server for a
  /// full snapshot (first-run bootstrap). Returns the decoded JSON body
  /// (`{ serverTime, changes: { accounts, categories, ... } }`).
  Future<Map<String, dynamic>> pull(DateTime? since) async {
    final response = await _dio.get(
      '/sync/pull',
      queryParameters:
          since == null ? null : {'since': since.toUtc().toIso8601String()},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Pushes a batch of local mutations. Returns the decoded body
  /// (`{ results: [ { index, id, status }, ... ] }`).
  Future<Map<String, dynamic>> push(
    List<Map<String, dynamic>> operations,
  ) async {
    final response = await _dio.post(
      '/sync/push',
      data: {'operations': operations},
    );
    return response.data as Map<String, dynamic>;
  }
}
