import 'dart:io';
import '../auth/auth_service.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/db/app_database.dart';
import '../auth/auth_bloc.dart';
import '../auth/auth_model.dart';
import 'package:image_picker/image_picker.dart';

class ProfileState {
  final UserModel? user;
  final int completedLessons;
  final int streakDays;
  final double averageAccuracy;
  final int certificateCount;
  final bool isLoading;

  const ProfileState({
    this.user,
    this.completedLessons = 0,
    this.streakDays = 0,
    this.averageAccuracy = 0.0,
    this.certificateCount = 0,
    this.isLoading = false,
  });

  ProfileState copyWith({
    UserModel? user,
    bool clearUser = false,
    int? completedLessons,
    int? streakDays,
    double? averageAccuracy,
    int? certificateCount,
    bool? isLoading,
  }) {
    return ProfileState(
      user: clearUser ? null : (user ?? this.user),
      completedLessons: completedLessons ?? this.completedLessons,
      streakDays: streakDays ?? this.streakDays,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      certificateCount: certificateCount ?? this.certificateCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  final AppDatabase db;
  final AuthBloc authBloc;
  final AuthService _authService;
  StreamSubscription? _authSubscription;

  ProfileCubit({
    required this.db,
    required this.authBloc,
    required AuthService authService,
  })  : _authService = authService,
        super(const ProfileState()) {
    _authSubscription = authBloc.stream.listen((state) {
      if (state is AuthAuthenticated) {
        loadProfile();
      } else if (state is AuthUnauthenticated) {
        emit(const ProfileState());
      }
    });
  }

  Future<void> loadProfile() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    final authAtStart = authBloc.state;
    try {
      UserModel? user;
      if (authBloc.state is AuthAuthenticated) {
        user = (authBloc.state as AuthAuthenticated).user;
      }

      final completed = await db.getCompletedLessonsCount();
      final accuracy = await db.getAverageAccuracy();
      final streak = user != null ? await db.getStreak(user.uid) : 0;

      if (isClosed || authBloc.state != authAtStart) return;
      emit(state.copyWith(
        user: user,
        clearUser: user == null,
        completedLessons: completed,
        averageAccuracy: accuracy,
        streakDays: streak,
        certificateCount: completed > 0 ? 1 : 0,
        isLoading: false,
      ));
    } catch (_) {
      if (!isClosed && authBloc.state == authAtStart) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  Future<void> updateProfilePicture() async {
    if (isClosed || state.isLoading || state.user == null) return;
    final user = state.user!;
    emit(state.copyWith(isLoading: true));
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70, maxWidth: 1080);

      if (isClosed || state.user?.uid != user.uid) return;
      if (image != null) {
        final localPath = await _authService.saveProfilePictureLocally(
            File(image.path), user.uid);

        if (isClosed || state.user?.uid != user.uid) return;

        if (localPath != null) {
          final updatedUser = state.user!.copyWith(photoUrl: localPath);
          authBloc.add(AuthUserUpdateRequested(updatedUser));
          emit(state.copyWith(user: updatedUser, isLoading: false));
        } else {
          emit(state.copyWith(isLoading: false));
        }
      }
    } finally {
      if (!isClosed && state.user?.uid == user.uid) {
        emit(state.copyWith(isLoading: false));
      }
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
