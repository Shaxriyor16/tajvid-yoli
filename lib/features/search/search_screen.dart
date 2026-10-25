import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/auth_widgets.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/widgets/glass_widgets.dart';
import '../quran/quran_data.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _RecentSearch {
  final String name;
  final int number;
  const _RecentSearch(this.name, this.number);

  Map<String, dynamic> toJson() => {'name': name, 'number': number};

  factory _RecentSearch.fromJson(Map<String, dynamic> json) =>
      _RecentSearch(json['name'] as String, json['number'] as int);
}

class _SearchScreenState extends State<SearchScreen> {
  static const String _recentKey = 'recent_surah_searches';
  static const int _maxRecent = 6;
  static const _popular = [
    _RecentSearch('Al-Fatihah', 1),
    _RecentSearch('Ya-Sin', 36),
    _RecentSearch("Al-Waqi'ah", 56),
    _RecentSearch('Al-Kahf', 18),
    _RecentSearch('Al-Mulk', 67),
  ];

  final _searchController = TextEditingController();
  List<Surah> _allSurahs = [];
  List<Surah> _filteredSurahs = [];
  List<_RecentSearch> _recent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    _loadRecent();
  }

  Future<void> _loadSurahs() async {
    try {
      final repo = context.read<QuranRepository>();
      final surahs = await repo.getSurahList();
      if (mounted) {
        setState(() {
          _allSurahs = surahs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .map((e) => _RecentSearch.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _recent = list);
    } catch (_) {
      // Buzilgan bo'lsa e'tibor bermaymiz.
    }
  }

  Future<void> _saveRecent(_RecentSearch entry) async {
    final updated = [
      entry,
      ..._recent.where((r) => r.number != entry.number),
    ].take(_maxRecent).toList();
    if (mounted) setState(() => _recent = updated);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _recentKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
    } catch (_) {
      // Saqlanmasa ham UI'da ko'rinadi.
    }
  }

  void _openSurah(Surah s) {
    HapticFeedback.lightImpact();
    _saveRecent(_RecentSearch(s.englishName, s.number));
    context.push('/quran/${s.number}');
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredSurahs = []);
      return;
    }

    final filtered = _allSurahs.where((s) {
      final name = s.englishName.toLowerCase();
      final arabic = s.arabicName;
      final q = query.toLowerCase();
      return name.contains(q) || arabic.contains(q) || s.number.toString() == q;
    }).toList();

    setState(() => _filteredSurahs = filtered);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Column(
            children: [
              ScreenHeader(title: l10n.get('search')),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: PremiumTextField(
                  controller: _searchController,
                  hint: l10n.get('search_hint'),
                  icon: CupertinoIcons.search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: _onSearch,
                  suffix: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(CupertinoIcons.xmark_circle_fill,
                              color: palette.textLow, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CupertinoActivityIndicator(
                            color: palette.accentGold, radius: 14))
                    : _searchController.text.isEmpty
                        ? _buildRecentSection(palette, l10n)
                        : _buildResultsSection(palette, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSection(AppPalette palette, AppLocalizations l10n) {
    final hasRecent = _recent.isNotEmpty;
    final entries = hasRecent ? _recent : _popular;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
              (hasRecent
                      ? l10n.get('recent_searches')
                      : l10n.get('popular_surahs'))
                  .toUpperCase(),
              style: TextStyle(
                  color: palette.accentGold,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
        ),
        GlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Divider(
                      height: 1,
                      indent: 62,
                      endIndent: 16,
                      color: palette.divider),
                _buildRecentSearch(entries[i], hasRecent, palette),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(AppPalette palette, AppLocalizations l10n) {
    if (_filteredSurahs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StarBadge(
              size: 84,
              child: Icon(CupertinoIcons.search,
                  size: 30, color: palette.accentGold),
            ),
            const SizedBox(height: 16),
            Text(l10n.get('no_results'),
                style: TextStyle(color: palette.textLow)),
          ],
        ),
      );
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      itemCount: _filteredSurahs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _filteredSurahs[i];
        final card = GlassCard(
          onTap: () => _openSurah(s),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          radius: 20,
          child: Row(
            children: [
              StarBadge(
                size: 44,
                child: Text('${s.number}',
                    style: TextStyle(
                        color: palette.accentGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(s.englishName,
                      style: TextStyle(
                          color: palette.textHi,
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5))),
              Text(s.arabicName,
                  style: AppTheme.arabic(size: 22, color: palette.accentGold)),
            ],
          ),
        );
        return i < 8
            ? FadeSlideIn(
                delay: Duration(milliseconds: 30 * i), offset: 8, child: card)
            : card;
      },
    );
  }

  Widget _buildRecentSearch(
      _RecentSearch entry, bool isRecent, AppPalette palette) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/quran/${entry.number}');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: palette.accentGold.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(isRecent ? CupertinoIcons.time : CupertinoIcons.flame,
                  color: palette.accentGold, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(entry.name,
                  style: TextStyle(
                      color: palette.textHi,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ),
            Text('${entry.number}',
                style: TextStyle(color: palette.textLow, fontSize: 12)),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.arrow_up_left,
                color: palette.textLow, size: 15),
          ],
        ),
      ),
    );
  }
}
