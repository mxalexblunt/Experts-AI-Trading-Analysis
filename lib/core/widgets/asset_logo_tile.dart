import 'package:flutter/cupertino.dart';

import '../../models/models.dart';
import '../services/app_log.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_typography.dart';

class AssetLogoTile extends StatelessWidget {
  const AssetLogoTile({
    super.key,
    required this.symbol,
    required this.type,
    this.logoUrl,
    this.size = 54,
    this.showChartFallback = false,
  });

  final String symbol;
  final AssetType type;
  final String? logoUrl;
  final double size;
  final bool showChartFallback;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    if (url == null || url.isEmpty) {
      AppLog.assetLogo(
        'fallback symbol=$symbol type=${type.name} '
        'reason=empty-logo-url size=$size',
      );
    } else {
      AppLog.assetLogo(
        'remote symbol=$symbol type=${type.name} '
        'url=$url size=$size',
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoTile,
        borderRadius: BorderRadius.circular(
          size >= 64 ? AppRadii.lg : AppRadii.md,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? _FallbackLogo(
              symbol: symbol,
              type: type,
              showChartFallback: showChartFallback,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                AppLog.assetLogo(
                  'fallback symbol=$symbol type=${type.name} '
                  'reason=network-image-error url=$url',
                  error: error,
                );
                return _FallbackLogo(
                  symbol: symbol,
                  type: type,
                  showChartFallback: showChartFallback,
                );
              },
            ),
    );
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({
    required this.symbol,
    required this.type,
    required this.showChartFallback,
  });

  final String symbol;
  final AssetType type;
  final bool showChartFallback;

  @override
  Widget build(BuildContext context) {
    final label = type == AssetType.etf ? 'ETF' : _shortSymbol(symbol);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.logoTile,
                AppColors.textPrimary.withValues(alpha: 0.78),
              ],
            ),
          ),
        ),
        if (showChartFallback)
          CustomPaint(
            painter: _LogoChartPainter(
              color: AppColors.primary.withValues(alpha: 0.72),
            ),
          ),
        Center(
          child: Text(
            label,
            style: AppTypography.caption1.copyWith(
              color: AppColors.canvasPure,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  String _shortSymbol(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) return '?';
    return normalized.length <= 2 ? normalized : normalized.substring(0, 2);
  }
}

class _LogoChartPainter extends CustomPainter {
  const _LogoChartPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.70)
      ..lineTo(size.width * 0.32, size.height * 0.56)
      ..lineTo(size.width * 0.48, size.height * 0.62)
      ..lineTo(size.width * 0.66, size.height * 0.38)
      ..lineTo(size.width * 0.86, size.height * 0.30);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoChartPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
