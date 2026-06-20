import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _localUrl = 'http://10.0.2.2:3000';
  static const String _productionUrl =
      'https://expense-tracker-production-8083.up.railway.app';

  static String get baseUrl => kReleaseMode ? _productionUrl : _localUrl;

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

  static const String accounts = '/accounts';
  static String accountById(String id) => '/accounts/$id';

  static const String transfers = '/transfers';
  static String transferById(String id) => '/transfers/$id';

  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
}
