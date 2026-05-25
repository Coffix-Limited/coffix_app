import 'package:coffix_app/features/transaction/data/model/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions();
  Future<Transaction?> getTransactionByNumber(String transactionNumber);
}
