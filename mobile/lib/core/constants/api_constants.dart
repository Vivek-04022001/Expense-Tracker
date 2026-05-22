import 'dart:io';

class ApiConstants {
  static final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:3000'
      : 'https://expense-tracker-production-8083.up.railway.app';

  static const String registerEndpoint = '/auth/register';
  static const String loginEndpoint = '/auth/login';
  static const String refreshEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';

  static const String expenses = '/expenses';
  static const String expenseSummary = '/expenses/summary';
  static String expenseById(String id) => '/expenses/$id';

  static const String budgets = '/budgets';
  static String budgetById(String id) => '/budgets/$id';
  static String budgetStatus(String id) => '/budgets/$id/status';

  static const String income = '/income';
  static String incomeById(String id) => '/income/$id';

  static const String savingsSummary = '/savings/summary';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
