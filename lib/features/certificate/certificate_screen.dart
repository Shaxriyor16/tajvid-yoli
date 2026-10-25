import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/responsive/adaptive_shell.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/ornaments.dart';
import '../../core/widgets/screen_header.dart';
import '../../core/db/app_database.dart';
import '../auth/auth_bloc.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  final GlobalKey _certificateKey = GlobalKey();
  int _completedCount = 0;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = context.read<AppDatabase>();
    final count = await db.getCompletedLessonsCount();
    if (mounted) {
      setState(() {
        _completedCount = count;
        _loading = false;
      });
    }
  }

  /// Sertifikatni PNG sifatida saqlab, ulashish oynasini ochadi.
  Future<void> _shareCertificate() async {
    if (_sharing) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      final boundary = _certificateKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'tajvid_yoli_sertifikat.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: l10n.get('cert_share_subject'),
        text: l10n.get('cert_share_text'),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('cert_share_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final authState = context.watch<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.fullName
        : l10n.get('cert_student');
    final date = DateFormat('d-MMMM, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: palette.accentGold))
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 20, 20,
                  isDesktop ? 40 : 20, isDesktop ? 40 : 110),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: isDesktop ? 480 : double.infinity),
                  child: Column(
                    children: [
                      ScreenHeader(title: l10n.get('cert_title')),
                      const SizedBox(height: 8),
                      if (_completedCount == 0)
                        _buildEmptyState()
                      else
                        RepaintBoundary(
                          key: _certificateKey,
                          child: _buildCertificate(userName, date),
                        ),
                      const SizedBox(height: 20),
                      _buildDisclaimer(),
                      if (_completedCount > 0) ...[
                        const SizedBox(height: 16),
                        GradientButton(
                          label: _sharing
                              ? l10n.get('cert_preparing')
                              : l10n.get('cert_share'),
                          icon: Icons.ios_share_rounded,
                          onTap: _sharing ? null : _shareCertificate,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      palette.accentGold.withValues(alpha: 0.25),
                      palette.accentGold.withValues(alpha: 0),
                    ]),
                  ),
                ),
                StarBadge(
                  size: 92,
                  child: Icon(Icons.lock_outline_rounded,
                      size: 32, color: palette.accentGold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.get('cert_empty_title'),
            textAlign: TextAlign.center,
            style: AppTheme.display(size: 19, color: palette.textHi),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('cert_empty_body'),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMid, height: 1.5),
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: l10n.get('cert_start_lessons'),
            onTap: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificate(String name, String date) {
    final l10n = AppLocalizations.of(context);
    return AspectRatio(
      aspectRatio: 1.42,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF6E8), Color(0xFFF1E7C8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB08D3E).withValues(alpha: 0.28),
              blurRadius: 36,
              offset: const Offset(0, 16),
            )
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFB08D3E), width: 1.6),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const RadialGradient(
                    colors: [Colors.transparent, Colors.white],
                    radius: 1.0,
                  ).createShader(rect),
                  child: IslamicPattern(
                    color: const Color(0xFFB08D3E).withValues(alpha: 0.10),
                    cell: 40,
                  ),
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFB08D3E), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFB08D3E)
                                  .withValues(alpha: 0.3),
                              blurRadius: 12,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child:
                              Image.asset('assets/logo.png', fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(l10n.get('cert_badge'),
                          style: const TextStyle(
                              color: Color(0xFF6B4E1E),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 14),
                      Text(name,
                          style: const TextStyle(
                              color: Color(0xFF4A3B1E),
                              fontWeight: FontWeight.w700,
                              fontSize: 20)),
                      const SizedBox(height: 6),
                      Text(l10n.get('cert_achievement'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Color(0xFF8A7444), fontSize: 12)),
                      const SizedBox(height: 14),
                      Container(
                          height: 1,
                          width: 80,
                          color:
                              const Color(0xFFB08D3E).withValues(alpha: 0.5)),
                      const SizedBox(height: 10),
                      Text(date,
                          style: const TextStyle(
                              color: Color(0xFF8A7444), fontSize: 10.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warn.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.get('cert_disclaimer'),
              style: TextStyle(
                  color: AppPalette.of(context).textMid,
                  fontSize: 11.5,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
