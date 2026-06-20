import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/expense_model.dart';
import '../models/expense_summary_model.dart';

class ExpenseRepository {
  final DioClient _dioClient;

  ExpenseRepository(this._dioClient);

  Future<List<ExpenseModel>> getExpenses({
    required DateTime from,
    required DateTime to,
    String? category,
  }) async {
    final params = <String, String>{
      'from': from.toIso8601String(),
      'to': to.toIso8601String(),
    };
    if (category != null) params['category'] = category;

    final response = await _dioClient.get(
      ApiConstants.expenses,
      queryParameters: params,
    );
    return (response.data['expenses'] as List)
        .cast<Map<String, dynamic>>()
        .map(ExpenseModel.fromJson)
        .toList();
  }

  Future<ExpenseModel> createExpense({
    required double amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
    String? accountId,
    String? categoryId,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.expenses,
      data: {
        'amount': amount,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (category != null) 'category': category.toServer(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod.toServer(),
        if (accountId != null) 'accountId': accountId,
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
    return ExpenseModel.fromJson(
      response.data['expense'] as Map<String, dynamic>,
    );
  }

  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? description,
    ExpenseCategory? category,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    final response = await _dioClient.put(
      ApiConstants.expenseById(id),
      data: {
        if (amount != null) 'amount': amount,
        if (description != null) 'description': description,
        if (category != null) 'category': category.toServer(),
        if (paymentMethod != null) 'paymentMethod': paymentMethod.toServer(),
      },
    );
    return ExpenseModel.fromJson(
      response.data['expense'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteExpense(String id) async {
    await _dioClient.delete(ApiConstants.expenseById(id));
  }

  Future<ExpenseSummaryModel> getExpenseSummary() async {
    final response = await _dioClient.get(ApiConstants.expenseSummary);
    return ExpenseSummaryModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
