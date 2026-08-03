import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/features/home/domain/entities/home_state.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/constants/home_ui_colors.dart';

class PeriodChips extends StatelessWidget {
  const PeriodChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final HomePeriod selected;
  final ValueChanged<HomePeriod> onSelected;

  static const List<HomePeriod> _periods = [
    HomePeriod.morning,
    HomePeriod.afternoon,
    HomePeriod.evening,
    HomePeriod.night,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _periods.map((period) {
        final isSelected = selected == period;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onSelected(period),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? HomeUiColors.selectedBg
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? HomeUiColors.selectedBg
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  HomePeriodHelper.label(period),
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
