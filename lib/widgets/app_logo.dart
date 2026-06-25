import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 92,
    this.fit = BoxFit.contain,
    this.showCard = false,
  });

  final double height;
  final BoxFit fit;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/ehfassviyafaari_logo.png',
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );

    if (!showCard) return image;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: image,
    );
  }
}
