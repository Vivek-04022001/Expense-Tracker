import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/transfer_model.dart';

class TransferRepository {
  final DioClient _dioClient;

  TransferRepository(this._dioClient);

  Future<List<TransferModel>> getTransfers() async {
    final response = await _dioClient.get(ApiConstants.transfers);
    return (response.data['transfers'] as List)
        .cast<Map<String, dynamic>>()
        .map(TransferModel.fromJson)
        .toList();
  }

  Future<TransferModel> createTransfer({
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    String? description,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.transfers,
      data: {
        'amount': amount,
        'fromAccountId': fromAccountId,
        'toAccountId': toAccountId,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return TransferModel.fromJson(
      response.data['transfer'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteTransfer(String id) async {
    await _dioClient.delete(ApiConstants.transferById(id));
  }
}
