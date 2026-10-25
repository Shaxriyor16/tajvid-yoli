import '../../core/utils/login_throttle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/error_handler.dart';
import 'auth_model.dart';
import 'auth_service.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthAppleSignInRequested extends AuthEvent {}

class AuthEmailVerificationCheckRequested extends AuthEvent {}

class AuthEmailVerificationResendRequested extends AuthEvent {}

class AuthEmailSignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  const AuthEmailSignUpRequested({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });
  @override
  List<Object?> get props => [email, password, firstName, lastName];
}

class AuthEmailSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthEmailSignInRequested(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class AuthUserUpdateRequested extends AuthEvent {
  final UserModel user;
  const AuthUserUpdateRequested(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthSignOutRequested extends AuthEvent {}

class AuthProfileCompleteRequested extends AuthEvent {
  final String firstName;
  final String lastName;
  const AuthProfileCompleteRequested(this.firstName, this.lastName);
  @override
  List<Object?> get props => [firstName, lastName];
}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthNeedsProfileCompletion extends AuthState {
  final UserModel user;
  const AuthNeedsProfileCompletion(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthNeedsEmailVerification extends AuthState {
  final String email;
  final bool emailSent;
  const AuthNeedsEmailVerification(this.email, {this.emailSent = false});
  @override
  List<Object?> get props => [email, emailSent];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  final AuthState? previous;

  /// l10n kaliti (UI'da `AppLocalizations.get` bilan tarjima qilinadi).
  const AuthError(this.message, {this.previous});
  @override
  List<Object?> get props => [message, previous];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final AppDatabase _db;
  AuthState get _stableState => state is AuthError
      ? ((state as AuthError).previous ?? AuthUnauthenticated())
      : state;

  AuthBloc(this._authService, this._db) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthEmailVerificationCheckRequested>(_onEmailVerificationCheckRequested);
    on<AuthEmailVerificationResendRequested>(
        _onEmailVerificationResendRequested);
    on<AuthEmailSignUpRequested>(_onEmailSignUpRequested);
    on<AuthEmailSignInRequested>(_onEmailSignInRequested);
    on<AuthUserUpdateRequested>(_onUserUpdateRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthProfileCompleteRequested>(_onProfileCompleteRequested);
  }

  Future<void> _onCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.loadUser();
      if (user != null) {
        if (user.provider == 'email' &&
            !await _authService.isCurrentEmailVerified()) {
          emit(AuthNeedsEmailVerification(user.email));
          return;
        }
        if (user.firstName.isEmpty || user.lastName.isEmpty) {
          emit(AuthNeedsProfileCompletion(user));
        } else {
          if (user.provider == 'email') await _authService.saveUser(user);
          await _activateUser(user);
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignInRequested(
      AuthGoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        if (user.firstName.isEmpty || user.lastName.isEmpty) {
          emit(AuthNeedsProfileCompletion(user));
        } else {
          await _activateUser(user);
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(AuthUnauthenticated()); // Foydalanuvchi o'zi bekor qildi
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e)));
    }
  }

  Future<void> _onAppleSignInRequested(
      AuthAppleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signInWithApple();
      if (user != null) {
        if (user.firstName.isEmpty || user.lastName.isEmpty) {
          emit(AuthNeedsProfileCompletion(user));
        } else {
          await _activateUser(user);
          emit(AuthAuthenticated(user));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e)));
    }
  }

  Future<void> _onEmailSignUpRequested(
      AuthEmailSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authService.signUpWithEmail(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
      );
      if (user != null) {
        await _db.upsertUser(user.uid, user.fullName, user.photoUrl);
        emit(AuthNeedsEmailVerification(user.email));
      } else {
        emit(const AuthError('err_signup_failed'));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e)));
    }
  }

  Future<void> _onEmailSignInRequested(
      AuthEmailSignInRequested event, Emitter<AuthState> emit) async {
    // Brute-force / credential stuffing: ketma-ket xatolardan keyin qurilma vaqtincha bloklanadi.
    if (await LoginThrottle.remaining() > Duration.zero) {
      emit(const AuthError('err_too_many'));
      return;
    }
    emit(AuthLoading());
    try {
      final user =
          await _authService.signInWithEmail(event.email, event.password);
      if (user != null) {
        await LoginThrottle.reset();
        if (!await _authService.isCurrentEmailVerified()) {
          emit(AuthNeedsEmailVerification(user.email));
        } else {
          await _activateUser(user);
          emit(AuthAuthenticated(user));
        }
      } else {
        await LoginThrottle.recordFailure();
        emit(const AuthError('err_bad_login'));
      }
    } catch (e) {
      final message = ErrorHandler.toUserFriendly(e);
      // Faqat noto'g'ri hisob ma'lumotlari urinish hisoblanadi (tarmoq xatosi emas).
      if (message == 'err_bad_credentials' || message == 'err_sign_in') {
        await LoginThrottle.recordFailure();
      }
      emit(AuthError(message));
    }
  }

  Future<void> _onEmailVerificationCheckRequested(
      AuthEmailVerificationCheckRequested event,
      Emitter<AuthState> emit) async {
    final previous = _stableState;
    final pending = previous is AuthNeedsEmailVerification ? previous : null;
    if (pending == null) return;

    emit(AuthLoading());
    try {
      if (!await _authService.isCurrentEmailVerified()) {
        emit(AuthNeedsEmailVerification(pending.email));
        return;
      }
      final user = await _authService.loadUser();
      if (user == null) {
        emit(AuthUnauthenticated());
        return;
      }
      if (user.firstName.isEmpty || user.lastName.isEmpty) {
        await _db.setActiveUser(user.uid);
        emit(AuthNeedsProfileCompletion(user));
      } else {
        await _authService.saveUser(user);
        await _activateUser(user);
        emit(AuthAuthenticated(user));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e), previous: pending));
    }
  }

  Future<void> _onEmailVerificationResendRequested(
      AuthEmailVerificationResendRequested event,
      Emitter<AuthState> emit) async {
    final previous = _stableState;
    if (previous is! AuthNeedsEmailVerification) return;
    try {
      await _authService.resendEmailVerification();
      emit(AuthNeedsEmailVerification(previous.email, emailSent: true));
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e), previous: previous));
    }
  }

  Future<void> _activateUser(UserModel user) async {
    await _db.setActiveUser(user.uid);
    await _db.upsertUser(user.uid, user.fullName, user.photoUrl);
  }

  Future<void> _onProfileCompleteRequested(
      AuthProfileCompleteRequested event, Emitter<AuthState> emit) async {
    final previous = _stableState;
    try {
      if (previous is AuthNeedsProfileCompletion) {
        final currentUser = previous.user;
        final updatedUser = currentUser.copyWith(
            firstName: event.firstName, lastName: event.lastName);
        await _authService.saveUser(updatedUser);
        await _activateUser(updatedUser);
        emit(AuthAuthenticated(updatedUser));
      }
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e), previous: previous));
    }
  }

  Future<void> _onUserUpdateRequested(
      AuthUserUpdateRequested event, Emitter<AuthState> emit) async {
    final previous = _stableState;
    try {
      await _authService.updateUser(event.user);
      await _activateUser(event.user);
      emit(AuthAuthenticated(event.user));
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e), previous: previous));
    }
  }

  Future<void> _onSignOutRequested(
      AuthSignOutRequested event, Emitter<AuthState> emit) async {
    try {
      await _authService.signOut();
      await _db.setActiveUser(null);
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(ErrorHandler.toUserFriendly(e)));
    }
  }
}
