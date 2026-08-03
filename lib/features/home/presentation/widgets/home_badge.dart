import 'package:flutter/material.dart';

/// Colored labels on homepage cards (Type / Recommendation status)
class HomeBadge extends StatelessWidget {
  const HomeBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    super.key,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
