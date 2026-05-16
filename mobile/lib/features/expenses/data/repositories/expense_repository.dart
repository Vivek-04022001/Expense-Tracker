import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  const ExpenseRepository(this._dioClient);

  final DioClient _dioClient;

  Future<ExpenseListResponse> getExpenses({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (category != null) 'category': category,
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _dioClient.get(
      ApiConstants.expenses,
      queryParameters: queryParams,
    );
    return ExpenseListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    required String category,
    String? description,
    required String paymentMethod,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'category': category,
      'paymentMethod': paymentMethod,
      if (description != null) 'description': description,
      if (date != null) 'date': date.toIso8601String(),
    };

    final response = await _dioClient.post(ApiConstants.expenses, data: body);
    return ExpenseModel.fromJson(
      (response.data as Map<String, dynamic>)['expense'] as Map<String, dynamic>,
    );
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? category,
    String? description,
    String? paymentMethod,
    DateTime? date,
  }) async {
    final body = <String, dynamic>{
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (date != null) 'date': date.toIso8601String(),
    };

    final response = await _dioClient.patch(
      ApiConstants.expenseById(id),
      data: body,
    );
    return ExpenseModel.fromJson(
      (response.data as Map<String, dynamic>)['expense'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteExpense(String id) async {
    await _dioClient.delete(ApiConstants.expenseById(id));
  }

  Future<ExpenseSummary> getSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{
      if (startDate != null) 'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate.toIso8601String(),
    };

    final response = await _dioClient.get(
      ApiConstants.expenseSummary,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return ExpenseSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
