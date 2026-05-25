import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:coffix_app/data/repositories/transaction_repository.dart';
import 'package:coffix_app/features/transaction/data/model/transaction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_state.dart';
part 'transaction_cubit.freezed.dart';

class TransactionCubit extends Cubit<TransactionState> {
  final TransactionRepository _transactionRepository;

  TransactionCubit({required TransactionRepository transactionRepository})
    : _transactionRepository = transactionRepository,
      super(TransactionState.initial());

  Future<void> getTransactions() async {
    emit(TransactionState.loading());
    try {
      final transactions = await _transactionRepository.getTransactions();
      emit(TransactionState.loaded(transactions: transactions));
    } catch (e) {
      emit(TransactionState.error(message: e.toString()));
    }
  }

  Future<void> fetchOriginalTransaction(String originalTransactionNumber) async {
    final current = state.whenOrNull(
      loaded: (txns, originals) => (txns, originals),
    );
    if (current == null) return;
    if (current.$2.containsKey(originalTransactionNumber)) return;
    final original = await _transactionRepository.getTransactionByNumber(
      originalTransactionNumber,
    );
    if (original == null) return;
    emit(TransactionState.loaded(
      transactions: current.$1,
      originalTransactions: {...current.$2, originalTransactionNumber: original},
    ));
  }
}
