import 'package:tajvid_yoli/core/widgets/ornaments.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/onboarding_store.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../core/widgets/islamic_pattern.dart';
import '../../core/widgets/motion.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    _SlideData(titleKey: 'ob_t1', subtitleKey: 'ob_s1', arabic: 'اقرأ'),
    _SlideData(titleKey: 'ob_t2', subtitleKey: 'ob_s2', arabic: 'تجويد'),
    _SlideData(titleKey: 'ob_t3', subtitleKey: 'ob_s3', arabic: 'بِسْمِ'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await OnboardingStore.markCompleted();
    if (!mounted) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final last = _page == _slides.length - 1;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(maxWidth: isDesktop ? 420 : double.infinity),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.glassBorder),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold2.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.asset('assets/logo.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: last ? 0 : 1,
                          child: TextButton(
                            onPressed: last ? null : () => _finish('/login'),
                            child: Text(l10n.get('ob_skip'),
                                style: TextStyle(color: palette.textMid)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _slides.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) =>
                          _OnboardingSlide(data: _slides[i]),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (i) {
                      final on = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: on ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: on ? AppColors.goldGradient : null,
                          color: on ? null : palette.textLow,
                        ),
                      );
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                    child: Column(
                      children: [
                        GradientButton(
                          label:
                              last ? l10n.get('ob_start') : l10n.get('ob_next'),
                          icon: Icons.arrow_forward_rounded,
                          onTap: () {
                            if (last) {
                              _finish('/permissions');
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                        ),
                        TextButton(
                          onPressed: () => _finish('/login'),
                          child: Text(l10n.get('ob_have_account'),
                              style: TextStyle(color: palette.textMid)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideData {
  final String titleKey;
  final String subtitleKey;
  final String arabic;
  const _SlideData(
      {required this.titleKey,
      required this.subtitleKey,
      required this.arabic});
}

class _OnboardingSlide extends StatelessWidget {
  final _SlideData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeSlideIn(child: _Medallion(arabic: data.arabic)),
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Text(l10n.get(data.titleKey),
                    textAlign: TextAlign.center,
                    style: AppTheme.display(size: 25, color: palette.textHi)),
              ),
              const SizedBox(height: 6),
              Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  l10n.get(data.subtitleKey),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: palette.textMid, fontSize: 14.5, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slayd tasviri: naqshli zumrad medalyon, ichida oltin arabcha so'z.
class _Medallion extends StatelessWidget {
  final String arabic;
  const _Medallion({required this.arabic});

  static const _gold = Color(0xFFE8C77B);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.gold2.withValues(alpha: 0.3),
                AppColors.gold2.withValues(alpha: 0),
              ]),
            ),
          ),
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: _gold.withValues(alpha: 0.55), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F4A3D).withValues(alpha: 0.4),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFF16604F), Color(0xFF0A2E27)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IslamicPattern(
                      color: _gold.withValues(alpha: 0.16),
                      cell: 38,
                    ),
                  ),
                  Container(
                    width: 138,
                    height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _gold.withValues(alpha: 0.25)),
                    ),
                  ),
                  PaddedShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.goldGradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(arabic,
                        style: AppTheme.arabic(size: 58, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
