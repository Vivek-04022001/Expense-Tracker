import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/savings_model.dart';

class SavingsRepository {
  final DioClient _dioClient;

  SavingsRepository(this._dioClient);

  Future<SavingsModel> getSummary({DateTime? from, DateTime? to}) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String().substring(0, 10);
    if (to != null) params['to'] = to.toIso8601String().substring(0, 10);

    final response = await _dioClient.get(
      ApiConstants.savingsSummary,
      queryParameters: params.isEmpty ? null : params,
    );
    return SavingsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
