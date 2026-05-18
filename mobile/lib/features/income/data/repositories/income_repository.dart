import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/income_model.dart';

class IncomeRepository {
  final DioClient _dioClient;

  IncomeRepository(this._dioClient);

  static final _dateFmt = DateFormat('yyyy-MM-dd');

  Future<List<IncomeModel>> getIncomes({
    required DateTime from,
    required DateTime to,
    IncomeType? incomeType,
  }) async {
    final params = <String, String>{
      'from': _dateFmt.format(from),
      'to': _dateFmt.format(to),
    };
    if (incomeType != null) params['incomeType'] = incomeType.toServer();

    final response = await _dioClient.get(
      ApiConstants.income,
      queryParameters: params,
    );
    return (response.data as List)
        .cast<Map<String, dynamic>>()
        .map(IncomeModel.fromJson)
        .toList();
  }

  Future<IncomeModel> createIncome({
    required double amount,
    IncomeType? incomeType,
    String? description,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.income,
      data: {
        'amount': amount,
        if (incomeType != null) 'incomeType': incomeType.toServer(),
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return IncomeModel.fromJson(
      response.data['income'] as Map<String, dynamic>,
    );
  }

  Future<IncomeModel> updateIncome(
    String id, {
    double? amount,
    IncomeType? incomeType,
    String? description,
  }) async {
    final response = await _dioClient.patch(
      ApiConstants.incomeById(id),
      data: {
        if (amount != null) 'amount': amount,
        if (incomeType != null) 'incomeType': incomeType.toServer(),
        if (description != null) 'description': description,
      },
    );
    return IncomeModel.fromJson(
      response.data['income'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteIncome(String id) async {
    await _dioClient.delete(ApiConstants.incomeById(id));
  }
}
