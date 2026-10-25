import 'package:flutter_bloc/flutter_bloc.dart';
import 'quran_data.dart';

abstract class QuranReaderState {
  const QuranReaderState();
}

class QuranReaderLoading extends QuranReaderState {
  const QuranReaderLoading();
}

class QuranReaderLoaded extends QuranReaderState {
  final Surah surah;
  const QuranReaderLoaded(this.surah);
}

class QuranReaderError extends QuranReaderState {
  final String message;
  const QuranReaderError(this.message);
}

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranRepository repository;
  int _requestId = 0;

  QuranReaderCubit({required this.repository})
      : super(const QuranReaderLoading());

  Future<void> loadSurah(int number) async {
    if (isClosed) return;
    final requestId = ++_requestId;
    emit(const QuranReaderLoading());
    try {
      final surah = await repository.getSurah(number);
      if (!isClosed && requestId == _requestId) emit(QuranReaderLoaded(surah));
    } catch (e) {
      if (!isClosed && requestId == _requestId) {
        emit(QuranReaderError(e.toString()));
      }
    }
  }
}
