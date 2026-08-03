import 'package:coffix_app/core/utils/stream_disposable.dart';

class StreamDisposableRegistry {
  final List<StreamDisposable> _disposables = [];

  void register(StreamDisposable disposable) => _disposables.add(disposable);

  void cancelAll() {
    for (final disposable in _disposables) {
      disposable.cancelSubscriptions();
    }
  }
}
