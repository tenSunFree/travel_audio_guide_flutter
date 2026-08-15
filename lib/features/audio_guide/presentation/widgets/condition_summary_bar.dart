import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/enums/sort_filter_enums.dart';

class ConditionSummaryBar extends StatelessWidget {
  const ConditionSummaryBar({
    required this.sortOrder,
    required this.filterType,
    required this.isNonDefault,
    required this.onReset,
    super.key,
  });

  final SortOrder sortOrder;
  final FilterType filterType;
  final bool isNonDefault;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: isNonDefault
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 14,
            color: isNonDefault ? colorScheme.primary : AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${sortOrder.label}・${filterType.label}',
              style: TextStyle(
                fontSize: 12,
                color: isNonDefault ? colorScheme.primary : AppColors.textHint,
              ),
            ),
          ),
          if (isNonDefault)
            GestureDetector(
              onTap: onReset,
              child: Text(
                '重設',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
