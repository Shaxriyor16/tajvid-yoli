import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tajvid_yoli/app.dart';
import 'package:tajvid_yoli/core/bloc/app_config_cubit.dart';
import 'package:tajvid_yoli/features/auth/auth_service.dart';
import 'package:tajvid_yoli/features/auth/auth_bloc.dart';
import 'quran_reliability_test.dart' show MemoryDatabase;

class FakeAuthService implements AuthService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestAuthBloc extends AuthBloc {
  TestAuthBloc() : super(FakeAuthService(), MemoryDatabase());
  void setStateForTest(AuthState next) => emit(next);
}

void main() {
  testWidgets('theme changes preserve the app router', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = AppConfigCubit();
    final auth = AuthBloc(FakeAuthService(), MemoryDatabase());
    await tester.pumpWidget(MultiBlocProvider(providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<AppConfigCubit>.value(value: config),
    ], child: const TajvidYoliApp()));
    await tester.pump(const Duration(seconds: 2));
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig;
    await tester.runAsync(() => config.setThemeMode(ThemeMode.dark));
    await tester.pump();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig,
        same(router));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(auth.close);
    await config.close();
  });

  testWidgets('failed sign-in stays on the login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = AppConfigCubit();
    final auth = TestAuthBloc();
    await tester.pumpWidget(MultiBlocProvider(providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<AppConfigCubit>.value(value: config),
    ], child: const TajvidYoliApp()));
    await tester.pump(const Duration(seconds: 2));
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig as GoRouter;
    auth.setStateForTest(AuthUnauthenticated());
    await tester.pumpAndSettle();
    router.go('/login');
    await tester.pumpAndSettle();
    auth.setStateForTest(AuthLoading());
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    auth.setStateForTest(const AuthError('Internet uzildi'));
    await tester.pump();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(auth.close);
    await config.close();
  });
}
