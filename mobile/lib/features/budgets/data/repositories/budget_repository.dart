import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final DioClient _dioClient;

  BudgetRepository(this._dioClient);

  Future<List<BudgetModel>> getBudgets({
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.budgets,
      queryParameters: {'month': month.toString(), 'year': year.toString()},
    );
    return (response.data['budgets'] as List)
        .cast<Map<String, dynamic>>()
        .map(BudgetModel.fromJson)
        .toList();
  }

  Future<BudgetModel> upsertBudget({
    required ExpenseCategory category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    final response = await _dioClient.put(
      ApiConstants.budgets,
      data: {
        'category': category.toServer(),
        'limitAmount': limitAmount,
        'month': month,
        'year': year,
      },
    );
    return BudgetModel.fromJson(response.data['budget'] as Map<String, dynamic>);
  }

  Future<void> deleteBudget(String id) async {
    await _dioClient.delete(ApiConstants.budgetById(id));
  }

  Future<BudgetStatusModel> getBudgetStatus(String id) async {
    final response = await _dioClient.get(ApiConstants.budgetStatus(id));
    return BudgetStatusModel.fromJson(response.data as Map<String, dynamic>);
  }
}
