import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/db/app_database.dart';
import '../auth/auth_bloc.dart';

class HomeState {
  final String userName;
  final String? photoUrl;
  final int streakDays;
  final int xpToday;
  final int xpGoal;
  final double currentLessonProgress;
  final String currentLessonTitle;
  final bool isLoading;

  const HomeState({
    this.userName = '',
    this.photoUrl,
    this.streakDays = 0,
    this.xpToday = 0,
    this.xpGoal = 100,
    this.currentLessonProgress = 0.0,
    this.currentLessonTitle = 'Boshlash uchun dars tanlang',
    this.isLoading = false,
  });

  HomeState copyWith({
    String? userName,
    String? photoUrl,
    int? streakDays,
    int? xpToday,
    int? xpGoal,
    double? currentLessonProgress,
    String? currentLessonTitle,
    bool? isLoading,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      photoUrl: photoUrl ?? this.photoUrl,
      streakDays: streakDays ?? this.streakDays,
      xpToday: xpToday ?? this.xpToday,
      xpGoal: xpGoal ?? this.xpGoal,
      currentLessonProgress:
          currentLessonProgress ?? this.currentLessonProgress,
      currentLessonTitle: currentLessonTitle ?? this.currentLessonTitle,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  double get goalRatio => (xpToday / xpGoal).clamp(0, 1).toDouble();
}

class HomeCubit extends Cubit<HomeState> {
  final AppDatabase db;
  final AuthBloc authBloc;
  StreamSubscription? _authSubscription;

  HomeCubit({required this.db, required this.authBloc})
      : super(const HomeState()) {
    _authSubscription = authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        fetchData();
      }
    });
  }

  Future<void> fetchData() async {
    if (isClosed || state.isLoading) return;
    emit(state.copyWith(isLoading: true));
    try {
      String name = 'Mehmon';
      String? photo;
      String uid = '';

      if (authBloc.state is AuthAuthenticated) {
        final user = (authBloc.state as AuthAuthenticated).user;
        name = user.firstName;
        photo = user.photoUrl;
        uid = user.uid;
      }

      final totalXpToday = await db.getTodayXp();
      final streak = uid.isNotEmpty ? await db.getStreak(uid) : 0;
      final latestProgress = await db.getLatestLessonProgress();

      if (uid.isNotEmpty) {
        await db.updateUserLastActive(uid);
      }

      const int dailyGoal = 500;

      if (isClosed) return;
      emit(state.copyWith(
        userName: name,
        photoUrl: photo,
        xpToday: totalXpToday,
        xpGoal: dailyGoal,
        streakDays: streak,
        currentLessonProgress: latestProgress?.completion ?? 0.0,
        currentLessonTitle:
            latestProgress?.lessonId ?? 'Boshlash uchun dars tanlang',
        isLoading: false,
      ));
    } catch (_) {
      if (!isClosed) emit(state.copyWith(isLoading: false));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
