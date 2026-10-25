import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/bloc/app_config_cubit.dart';
import 'core/db/app_database.dart';
import 'core/services/ai_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/alphabet/alphabet_screen.dart';
import 'features/quran/book_reader_screen.dart';
import 'features/quran/quran_data.dart';
import 'features/quran/quran_reader_screen.dart';
import 'features/quran/surah_list_screen.dart';
import 'features/recitation_finder/recitation_finder_screen.dart';
import 'features/settings/settings_screen.dart';

/// Faqat UI tekshirish uchun ishlatiladigan kirish nuqtasi —
/// Firebase'siz, real ekranlarni ko'rish imkonini beradi.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final notificationService = _PreviewNotificationService();
  final quranRepository = QuranRepository(
    apiService: QuranApiService(),
    database: database,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>.value(value: database),
        RepositoryProvider<NotificationService>.value(
            value: notificationService),
        RepositoryProvider<QuranRepository>.value(value: quranRepository),
        RepositoryProvider<AiService>.value(value: AiService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => AppConfigCubit()),
        ],
        child: const _PreviewApp(),
      ),
    ),
  );
}

class _PreviewNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> hasPermission() async => true;
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tajvid Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _mode,
      home: _PreviewShell(onToggleTheme: () {
        setState(() {
          _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        });
      }),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return CupertinoTheme(
          data: isDark
              ? const CupertinoThemeData(brightness: Brightness.dark)
              : const CupertinoThemeData(brightness: Brightness.light),
          child: Container(
            decoration: AppColors.adaptiveBackground(context),
            child: child,
          ),
        );
      },
    );
  }
}

class _PreviewShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const _PreviewShell({required this.onToggleTheme});

  @override
  State<_PreviewShell> createState() => _PreviewShellState();
}

class _PreviewShellState extends State<_PreviewShell> {
  int _index = 0;

  static const _labels = [
    'Ro\'yxat',
    'Oyatlar',
    'Kitob',
    'Finder',
    'Harflar',
    'Sozlamalar',
  ];

  static const _screens = [
    SurahListScreen(),
    QuranReaderScreen(surahNumber: 1),
    BookReaderScreen(surahNumber: 1),
    RecitationFinderScreen(),
    AlphabetScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < _labels.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(_labels[i]),
                                selected: _index == i,
                                onSelected: (_) => setState(() => _index = i),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: _index == i
                                      ? Colors.white
                                      : palette.textMid,
                                ),
                                selectedColor: AppColors.lightEmerald,
                                backgroundColor: palette.fieldFill,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _index == 0
                          ? CupertinoIcons.moon_fill
                          : CupertinoIcons.sun_max_fill,
                      color: palette.accentGold,
                      size: 20,
                    ),
                    onPressed: widget.onToggleTheme,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _index, children: _screens),
          ),
        ],
      ),
    );
  }
}
