import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/expense_model.dart';

class ExpenseRepository {
  const ExpenseRepository(this._dioClient);

  final DioClient _dioClient;

  // GET /expenses?category=...&from=...&to=...
  Future<ExpenseListResponse> getExpenses({
    String? category,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{
      if (category != null) 'category': category,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    };

    final response = await _dioClient.get(
      ApiConstants.expenses,
      queryParameters: query.isEmpty ? null : query,
    );
    return ExpenseListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // POST /expenses  body: { amount, description?, category?, paymentMethod? }
  Future<ExpenseModel> createExpense({
    required double amount,
    String? description,
    String? category,
    String? paymentMethod,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
    };

    final response = await _dioClient.post(ApiConstants.expenses, data: body);
    return ExpenseModel.fromJson(
      (response.data as Map<String, dynamic>)['expense']
          as Map<String, dynamic>,
    );
  }

  // PUT /expenses/:id  body: { amount?, category?, paymentMethod?, description? }
  Future<ExpenseModel> updateExpense(
    String id, {
    double? amount,
    String? category,
    String? paymentMethod,
    String? description,
  }) async {
    final body = <String, dynamic>{
      if (amount != null) 'amount': amount,
      if (category != null) 'category': category,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (description != null) 'description': description,
    };

    final response = await _dioClient.put(
      ApiConstants.expenseById(id),
      data: body,
    );
    return ExpenseModel.fromJson(
      (response.data as Map<String, dynamic>)['expense']
          as Map<String, dynamic>,
    );
  }

  // DELETE /expenses/:id  (soft delete on server)
  Future<void> deleteExpense(String id) async {
    await _dioClient.delete(ApiConstants.expenseById(id));
  }

  // GET /expenses/summary
  Future<ExpenseSummary> getSummary() async {
    final response = await _dioClient.get(ApiConstants.expenseSummary);
    return ExpenseSummary.fromJson(response.data as Map<String, dynamic>);
  }
}
